local _G = _G

-- addon name and namespace
local ADDON, NS = ...

-- get translations
local L = LibStub:GetLibrary("AceLocale-3.0"):GetLocale(ADDON)

local GetMapNameByID = _G.GetMapNameByID

-- get localized mob name from id
-- taken from _NPCScan by Saiket
do
	local tooltip = CreateFrame("GameTooltip", ADDON .. "_NPCScanTooltip")
	
	-- Add template text lines
	local text = tooltip:CreateFontString();
	
	tooltip:AddFontStrings(text, tooltip:CreateFontString())
	--- Checks the cache for a given NpcID.
	-- @return Localized name of the NPC if cached, or nil if not.
	function NS:TestNPCName(id)
		tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
		tooltip:SetHyperlink(( "unit:0xF53%05X00000000" ):format(id))
		if tooltip:IsShown() then
			return text:GetText()
		end
	end
end

NS.extensionTranslations = {
	[-1] = L["Custom"],
	[0] = _G.EXPANSION_NAME0,
	[1] = _G.EXPANSION_NAME1,
	[2] = _G.EXPANSION_NAME2,
	[3] = _G.EXPANSION_NAME3,
	[4] = _G.EXPANSION_NAME4,
	[5] = _G.EXPANSION_NAME5,
}

NS.instances = {
	-- Custom
	[-1] = {
		"Custom Keywords",
		"Challenge Mode",
		"Heroic Scenario",
		"Mythic Dungeon",
		"Rated Battleground",
		"Timewalking",
	},
	-- Classic
	[0] = {
		"Blackwing Lair",
		"Blackrock Spire",
		"Molten Core",
		"Ruins of Ahn'Qiraj",
		"Temple of Ahn'Qiraj",
	},
	-- The Burning Crusade
	[1] = {
		"Black Temple",
		"Gruul's Lair",
		"Karazhan",
		"Magtheridon's Lair",
		"Mount Hyjal",
		"Serpentshrine Cavern",
		"Sunwell Plateau",
		"Tempest Keep",
		"Zul'Aman",
	},
	-- Wrath of the Lich King
	[2] = {
		"The Eye of Eternity",
		"Icecrown Citadel",
		"Naxxramas",
		"The Obsidian Sanctum",
		"Onyxia's Lair",
		"The Ruby Sanctum",
		"Trial of the Crusader",
		"Ulduar",
		"Vault of Archavon",
	},
	-- Cataclysm
	[3] = {
		"Baradin Hold",
		"The Bastion of Twilight",
		"Blackwing Descent",
		"Dragon Soul",
		"Firelands",
		"Throne of the Four Winds",
	},
	-- Mists of Pandaria
	[4] = {
		"The Four Celestials",
		"Galleon",
		"Heart of Fear",
		"Mogu'shan Vaults",
		"Nalak",
		"Oondasta",
		"Ordos",
		"Sha of Anger",
		"Siege of Orgrimmar",
		"Terrace of the Endless Spring",
		"Throne of Thunder",
	},
	-- Warlords of Draenor
	[5] = {
		"Blackrock Foundry",
		"Drov the Ruiner",
		"Hellfire Citadel",
		"Highmaul",
		"Rukhmar",
		"Supreme Lord Kazzak",
		"Tarlna the Ageless",
	},
}

NS.instanceList = {}

do
	for extension, instances in pairs(NS.instances) do
		for _, instance in ipairs(instances) do
			NS.instanceList[instance] = extension
		end
	end
end

NS.defaultLFGKeywords = L["LFGDefaultKeywords"]

NS.defaultInstanceKeywords = {
	-- Custom
	["Custom Keywords"]               = "",
	["Challenge Mode"]                = L["DefaultKeywords-Challenge Mode"],
	["Heroic Scenario"]               = L["DefaultKeywords-Heroic Scenario"],
	["Mythic Dungeon"]                = L["DefaultKeywords-Mythic Dungeon"],
	["Rated Battleground"]            = L["DefaultKeywords-Rated Battleground"],
	["Timewalking"]                   = L["DefaultKeywords-Timewalking"],
	-- Classic
	["Blackwing Lair"]                = L["DefaultKeywords-Blackwing Lair"],
	["Blackrock Spire"]               = L["DefaultKeywords-Blackrock Spire"],
	["Molten Core"]                   = L["DefaultKeywords-Molten Core"],
	["Ruins of Ahn'Qiraj"]            = L["DefaultKeywords-Ruins of Ahn'Qiraj"],
	["Temple of Ahn'Qiraj"]           = L["DefaultKeywords-Temple of Ahn'Qiraj"],
	-- The Burning Crusade
	["Black Temple"]                  = L["DefaultKeywords-Black Temple"],
	["Gruul's Lair"]                  = L["DefaultKeywords-Gruul's Lair"],
	["Karazhan"]                      = L["DefaultKeywords-Karazhan"],
	["Magtheridon's Lair"]            = L["DefaultKeywords-Magtheridon's Lair"],
	["Mount Hyjal"]                   = L["DefaultKeywords-Mount Hyjal"],
	["Serpentshrine Cavern"]          = L["DefaultKeywords-Serpentshrine Cavern"],
	["Sunwell Plateau"]               = L["DefaultKeywords-Sunwell Plateau"],
	["Tempest Keep"]                  = L["DefaultKeywords-Tempest Keep"],
	["Zul'Aman"]                      = L["DefaultKeywords-Zul'Aman"],
	-- Wrath of the Lich King
	["The Eye of Eternity"]           = L["DefaultKeywords-The Eye of Eternity"],
	["Icecrown Citadel"]              = L["DefaultKeywords-Icecrown Citadel"],
	["Naxxramas"]                     = L["DefaultKeywords-Naxxramas"],
	["The Obsidian Sanctum"]          = L["DefaultKeywords-The Obsidian Sanctum"],
	["Onyxia's Lair"]                 = L["DefaultKeywords-Onyxia's Lair"],
	["The Ruby Sanctum"]              = L["DefaultKeywords-The Ruby Sanctum"],
	["Trial of the Crusader"]         = L["DefaultKeywords-Trial of the Crusader"],
	["Ulduar"]                        = L["DefaultKeywords-Ulduar"],
	["Vault of Archavon"]             = L["DefaultKeywords-Vault of Archavon"],
	-- Cataclysm
	["Baradin Hold"]                  = L["DefaultKeywords-Baradin Hold"],
	["The Bastion of Twilight"]       = L["DefaultKeywords-The Bastion of Twilight"],
	["Blackwing Descent"]             = L["DefaultKeywords-Blackwing Descent"],
	["Dragon Soul"]                   = L["DefaultKeywords-Dragon Soul"],
	["Firelands"]                     = L["DefaultKeywords-Firelands"],
	["Throne of the Four Winds"]      = L["DefaultKeywords-Throne of the Four Winds"],
	-- Mists of Pandaria
	["The Four Celestials"]           = L["DefaultKeywords-The Four Celestials"],
	["Galleon"]                       = L["DefaultKeywords-Galleon"],
	["Heart of Fear"]                 = L["DefaultKeywords-Heart of Fear"],
	["Mogu'shan Vaults"]              = L["DefaultKeywords-Mogu'shan Vaults"],
	["Nalak"]                         = L["DefaultKeywords-Nalak"],
	["Oondasta"]                      = L["DefaultKeywords-Oondasta"],
	["Ordos"]                         = L["DefaultKeywords-Ordos"],
	["Sha of Anger"]                  = L["DefaultKeywords-Sha of Anger"],
	["Siege of Orgrimmar"]            = L["DefaultKeywords-Siege of Orgrimmar"],
	["Terrace of the Endless Spring"] = L["DefaultKeywords-Terrace of the Endless Spring"],
	["Throne of Thunder"]             = L["DefaultKeywords-Throne of Thunder"],
	-- Warlords of Draenor
	["Blackrock Foundry"]             = L["DefaultKeywords-Blackrock Foundry"],
	["Drov the Ruiner"]               = L["DefaultKeywords-Drov the Ruiner"],
	["Hellfire Citadel"]              = L["DefaultKeywords-Hellfire Citadel"],
	["Highmaul"]                      = L["DefaultKeywords-Highmaul"],
	["Rukhmar"]                       = L["DefaultKeywords-Rukhmar"],
	["Supreme Lord Kazzak"]           = L["DefaultKeywords-Supreme Lord Kazzak"],
	["Tarlna the Ageless"]            = L["DefaultKeywords-Tarlna the Ageless"],
}

NS.instanceTranslations = {
	-- Custom
	["Custom Keywords"]               = L["Custom Keywords"],
	["Challenge Mode"]                = L["Challenge Mode"],
	["Heroic Scenario"]               = L["Heroic Scenario"],
	["Mythic Dungeon"]                = L["Mythic Dungeon"],
	["Rated Battleground"]            = L["Rated Battleground"],
	["Timewalking"]                   = L["Timewalking"],
	-- Classic
	["Blackwing Lair"]                = GetMapNameByID(755)   or "Blackwing Lair",
	["Blackrock Spire"]               = GetMapNameByID(696)   or "Blackrock Spire",
	["Molten Core"]                   = GetMapNameByID(721)   or "Molten Core",
	["Ruins of Ahn'Qiraj"]            = GetMapNameByID(717)   or "Ruins of Ahn'Qiraj",
	["Temple of Ahn'Qiraj"]           = GetMapNameByID(766)   or "Temple of Ahn'Qiraj",
	-- The Burning Crusade
	["Black Temple"]                  = GetMapNameByID(796)   or "Black Temple",
	["Gruul's Lair"]                  = GetMapNameByID(776)   or "Gruul's Lair",
	["Karazhan"]                      = GetMapNameByID(799)   or "Karazhan",
	["Magtheridon's Lair"]            = GetMapNameByID(779)   or "Magtheridon's Lair",
	["Mount Hyjal"]                   = GetMapNameByID(775)   or "Mount Hyjal",
	["Serpentshrine Cavern"]          = GetMapNameByID(780)   or "Serpentshrine Cavern",
	["Sunwell Plateau"]               = GetMapNameByID(789)   or "Sunwell Plateau",
	["Tempest Keep"]                  = GetMapNameByID(782)   or "Tempest Keep",
	["Zul'Aman"]                      = GetMapNameByID(781)   or "Zul'Aman",
	-- Wrath of the Lich King
	["The Eye of Eternity"]           = GetMapNameByID(527)   or "The Eye of Eternity",
	["Icecrown Citadel"]              = GetMapNameByID(604)   or "Icecrown Citadel",
	["Naxxramas"]                     = GetMapNameByID(535)   or "Naxxramas",
	["The Obsidian Sanctum"]          = GetMapNameByID(531)   or "The Obsidian Sanctum",
	["Onyxia's Lair"]                 = GetMapNameByID(718)   or "Onyxia's Lair",
	["The Ruby Sanctum"]              = GetMapNameByID(609)   or "The Ruby Sanctum",
	["Ulduar"]                        = GetMapNameByID(529)   or "Ulduar",
	["Trial of the Crusader"]         = GetMapNameByID(543)   or "Trial of the Crusader",
	["Vault of Archavon"]             = GetMapNameByID(532)   or "Vault of Archavon",
	-- Cataclysm
	["Baradin Hold"]                  = GetMapNameByID(752)   or "Baradin Hold",
	["The Bastion of Twilight"]       = GetMapNameByID(758)   or "The Bastion of Twilight",
	["Blackwing Descent"]             = GetMapNameByID(754)   or "Blackwing Descent",
	["Dragon Soul"]                   = GetMapNameByID(824)   or "Dragon Soul",
	["Firelands"]                     = GetMapNameByID(800)   or "Firelands",
	["Throne of the Four Winds"]      = GetMapNameByID(773)   or "Throne of the Four Winds",
	-- Mists of Pandaria
	["The Four Celestials"]           = _G.WORLD_BOSS_FOUR_CELESTIALS or "The Four Celestials",
	["Galleon"]                       = NS:TestNPCName(62346) or "Galleon",
	["Heart of Fear"]                 = GetMapNameByID(897)   or "Heart of Fear",
	["Mogu'shan Vaults"]              = GetMapNameByID(896)   or "Mogu'shan Vaults",
	["Nalak"]                         = NS:TestNPCName(69099) or "Nalak",
	["Oondasta"]                      = NS:TestNPCName(69161) or "Oondasta",
	["Ordos"]                         = NS:TestNPCName(72057) or "Ordos",
	["Sha of Anger"]                  = NS:TestNPCName(60491) or "Sha of Anger",
	["Siege of Orgrimmar"]            = GetMapNameByID(953)   or "Siege of Orgrimmar",
	["Terrace of the Endless Spring"] = GetMapNameByID(886)   or "Terrace of the Endless Spring",
	["Throne of Thunder"]             = GetMapNameByID(930)   or "Throne of Thunder",
	-- Warlords of Draenor
	["Blackrock Foundry"]             = GetMapNameByID(988)   or "Blackrock Foundry",
	["Drov the Ruiner"]               = NS:TestNPCName(81252) or "Drov the Ruiner",
	["Hellfire Citadel"]              = GetMapNameByID(1448)  or "Hellfire Citadel",
	["Highmaul"]                      = GetMapNameByID(994)   or "Highmaul",
	["Rukhmar"]                       = NS:TestNPCName(87493) or "Rukhmar",
	["Supreme Lord Kazzak"]           = NS:TestNPCName(94015) or "Supreme Lord Kazzak",
	["Tarlna the Ageless"]            = NS:TestNPCName(81535) or "Tarlna the Ageless",
}

NS.worldBosses = {
	-- Mists of Pandaria
	["The Four Celestials"]           = _G.WORLD_BOSS_FOUR_CELESTIALS or "The Four Celestials",
	["Galleon"]                       = NS:TestNPCName(62346) or "Galleon",
	["Nalak"]                         = NS:TestNPCName(69099) or "Nalak",
	["Oondasta"]                      = NS:TestNPCName(69161) or "Oondasta",
	["Ordos"]                         = NS:TestNPCName(72057) or "Ordos",
	["Sha of Anger"]                  = NS:TestNPCName(60491) or "Sha of Anger",
	-- Warlords of Draenor
	["Drov the Ruiner"]               = NS:TestNPCName(81252) or "Drov the Ruiner",
	["Rukhmar"]                       = NS:TestNPCName(87493) or "Rukhmar",
	["Supreme Lord Kazzak"]           = NS:TestNPCName(94015) or "Supreme Lord Kazzak",
	["Tarlna the Ageless"]            = NS:TestNPCName(81535) or "Tarlna the Ageless",
}

function NS:TranslateExpansion(id)
	return NS.extensionTranslations[id] or ""
end

function NS:TranslateInstance(instance)
	if type(instance) ~= "string" then
		return ""
	end

	return NS.instanceTranslations[instance] or instance
end

function NS:IsValidInstance(instance)
	return NS.instanceList[instance] and true or false
end

function NS:IsWorldBoss(instance)
	return NS.worldBosses[instance] and true or false
end

function NS:IterateInstances()
	return pairs(NS.instanceList)
end
