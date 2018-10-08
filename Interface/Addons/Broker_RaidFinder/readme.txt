Broker_RaidFinder, a World of Warcraft® user interface addon.
Copyright© 2012 Bernhard Voigt, aka tritium - All rights reserved.
License is given to copy, distribute and to make derivative works.

Broker_RaidFinder - A broker addon that monitors trade and lfg channels in major cities for raid offers. Supports remote search through friends and guild mates. 

Features -

	* Monitor General, Trade and LookingForGroup channels in major cities for raid offers.
	* Remote search. With activated addon communication option guild mates, mutual friends and battlenet friends using this addon will monitor city channels for you while you are out of town and inform you about the results.
	* Cross-character support. Hits made on one character are available on all your characters of the same faction.
	* Sound and text notifications for hits with timeout option to avoid irritation because of spammed messages.
	* Optionally exclude saved instances from monitoring.
	* Postings of players from the raid you are currently in will be omitted.
	* Whisper players directly by using the 'Whisper' button. No problems with tricky names with accents, umlauts and other creative spelling.
	* Adjust monitored keywords for all instances.
	* Plug-in support to extend addon functionality. 
	* Profile support for settings.

New -

	* Plug-in support to extend addon functionality. Comes bundled with 2 Plugins:
		** BRF Forwarder: Forwards LFG messages to all users of the plugin so they can track raid offers as long as one of them is in a major city.
		** BRF Forwarding Tracker: Keeps track of messages forwarded by LFGForwarder and TradeForwarder and feeds them to the addon.
	* Option 'Message Filters' - Applies chat filters such as spam filters introduced by other addons before processing messages. Recommended when using forwarding plugins to make sure you are not reported for forwarding spam.
	* Option 'Filter Matches' - Removes matches made by the addon from being shown in the chat windows.
	
Install -

	Copy the Broker_RaidFinder folder to your Interface\AddOns directory.
		
Commands - 

	/braidfinder arg
	/brfind arg

	With arg:
	version - display version information
	menu - display options menu
	on - activate monitoring
	off - deactivate monitoring
	show - show log window
	help - display this help
	
Usage -

	* In options select raids to search for and activate monitoring to start.
	* Click on addons broker entry or minimap button for interaction (or use slash commands listed above)
		** Right-click - Open options menu.
		** Left-click - Open log window which is listing all matches.
		** Alt-Left-click - Activate/deactivate monitoring.
	* Whisper players throught the log window.
	* Activate addon communication option for remote searches. This means when you are in town you may act as server for other clients out of town. If you are out of town you will engage other players as server for your remote searches. NOTE: see section Restrictions
	
Interface -

	* Icon - 
		** colored icon - indicates active monitoring
		** grey icon - indicates deactivated monitoring
	* Label - 
		** I: - Number of matched instances.
		** P: - Total number of players searching for any of your tracked instances.
		** ! - Remote monitoring active, that means a player is actively working as server for you monitoring the city channels.
	* Tooltip - 
		** For each tracked instance last hit is shown with name of searching player, total number of matches for that instance and time since last match.
		** Saved instances are marked red.
		** Instances without hit are grey.
		** Color-coded time since match (green for most recent; red means that match almost has reached end of time frame and is about to be removed from list).
	* Log window - 
		** Lists all matches for tracked instances with time, author and instance.
		** For selected entry complete message will be shown.
		** Filter log list by instance or source. Source is the character who found the match. (current character, alt or remote character)
		** 'Whisper' button to contact selected player directly.

Options -

	* General -
		** Monitoring active - Activate/deactivate the monitoring.
		** Addon communication - Toggle whether or not the addon shall sync with addons of other players.
		** Minimap Button - Show/hide Minimap Button
		** Hide Hint - Hide usage hint in tooltip
	* Raids - Set up which raids you will monitor.
	* Keywords - Set up keywords for each instance.
		** LFG Keywords - Comma separated list of keywords indicating someone is looking for players for a raid.
		** Default - Revert to default keywords.
	* Monitoring - Set up monitoring parmaters for addon.
		** Guild Chat - Monitor guild chat.
		** Exclude Saved Raids - Exclude raids you are currently saved to from monitoring.
		** Time Frame - Set up how long the log will reach back.
	* Notifications - Set up notifications when addon finds a match.
		** Text Alert - Show text message when addon finds a match.
		** Sound Alert - Play sound when addon finds a match.
		** Notification Sound - Choose sound to be played on notifications.
		** Timeout - Set notification timeout. You will not be notified about matches of a single player for the same instance more than once during the timeout duration.
	* Extras
		** Message Filters - Applies chat filters such as spam filters introduced by other addons before processing messages. Recommended when using forwarding plugins to make sure you are not reported for forwarding spam.
		** Filter Matches - Removes matches made by the addon from being shown in the chat windows.
	* Plug-ins
		** Every plugin registered with the addon will be added in this section. There are 3 options for each of them.
		** Activate - Activated/deactivates plug-in.
		** Label - Activates/deactivates label extension of the main addon.
		** Tooltip - Activates/deactivates tooltip extension of the main addon.

Restrictions -

	* Addon communication is restricted to your guild mates, chars of your battlenet friends in the current realm and mutual(!) friends who have this addon running as well. Addon communication has to be activated on both sides.
	* Especially you cannot just add players you frequently see in the city chats to your friend list in the hope they run this addon so they now can do the searching for you.	
	* Remote monitoring is restricted to default keywords. This is to prevent players from creating excessively long or accidentally or maliciously malformed keyword lists for remote search.
	* For clients without supported localization this will default to english localization which in all likelyhood will confine the usability of this addon considerably for players using such clients. Help with proper localized  lists of default keywords for non-english clients is greatly appreciated.
	* The matching works on a first hit policy. If a message contains more than one of your searched instances it will register only for the instance of the first hit in the message.
	* For remote monitoring this means that some clients might miss out on a hit when one client is registered for the first hit and another for the omitted second hit. That restriction is in place in order to keep the work for the server addon low so the player doing the searching for you does not face excessive load due to this service.
	