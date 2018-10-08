local _G = _G

-- TODO: bnet friend stuff doesnt seem to work as partner
--  remove friends bnet from ignore list, reinit config data

-- addon name and namespace
local ADDON, NS = ...

local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON)

-- the communication module
local Communication = Addon:NewModule("Communication", "AceEvent-3.0", "AceTimer-3.0")

LibStub:GetLibrary("AceComm-3.0"):Embed(Communication)
LibStub:GetLibrary("AceSerializer-3.0"):Embed(Communication)

-- local functions
local strlower, strfind = strlower, strfind
local tinsert    = table.insert
local table_sort = table.sort
local math_ceil  = math.ceil
local pairs      = pairs
local next       = next
local time       = time

local GetNumFriends               = _G.GetNumFriends
local GetFriendInfo               = _G.GetFriendInfo
local GetNumGuildMembers          = _G.GetNumGuildMembers
local GetGuildRosterInfo          = _G.GetGuildRosterInfo
local BNGetNumFriends             = _G.BNGetNumFriends
local BNGetFriendInfo             = _G.BNGetFriendInfo
local CanCooperateWithGameAccount = _G.CanCooperateWithGameAccount

local BNET_CLIENT_WOW             = _G.BNET_CLIENT_WOW

-- aux variables
local _

local potentials = {}

-- message types
local INVALIDMSG     = 0
local READYFORCOMM   = 1
local INFODATA       = 2
local SERVERREQUEST  = 3
local SERVERREPLY    = 4
local USERDATA       = 7
local DROPSERVER     = 8
local DROPCLIENT     = 9
local CONFIGDATA     = 10
local CONFIGREQUEST  = 11

local REASONHIGHLOAD = 1
local REASONFULL     = 2
local REASONREJECT   = 3

-- constants
local MAX_CONNECTIONS    = 50
local MSG_CACHE_SIZE     = 250

local MAX_IMBALANCE      = 5

local BROADCAST_INTERVAL = 5

-- TODO: compress data communication

-- module handling
function Communication:OnInitialize()
	self.activate = false
	self.ready    = false
	
	-- some auxillary vars
	-- why can't there simply be WoW API functions like IsFriend(name), IsGuildMate(name), IsBNetFriend(name)?
	self.guildmates  = {}
	self.friends     = {}
	self.bnetfriends = {}
	self.blacklist   = {}
	
	-- valid partners to communicate with
	self.partners = {}
	
	-- clients for which we monitor the channels
	self.clients    = {}
	
	self.numClients = 0
	self.quality    = 0
	
	-- server we use for monitoring
	self.server = nil
	
	-- pending ready requests
	self.pending = {}
	
	-- msg cache
	self.serverCache = NS:CreateServerCache(MSG_CACHE_SIZE)
	self.clientCache = NS:CreateClientCache()	
end

function Communication:OnEnable()
	self:Setup()
end

function Communication:OnDisable()
	self:Shutdown()
end

-- module communication setup
function Communication:Setup()	
	-- keep friend, guild and bnet friend list up to date
	self:RegisterEvent("FRIENDLIST_UPDATE",           "UpdateFriends")
	self:RegisterEvent("GUILD_ROSTER_UPDATE",         "UpdateGuildMates")
	self:RegisterEvent("BN_CONNECTED",                "UpdateBNetFriends")
	self:RegisterEvent("BN_DISCONNECTED",             "UpdateBNetFriends")
	self:RegisterEvent("BN_FRIEND_LIST_SIZE_CHANGED", "UpdateBNetFriends")
	self:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE",    "UpdateBNetFriends")
	self:RegisterEvent("BN_FRIEND_ACCOUNT_OFFLINE",   "UpdateBNetFriends")
	
	-- fill valid partner lists
	self:UpdateFriends()
	self:UpdateGuildMates()
	self:UpdateBNetFriends()
	
	-- request current friend list from server
	ShowFriends()
	
	-- client config
	self:SetupClientConfig()
	
	-- set up actual communication
	self:ActivateCommunication(true)	
end

function Communication:ShutDown()
	self:ActivateCommunication(false, true)

	-- unregister events maintaining valid partner lists
	self:UnregisterEvent("FRIENDLIST_UPDATE")
	self:UnregisterEvent("GUILD_ROSTER_UPDATE")
	self:UnregisterEvent("BN_CONNECTED")
	self:UnregisterEvent("BN_DISCONNECTED")
	self:UnregisterEvent("BN_FRIEND_LIST_SIZE_CHANGED")
	self:UnregisterEvent("BN_FRIEND_ACCOUNT_ONLINE")
	self:UnregisterEvent("BN_FRIEND_ACCOUNT_OFFLINE")
	
end

function Communication:ResetCommVars()
	NS:ClearTable(self.partners)
	NS:ClearTable(self.clients)
	NS:ClearTable(self.pending)
	
	self.numClients = 0
	self.quality    = 0
	
	-- server we use for monitoring
	self.server = nil
	
	-- msg cache
	self.serverCache:Reset()
	self.clientCache:Reset()	
end

function Communication:ActivateCommunication(activate, now)
	self.activate = activate
	
	self:Prepare(now)
end

function Communication:Prepare(now)
	self:Debug("Prepare " .. (now and "now" or "") )
	if now then
		if self.activationTimer then
			self:CancelTimer(self.activationTimer)
			self.activationTimer = nil
		end
		self:UpdateCommSetup()
	else
		-- don't send immediately
		if not self.activationTimer then
			self.activationTimer = self:ScheduleTimer("UpdateCommSetup", BROADCAST_INTERVAL)
		end
	end

end

function Communication:UpdateCommSetup()
	self.activationTimer = nil
	self:Debug("UpdateCommSetup")

	if self.activate == true and Addon:GetAddonCommunication() == true then
		if not self.ready then
			self:Debug("UpdateCommSetup: setup communication")

			-- init comm variables
			self:ResetCommVars()

			self.ready = true
			self:RegisterComm(Addon.MODNAME, "OnCommReceive")	
			self:BroadcastAddonReady(true)
			
			-- inform others about our current info
			self:UpdateInfoData()
	
			-- try to find a server if needed
			self:UpdateRemoteMonitoring()

			-- monitor channel notices to keep track of 'quality' of service
			-- if we are not in any of the monitored channels quality will be 0
			-- and we are disqualified from being a server
			self:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE", "UpdateInfoData", false)

			-- update addon label
			Addon:UpdateLabel()				
		end
	else
		if self.ready == true then
			self:Debug("UpdateCommSetup: shutdown communication")
			-- unregister channel monitoring
			self:UnregisterEvent("CHAT_MSG_CHANNEL_NOTICE")

			self:BroadcastAddonReady(false)
			self:UnregisterComm(Addon.MODNAME)
			self.ready = false

			-- re-init comm variables
			self:ResetCommVars()
			
			-- update addon label
			Addon:UpdateLabel()	
		end
	end
end

function Communication:SetupClientConfig()
	self.clientConfig       = {}

	for instance, keywords in pairs(NS.defaultInstanceKeywords) do
		self.clientConfig[instance]    = {}
	end
end

function Communication:IsReady()
	return self.ready
end

function Communication:HasActiveClients()
	return next(self.clients) and true or false
end

function Communication:InstanceMonitoredByClient(instance)
	return next(self.clientConfig[instance]) and true or false
end

-- config possibly changed, which means we might need a connection or have to drop the current one
function Communication:UpdateRemoteMonitoring()	
	if self.server then
		-- we got a server but we stopped monitoring
		if not self:NeedsRemoteMonitoring() then
			-- send msg only if we deactivated monitoring
			self:ResetServer(not Addon:GetMonitoringActive())
		end
	else
		if self:RequiresServer() then
			-- select the best server
			local server = self:SelectBestServer()
		
			if server then
				self:Debug("UpdateRemoteMonitoring: best server " .. tostring(server))
				self:SendGrantServerRequest(server)				
			else
				self:Debug("UpdateRemoteMonitoring: no valid server candidate found")			
			end
		end
	end
end

-- select by highest quality and lowest connection count
function Communication:SelectBestServer()
	local best        = nil
	local quality     = 0
	local connections = MAX_CONNECTIONS
	
	for partner, info in pairs(self.partners) do
		-- 1 is the general chat which is always available
		if info.quality > 1 and info.quality >= quality then
			quality = info.quality
			
			if info.connections < connections then
				connections = info.connections
				
				best = partner
			end
		end
	end
	
	return best
end

-- is monitoring but has no server and no request waiting
function Communication:RequiresServer()
	return not self.server and not self.requested and self:NeedsRemoteMonitoring()
end

function Communication:NeedsRemoteMonitoring()
	if not Addon:GetMonitoringActive() then
		self:Debug("NeedsRemoteMonitoring: no - monitoring inactive")
		return false
	end

	if self.quality > 1 then
		self:Debug("NeedsRemoteMonitoring: no - quality > 1")
		return false
	end
	
	if Addon:IsAnyInstanceMonitored() then
		self:Debug("NeedsRemoteMonitoring: needs monitoring!")
		return true
	end
	
	self:Debug("NeedsRemoteMonitoring: no instances tracked")
	return false
end

function Communication:CheckServer()
	self:Debug("CheckServer")
	if not self.server then
		self:Debug("CheckServer: no server")
		return
	end
	
	-- servers quality dropped to 1, so we dump it an try to connect to a new server
	if self.partners[self.server].quality <= 1 then
		self:Debug("CheckServer: server no longer qualified")
		self:ResetServer()
		
		self:UpdateRemoteMonitoring()
	end
end

function Communication:IsConnected()
	return self.server ~= nil
end

-- connection handling
function Communication:ResetServer(sendmsg)
	self:Debug("ResetServer")
	if sendmsg then
		self:Debug("ResetServer: send msg")
		self:SendDropServer()
	end

	self.server = nil
	
	-- reset client cache
	self.clientCache:Reset()

	Addon:UpdateLabel()
end

function Communication:DropClient(client)
	self:Debug("DropClient: " .. tostring(client))
	self:SendDropClient(client)
	
	self:DisconnectClient(client)
end

function Communication:ConnectionRequest(client)
	self:Debug("ConnectionRequest: client - " .. tostring(client))
	local granted = true
	local reason  = nil

	-- we don't maintain client already
	if not self.clients[client] then
		-- only mutual friends communicate and guild mates
		if not self.partners[client] then
			self:Debug("ConnectionRequest: client is not in list of partners")
			granted = false
			reason  = REASONREJECT
		elseif #self.clients >= MAX_CONNECTIONS then
			self:Debug("ConnectionRequest: we have reached max connections")
			-- client sending request appears not to have current information (selecting suboptimal server)
			self:UpdateInfoData(true)
			
			granted = false
			reason  = REASONFULL
		else
			self:Debug("ConnectionRequest: check max connections")
			-- make sure we dont take all the load
			local best = self:SelectBestServer()
			
			self:Debug("ConnectionRequest: best alternative " .. tostring(best))
			if best and 
			   self.partners[best].quality >= self.quality and
			   self.partners[best].connections + MAX_IMBALANCE < #self.clients then
				-- client sending request appears not to have current information (selecting suboptimal server)
				self:Debug("ConnectionRequest: alternative server should be preferred - reject request")
				self:UpdateInfoData(true)
				
				granted = false
				reason  = REASONHIGHLOAD
			else
				self:Debug("ConnectionRequest: accept request")
				self.clients[client] = time()
				
				self:UpdateInfoData()			   
			end
		end
	else
		self:Debug("ConnectionRequest: client already maintained")
	end
	
	return granted, reason
end

function Communication:DisconnectClient(client)
	self:Debug("DisconnectClient: " .. tostring(client))
	-- remove sender from client list
	if self.clients[client] then
		self:Debug("DisconnectClient: disconnect")
		self.clients[client] = nil
		
		-- reset client config
		for instance, config in pairs(self.clientConfig) do
			config[client] = nil
		end
		
		-- delete client from server cache
		self.serverCache:InvalidateClient(client)
		
		self:UpdateInfoData()
	end
end

-- partner handling
function Communication:IsValidPartner(partner)
	if Addon.PlayerName == partner then
		return false
	end
	
	if self.blacklist[partner] then
		return false
	end

	if self.guildmates[partner] then
		return true
	end

	if self.friends[partner] then
		return true
	end
	
	if self.bnetfriends[partner] then
		return true
	end

	return false
end

function Communication:UpdateFriends()
	self:Debug("UpdateFriends")	
	NS:ClearTable(potentials)
	
	for i = 1, GetNumFriends() do
		local friend, _, _, _, online = GetFriendInfo(i)
		
		-- friend is online and not blacklisted (which happens when 1-way friendship disqualifies us from communicating)
		if friend and online and not self.blacklist[friend] then
			self:Debug("UpdateFriends: added " .. tostring(friend))
			potentials[friend] = true
		end
	end
	
	self:UpdatePotentialPartners(self.friends, potentials)
end

function Communication:UpdateGuildMates()
	self:Debug("UpdateGuildMates")
	NS:ClearTable(potentials)
	
	for i = 1, GetNumGuildMembers() do
		local guildmate = GetGuildRosterInfo(i)
		
		-- we dont bother with online state here since guild mates receive their messages as broadcast
		if guildmate then
			potentials[guildmate] = true
		end
	end	

	self:UpdatePotentialPartners(self.guildmates, potentials)
end

function Communication:UpdateBNetFriends()
	self:Debug("UpdateBNetFriends")
	NS:ClearTable(potentials)

	for i = 1, BNGetNumFriends() do
		local bnetIDAccount, _, _, _, toon, toonID, client, online = BNGetFriendInfo(i)
		if client and toon then
			self:Debug("UpdateBNetFriends: client " .. tostring(client) .. " toon " .. tostring(toon) .. " toonID " .. tostring(toonID) .. " online " .. tostring(online))
		end
		if client == BNET_CLIENT_WOW and toon and online and CanCooperateWithGameAccount(bnetIDAccount) then
			self:Debug("UpdateBNetFriends: added " .. tostring(toon))
			potentials[toon] = true
		end
	end

	self:UpdatePotentialPartners(self.bnetfriends, potentials)
end

function Communication:UpdatePotentialPartners(potentials, updated)
	if type(potentials) ~= "table" or type(updated) ~= "table" then
		return
	end

	local removed = false
	local added   = false
	
	-- remove missing
	for potential, _ in pairs(potentials) do
		if not updated[potential] then
			potentials[potential] = nil
			removed = true
		end
	end
	
	-- add new ones
	for potential, _ in pairs(updated) do
		if not potentials[potential] then
			potentials[potential] = true
			added = true
		end
	end
	
	if removed then
		-- throw out removed partners
		self:UpdatePartnerValidity()
	end
	
	if added then
		-- inform new partners
		self:UpdateAddonReady()	
	end
end

function Communication:UpdatePartnerValidity()
	self:Debug("UpdatePartnerValidity")
	
	-- check partners
	for partner, _ in pairs(self.partners) do
		if not self:IsValidPartner(partner) then			
			self:Debug("UpdatePartnerValidity: removing partner " .. tostring(partner))
			self.partners[partner] = nil

			if self.clients[partner] then
				self:Debug("UpdatePartnerValidity: removing client " .. tostring(partner))
				self:DisconnectClient(partner)
			end
		end
	end
	
	-- check servers
	if self.server and not self:IsValidPartner(self.server) then
		self:Debug("UpdatePartnerValidity: removing server " .. tostring(self.server))
		self:ResetServer()
		
		self:UpdateRemoteMonitoring()
	end	
end

-- info data

-- something on this side changed so we have to notify our partners to retain perfect information
function Communication:UpdateInfoData(now)
	local quality = 0
	
	local channels = {GetChannelList()}
	
	for i=1, #channels, 2 do
		if Addon:IsMonitoredChannel(channels[i]) then
			quality = quality + channels[i]
		end
	end

	if quality ~= self.quality or #self.clients ~= self.numClients then
		self.quality    = quality
		self.numClients = #self.clients	
		
		if now then
			self:Debug("UpdateInfoData: send now")
			if self.broadcastTimer then
				self:CancelTimer(self.broadcastTimer)
				self.broadcastTimer = nil
			end
		
			-- send immediately when requested
			self:ProcessInfoData()
		else
			self:Debug("UpdateInfoData: send delayed")
			-- dont send immediately
			if not self.broadcastTimer then
				self.broadcastTimer = self:ScheduleTimer("ProcessInfoData", BROADCAST_INTERVAL)
			end
		end
	end	
end

function Communication:ProcessInfoData()
	self:Debug("ProcessInfoData")
	-- disconnect clients if our quality dropped to zero
	-- we do it silently without informing the client explicitely
	-- clients will notice from the zero quality in the info data and disconnect on their own
	if self.quality <= 1 then
		self:Debug("ProcessInfoData: quality <= 1 - disconnect all clients")
		
		-- reset client config
		for instance, config in pairs(self.clientConfig) do
			self:Debug("ProcessInfoData: clear config for instance " .. tostring(instance))
			NS:ClearTable(config)
		end
		
		-- drop clients
		self:Debug("ProcessInfoData: clear clients " .. tostring(self.clients))
		NS:ClearTable(self.clients)		
		
		self.numClients = 0
		
		-- clear cache
		self.serverCache:Reset()
	end

	self:BroadcastInfoData()
	
	self:UpdateRemoteMonitoring()
end

-- config data 
function Communication:UpdateConfigData()
	-- keep config data up to date only when we are actually ready for communication
	if not self.ready then
		return
	end
	
	-- update connection state
	self:UpdateRemoteMonitoring()
	
	if self.server then
		self:SendConfigData()
	end
end

-- remote config data
function Communication:UpdateClientConfigData(client, instances)
	self:Debug("UpdateClientConfigData: " .. tostring(client) .. " searches " .. tostring(instances))
	if not self.clients[client] then
		self:Debug("UpdateClientConfigData: no client of that name")
		return
	end
	
	-- remove old config
	for instance, _ in pairs(self.clientConfig) do
		self.clientConfig[instance][client] = nil
	end
	
	local clientinstances = ""
	for _, instance in pairs(instances) do
		if NS:IsValidInstance(instance) then
			self.clientConfig[instance][client] = true
			
			clientinstances = clientinstances .. " " .. instance
		end
	end
	
	self:Debug("UpdateClientConfigData: " .. client .. " searches " .. clientinstances)
end

-- remote message processing
function Communication:SendRemoteHit(instance, msg, author)
	self:Debug("SendRemoteHit")
	if not self.ready or not next(self.clients) then
		self:Debug("SendRemoteHit: aborting - comm " .. (self.ready and "ready" or "not ready") .. " and " .. (next(self.clients) and "has clients" or "has no clients"))
		return
	end

	for client, _ in pairs(self.clientConfig[instance]) do
		self:SendUserData(client, author, msg)
	end
end

-- communication

-- some new partner requires our info date
function Communication:SendInfoData(partner)
	self:Debug("SendInfoData to " .. tostring(partner))
	if not self.partners[partner] then
		self:Debug("SendInfoData: invalid partner")
		return
	end

	local data = {
		msgtype     = INFODATA,
		sender      = Addon.PlayerName,
		quality     = self.quality,
		connections = self.numClients,
	}
	
	self:SendData(partner, data)	
end

-- inform a client about a match
function Communication:SendUserData(client, author, message)
	self:Debug("SendUserData: client - " .. tostring(client) .. " / author - " .. tostring(author) .. " / message - " .. tostring(message))
	if not self.clients[client] then
		self:Debug("SendUserData: invalid client")
		return
	end
	
	local data = {
		msgtype     = USERDATA,
		sender      = Addon.PlayerName,
	}
	
	local id = self.serverCache:GetCacheID(author, message)
	
	local clientInformed = false
	 
	if id then
		self:Debug("SendUserData: msg found cached in line " .. tostring(id))
		clientInformed = self.serverCache:GetValidateCacheID(client, id)
		self:Debug("SendUserData: client was " .. (clientInformed and "informed" or "not informed"))
	else
		id = self.serverCache:CacheMessage(author, message)
		self:Debug("SendUserData: msg stored cached in line " .. tostring(id))
	end
	
	if not id or not clientInformed then
		data.author  = author
		data.message = message
	end
	
	data.id = id
	
	self:SendData(client, data)

	if not clientInformed then
		self.serverCache:SetValidateCacheID(client, id)
		self:Debug("SendUserData: cache line validated for client")
	end
end

function Communication:SendGrantServerRequest(server)
	self:Debug("SendGrantServerRequest " .. tostring(server))
	-- we do not connect unless we are really monitoring any channels
	if not self:RequiresServer() then
		self:Debug("SendGrantServerRequest: no server needed")
		return
	end
	
	-- server is not in the list of our partners
	if not self.partners[server] then
		self:Debug("SendGrantServerRequest: invalid partner")
		return
	end
	
	-- already got the server
	if self.server == server then
		self:Debug("SendGrantServerRequest: is server already")
		return
	end

	-- keep track of server request
	self.requested = server
	
	local data = {
		msgtype     = SERVERREQUEST,
		sender      = Addon.PlayerName,
	}
	
	self:SendData(server, data)			
end

function Communication:SendGrantServerReply(client, granted, reason)
	self:Debug("SendGrantServerReply")
	-- client is not in the list of our partners
	if not self.partners[client] then
		self:Debug("SendGrantServerReply: partner invalid as client " .. tostring(client))
		return
	end
	
	local data = {
		msgtype     = SERVERREPLY,
		sender      = Addon.PlayerName,
		granted     = granted,
		reason      = reason,
	}
	
	self:Debug("SendGrantServerReply: client " .. tostring(client) .. " is granted=" .. tostring(data.granted) .. " (reason=" .. tostring(data.reason) .. ")")
	
	self:SendData(client, data)		
end

-- there is no monitoring active, so we drop the server
-- we dont have to send this when the server quality goes down to 0 (no more tracked channels) 
-- the server takes care of that itself
function Communication:SendDropServer()
	self:Debug("SendDropServer")
	-- no server to drop
	if not self.server then
		self:Debug("SendDropServer: no server")
		return
	end
	
	local data = {
		msgtype     = DROPSERVER,
		sender      = Addon.PlayerName,
	}
	
	self:SendData(self.server, data)		
end

-- for some reason we kick out a client
-- we do not explicitely drop clients when leaving the tracked channels
-- the clients can do that themselves when connection quality drops to 0
-- in that case they dont even send a DropServer message, 
-- since the server took care of that already when quality dropped to 0
function Communication:SendDropClient(client)
	self:Debug("SendDropClient")
	-- we do not have a connection to this client anyway
	if not self.clients[client] then
		self:Debug("SendDropClient: invalid client")
		return
	end	

	local data = {
		msgtype     = DROPCLIENT,
		sender      = Addon.PlayerName,
	}
	
	self:SendData(client, data)	
end

-- send info which instances to track with which keywords (and lfg keywords too)
function Communication:SendConfigData()
	self:Debug("SendConfigData")
	if not self.server then
		self:Debug("SendConfigData: no server")
		return
	end
	
	local data = {
		msgtype     = CONFIGDATA,
		sender      = Addon.PlayerName,
	}

	local instances = {}
	
	for instance, _ in Addon:IterateMonitoredInstances() do
		self:Debug("SendConfigData: instance " .. tostring(instance))
		tinsert(instances, instance)
	end
	
	if #instances > 0 then
		data.instances = instances
	end
	
	self:SendData(self.server, data)
end

-- request config data from client
function Communication:SendConfigDataRequest(client)
	self:Debug("SendConfigDataRequest to " .. tostring(client) )
	if not self.clients[client] then
		self:Debug("SendConfigDataRequest: invalid client")
		return
	end

	local data = {
		msgtype     = CONFIGREQUEST,
		sender      = Addon.PlayerName,
	}
	
	self:SendData(client, data)	
end

-- inform all valid receivers that are not already partners that we are ready
function Communication:UpdateAddonReady()
	self:Debug("UpdateAddonReady")

	-- remove pending chars that are not in friend or bnet friend list
	for toon, _ in pairs(self.pending) do
		if not self.friends[toon] and not self.bnetfriends[toon] then
			self.pending[toon] = nil
		end
	end
	
	if not self.ready then
		self:Debug("UpdateAddonReady: abort since we are not ready")
		return
	end

	self:BroadcastAddonReady(self.ready)
end

function Communication:FilterReceiverForAddonReady(receiver)
	if self.pending[receiver] then
		return false
	end
	
	self.pending[receiver] = true
	
	return true
end

-- make sure there is no unnecessary communication in broadcasts
-- send to guild as broadcast and only send to friends that are not in the guild
-- maintain list of online friends
function Communication:BroadcastAddonReady(ready)
	self:Debug("BroadcastAddonReady")
	local data = {
		msgtype     = READYFORCOMM,
		sender      = Addon.PlayerName,
		ready       = ready,
	}
	
	self:BroadcastData(data, self.FilterReceiverForAddonReady)
end

-- notify all partners about changes in the info data (quality, num clients)
function Communication:BroadcastInfoData()
	self:Debug("BroadcastInfoData")
	self.broadcastTimer = nil
				
	local data = {
		msgtype     = INFODATA,
		sender      = Addon.PlayerName,
		quality     = self.quality,
		connections = self.numClients,
	}
	
	for k, v in pairs(data) do
		self:Debug("BroadcastInfoData data " .. tostring(k) .. "=" .. tostring(v))
	end
	
	self:BroadcastData(data)
end

function Communication:BroadcastData(data, fctFilterReceiver)
	if type(data) ~= "table" then
		self:Debug("BroadcastData: rejected - no or invalid data")
		return
	end

	local serializeddata = self:Serialize(data)

	-- first we communicate via broadcast to guild
	self:Debug("BroadcastData: to guild")
	self:SendCommMessage(Addon.MODNAME, serializeddata, "GUILD")

	-- then to all friends that are not in the guild
	for friend, _ in pairs(self.friends) do
		if not self.guildmates[friend] then
			self:Debug("BroadcastData: 1:1 to friend " .. friend)
			if not fctFilterReceiver or fctFilterReceiver(self, friend, data) then
				-- READYFORCOMM initializes communication and must be sent to valid partners even if they are not yet in the partner list
				self:SendData(friend, serializeddata, true, data.msgtype == READYFORCOMM)
			end
		end
	end

	-- last to all bnet friends that are not in the guild and have not already been contacted as direct friend
	for bnetfriend, _ in pairs(self.bnetfriends) do
		if not self.guildmates[bnetfriend] and not self.friends[bnetfriend] then
			self:Debug("BroadcastData: 1:1 to bnetfriend " .. bnetfriend)
			if not fctFilterReceiver or fctFilterReceiver(self, bnetfriend, data) then
				-- READYFORCOMM initializes communication and must be sent to valid partners even if they are not yet in the partner list
				self:SendData(bnetfriend, serializeddata, true, data.msgtype == READYFORCOMM)
			end
		end
	end
end

function Communication:SendData(receiver, data, isSerialized, force)
	if type(data) ~= "table" then
		if not isSerialized or type(data) ~= "string" then
			self:Debug("SendData: rejected - no or invalid data")
			return
		end
	end

	if not self.partners[receiver] and not force then
		self:Debug("SendData to " .. tostring(receiver) .. " rejected")
		return
	end
	
	local serializeddata = data
	
	if not isSerialized then
		serializeddata = self:Serialize(data)
	end
	
	self:Debug("SendData to " .. tostring(receiver))
	self:SendCommMessage(Addon.MODNAME, serializeddata, "WHISPER", receiver)
end

-- callback for received messages
function Communication:OnCommReceive(prefix, msgs, distribution, target)
	-- shouldn't happen, which means we got to test for it
	if not self.ready then
		return
	end
	
	-- deserialize
	self:Debug("OnCommReceive: deserialize data (sent on distri chan " .. tostring(distribution) .. ")")
	
	local success, data = self:Deserialize(msgs)
	
	if not success then
		self:Debug("OnCommReceive: data corrupt")
		return
	end
	
	local messagetype = data.msgtype
	
	self:Debug("OnCommReceive: msg of type " .. tostring(messagetype))
	
	-- check if partner is valid
	-- TODO: supresses reject!!! fix it
	if not self:IsValidPartner(data.sender) then
		self:Debug("OnCommReceive: invalid sender " .. tostring(data.sender))
		return
	end
	
	-- process message
	if messagetype == READYFORCOMM then
		self:HandleReadyForComm(data)
	elseif messagetype == INFODATA then
		self:HandleInfoData(data)
	elseif messagetype == SERVERREQUEST then
		self:HandleServerRequest(data)
	elseif messagetype == SERVERREPLY then
		self:HandleServerReply(data)
	elseif messagetype == CONFIGREQUEST then
		self:HandleConfigRequest(data)
	elseif messagetype == CONFIGDATA then	
		self:HandleConfigData(data)
	elseif messagetype == USERDATA then
		self:HandleUserData(data)
	elseif messagetype == DROPSERVER then
		self:HandleDropServer(data)
	elseif messagetype == DROPCLIENT then
		self:HandleDropClient(data)
	end

end

function Communication:HandleReadyForComm(data)
	self:Debug("HandleReadyForComm: received request")
	if not data then
		self:Debug("HandleReadyForComm: no data")
		return
	end
	
	if data.ready == true then
		-- check if partner is valid
		if not self:IsValidPartner(data.sender) then
			self:Debug("HandleReadyForComm: invalid sender " .. tostring(data.sender))
			return
		end
		
		if not self.partners[data.sender] then
			-- insert sender as partner
			self.partners[data.sender] = {
				timestamp   = time(),
				quality     = 0,
				connections = 0,
			}
		else
			-- already registered
			self:Debug("HandleReadyForComm: already registered " .. tostring(data.sender))
			-- we continue here because if sender did /reloadui they will starve at this point
			-- return
		end
		
		self:Debug("HandleReadyForComm: register as partner " .. tostring(data.sender))
		-- if a new partner registers we send it our info data
		self:SendInfoData(data.sender)
	else
		self:Debug("HandleReadyForComm: unregister as partner " .. tostring(data.sender))
		-- remove partner when comm goes down
		self.partners[data.sender] = nil
		
		if self.clients[data.sender] then
			self:DisconnectClient(data.sender)
		end
		
		if self.server == data.sender then
			self:ResetServer()
			
			self:UpdateRemoteMonitoring()
		end
	end
end

function Communication:HandleInfoData(data)
	self:Debug("HandleInfoData: received request")
	if not data then
		self:Debug("HandleInfoData: no data")
		return
	end
	self:Debug("HandleInfoData: sender " .. tostring(data.sender))

	-- after initial READYFORCOMM msg receiver send us their info data and we build our list of partners by this
	if not self.partners[data.sender] then
		self:Debug("HandleInfoData: added as partner ")
		-- insert sender as partner
		self.partners[data.sender] = {
			timestamp = time(),
		}
		-- reset possible pending ready hand out
		self.pending[data.sender] = nil
	end
	
	self.partners[data.sender].quality     = data.quality
	self.partners[data.sender].connections = data.connections
	
	if data.sender == self.server then
		self:Debug("HandleInfoData: check server")
		-- check if server is still working for us
		self:CheckServer()
	elseif data.quality > 1 and self:RequiresServer() then
		self:Debug("HandleInfoData: new server required -> UpdateRemoteMonitoring")
		-- source is potential server which we are in need of
		self:UpdateRemoteMonitoring()
	elseif data.quality > 1 and next(self.clients) and self.clients[data.sender] then
		-- client moved into a city, so we stop remote monitoring for it
		self:DisconnectClient(data.sender)
	elseif data.quality > 1 and next(self.clients) then
		self:Debug("HandleInfoData: other potential server, check imbalances")
		-- we work as server so we check if our load is too high compared to other potential servers
		if #self.clients > data.connections + MAX_IMBALANCE then
			self:Debug("HandleInfoData: rebalancing required")
			
			-- need to rebalance			
			local numLocalClients = #self.clients
			
			local numTotalClients = numLocalClients
			local numTotalServers = 1
			
			local total
			
			for partner, info in self.partners do
				if info.quality > 1 then
					numTotalClients = numTotalClients + partner.connections
					numTotalServers = numTotalServers + 1
				end
			end
			
			local keep = math_ceil(numTotalClients/numTotalServers)
			
			-- throw out the oldest connections
			local clients = {}
			for client, since in pairs(self.clients) do
				tinsert(clients, client)
			end
			
			table_sort(clients, self.IsOlderClient)
			
			for i = keep+1, numLocalClients do
				self:DropClient(clients[i])
			end
		end
	end
end

function Communication:HandleServerRequest(data)
	self:Debug("HandleServerRequest: received request")
	if not data then
		self:Debug("HandleServerRequest: no data")
		return
	end
	
	local granted, reason = self:ConnectionRequest(data.sender)
	
	self:SendGrantServerReply(data.sender, granted, reason)	
end

function Communication:HandleServerReply(data)
	self:Debug("HandleServerReply: received request")
	if not data then
		self:Debug("HandleServerReply: no data")
		return
	end

	-- that's not my cow! ... erm... server!
	if data.sender ~= self.requested then
		self:Debug("HandleServerReply: reply by wrong server " .. tostring(data.sender))
		return
	end
	
	-- reset request variable
	self.requested = nil

	self:Debug("HandleServerReply: granted " .. tostring(data.granted))
	
	if data.granted == true then
		self:Debug("HandleServerReply: access granted by server " .. tostring(data.sender))
		self.server = data.sender
		
		self:SendConfigData()
		
		Addon:UpdateLabel()
	else
		self:Debug("HandleServerReply: access rejected by server " .. tostring(data.sender) .. " " .. tostring(data.reason))
		if data.reason == REASONREJECT then
			self:Debug("HandleServerReply: blacklist server")
			-- we are rejected because we are no valid partner to the other side
			-- since we are valid to our guild mates this must be a one-way friendship
			-- we cannot maintain any communication with this partner
			this.blacklist[data.sender] = true
			this.partners[data.sender] = nil
		end
		
		-- try again
		self:UpdateRemoteMonitoring()
	end
end

function Communication:HandleConfigRequest(data)
	self:Debug("HandleConfigRequest: received request")
	if not data then
		self:Debug("HandleConfigRequest: no data")
		return
	end
	
	-- apparently the server hasn't received our config data -> resend it
	if self.server == data.sender then
		self:SendConfigData()
	end
end

function Communication:HandleConfigData(data)
	self:Debug("HandleConfigData: received request")
	if not data then
		self:Debug("HandleConfigData: no data")
		return
	end

	for k, v in pairs(data.instances) do
		self:Debug("HandleConfigData: instances " .. " key " ..tostring(k) .. " value " .. tostring(v))		
	end
	
	-- store config data
	self:Debug("HandleConfigData: update config data")
	self:UpdateClientConfigData(data.sender, data.instances)
end

function Communication:HandleUserData(data)
	self:Debug("HandleUserData: received request")
	if not data then
		self:Debug("HandleUserData: no data")
		return
	end

	if not data.id then
		self:Debug("HandleUserData: cache id missing")
		return
	end
	
	if not self.server or data.sender ~= self.server then
		self:Debug("HandleUserData: invalid sender or no server")
		return
	end
	
	local message = data.message
	local author  = data.author
	
	if message then
		self:Debug("HandleUserData: caching msg in cache line " .. tostring(data.id))
		-- cache message for further reference
		self.clientCache:CacheMessage(data.id, message, author)
	else
		self:Debug("HandleUserData: get cached msg in cache line " .. tostring(data.id))
		-- we just received a reference id so we have to retrieve the actual data
		author, message = self.clientCache:GetMessage(data.id)
	end

	-- process the message locally
	if message and author then
		self:Debug("HandleUserData: process remote msg '" .. tostring(message) .. "' by author " .. tostring(author))
		Addon:ProcessMessage(message, author, data.sender)
	else
		self:Debug("HandleUserData: user data missing msg '" .. tostring(message) .. "' by author " .. tostring(author))	
	end
end

function Communication:HandleDropServer(data)
	self:Debug("HandleDropServer: received request")
	if not data then
		self:Debug("HandleDropServer: no data")
		return
	end

	self:DisconnectClient(data.sender)
end

function Communication:HandleDropClient(data)
	self:Debug("HandleDropClient: received request")
	if not data then
		self:Debug("HandleDropClient: no data")
		return
	end

	if data.sender == self.server then
		self:Debug("HandleDropClient: disconnected from server")
		self:ResetServer()
		
		self:UpdateRemoteMonitoring()			
	end
end

function Communication:IsOlderClient(a, b)
	if not self.clients[a] then
		return false
	end

	if not self.clients[b] then
		return true
	end
	
	return self.clients[a] < self.clients[b]
end

-- test
function Communication:Debug(msg)
	Addon:Debug("(Communication) " .. msg)
end
