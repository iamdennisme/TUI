--[[ *******************************************************************
Project                 : BRF_Forwarder
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
L["/brfforwarder arg"] = "/brfforwarder arg"
L["/brffwd arg"] = "/brffwd arg"
L["Args:"] = "Argumente:"
L["on - activate forwarding"] = "on - Weiterleitung aktivieren"
L["off - deactivate forwarding"] = "off - Weiterleitung deaktivieren"
L["version - display version information"] = "version - Versionsinformation anzeigen"
L["help - display this help"] = "help - diese Hilfe anzeigen"
		
L["Plugin adds support to forward LFG messages over a shared channel. This allows cross addon communication for all users of this plugin."] = "Modul, welches Nachrichten über einen verborgenen Kanal weiterleitet und somit eine Addon-übergreifende Kommunikation für alle Benutzer dieses Moduls ermöglicht."
	
L["Message forwarding active."] = "Nachrichtenweiterleitung aktiv"
L["Using fallback channel"] = "Ausweichkanal in Verwendung."
L["Current channel owner is on ignore list."] = "Aktueller Kanalbesitzer ist auf der Ignorieren-Liste."
L["Not connected to forwarding channel."] = "Kanal für Weiterleitung nicht aktiv."
L["No forwarder available."] = "Kein Sender verfügbar."
L["Operation paused in major city."] = "Betrieb in Hauptstadt pausiert."
	
L["Version"] = "Version"
