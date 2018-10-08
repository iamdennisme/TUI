local _G = _G

-- addon name and namespace
local ADDON, NS = ...

-- the plugin name
local PLUGIN = "Forwarder"

-- local functions
local strlower       = strlower
local strfind        = strfind
local strupper       = strupper
local string_format  = string.format
local tinsert        = table.insert
local table_sort     = table.sort
local pairs          = pairs
local time           = time
local floor          = floor
local gsub           = gsub

local GetChannelList = _G.GetChannelList

local _

-- setup libs
local LibStub = LibStub

-- get translations
local L = LibStub:GetLibrary("AceLocale-3.0"):GetLocale(ADDON)

-- addon and locals
local Addon = LibStub:GetLibrary("AceAddon-3.0"):NewAddon(ADDON, "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")

local Communication = nil
local Channel       = nil

-- addon constants
Addon.MODNAME   = "BRFForwarder"
Addon.FULLNAME  = "Broker: Raid Finder - Forwarder"
Addon.SHORTNAME = "BRF-Forwarder"

-- broker raid finder plugin host
local BRFGetPluginHost = _G.BRFGetPluginHost

-- infrastcructure
function Addon:OnInitialize()
	-- init variables
	self.readyToFwd = false
	
	-- the active flag
	self.active = false
	
	-- label text
	self.label = "F"
	
	-- debugging
	self.debug = false
	
	self:RegisterChatCommand("brfforwarder", "ChatCommand")
	self:RegisterChatCommand("brffwd", "ChatCommand")
	
	-- plugin host
	self.host = nil	
end

function Addon:OnEnable()
	-- set module references
	Channel       = self:GetModule("Channel")
	Communication = self:GetModule("Communication")

	self.PlayerName = UnitName("player")
	
	self.language = GetDefaultLanguage("player")
	
	self:RegisterPlugin()	
end

function Addon:OnDisable()			
	-- unregister the plugin
	self:UnregisterPlugin()
end

function Addon:IsValidHost(host)
	-- check interface
	if type(host) == "table" and 
		type(host.RegisterPlugin) == "function" and 
		type(host.UnregisterPlugin) == "function" and 
		type(host.UpdateLabel) == "function" and 
		type(host.ProcessMessage) == "function" and 
		type(host.IsMonitoredChannel) == "function" and 
		host.EVENT_MATCH_LFG then
		return true
	end
	
	return false
end

function Addon:RegisterPlugin()
	self:Debug("BrokerRaidFinder PluginHost " .. (type(BRFGetPluginHost) == "function" and L["found"] or L["not found"]))
	
	local host = BRFGetPluginHost()
	
	if not self:IsValidHost(host) then
		self:Debug(L["Aborted plug-in registration. Invalid plug-in host."])
		return
	end
	
	if host:RegisterPlugin(self) then
		self:Debug(L["Plug-in registered with BrokerRaidFinder"])
		self.host = host
		
		self:UpdateSetup()
	else
		self:Output(L["Plug-in failed to register with BrokerRaidFinder"])
	end
end

function Addon:UnregisterPlugin()
	if self.host then
		if host.UnregisterPlugin then
			self.host:UnregisterPlugin(self)
		end
		
		self:Debug(L["Plug-in unregistered."])
		
		self.host = nil
		
		self:UpdateSetup()
	end
end

function Addon:UpdateSetup()
	-- update ready to send
	self:CheckReadyToForward()
		
	if self.host and self:IsActive() then
		-- setup event handlers
		self:RegisterEventHandlers()

		-- setup comm
		Communication:SetActive(true)
				
		-- setup channel
		Channel:SetActive(true)
	else
		-- shutdown channel
		Channel:SetActive(false)
		
		-- shutdown comm
		Communication:SetActive(false)

		-- shutdown event handlers
		self:UnregisterEventHandlers()		
	end
end

function Addon:RegisterEventHandlers()
    self:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
end

function Addon:UnregisterEventHandlers()
    self:UnregisterEvent("CHAT_MSG_CHANNEL_NOTICE")
end

function Addon:ChatCommand(input)
    if input then  
		args = NS:GetArgs(input)
		
		self:TriggerAction(unpack(args))
	        
        NS:ReleaseTable(args)
	else
		self:TriggerAction("help")
	end
end

function Addon:TriggerAction(action, ...)
    local args = NS:NewTable(...)

	if action == "debug" then
		if args[1] == "on" then
			self:Output("debug mode turned on")
			self.debug = true
		end
		if args[1] == "off" then
			self:Output("debug mode turned off")
			self.debug = false
		end
	elseif action == "version" then
		-- print version information
		self:PrintVersionInfo()
	elseif action == "fwd" then
		if args[1] and args[2] then
			local msg = ""
			for i = 2, #args do
				msg = msg .. args[i] .. " "
			end

			Channel:ForwardMessage(msg, args[1])
		else
			self:Output("forward is missing an argument")
		end
	elseif action == "toggle" then
		self:ToggleActive()
		self:Output("Plugin is " .. (self:IsActive() and "activated" or "deactivated"))
	elseif action == "on" then
		self:SetActive(true)
		self:Output("Plugin is " .. (self:IsActive() and "activated" or "deactivated"))
	elseif action == "off" then
		self:SetActive(false)
		self:Output("Plugin is " .. (self:IsActive() and "activated" or "deactivated"))
	elseif action == "register" then
		self:RegisterPlugin()
		self:Output("Plugin is " .. (self.host and "registered" or "not registered"))
	elseif action == "unregister" then
		self:UnregisterPlugin()
		self:Output("Plugin is " .. (self.host and "registered" or "not registered"))
	elseif action == "status" then
		self:Output("Plugin is " .. (self.host and "registered" or "not registered"))
		self:Output("Plugin is " .. (self:IsActive() and "activated" or "deactivated"))	
		self:Output("Channel ID: " .. tostring(Channel:GetChannelID()))	
		self:Output("Channel name: " .. tostring(Channel:GetChannelName()))	
		self:Output("Channel owner: " .. tostring(Channel:GetOwner()) .. " (self: " .. (self:IsPlayer(Channel:GetOwner()) and "yes" or "no") .. ")")	
		self:Output("Ready to forward: " .. (self:IsReadyToForward() and "yes" or "no"))
		self:Output("Candidates: ")
		for name, _ in Channel:IterateCandidates() do
			self:Output(name)
		end
	else -- if action == "help" then
		-- display help
		self:Output(L["Usage:"])
		self:Output(L["/brfforwarder arg"])
		self:Output(L["/brffwd arg"])
		self:Output(L["Args:"])
		self:Output(L["on - activate forwarding"])
		self:Output(L["off - deactivate forwarding"])
		self:Output(L["version - display version information"])
		self:Output(L["help - display this help"])
	end
    
    NS:ReleaseTable(args)
end

function Addon:UpdateLabelText()
	local old = self.label
	
	local label = "F"
	
	if self:IsActive() then
		if Channel:IsConnected() then
			if self:IsReadyToForward() then
				label = NS:Colorize("White", label)
			else
				if self:IsPlayer(Channel:GetOwner()) then
					label = NS:Colorize("Red", label)
				elseif Channel:IsOwnerIgnored() then
					label = NS:Colorize("Red", label)
				elseif Channel:UsingFallbackChannel() then
					label = NS:Colorize("Yellow", label)
				else
					label = NS:Colorize("Green", label)
				end
			end
		else
			label = NS:Colorize("Red", label)
		end
	else	
		label = NS:Colorize("GrayOut", label)
	end
	
	if label ~= self.label then
		self.label = label
		
		if self.host then
			self.host:UpdateLabel()
		end
	end
end

-- implement plugin interface
function Addon:GetPluginName()
	return PLUGIN
end

function Addon:GetPluginDescription()
	return L["Plugin adds support to forward LFG messages over a shared channel. This allows cross addon communication for all users of this plugin."]
end

-- keep it short (1-2 chars) - this is additional to the label text of the host
function Addon:GetLabelText()	
	return self.label
end

function Addon:GetTooltipMessages()
	local messages = {}
	
	if self:IsActive() then
		if Channel:IsConnected() then
			if self:IsReadyToForward() then
				tinsert(messages, NS:Colorize("White", L["Operation paused in major city."]))
			else
				if self:IsPlayer(Channel:GetOwner()) then
					tinsert(messages, NS:Colorize("Red", L["No forwarder available."]))
				elseif Channel:IsOwnerIgnored() then
					tinsert(messages, NS:Colorize("Red", L["Current channel owner is on ignore list."]))
				elseif Channel:UsingFallbackChannel() then
					tinsert(messages, NS:Colorize("Yellow", L["Using fallback channel"] .. " " .. tostring(self.invalids) .. "."))
				else
					tinsert(messages, NS:Colorize("Green", L["Message forwarding active."]))
				end
			end
		else
			tinsert(messages, NS:Colorize("Red", L["Not connected to forwarding channel."]))
		end
	end
	
	return messages
end

function Addon:SetActive(active)
	if active ~= self.active then
		self.active = active

		self:UpdateSetup()
		self:UpdateLabelText()
	end
end

function Addon:IsActive()
	return self.active
end

function Addon:HandleEvent(event, data)
	if not self:IsActive() or not self:IsPlayer(Channel:GetOwner()) then
		return
	end

	-- event has to be at least EVENT_MATCH_LFG
	if event >= self.host.EVENT_MATCH_LFG then
		data = data or {}
		
		-- restricted data is to be handled locally only and may not be forwarded
		if not data.restricted then
			Channel:ForwardMessage(data.message, data.author)
		end
	end	
end

-- testing
function Addon:Debug(msg)
	if self.debug then
		if ( msg ~= nil and DEFAULT_CHAT_FRAME ) then
			DEFAULT_CHAT_FRAME:AddMessage(self.MODNAME .. " (dbg): " .. msg, 1.0, 0.37, 0.37)
		end		
	end
end

-- event handlers
function Addon:CHAT_MSG_CHANNEL_NOTICE(event, message, sender, language, channelString, target, flags, unknown, channelNumber, channelName)
	self:Debug("CHAT_MSG_CHANNEL_NOTICE: sender " .. tostring(sender) .." msg " .. tostring(message) .. " channelName " .. tostring(channelName) .. " channelNumber " .. tostring(channelNumber) .. " channelString >" .. tostring(channelString) .. "<" )
	
	if message == "YOU_JOINED" or message == "YOU_LEFT" or message == "SUSPENDED" or message == "YOU_CHANGED" then
		self:Debug("CHAT_MSG_CHANNEL_NOTICE: CheckReadyToForward")
		self:CheckReadyToForward()
	end
end

-- message handling
function Addon:ProcessMessage(author, message)
	self:Debug("ProcessMessage")
	
	-- we forwarded the message ourself
	if self:IsPlayer(Channel:GetOwner()) then
		return
	end
	
	-- we read can read the chat anyway
	if self:IsReadyToForward() then
		return
	end
	
	if not self.host then
		self:Debug("ProcessMessage: host missing")
		return
	end
	
	self:Debug("ProcessMessage: ".. tostring(author) .. ": " .. tostring(message))
	
	-- process message when not in town
	if author and message then
		self.host:ProcessMessage(self, message, author, self.owner)
	end
end

-- user functions
function Addon:PrintVersionInfo()
    self:Output(L["Version"] .. " " .. NS:Colorize("White", GetAddOnMetadata(ADDON, "Version")))
end

-- settings
function Addon:CheckReadyToForward()
	local wasReady = self.readyToFwd

	local readyToFwd = false
	
	if self.host then
		local channels = {GetChannelList()}
		
		for i=1, #channels, 2 do
			if self.host:IsMonitoredChannel(channels[i]) then
				-- if monitored channel is not just general chat
				if channels[i] == 2 then
					readyToFwd = true
					break
				end
			end
		end		
	end
	
	self:Debug("CheckReadyToForward: " .. tostring(readyToFwd))
	
	if self.readyToFwd ~= readyToFwd then
		self.readyToFwd = readyToFwd
		self:HandleReadyToForwardChanged()
	end
end

function Addon:HandleReadyToForwardChanged()
	if self:IsPlayer(Channel:GetOwner()) then
		-- transfer ownership if we are no longer ready
		if not self:IsReadyToForward() then
			Channel:TryTransferOwnership()
		end
	else
		-- owner is informed about both states: ready and not ready
		Communication:NotifyOwner(Channel:GetOwner())
	end
	
	self:UpdateLabelText()
end

function Addon:IsReadyToForward()
	return self.readyToFwd
end

-- utilities
function Addon:Output(msg)
	if ( msg ~= nil and DEFAULT_CHAT_FRAME ) then
		DEFAULT_CHAT_FRAME:AddMessage(self.MODNAME..": "..msg, 0.6, 1.0, 1.0)
	end
end

function Addon:IsPlayer(char)
	return char == self.PlayerName
end

function Addon:IsChannelOwner()
	return Channel:IsOwner()
end

function Addon:GetLanguage()
	return self.language
end

function Addon:UpdateCharacterState(char, ready)
	Channel:UpdateCharacterState(char, ready)
end

function Addon:NotifyOwnerChanged(owner, old)
	if not self:IsPlayer(old) then
		-- clear pending notifications for old owner
		Communication:CancelPendingNotification()
	end
	
	if not self:IsPlayer(owner) then
		--notify new owner, that we are ready to send
		if self:IsReadyToForward() then
			-- send delayed notification to avoid msg burst on receiver side
			Communication:NotifyOwner(owner, true)
		end
	end
	
	Addon:UpdateLabelText()
end

function Addon:NotifyIgnoredChanged(ignored)
	Addon:UpdateLabelText()	
end
