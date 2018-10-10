local _G = _G

-- addon name and namespace
local ADDON, NS = ...

local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON)

-- the Plugins module
local Plugins = Addon:NewModule("Plugins", "AceTimer-3.0")

-- local functions
local tinsert           = table.insert
local pairs             = pairs

local _

-- get translations
local L = LibStub:GetLibrary("AceLocale-3.0"):GetLocale(ADDON)

-- module handling
function Plugins:OnInitialize()
	self.plugins = {}
	
	self.order = 0
	self.options = {
		type = 'group',
		name = L["Plugins"],
		desc = L["Manage plugins."],
		order = 100,
		args = {
			-- filled dynamically
		},
	}
	
	local options = Addon:GetModule("Options")
	
	self.db = options:GetPluginDB()

	options:InsertPluginOptions(self.options)
	
	-- decouple refresh requests by plugins
	self.pluginLabelNeedsRefresh = false
	self.pluginLabelUpdateTimer = self:ScheduleRepeatingTimer("RefreshPluginLabel", 1)
end

function Plugins:OnEnable()
	-- empty
end

function Plugins:OnDisable()
	-- empty
end

function Plugins:GetOptions()
	return self.options
end

function Plugins:SetupDB()
	local options = Addon:GetModule("Options")
	
	self.db = options:GetPluginDB()
end

function Plugins:RegisterPlugin(plugin)
	if type(plugin) ~= "table" then 
		self:Debug("RegisterPlugin: no plugin provided")
		return false
	end
	
	-- check interface
	if not self:IsValidPlugin(plugin) then
		self:Debug("RegisterPlugin: plugin doesn't implement interface")
		return false
	end
	
	local name = plugin:GetPluginName()
	
	if not name or name == "" then
		self:Debug("RegisterPlugin: plugin doesn't provide name")
		return false
	end
	
	-- already registered
	if self:HasPlugin(name) then
		self:Debug("RegisterPlugin: plugin '" .. tostring(name) .. "' already registered")
		return false
	end
	
	-- register plugin
	self.plugins[name] = plugin
	
	-- register options
	self:RegisterPluginOptions(plugin)
	
	-- set active
	plugin:SetActive(self:IsSetActive(name))
	
	return true
end

function Plugins:UnregisterPlugin(plugin)
	if not plugin or not plugin.GetPluginName or not self:HasPlugin(plugin:GetPluginName()) then 
		return
	end
	
	-- unregister options
	self:UnregisterPluginOptions(plugin)
	
	-- unregister plugin
	self.plugins[plugin:GetPluginName()] = nil
end

function Plugins:RegisterPluginOptions(plugin)
	local name = plugin:GetPluginName()

	if not self:HasPlugin(name) then
		return
	end
	
	self:AddPluginToDB(name)
	
	self.order = self.order + 10
	
	local order = self.order
	
	-- description
	self.options.args[name.."-description"] = {
		type = "description",
		name = NS:Colorize("Yellow", name) .. ": " .. plugin:GetPluginDescription(),
		order = order + 1,
	}	
	
	-- active
	self.options.args[name.."-active"] = {
		type = 'toggle',
		name = L["Active"],
		desc = L["Activate/Deactivate plugin."],
		order = order + 2,
		get = function() 
			return self:IsSetActive(name)
		end,
		set = function()
			self:ToggleIsSetActive(name)
		end,	
	}
	
	-- label
	self.options.args[name.."-label"] = {
		type = 'toggle',
		name = L["Label"],
		desc = L["Append plugin label text to label."],
		order = order + 3,
		get = function() 
			return self:ShowLabel(name)
		end,
		set = function()
			self:ToggleShowLabel()
		end,	
	}
	
	-- tooltip
	self.options.args[name.."-tooltip"] = {
		type = 'toggle',
		name = L["Tooltip"],
		desc = L["Append plugin messages to tooltip."],
		order = order + 4,
		get = function() 
			return self:ShowTooltip(name)
		end,
		set = function()
			self:ToggleShowTooltip()
		end,	
	}
end

function Plugins:UnregisterPluginOptions(plugin)
	local name = plugin:GetPluginName()
	
	if not self:HasPlugin(name) then
		return
	end
	
	-- remove plugin active checkbox to plugin page
	self.options.args[name.."-description"] = nil
	self.options.args[name.."-active"]      = nil
	self.options.args[name.."-label"]       = nil
	self.options.args[name.."-tooltip"]     = nil
end

function Plugins:IsValidPlugin(plugin)
	-- check interface
	if type(plugin) == "table" and 
		type(plugin.GetPluginDescription) == "function" and
		type(plugin.IsActive) == "function" and
		type(plugin.SetActive) == "function" and
		type(plugin.GetLabelText) == "function" and
		type(plugin.GetTooltipMessages) == "function" and
		type(plugin.HandleEvent) == "function" then
		return true
	end
	
	return false
end

function Plugins:AddPluginToDB(name)
	if not self:HasPlugin(name) then
		return
	end	

	if not self.db[name] then
		self.db[name] = {}
		
		self.db[name].active  = false
		self.db[name].label   = true
		self.db[name].tooltip = true		
	end
end

function Plugins:CheckPluginDB(name)
	if not self:HasPlugin(name) then
		return false
	end
	
	if not self.db[name] then
		self:AddPluginToDB(name)
	end
	
	return true
end

function Plugins:IteratePlugins()
	return pairs(self.plugins)
end

function Plugins:HasPlugin(name)
	return self.plugins[name] ~= nil
end

function Plugins:GetPlugin(name)
	return self.plugins[name]
end

function Plugins:HandleEvent(event, data)
	for name, plugin in pairs(self.plugins) do
		if self:IsSetActive(name) and plugin:IsActive() then
			plugin:HandleEvent(event, data)
		end
	end
end

function Plugins:HandleAction(action, name, ...)
	if not action or action == "list" then
		Addon:Output("Registered plugins:")
		for name, plugin in pairs(self.plugins) do
			Addon:Output(name .. ": " .. (plugin:IsActive() and "activated" or "deactivated"))
		end
		
		return
	end
		
	if not name then
		Addon:Output("Missing plugin name.")
		
		return
	end

	if not self:HasPlugin(name) then
		Addon:Output("Plugin '" .. name .. "' not found.")
		
		return
	end
	
	local plugin = self.plugins[name]
	
	if action == "status" then
		Addon:Output(name .. ": " .. (plugin:IsActive() and "activated" or "deactivated"))
	elseif action == "activate" then
		plugin:SetActive(true)
	elseif action == "deactivate" then
		plugin:SetActive(false)
	elseif action == "exec" then
		if plugin.TriggerAction then
			plugin:TriggerAction(...)
		else
			Addon:Output("Plugin '" .. name .. "' cannot execute commands.")
		end
	end	
end

function Plugins:RequestUpdatePluginLabel()
	self.pluginLabelNeedsRefresh = true
end

function Plugins:RefreshPluginLabel()
	if self.pluginLabelNeedsRefresh then
		Addon:UpdateLabel()
		self.pluginLabelNeedsRefresh = false
	end
end

function Plugins:GetFullLabel()
	local label = ""

	for name, plugin in self:IteratePlugins() do
		if self:ShowLabel(name) and plugin:IsActive() then
			local ptext = plugin:GetLabelText()
			
			if ptext then
				label = label .. " " .. ptext
			end
		end
	end
	
	return label
end

-- settings
function Plugins:SetShowLabel(name, show)
	if self:CheckPluginDB(name) and show ~= self:ShowLabel(name) then
		self.db[name].label = show
		Addon:UpdateLabel()
	end
end

function Plugins:ToggleShowLabel(name)
	self:SetShowLabel(name, not self:ShowLabel(name))
end

function Plugins:ShowLabel(name)
	return self.db[name] and self.db[name].label or false
end

function Plugins:SetShowTooltip(name, show)
	if self:CheckPluginDB(name) and show ~= self:ShowTooltip(name) then
		self.db[name].tooltip = show
	end
end

function Plugins:ToggleShowTooltip(name)
	self:SetShowTooltip(name, not self:ShowTooltip(name))
end

function Plugins:ShowTooltip(name)
	return self.db[name] and self.db[name].tooltip or false
end

function Plugins:SetIsSetActive(name, active)
	if self:CheckPluginDB(name) and active ~= self:IsSetActive(name) then
		self.db[name].active = active
		
		self.plugins[name]:SetActive(self.db[name].active)
	end
end

function Plugins:ToggleIsSetActive(name)
	self:SetIsSetActive(name, not self:IsSetActive(name))
end

function Plugins:IsSetActive(name)
	return self.db[name] and self.db[name].active or false
end

-- test
function Plugins:Debug(msg)
	Addon:Debug("(Plugins) " .. msg)
end

-- plugin host
local function RegisterPlugin(self, plugin)
	return Plugins:RegisterPlugin(plugin)
end

local function UnregisterPlugin(self, plugin)
	return Plugins:UnregisterPlugin(plugin)
end

local function IsMonitoredChannel(self, id)
	return Addon:IsMonitoredChannel(id)
end

local function UpdateLabel(self)
	return Plugins:RequestUpdatePluginLabel()
end

local function ProcessMessage(self, plugin, message, author, sender)
	if not plugin or type(plugin) ~= "table" or type(plugin.GetPluginName) ~= "function" then
		return
	end

	local name = plugin:GetPluginName()
	
	-- get the local plugin for name
	local lPlugin = Plugins:GetPlugin(name)
	
	-- only registered and active plugins may use addon
	if lPlugin == plugin and Plugins:IsSetActive(name) and plugin:IsActive() then
		return Addon:ProcessMessage(message, author, sender)
	end
end

local function IterateMonitoredInstances(self)
	return Addon:IterateMonitoredInstances()
end

local function IterateInstanceKeywords(self, instance)
	return Addon:IterateInstanceKeywords(instance)
end

local function IsWorldBoss(self, instance)
	return NS:IsWorldBoss(instance)
end

local function TranslateInstance(self, instance)
	return NS:TranslateInstance(instance)
end

-- create a plugin host object
function BRFGetPluginHost()
	local host = {}
	
	host.RegisterPlugin            = RegisterPlugin
	host.UnregisterPlugin          = UnregisterPlugin
	host.IsMonitoredChannel        = IsMonitoredChannel
	host.UpdateLabel               = UpdateLabel
	host.ProcessMessage            = ProcessMessage
	host.IterateMonitoredInstances = IterateMonitoredInstances
	host.IterateInstanceKeywords   = IterateInstanceKeywords
	host.IsWorldBoss               = IsWorldBoss
	host.TranslateInstance         = TranslateInstance
	
	host.EVENT_MATCH_LFG    = Addon.EVENT_MATCH_LFG
	host.EVENT_MATCH_LOCAL  = Addon.EVENT_MATCH_LOCAL
	host.EVENT_MATCH_REMOTE = Addon.EVENT_MATCH_REMOTE
	
	return host
end
