local _G = _G

-- addon name and namespace
local ADDON, NS = ...

local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON)

local Channel = Addon:NewModule("Channel", "AceEvent-3.0", "AceTimer-3.0")

-- local functions
local tinsert    = table.insert
local tremove    = table.remove
local pairs      = pairs
local next       = next

local JoinTemporaryChannel	= _G.JoinTemporaryChannel
local LeaveChannelByName	= _G.LeaveChannelByName
local DisplayChannelOwner	= _G.DisplayChannelOwner
local SetChannelOwner		= _G.SetChannelOwner
local IsIgnored				= _G.IsIgnored
local ChannelModerate		= _G.ChannelModerate
local SetChannelPassword	= _G.SetChannelPassword
local GetChannelName        = _G.GetChannelName
local GetChannelList        = _G.GetChannelList

local _

-- local constants
local TIMEOUT            = 5

local BRF_CHANNEL_NAME   = "BRFForwarder"
local BRF_CHANNEL_PASS   = "BRFForwarderpass" -- dummy password that should prevent someone stumbling in accidently (non-functional for any security considerations)
local MAX_CHANNEL_OFFSET = 100

-- how long are messages valid in cache
local MAX_CACHE_DURATION = 180

-- max characters per second rate of forwarding messages
local MAX_CPS            = 500

-- messages that could not be forwarded within this time [s] will be dropped
local FORWARD_TIMEOUT    = 10

-- max number of channels
local MAX_CHANNELS       = 10

-- setup
function Channel:OnInitialize()
	-- init constants
	self.MSG_AUTHOR = "Author: "
	self.MSG_BODY   = "Message: "
	self.MSG_SPACE  = " "
	
	-- the channel owner
	self.owner = nil
	
	-- current owner is on ignore list
	self.ignored = false
	
	-- setup player queue of candidates for ownership (players currently in a major city)
	self.candidates = {}
	
	-- setup message cache
	self.cache = {}
			
	self.readyForChannel = false
	
	self:SetActive(false)	
end

function Channel:OnEnable()
	-- we are ready to join channels only after general chat is joined
	self:TestForGeneralChat()
	
	self:RegisterEventHandlers()
end

function Channel:OnDisable()
	self:UnregisterEventHandlers()
	
	self:SetActive(false)

	self:ChannelLeft()
end

function Channel:SetActive(active)
	if self.active ~= active then
		self.active = active
		
		self:SetupChannel()	
	end
end

function Channel:IsActive()
	return self.active
end

function Channel:TestForGeneralChat()
	if self:ReadyForChannel() then
		return
	end
	
	local channels = {GetChannelList()}
	
	for i=1, #channels, 2 do
		-- we assume that channel number 1 is the general chat
		-- if any other addon has displaced general chat there is nothing we can do about it
		if channels[i] == 1 then
			self.readyForChannel = true
		end
	end
	
	if self:ReadyForChannel() then
		-- allow a 3s grace interval in case trade/lfg chat are not joined yet
		self:ScheduleTimer("SetupChannel", 3)
	else
		-- repeat test in 1s
		self:ScheduleTimer("TestForGeneralChat", 1)
	end
end

function Channel:ReadyForChannel()
	return self.readyForChannel
end

function Channel:RegisterEventHandlers()
    self:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
end

function Channel:UnregisterEventHandlers()
    self:UnregisterEvent("CHAT_MSG_CHANNEL_NOTICE")
end

-- channel handling
function Channel:SetupChannel()
	self:Debug("SetupChannel")
	if self:IsActive() == true then
		-- check if initial timeout to join channel has elapsed
		if self:ReadyForChannel() then
			self:JoinChannel()
		else
			-- try again in a sec
			self:ScheduleTimer("SetupChannel", 1)
		end
	else
		self:LeaveChannel()
	end
end

function Channel:JoinChannel()
	self:Debug("JoinChannel")
	if self.channelID then 
		return
	end
	
	if self.joinTimer then
		return
	end
	
	-- check if we already are in the channel befor we try joining it
	if self:IsDefaultChannelActive() then
		return
	end
	
	local offset = ""
	
	if self.invalids then
		offset = tostring(self.invalids)
	end
	
	self.channelName = BRF_CHANNEL_NAME..offset
	
	self.joinTimer = self:ScheduleTimer("JoinTimeout", TIMEOUT)
	
	JoinTemporaryChannel(self.channelName) -- , BRF_CHANNEL_PASS)
	self:Debug("JoinChannel done")	
end

function Channel:ChannelJoined(id)
	self:Debug("ChannelJoined:" .. tostring(id))	
	if not id then
		return
	end

	if self.joinTimer then
		self:CancelTimer(self.joinTimer)
		self.joinTimer = nil
	end

	-- assign channel id
	self.channelID = id
		
	-- set up message queue
	self.sendQueue = {}
	
	-- character counter used to limit message throughput
	self.chars = 0	
	
	-- register required events
	self:RegisterEvent("CHAT_MSG_CHANNEL")
	self:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE_USER")
	self:RegisterEvent("CHAT_MSG_CHANNEL_JOIN")
	self:RegisterEvent("CHAT_MSG_CHANNEL_LEAVE")
	self:RegisterEvent("IGNORELIST_UPDATE")				
	
	-- request channel owner info
	DisplayChannelOwner(self.channelName)	
	
	Addon:UpdateLabelText()
end

function Channel:LeaveChannel()
	self:Debug("LeaveChannel")
	if not self.channelID then 
		return
	end
	
	if self.leaveTimer then
		return
	end
	
	-- assign successor for ownership
	if self:IsOwner() then
		self:TryTransferOwnership()
	end
	
	self.leaveTimer = self:ScheduleTimer("LeaveTimeout", TIMEOUT)
	
	LeaveChannelByName(self.channelName)
	self:Debug("LeaveChannel done")	
end

function Channel:ChannelLeft()
	self:Debug("ChannelLeft")	
	if self.leaveTimer then
		self:CancelTimer(self.leaveTimer)
		self.leaveTimer = nil
	end

	-- unregister events
	self:UnregisterEvent("CHAT_MSG_CHANNEL")	
	self:UnregisterEvent("CHAT_MSG_CHANNEL_NOTICE_USER")
	self:UnregisterEvent("CHAT_MSG_CHANNEL_JOIN")
	self:UnregisterEvent("CHAT_MSG_CHANNEL_LEAVE")	
	self:UnregisterEvent("IGNORELIST_UPDATE")				
	
	-- clear channel data
	self.invalids    = nil
	
	self.channelID   = nil
	self.channelName = nil
	
	-- reset owner info
	self:SetOwner(nil)
	
	Addon:UpdateLabelText()	
end

function Channel:JoinTimeout()
	self.joinTimer = nil

	-- something prevents us from joining the current channel
	if not self.invalids then
		self.invalids = 1
	else
		self.invalids = self.invalids + 1
	end
	
	if self.invalids >= MAX_CHANNEL_OFFSET then
		-- apparently we are unable to enter any channel
		self.invalids = nil
		-- disable plugin
		Addon:SetActive(false)
	else
		-- retry
		self:SetupChannel()
	end	
end

function Channel:LeaveTimeout()
	self.leaveTimer = nil

	-- retry
	self:SetupChannel()
end

function Channel:IsDefaultChannelActive()
	local id = self:CheckChannel(BRF_CHANNEL_NAME)
	
	if id then
		self.channelName = BRF_CHANNEL_NAME
		self:ChannelJoined(id)
		return true
	end
	
	return false
end

function Channel:CheckChannel(channel)
	for i = 1, MAX_CHANNELS do
		id, name = GetChannelName(i)
		if name == channel then
			-- channel exists
			return id
		end
	end
end

-- properties
function Channel:IsConnected()
	return self.channelID ~= nil
end

function Channel:UsingFallbackChannel()
	return self.invalids ~= nil
end

function Channel:IsMonitoredChannel(id)
	return id and id == self.channelID
end

function Channel:GetChannelID()
	return self.channelID
end

function Channel:GetChannelName()
	return self.channelName
end

-- message sending
function Channel:ForwardMessage(msg, author)
	self:Debug("ForwardMessage")
	if not self:IsOwner() then
		self:Debug("ForwardMessage: we are not channel owner - abort")
		return
	end
	
	if not msg then
		self:Debug("ForwardMessage: message missing")
		return
	end

	if not author then
		self:Debug("ForwardMessage: author missing")
		return
	end

	if self:IsCached(msg, author) then
		self:Debug("ForwardMessage: message is cached: " .. msg)
		return
	end

	-- add cache entry
	local timestamp = self:AddToCache(msg, author)
	
	-- review cache for old entries
	self:ReviewCache()
	
	-- assemble message for channel
	local message = self.MSG_AUTHOR .. author .. self.MSG_SPACE .. self.MSG_BODY .. msg

	-- put into message queue
	local entry = {
		message   = message,
		timestamp = timestamp,
	}
	
	tinsert(self.sendQueue, entry)
	self:Debug("ForwardMessage: added msg to queue: " .. entry.message)
	
	self:ProcessMessageQueue()
end

function Channel:ProcessMessageQueue()
	local now = time()

	while #self.sendQueue > 0 and self.chars < MAX_CPS do
		local entry = tremove(self.sendQueue, 1)
		
		-- drop messages to old (to make sure we do not face an ever growing queue)
		if entry.timestamp >= now - FORWARD_TIMEOUT then
			self:Debug("ProcessMessageQueue: sending " .. tostring(entry.message) .. " (" .. tostring(entry.timestamp) .. ")")
			SendChatMessage(entry.message, "CHANNEL", Addon:GetLanguage(), self.channelID)	
	
			-- add up to character count (which is reset once every second)
			self.chars = self.chars + entry.message:len()
		end
	end	
end

function Channel:ResetCharacterCount()
	self.chars = 0
	
	-- in case there are still unsent messages in the queue
	self:ProcessMessageQueue()
end

-- event handlers
function Channel:CHAT_MSG_CHANNEL(event, message, sender, arg3, arg4, arg5, arg6, arg7, id)
	if self:IsMonitoredChannel(id) then
		self:HandleChannelMessage(message, sender)
	end
end

function Channel:CHAT_MSG_CHANNEL_NOTICE_USER(event, message, sender, language, channelString, target, flags, arg7, channelNumber, channelName)
	self:Debug("CHAT_MSG_CHANNEL_NOTICE_USER: sender " .. tostring(sender) .." chan " .. tostring(channelName) .. " #" .. tostring(channelNumber))
	if self:IsMonitoredChannel(channelNumber) then
		self:Debug("CHAT_MSG_CHANNEL_NOTICE_USER: message " .. tostring(message))
		if message == 'OWNER_CHANGED' then
			self:SetOwner(sender)
		elseif message == 'CHANNEL_OWNER' then
			self:SetOwner(sender)
		elseif message == "PLAYER_NOT_FOUND" then
			-- only action we perform in this addon to trigger this is to pass the ownership
			
			-- if the player is not found we remove it from the list of candidates
			self:RemoveCandidate(target)
			
			-- try again
			self:TryTransferOwnership()
		end
	end
end

function Channel:CHAT_MSG_CHANNEL_JOIN(event, arg1, sender, arg3, channelString, arg5, arg6, arg7, channelNumber, channelName)
	self:Debug("CHAT_MSG_CHANNEL_JOIN: sender " .. tostring(sender) .." chan " .. tostring(channelName) .. " #" .. tostring(channelNumber))
	if self:IsMonitoredChannel(channelNumber) then
		self:Debug("CHAT_MSG_CHANNEL_JOIN: user " .. tostring(sender) .." joined")
		-- new user invalidates the whole cache because the user doesn't know any of the messages
		self:ClearCache()
	end
end

function Channel:CHAT_MSG_CHANNEL_LEAVE(event, arg1, sender, arg3, channelString, arg5, arg6, arg7, channelNumber, channelName)
	self:Debug("CHAT_MSG_CHANNEL_LEAVE: sender " .. tostring(sender) .." chan " .. tostring(channelName) .. " #" .. tostring(channelNumber))
	if self:IsMonitoredChannel(channelNumber) then
		self:Debug("CHAT_MSG_CHANNEL_LEAVE: user " .. tostring(sender) .." left")
		-- player leaving the chat will be removed from list of candidates
		self:RemoveCandidate(sender)
	end
end

function Channel:CHAT_MSG_CHANNEL_NOTICE(event, message, sender, language, channelString, target, flags, unknown, channelNumber, channelName)
	self:Debug("CHAT_MSG_CHANNEL_NOTICE: sender " .. tostring(sender) .." msg " .. tostring(message) .. " channelName " .. tostring(channelName) .. " channelNumber " .. tostring(channelNumber) .. " channelString >" .. tostring(channelString) .. "<" )
	
	if channelName == self.channelName then
		if message == "YOU_JOINED" then
			self:ChannelJoined(channelNumber)
		elseif message == "YOU_LEFT" then
			self:ChannelLeft()
			
			-- in case we left the channel 'involuntary'
			self:SetupChannel()
		end
	end
end

function Channel:IGNORELIST_UPDATE()
	self:Debug("IGNORELIST_UPDATE")
	
	self:CheckOwnerIgnored()
end

-- message handling
function Channel:HandleChannelMessage(msg, sender)
	self:Debug("HandleChannelMessage: by sender " .. tostring(sender))
	if Addon:IsPlayer(sender) then
		self:Debug("HandleChannelMessage: no need to handle self")
		return
	end

	-- get original author
	local author = msg:gsub(self.MSG_AUTHOR .. "(.-)" .. self.MSG_SPACE .. ".*", "%1")
	
	-- get original message
	local message = msg:gsub(".-" .. self.MSG_BODY .. "(.*)", "%1")
	
	Addon:ProcessMessage(author, message)
end

-- cache handling
function Channel:ClearCache()
	for k in pairs(self.cache) do
		self.cache[k] = nil
	end
end

function Channel:IsCached(msg, author)
	return self.cache[author] and self.cache[author].cache[msg]
end

function Channel:AddToCache(msg, author)
	if self:IsCached(msg, author) then
		return self.cache[author].cache[msg]
	end

	local now = time()
	
	if not self.cache[author] then
		self.cache[author] = {
			lines = 0,
			cache = {},
		}
	end
	
	self.cache[author].cache[msg] = now
	self.cache[author].lines = self.cache[author].lines + 1
	
	return now
end

function Channel:ReviewCache()
	local now    = time()
	local oldest = now - MAX_CACHE_DURATION
	
	-- if the oldest timestamp in cache is inside the time frame we dont have to check
	if self.oldestCacheStamp and self.oldestCacheStamp > oldest then
		return
	end
	
	self.oldestCacheStamp = now
	
	for author, messages in pairs(self.cache) do
		for msg, timestamp in pairs(messages.cache) do
			if timestamp < oldest then
				self:RemoveFromCache(msg, author)
			elseif timestamp < self.oldestCacheStamp then
				self.oldestCacheStamp = timestamp
			end
		end
	end
end

function Channel:RemoveFromCache(msg, author)
	if not self:IsCached(msg, author) then
		return
	end
		
	if self.cache[author].lines == 1 then
		self.cache[author] = nil
	else
		self.cache[author].cache[msg] = nil
		self.cache[author].lines = self.cache[author].lines - 1
	end
end

-- owner handling
function Channel:IsOwner()
	return Addon:IsPlayer(self.owner)
end

function Channel:TryTransferOwnership()
	if not self:IsOwner() then
		return
	end
	
	local candidate = self:SelectCandidate()
	
	if candidate then
		SetChannelOwner(self.channelName, candidate);
	end
end

function Channel:SetOwner(owner)
	if owner == "" then
		owner = nil
	end
	
	self:Debug("SetOwner: " .. tostring(owner))
	if self.owner == owner then
		return
	end

	local old = self.owner
	
	-- clean up data if we have been the owner so far
	if self:IsOwner() then
		self:ClearCache()
		self:ClearCandidates()
		
		-- clear send queue
		for k in pairs(self.sendQueue) do
			self.sendQueue[k] = nil
		end
			
		-- cancel timer to reset character count
		self:CancelTimer(self.cpsTimer)
	end
	
	self.owner = owner

	if self:IsOwner() then
		-- set default password in case some clown changed it
		-- SetChannelPassword(self.channelName, BRF_CHANNEL_PASS)
		
		-- reset character counter
		self:ResetCharacterCount()
		
		-- timer to reset character counter
		self.cpsTimer = self:ScheduleRepeatingTimer("ResetCharacterCount", 1)
		
		-- if we have been assigned ownership, but we are not inside a city try to pass on the ownership right away
		if not Addon:IsReadyToForward() then
			self:TryTransferOwnership()
		end		
	else				
		self:CheckOwnerIgnored()
	end
	
	Addon:NotifyOwnerChanged(owner, old)
end

function Channel:GetOwner()
	return self.owner
end

function Channel:CheckOwnerIgnored()
	self:SetOwnerIgnored(self.owner and IsIgnored(self.owner))
end

function Channel:SetOwnerIgnored(ignored)
	if self.ignored ~= ignored then
		self.ignored = ignored
		
		Addon:NotifyIgnoredChanged(ignored)
	end
end

function Channel:IsOwnerIgnored()
	return self.ignored
end

-- handle channel owner candidates
function Channel:UpdateCharacterState(char, ready)
	self:Debug("UpdateCharacterState: char " .. tostring(char) .. " ready " .. tostring (ready))
	if ready then
		self:Debug("UpdateCharacterState: SetCandidate " .. tostring(char))
		self:SetCandidate(char)
		
		if self:IsOwner() and not Addon:IsReadyToForward() then
			self:Debug("UpdateCharacterState: TryTransferOwnership")
			self:TryTransferOwnership()
		end
	else
		self:Debug("UpdateCharacterState: RemoveCandidate " .. tostring(char))
		self:RemoveCandidate(char)
	end
end

function Channel:SetCandidate(char)
	if self.candidates[char] then
		return
	end
	
	self.candidates[char] = time()
end

function Channel:RemoveCandidate(char)
	self.candidates[char] = nil
end

function Channel:ClearCandidates()
	for k in pairs(self.candidates) do
		self.candidates[k] = nil
	end
end

function Channel:IterateCandidates()
	return pairs(self.candidates)
end

-- selects oldest char entry (newest entry, if param is true)
function Channel:SelectCandidate(newest)
	local candidate = nil
	local since     = nil
	
	local better    = nil
	
	if newest then
		better = function(a, b) return a > b end
	else
		better = function(a, b) return a < b end
	end
	
	for name, timestamp in pairs(self.candidates) do
		if not since or better(timestamp, since) then
			candidate = name
			since     = timestamp
		end
	end	
	
	return candidate
end

-- test
function Channel:Debug(msg)
	Addon:Debug("(Channel) " .. msg)
end
