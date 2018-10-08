--[[ *******************************************************************
Project                 : Broker_RaidFinder
Description             : German translation file (deDE)
Author                  : burny_dd
Translator              : burny_dd
Revision                : $Rev: 1 $
********************************************************************* ]]

local ADDON = ...

local L = LibStub:GetLibrary("AceLocale-3.0"):NewLocale(ADDON, "deDE")
if not L then return end

-- keywords which indicate players looking for group
L["LFGDefaultKeywords"] = "lfg, lfm, lfr, lf%d, lf%s, suche"

-- default keywords for raids (all lower-case)
-- make sure we only use a minimal but definite set 
-- Custom
L["DefaultKeywords-Challenge Mode"] = "herausforder"
L["DefaultKeywords-Heroic Scenario"] = "hc szenario, heroisches szenario"
L["DefaultKeywords-Mythic Dungeon"] = "mythisch"
L["DefaultKeywords-Rated Battleground"] = "rbg, gewertet"
L["DefaultKeywords-Timewalking"] = "zeitwand"
-- Classic
L["DefaultKeywords-Blackwing Lair"] = "psh, pechschwingenhort"
L["DefaultKeywords-Blackrock Spire"] = "schwarzfelsspitze"
L["DefaultKeywords-Molten Core"] = "geschmolzener kern"
L["DefaultKeywords-Ruins of Ahn'Qiraj"] = "aq20, ruinen von ahn"
L["DefaultKeywords-Temple of Ahn'Qiraj"] = "%saq[^%a], %saq$, aq40, tempel von ahn"
-- The Burning Crusade
L["DefaultKeywords-Black Temple"] = "schwarze tempel, schwarzer tempel"
L["DefaultKeywords-Gruul's Lair"] = "gruul"
L["DefaultKeywords-Karazhan"] = "kara, karazhan"
L["DefaultKeywords-Magtheridon's Lair"] = "maggi, magtheridon"
L["DefaultKeywords-Mount Hyjal"] = "hiyal"
L["DefaultKeywords-Serpentshrine Cavern"] = "hds, schlangenschrein"
L["DefaultKeywords-Sunwell Plateau"] = "sunwell"
L["DefaultKeywords-Tempest Keep"] = "fds, festung der stürme"
L["DefaultKeywords-Zul'Aman"] = "%sza[^%a], %sza$, zulaman, zul aman, zul'aman"
-- Wrath of the Lich King
L["DefaultKeywords-The Eye of Eternity"] = "maly, auge der ewigkeit"
L["DefaultKeywords-Icecrown Citadel"] = "ekz, eiskrone"
L["DefaultKeywords-Naxxramas"] = "naxx"
L["DefaultKeywords-The Obsidian Sanctum"] = "obsidiansanktum"
L["DefaultKeywords-Onyxia's Lair"] = "onyxia"
L["DefaultKeywords-The Ruby Sanctum"] = "rubinsanktum"
L["DefaultKeywords-Trial of the Crusader"] = "pdk, prüfung, kreuzfahrer"
L["DefaultKeywords-Ulduar"] = "ulduar"
L["DefaultKeywords-Vault of Archavon"] = "voa, archavon"
-- Cataclysm
L["DefaultKeywords-Baradin Hold"] = "%sbf[^%a], %sbf$, baradinfest"
L["DefaultKeywords-The Bastion of Twilight"] = "bdz, bastion des zwielichts"
L["DefaultKeywords-Blackwing Descent"] = "psa, pechschwingenabstieg"
L["DefaultKeywords-Dragon Soul"] = "%sds[^%a], %sds$, drachenseele"
L["DefaultKeywords-Firelands"] = "feuerland"
L["DefaultKeywords-Throne of the Four Winds"] = "tdg, thron der gezeiten"
-- Mists of Pandaria
L["DefaultKeywords-The Four Celestials"] = "himmlischen, erhabenen, chi-ji, chiji, yu'lon, yu’lon, yulon, niuzao, xuen"
L["DefaultKeywords-Galleon"] = "galleon"
L["DefaultKeywords-Heart of Fear"] = "hda, herz der angst"
L["DefaultKeywords-Mogu'shan Vaults"] = "%swm[^%a], wvm, mogushan, mogu'shan"
L["DefaultKeywords-Nalak"] = "nalak"
L["DefaultKeywords-Oondasta"] = "oondasta"
L["DefaultKeywords-Ordos"] = "ordos"
L["DefaultKeywords-Sha of Anger"] = "%ssha[^%a], %ssha$"
L["DefaultKeywords-Siege of Orgrimmar"] = "%ssuo[^%a], %ssuo$, schlacht um orgrimmar"
L["DefaultKeywords-Terrace of the Endless Spring"] = "%stes[^%a], %stoes[^%a], totes, terrace"
L["DefaultKeywords-Throne of Thunder"] = "%stot[^%a], %stot$, %stdd, %sthron, donner"
-- Warlords of Draenor
L["DefaultKeywords-Blackrock Foundry"] = "sfg, schwarzfelsgießerei"
L["DefaultKeywords-Drov the Ruiner"] = "drov"
L["DefaultKeywords-Hellfire Citadel"] = "%shfz, %shz[^%a], %shz$, zitadelle"
L["DefaultKeywords-Highmaul"] = "hochfels"
L["DefaultKeywords-Rukhmar"] = "rukhmar"
L["DefaultKeywords-Supreme Lord Kazzak"] = "kazzak"
L["DefaultKeywords-Tarlna the Ageless"] = "tarlna"

L["Custom"]             = "Nutzerdefiniert"
L["Custom Keywords"]    = "Nutzerdefinierte Suchbegriffe"
L["Heroic Scenario"]    = "Heroisches Szenario"
L["Mythic Dungeon"]     = "Mythischer Dungeon"
L["Challenge Mode"]     = "Herausforderungsmodus"
L["Rated Battleground"] = "Gewertetes Schlachtfeld"
L["Timewalking"]        = "Zeitwanderung"

L["Default"]  = "Vorgabe"
L["Revert to default LFG keywords"] = "Zurück auf Standardeinstellungen für LFG-Schlüsselwörter"

L["Show All"] = "Zeige alle"
L["Self"]     = "Eigene"
L["Alts"]     = "Alts"
L["Remote"]   = "Andere"

L["Raids"] = "Raids"
L["Set up which raids you will monitor."] = "Einstellen der zu überwachenden Raids"	

L["Keywords"] = "Schlüsselwörter"
L["Set up keywords for each instance."] = "Einstellungen der Schlüsselwörter für alle Instanzen."

L["LFG Keywords"] = "LFG Schlüsselwörter"
L["Comma separated list of keywords indicating someone is looking for players for a raid."] = "Kommaseparierte Liste von Schlüsselwörtern, mit denen Spieler nach Raids suchen."

L["Monitoring"] = "Überwachung"
L["Set up monitoring parmaters for addon."] = "Überwachungseinstellungen für das Addon."
L["Guild Chat"] = "Gildenunterhaltung"
L["Monitor guild chat."] = "Gildenunterhaltung überwachen"
L["Monitor Say"] = "Überwache Sprechen"
L["Monitor say in chat."] = "Überwache Sprechen in Unterhaltungen"
L["Monitor Yell"] = "Überwache Schreien"
L["Monitor yell in chat."] = "Überwache Schreien in Unterhaltungen"
L["Exclude Saved Raids"] = "Keine gesperrten Instanzen"
L["Exclude raids you are currently saved to."] = "Gesperrte Instanzen von Überwachung ausnehmen."
L["Time Frame"] = "Zeitfenster"
L["Set up how many minutes the log will reach back."] = "Einstellung, wie viele Minuten die Protokollierung zurückreicht."

L["Notifications"] = "Benachrichtigungen"
L["Set up notifications when addon finds a match."] = "Einstellungen für Benachrichtigungen, wenn das Addon einen Treffer findet."
L["Text Alert"] = "Textalarm"
L["Show text message when addon finds a match."] = "Zeige Textnachricht, wenn Addon einen Treffer findet."
L["Toast Alert"] = "Toast-Alarm"
L["Show toast notification when addon finds a match."] = "Zeige Toast-Benachrichtigung, wenn Addon einen Treffer findet."
L["Sound Alert"] = "Sound-Alarm"
L["Play sound when addon finds a match."] = "Bei einem Treffer wird ein Sound gespielt."
L["Notification Sound"] = "Benachrichtigung-Sound"
L["Choose sound to be played on notifications."] = "Wähle Benachrichtigungs-Sound, der bei Treffern abgespielt werden soll."
L["Play Sound"] = "Sound abspielen"
L["Play selected notification sound."] = "Spielt den gewählten Benachrichtigungs-Sound ab."
L["Timeout"] = "Timeout"
L["Set notification timeout. You will not be notified about matches of a single player for the same instance more than once during the timeout duration."] = "Setzt den Benachrichtigungs-Timeout. Findet das Addon wiederholt Treffer vom selben Spieler, wird innerhalb dieser Zeit nur einmal die Benachrichtigung ausgelöst."

L["Monitoring Active"] = "Überwachung aktiv"
L["Activate/Deactivate the monitoring."] = "Aktiviere/Deaktiviere Überwachung."
L["Addon Communication"] = "Addon-Kommunikation"
L["Toggle whether or not the addon shall sync with addons of other players. This is restricted to (mutual) friends and guild members."] = "Aktiviert/Deaktiviert entfernte Überwachung durch Addons anderer Spieler. Dies ist beschränkt auf (beiderseitige) Freunde und Gildenmitglieder."
L["Use Spam-Filter"] = "Verwende Spam-Filter"
L["If you got a spam blocker installed the addon will apply the filtering to the messages before processing them."] = "Wenn ein Spam-Filter-Addon installiert ist, wird dieser verwendet, bevor die Nachrichten ausgewertet werden."
L["Minimap Button"] = "Minimap-Button"
L["Show Minimap Button."] = "Zeige Minimap-Button"
L["Hide Hint"] = "Hinweis verbergen"
L["Hide usage hint in tooltip."] = "Benutzungshinweise im Tooltip verbergen"

L["Monitor chat for "] = "Überwache Chat für "
L["Keywords for "] = "Schlüsselwörter für "
L["Revert to default keywords for "] = "Zurück auf Standardeinstellungen für "

L["Plugins"] = "Module"
L["Manage plugins."] = "Modulverwaltung"
L["Active"] = "Aktiv"
L["Activate/Deactivate plugin."] = "Aktiviere/Deaktiviere Modul"
L["Label"] = "Beschriftung"
L["Append plugin label text to label."] = "Erweitere Beschriftung um Modultext."
L["Tooltip"] = "Tooltip"
L["Append plugin messages to tooltip."] = "Erweitere Tooltip um Modulnachrichten."

L["Log Window"] = "Protokollfenster"
L["Show Instance:"] = "Zeige Instanz:"
L["Show Source:"] = "Zeige Quelle:"

L["Usage:"] = "Verwendung:"
L["/braidfinder arg"] = "/braidfinder arg"
L["/brfind arg"] = "/brfind arg"
L["Args:"] = "Argumente:"
L["version - display version information"] = "version - Versionsinformation anzeigen"
L["menu - display options menu"] = "menu - Optionsmenü anzeigen"
L["on - activate monitoring"] = "on - Überwachung einschalten"
L["off - deactivate monitoring"] = "off - Überwachung ausschalten"
L["show - show log window"] = "show - Protokollfenster anzeigen"
L["help - display this help"] = "help - diese Hilfe anzeigen"

-- I for instance P for Player
L["I: "] = "I: "
L["P: "] = "S: "

L["Remote client is monitoring."] = "Anderer Client überwacht."
L["Monitoring is switched off."] = "Überwachung ist abgeschaltet."

L["Plug-in"] = "Modul"

L["Left-Click"] = "Linksklick"
L["Show logging window."] = "Zeige Protokollfenster."
L["Alt-Click"] = "Alt-Klick"
L["Enable/disable monitoring."] = "Überwachung Ein/Aus."
L["Right-Click"] = "Rechtsklick"
L["Open option menu."] = "Optionsmenü öffnen."
L["Left-Click Tip"] = "Linksklick Tip"
L["Click on instance name to toggle monitoring."] = "Klick auf Instanznamen (de-)aktiviert Überwachung."
L["Ctrl-Hover Tip"] = "Strg halten Tip"
L["Press Ctrl while opening tooltip shows all instances."] = "Strg gedrückt halten beim Auslösen des Tooltips für Anzeige aller Instanzen."

L["Version"] = "Version"

L["Found new match for %s from player %s."] = "Neuer Treffer für %s von Spieler %s gefunden."
