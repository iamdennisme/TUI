--[[ *******************************************************************
Project                 : BRF_Forwarder
Description             : English translation file (enUS)
Author                  : burny_dd
Translator              : burny_dd
Revision                : $Rev: 1 $
********************************************************************* ]]

local ADDON = ...

local L = LibStub:GetLibrary("AceLocale-3.0"):NewLocale(ADDON, "enUS", true, true)
if not L then return end

L["found"] = true
L["not found"] = true
L["Plug-in registered with BrokerRaidFinder"] = true
L["Plug-in failed to register with BrokerRaidFinder"] = true
L["Plug-in unregistered."] = true

L["Usage:"] = true
L["/brfforwarder arg"] = true
L["/brffwd arg"] = true
L["Args:"] = true
L["on - activate forwarding"] = true
L["off - deactivate forwarding"] = true
L["version - display version information"] = true
L["help - display this help"] = true
		
L["Plugin adds support to forward LFG messages over a shared channel. This allows cross addon communication for all users of this plugin."] = true
	
L["Message forwarding active."] = true
L["Using fallback channel"] = true
L["Current channel owner is on ignore list."] = true
L["Not connected to forwarding channel."] = true
L["No forwarder available."] = true
L["Operation paused in major city."] = true
	
L["Version"] = true

