--[[ *******************************************************************
Project                 : BRF_ForwardingTracker
Description             : German translation file (deDE)
Author                  : burny_dd
Translator              : burny_dd
Revision                : $Rev: 1 $
********************************************************************* ]]

local ADDON = ...

local L = LibStub:GetLibrary("AceLocale-3.0"):NewLocale(ADDON, "deDE")
if not L then return end

L["found"] = "gefunden"
L["not found"] = "nicht gefunden"
L["Plug-in registered with BrokerRaidFinder"] = "Modul ist bei BrokerRaidFinder angemeldet."
L["Plug-in failed to register with BrokerRaidFinder"] = "Modul konnte nicht bei BrokerRaidFinder angemeldet werden."
L["Plug-in unregistered."] = "Modul abgemeldet."

L["Usage:"] = "Verwendung:"
L["/brffwdtracker arg"] = "/brffwdtracker arg"
L["/brftrack arg"] = "/brftrack arg"
L["Args:"] = "Argumente:"
L["on - activate tracking"] = "on - Überwachung aktivieren"
L["off - deactivate tracking"] = "off - Überwachung deaktivieren"
L["version - display version information"] = "version - Versionsinformation anzeigen"
L["help - display this help"] = "help - diese Hilfe anzeigen"
		
L["Plug-in keeps track of messages forwarded by LFGForwarder and TradeForwarder and feeds them to the addon."] = "Plug-in überwacht Nachrichten, die von LFGForwarder oder TradeForwarder weitergeleitet wurden und gibt diese an das Addon weiter."
	
L["No sender available."] = "kein Sender verfügbar."
L["Tracking in progress."] = "wird überwacht."
L["No data received for more than 3 minutes."] = "Seit mehr als 3 Minuten wurden keine Daten empfangen."
L["Cannot track LFG/TradeForwarder. Channel(s) not found."] = "LFG/TradeForwarder kann nicht überwacht werden. Kanäle nicht gefunden."
L["Tracking paused in major city."] = "Überwachung in Hauptstadt ausgesetzt."
	
L["Version"] = "Version"
