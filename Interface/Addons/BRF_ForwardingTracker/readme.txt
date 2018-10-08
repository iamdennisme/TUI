BRF_ForwardingTracker, a World of Warcraft® user interface addon.
Copyright© 2012 Bernhard Voigt, aka tritium - All rights reserved.
License is given to copy, distribute and to make derivative works.

BRF_ForwardingTracker - Plug-in for Broker: Raid Finder. Keeps track of messages forwarded by LFGForwarder and TradeForwarder and feeds them to Broker: Raid Finder.

Features -

	* Keeps track of messages forwarded by LFGForwarder and TradeForwarder addons and feeds them them to Broker: Raid Finder.
	
Install -

	Copy the BRF_ForwardingTracker folder to your Interface\AddOns directory.
		
Commands - 

	Usage:
	/brffwdtracker arg
	/brftrack arg
	
	With args:
	on - activate forwarding
	off - deactivate forwarding
	version - display version information
	help - display this help
	
Usage -

	* Setup in Broker: Raid Finder options in section "Plug-ins".
		** Activate: Activated/deactivates plug-in.
		** Label: Activates/deactivates label extension of the main addon.
		** Tooltip: Activates/deactivates tooltip extension of the main addon.
	
Interface -

	* Label - 
		** Extends Broker: Raid Finder label by the color coded letter 'T' 
		** White: Plug-in is activated but operation has paused in a major city.
		** Green: Plug-in is activated and processing forwarded messages.
		** Red: Plug-in could not find operating channels of LFGForwarder or TradeForwarder.
		** On deactivated plug-in the label extension will be hidden
	* Tooltip - 
		** Extends Broker: Raid Finder tooltip by several messages stating the current mode of operation.
	