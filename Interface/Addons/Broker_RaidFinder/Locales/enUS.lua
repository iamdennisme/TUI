--[[ *******************************************************************
Project                 : Broker_RaidFinder
Description             : English translation file (enUS)
Author                  : burny_dd
Translator              : burny_dd
Revision                : $Rev: 1 $
********************************************************************* ]]

local ADDON = ...

local L = LibStub:GetLibrary("AceLocale-3.0"):NewLocale(ADDON, "enUS", true, true)
if not L then return end

-- keywords which indicate players looking for group
L["LFGDefaultKeywords"] = "lfg, lfm, lfr, lf%d, lf%s, any1, looking for, anyone up, anyone for, anyone doing"

-- default keywords for raids (all lower-case)
-- make sure we only use a minimal but definite set 
-- Custom
L["DefaultKeywords-Challenge Mode"] = "challenge"
L["DefaultKeywords-Heroic Scenario"] = "hc scenario, heroic scenario"
L["DefaultKeywords-Mythic Dungeon"] = "mythic"
L["DefaultKeywords-Rated Battleground"] = "rbg, rated bg, rated battle"
L["DefaultKeywords-Timewalking"] = "twalk, timewalk"
-- Classic
L["DefaultKeywords-Blackwing Lair"] = "bwl, blackwing lair"
L["DefaultKeywords-Blackrock Spire"] = "brs, blackrock spire"
L["DefaultKeywords-Molten Core"] = "%smc[^%a], %smc$, molten core"
L["DefaultKeywords-Ruins of Ahn'Qiraj"] = "aq20, ruins of ahn"
L["DefaultKeywords-Temple of Ahn'Qiraj"] = "%saq[^%a], %saq$, aq40, temple of ahn"
-- The Burning Crusade
L["DefaultKeywords-Black Temple"] = "%sbt[^%a], %sbt$, black temple"
L["DefaultKeywords-Gruul's Lair"] = "gruul"
L["DefaultKeywords-Karazhan"] = "kara, karazhan"
L["DefaultKeywords-Magtheridon's Lair"] = "maggi, magtheridon"
L["DefaultKeywords-Mount Hyjal"] = "%smh[^%a], %smh$, hyjal"
L["DefaultKeywords-Serpentshrine Cavern"] = "ssc, serpentshrine"
L["DefaultKeywords-Sunwell Plateau"] = "sunwell, swp"
L["DefaultKeywords-Tempest Keep"] = "%stk, tempest keep"
L["DefaultKeywords-Zul'Aman"] = "%sza[^%a], %sza$, zulaman, zul aman, zul'aman"
-- Wrath of the Lich King
L["DefaultKeywords-The Eye of Eternity"] = "eoe, eye of eternity, maly"
L["DefaultKeywords-Icecrown Citadel"] = "icc, icecrown, %slk, lich king, frozen throne"
L["DefaultKeywords-Naxxramas"] = "naxx"
L["DefaultKeywords-The Obsidian Sanctum"] = "%sos[^%a], %sos$, obsidian sanctum"
L["DefaultKeywords-Onyxia's Lair"] = "onyxia"
L["DefaultKeywords-The Ruby Sanctum"] = "%srs[^%a], %srs$, ruby sanctum"
L["DefaultKeywords-Trial of the Crusader"] = "totc, crusader, colliseum"
L["DefaultKeywords-Ulduar"] = "ulduar"
L["DefaultKeywords-Vault of Archavon"] = "voa, archavon"
-- Cataclysm
L["DefaultKeywords-Baradin Hold"] = "%sbh[^%a], %sbh$, baradin hold"
L["DefaultKeywords-The Bastion of Twilight"] = "%sbot, %sbot$, bastion of twilight"
L["DefaultKeywords-Blackwing Descent"] = "%sbd, bwd, blackwing descent"
L["DefaultKeywords-Dragon Soul"] = "%sds[^%a], %sds$, dragon soul, dragonsoul, deathwing"
L["DefaultKeywords-Firelands"] = "%sfl[^%a], %sfl$, fireland"
L["DefaultKeywords-Throne of the Four Winds"] = "tofw, to4w, four winds"
-- Mists of Pandaria
L["DefaultKeywords-The Four Celestials"] = "tfc, t4c, celestials, chi-ji, chiji, yu'lon, yu’lon, yulon, niuzao, xuen"
L["DefaultKeywords-Galleon"] = "galleon, salyis"
L["DefaultKeywords-Heart of Fear"] = "%shof[^%a], %shof$, heart of fear"
L["DefaultKeywords-Mogu'shan Vaults"] = "%smv[^%a], %smv$, msv, mogushan, mogu'shan, vaults"
L["DefaultKeywords-Nalak"] = "nalak"
L["DefaultKeywords-Oondasta"] = "oondasta"
L["DefaultKeywords-Ordos"] = "ordos"
L["DefaultKeywords-Sha of Anger"] = "%ssha[^%a], %ssha$"
L["DefaultKeywords-Siege of Orgrimmar"] = "%ssoo[^%a], %ssoo$, %ssiege"
L["DefaultKeywords-Terrace of the Endless Spring"] = "%stes[^%a], %stes$, %stoes[^%a], %stoes$, totes, terrace"
L["DefaultKeywords-Throne of Thunder"] = "%stot[^%a], %stot$, thunder, throne"
-- Warlords of Draenor
L["DefaultKeywords-Blackrock Foundry"] = "brf, foundry"
L["DefaultKeywords-Drov the Ruiner"] = "drov"
L["DefaultKeywords-Hellfire Citadel"] = "%shfc, %shc[^%a], %shc$, hellfire, citadel"
L["DefaultKeywords-Highmaul"] = "highmaul"
L["DefaultKeywords-Rukhmar"] = "rukhmar"
L["DefaultKeywords-Supreme Lord Kazzak"] = "kazzak"
L["DefaultKeywords-Tarlna the Ageless"] = "tarlna"

L["Custom"]             = true
L["Custom Keywords"]    = true
L["Challenge Mode"]     = true
L["Heroic Scenario"]    = true
L["Mythic Dungeon"]     = true
L["Rated Battleground"] = true
L["Timewalking"]        = true

L["Default"]  = true
L["Revert to default LFG keywords"] = true

L["Show All"] = true
L["Self"]     = true
L["Alts"]     = true
L["Remote"]   = true

L["Raids"] = true
L["Set up which raids you will monitor."] = true	

L["Keywords"] = true
L["Set up keywords for each instance."] = true

L["LFG Keywords"] = true
L["Comma separated list of keywords indicating someone is looking for players for a raid."] = true

L["Monitoring"] = true
L["Set up monitoring parmaters for addon."] = true
L["Guild Chat"] = true
L["Monitor guild chat."] = true
L["Monitor Say"] = true
L["Monitor say in chat."] = true
L["Monitor Yell"] = true
L["Monitor yell in chat."] = true
L["Exclude Saved Raids"] = true
L["Exclude raids you are currently saved to."] = true
L["Time Frame"] = true
L["Set up how many minutes the log will reach back."] = true

L["Notifications"] = true
L["Set up notifications when addon finds a match."] = true
L["Text Alert"] = true
L["Show text message when addon finds a match."] = true
L["Toast Alert"] = true
L["Show toast notification when addon finds a match."] = true
L["Sound Alert"] = true
L["Play sound when addon finds a match."] = true
L["Notification Sound"] = true
L["Choose sound to be played on notifications."] = true
L["Play Sound"] = true
L["Play selected notification sound."] = true
L["Timeout"] = true
L["Set notification timeout. You will not be notified about matches of a single player for the same instance more than once during the timeout duration."] = true

L["Monitoring Active"] = true
L["Activate/Deactivate the monitoring."] = true
L["Addon Communication"] = true
L["Toggle whether or not the addon shall sync with addons of other players. This is restricted to (mutual) friends and guild members."] = true
L["Use Spam-Filter"] = true
L["If you got a spam blocker installed the addon will apply the filtering to the messages before processing them."] = true
L["Minimap Button"] = true
L["Show Minimap Button."] = true
L["Hide Hint"] = true
L["Hide usage hint in tooltip."] = true

L["Monitor chat for "] = true
L["Keywords for "] = true
L["Revert to default keywords for "] = true

L["Plugins"] = true
L["Manage plugins."] = true
L["Active"] = true
L["Activate/Deactivate plug-in."] = true
L["Label"] = true
L["Append plugin label text to label."] = true
L["Tooltip"] = true
L["Append plugin messages to tooltip."] = true
		
L["Log Window"] = true
L["Show Instance:"] = true
L["Show Source:"] = true

L["Usage:"] = true
L["/braidfinder arg"] = true
L["/brfind arg"] = true
L["Args:"] = true
L["version - display version information"] = true
L["menu - display options menu"] = true
L["on - activate monitoring"] = true
L["off - deactivate monitoring"] = true
L["show - show log window"] = true
L["help - display this help"] = true

-- I for instance P for Player
L["I: "] = true
L["P: "] = true

L["Remote client is monitoring."] = true
L["Monitoring is switched off."] = true

L["Plug-in"] = true

L["Left-Click"] = true
L["Show logging window."] = true
L["Alt-Click"] = true
L["Enable/disable monitoring."] = true
L["Right-Click"] = true
L["Open option menu."] = true
L["Left-Click Tip"] = true
L["Click on instance name to toggle monitoring."] = true
L["Ctrl-Hover Tip"] = true
L["Press Ctrl while opening tooltip shows all instances."] = true

L["Version"] = true

L["Found new match for %s from player %s."] = true
