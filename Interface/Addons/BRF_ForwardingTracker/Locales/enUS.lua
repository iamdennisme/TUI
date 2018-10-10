--[[ *******************************************************************
Project                 : BRF_ForwardingTracker
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
L["/brffwdtracker arg"] = true
L["/brftrack arg"] = true
L["Args:"] = true
L["on - activate tracking"] = true
L["off - deactivate tracking"] = true
L["version - display version information"] = true
L["help - display this help"] = true
		
L["Plug-in keeps track of messages forwarded by LFGForwarder and TradeForwarder and feeds them to the addon."] = true
	
L["No sender available."] = true
L["Tracking in progress."] = true
L["No data received for more than 3 minutes."] = true
L["Cannot track LFG/TradeForwarder. Channel(s) not found."] = true
L["Tracking paused in major city."] = true
			
L["Version"] = true

