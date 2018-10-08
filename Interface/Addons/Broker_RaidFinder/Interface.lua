local _G = _G

-- addon name and namespace
local ADDON, NS = ...

local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON)

-- the Interface module
local Interface = Addon:NewModule("Interface")

NS.Interface = Interface

-- local functions
local string_format = string.format
local tinsert       = table.insert
local table_sort    = table.sort
local pairs         = pairs

-- aux variables
local _

local monitored = {}

-- get translations
local L = LibStub:GetLibrary("AceLocale-3.0"):GetLocale(ADDON)

-- utilities
local function format_time(stamp)
	local days    = floor(stamp/86400)
	local hours   = floor((stamp - days * 86400) / 3600)
	local minutes = floor((stamp - days * 86400 - hours * 3600) / 60)
	local seconds = floor((stamp - days * 86400 - hours * 3600 - minutes * 60))

	return string_format("%02d:%02d:%02d", hours, minutes, seconds)
end

-- local constants
local MAX_LIST_SIZE       = 10
local LIST_ENTRY_HEIGHT     = 20

local FILTER_INSTANCE_OPT_ALL   = "Show All"

local FILTER_INSTANCE_OPT_ALL    = 0
local FILTER_INSTANCE_OPT_SELF   = 1
local FILTER_INSTANCE_OPT_ALTS   = 2
local FILTER_INSTANCE_OPT_REMOTE = 3

local filterInstanceBtnInfo = { func = function(self) Interface:HandleInstanceFilter(self.value); UIDropDownMenu_SetSelectedValue(Interface.logFilterInstance, self.value) end } 
local filterSourceBtnInfo   = { func = function(self) Interface:HandleSourceFilter(self.value); UIDropDownMenu_SetSelectedValue(Interface.logFilterSource, self.value) end }

local function InitInstanceFilter()
	if Addon:InCombat() then
		return
	end
	
	filterInstanceBtnInfo.text = L["Show All"]
	filterInstanceBtnInfo.value = FILTER_INSTANCE_OPT_ALL
	filterInstanceBtnInfo.checked = Interface.instanceFilter == FILTER_INSTANCE_OPT_ALL
	UIDropDownMenu_AddButton(filterInstanceBtnInfo)
	
	-- populate with currently monitored instances
	NS:ClearTable(monitored)
	
	for instance, _ in Addon:IterateMonitoredInstances() do
		tinsert(monitored, instance)
	end
	
	table_sort(monitored, function(a, b) return NS:TranslateInstance(a) < NS:TranslateInstance(b); end)
	
	for i = 1, #monitored do
		filterInstanceBtnInfo.text =  NS:TranslateInstance(monitored[i])
		filterInstanceBtnInfo.value = monitored[i]
		filterInstanceBtnInfo.checked = Interface.instanceFilter == monitored[i]
		UIDropDownMenu_AddButton(filterInstanceBtnInfo)
	end

	UIDropDownMenu_SetSelectedValue(Interface.logFilterInstance, Interface.instanceFilter)
end

local function InitSourceFilter()
	if Addon:InCombat() then
		return
	end
	
	filterSourceBtnInfo.text = L["Show All"]
	filterSourceBtnInfo.value = FILTER_INSTANCE_OPT_ALL
	filterSourceBtnInfo.checked = Interface.sourceFilter == FILTER_INSTANCE_OPT_ALL
	UIDropDownMenu_AddButton(filterSourceBtnInfo)
	
	filterSourceBtnInfo.text = L["Self"]
	filterSourceBtnInfo.value = FILTER_INSTANCE_OPT_SELF
	filterSourceBtnInfo.checked = Interface.sourceFilter == FILTER_INSTANCE_OPT_SELF
	UIDropDownMenu_AddButton(filterSourceBtnInfo)
	
	filterSourceBtnInfo.text = L["Alts"]
	filterSourceBtnInfo.value = FILTER_INSTANCE_OPT_ALTS
	filterSourceBtnInfo.checked = Interface.sourceFilter == FILTER_INSTANCE_OPT_ALTS
	UIDropDownMenu_AddButton(filterSourceBtnInfo)
	
	filterSourceBtnInfo.text = L["Remote"]
	filterSourceBtnInfo.value = FILTER_INSTANCE_OPT_REMOTE
	filterSourceBtnInfo.checked = Interface.sourceFilter == FILTER_INSTANCE_OPT_REMOTE
	UIDropDownMenu_AddButton(filterSourceBtnInfo)
	
	UIDropDownMenu_SetSelectedValue(Interface.logFilterSource, Interface.sourceFilter)
end

local function MatchListUpdate()
	local frame = Interface.matchlistFrame
	local entries = frame.entries
	local numEntries = #Interface.filteredMatches
	local listSize = min(numEntries, MAX_LIST_SIZE)

	local scrollFrame = frame.scrollFrame
	
	local offset = FauxScrollFrame_GetOffset(scrollFrame)
	FauxScrollFrame_Update(scrollFrame, numEntries, listSize, LIST_ENTRY_HEIGHT)

	-- if the list gets shortened so much that all entries are below the current offset then adjust the offset
	if offset + MAX_LIST_SIZE > numEntries then
		offset = numEntries - MAX_LIST_SIZE
		if offset < 0 then
			offset = 0
		end
		FauxScrollFrame_SetOffset(scrollFrame, offset)
	end	
	
	for i = 1, MAX_LIST_SIZE do
		local index = i + offset
		local entry = entries[i]

		if index <= numEntries then
			local data = Interface.filteredMatches[index]
			entry.timeFrame.text:SetText(format_time(data.timestamp+Addon:GetTimeOffset()))
			entry.authorFrame.text:SetText(Addon:ColorizeChar(tostring(data.player)))
			entry.msgFrame.text:SetText(NS:TranslateInstance(data.instance))
			
			entry.data = data
			
			if Interface.selectedMatch == data then
				entry:SetBackdropColor(1, 1, 1, 1)
			else
				entry:SetBackdropColor(0, 0, 0, .33)
			end
			
			entry:Show()
		else
			entry:Hide()
		end
		
		if scrollFrame:IsShown() then
			entry:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -1*(i-1)*LIST_ENTRY_HEIGHT - 3)
		else
			entry:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -1*(i-1)*LIST_ENTRY_HEIGHT - 3)
		end		
	end
end

-- module handling
function Interface:OnInitialize()
	self.filteredMatches  = {}

	self:Setup()
end

function Interface:OnEnable()
	-- empty
end

function Interface:OnDisable()
	-- empty
end

-- log window
function Interface:Setup()
	-- log window setup
	local backdrop = {
		-- path to the background texture
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", 
		-- path to the border texture
		edgeFile = "Interface\\TutorialFrame\\TutorialFrameBorder",
		-- true to repeat the background texture to fill the frame, false to scale it
		tile = true,
		-- size (width or height) of the square repeating background tiles (in pixels)
		tileSize = 32,
		-- thickness of edge segments and square size of edge corners (in pixels)
		edgeSize = 28,
		-- distance from the edges of the frame to those of the background texture (in pixels)
		insets = {
			left   = 5,
			right  = 2,
			top    = 20,
			bottom = 5
		}
	}
	
	self.logWindow = CreateFrame("Frame", ADDON.."LogWindow", UIParent)
	self.logWindow:SetFrameStrata("DIALOG")
	self.logWindow:CreateTitleRegion():SetAllPoints()
	self.logWindow:SetToplevel(true)
	self.logWindow:EnableMouse(true)
	self.logWindow:SetMovable(true)
	self.logWindow:SetUserPlaced(true)
	self.logWindow:SetHeight(370)
	self.logWindow:SetWidth(500)
	self.logWindow:SetBackdrop(backdrop)
	self.logWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	self.logWindow:RegisterForDrag("LeftButton")
	
	tinsert(UISpecialFrames, self.logWindow:GetName())
	
	local titleBar = self.logWindow:CreateTitleRegion()
	titleBar:SetPoint("TOPRIGHT", -5, 0)
	titleBar:SetPoint("TOPLEFT", 5, 0)
	titleBar:SetHeight(28)

	self.logWindow.title = self.logWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	self.logWindow.title:SetPoint("CENTER", titleBar, "CENTER", 0, 8)
	self.logWindow.title:SetText(Addon.FULLNAME .. " - " .. L["Log Window"])
	
	local button = CreateFrame("Button", nil, self.logWindow, "UIPanelCloseButton")
	button:SetPoint("TOPRIGHT", 5, 6)
	
	-- label for instance filter
	local frame = CreateFrame("Frame", nil, self.logWindow)
	frame:SetHeight(20)
	frame:SetWidth(85)
	frame:SetPoint("TOPLEFT", self.logWindow, "TOPLEFT", 15, -35)
	
	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("LEFT", frame, "LEFT")
	text:SetText(L["Show Instance:"])
	
	-- combobox for instance filter
	self.instanceFilter = FILTER_INSTANCE_OPT_ALL
	
	self.logFilterInstance = CreateFrame("Frame", ADDON.."InstanceFilter", self.logWindow, "UIDropDownMenuTemplate")
	
	self.logFilterInstance:ClearAllPoints()
	self.logFilterInstance:SetPoint("TOPLEFT", self.logWindow, "TOPLEFT", 100, -30)
	
	UIDropDownMenu_Initialize(self.logFilterInstance, InitInstanceFilter)
	UIDropDownMenu_SetWidth(self.logFilterInstance, 100);
	UIDropDownMenu_SetButtonWidth(self.logFilterInstance, 124)
	UIDropDownMenu_JustifyText(self.logFilterInstance, "LEFT")
 
	-- label for source filter
	local frame = CreateFrame("Frame", nil, self.logWindow)
	frame:SetHeight(20)
	frame:SetWidth(85)
	frame:SetPoint("TOPLEFT", self.logWindow, "TOPLEFT", 260, -35)
	
	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("LEFT", frame, "LEFT")
	text:SetText(L["Show Source:"])

	-- combobox for source filter
	self.sourceFilter = FILTER_INSTANCE_OPT_ALL
	
	self.logFilterSource = CreateFrame("Frame", ADDON.."SourceFilter", self.logWindow, "UIDropDownMenuTemplate")
	
	self.logFilterSource:ClearAllPoints()
	self.logFilterSource:SetPoint("TOPLEFT", self.logWindow, "TOPLEFT", 355, -30)
	
	UIDropDownMenu_Initialize(self.logFilterSource, InitSourceFilter)
	UIDropDownMenu_SetWidth(self.logFilterSource, 100);
	UIDropDownMenu_SetButtonWidth(self.logFilterSource, 124)
	UIDropDownMenu_JustifyText(self.logFilterSource, "LEFT")
	
	-- THE list
	backdrop = {
		-- path to the background texture
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", 
		-- path to the border texture
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		-- true to repeat the background texture to fill the frame, false to scale it
		tile = true,
		-- size (width or height) of the square repeating background tiles (in pixels)
		tileSize = 16,
		-- thickness of edge segments and square size of edge corners (in pixels)
		edgeSize = 16,
		-- distance from the edges of the frame to those of the background texture (in pixels)
		insets = {
			left   = 5,
			right  = 5,
			top    = 5,
			bottom = 5
		}
	}
	frame = CreateFrame('Frame', self.logWindow:GetName() .. 'FSList', self.logWindow)
	frame:SetHeight(MAX_LIST_SIZE*LIST_ENTRY_HEIGHT+6)
	frame:SetWidth(480)
	frame:SetBackdrop(backdrop)
	frame:SetPoint("TOPLEFT", self.logWindow, "TOPLEFT", 10, -70)

	-- list entries
	frame.entries = {}

	backdrop = {
		-- path to the background texture
		bgFile = "Interface\\QuestFrame\\UI-QuestTitleHighlight", 
		-- true to repeat the background texture to fill the frame, false to scale it
		tile = false,
		-- distance from the edges of the frame to those of the background texture (in pixels)
		insets = {
			left   = 1,
			right  = 1,
			top    = 1,
			bottom = 1
		}
	}
	
	for i=1, MAX_LIST_SIZE do
		local entry = CreateFrame('Button', frame:GetName() .. 'Entry' .. tostring(i), frame)
		entry:SetHeight(LIST_ENTRY_HEIGHT)
		entry:SetPoint("TOPLEFT",  frame, "TOPLEFT",   3, -1*(i-1)*LIST_ENTRY_HEIGHT - 3)
		entry:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -1*(i-1)*LIST_ENTRY_HEIGHT - 3)
		entry:SetBackdrop(backdrop)
		entry:SetBackdropColor(0, 0, 0, .33)
		-- entry:EnableMouse(true)
		entry:SetScript('OnEnter', function(self) self:SetBackdropColor(1, 1, 1, 1); if self.data then GameTooltip:SetOwner(self, 'ANCHOR_CURSOR'); GameTooltip:SetText(self.data.message); end; end)
		entry:SetScript('OnLeave', function(self) if self.data ~= Interface.selectedMatch then self:SetBackdropColor(0, 0, 0, .33); end; GameTooltip:Hide(); end)
		entry:SetScript('OnClick', function(self, button, down) Interface:SetSelectedEntry(self) end)
		
		frame.entries[i] = entry
		
		-- subframes holding text for time, author and message
		entry.timeFrame = CreateFrame('Frame', entry:GetName() .. '1', entry)
		entry.timeFrame:SetHeight(LIST_ENTRY_HEIGHT)
		entry.timeFrame:SetWidth(60)
		entry.timeFrame:SetPoint("TOPLEFT", entry, "TOPLEFT", 5, 0)
		entry.timeFrame.text = entry.timeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		entry.timeFrame.text:SetAllPoints()
		entry.timeFrame.text:SetJustifyH("LEFT")
		
		entry.authorFrame = CreateFrame('Frame', entry:GetName() .. '1', entry)
		entry.authorFrame:SetHeight(LIST_ENTRY_HEIGHT)
		entry.authorFrame:SetWidth(100)
		entry.authorFrame:SetPoint("TOPLEFT", entry.timeFrame, "TOPRIGHT", 5, 0)
		entry.authorFrame.text = entry.authorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		entry.authorFrame.text:SetAllPoints()
		entry.authorFrame.text:SetJustifyH("LEFT")
		
		entry.msgFrame = CreateFrame('Frame', entry:GetName() .. '1', entry)
		entry.msgFrame:SetHeight(LIST_ENTRY_HEIGHT)
		entry.msgFrame:SetPoint("TOPLEFT", entry.authorFrame, "TOPRIGHT", 5, 0)
		entry.msgFrame:SetPoint("TOPRIGHT", entry, "TOPRIGHT")
		entry.msgFrame.text = entry.msgFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		entry.msgFrame.text:SetAllPoints()
		entry.msgFrame.text:SetJustifyH("LEFT")
	end
	
	-- the scrollframe
	local scroll = CreateFrame('ScrollFrame', frame:GetName() .. 'ScrollFrame', frame, 'FauxScrollFrameTemplate')
	scroll:SetPoint('TOPLEFT', 5, -4)
	scroll:SetPoint('BOTTOMRIGHT', -26, 3)
	scroll:SetScript('OnVerticalScroll', function(self, arg1)
		FauxScrollFrame_OnVerticalScroll(self, arg1, LIST_ENTRY_HEIGHT, function() MatchListUpdate() end)
	end)
	frame.scrollFrame = scroll

	frame:SetScript('OnShow', function(self) MatchListUpdate() end)
	
	self.matchlistFrame = frame
	
	-- frame for the whole entry including message
	backdrop = {
		-- path to the background texture
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", 
		-- path to the border texture
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		-- true to repeat the background texture to fill the frame, false to scale it
		tile = true,
		-- size (width or height) of the square repeating background tiles (in pixels)
		tileSize = 16,
		-- thickness of edge segments and square size of edge corners (in pixels)
		edgeSize = 16,
		-- distance from the edges of the frame to those of the background texture (in pixels)
		insets = {
			left   = 5,
			right  = 5,
			top    = 5,
			bottom = 5
		}
	}
	local frame2 = CreateFrame('Frame', self.logWindow:GetName() .. 'Message', self.logWindow)
	frame2:SetHeight(40)
	frame2:SetWidth(480)
	frame2:SetBackdrop(backdrop)
	frame2:SetPoint("TOPLEFT", self.logWindow, "TOPLEFT", 10, -285)
	
	frame2.text = frame2:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame2.text:SetAllPoints()
	frame2.text:SetPoint("TOPLEFT",     frame2, "TOPLEFT",      5, -5)
	frame2.text:SetPoint("BOTTOMRIGHT", frame2, "BOTTOMRIGHT", -5,  5)
	frame2.text:SetJustifyH("LEFT")
	frame2.text:SetJustifyV("TOP")
	frame2.text:SetWordWrap(true)
	frame2.text:SetNonSpaceWrap(false) 
	
	self.messageFrame = frame2
	
	-- whisper button
	local button = CreateFrame("Button", nil, self.logWindow, "UIPanelButtonTemplate")
	button:SetHeight(20)
	button:SetWidth(80)
	button:SetText("Whisper")
	button:SetScript("OnClick", function(self, button, down) Interface:Whisper() end)
	button:SetPoint("TOPLEFT", self.logWindow, "TOPLEFT", 210, -335)
	
	self.whisperButton = button
end

function Interface:ShowLogWindow()
	if not self.logWindow:IsShown() then
		self.logWindow:Show()
	end
end

function Interface:HandleInstanceFilter(value)
	if not value or value == self.instanceFilter then
		return
	end
	
	self.instanceFilter = value
		
	self:UpdateLogList()
end

function Interface:HandleSourceFilter(value)
	if not value or value == self.sourceFilter then
		return
	end
	
	self.sourceFilter = value
	
	self:UpdateLogList()
end

function Interface:SetSelectedEntry(selected)
	if not selected then
		return
	end
	
	-- deselect old match
	for i=1, MAX_LIST_SIZE do
		local entry = self.matchlistFrame.entries[i]

		if entry.data == self.selectedMatch then
			entry:SetBackdropColor(0, 0, 0, .33)
		end
	end
	
	-- really needed? if we click the frame OnEnter should have colored it properly before anyway
	selected:SetBackdropColor(1, 1, 1, 1)
	
	self.selectedMatch = selected.data
	
	self:DisplaySelectedMessage()
end

function Interface:DisplaySelectedMessage()
	if self.selectedMatch then
		local match = self.selectedMatch
		local text = NS:TranslateInstance(match.instance) .. " - [" .. format_time(match.timestamp + Addon:GetTimeOffset()) .. "] " .. Addon:ColorizeChar(match.player) .. ": " .. match.message
		
		self.messageFrame.text:SetText(text)
		
		-- enable whisper button
		self.whisperButton:Enable()		
	else
		self.messageFrame.text:SetText("")
		
		-- disable whisper button
		self.whisperButton:Disable()		
	end
end

function Interface:UpdateLogList()
	NS:ClearTable(self.filteredMatches)

	local found = false 
	
	for _, match in Addon:IterateActiveMatches() do			
		-- check source filter
		local validSource = false
		
		if self.sourceFilter == FILTER_INSTANCE_OPT_ALL then
			validSource = true
		elseif self.sourceFilter == FILTER_INSTANCE_OPT_SELF then
			if not match.source and match.char == Addon.PlayerName then
				validSource = true
			end
		elseif self.sourceFilter == FILTER_INSTANCE_OPT_ALTS then
			if not match.source and match.char ~= Addon.PlayerName then
				validSource = true
			end
		elseif self.sourceFilter == FILTER_INSTANCE_OPT_REMOTE then
			if match.source then
				validSource = true
			end
		end
		
		-- check instance filter
		local validInstance = false

		if self.instanceFilter == FILTER_INSTANCE_OPT_ALL then
			validInstance = true
		elseif match.instance == self.instanceFilter then
			validInstance = true
		end
		
		-- insert into filtered matches
		if validSource and validInstance then
			tinsert(self.filteredMatches, match)
			
			if match.class then
				Addon:RestoreClassToCache(match.player, match.class)
			end
			
			if match == self.selectedMatch then
				found = true
			end
		end
	end
	
	if not found then
		-- reset selection
		self.selectedMatch = nil

		self:DisplaySelectedMessage()
	end
	
	MatchListUpdate()
end

function Interface:GetSelectedCharacter()
	return self.selectedMatch and self.selectedMatch.player
end

function Interface:Whisper()
	return Addon:WhisperCharacter(self:GetSelectedCharacter())
end

-- test
function Interface:Debug(msg)
	Addon:Debug("(Interface) " .. msg)
end
