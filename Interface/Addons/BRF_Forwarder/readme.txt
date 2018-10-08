BRF_Forwarder, a World of Warcraft® user interface addon.
Copyright© 2012 Bernhard Voigt, aka tritium - All rights reserved.
License is given to copy, distribute and to make derivative works.

BRF_Forwarder - Plug-in for Broker: Raid Finder. Forwards LFG messages to shared hidden channel, so all users of the plugin can track of raid offers as long as one of them is in a major city. 

Features -

	* Uses of shared hidden channel to keep track of raid offers while out of town.
	* While anyone with this plugin active is in a major city the plugin receives LFG messages and feeds them to the main addon.
	* Uses fallback channels in case anyone tinkers with the dafault channel excluding people from joining via ban or setting up a password for the channel.

Note -
	* This plug-in forwards third party lfg messages. Receiving players might run spam detection addons that could report you if those forwarded messages contain spam. Therefore it is recommended to use a spam filtering addon yourself and activate the option 'Message Filters' of 'Broker: Raid Finder'. This way the main addon will sort out spam messages before processing them.
	
Install -

	Copy the BRF_Forwarder folder to your Interface\AddOns directory.
		
Commands - 
	
	Usage:
	/brfforwarder arg
	/brffwd arg
	
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
		** Extends Broker: Raid Finder label by the color coded letter 'F' 
		** White: Plug-in is activated but not yet ready.
		** Green: Plug-in is activated and ready for forwarding or processing forwarded messages.
		** Red: Plug-in could not join designed channel and is using a fallback channel.
		** On deactivated plug-in the label extension will be hidden
	* Tooltip - 
		** Extends Broker: Raid Finder tooltip by several messages stating the current mode of operation.
