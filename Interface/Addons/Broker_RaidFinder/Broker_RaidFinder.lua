local _G = _G

-- addon name and namespace
local ADDON, NS = ...

-- local functions
local strlower          = strlower
local strfind           = strfind
local strupper          = strupper
local string_format     = string.format
local tinsert           = table.insert
local table_sort        = table.sort
local ipairs            = ipairs
local pairs             = pairs
local time              = time
local floor             = floor
local gsub              = gsub

local GetNumGroupMembers    = _G.GetNumGroupMembers
local GetNumSubgroupMembers = _G.GetNumSubgroupMembers
local GetPlayerInfoByGUID   = _G.GetPlayerInfoByGUID
local InCombatLockdown      = _G.InCombatLockdown
local IsAltKeyDown          = _G.IsAltKeyDown
local IsControlKeyDown      = _G.IsControlKeyDown
local IsInRaid              = _G.IsInRaid
local IsShiftKeyDown        = _G.IsShiftKeyDown
local RequestRaidInfo       = _G.RequestRaidInfo
local UnitName              = _G.UnitName
local ChatFrame_GetMessageEventFilters = _G.ChatFrame_GetMessageEventFilters

local LE_PARTY_CATEGORY_HOME = _G.LE_PARTY_CATEGORY_HOME

-- aux variables
local _

local players   = {}
local instances = {}

-- setup libs
local LibStub   = LibStub
local LDB       = LibStub:GetLibrary("LibDataBroker-1.1")

-- coloring tools
local Crayon	= LibStub:GetLibrary("LibCrayon-3.0")

-- toast notifications
local LibToast = LibStub("LibToast-1.0")

-- get translations
local L         = LibStub:GetLibrary("AceLocale-3.0"):GetLocale(ADDON)

-- for sorted keyword list we only care that the shortest keywords (which are more likely to produce a match) are first
local function keyword_lt(a, b) 
	return a:len() < b:len() 
end

-- addon
local Addon = LibStub:GetLibrary("AceAddon-3.0"):NewAddon(ADDON, "AceEvent-3.0", "AceConsole-3.0", "AceTimer-3.0")

-- add to namespace
NS.Addon = Addon

-- constants
Addon.MODNAME   = "BrokerRaidFinder"
Addon.FULLNAME  = "Broker: Raid Finder"
Addon.SHORTNAME = "Raid Finder"

-- modules
local Interface     = nil
local Communication = nil
local Plugins       = nil
local Options       = nil
local Tooltip       = nil
local MinimapButton = nil
local DataBroker    = nil

-- icons
local ICON          = "Interface\\Addons\\"..ADDON.."\\icon.tga"
local ICON_DISABLED = "Interface\\Addons\\"..ADDON.."\\icondisabled.tga"

LibStub:GetLibrary('LibWho-2.0'):Embed(Addon)

-- blizzard channels to monitor
local monitoredChannels = {
	[1] =  true, -- General
	[2] =  true, -- Trade
	[4] =  true, -- LFG
}

local monitorEvents = {
	["monitorGuild"] =  {"CHAT_MSG_GUILD", "CHAT_MSG_OFFICER"},
	["monitorSay"]   =  {"CHAT_MSG_SAY"},
	["monitorYell"]  =  {"CHAT_MSG_YELL"},
}

local confidentialChat = {
	["CHAT_MSG_GUILD"] = true, 
	["CHAT_MSG_OFFICER"] = true,
}

local emptyTable = {}

-- close toast callback
local function CloseToast()
	Addon:TriggerAction("show")
end

-- chat event filter
local function MessageEventFilterByMatch(self, event, ...)
	local message, author, arg3, arg4, arg5, arg6, arg7, id = ...

	-- under these criteria no matching will be performed by Addon
	if Addon:GetMonitoringActive() == false or
	   author == Addon.PlayerName or  
	   Addon:IsInRaid(author) or
	   not Addon:IsMonitoredChannel(id) then
		return
	end
	
	local match, instance, keyword = Addon:FindInstanceMatch(message)

	-- if message is matched for an instance then we can filter it
	if match and instance then
		return true
	end
end

-- infrastcructure
function Addon:OnInitialize()
	-- addon constants
	self.MAX_TIME_RANGE = 120	

    -- matches
	self.EVENT_MATCH_LFG    = 1
	self.EVENT_MATCH_LOCAL  = 2
	self.EVENT_MATCH_REMOTE = 3
	
	-- addon variables
	
	-- monitored instances
	self.monitored = {}
		
	-- aux vars 
	self.playerSavedRaids = {}
	self.notificationTimeouts = {}
	
	-- track combat 
	self.inCombat = false
	
	-- debugging
	self.debug = false
	
	-- unit information
	self.raidNames   = {}
	self.PlayerName  = UnitName("player")
	self.playerName  = strlower(self.PlayerName)

	self.classCache  = {}
	
	-- offset to local time
	local gHour = GetGameTime()
	self.timeOffset = (tonumber(gHour) - date("!%H")) * 3600
	
	-- matches 
	self.matches = nil
	
	-- processed data
	self.taintedData      = true
	self.matchedPlayers   = 0
	self.matchedInstances = 0
	self.matchesLatest    = {}
	self.matchOldest      = nil
	
	-- keyword data
	self.lfgKeywordList       = {}
	self.instanceKeywordLists = {}

	self.defaultLfgKeywords   = {}
	self.defaultKeywords      = {}
	
	self:SetupDefaultKeywords()
	
	self:RegisterChatCommand("braidfinder", "ChatCommand")
    self:RegisterChatCommand("brfind",      "ChatCommand")
	
	-- setup toast support
	LibToast:Register(Addon.FULLNAME, function(toast, ...)
		toast:SetTitle(Addon.FULLNAME)
		toast:SetIconTexture(ICON)
		toast:SetText(...)
		toast:SetUrgencyLevel("moderate")
		toast:SetPrimaryCallback(_G.SHOW, CloseToast)
	end)	
end

function Addon:OnEnable()
	-- set module references
	Interface     = self:GetModule("Interface")
	Communication = self:GetModule("Communication")
	Plugins       = self:GetModule("Plugins")
	Options       = self:GetModule("Options")
	Interface     = self:GetModule("Interface")
	Tooltip       = self:GetModule("Tooltip")
	MinimapButton = self:GetModule("MinimapButton")
	DataBroker    = self:GetModule("DataBroker")

	-- redo: offset to local time
	-- seems on initialize the game time is not always set properly
	local gHour = GetGameTime()
	self.timeOffset = (tonumber(gHour) - date("!%H")) * 3600
	
	self.matches = Options:GetMatchTable()
	
	self:SetupEventHandlers()
		
	-- wholib query callback
	-- self:RegisterCallback('WHOLIB_QUERY_RESULT', 'UnitInfoCallback')
	
	-- timer for cyclic cleaning up of history
	self.timer = self:ScheduleRepeatingTimer("ManageHistory", 60)
	
	-- update keyword data
	self:UpdateAllKeywords()
	
	-- update cached unit data
	self:UpdateRaidUnits()

	-- set initial combat state
	self:UpdateCombatState()
	
	-- setup message event filter
	self:ActivateMessageEventFilter(self:GetSetting("filterMatches"))

	MinimapButton:SetShow(Options:GetSetting("minimap"))

	self:UpdateAllMonitoredInstances()
	
	self:UpdateIcon()
	self:Update()
	
	-- request info about saved instances
	RequestRaidInfo() 
end

function Addon:OnDisable()
	self:SetupEventHandlers()
	
	MinimapButton:SetShow(false)
	
	-- remove message event filter
	self:ActivateMessageEventFilter(false)
	
	-- cancel timer for cyclic cleaning up of history
	self:CancelTimer(self.timer)
end

function Addon:OnOptionsReloaded()
	Plugins:SetupDB()
	
	self:UpdateAllKeywords()

	self:ActivateMessageEventFilter(self:GetSetting("filterMatches"))

	MinimapButton:SetShow(Options:GetSetting("minimap"))
	
	self:UpdateAllMonitoredInstances()

	self:SetupMessageEventHandlers()
	
	self.taintedData = true

	self:UpdateIcon()
	self:Update()
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

function Addon:OnClick(button)
	if ( button == "RightButton" ) then 
		if IsShiftKeyDown() then
			-- unused
		elseif IsControlKeyDown() then
			-- unused
		elseif IsAltKeyDown() then
			-- unused
		else
			-- open options menu
			Addon:TriggerAction("menu")
		end
	elseif ( button == "LeftButton" ) then 
		if IsShiftKeyDown() then
			-- unused
		elseif IsControlKeyDown() then
			-- unused
		elseif IsAltKeyDown() then
			-- toggle monitoring
			Addon:TriggerAction("toggle")
		else
			-- show finder log
			Addon:TriggerAction("show")
		end
	end
end

function Addon:TriggerAction(action, ...)
    local args = NS:NewTable(...)

	action = type(action) == "string" and string.lower(action) or ""	

	if action == "menu" then
		-- open options menu
		InterfaceOptionsFrame_OpenToCategory(self.FULLNAME)
		-- call twice because otherwise first time options are opened it will not switch to the addon
		InterfaceOptionsFrame_OpenToCategory(self.FULLNAME)
	elseif action == "version" then
		-- print version information
		self:PrintVersionInfo()
	elseif action == "debug" then
		if args[1] == "on" then
			self:Output("debug mode turned on")
			self.debug = true
		end
		if args[1] == "off" then
			self:Output("debug mode turned off")
			self.debug = false
		end
	elseif action == "toggle" then
		Options:ToggleSetting("monitoringActive")
		self:Output(L["Monitoring is "] .. (self:GetMonitoringActive() and L["on"] or L["off"]))
	elseif action == "on" then
		Options:SetSetting("monitoringActive", true)
		self:Output(L["Monitoring is "] .. (self:GetMonitoringActive() and L["on"] or L["off"]))
	elseif action == "off" then
		Options:SetSetting("monitoringActive", false)
		self:Output(L["Monitoring is "] .. (self:GetMonitoringActive() and L["on"] or L["off"]))
	elseif action == "show" then
		Interface:ShowLogWindow()
	elseif action == "friends" then
		if next(Communication.friends) then
			for player, _ in pairs(Communication.friends) do
				self:Output("Friend: " .. player)
			end
		else
			self:Output("No friends.")
		end
		if next(Communication.bnetfriends) then
			for player, _ in pairs(Communication.bnetfriends) do
				self:Output("BNetFriend: " .. player)
			end
		else
			self:Output("No bnetfriends.")
		end
	elseif action == "remote" then
		self:Output("Partners:")
		for partner, _ in pairs(Communication.partners) do
			self:Output(tostring(partner))
		end
		self:Output("Clients:")
		for client, _ in pairs(Communication.clients) do
			self:Output(tostring(client))
			self:Output("Instances:")
			for instance, clients in pairs(Communication.clientConfig) do
				for c, _ in pairs(clients) do
					if c == client then
						self:Output(instance)
					end
				end
			end
		end
		if Communication.server then
			self:Output("Server: " .. tostring(Communication.server))
		else
			self:Output("Server: none")
		end
		self:Output("Blacklisted:")
		for blacklisted, _ in pairs(Communication.blacklist) do
			self:Output(tostring(blacklisted))
		end
		self:Output("Comm quality: " .. tostring(Communication.quality))
		self:Output("Comm numclients: " .. tostring(Communication.numClients))
	elseif action == "saved" then
		if next(self.playerSavedRaids) then
			for instance, _ in pairs(self.playerSavedRaids) do
				self:Output(instance)
			end
		else
			self:Output("No saved raids.")
		end
	elseif action == "plugin" then
		local action = args[1]
		local name
		local index = 2
		local cmdArgs = NS:NewTable()
		
		for i = 2, #args do
			name = name and name .. " " or ""
			name = name .. args[i]
			
			if Plugins:HasPlugin(name) then
				break
			end
			
			index = index + 1
		end

		if not Plugins:HasPlugin(name) then
			name = args[2]
			index = 2
		end
				
		for i = 1, #args - index do
			cmdArgs[i] = args[i + index]
		end
		
		Plugins:HandleAction(action, name, unpack(cmdArgs))
		
		NS:ReleaseTable(cmdArgs)
	else -- if action == "help" then
		-- display help
		self:Output(L["Usage:"])
		self:Output(L["/braidfinder arg"])
		self:Output(L["/brfind arg"])
		self:Output(L["Args:"])
		self:Output(L["version - display version information"])
		self:Output(L["menu - display options menu"])
		self:Output(L["on - activate monitoring"])
		self:Output(L["off - deactivate monitoring"])
		self:Output(L["show - show log window"])
		self:Output(L["help - display this help"])
	end
    
    NS:ReleaseTable(args)
end

function Addon:CreateTooltip(obj, autoHideDelay)
	Tooltip:Create(obj, autoHideDelay)
end

function Addon:RemoveTooltip()
	Tooltip:Remove()
end

function Addon:ActivateMessageEventFilter(activate)
	if activate then
		ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", MessageEventFilterByMatch)
	else
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_CHANNEL", MessageEventFilterByMatch)
	end
end

-- update functions
function Addon:Update()
	self:UpdateData()
	self:UpdateLabel()
end

-- aggregate some meaningful data from the list of matches for display on label/tooltip and internal processing
-- matchOldest:
-- 		used to determine when the next data update is needed because match is older than allowed by configured the time frame
-- matchedPlayers/Instances:
-- 		aggregates the total number of players/instances from valid matches 
-- matchesLatest:
-- 		for every instance the time and author of the most recent match is stored along with the total number of matches for that instance
function Addon:UpdateData()
	Interface:UpdateLogList()

	if self.taintedData == false then
		return
	end

	NS:ClearTable(players)
	NS:ClearTable(instances)
	
	NS:ClearTable(self.matchesLatest)
	self.matchOldest   = nil
	
	for _, match in self:IterateActiveMatches() do
		players[match.player] = true
		instances[match.instance] = true

		if not self.matchesLatest[match.instance] then
			local last = {
				player    = match.player,
				timestamp = match.timestamp,
				players   = {}
			}
			self.matchesLatest[match.instance] = last
		end

		self.matchesLatest[match.instance].players[match.player] = true
		
		self.matchOldest = match
	end
	
	self.matchedPlayers = 0
	
	for _ in pairs(players) do
		self.matchedPlayers = self.matchedPlayers + 1
	end

	self.matchedInstances = 0
	
	for _ in pairs(instances) do
		self.matchedInstances = self.matchedInstances + 1
	end	

	for _, match in pairs(self.matchesLatest) do
		local count = 0
		
		for _ in pairs(match.players) do
			count = count + 1
		end
		
		match.players = count
	end
		
	self.taintedData = false
end

function Addon:UpdateLabel()
	local text = L["I: "] .. tostring(self.matchedInstances) .. " / " .. L["P: "] .. tostring(self.matchedPlayers)
	
	if not self:GetMonitoringActive() or not self:IsAnyInstanceMonitored() then
		text = NS:Colorize("GrayOut", text)
	elseif self.matchedInstances == 0 then
		text = NS:Colorize("Red", text)
	else
		text = NS:Colorize("Green", text)
	end
	
	if Communication:IsConnected() then
		text = text .. " " .. NS:Colorize("Green", "!")
	end

	-- append plugin texts
	local pText = Plugins:GetFullLabel()
	
	if pText and pText ~= "" then
		text = text .. " " .. pText
	end
		
	DataBroker:SetText(text)
end

function Addon:UpdateIcon()
	local icon = self:GetIcon()
	
	DataBroker:SetIcon(icon)
	MinimapButton:SetIcon(icon)
end

function Addon:GetIcon()
	if Options and Options:GetSetting("monitoringActive") then
		return ICON
	else
		return ICON_DISABLED
	end
end

-- settings
function Addon:UpdateSetting(event, setting, value, old, category)
	if category == "Keywords" then
		if setting == "lfgKeywords" then
			self:UpdateLFGKeywords()
		else
			self:UpdateInstanceKeywords(setting)
		end
	elseif setting == "addonCommunication" then
		Communication:Prepare()
	elseif setting == "monitoringActive" then
		self:SetupMessageEventHandlers()
		
		self:UpdateIcon()
		self:Update()	
	elseif setting == "excludeSavedRaids" then
		self:UpdateAllMonitoredInstances()
	elseif setting == "timeFrame" then
		self:ManageHistory()
	elseif setting == "filterMatches" then
		self:ActivateMessageEventFilter(value)
	elseif setting == "monitorGuild" or setting == "monitorSay" or setting == "monitorYell" then
		self:SetupChatEventHandlers(setting)
	elseif setting == "minimap" then
		MinimapButton:SetShow(value)
	end
end

function Addon:GetSetting(setting)
	return Options:GetSetting(setting)
end

function Addon:GetMonitoringActive()
	return Options:GetSetting("monitoringActive")
end

function Addon:GetAddonCommunication()
	return Options:GetSetting("addonCommunication")
end

-- instance handling
function Addon:UpdateAllMonitoredInstances()
	for instance in NS:IterateInstances() do
		self:UpdateMonitoredInstance(nil, instance, true)
	end
	
	self.taintedData = true
	
	Communication:UpdateConfigData()
	
	self:Update()
end

function Addon:UpdateMonitoredInstance(event, instance, silent)
	if not NS:IsValidInstance(instance) then
		return
	end
	
	self.monitored[instance] = Options:IsMonitored(instance) and not self:ExcludeAsSaved(instance) or nil

	self.taintedData = true
		
	if not silent then
		Communication:UpdateConfigData()
		
		self:Update()	
	end
end

function Addon:IsMonitored(instance)
	return self.monitored[instance] == true
end

function Addon:IsAnyInstanceMonitored()
	return next(self.monitored) ~= nil
end

function Addon:IterateMonitoredInstances()
	return pairs(self.monitored)
end

function Addon:ToggleMonitored(instance)
	Options:ToggleMonitored(instance)
end

-- update cached data function
function Addon:UpdateRaidInfo()
	NS:ClearTable(self.playerSavedRaids)

	local numSaved = GetNumSavedInstances()
	
	-- we do not distinguish between different difficulties
	for i = 1, numSaved do
		local instanceName, instanceID, instanceReset, instanceDifficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, maxBosses, defeatedBosses = GetSavedInstanceInfo(i)
		
		if isRaid and locked then
			instance = self:FuzzySearchInstance(instanceName)

			if instance then
				self.playerSavedRaids[instance] = true
			end
		end
	end
end

-- since we need to map the localized name returned by GetSavedInstanceInfo to our internal non-localized instance name
-- we perform a very simple matching algorithm to do the task
-- if pattern contains all of the significant words (longer than 3 chars) we assume we found the match
function Addon:FuzzySearchInstance(pattern)
	if not pattern then
		return
	end
	
	pattern = strlower(pattern)

	for instance, _ in pairs(NS.defaultInstanceKeywords) do
		local localized = NS:TranslateInstance(instance)
		localized = strlower(localized)
		
		local matched = true
		
		for word in string.gmatch(localized, "[^%s%p%c]+") do
		    -- significant length of a word is 4 characters
			-- not sure if that works well with all possible localizations
			if string.len(word) > 3 then
				matched = matched and strfind(pattern, word)
			end
		end
		
		if matched then
			return instance
		end
	end
	
	return 
end

function Addon:UpdateRaidUnits()
	NS:ClearTable(self.raidNames)
	
	if GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) > 0 then
		if IsInRaid() then
			for i = 1, 40, 1 do
				local unit = "raid"..i
				local name = UnitName(unit)
				
				if name then
					self.raidNames[name] = true
				end
			end
		else
			for i = 1, 4, 1 do
				local unit = "party"..i
				local name = UnitName(unit)
				
				if name then
					self.raidNames[name] = true
				end
			end
		end
	end
end

function Addon:UpdateCombatState(inCombat)
	if inCombat == nil then
		self.inCombat = InCombatLockdown()
	else
		self.inCombat = inCombat
	end
	
	self:Debug("UpdateCombatState: now " .. tostring(self.inCombat))
end

function Addon:InCombat()
	return self.inCombat
end

-- update keyword lists
function Addon:SetupDefaultKeywords()
	self.defaultLfgKeywords = self:GetKeywordList(NS.defaultLFGKeywords)
	self.defaultKeywords    = {}

	for instance in NS:IterateInstances() do
		self.defaultKeywords[instance] = {}
		
		local keywords = self:GetKeywordList(NS.defaultInstanceKeywords[instance])
		
		for _, keyword in pairs(keywords) do
			self.defaultKeywords[instance][keyword] = true
		end
	end
end

function Addon:UpdateAllKeywords()
	self:UpdateLFGKeywords()

	for instance in NS:IterateInstances() do
		self:UpdateInstanceKeywords(instance)
	end
end

function Addon:UpdateLFGKeywords()
	self.lfgKeywordList = self:GetKeywordList(Options:GetLFGKeywords())
end

function Addon:UpdateInstanceKeywords(instance)
	if not instance then
		return
	end
	
	self.instanceKeywordLists[instance] = self:GetKeywordList(Options:GetInstanceKeywords(instance))	
end

function Addon:GetKeywordList(keywords)
	if not keywords then
		return {}
	end

	local list =  {}
	
	-- get all words separated by comma and trim left and right
	for word in string.gmatch(keywords, "[^,]+") do 
		word = word:gsub("^%s*(.-)%s*$", "%1")
		if word ~= "" then
			list[#list+1] = strlower(word)
		end
	end
	
	-- sort list by keyword length, shortest first
	table_sort(list, keyword_lt)
	
	return list
end

function Addon:IterateInstanceKeywords(instance)
	if not instance then
		return
	end
	
	local keywords = instance and self.instanceKeywordLists[instance] or emptyTable
	
	return ipairs(keywords)
end

-- event handlers
function Addon:SetupEventHandlers()
	if self:IsEnabled() then
		Options.RegisterCallback(self, ADDON .. "_MONITORING_CHANGED", "UpdateMonitoredInstance")	
		Options.RegisterCallback(self, ADDON .. "_SETTING_CHANGED",    "UpdateSetting")	

		-- register raid info events
		self:RegisterEvent("UPDATE_INSTANCE_INFO")
		self:RegisterEvent("RAID_INSTANCE_WELCOME")
		self:RegisterEvent("CHAT_MSG_SYSTEM")
		
		-- register raid unit events
		self:RegisterEvent("PARTY_CONVERTED_TO_RAID", "UpdateRaidUnits")
		self:RegisterEvent("GROUP_ROSTER_UPDATE", "UpdateRaidUnits")

		-- register events to track combat
		self:RegisterEvent("PLAYER_REGEN_ENABLED",  "UpdateCombatState", false)
		self:RegisterEvent("PLAYER_REGEN_DISABLED", "UpdateCombatState", true)
	else
		Options.UnregisterCallback(self, ADDON .. "_MONITORING_CHANGED")	
		Options.UnregisterCallback(self, ADDON .. "_SETTING_CHANGED")
		
		-- unregister raid info events
		self:UnregisterEvent("UPDATE_INSTANCE_INFO")
		self:UnregisterEvent("RAID_INSTANCE_WELCOME")
		self:UnregisterEvent("CHAT_MSG_SYSTEM")

		-- unregister raid unit events
		self:UnregisterEvent("PARTY_CONVERTED_TO_RAID")
		self:UnregisterEvent("PARTY_MEMBERS_CHANGED")
		
		-- register events to track combat
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	end
	
	self:SetupMessageEventHandlers()
end

function Addon:SetupMessageEventHandlers()
	self:SetupChannelEventHandlers()	

	self:SetupChatEventHandlers("monitorGuild")
	self:SetupChatEventHandlers("monitorSay")
	self:SetupChatEventHandlers("monitorYell")
end

function Addon:SetupChannelEventHandlers()
	if self:IsEnabled() and self:GetMonitoringActive() then
		self:RegisterEvent("CHAT_MSG_CHANNEL")
	else
		self:UnregisterEvent("CHAT_MSG_CHANNEL")	
	end
end

function Addon:SetupChatEventHandlers(type)
	if not monitorEvents[type] then
		return
	end
	
	if self:IsEnabled() and self:GetMonitoringActive() and Options:GetSetting(type) then
		for _, event in ipairs(monitorEvents[type]) do
			self:RegisterEvent(event, "HandleCHAT_MSG")
		end
	else
		for _, event in ipairs(monitorEvents[type]) do
			self:UnregisterEvent(event)
		end
	end
end

function Addon:CHAT_MSG_CHANNEL(event, ...)
	local message, author, _, _, _, _, _, id, _, _, _, guid = ...
	
	if self:IsMonitoredChannel(id) then
		-- apply chat filter to sort out spam
		if self:GetSetting("messageFilters") and self:IsFilteredByMessageEventFilters(event, ...) then
			-- message is filtered out
			return
		end
		
		-- get authors class
		self:AddToClassCache(author, guid)	
		
		self:HandleMessage(message, author)
	end
end

function Addon:HandleCHAT_MSG(event, ...)
	local message, author, _, _, _, _, _, id, _, _, _, guid = ...

	self:Debug("HandleCHAT_MSG: " .. tostring(event) .. "/" .. tostring(author) .. "/" .. tostring(id) .. "/" .. tostring(guid))
	
	local restricted = false
	
	if confidentialChat[event] == true then
		restricted = true
	else
		-- apply chat filter to sort out spam
		if self:GetSetting("messageFilters") and self:IsFilteredByMessageEventFilters(event, ...) then
			-- message is filtered out
			self:Debug("HandleCHAT_MSG: filtered ")
			return
		end
	end

	self:Debug("HandleCHAT_MSG: restricted " .. tostring(restricted))
	
	-- get authors class
	self:AddToClassCache(author, guid)	
	
	self:HandleMessage(message, author, restricted)	
end

-- saved raid info events
function Addon:UPDATE_INSTANCE_INFO()
	self:UpdateRaidInfo()
end

function Addon:RAID_INSTANCE_WELCOME()
	RequestRaidInfo()
end

function Addon:CHAT_MSG_SYSTEM(msg)
	if tostring(msg) == _G["INSTANCE_SAVED"] then
		RequestRaidInfo()
	end
end

-- user functions
function Addon:PrintVersionInfo()
    self:Output(L["Version"] .. " " .. NS:Colorize("White", GetAddOnMetadata(ADDON, "Version")))
end

-- utilities
function Addon:Output(msg)
	if ( msg ~= nil and DEFAULT_CHAT_FRAME ) then
		DEFAULT_CHAT_FRAME:AddMessage( self.MODNAME..": "..msg, 0.6, 1.0, 1.0 )
	end
end

function Addon:IsMonitoredChannel(id)
	return monitoredChannels[id] == true
end

function Addon:AddToClassCache(name, guid)
	if not guid or type(guid) ~= "string" or guid:len() == 0 then
		return
	end
	
	if name and not self.classCache[name] then
		local _, class = GetPlayerInfoByGUID(guid)
		
		if class then
			self.classCache[name] = class
		end
	end
end

function Addon:RestoreClassToCache(name, class)
	if not name or not class or not _G["RAID_CLASS_COLORS"][class] then
		return
	end
	
	if not self.classCache[name] then
		self.classCache[name] = class
	end
end

function Addon:ColorizeChar(name)
	if not name then
		return
	end
	
	local class = self:GetClass(name)
	
	if class then
		local colortable = _G["CUSTOM_CLASS_COLORS"] or _G["RAID_CLASS_COLORS"]
		local color = colortable[class]
		return "|cff" .. string.format("%02x%02x%02x", color.r*255, color.g*255, color.b*255) .. name .. "|r"
	else
		return NS:Colorize("GrayOut", name)
	end
end

function Addon:GetClass(name)
	if not self.classCache[name] then
		local result = self:UserInfo(name, {queue = self.WHOLIB_QUEUE_QUIET, timeout = -1, callback = 'UnitInfoCallback'}) --flags = self.WHOLIB_FLAG_ALWAYS_CALLBACK, 
		
		if result then
			self:UnitInfoCallback(result)
		end
	end

	return self.classCache[name]
end

function Addon:UnitInfoCallback(user, time)
	if user and user.Class then
		self.classCache[user.Name] = gsub(strupper(user.Class), " ", "")
	end		
end

function Addon:IsSaved(instance)
	return self.playerSavedRaids[instance] == true
end

function Addon:ExcludeAsSaved(instance)
	return Options:GetSetting("excludeSavedRaids") and self:IsSaved(instance)
end

function Addon:PlaySoundFile(sound)
	if type(sound) ~= "string" then
		return
	end

	if ((string.sub(sound, -4) == ".ogg") or (string.sub(sound, -4) == ".mp3")) then
		PlaySoundFile(sound)
	else
		PlaySound(sound)
	end
end

function Addon:IsInRaid(name)
	return self.raidNames[name] ~= nil
end

function Addon:WhisperCharacter(character)
	if not character then
		return
	end

	DEFAULT_CHAT_FRAME.editBox:Show()
	DEFAULT_CHAT_FRAME.editBox:SetText("/whisper " .. character .. " ")
end

function Addon:GetTimeOffset()
	return self.timeOffset
end

-- testing
function Addon:Debug(msg)
	if self.debug then
		if ( msg ~= nil and DEFAULT_CHAT_FRAME ) then
			DEFAULT_CHAT_FRAME:AddMessage( self.MODNAME .. " (dbg): " .. msg, 1.0, 0.37, 0.37 )
		end
	end
end

-- data handling

-- NOTE: the filters are applied for message display anyway, but in order to sort out the spam for our purposes we have to execute it once more
-- NOTE: auto-reporting of spam done in filter functions will probably executed again as well
function Addon:IsFilteredByMessageEventFilters(event, ...)
	local chatFilters = ChatFrame_GetMessageEventFilters(event)
	
	if chatFilters then
		for _, filterFunc in next, chatFilters do
			-- check all filters but our own
			-- NOTE: we dont care about any changes made to the args, we just want to know if the original message is filtered or not
			if filterFunc ~= MessageEventFilterByMatch and filterFunc(Interface.logWindow, event, ...) then 
				return true
			end
		end 
	end 
	
	return false
end

function Addon:HandleMessage(msg, author, restricted)
	local instance, keyword = self:ProcessMessage(msg, author, nil, restricted)
	
	if not restricted then
		self:ProcessMessageForRemoteClients(msg, author, keyword, instance)
	end
end

function Addon:ProcessMessage(msg, author, source, restricted)
	if not Options:GetSetting("monitoringActive") or
	   author == self.PlayerName or  
	   self:IsInRaid(author) then
		return
	end

	local match, instance, keyword = self:FindInstanceMatch(msg)
	
	if not match then
		return
	end
	
	-- setup event and data for plugin notification
	local event = self.EVENT_MATCH_LFG
	
	local data = {
		message    = msg,
		author     = author,
		instance   = instance,
		keyword    = keyword,
		source     = source,
		restricted = restricted,
	}
	
	-- process matched instance
	if instance then
		-- insert match into list
		local match = self:InsertMatch(author, msg, instance, source)
		
		-- trigger notification
		self:NotifyMatch(match)
		
		-- notify plugins
		if source then
			event = self.EVENT_MATCH_REMOTE
		else
			event = self.EVENT_MATCH_LOCAL
		end

		self:Update()						
	end
	
	-- notify plugins about lfg match
	Plugins:HandleEvent(event, data)
	
	return instance, keyword
end

-- match is the keyword which the local processing of the message produced
-- if that constitutes a valid hit we inform the clients without checking the message again
-- NOTES: 
-- - first hit policy (if we match something we use that hit and dont check for any other)
--   if there is more than one instance that could be matched in the message only clients subscribing for the first will get notified, the others are left out 
--   we live with that
-- - remote message processing uses default keywords only
-- - remote message processing always uses default lfg pattern
function Addon:ProcessMessageForRemoteClients(msg, author, match, instance)
	self:Debug("ProcessMessageForRemoteClients")
	if not Communication:IsReady() or not Communication:HasActiveClients() then
		self:Debug("ProcessMessageForRemoteClients: aborting - comm " .. (Communication:IsReady() and "ready" or "not ready") .. " and " .. (Communication:HasActiveClients() and "has clients" or "has no clients"))
		return
	end

	-- check if local match can be used
	if match and instance then
		self:Debug("ProcessMessageForRemoteClients: local match")
		if self.defaultKeywords[instance] and 
		   self.defaultKeywords[instance][match] then
			if Communication:InstanceMonitoredByClient(instance) then
				self:Debug("ProcessMessageForRemoteClients: local match is remote hit")
				Communication:SendRemoteHit(instance, author, msg)
				
				-- first hit ends it
				return
			end
		end
	end

	-- check message for hit
	local lmsg = strlower(msg)
	local hasMatch = false
	
	-- check message lfg hit
	for _, keyword in pairs(self.defaultLfgKeywords) do
		if strfind(lmsg, keyword) then
			hasMatch = true
			break
		end
	end
	
	if not hasMatch then
		return
	end
	
	-- for all instances
	for instance, keywords in pairs(self.defaultKeywords) do
		-- any client registered for instance
		if Communication:InstanceMonitoredByClient(instance) then
			-- check keywords
			for keyword, _ in pairs(keywords) do
				if strfind(lmsg, keyword) then
					self:Debug("ProcessMessageForRemoteClients: found remote hit")
					
					Communication:SendRemoteHit(instance, author, msg)
					
					-- first hit ends it
					return
				end
			end
		end
	end
end

function Addon:FindInstanceMatch(msg)
	local lmsg = strlower(msg)
	
	-- check for 'looking for' keywords
	if not self:IsLFGMessage(lmsg, true) then
		return false
	end

	-- after 'looking for' match we need to find an instance match
	local matchedKeyword  = nil
	local matchedInstance = nil
	
	-- for all extensions
	for extension, instances in pairs(NS.instances) do
		-- for all instances
		for _, instance in pairs(instances) do
		
			if self:IsMonitored(instance) then 
				-- for all keywords
				local keywords = self.instanceKeywordLists[instance] or {}
				
				for _, keyword in pairs(keywords) do
					if strfind(lmsg, keyword) then
						matchedKeyword  = keyword
						matchedInstance = instance
						
						break
					end
				end
			end
		end
	end
	
	return true, matchedInstance, matchedKeyword
end

function Addon:IsLFGMessage(msg, isLower)
	if not isLower then
		msg = strlower(msg)
	end
	
	-- check for 'looking for' keywords
	for _, keyword in pairs(self.lfgKeywordList) do
		if strfind(msg, keyword) then
			return true
		end
	end
	
	return false
end

function Addon:InsertMatch(author, msg, instance, source)
	if not author or not msg or not instance then
		return nil
	end
	
	local match = {
		timestamp = time(),
		char      = self.PlayerName,
		instance  = instance,
		player    = author,
		class     = self:GetClass(author),
		message   = msg,
		source    = source,
	}
						
	-- remove last entry by author to the very same instance	
	for index, entry in pairs(self.matches) do
		if entry.instance == match.instance and
		   entry.player == match.player then
			tremove(self.matches, index)
			
			break
		end
	end
	
	-- insert at the beginning
	tinsert(self.matches, 1, match)

	self.taintedData = true
	
	return match
end					

function Addon:NotifyMatch(match)
	local author   = match.player
	local instance = match.instance
	
	if not author or not instance then
		return
	end

	-- check notification timeout
	local donotify = true
	
	if not self.notificationTimeouts[author] then
		self.notificationTimeouts[author] = {}
	end
	
	if self.notificationTimeouts[author][instance] and self.notificationTimeouts[author][instance] + Options:GetSetting("notificationTimeout")*60 > match.timestamp then
		donotify = false
	end						

	-- notification only if last match wasn't by same player to prevent spamming					
	if donotify then
		if Options:GetSetting("notifyText") then
			self:Output(string.format(L["Found new match for %s from player %s."], instance, author))
		end

		if Options:GetSetting("notifySound") then
			self:PlaySoundFile(Options:GetSoundFile(Options:GetSetting("notificationSound")))
		end
		
		if Options:GetSetting("notifyToast") then
			LibToast:Spawn(Addon.FULLNAME, string.format(L["Found new match for %s from player %s."], NS:Colorize("Green", instance), self:ColorizeChar(author)))
		end
		
		-- update notification timeout timestamp
		self.notificationTimeouts[author][instance] = match.timestamp
	end
end

function Addon:ManageHistory()
	local now           = time()
	local oldestValid   = now - self.MAX_TIME_RANGE * 60
	local oldestFrame   = now - self:GetSetting("timeFrame") * 60
	
	-- remove all matches outside global maximum time range
	while #self.matches ~= 0 and self.matches[#self.matches].timestamp < oldestValid do
		tremove(self.matches)
	end
	
	-- currently stored oldest match is out of the timeframe now, so we need
	if not self.matchOldest or self.matchOldest.timestamp < oldestFrame then
		self.taintedData = true
	end

	if self.taintedData then
		self:Update()
	end
end

function Addon:IterateMatches()
	return ipairs(self.matches)
end

-- Addon:IterateActiveMatches
do --Do-end block for iterator
	local emptyTbl = {}
	local tablestack = setmetatable({}, {__mode = 'k'})

	local function ActiveMatchIter(t, prestate)
		if not t then 
			return nil 
		end

		if t.iterator then
			local index, match = t.iterator(t.t, prestate)

			if index and match.timestamp + t.timeframe >= t.now then
				if Addon:IsMonitored(match.instance) and not Addon:ExcludeAsSaved(match.instance) then
					return index, match
				end
			end				
		end
		
		tablestack[t] = true
		return nil, nil		
	end

	function Addon:IterateActiveMatches()
		local tbl = next(tablestack) or {}		
		tablestack[tbl] = nil
				
		local iterator, t, state = self:IterateMatches()
		
		tbl.iterator  = iterator
		tbl.t         = t
		tbl.now       = time()
		tbl.timeframe = self:GetSetting("timeFrame")*60
		
		return ActiveMatchIter, tbl, state
	end
end
