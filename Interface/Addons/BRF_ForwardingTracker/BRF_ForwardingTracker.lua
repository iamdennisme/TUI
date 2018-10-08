local _G = _G

-- addon name and namespace
local ADDON, NS = ...

-- the plugin name
local PLUGIN = "Forwarding Tracker"

-- local functions
local strfind = strfind
local tinsert = table.insert
local pairs   = pairs
local time    = time

local GetChannelList  = _G.GetChannelList

local _

-- LFG Forwarder data

-- global channel name
local LFW_CHANNEL_NAME = _G.LFW_CHANNEL_NAME
local TFW_CHANNEL_NAME = _G.TFW_CHANNEL_NAME

-- taken directly from LFGForwarder.lua
local LFW_SEP_R = "_%$"
local LFW_PATTERN_R = "^"..LFW_SEP_R.."(%d+)([^%d]+)"..LFW_SEP_R.."(.+)"..LFW_SEP_R.."(%x%x%x%x%x%x)%$$"

-- report lack of received data after this time [s]
local TRACKING_TIMEOUT = 180

-- setup libs
local LibStub = LibStub

-- get translations
local L = LibStub:GetLibrary("AceLocale-3.0"):GetLocale(ADDON)

-- addon and locals
local Addon = LibStub:GetLibrary("AceAddon-3.0"):NewAddon(ADDON, "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")

-- addon constants
Addon.MODNAME   = "BRFForwardingTracker"
Addon.FULLNAME  = "Broker: Raid Finder - Forwarding Tracker"
Addon.SHORTNAME = "BRF-ForwardingTracker"

Addon.LFG_FORWARDER   = "lfg"
Addon.TRADE_FORWARDER = "trade"

-- broker raid finder plugin host
local BRFGetPluginHost = _G.BRFGetPluginHost

-- infrastcructure
function Addon:OnInitialize()
	-- init variables
	self.channels = {
	}
	
	if LFW_CHANNEL_NAME then
		self.channels[LFW_CHANNEL_NAME] = self.LFG_FORWARDER
	end
	
	if TFW_CHANNEL_NAME then
		self.channels[TFW_CHANNEL_NAME] = self.TRADE_FORWARDER
	end
	
	self.tracking = {}
	self.owner = {}
	
	self.needsTrackingData = false

	self.timeoutTracker  = nil
	self.trackingTimeout = false
	
	-- the active flag
	self.active = false
	
	-- label text
	self.label = "T"
	
	-- debugging
	self.debug = false
	
	self:RegisterChatCommand("brffwdtracker", "ChatCommand")
	self:RegisterChatCommand("brftrack",      "ChatCommand")
	
	-- plugin host
	self.host = nil	
end

function Addon:OnEnable()
	self.PlayerName = UnitName("player")

	-- register the plugin
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
		type(host.IsMonitoredChannel) == "function" then
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
	-- update current channel states
	self:CheckChannelStates()
		
	if self.host and self:IsActive() then
		-- setup event handlers
		self:RegisterEventHandlers()
	else
		-- unregister event handlers
		self:UnregisterEventHandlers()
	end
end

function Addon:RegisterEventHandlers()
	-- register channel tracking
	self:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")				
	self:RegisterEvent("CHAT_MSG_CHANNEL")				
	self:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE_USER")				
end

function Addon:UnregisterEventHandlers()
	-- unregister channel tracking
	self:UnregisterEvent("CHAT_MSG_CHANNEL_NOTICE")			
	self:UnregisterEvent("CHAT_MSG_CHANNEL")			
	self:UnregisterEvent("CHAT_MSG_CHANNEL_NOTICE_USER")			
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
	elseif action == "tracking" then
		self:Output("Tracking status:")
		for chan, id in pairs(self.channels) do
			self:Output("Channel: " .. tostring(chan))
			self:Output("ID: " .. tostring(id))
			self:Output("Tracking: " .. tostring(self.tracking[id]))
			self:Output("Owner: " .. tostring(self.owner[id]))
		end
		
	elseif action == "status" then
		self:Output("Plugin is " .. (self.host and "registered" or "not registered"))
		self:Output("Plugin is " .. (self:IsActive() and "activated" or "deactivated"))	
		self:Output("Needs tracking: " .. (self:NeedsTrackingData() and "yes" or "no"))	
		self:Output("Is tracking: " .. (self:IsAnyTracking() and "yes" or "no"))	
		self:Output("Is data receiver: " .. (self:IsDataReceiver() and "yes" or "no"))	
	else -- if action == "help" then
		-- display help
		self:Output(L["Usage:"])
		self:Output(L["/brffwdtracker arg"])
		self:Output(L["/brftrack arg"])
		self:Output(L["Args:"])
		self:Output(L["on - activate tracking"])
		self:Output(L["off - deactivate tracking"])
		self:Output(L["version - display version information"])
		self:Output(L["help - display this help"])
	end
    
    NS:ReleaseTable(args)
end

function Addon:UpdateLabelText()
	local label = "T"
	
	if self:IsActive() then
		if self:NeedsTrackingData() then
			if self:IsAnyTracking() and self:IsDataReceiver() then
				if self:HasTrackingTimeout() then
					label = NS:Colorize("Yellow", label)
				else
					label = NS:Colorize("Green", label)
				end
			else
				label = NS:Colorize("Red", label)
			end
		else
			label = NS:Colorize("White", label)
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
	return L["Plug-in keeps track of messages forwarded by LFGForwarder and TradeForwarder and feeds them to the addon."]
end

-- keep it short (1-2 chars) - this is additional to the label text of the host
function Addon:GetLabelText()	
	return self.label
end

function Addon:GetTooltipMessages()
	local messages = {}
	
	if self:IsActive() then
		if self:NeedsTrackingData() then
			if self:IsAnyTracking() then
				if self:IsTracking(self.LFG_FORWARDER) then
					if self:IsOwner(self.LFG_FORWARDER) then
						tinsert(messages, NS:Colorize("Yellow", "LFGForwarder: " .. L["No sender available."]))
					else
						tinsert(messages, NS:Colorize("Green", "LFGForwarder: " .. L["Tracking in progress."]))
					end
				end
				if self:IsTracking(self.TRADE_FORWARDER) then
					if self:IsOwner(self.TRADE_FORWARDER) then
						tinsert(messages, NS:Colorize("Yellow", "TradeForwarder: " .. L["No sender available."]))
					else
						tinsert(messages, NS:Colorize("Green", "TradeForwarder: " .. L["Tracking in progress."]))
					end
				end
				
				if self:IsDataReceiver() then
					if self:HasTrackingTimeout() then
						tinsert(messages, NS:Colorize("Yellow", L["No data received for more than 3 minutes."]))
					end
				else
					tinsert(messages, NS:Colorize("Red", L["No sender available."]))
				end
			else
				tinsert(messages, NS:Colorize("Red", L["Cannot track LFG/TradeForwarder. Channel(s) not found."]))
			end
		else
			tinsert(messages, NS:Colorize("White", L["Tracking paused in major city."]))
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

-- we do not handle events provided by the main addon
function Addon:HandleEvent(event, data)
	-- void
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
	if message == "YOU_JOINED" or message == "YOU_LEFT" or message == "SUSPENDED" or message == "YOU_CHANGED" then
		self:Debug("CHAT_MSG_CHANNEL_NOTICE: message " .. tostring(message) .." chan " .. tostring(channelName) .. " #" .. tostring(channelNumber))
		self:CheckChannelStates()
	end
end

function Addon:CHAT_MSG_CHANNEL(event, message, author, arg3, arg4, arg5, arg6, arg7, id, channelName)
	if self:GetInternalIDForChannel(channelName) then
		self:HandleChannelMessage(message, author)
	end
end

function Addon:CHAT_MSG_CHANNEL_NOTICE_USER(event, message, sender, language, channelString, target, flags, arg7, channelNumber, channelName)
	self:Debug("CHAT_MSG_CHANNEL_NOTICE_USER: sender " .. tostring(sender) .." chan " .. tostring(channelName) .. " #" .. tostring(channelNumber))
	
	if message == 'OWNER_CHANGED' or message == 'CHANNEL_OWNER' then
		local id = self:GetInternalIDForChannel(channelName)

		self:Debug("CHAT_MSG_CHANNEL_NOTICE_USER: message " .. tostring(message) .. " id " .. tostring(id))
		
		if id then
			self:SetOwner(id, sender)
		end
	end
end

-- message handling
function Addon:HandleChannelMessage(msg, sender)
	self:Debug("HandleChannelMessage: by sender " .. tostring(sender))
	
	if not self:IsActive() then
		self:Debug("HandleChannelMessage: plugin not active")
		return
	end
	
	if sender == self.PlayerName then
		self:Debug("HandleChannelMessage: no need to handle self")
		return
	end

	-- reschedule timeout tracking timer
	self:RescheduleTimer()
	
	self:ProcessMessage(msg, sender)
end

function Addon:ProcessMessage(rawmsg, sender)
	self:Debug("ProcessMessage")
	
	-- we read can read the chat anyway
	if not self:NeedsTrackingData() then
		self:Debug("ProcessMessage: dont need tracking data")
		return
	end
	
	if not self.host then
		self:Debug("ProcessMessage: host missing")
		return
	end

	-- get data from raw message
	local _, _, idx, author, message, color = strfind(rawmsg, LFW_PATTERN_R);

	self:Debug("ProcessMessage: ".. tostring(author) .. ": " .. tostring(message))
	
	-- process message when not in town
	if author and message then
		self.host:ProcessMessage(self, message, author, sender)
	end
end

-- user functions
function Addon:PrintVersionInfo()
    self:Output(L["Version"] .. " " .. NS:Colorize("White", GetAddOnMetadata(ADDON, "Version")))
end

-- utilities
function Addon:Output(msg)
	if ( msg ~= nil and DEFAULT_CHAT_FRAME ) then
		DEFAULT_CHAT_FRAME:AddMessage(self.MODNAME..": "..msg, 0.6, 1.0, 1.0)
	end
end

-- settings
function Addon:CheckChannelStates()
	self:Debug("CheckChannelStates")
	self.tracking[self.LFG_FORWARDER] = false
	self.tracking[self.TRADE_FORWARDER] = false
	self.needsTrackingData = true
	
	if self.host then
		local channels = {GetChannelList()}
		
		for i=1, #channels, 2 do
			-- check if we have joined the usual channels in a major city
			if self.host:IsMonitoredChannel(channels[i]) then
				-- if monitored channel is not just general chat
				if channels[i] == 2 then
					self.needsTrackingData = false
				end
			end
			
			-- check if we are present in the LFGForwarder channel
			if LFW_CHANNEL_NAME and channels[i+1] == LFW_CHANNEL_NAME then
				self.tracking[self.LFG_FORWARDER] = true
			elseif TFW_CHANNEL_NAME and channels[i+1] == TFW_CHANNEL_NAME then
				self.tracking[self.TRADE_FORWARDER] = true
			end
		end		
	end
	
	if not self.tracking[self.LFG_FORWARDER] then
		self.owner[self.LFG_FORWARDER] = false
	end
	
	if not self.tracking[self.TRADE_FORWARDER] then
		self.owner[self.TRADE_FORWARDER] = false
	end
	
	self:UpdateTimeoutTracking()
	
	self:UpdateLabelText()
end

function Addon:GetInternalIDForChannel(channel)
	return self.channels[channel]
end

function Addon:IsAnyTracking()
	return self:IsTracking(self.TRADE_FORWARDER) or self:IsTracking(self.TRADE_FORWARDER)
end

function Addon:IsTracking(id)
	return self.tracking[id]
end

function Addon:IsOwner(id)
	return self.owner[id]
end

function Addon:NeedsTrackingData()
	return self.needsTrackingData
end

function Addon:SetOwner(id, owner)
	self:Debug("SetOwner: id " .. tostring(id) .. " owner " .. tostring(owner))
	if id then
		local isOwner = owner == self.PlayerName
		
		if self.owner[id] ~= isOwner then
			self.owner[id] = isOwner
			
			self:UpdateLabelText()
		end
	end
end

function Addon:IsDataReceiver()
	return self:IsDataReceiverFor(self.TRADE_FORWARDER) or self:IsDataReceiverFor(self.LFG_FORWARDER)
end

function Addon:IsDataReceiverFor(channel)
	return self:IsTracking(channel) and not self:IsOwner(channel)
end

-- timeout tracking
function Addon:UpdateTimeoutTracking()
	if self:IsActive() and self:NeedsTrackingData() then
		if not self.timeoutTracker then	
			self:RescheduleTimer()
		end
	else
		self:CancelTrackingTimer()
	end
end

function Addon:RescheduleTimer()
	-- reset timeout on reschedule
	self:SetTrackingTimeout(false)
	
	self:CancelTrackingTimer()
	
	self.timeoutTracker = self:ScheduleTimer("TrackingTimeoutElapsed", TRACKING_TIMEOUT)
end

function Addon:TrackingTimeoutElapsed()
	self.timeoutTracker = nil
	
	self:SetTrackingTimeout(true)
end

function Addon:CancelTrackingTimer()
	if self.timeoutTracker then
		self:CancelTimer(self.timeoutTracker)
		
		self.timeoutTracker = nil
	end
end

function Addon:SetTrackingTimeout(timeout)
	if timeout ~= self.trackingTimeout then
		self.trackingTimeout = timeout
		
		self:UpdateLabelText()
	end
end

function Addon:HasTrackingTimeout()
	return self.trackingTimeout
end
