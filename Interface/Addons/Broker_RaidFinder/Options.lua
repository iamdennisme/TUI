local _G = _G

-- addon name and namespace
local ADDON, NS = ...

local Addon = LibStub("AceAddon-3.0"):GetAddon(ADDON)

-- the Options module
local Options = Addon:NewModule("Options")

-- internal event handling
Options.callbacks = LibStub("CallbackHandler-1.0"):New(Options)

-- local functions
local pairs   = pairs
local tinsert = table.insert

local GetExpansionLevel = _G.GetExpansionLevel

local _

local LibStub   = LibStub

-- config libraries
local AceConfig 		= LibStub:GetLibrary("AceConfig-3.0")
local AceConfigReg 		= LibStub:GetLibrary("AceConfigRegistry-3.0")
local AceConfigDialog	= LibStub:GetLibrary("AceConfigDialog-3.0")

-- translations
local L = LibStub:GetLibrary("AceLocale-3.0"):GetLocale(ADDON)

-- local variables
local defaults = {
	profile = {
		monitoringActive	= true,
		monitorGuild		= true,
		monitorSay	    	= false,
		monitorYell  		= false,
		excludeSavedRaids	= false,
		notifyText			= true,
		notifySound			= false,
		notifyToast			= true,
		notificationSound	= 0,
		notificationTimeout	= 5,
		timeFrame			= 60,
		addonCommunication	= false,
		hideHint			= false,
        minimap				= false,
        messageFilters		= false,
        filterMatches		= false,
		monitored           = {},
		plugins				= {},
	},
	factionrealm = {
		matches = {},
	},
	global = {
		lfgKeywords      = NS.defaultLFGKeywords,
		instanceKeywords = {},
	}
}

-- local variables
local soundFiles = {
	[0] = "Sound\\interface\\iTellMessage.ogg",
	[1] = "Sound\\Spells\\BeastCall.ogg",
	[2] = "Sound\\Doodad\\BellTollAlliance.ogg",
	[3] = "Sound\\Doodad\\BellTollHorde.ogg",
	[4] = "Sound\\Doodad\\BellTollNightElf.ogg",
	[5] = "Sound\\Doodad\\BellTollTribal.ogg",
	[6] = "Sound\\Doodad\\BlastedLandsLightningbolt01Stand-Bolt.ogg",
	[7] = "Sound\\Spells\\Bonk1.ogg",
	[8] = "Sound\\Spells\\Bonk2.ogg",
	[9] = "Sound\\Spells\\Bonk3.ogg",
	[10] = "Sound\\Doodad\\TK_Control_Consoles.ogg",
	[11] = "Sound\\interface\\DropOnGround.ogg",
	[12] = "Sound\\interface\\DwarfExploration.ogg",
	[13] = "Sound\\Doodad\\DwarfHorn.ogg",
	[14] = "Sound\\interface\\Error.ogg",
	[15] = "Sound\\Doodad\\Firecrackers_ThrownExplode.ogg",
	[16] = "Sound\\Doodad\\G_GongTroll01.ogg",
	[17] = "Sound\\Events\\GuldanCheers.ogg",
	[18] = "Sound\\Doodad\\KharazahnBellToll.ogg",
	[19] = "Sound\\Spells\\KillCommand.ogg",
	[20] = "Sound\\interface\\MapPing.ogg",
	[21] = "Sound\\Doodad\\G_Mortar.ogg",
	[22] = "Sound\\interface\\RaidWarning.ogg",
	[23] = "Sound\\interface\\ReadyCheck.ogg",
	[24] = "Sound\\Doodad\\BE_ScryingOrb_Explode.ogg",
	[25] = "Sound\\Doodad\\Sizzle.ogg",
	[26] = "Sound\\Spells\\ThrowWater.ogg",
	[27] = "Sound\\interface\\UnsheathMetal.ogg",
	[28] = "Sound\\interface\\UnsheathShield.ogg",
	[29] = "Sound\\Event Sounds\\Wisp\\WispPissed1.ogg",
	[30] = "Sound\\Event Sounds\\Wisp\\WispReady1.ogg",
	[31] = "Sound\\Event Sounds\\Wisp\\WispWhat1.ogg",
	[32] = "Sound\\Event Sounds\\Wisp\\WispYes1.ogg",
}

local soundNames = {
	[0] = L["Default"].." (Tell Message)",
	[1] = "Beast Call",
	[2] = "Bell Toll Alliance",
	[3] = "Bell Toll Horde",
	[4] = "Bell Toll Night Elf",
	[5] = "Bell Toll Tribal",
	[6] = "Bolt",
	[7] = "Bonk 1",
	[8] = "Bonk 2",
	[9] = "Bonk 3",
	[10] = "Control Consoles",
	[11] = "Drop On Ground",
	[12] = "Dwarf Exploration",
	[13] = "Dwarf Horn",
	[14] = "Error",
	[15] = "Firecrackers",
	[16] = "Gong Troll",
	[17] = "Guldan Cheers",
	[18] = "Kharazahn Bell Toll",
	[19] = "Kill Command",
	[20] = "Map Ping",
	[21] = "Mortar",
	[22] = "Raid Warning",
	[23] = "Ready Check",
	[24] = "ScryingOrb Explode",
	[25] = "Sizzle",
	[26] = "ThrowWater",
	[27] = "Unsheath Metal",
	[28] = "Unsheath Shield",
	[29] = "Wisp Pissed",
	[30] = "Wisp Ready",
	[31] = "Wisp What",
	[32] = "Wisp Yes",
}

local monitorChatOptions = {
	["guild"] = "monitorGuild",
	["say"]   = "monitorSay",
	["yell"]  = "monitorYell",
}

-- module handling
function Options:OnInitialize()
	-- init localized keywords
	for instance in NS:IterateInstances() do
		defaults.global.instanceKeywords[instance] = NS.defaultInstanceKeywords[instance]
	end

	-- options
	self.options = {}
	
	self.db = LibStub:GetLibrary("AceDB-3.0"):New(Addon.MODNAME.."_DB", defaults, "Default")
		
	self:Setup()
	
	-- profile support
	self.options.args.profile = LibStub:GetLibrary("AceDBOptions-3.0"):GetOptionsTable(self.db)
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied",  "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset",   "OnProfileChanged")

	AceConfigReg:RegisterOptionsTable(Addon.FULLNAME, self.options)
	AceConfigDialog:AddToBlizOptions(Addon.FULLNAME)
end

function Options:OnEnable()
	-- empty
end

function Options:OnDisable()
	-- empty
end

function Options:OnProfileChanged(event, database, newProfileKey)
	self.db.profile = database.profile
	
	Addon:OnOptionsReloaded()
end

-- setup
function Options:Setup()	
    self.options = {
		handler = Options,
		type = 'group',
		args = {
			raids = {
				type = 'group',
				name = L["Raids"],
				desc = L["Set up which raids you will monitor."],
				order = 10,
				args = {
					-- filled dynamically
				},
			},			
			keywords = {
				type = 'group',
				name = L["Keywords"],
				desc = L["Set up keywords for each instance."],
				order = 20,
				args = {
					lfgkeywords = {
						type = "input",
						name = L["LFG Keywords"],
						desc = L["Comma separated list of keywords indicating someone is looking for players for a raid."],
						order = 1,
						multiline = 4,
						get = function()
								return self:GetLFGKeywords()
							end,
						set = function(info, key)
							self:SetLFGKeywords(key)
						end,
					},
					-- restore default keywords button
					defaultlfgkeywords = {
						type = "execute",
						name = L["Default"],
						desc = L["Revert to default LFG keywords"],
						order = 2,
						func = function()
							self:SetLFGKeywords(NS.defaultLFGKeywords)
						end,	
					}
					-- raid keywords filled dynamically
				},
			},			
			monitoring = {
				type = 'group',
				name = L["Monitoring"],
				desc = L["Set up monitoring parmaters for addon."],
				order = 30,
				args = {
					guild = {
						type = 'toggle',
						name = L["Guild Chat"],
						desc = L["Monitor guild chat."],
						order = 1,
						get = function() return self:GetSetting("monitorGuild") end,
						set = function() 
							self:ToggleSetting("monitorGuild")
						end,
					},
					say = {
						type = 'toggle',
						name = L["Monitor Say"],
						desc = L["Monitor say in chat."],
						order = 2,
						get = function() return self:GetSetting("monitorSay") end,
						set = function() 
							self:ToggleSetting("monitorSay")
						end,
					},
					yell = {
						type = 'toggle',
						name = L["Monitor Yell"],
						desc = L["Monitor yell in chat."],
						order = 3,
						get = function() return self:GetSetting("monitorYell") end,
						set = function() 
							self:ToggleSetting("monitorYell")
						end,
					},
					saved = {
						type = 'toggle',
						name = L["Exclude Saved Raids"],
						desc = L["Exclude raids you are currently saved to."],
						order = 4,
						get = function() return self:GetSetting("excludeSavedRaids") end,
						set = function() 
							self:ToggleSetting("excludeSavedRaids")
						end,
					},
					timeframe = {
						type = 'range',
						name = L["Time Frame"],
						desc = L["Set up how many minutes the log will reach back."],
						order = 5,
						get = function() return self:GetSetting("timeFrame") end,	
						set = function(info, key) 
							self:SetSetting("timeFrame", key)
						end,
						min = 0,
						max = Addon.MAX_TIME_RANGE,
						step = 1,
					},
				},
			},			
			notifications = {
				type = 'group',
				name = L["Notifications"],
				order = 40,
				desc = L["Set up notifications when addon finds a match."],
				args = {
					text = {
						type = 'toggle',
						name = L["Text Alert"],
						desc = L["Show text message when addon finds a match."],
						order = 1,
						get = function() return self:GetSetting("notifyText") end,
						set = function() 
							self:ToggleSetting("notifyText")
						end,
					},
					toast = {
						type = 'toggle',
						name = L["Toast Alert"],
						desc = L["Show toast notification when addon finds a match."],
						order = 2,
						get = function() return self:GetSetting("notifyToast") end,
						set = function() 
							self:ToggleSetting("notifyToast")
						end,
					},
					sound = {
						type = 'toggle',
						name = L["Sound Alert"],
						desc = L["Play sound when addon finds a match."],
						order = 3,
						get = function() return self:GetSetting("notifySound") end,
						set = function() 
							self:ToggleSetting("notifySound")
						end,
					},
					notificationSound = { 
						type = 'select',
						name = L["Notification Sound"],
						desc = L["Choose sound to be played on notifications."],
						order = 4,
						get = function() return self:GetSetting("notificationSound") end,	
						set = function(info, key) 
							self:SetSetting("notificationSound", key)
						end,
						values = soundNames,
					},
					playSound = { 
						type = 'execute',
						name = L["Play Sound"],
						desc = L["Play selected notification sound."],
						order = 5,
						func = function() Addon:PlaySoundFile(self:GetSoundFile(Options:GetSetting("notificationSound"))) end,	
					},
					timeout = {
						type = 'range',
						name = L["Timeout"],
						desc = L["Set notification timeout. You will not be notified about matches of a single player for the same instance more than once during the timeout duration."],
						order = 6,
						get = function() return self:GetSetting("notificationTimeout") end,	
						set = function(info, key) 
							self:SetSetting("notificationTimeout", key)
						end,
						min = 0,
						max = Addon.MAX_TIME_RANGE,
						step = 1,
					},
				},
			},
			extras = {
				type = 'group',
				name = L["Extras"],
				order = 50,
				desc = L["Some of the more exotic settings."],
				args = {
					msgFilter = {
						type = 'toggle',
						name = L["Message Filter"],
						desc = L["Applies registered message filters before message processing. If you are using a plugin for forwarding messages it is recommended to run a spam filtering addon and check this option to avoid being reported for spam forwarding by other peoples spam filter addons."],
						order = 1,
						get  = function() return self:GetSetting("messageFilters") end,
						set  = function()
							self:ToggleSetting("messageFilters") 
						end,
					},
					filterMatches = {
						type = 'toggle',
						name = L["Filter Matches"],
						desc = L["If enabled removes matched messages from chat windows."],
						order = 2,
						get  = function() return self:GetSetting("filterMatches") end,
						set  = function()
							self:ToggleSetting("filterMatches") 
						end,
					},
				},
			},
			active = { 
				type = "toggle",
				name = L["Monitoring Active"],
				desc = L["Activate/Deactivate the monitoring."],
	            order = 1,
				get  = function() return self:GetSetting("monitoringActive") end,
				set  = function()
					self:ToggleSetting("monitoringActive") 
				end,
			},
			addonComm  = {
				type = "toggle",
				name = L["Addon Communication"],
				desc = L["Toggle whether or not the addon shall sync with addons of other players. This is restricted to (mutual) friends and guild members."],
				order = 2,
				get  = function() return self:GetSetting("addonCommunication") end,
				set  = function()
					self:ToggleSetting("addonCommunication") 
				end,
			},
			minimap = {
				type = 'toggle',
				name = L["Minimap Button"],
				desc = L["Show Minimap Button."],
				order = 3,
				get  = function() return self:GetSetting("minimap") end,
				set  = function()
					self:ToggleSetting("minimap")
				end,
			},
			hint = {
				type = 'toggle',
				name = L["Hide Hint"],
				desc = L["Hide usage hint in tooltip."],
				order = 4,
				get  = function() return self:GetSetting("hideHint") end,
				set  = function()
					self:ToggleSetting("hideHint") 
				end,
			},
		},
	}
	
	self:InsertRaidOptions()
end

function Options:InsertRaidOptions()
	local maxExpansion = GetExpansionLevel() or 0
	
	for extension, instances in pairs(NS.instances) do		
		local order = extension < 0 and 0 or (maxExpansion+1-extension)*1000
		
		local localizedExtension = NS:TranslateExpansion(extension)
		
		-- preface raids by extension name
		self.options.args.raids.args[localizedExtension] = {
			type = "header",
			name = NS:Colorize("Orange", L[localizedExtension]),
			order = order,
		}
		
		self.options.args.keywords.args[localizedExtension] = {
			type = "header",
			name = NS:Colorize("Orange", L[localizedExtension]),
			order = order,
		}
				
		for index, instance in pairs(instances) do
			local localizedInstance = NS:TranslateInstance(instance)
			
			-- raid monitoring
			self.options.args.raids.args[instance] = {
				type = 'toggle',
				name = localizedInstance,
				desc = L["Monitor chat for "] .. localizedInstance .. ".",
				order = order+10*index,
				get = function() return self:IsMonitored(instance) end,
				set = function() 
					self:ToggleMonitored(instance)
				end,
			}
			-- raid keywords
			self.options.args.keywords.args[instance] = {
				type = "input",
				name = localizedInstance,
				desc = L["Keywords for "] .. localizedInstance .. ".",
				order = order+10*index,
				multiline = 4,
				get = function() return self:GetInstanceKeywords(instance) end,
				set = function(info, key)
					self:SetInstanceKeywords(instance, key)
				end,
			}
			
			-- restore default keywords button
			self.options.args.keywords.args[instance.."-default"] = {
				type = "execute",
				name = L["Default"],
				desc = L["Revert to default keywords for "] .. localizedInstance .. ".",
				order = order+10*index+1,
				func = function()
					self:SetInstanceKeywords(instance, NS.defaultInstanceKeywords[instance])
				end,	
			}
		end
	end	
end

function Options:InsertPluginOptions(options)
	if not options or type(options) ~= "table" then
		return
	end

	self.options.args["plugins"] = options
	
	options.order = 100
end

-- settings
function Options:GetMatchTable()
	return self.db.factionrealm.matches
end

function Options:IsMonitored(instance)
	return self.db.profile.monitored[instance] == true
end

function Options:ToggleMonitored(instance)
	self:SetMonitored(instance, not self:IsMonitored(instance) and true or nil)
end

function Options:SetMonitored(instance, active)
	if not NS:IsValidInstance(instance) then
		return
	end

	local current = self:IsMonitored(instance)

	active = active and true or nil
	
	if current == (active or false) then
		return
	end
	
	self.db.profile.monitored[instance] = active
	
	-- fire event when monitoring changed
	self.callbacks:Fire(ADDON .. "_MONITORING_CHANGED", instance)
end

function Options:IsAnyInstanceMonitored()
	return next(self.db.profile.monitored) ~= nil
end

function Options:IterateMonitoredInstances()
	return pairs(self.db.profile.monitored)
end


-- keywords
function Options:SetLFGKeywords(value)
	if type(value) ~= "string" then
		return
	end
	
	local current = self:GetLFGKeywords(option)

	if current == value then
		return
	end
	
	self.db.global.lfgKeywords = value

	-- fire event when setting changed
	self.callbacks:Fire(ADDON .. "_SETTING_CHANGED", "lfgKeywords", value, current, "Keywords")
end

function Options:GetLFGKeywords()
	return self.db.global.lfgKeywords
end

function Options:SetInstanceKeywords(instance, value)
	if type(value) ~= "string" then
		return
	end
	
	local current = self:GetInstanceKeywords(instance)

	if current == value then
		return
	end
	
	self.db.global.instanceKeywords[instance] = value

	-- fire event when setting changed
	self.callbacks:Fire(ADDON .. "_SETTING_CHANGED", instance, value, current, "Keywords")
end

function Options:GetInstanceKeywords(instance)
	return self.db.global.instanceKeywords[instance]
end

-- set/get options
function Options:GetSetting(option)
	return self.db.profile[option]
end

function Options:SetSetting(option, value)
	local current = self:GetSetting(option)

	if current == value then
		return
	end
	
	self.db.profile[option] = value

	-- fire event when setting changed
	self.callbacks:Fire(ADDON .. "_SETTING_CHANGED", option, value, current)
end

function Options:ToggleSetting(option)
	self:SetSetting(option, not self:GetSetting(option) and true or false)
end

function Options:ToggleSettingTrueNil(option)
	self:SetSetting(option, not self:GetSetting(option) and true or nil)
end

-- utility
function Options:GetSoundFile(id)
	return soundFiles[id] or soundFiles[0]
end

-- plugin handling
function Options:GetPluginDB()
	return self.db.profile.plugins
end

-- test
function Options:Debug(msg)
	Addon:Debug("(Options) " .. msg)
end
