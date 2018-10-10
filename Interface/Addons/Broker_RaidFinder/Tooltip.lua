local _G = _G

-- addon name and namespace
local ADDON, NS = ...

local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON)

-- the Tooltip module
local Tooltip = Addon:NewModule("Tooltip")

-- get translations
local L = LibStub:GetLibrary("AceLocale-3.0"):GetLocale(ADDON)

-- tooltip library
local QT = LibStub:GetLibrary("LibQTip-1.0")

-- coloring tools
local Crayon = LibStub:GetLibrary("LibCrayon-3.0")

-- local functions
local pairs             = pairs
local next              = next
local floor             = floor

local GetExpansionLevel = GetExpansionLevel

-- local variables
local _

local tooltip = nil

-- utilities
local function ToggleInstance(cell, instance, button)
	Addon:ToggleMonitored(instance)
	Tooltip:Refresh()
end

-- module handling
function Tooltip:OnInitialize()
	-- empty
end

function Tooltip:OnEnable()
	-- empty
end

function Tooltip:OnDisable()
	self:Remove()
end

function Tooltip:Create(obj, autoHideDelay)
	if not self:IsEnabled() then
		return
	end

	autoHideDelay = autoHideDelay and autoHideDelay or 0.1

	tooltip = QT:Acquire(ADDON.."TT", 3)
	
	tooltip:Hide()
	tooltip:Clear()
	tooltip:SetScale(1)
		
	self:Draw()

	tooltip:SetAutoHideDelay(autoHideDelay, obj)
	tooltip:EnableMouse()
	tooltip:SmartAnchorTo(obj)
	tooltip:Show()
end

function Tooltip:Remove()
	if tooltip then
		tooltip:Hide()
		QT:Release(tooltip)
		tooltip = nil
	end
end

function Tooltip:Refresh()
	if not self:IsEnabled() then
		self:Remove()
		return
	end
	
	self:Draw()
	
	tooltip:Show()
	
	tooltip:UpdateScrolling()
end

-- tooltip
function Tooltip:Draw()
	if not tooltip then
		return
	end

	tooltip:Hide()
	tooltip:Clear()
	
	local now = time()
	
	-- addon header
	local lineNum = tooltip:AddHeader(" ")
	tooltip:SetCell(lineNum, 1, NS:Colorize("White", Addon.FULLNAME), "CENTER", tooltip:GetColumnCount())
	
	local ctrlKeyPressed = IsControlKeyDown()
	
	local timeframe = Addon:GetSetting("timeFrame") * 60

	-- monitored raids
	if ctrlKeyPressed or Addon:GetMonitoringActive() then
		local currentExpansion = GetExpansionLevel()
		
		-- for all expansions
		for expansion = currentExpansion + 1, 0, -1 do
			expansion = expansion > currentExpansion and -1 or expansion
			local headerPresent = false
			local instances = NS.instances[expansion]
			
			-- for all instances
			for _, instance in ipairs(instances) do
				local monitored = Addon:IsMonitored(instance)
				
				if ctrlKeyPressed or (Addon:IsMonitored(instance) and not Addon:ExcludeAsSaved(instance)) then 
					local saved = Addon:IsSaved(instance)

					local localizedInstance = NS:TranslateInstance(instance)
					
					if not headerPresent then
						-- set expansion name as header
						tooltip:AddLine(" ")
						lineNum = tooltip:AddLine(" ")
						tooltip:SetCell(lineNum, 1, NS:Colorize("Orange", NS:TranslateExpansion(expansion)), "LEFT", tooltip:GetColumnCount())
						
						headerPresent = true
					end

					lineNum = tooltip:AddLine(" ")
					
					if Addon.matchesLatest[instance] then
						-- instance
						if saved then
							tooltip:SetCell(lineNum, 1, NS:Colorize("Red", localizedInstance) .. " ", "LEFT")
						else
							tooltip:SetCell(lineNum, 1, NS:Colorize("Green", localizedInstance) .. " ", "LEFT")
						end

						local match = Addon.matchesLatest[instance]
						
						-- last player posting
						tooltip:SetCell(lineNum, 2, Addon:ColorizeChar(match.player) .. NS:Colorize("White", " (of " .. tostring(match.players) .. ") ") , "LEFT")
						
						-- time since posting
						local timestamp = now - match.timestamp
						local timestring = ""
						if Crayon then
							timestring = "|cff"..Crayon:GetThresholdHexColor(timestamp, timeframe, timeframe * 0.75, timeframe * 0.5, timeframe * 0.25, 1) .. NS:FormatTime(timestamp) .. "|r"
						else
							timestring = NS:FormatTime(timestamp)
						end				
						
						tooltip:SetCell(lineNum, 3, timestring, "RIGHT")
					else
						if saved then
							tooltip:SetCell(lineNum, 1, NS:Colorize("Red", localizedInstance) .. " ", "LEFT")
						elseif monitored then
							tooltip:SetCell(lineNum, 1, NS:Colorize("Blueish", localizedInstance) .. " ", "LEFT")
						else
							tooltip:SetCell(lineNum, 1, NS:Colorize("GrayOut", localizedInstance) .. " ", "LEFT")
						end
						
						-- no player
						tooltip:SetCell(lineNum, 2, NS:Colorize("GrayOut", "--"), "LEFT")
						
						-- no time
						tooltip:SetCell(lineNum, 3, NS:Colorize("GrayOut", "--"), "RIGHT")
					end
					
					tooltip:SetCellScript(lineNum, 1, "OnMouseDown", ToggleInstance, instance)					
				end			
			end	
		end
		
		local communication = Addon:GetModule("Communication")
		
		if communication and communication:IsConnected() then
			tooltip:AddLine(" ")
			lineNum = tooltip:AddLine(" ")
			tooltip:SetCell(lineNum, 1, NS:Colorize("Green", L["Remote client is monitoring."]), "LEFT", tooltip:GetColumnCount())
		end
	else
		lineNum = tooltip:AddLine(" ")
		tooltip:SetCell(lineNum, 1, NS:Colorize("Red", L["Monitoring is switched off."]), "LEFT", tooltip:GetColumnCount())
	end
	
	-- plugins
	local plugins = Addon:GetModule("Plugins")
	
	for name, plugin in plugins:IteratePlugins() do
		if plugins:ShowTooltip(name) and plugin:IsActive() then
			local messages = plugin:GetTooltipMessages() or {}
			
			if #messages > 0 then
				tooltip:AddLine(" ")
				lineNum = tooltip:AddLine(" ")
				tooltip:SetCell(lineNum, 1, NS:Colorize("Brownish", plugin:GetPluginName() .. " " .. L["Plugin"] .. ":"), "LEFT", tooltip:GetColumnCount())
			end
			
			for idx, msg in ipairs(messages) do
				lineNum = tooltip:AddLine(" ")
				tooltip:SetCell(lineNum, 1, msg, "LEFT", tooltip:GetColumnCount())
			end
		end
	end
	
	-- hint to show options
	if not Addon:GetSetting("hideHint") then
		tooltip:AddLine(" ")
		lineNum = tooltip:AddLine(" ")
		tooltip:SetCell(lineNum, 1, NS:Colorize("Brownish", L["Left-Click"] .. ":") .. " " .. NS:Colorize("Yellow", L["Show logging window."]), "LEFT", tooltip:GetColumnCount())
		lineNum = tooltip:AddLine(" ")
		tooltip:SetCell(lineNum, 1, NS:Colorize("Brownish", L["Alt-Click"] .. ":") .. " " .. NS:Colorize("Yellow", L["Enable/disable monitoring."]), "LEFT", tooltip:GetColumnCount())
		lineNum = tooltip:AddLine(" ")
		tooltip:SetCell(lineNum, 1, NS:Colorize("Brownish", L["Right-Click"] .. ":") .. " " .. NS:Colorize("Yellow", L["Open option menu."]), "LEFT", tooltip:GetColumnCount())
		lineNum = tooltip:AddLine(" ")
		tooltip:SetCell(lineNum, 1, NS:Colorize("Brownish", L["Left-Click Tip"] .. ":") .. " " .. NS:Colorize("Yellow", L["Click on instance name to toggle monitoring."]), "LEFT", tooltip:GetColumnCount())
		lineNum = tooltip:AddLine(" ")
		tooltip:SetCell(lineNum, 1, NS:Colorize("Brownish", L["Ctrl-Hover Tip"] .. ":") .. " " .. NS:Colorize("Yellow", L["Press Ctrl while opening tooltip shows all instances."]), "LEFT", tooltip:GetColumnCount())
	end	
end

-- test
function Tooltip:Debug(msg)
	Addon:Debug("(Tooltip) " .. msg)
end
