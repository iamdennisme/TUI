--------------------------------------
-- Namespaces
--------------------------------------
local _, core = ... 											--Global Addon Namespace
local L = core.L												--Translation Table

local events = CreateFrame("Frame")								--All events are registered to this frame
local UIConfig													--UIConfig is used to make a display asking the user if they would like
local UICreated = false											--To enable achievement tracking when they enter an instances
local debugMode = false
local debugModeChat = false
local sendDebugMessages = false

--------------------------------
-- Saved Variables tables
--------------------------------
AchievementTrackerOptions = {}									--Saved Variables Tables
AchievementTrackerDebug = {}

events:RegisterEvent("ADDON_LOADED")							--This is the first event that is called as soon as the addon loaded. Does Initial Setup							
events:RegisterEvent("GET_ITEM_INFO_RECEIVED")					--Get Item Information after the game has loaded to finish loading tactics

function generateItemCache()									--The Item Cache can only be generated once the game has loaded		
	for i,v in pairs(core.ItemCache) do							--We need to first get information about the item to load into the cache
		GetItemInfo(core.ItemCache[v])							--Then we can insert this information into the tactics. Tactics hold string "IAT_12345" to eventually get replaced
	end
end

function events:GET_ITEM_INFO_RECEIVED(self, arg1)
	if core:has_value2(core.ItemCache, arg1) then
		--Update table with updated info
		for expansion, _ in pairs(core.Instances) do
			for instanceType, _ in pairs(core.Instances[expansion]) do
				for instance, _ in pairs(core.Instances[expansion][instanceType]) do
					for boss, _ in pairs(core.Instances[expansion][instanceType][instance]) do
						if boss ~= "name" then
							if string.find(core.Instances[expansion][instanceType][instance][boss].tactics, ("IAT_" .. arg1)) then
								local itemName, itemLink = GetItemInfo(arg1)
								core.Instances[expansion][instanceType][instance][boss].tactics = string.gsub(core.Instances[expansion][instanceType][instance][boss].tactics, ("IAT_" .. arg1), itemLink)
							end
						end
					end
				end
			end
		end
	end
end

events:SetScript("OnEvent", function(self, event, ...)
    return self[event] and self[event](self, event, ...) 	--Allow event arguments to be called from seperate functions
end)

--Used to detect whether there are still players in the group still in combat with the boss
function events:onUpdate(sinceLastUpdate)
	self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate;
	if ( self.sinceLastUpdate >= 1 ) then -- in seconds
		-- do stuff here
		self.sinceLastUpdate = 0;
		local combatStatus = getCombatStatus()
		if combatStatus == false then
			core:clearInstanceVariables()
			core:clearVariables()
			core:sendDebugMessage("Locking Detection for 3 seconds")
			core.lockDetection = true
			C_Timer.After(3, function() 
				core.lockDetection = false
				core:sendDebugMessage("Detection unlocked")
			end)
			core:sendDebugMessage("Left Combat")
			events:SetScript("OnUpdate",nil)
		end
	end
end

--------------------------------------
-- Achievement Scanning Variables
--------------------------------------
local playersToScan = {}						--List of players that still need to be scanned to see which achievements they are missing for the current instance
local playersScanned = {}						--List of players that have been successfully scanned for the current instance
local rescanNeeded = false						--Set to true if a rescan is needed during a current scan. This is fired if the group size changes during a scan
local playerCurrentlyScanning = nil				--This is set to the current player that is being scanned
local scanInProgress = false					--Set to true when a scan of the group has started
core.scanFinished = false						--Set to true when everyone in the group has been scanned successfully and no rescan is needed. Part of core so it can be accessed by the GUI
local scanAnnounced = false						--Whether the achievement scanning has been announced to the chat
local scanCounter = 0							--Incremented everytime a scan completes so only scan timer waiting for a reponse are not used

--------------------------------------
-- Main Variables
--------------------------------------
core.currentZoneID = nil						--The ID of the current instance the player is in
core.playerCount = 0							--The amount of players the instance lock can hold
core.inCombat = false							--Whether anyone in the current group is in combat with boss/mobs
core.achievementsFailed = {}					--Set to true when the requirements for a tracked achievement has failed
core.achievementsCompleted = {}					--Set to true when the requrements for a tracked achievement have been met
core.chatType = nil								--The chat type for the current group (say/party/raid)
core.achievementTrackedMessageShown = false		--Set to true when the message "Tracking {achievement}" is output to the chat so that it only outputs once per fight
core.groupSize = 1								--Amount of players currently in the group. Set to 1 by default
core.achievementIDs = {}						--Stores a list of the achievements to track for the current boss
core.achievementTrackingEnabled = false			--Whether the user wants to track achievements for the particular instance or not
core.playersFailedPersonal = {}					--List of players that have failed a personal achievement. Resets when you exit combat
core.playersSuccessPersonal = {}				--List of players that have successfully completed a personal acheievement. Resets when you exit combat
core.enableAchievementScanning = true			--Whether the addon is allowed to scan for achievements
local combatTimerStarted = false				--Used to determine if players in the group are still in combat with a boss
local lastMessageSent = ""   					--Stores the last message sent to the chat. This is used to prevent the same message being sent more than once in case of an error and to prevent unwanted spam
local requestToRun = false						--Store whether the current addon sent the request to enable itself or not for achievement tracking
local electionFinished = false
local enableDisplayAchievement = true
local currentBossNums = {}
local detectBossWait = false
local announceToRaidWarning = false				--Whether or not to announce messages to Raid Warning or not. Can only be done while in raid & user is raid leader or assist.
local enableSound = false						--Whether to play a sound when achievement is completed or failed
local failedSound = nil
local completedSound = nil

--------------------------------------
-- Current Instance Variables
--------------------------------------
core.inInstance = false
core.expansion = nil							--Current expansion of the particular instance
core.instanceType = nil							--Whether the instance is a dungeon or a raid
core.instance = nil								--Name of the instance the player is currently in
core.instanceNameSpaces = nil					--Instance name with spaces
core.foundBoss = false							--Whether or not a boss has been found to track or not
core.currentBosses = {}							--Stores a list of the bosses the player is currently attacking. (Can be mutliple if one boss has multiple achievements)
core.mobCache = {}								--Stores a list of mobs that have been checked to see whether or not they need to be tracked or not
core.instanceVariablesReset = true				--Whether the instance variables have reset after leaving an instance

--------------------------------------
-- Boss functions
--------------------------------------
core.mobCounter = 0								--Used in the trackMob function to see how many of a certain type of mob have currently spawned
core.mobUID = {}								--Used in the trackMob function to store the unique UID of each mob of a certain type that has spawned
core.thresholdAnnounced = false					--Used to check whether the trackMob funciton has announced the requirements have been met
core.encounterStarted = false
core.displayAchievements = false
core.encounterDetected = false
core.outputTrackingStatus = false
core.announceTrackedAchievementsToChat = false	--Whether or not the user has chosen for IAT to announce which achievements are currently being tracked to chat
core.lockDetection = false						--Once an encounter has finished. Stop the encounter being detected again straight away
core.onlyTrackMissingAchievements = false		--Whether or not the user has chosen to only track missing achievements or not
core.trackingSupressed = false					--Whether or not tracking is being supressed for the current fight

--------------------------------------
-- Addon Syncing 
--------------------------------------
local masterAddon = false					--The master addon for the group. This stop multiple people with the addon outputting identical messages. Reset at the end of every fight
local playerRank = -1						--The rank of the player is the group. Players with higher rank get priorty over outputting messages unless they have an outdated addon
local addonID = 0
local messageQueue = {}

--Get the current size of the group
function core:getGroupSize()
	local size = GetNumGroupMembers()

	if size == 0 then
		--If the size is 0 then player is not in a group. However we need to still set it to 1 since 0 players doesn't make sense
		core.groupSize = 1
	else
		core.groupSize = size
	end
end

------------------------------------------------------
---- Players Achievements Functions
------------------------------------------------------

--Get a list of all the players currently in the group. This is used so we can scan all the players in the group to see which achievements they need
--This is run everytime the composition of the group changes so we always have an up to date list of players who need a certain achievement
function getPlayersInGroup()
	if core.inInstance == true then
		--Only Announce the scanning once.
		if scanAnnounced == false then
			printMessage(L["Starting Achievement Scan For"] .. " " .. core.instanceNameSpaces .. " (" .. L["This may freeze your game for a few seconds"] .. "!)")
			scanAnnounced = true
		end
		core:getGroupSize() --Get current size of the group
		scanInProgress = true
		core.scanFinished = false
		local currentGroup = {} --Create a local copy of the group so we can then compare it to the current group to see what changes there are.

		if core.groupSize > 1 then
			--We are in a group
			local currentUnit
			core:detectGroupType() --Detect the type of group the player is in so we can do the appropriate scanning
			for i = 1, core.groupSize do
				if core.chatType == "PARTY" then
					if i < core.groupSize then
						currentUnit = "party" .. i
					else
						currentUnit = "player"
					end
				elseif core.chatType == "RAID" then
					currentUnit = "raid" .. i
				end

				local name, realm = UnitName(currentUnit)
				if core:has_value(playersScanned, name) == false and core:has_value(playersToScan, name) == false and name ~= "Unknown" then
					table.insert(playersToScan, name)
				end

				--Add to the current group so we can remove players that have left the group
				if name ~= "Unknown" then
					table.insert(currentGroup, name)
				end
			end
		else
			currentUnit = "player"
			local name, realm = UnitName(currentUnit)
			if core:has_value(playersScanned, name) == false and core:has_value(playersToScan, name) == false and name ~= "Unknown" then
				table.insert(playersToScan, name)
			end
			table.insert(currentGroup, name)
		end

		--Check if anyone in the group has left that has already been scanned
		--In playersToScan
		if #playersToScan > 0 then
			for i = #playersToScan, 1, -1 do
				if core:has_value(currentGroup, playersToScan[i]) == false then
					table.remove(playersToScan, i)
				end
			end
		end

		--In playersScanned
		if #playersScanned > 0 then
			for i = #playersScanned, 1, -1 do
				if core:has_value(currentGroup, playersScanned[i]) == false then
					--Remove player from the table that generates the UI for that achievementw
					for boss,_ in pairs(core.Instances[core.expansion][core.instanceType][core.instance]) do
						if boss ~= "name" then
							local name = playersScanned[i]
							--print("Removing: " .. name)

							--Check if player was added the table
							for j = 1, #core.Instances[core.expansion][core.instanceType][core.instance][boss].players do
								if core.Instances[core.expansion][core.instanceType][core.instance][boss].players[j] == name then
									table.remove(core.Instances[core.expansion][core.instanceType][core.instance][boss].players, j)
									--print("Removed: " .. name)
								end
							end
						end
					end

					--Update the GUI
					core.Config:Instance_OnClickAutomatic()

					table.remove(playersScanned, i)
				end
			end
		end

		rescanNeeded = false

		--Start the player scanning
		if #playersToScan > 0 then
			--Fetch information for the next person in the group
			getInstanceAchievements()
		else
			core:sendDebugMessage(L["Achievement Scanning Finished"] .. " (" .. #playersScanned .. "/" .. core.groupSize .. ")")
			scanInProgress = false
			core.scanFinished = true

			--Once the achievement scanning has finished enable the achievement tab to start scanning again
			if _G["AchievementFrameComparison"] ~= nil then
				--Re-register this event so achievement ui and inspect achievement ui work as intended
				_G["AchievementFrameComparison"]:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
			end
		end
	else
		core:sendDebugMessage("Player is not in an instance. Cancelling scan")
	end
end

--Used to fetch achievement information for each player in the group. This is used so players can see and output which players in the group are missing which achievements
--TODO: have a limit on the amount of times a certain player is scanned. This is needed so we are not constantly scanning players that are offline or players who never enter the instance
function getInstanceAchievements()
	ClearAchievementComparisonUnit()
	--Make sure the player we are about to scan is still in the group
	if UnitName(playersToScan[1]) ~= nil then
		playerCurrentlyScanning = playersToScan[1]
		core:sendDebugMessage("Setting Comparison Unit to: " .. UnitName(playersToScan[1]))
		core.currentComparisonUnit = UnitName(playersToScan[1])

		--Check if the achievement ui is open before setting the comparison unit
		if _G["AchievementFrame"] then
			--The AchievementFrameComparison_OnEvent in Blizzard_AchievementUI does not check if the INSPECT_ACHIEVEMENT_READY event was fired from it's own addon or not
			--Temporarily disable the event while we do our scanning.
			--To protect against errors by disabling event, pause the scanning if the achievement ui or inspect achievement ui is shown
			_G["AchievementFrameComparison"]:UnregisterEvent("INSPECT_ACHIEVEMENT_READY");
			SetAchievementComparisonUnit(playersToScan[1])	
		else
			--Achievement Frame has not been loaded so go ahead and set the comparison unit
			SetAchievementComparisonUnit(playersToScan[1])	
		end

		--Set the id to the current scanCounter so we can determine if the timer is still valid or not. If the scanCounter is higher than the local timer then ignore the output from the timer since it's no longer valid
		local scanCounterloc = scanCounter

		--Wait 2 seconds then check if the achievement information was returned successfully. If playerCurrentlyScanning is nil then we can assume the information was returned successfully
		--If playerCurrentlyScanning still has a value then INSPECT_ACHIEVEMNT_READY event has not run and the information for that player was not fetched
		C_Timer.After(2, function()
			--Check if the scan is still valid or not
			if scanCounterloc == scanCounter then
				--Last player scan was successfully. Check if we need to continue scanning
				-- if #playersToScan > 0 then
				-- 	getInstanceAchievements()
				-- elseif #playersToScan == 0 and rescanNeeded == false then
				-- 	printMessage("Achievment Scanning Finished (" .. #playersScanned .. "/" .. core.groupSize .. ")")
				-- 	scanInProgress = false
				-- 	core.scanFinished = true
				-- elseif #playersToScan == 0 and rescanNeeded == true then
				-- 	--print("Achievement Scanning Finished but some players still need scanning. Waiting 20 seconds then trying again (" .. #playersScanned .. "/" .. core.groupSize .. ")")
				-- 	C_Timer.After(10, function()
				-- 		scanInProgress = true
				-- 		getPlayersInGroup()
				-- 	end)
				-- end

				--Last player to scan was not successfull
				core:sendDebugMessage("Last scan was unsuccessfull: " .. scanCounterloc)
				rescanNeeded = true
				if playersToScan[1] ~= nil then
					--print("Cannot Scan " .. playersToScan[1])
					table.remove(playersToScan, 1)
				end

				if #playersToScan > 0 then
					getInstanceAchievements()
				elseif #playersToScan == 0 and rescanNeeded == true then
					--print("Achievement Scanning Finished but some players still need scanning. Waiting 20 seconds then trying again (" .. #playersScanned .. "/" .. core.groupSize .. ")")
					C_Timer.After(10, function()
						scanInProgress = true
						getPlayersInGroup()
					end)
				end
			else
				core:sendDebugMessage("Cancelling: " .. scanCounterloc)
			end
		end)
	else
		rescanNeeded = true
		scanInProgress = true
		getPlayersInGroup()
	end
end

------------------------------------------------------
---- Achievement Tracking Setup
------------------------------------------------------

--Run when the player initially enters an instance to setup variables such as instanceName, expansion etc so we can track the correct bosses
function getInstanceInfomation()
	--DEBUG
	-- if debugMode == true then
	-- 	core.instance = "Ulduar"
	-- 	core.instanceClear = "Ulduar"
	-- 	core.instanceNameSpaces = "Ulduar"
	-- 	core.expansion = "WrathOfTheLichKing"
	-- 	core.instanceType = "Raids"
	-- 	core.inInstance = true
	-- 	if UICreated == false then
	-- 		core:sendDebugMessage("Creating Tracking UI")
	-- 		createEnableAchievementTrackingUI()
	-- 	else
	-- 		core:sendDebugMessage("Displaying Tracking UI since it was already created")
	-- 		UIConfig:Show()
	-- 	end
	-- end

	if IsInInstance() and core.inInstance == false then
		core:sendDebugMessage("Player has entered instance")
		local instanceCompatible = false --Check whether player is on correct difficulty to earn achievements
		core.instanceNameSpaces, _, core.difficultyID, _, core.maxPlayers, _, _, core.currentZoneID, _ = GetInstanceInfo()

		core:sendDebugMessage(core.currentZoneID)

		core.instance = core.currentZoneID --Instance name without any puntuation
		core.instanceClear = "_" .. core.currentZoneID --Instance name with _ to fetch functions for tracking of the particular instance

		core:sendDebugMessage("Offical Instance Name: " .. core.instance .. " " .. core.instanceClear)

		--If the raid is in the lich king expansion then detect whether player is on the 10man or 25man difficulty
		--This is only needed for raids that have seperate achievements for 10man and 25man. Happens for the majority of WOTLK raids
		if core.instance == 615 or core.instance == 616 or core.instance == 249 or core.instance == 649 or core.instance == 624 or core.instance == 533 or core.instance == 631 then
			if core.difficultyID == 3 or core.difficultyID == 5 then
				--10 Man
				core:sendDebugMessage("Detected Legacy 10 man Raid")
				core.instance = core.instance .. -10
				core:sendDebugMessage("New Instance Name: " .. core.instance)
			elseif core.difficultyID == 4 or core.difficultyID == 6 then
				--25 Man
				core:sendDebugMessage("Detected Legacy 25 man raid")
				core.instance = core.instance .. -25
				core:sendDebugMessage("New Instance Name: " .. core.instance)
			end
		end

		--Find the instance in the core.instances table so we can cache the value to be used later
		for expansion,_ in pairs(core.Instances) do
			for instanceType,_ in pairs(core.Instances[expansion]) do
				for instance,_ in pairs(core.Instances[expansion][instanceType]) do
					if instance == core.instance then
						core.expansion = expansion
						core.instanceType = instanceType
						core.instance = instance
						core.inInstance = true
						core.instanceVariablesReset = false

						core:sendDebugMessage("Expansion: " .. core.expansion)
						core:sendDebugMessage("Instance Type: " .. core.instanceType)
						core:sendDebugMessage("Instance: " .. core.instance)
					end
				end
			end
		end

		--Check whether achievements can be earned for the instance the player has entered
		core:sendDebugMessage("DifficultyID: " .. core.difficultyID)
		if core.difficultyID == 2 then
			--WOTLK/Cata/Mop/Wod heroic dungeons
			if core.expansion == 7 or core.expansion == 6 or core.expansion == 5 or core.expansion == 4 then
				instanceCompatible = true
			end
		elseif core.difficultyID == 23 then
			--Legion/BFA Mythics
			if core.expansion == 3 or core.expansion == 2 then
				instanceCompatible = true
			end
		elseif core.difficultyID == 3 or core.difficultyID == 5 then
			--legacy10
			instanceCompatible = true
		elseif core.difficultyID == 4 or core.difficultyID == 6 then
			--legacy25
			instanceCompatible = true
		elseif core.difficultyID == 11 or core.difficultyID == 12 then
			--scenerios"
			if core.expansion == 5 then
				instanceCompatible = true
			end
		elseif core.difficultyID == 13 or core.difficultyID == 14 or core.difficultyID == 15 or core.difficultyID == 16 then
			--current
			instanceCompatible = true
		elseif core.difficultyID == 7 or core.difficultyID == 17 and debugMode == true then
			instanceCompatible = true
		elseif core.difficultyID == 24 or core.difficultyID == 33 then
			--Timewalking
			instanceCompatible = true
		end

		if debugMode == true then
			instanceCompatible = true
		end

		if instanceCompatible == true then
			--Check if the instance has any achievements to actually track
			local foundTracking = false
			core:sendDebugMessage("Expansion: " .. core.expansion)
			core:sendDebugMessage("Instance Type: " .. core.instanceType)
			core:sendDebugMessage("Instance: " .. core.instance)
			for boss,_ in pairs(core.Instances[core.expansion][core.instanceType][core.instance]) do
				if boss ~= "name" then
					if core.Instances[core.expansion][core.instanceType][core.instance][boss].track ~= nil then
						foundTracking = true
					end
				end
			end

			--Ask the user whether they want to enable Achievement Tracking in the instance. Only do this if there is any achievements to track for the particular instance
			if foundTracking == true then
				core:sendDebugMessage("Asking user whether they want to track this instance")
				if UICreated == false then
					core:sendDebugMessage("Creating Tracking UI")
					createEnableAchievementTrackingUI()
				else
					core:sendDebugMessage("Displaying Tracking UI since it was already created")
					UIConfig.content:SetText(L["Do you want to enable achievement tracking for"] .. ": " .. core.instanceNameSpaces);
					UIConfig:Show()
				end
			else
				core:sendDebugMessage("No Achievements to track for this instance")
			end
		else
			core:sendDebugMessage("Achievements cannot be earned for the following difficulty " .. core.difficultyID)
		end
	elseif IsInInstance() == false and core.inInstance == true then
		core.inInstance = false
	end
end

--Run if we need to setup additional events/variables for a certain instance. For example if we need to track additional events such as messages from bosses
function initialInstanceSetup()
	--Used to start certain events for some instances so we don't have to run them when they are not needed
	core:sendDebugMessage("Starting Initial Setup If Needed...")
	local retOK, ret1 = pcall(function() core[core.instanceClear]:InitialSetup() end);
	if (retOK) then
		core:sendDebugMessage("Starting Initial Setup For Instance")
		core[core.instanceClear]:InitialSetup()
	else
		core:sendDebugMessage("Function failed, error text: " .. ret1 .. ".")
	end
end

--Create the achievement tracking UI if it is not already been created
--This will ask the user if they want to enable acheivement tracking for the current instance the player has entered
--It will only show in instances where there are achievements to be tracked and they are on the correct difficulty to earn acheivements
function createEnableAchievementTrackingUI()
	UICreated = true

	--Create the frame to ask the user whether they want to enable the addon for the particular instance they are in
	UIConfig = CreateFrame("Frame", "AchievementTrackerCheck", UIParent, "UIPanelDialogTemplate", "AchievementTemplate")
	UIConfig:SetSize(200, 200)
	UIConfig:SetPoint("CENTER")

	--Title
	UIConfig.title = UIConfig:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	UIConfig.title:SetPoint("CENTER", AchievementTrackerCheckTitleBG, "CENTER", -5, 0);
	UIConfig.title:SetText(L["Track Achievements"] .. "?");

	--Content
	UIConfig.content = UIConfig:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	UIConfig.content:SetPoint("TOPLEFT", AchievementTrackerCheckDialogBG, "TOPLEFT", 0, -5);
	UIConfig.content:SetText(L["Do you want to enable achievement tracking for"] .. ": " .. core.instanceNameSpaces);
	UIConfig.content:SetWidth(185)

	UIConfig.btnYes = CreateFrame("Button", nil, UIConfig, "GameMenuButtonTemplate");
	UIConfig.btnYes:SetPoint("RIGHT", UIConfig.content, "BOTTOM", 0, -20);
	UIConfig.btnYes:SetSize(80, 30);
	UIConfig.btnYes:SetText(L["Yes"]);
	UIConfig.btnYes:SetNormalFontObject("GameFontNormal");
	UIConfig.btnYes:SetHighlightFontObject("GameFontHighlight");

	UIConfig.btnNo = CreateFrame("Button", nil, UIConfig, "GameMenuButtonTemplate");
	UIConfig.btnNo:SetPoint("LEFT", UIConfig.btnYes, "RIGHT", 5, 0);
	UIConfig.btnNo:SetSize(80, 30);
	UIConfig.btnNo:SetText(L["No"]);
	UIConfig.btnNo:SetNormalFontObject("GameFontNormal");
	UIConfig.btnNo:SetHighlightFontObject("GameFontHighlight");

	UIConfig:SetHeight(UIConfig.content:GetHeight() + UIConfig.btnYes:GetHeight() + UIConfig.title:GetHeight() + 35)
	UIConfig.btnYes:SetScript("OnClick", enableAchievementTracking);
	UIConfig.btnNo:SetScript("OnClick", disableAchievementTracking);
end

--Players wants to track achievements for this instance
function enableAchievementTracking(self)
	core.achievementTrackingEnabled = true
	UIConfig:Hide()

	--Switch to correct tab in GUI
	if core.expansion == 2 then
		Tab_OnClick(_G["AchievementTrackerTab2"])
	elseif core.expansion == 3 then
		Tab_OnClick(_G["AchievementTrackerTab3"])
	elseif core.expansion == 4 then
		Tab_OnClick(_G["AchievementTrackerTab4"])
	elseif core.expansion == 5 then
		Tab_OnClick(_G["AchievementTrackerTab5"])
	elseif core.expansion == 6 then
		Tab_OnClick(_G["AchievementTrackerTab6"])
	elseif core.expansion == 7 then
		Tab_OnClick(_G["AchievementTrackerTab7"])
	end

	--Register Events
	events:RegisterEvent("INSPECT_ACHIEVEMENT_READY") 			--Used for scanning players in the group to see which achievements they are missing
	events:RegisterEvent("GROUP_ROSTER_UPDATE")					--Used to find out when the group size has changed and to therefore initiate an achievement scan of the group
	events:RegisterEvent("CHAT_MSG_SYSTEM")						--Used to find out when players join group to intiate an achievement scan of the group
	events:RegisterEvent("PLAYER_REGEN_DISABLED")				--Used to detect when the player has entered combat and to reset tracked variables for bosses
	events:RegisterEvent("PLAYER_REGEN_ENABLED")				--Used to track when the player has left combat
	events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")			--Used to track the completion/failiure of achievements
	events:RegisterEvent("ENCOUNTER_START")						--Used to detect the start of a boss fight
	events:RegisterEvent("ENCOUNTER_END")						--Used to detect the end of a boss fight

	--Start the achievement scan
	if core.enableAchievementScanning == true then
		getPlayersInGroup()
	else
		core:sendDebugMessage("Achievement Scanning Disabled")	
	end

	--Addon Syncing Priority:
	--1.) Highest Version Number of addon
	--2.) Raid Leader / Party Leader
	--3.) Raid Assistant
	--4.) Member

	--Setup the instance events if required
	initialInstanceSetup()

	--Get a random ID between 1 and 100,000
	addonID = random(1,100000)

	--Check if there is already someone else running the addon in the group / whether the priority is higher for the current player than other players running the addon
	if core.groupSize == 1 then
		--Player is not a group so set the player to the master addon
		core:sendDebugMessage("Setting Master Addon 1")
		masterAddon = true
		printMessage(L["Achievement Tracking Enabled for"] .. " " .. core.instanceNameSpaces)
	else
		--Get the rank for the current player
		for i = 1, core.groupSize do
			local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
			if name == UnitName("Player") then
				--Send out message so other adds can add new player to their arrays
				playerRank = rank
			end
		end
	end

	--Make sure right instance is selected
	core.Config:Instance_OnClickAutomatic()
end

--Hide the achievment tracking UI once the player has left the instance
function disableAchievementTracking(self)
	UIConfig:Hide()
end

--Used to detect when everyone in the group has left combat so we can reset global and instance variables
function getCombatStatus()
	local playerInCombat = false
	if core.groupSize > 1 then
		--We are in a group
		local currentUnit
		core:detectGroupType()
		for i = 1, core.groupSize do
			if core.chatType == "PARTY" then
				if i < core.groupSize then
					currentUnit = "party" .. i
				else
					currentUnit = "player"
				end
			elseif core.chatType == "RAID" then
				currentUnit = "raid" .. i
			end

			if currentUnit ~= nil then
				if UnitAffectingCombat(currentUnit) == true then
					playerInCombat = true
				end
			end
		end

		if playerInCombat == false then
			--Everyone in the group has left combat so we can clear the tracking variables
			return false
		else
			--Someone in the group is still in combat
			return true
		end
	else
		--Player is not in a group therefore, they must of left combat so clear variables
		return false
	end
end

--------------------------------------
---- Custom Slash Command
--------------------------------------
core.commands = {
	[L["help"]] = function()
		printMessage(L["List of slash commands"] .. ":")
		printMessage("/iat help|r - " .. L["shows a list of avaliable slash commands"])
		printMessage("/iat enable|r - " .. L["enable/disable IAT achievement tracking"])
	end,

	[L["enable"]] = function()
		print("Enable/Disable addon")
	end,

	["debug"] = function()
		if debugMode == true then
			debugMode = false
		else
			debugMode = true
		end
		print(debugMode)
	end,
};

local function HandleSlashCommands(str)	
	if (#str == 0) then	
		-- User just entered "/iat" with no additional args.
		core.Config.Toggle()
		return;		
	end	
	
	local args = {};
	for _, arg in ipairs({ string.split(' ', str) }) do
		if (#arg > 0) then
			table.insert(args, arg);
		end
	end
	
	local path = core.commands; -- required for updating found table.
	
	for id, arg in ipairs(args) do
		if (#arg > 0) then -- if string length is greater than 0.
			arg = arg:lower();			
			if (path[arg]) then
				if (type(path[arg]) == "function") then				
					-- all remaining args passed to our function!
					path[arg](select(id + 1, unpack(args))); 
					return;					
				elseif (type(path[arg]) == "table") then				
					path = path[arg]; -- another sub-table found!
				end
			else
				-- does not exist!
				core.commands.help();
				return;
			end
		end
	end
end

------------------------------------------------------
---- Events
------------------------------------------------------

function events:ADDON_LOADED(event, name)
	if name == "Blizzard_AchievementUI" then
		core:sendDebugMessage("Achiev UI Loaded")
		-- local AchievementFrameComparison_UpdateStatusBars = AchievementFrameComparison_UpdateStatusBars; -- (1)
		-- AchievementFrameComparison_UpdateStatusBars = function(...) -- (2)
		-- 	print("Whizzey Addon")
		-- 	return AchievementFrameComparison_UpdateStatusBars(...); -- (6)
		-- end
	end
	
	if name ~= "InstanceAchievementTracker" then return end

	generateItemCache()

	--Check if the options have been setup
	
	--Enable/Disable addon
	if AchievementTrackerOptions["enableAddon"] == nil then
		AchievementTrackerOptions["enableAddon"] = true
	end
	_G["AchievementTracker_EnableAddon"]:SetChecked(AchievementTrackerOptions["enableAddon"])

	--Show/Hide minimap
	if AchievementTrackerOptions["showMinimap"] == nil then
		AchievementTrackerOptions["showMinimap"] = true
	end
	_G["AchievementTracker_ToggleMinimapIcon"]:SetChecked(AchievementTrackerOptions["showMinimap"])

	--Announce which achievments are being tracked
	if AchievementTrackerOptions["announceTrackedAchievements"] == nil then
		AchievementTrackerOptions["announceTrackedAchievements"] = false --Do not enable by default
	elseif AchievementTrackerOptions["announceTrackedAchievements"] == true then
		core.announceTrackedAchievementsToChat = true
	end
	_G["AchievementTracker_ToggleAchievementAnnounce"]:SetChecked(AchievementTrackerOptions["announceTrackedAchievements"])

	--Only track missing achievements
	if AchievementTrackerOptions["onlyTrackMissingAchievements"] == nil then
		AchievementTrackerOptions["onlyTrackMissingAchievements"] = false --Do not enable by default
	elseif AchievementTrackerOptions["onlyTrackMissingAchievements"] == true then
		core:sendDebugMessage("Only Tracking Missing Achievements Enabled")
		core.onlyTrackMissingAchievements = true
		core:sendDebugMessage(tostring(core.onlyTrackMissingAchievements))
	end
	_G["AchievementTracker_ToggleTrackMissingAchievementsOnly"]:SetChecked(AchievementTrackerOptions["onlyTrackMissingAchievements"])

	--Announce to Raid Warning
	if AchievementTrackerOptions["announceToRaidWarning"] == nil then
		AchievementTrackerOptions["announceToRaidWarning"] = true --Enable this by default
	elseif AchievementTrackerOptions["announceToRaidWarning"] == true then
		announceToRaidWarning = true
	end
	_G["AchievementTracker_ToggleAnnounceToRaidWarning"]:SetChecked(AchievementTrackerOptions["announceToRaidWarning"])
	
	--Play sound when achievement completed or failed
	if AchievementTrackerOptions["toggleSound"] == nil then
		AchievementTrackerOptions["toggleSound"] = false --Do not enable by default
	elseif AchievementTrackerOptions["toggleSound"] == true then
		enableSound = true
	end
	_G["AchievementTracker_ToggleSound"]:SetChecked(AchievementTrackerOptions["toggleSound"])

	--Sound when achievement is completed
	if AchievementTrackerOptions["completedSoundID"] ~= nil then
		--Set the sound if already selected previously
		MSA_DropDownMenu_SetText(_G["AchievementTracker_SelectSoundDropdownCompleted"], AchievementTrackerOptions["completedSoundID"])
	end
	if AchievementTrackerOptions["completedSound"] ~= nil then
		--Set the source of the completed sound
		completedSound = AchievementTrackerOptions["completedSound"]
	end
	
	--Sound when achievement is failed
	if AchievementTrackerOptions["failedSoundID"] ~= nil then
		MSA_DropDownMenu_SetText(_G["AchievementTracker_SelectSoundDropdownFailed"], AchievementTrackerOptions["failedSoundID"])
	end
	if AchievementTrackerOptions["failedSound"] ~= nil then
		--Set the source of the completed sound
		failedSound = AchievementTrackerOptions["failedSound"]
	end

	-- if AchievementTrackerOptions["enableAchievementScan"] == nil then
	-- 	core:sendDebugMessage("Setting Initial Settings")
	-- 	AchievementTrackerOptions["enableAchievementScan"] = true
	-- end
	-- _G["AchievementTracker_EnableAchievementScan"]:SetChecked(AchievementTrackerOptions["enableAchievementScan"])
	-- core.enableAchievementScanning = _G["AchievementTracker_EnableAchievementScan"]:GetChecked()
	
    -- core.Config:SetupAchievementTracking(core.enableAchievementScanning)

	SLASH_IAT1 = "/iat";
	SlashCmdList.IAT = HandleSlashCommands;

	--printMessage("loaded. Version: V" .. core.Config.majorVersion .. "." .. core.Config.minorVersion .. "." .. core.Config.revisionVersion)

	--------------------------------------
	-- Minimap Icon
	--------------------------------------
	core.ATButton = LibStub("LibDBIcon-1.0")
	--local profile

	-- LDB
	if not LibStub:GetLibrary("LibDataBroker-1.1", true) then return end

	--Make an LDB object
	local MiniMapLDB = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("InstanceAchievementTracker", {
		type = "launcher",
		text = "InstanceAchievementTracker",
		icon = "Interface\\Icons\\ACHIEVEMENT_GUILDPERK_MRPOPULARITY",
		OnTooltipShow = function(tooltip)
			tooltip:AddLine("|cff00FF00" .. "Instance Achievement Tracker" .. "|r");
		end,
		OnClick = function(self, button)
			core.Config.Toggle()
		end,
	})

	--Register Minimap Icon
	core.ATButton:Register("InstanceAchievementTracker", MiniMapLDB, AchievementTrackerOptions);

	--Show Minimap Icon
	if AchievementTrackerOptions["showMinimap"] then
		core:sendDebugMessage("Showing Minimap Icon")
        core.ATButton:Show("InstanceAchievementTracker")
	else
		core:sendDebugMessage("Hiding Minimap Icon")
		C_Timer.After(1, function()
			core.ATButton:Hide("InstanceAchievementTracker")		
		end)
    end

	--Set whether addon should be enabled or disabled
	setAddonEnabled(AchievementTrackerOptions["enableAddon"])
end

function setCompletedSound(setCompletedSound)
	--print("Setting Completed Sound to...")
	--print(setCompletedSound)
	completedSound = setCompletedSound
end

function setFailedSound(setFailedSound)
	--print("Setting Failed Sound to...")
	--print(setFailedSound)
	failedSound = setFailedSound
end

function setEnableSound(setEnableSound)
	if setEnableSound then
		enableSound = true

		--Set sounds for user if not done already
		if completedSound == nil then
			AchievementTrackerOptions["completedSound"] = "Interface\\AddOns\\InstanceAchievementTracker\\Sounds\\Achievement Completed.ogg"
			AchievementTrackerOptions["completedSoundID"] = 13
			setCompletedSound("Interface\\AddOns\\InstanceAchievementTracker\\Sounds\\Achievement Completed.ogg")
			MSA_DropDownMenu_SetText(_G["AchievementTracker_SelectSoundDropdownCompleted"], 13)
		end

		if failedSound == nil then
			AchievementTrackerOptions["failedSound"] = "Interface\\AddOns\\InstanceAchievementTracker\\Sounds\\Achievement Failed.ogg"
			AchievementTrackerOptions["failedSoundID"] = 11
			setFailedSound("Interface\\AddOns\\InstanceAchievementTracker\\Sounds\\Achievement Failed.ogg")   
			MSA_DropDownMenu_SetText(_G["AchievementTracker_SelectSoundDropdownFailed"], 11)  
		end
	else
		enableSound = false					
	end
end

function setAnnounceToRaidWarning(setAnnounceToRaidWarning)
	if setAnnounceToRaidWarning then
		announceToRaidWarning = true
	else
		announceToRaidWarning = false					
	end
end

function setAddonEnabled(addonEnabled)
	if addonEnabled then
		core:sendDebugMessage("Enabling Addon")
		events:RegisterEvent("PLAYER_ENTERING_WORLD")				--Used to detect if player is inside an instance when they enter the world
		events:RegisterEvent("ZONE_CHANGED_NEW_AREA")				--Used to detect if player is inside an instance when they change zone
		events:RegisterEvent("CHAT_MSG_ADDON")						--Allows the addon to communicate with other addons in the same party/raid
		
		core:sendDebugMessage("Registering CHAT_MSG_ADDON prefix")
		C_ChatInfo.RegisterAddonMessagePrefix("Whizzey") 
	else
		core:sendDebugMessage("Disabling Addon")
		events:UnregisterEvent("PLAYER_ENTERING_WORLD")				
		events:UnregisterEvent("ZONE_CHANGED_NEW_AREA")				
		events:UnregisterEvent("CHAT_MSG_ADDON")						
	end
end

function setOnlyTrackMissingAchievements(setOnlyTrackMissingAchievements)
	if setOnlyTrackMissingAchievements then
		core.onlyTrackMissingAchievements = true
	else
		core.onlyTrackMissingAchievements = false						
	end
end

function setAchievementScanEnabled(setAchievementScanEnabled)
	if setAchievementScanEnabled then
		core.enableAchievementScanning = true
	else
		core.enableAchievementScanning = false						
	end
end

function setAnnounceTrackedAchievementsToChat(setTrackedAchievements)
	if setTrackedAchievements then
		core.announceTrackedAchievementsToChat = true
	else
		core.announceTrackedAchievementsToChat = false						
	end
end

--Used by GUI functions to update the list of players being disabled.
function core:getPlayersInGroup2()
	getPlayersInGroup()
end

--Fired whenever the composition of the group changes.
--Used to alter size of group variables and which player in group is running the master addon
function events:GROUP_ROSTER_UPDATE()
	--When player enters the world in an instance start the achievement scanner. Only start the scanner if the raid size has changed
	core:sendDebugMessage("Group Roster Update")
	if core.enableAchievementScanning == true then
		--Player has enabled acheivement scanning from the option menu
		core:sendDebugMessage("Achievement Scanning Enabled")
		if scanInProgress == false then
			--There is currently no achievement scan in progress, so intiate a new acheivement scan
			core:sendDebugMessage("Starting Scan")
			scanInProgress = true
			getPlayersInGroup()
		else
			--There is currently an achievement scan in progress. Ask for a rescan once the current achievement scan has finished
			core:sendDebugMessage("Scan in progress. Asking for rescan")
			rescanNeeded = true
		end
	else
		--Player has disabled acheivement scanning from the option menu
		core:sendDebugMessage("Achievement Scanning is disabled")
	end

	--Update the group size whenever the composition of the group changes
	core:getGroupSize()

	--Update the rank of the current player incase it has changed. This is used so we know who should output information to chat when mutliple people have the addon installed.
	for i = 1, core.groupSize do
		local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
		if name == UnitName("Player") then
			--Send out message so other adds can add new player to their arrays
			playerRank = rank
			core:sendDebugMessage("Setting rank to: " .. rank)
		end
	end
end

function events:CHAT_MSG_SYSTEM(self, message)
	local chatStrs = {"joins the party", "joined the instance group", "joined the raid group", "joined a raid group", "leaves the party", "left the instance group", "leaves the party", "left the raid group"}
	for i = 1, #chatStrs do
		if string.match(message, chatStrs[i]) then
			if core.enableAchievementScanning == true then
				core:sendDebugMessage("CHAT_MSG_SYSTEM: " .. message)
				--Player has enabled acheivement scanning from the option menu
				core:sendDebugMessage("Achievement Scanning Enabled 2")
				if scanInProgress == false then
					--There is currently no achievement scan in progress, so intiate a new acheivement scan
					core:sendDebugMessage("Starting Scan")
					scanInProgress = true
					getPlayersInGroup()
				else
					--There is currently an achievement scan in progress. Ask for a rescan once the current achievement scan has finished
					core:sendDebugMessage("Scan in progress. Asking for rescan")
					rescanNeeded = true
				end
			else
				--Player has disabled acheivement scanning from the option menu
				core:sendDebugMessage("Achievement Scanning is disabled")
			end
		end
	end
end

--Fired when a user engages a boss. Used to output to chat which achievement is currently being tracked
--Does not fire for all bosses or sometimes fires too late into the fight so some fight manually call the achievement tracking functions
--Does not get called for achievements which are not part of a boss fight so achievement tracking is calling manually once per session for those achievements
function events:ENCOUNTER_START(self, encounterID, encounterName, difficultyID, groupSize)
	core:sendDebugMessage("---Encounter Started---")
	core:sendDebugMessage("Encounter ID: " .. encounterID)
	--table.insert(--TargetLogData, "---Encounter Started---")
	core.encounterStarted = true

	if core.displayAchievements == true then
		core.disableAchievementTracking = false
	end

	--If encounter ID is detected then use that to detectBoss
	if encounterID ~= nil then
		--Found the boss encounter ID so clear out any other bosses currently stored
		if core.lockDetection == false then
			detectBossByEncounterID(encounterID)
		end
	end
end

--Fired when a users has finished engaging a boss. This is used to make sure achievement tracking is not fired when the player is not attacking a boss
function events:ENCOUNTER_END()
	core:sendDebugMessage("---Encounter Ended---")
	--table.insert(--TargetLogData, "---Encounter Ended---")
	core.encounterStarted = false
	core.encounterDetected = false
end

--This event is used to scan players in the group to see which achievements they are currently missing
function events:INSPECT_ACHIEVEMENT_READY(self, GUID)
	local class, classFilename, race, raceFilename, sex, name, realm = GetPlayerInfoByGUID(GUID)
	core:sendDebugMessage("INSPECT_ACHIEVEMENT_READY FIRED. INFORMATION FOR: " .. name)

	--Check if the Inspect_Achievement_Ready was from a request that we made and not from another addon. Really important.
	if core.currentComparisonUnit == name then
		--Make sure the player is still online since achievement scanning may happen some time after scanning players
		if UnitName(playerCurrentlyScanning) ~= nil then
			local name2, realm2 = UnitName(playerCurrentlyScanning)
			--Find all bosses for the current instance the player is in.
			for boss,_ in pairs(core.Instances[core.expansion][core.instanceType][core.instance]) do
				if boss ~= "name" then
					--Check if the player has completed the achievement for the current boss
					local completed, month, day, year = GetAchievementComparisonInfo(core.Instances[core.expansion][core.instanceType][core.instance][boss].achievement)

					--Make sure any text being displayed currently for the achievement is removed.
					if core.Instances[core.expansion][core.instanceType][core.instance][boss].players[1] == L["Enter instance to start scanning"] or core.Instances[core.expansion][core.instanceType][core.instance][boss].players[1] == L["No players in the group need this achievement"] then
						table.remove(core.Instances[core.expansion][core.instanceType][core.instance][boss].players, 1)
					end

					--If the player has not completed the achievement then add them to the players string to display in the GUI
					if completed == nil then
						local name, _ = UnitName(playersToScan[1])
						table.insert(core.Instances[core.expansion][core.instanceType][core.instance][boss].players, name)
					end
				end
			end

			--Check if any of the achievements have been achieved by every player in the group. If they have then update GUI with appropriate text
			for boss,_ in pairs(core.Instances[core.expansion][core.instanceType][core.instance]) do
				if boss ~= "name" then
					if #core.Instances[core.expansion][core.instanceType][core.instance][boss].players == 0 then
						table.insert(core.Instances[core.expansion][core.instanceType][core.instance][boss].players, L["No players in the group need this achievement"])
					end
				end
			end

			--print("Scanned " .. UnitName(playersToScan[1]))
			table.insert(playersScanned, playersToScan[1])
			table.remove(playersToScan, 1)

			--Update the GUI
			core.Config:Instance_OnClickAutomatic()

			playerCurrentlyScanning = nil

			--Last player scan was successfully. Check if we need to continue scanning
			scanCounter = scanCounter + 1 --Stop previous timers from executing!
			if #playersToScan > 0 then
				--More players still need scanning
				getInstanceAchievements()
			elseif #playersToScan == 0 and rescanNeeded == false and #playersScanned == core.groupSize then
				printMessage("Achievement Scanning Finished (" .. #playersScanned .. "/" .. core.groupSize .. ")")
				scanInProgress = false
				core.scanFinished = true

				--Once the achievement scanning has finished enable the achievement tab to start scanning again
				if _G["AchievementFrameComparison"] ~= nil then
					--Re-register this event so achievement ui and inspect achievement ui work as intended
					_G["AchievementFrameComparison"]:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
				end
			elseif #playersToScan == 0 and rescanNeeded == true then
				core:sendDebugMessage("Achievement Scanning Finished but some players still need scanning. Waiting 20 seconds then trying again (" .. #playersScanned .. "/" .. core.groupSize .. ")")
				--Once the achievement scanning has finished enable the achievement tab to start scanning again
				if _G["AchievementFrameComparison"] ~= nil then
					--Re-register this event so achievement ui and inspect achievement ui work as intended
					_G["AchievementFrameComparison"]:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
				end

				C_Timer.After(10, function()
					scanInProgress = true
					getPlayersInGroup()
				end)
			else
				core:sendDebugMessage("UNKNOWN ERROR")
			end
		else
			--Someone in the group cannot be scanned because they have gone offline since scanning took place, or they are not currently out of range of scanning.
			--Must be in the same instance in order to get scanned.
			rescanNeeded = true
		end
	else
		--Someone else has called the INSPECT_ACHIEVEMENT_READY event so do not perform achievement scanning for that player
		core:sendDebugMessage("Incorrect INSPECT_ACHIEVEMENT_READY call for " .. name)
	end
end

--Fired when the players has finished loading in the world.
--Used to detect whether the player is in an instance and if so it will setup the instance variables for that instance
--This is done so we know which achievements we need to be tracking and so we know which achievements to scan the players in the group for
function events:PLAYER_ENTERING_WORLD()
	getInstanceInfomation()
end

--Fired when the player enters a new zone.
--Used to detect whether the player is in an instance and if so it will setup the instance variables for that instance
--This is done so we know which achievements we need to be tracking and so we know which achievements to scan the players in the group for
--It is also used to disable tracking for a instance once the player has left that particular instance
function events:ZONE_CHANGED_NEW_AREA()
	if UIConfig ~= nil and core.inInstance == false then
		core:sendDebugMessage("Hiding Tracking UI")
		UIConfig:Hide()
	end

	getInstanceInfomation()

	if core.inInstance == false and core.instanceVariablesReset == false then
		--Update achievement tracking
		for boss,_ in pairs(core.Instances[core.expansion][core.instanceType][core.instance]) do
			if boss ~= "name" then
				core.Instances[core.expansion][core.instanceType][core.instance][boss].players = {L["Enter instance to start scanning"]}
			end
		end

		--Update the GUI
		core.Config:Instance_OnClickAutomatic()

		--If user has left the instance then unregister events if they were registered
		core:sendDebugMessage("Player has left instance. Unregestering events and resetting variables")
		events:UnregisterEvent("GROUP_ROSTER_UPDATE")
		events:UnregisterEvent("CHAT_MSG_SYSTEM")
		events:UnregisterEvent("PLAYER_REGEN_DISABLED")
		events:UnregisterEvent("PLAYER_REGEN_ENABLED")
		events:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		events:UnregisterEvent("INSPECT_ACHIEVEMENT_READY")
		events:UnregisterEvent("ENCOUNTER_START")						
		events:UnregisterEvent("ENCOUNTER_END")						

		--Reset Instance Variables
		core.expansion = nil
		core.instanceType = nil
		core.instance = nil
		core.instanceNameSpaces = nil
		core.currentBosses = {}
		core.foundBoss = false
		core.mobCache = {}
		core.instanceVariablesReset = true --This is done so we only reset instance variables once, rather than everytime the player changes zone

		--Reset Achievement Variabless
		playersToScan = {}
		playersScanned = {}
		rescanNeeded = false
		playerCurrentlyScanning = nil
		scanInProgress = false
		core.scanFinished = false
		scanAnnounced = false

		--Unregister events if set
		if pcall(function() core[core.instanceClear]:InstanceCleanup() end) == true then
			core:sendDebugMessage("Cleaning up instance events")
			core[core.instanceClear]:InstanceCleanup()
		end
	end
end

--Used to communicate between everyone in the group using the addon to decide which addon is the master addon
--The master addon is detected at the start of every fight so we don't have to worry about if a player is in the instance/offline etc
function events:CHAT_MSG_ADDON(self, prefix, message, channel, sender)
	--core:sendDebugMessage("CHAT_MSG_ADDON FIRED")
	--core:sendDebugMessage(message)

	--Addon is checking who should be leader
	local name, realm = UnitName("Player")
	local nameSend, realmSend = strsplit("-", sender)

	if string.match(message, "demote") then
		--Another addon has requested that this adodn demotes itself
		local nameFetched, realmFetched, message = strsplit("-", message)

		if nameFetched == name then
			--Demote this player
			core:sendDebugMessage("Demoting Myself...")
			masterAddon = false
		end
	elseif string.match(message, "info") then
		--Other addons have returned the requested info
		local info, addonIDRecieved, nameRecieved, masterAddonRecieved, playerRankRecieved, majorVersionRecieved, minorVersionRecieved, onlyTrackMissingAchievementsRecieved = strsplit(",", message)
		local demotionRequired = false

		if nameRecieved ~= name then
			if masterAddonRecieved ~= nil then
				core:sendDebugMessage("------------NEW REQUEST------------")
				core:sendDebugMessage("Recieved Info From: " .. sender)
				core:sendDebugMessage("AddonID: " .. addonIDRecieved .. " : " .. tostring(addonID))
				core:sendDebugMessage("Master Addon: " .. masterAddonRecieved .. " : " .. tostring(masterAddon))
				core:sendDebugMessage("Player Rank: " .. playerRankRecieved .. " : " .. tostring(playerRank))
				core:sendDebugMessage("Major Version: " .. majorVersionRecieved .. " : " .. tostring(core.Config.majorVersion))
				core:sendDebugMessage("Minor Version: " .. minorVersionRecieved .. " : " .. tostring(core.Config.minorVersion))
				core:sendDebugMessage("Only Track Missing Achievements: " .. onlyTrackMissingAchievementsRecieved .. " : " .. tostring(core.trackingSupressed))
			end

			if masterAddonRecieved == "true" then

				if onlyTrackMissingAchievementsRecieved == "true" and core.trackingSupressed == false then
					--Other player is supressing achievements but this addon is not so set this to the master addon
					core:sendDebugMessage("0.1: " .. sender .. " is supressing achievements so demote")
					masterAddon = true
					demotionRequired = true
				elseif onlyTrackMissingAchievementsRecieved == "false" and core.trackingSupressed == true then
					core:sendDebugMessage("0.2: This addon is supressing messages so demote")
					--This addon is supressing achievements but other addon is not so demote this addon
					masterAddon = false
				elseif tonumber(majorVersionRecieved) < core.Config.majorVersion then
					--Major version recieved from other player is lower so set this addon to the master addon
					core:sendDebugMessage("1: " .. sender .. " has a lower major version. Setting this addon to master")
					core:sendDebugMessage("Setting Master Addon 2")
					masterAddon = true
					demotionRequired = true
				elseif tonumber(majorVersionRecieved) == core.Config.majorVersion and tonumber(minorVersionRecieved) < core.Config.minorVersion then
					--Major version recieved from other player is the same but other player has lower minor version so set this addon to the master addon
					core:sendDebugMessage("2: " .. sender .. " has a lower minor version. Setting this addon to master")
					core:sendDebugMessage("Setting Master Addon 3")
					masterAddon = true
					demotionRequired = true
				elseif tonumber(majorVersionRecieved) == core.Config.majorVersion and tonumber(minorVersionRecieved) == core.Config.minorVersion and tonumber(playerRankRecieved) < playerRank then
					--Other player has same major and minor version but has lower rank than this addon so set this addon to the master addon					
					core:sendDebugMessage("3: " .. sender .. " has a lower rank. Setting this addon to master")
					core:sendDebugMessage("Setting Master Addon 4")
					masterAddon = true
					demotionRequired = true
				elseif tonumber(majorVersionRecieved) == core.Config.majorVersion and tonumber(minorVersionRecieved) == core.Config.minorVersion and tonumber(playerRankRecieved) == playerRank and tonumber(addonIDRecieved) < addonID then
					--Other player has exact same requirements but has lower addonID so set this addon to the master addon
					core:sendDebugMessage("3: " .. sender .. " has a lower Addon ID. Setting this addon to master")
					core:sendDebugMessage("Setting Master Addon 5")
					masterAddon = true
					demotionRequired = true
				elseif tonumber(majorVersionRecieved) == core.Config.majorVersion and tonumber(minorVersionRecieved) == core.Config.minorVersion and tonumber(playerRankRecieved) == playerRank and tonumber(addonIDRecieved) == addonID then
					--Everything about the 2 addons are completely identical. Keep rolling for a random new addonID number until it's different from the one recieved
					core:sendDebugMessage("5: " .. sender .. " Both addon have the same requirements. Sorting players name into alphabetical order. Player first will get master")
					names = {}
					names[1] = nameSend
					names[2] = UnitName("Player")

					local sortedKeys = getKeysSortedByValue(names, function(a, b) return a < b end)

					local counter = 1
					for _, key in ipairs(sortedKeys) do
						if counter == 1 then
							core:sendDebugMessage(names[key])
							if names[key] == UnitName("Player") then
								core:sendDebugMessage("5.5: Setting This addon to master")
								masterAddon = true
							else
								core:sendDebugMessage("5.5: Demoting this addon")
								masterAddon = false
							end
							counter = counter + 1
						end
					end
				else
					core:sendDebugMessage("4: " .. sender .. " has better requirements. Not setting this addon to master")
					--Other addon has the better requirements so this addon should not be the master addon
					masterAddon = false
				end
			elseif masterAddonRecieved == "false" then
				--Other player addon is not master addon so set this addon to the master addon
				core:sendDebugMessage("5: " .. sender .. " is not the master addon. Setting this addon to master")
				core:sendDebugMessage("Setting Master Addon 7")
				masterAddon = true
			end
		end

		--Other addon has lower requirements so ask them to demote themself
		if demotionRequired == true then
			core:sendDebugMessage("Asking " .. sender .. " to demote themselves")
			C_ChatInfo.SendAddonMessage("Whizzey", sender .. "-demote", "RAID")
		end
	end
end

--Fired when a player has entered combat. Used to detect bosses and when we need to reset variables between boss fights
function events:PLAYER_REGEN_DISABLED()
	core.inCombat = true
	core:detectGroupType()
   	core:sendDebugMessage("Entered Combat")

   --DEBUG
	----core:sendDebugMessage(UnitGUID("Boss1"))
	----core:sendDebugMessage(UnitGUID("Boss2"))
end

--Fired when a player has left combat. Used to reset variables between boss fights
function events:PLAYER_REGEN_ENABLED()
   --Although the player running the addon has left combat, the boss could still be in combat with other players. Check everyone else in the group to see if anyone is still in combat with the boss
   if getCombatStatus() == false then
		if core.encounterDetected == false then
			core:clearInstanceVariables()
			core:clearVariables()
			core:sendDebugMessage("Locking Detection for 3 seconds")
			core.lockDetection = true
			C_Timer.After(3, function() 
				core.lockDetection = false
				core:sendDebugMessage("Detection unlocked")
			end)
		else
			core:sendDebugMessage("Not clearing global variables since encounter is still in progress")
		end
	   core:sendDebugMessage("Left Combat")
	   events:SetScript("OnUpdate",nil)
   else
	   --Someone in the group is still in combat. Wait 1 second then check again
	   events:SetScript("OnUpdate",events.onUpdate)
   end
end

--Used to monitor the combat log so we can track achievements. The variables change depending on the information being recieved from the combat log
function events:COMBAT_LOG_EVENT_UNFILTERED(self, ...)
	core.timestamp, core.type, core.hideCaster, core.sourceGUID, core.sourceName, core.sourceFlags, core.sourceRaidFlags, core.destGUID, core.destName, core.destFlags, core.destRaidFlags = CombatLogGetCurrentEventInfo()

	if string.match(core.type, "RANGE_") or string.match(core.type, "SPELL_") or string.match(core.type, "SPELL_PERIODIC_") or string.match(core.type, "SPELL_BUILDING_") then
		core.spellId, core.spellName, core.spellSchool = select(12, CombatLogGetCurrentEventInfo())

		if string.match(core.type, "_DAMAGE") then
			core.amount, core.overkill, core.school, core.resisted, core.blocked, core.absorbed, core.critical, core.glancing, core.crushing = select(15, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_MISSED") then
			core.missType, core.isOffHand, core.amountMissed = select(15, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_HEAL") then
			core.amount, core.overhealing, core.absorbed, core.critical = select(15, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_ENERGIZE") then
			core.amount, core.powerType = select(15, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_DRAIN") or string.match(core.type, "_LEECH") then
			core.amount, core.powerType, core.extraAmount = select(15, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_INTERRUPT") or string.match(core.type, "_DISPEL_FAILED") then
			core.extraSpellId, core.extraSpellName,	core.extraSchool = select(15, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_DISPEL") or string.match(core.type, "_STOLEN") then
			core.extraSpellId, core.extraSpellName, core.extraSchool, core.auraType = select(15, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_EXTRA_ATTACKS") then
			core.amount = select(15, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_AURA_APPLIED") or string.match(core.type, "_AURA_REMOVED") or string.match(core.type, "_AURA_APPLIED_DOSE") or string.match(core.type, "_AURA_REMOVED_DOSE") or string.match(core.type, "_AURA_REFRESH") then
			core.auraType, core.amount = select(15, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_AURA_BROKEN") then
			core.auraType = select(15, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_AURA_BROKEN_SPELL") then
			core.extraSpellId, core.extraSpellName, core.extraSchool, core.auraType = select(15, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_CAST_FAILED") then
			core.failedType = select(15, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_ABSORBED") then
			core.addDestGUID, core.addDestName, core.addDestFlags, core.addDestRaidFlags, core.addSpellId, core.addSpellName, core.addSpellSchool = select(15, CombatLogGetCurrentEventInfo())
		end
	elseif string.match(core.type, "SWING_") then
		if string.match(core.type, "_DAMAGE") then
			core.amount, core.overkill, core.school, core.resisted, core.blocked, core.absorbed, core.critical, core.glancing, core.crushing = select(12, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_MISSED") then
			core.missType, core.isOffHand, core.amountMissed = select(12, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_HEAL") then
			core.amount, core.overhealing, core.absorbed, core.critical = select(12, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_ENERGIZE") then
			core.amount, core.powerType = select(12, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_DRAIN") or string.match(core.type, "_LEECH") then
			core.amount, core.powerType, core.extraAmount = select(12, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_INTERRUPT") or string.match(core.type, "_DISPEL_FAILED") then
			core.extraSpellId, core.extraSpellName,	core.extraSchool = select(12, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_DISPEL") or string.match(core.type, "_STOLEN") then
			core.extraSpellId, core.extraSpellName, core.extraSchool, core.auraType = select(12, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_EXTRA_ATTACKS") then
			core.amount = select(12, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_AURA_APPLIED") or string.match(core.type, "_AURA_REMOVED") or string.match(core.type, "_AURA_APPLIED_DOSE") or string.match(core.type, "_AURA_REMOVED_DOSE") or string.match(core.type, "_AURA_REFRESH") then
			core.auraType, core.amount = select(12, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_AURA_BROKEN") then
			core.auraType = select(12, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_AURA_BROKEN_SPELL") then
			core.extraSpellId, core.extraSpellName, core.extraSchool, core.auraType = select(12, CombatLogGetCurrentEventInfo())
		elseif string.match(core.type, "_CAST_FAILED") then
			core.failedType = select(12, CombatLogGetCurrentEventInfo())
		end
	elseif string.match(core.type, "ENVIRONMENTAL_") then
		core.environmentalType = select(12, ...)

		if string.match(core.type, "_DAMAGE") then
			core.amount, core.overkill, core.school, core.resisted, core.blocked, core.absorbed, core.critical, core.glancing, core.crushing = select(13, ...)
		elseif string.match(core.type, "_MISSED") then
			core.missType, core.isOffHand, core.amountMissed = select(13, ...)
		elseif string.match(core.type, "_HEAL") then
			core.amount, core.overhealing, core.absorbed, core.critical = select(13, ...)
		elseif string.match(core.type, "_ENERGIZE") then
			core.amount, core.powerType = select(13, ...)
		elseif string.match(core.type, "_DRAIN") or string.match(core.type, "_LEECH") then
			core.amount, core.powerType, core.extraAmount = select(13, ...)
		elseif string.match(core.type, "_INTERRUPT") or string.match(core.type, "_DISPEL_FAILED") then
			core.extraSpellId, core.extraSpellName,	core.extraSchool = select(13, ...)
		elseif string.match(core.type, "_DISPEL") or string.match(core.type, "_STOLEN") then
			core.extraSpellId, core.extraSpellName, core.extraSchool, core.auraType = select(13, ...)
		elseif string.match(core.type, "_EXTRA_ATTACKS") then
			core.amount = select(13, ...)
		elseif string.match(core.type, "_AURA_APPLIED") or string.match(core.type, "_AURA_REMOVED") or string.match(core.type, "_AURA_APPLIED_DOSE") or string.match(core.type, "_AURA_REMOVED_DOSE") or string.match(core.type, "_AURA_REFRESH") then
			core.auraType, core.amount = select(13, ...)
		elseif string.match(core.type, "_AURA_BROKEN") then
			core.auraType = select(13, ...)
		elseif string.match(core.type, "_AURA_BROKEN_SPELL") then
			core.extraSpellId, core.extraSpellName, core.extraSchool, core.auraType = select(13, ...)
		elseif string.match(core.type, "_CAST_FAILED") then
			core.failedType = select(13, ...)
		end
	end

	if string.match(core.sourceGUID, "Creature") or string.match(core.destGUID, "Creature") or string.match(core.sourceGUID, "Vehicle") or string.match(core.destGUID, "Vehicle") then
		--GUID for a creature
		core.unitTypeSrc, _, _, _, _, core.sourceID, core.spawn_uid = strsplit("-", core.sourceGUID)
		core.unitType, _, _, _, _, core.destID, core.spawn_uid_dest = strsplit("-", core.destGUID)
		core.currentUnit = "Creature"

		if string.match(core.sourceGUID, "Creature") or string.match(core.sourceGUID, "Vehicle") then
			core.currentSource = "Creature"
		elseif string.match(core.destGUID, "Creature") or string.match(core.destGUID, "Vehicle") then
			core.currentDest = "Creature"
		end
	end

	if string.match(core.sourceGUID, "Player") or string.match(core.destGUID, "Player") then
		--GUID for a player
		core.unitTypeSrcPlayer, _, _, _, _, core.sourceIDPlayer, core.spawn_uidPlayer = strsplit("-", core.sourceGUID)
		core.unitTypePlayer, core.destIDPlayer, core.spawn_uid_dest_Player = strsplit("-", core.destGUID)
		core.currentUnit = "Player"

		if string.match(core.sourceGUID, "Player") then
			core.currentSource = "Player"
		elseif string.match(core.destGUID, "Player") then
			core.currentDest = "Player"
		end
	end

	--Boss Detection!
	if core.foundBoss == true then
		--Start tracking the particular boss if the user has not disabled tracking for that boss
		for i = 1, #core.currentBosses do
			if core.currentBosses[i].enabled == true then
				if core.onlyTrackMissingAchievements == false or (core.onlyTrackMissingAchievements == true and core.currentBosses[i].players ~= L["No players in the group need this achievement"]) then
					core.currentBosses[i].track()
				end
			end
		end
	else
		if core.lockDetection == false then
			--Check if any of the 5 nameplates have caches boss ID and whether source and dest GUID have been stored or not
			local doNotTrack = false
			for i = 1, 5 do
				if UnitGUID("boss" .. i) ~= nil and UnitIsDead("boss" .. i) == false and UnitIsEnemy("Player", "boss" .. i) == true then
					local _, _, _, _, _, bossID, _ = strsplit("-", UnitGUID("boss" .. i))
					if bossID ~= nil then
						if core:has_value(core.mobCache, bossID) == false then
							core:sendDebugMessage("Calling Detect Boss 1: " .. bossID)
							detectBoss(bossID)
						end
					end
				elseif UnitIsDead("boss" .. i) == true then
					doNotTrack = true
				end
			end

			if core.sourceID ~= nil and doNotTrack == false and core.currentSource == "Creature" then
				--core:sendDebugMessage(core.sourceID)
				if core:has_value(core.mobCache, core.sourceID) ~= true then
					core:sendDebugMessage("Calling Detect Boss 2: " .. core.sourceID)
					--print(...)
					detectBoss(core.sourceID)
				end
			end

			if core.destID ~= nil and doNotTrack == false and core.currentDest == "Creature" then
				--core:sendDebugMessage(core.destID)
				if core:has_value(core.mobCache, core.destID) == false then
					core:sendDebugMessage("Calling Detect Boss 3: " .. core.destID)
					--print(...)
					detectBoss(core.destID)
				end
			end

			--Start tracking the particular boss if the user has not disabled tracking for that boss
			for i = 1, #core.currentBosses do
				if core.currentBosses[i].enabled == true then
					if core.onlyTrackMissingAchievements == false or (core.onlyTrackMissingAchievements == true and core.currentBosses[i].players ~= L["No players in the group need this achievement"]) then
						core.currentBosses[i].track()
					end
				end
			end

			--Track additional variables for the instance if they are not tied to a boss/encounter
			if pcall(function() core[core.instanceClear]:TrackAdditional() end) == true then
				core[core.instanceClear]:TrackAdditional()
			end
		end
	end
end

------------------------------------------------------
---- Detection Function
------------------------------------------------------

--Detect whether the user is in a party/raid or alone. This is used to output messages to the right chat channel.
function core:detectGroupType()
	--Detect type of group the user is in
	if UnitInRaid("player") then
		core.chatType = "RAID"
	elseif UnitInParty("player") then
		core.chatType = "PARTY"
	else
		core.chatType = "SAY"
	end

	--Debug to stop message going out to other people by accident
	--core.chatType = "OFFICER"
end

--Detect Raid and dungeons bosses which have an encounter ID
function detectBossByEncounterID(id)
	core:sendDebugMessage("Detected boss using ENCOUNTER ID")
	core:sendDebugMessage("Found the following encounter ID: " .. id)
	local counter = 0
	for boss,_ in pairs(core.Instances[core.expansion][core.instanceType][core.instance]) do
		if boss ~= "name" then
			if core.Instances[core.expansion][core.instanceType][core.instance][boss].encounterID ~= nil then
				--Detect boss by the encounter ID
				core:sendDebugMessage("Type:")
				--core:sendDebugMessage(core.Instances[core.expansion][core.instanceType][core.instance][boss].encounterID)
				if type(core.Instances[core.expansion][core.instanceType][core.instance][boss].encounterID) == "table" then
					--If achievement relates to multiple encounters
					for i = 1, #core.Instances[core.expansion][core.instanceType][core.instance][boss].encounterID do
						--Check whether the boss has an achievement first before adding. This is so we can output to the chat. "IAT cannot track any achievements for this encounter" if needed
						if id == core.Instances[core.expansion][core.instanceType][core.instance][boss].encounterID[i] then
							if core.Instances[core.expansion][core.instanceType][core.instance][boss].achievement ~= false then
								if core:has_value(currentBossNums, boss) == false then
									if counter == 0 then
										--Clear the array storing bosses and achievements so we only output track achievements relevant to that fight
										core.currentBosses = {}
										core.achievementIDs = {}
										currentBossNums = {}
										counter = 1
									end
									core:sendDebugMessage("(E) Adding the following encounter ID: " .. boss)
									table.insert(core.currentBosses, core.Instances[core.expansion][core.instanceType][core.instance][boss])
									table.insert(currentBossNums, boss)
								end
								if core:has_value(core.achievementIDs, core.Instances[core.expansion][core.instanceType][core.instance][boss].achievement) == false then
									core:sendDebugMessage("(E) Adding the following achievement ID beacuse it doesn't exist: " .. core.Instances[core.expansion][core.instanceType][core.instance][boss].achievement)
									table.insert(core.achievementIDs, core.Instances[core.expansion][core.instanceType][core.instance][boss].achievement)
								end
								if core.Instances[core.expansion][core.instanceType][core.instance][boss].enabled == true then
									core.outputTrackingStatus = true
								end
								core.foundBoss = true
							end
							core.encounterDetected = true --This will stop other bosses being detected by accident through the detection method below
						end
					end
				elseif id == core.Instances[core.expansion][core.instanceType][core.instance][boss].encounterID then
					--Check whether the boss has an achievement first before adding. This is so we can output to the chat. "IAT cannot track any achievements for this encounter" if needed
					if core.Instances[core.expansion][core.instanceType][core.instance][boss].achievement ~= false then
						if core:has_value(currentBossNums, boss) == false then
							if counter == 0 then
								--Clear the array storing bosses and achievements so we only output track achievements relevant to that fight
								core.currentBosses = {}
								core.achievementIDs = {}
								currentBossNums = {}
								counter = 1
							end
							core:sendDebugMessage("(E) Adding the following encounter ID: " .. boss)
							table.insert(core.currentBosses, core.Instances[core.expansion][core.instanceType][core.instance][boss])
							table.insert(currentBossNums, boss)
						end
						if core:has_value(core.achievementIDs, core.Instances[core.expansion][core.instanceType][core.instance][boss].achievement) == false then
							core:sendDebugMessage("(E) Adding the following achievement ID beacuse it doesn't exist: " .. core.Instances[core.expansion][core.instanceType][core.instance][boss].achievement)
							table.insert(core.achievementIDs, core.Instances[core.expansion][core.instanceType][core.instance][boss].achievement)
						end
						if core.Instances[core.expansion][core.instanceType][core.instance][boss].enabled == true then
							core.outputTrackingStatus = true
						end
						core.foundBoss = true
					end
					core.encounterDetected = true --This will stop other bosses being detected by accident through the detection method below
				end
			end
		end
	end

	--If encounter is detected but no achievements for the boss have been found then output no achievements to track for this encounter
	if core.outputTrackingStatus == false then
		if core.encounterDetected == true and core.onlyTrackMissingAchievements == false then
			core:printMessage("IAT cannot track any achievements for this encounter.")

			--Announce to chat if enabled
			if core.announceTrackedAchievementsToChat == true then
				core:sendMessage("IAT cannot track any achievements for this encounter.")
			end
		end
	end

	if core.foundBoss == true then
		--Display tracking achievement for that boss if it has not been output yet for the fight. Make sure we are in combat as well before calling this function
		core:getAchievementToTrack()
	end
end

--Detect Raid & Dungeons bosses which have nameplates
function detectBossByNameplate(id)
	--Fallback method for detecting boss fights when ENCOUNTER_START fails to fire
	core:sendDebugMessage("Detecting Boss by NAMEPLATE")
	core:sendDebugMessage("Found the following boss ID: " .. id)

	for boss,_ in pairs(core.Instances[core.expansion][core.instanceType][core.instance]) do
		if boss ~= "name" then
			if core.Instances[core.expansion][core.instanceType][core.instance][boss].bossIDs ~= nil and core.encounterDetected == false then
				if #core.Instances[core.expansion][core.instanceType][core.instance][boss].bossIDs > 0 then
					for i = 1, #core.Instances[core.expansion][core.instanceType][core.instance][boss].bossIDs do
						local bossID = core.Instances[core.expansion][core.instanceType][core.instance][boss].bossIDs[i]
						if string.find(id, bossID) then
							if core:has_value(currentBossNums, boss) == false then
								core:sendDebugMessage("Adding the following boss: " .. boss)
								table.insert(core.currentBosses, core.Instances[core.expansion][core.instanceType][core.instance][boss])
								table.insert(currentBossNums, boss)
							end
							if core:has_value(core.achievementIDs, core.Instances[core.expansion][core.instanceType][core.instance][boss].achievement) == false then
								core:sendDebugMessage("Adding the following achievement ID beacuse it doesn't exist: " .. core.Instances[core.expansion][core.instanceType][core.instance][boss].achievement)
								table.insert(core.achievementIDs, core.Instances[core.expansion][core.instanceType][core.instance][boss].achievement)
							end
							if core.Instances[core.expansion][core.instanceType][core.instance][boss].enabled == true then
								core.outputTrackingStatus = true
							end
							core.foundBoss = true
						end
					end
				end
			end
		end
	end

	--If a boss has been found then output the achievements that will be tracked to chat.
	--If an id is found by not in the database then add to cache to prevent the same ID being checked against the database over and over again
	if core.foundBoss == true then
		--Display tracking achievement for that boss if it has not been output yet for the fight. Make sure we are in combat as well before calling this function
		if core.encounterStarted == true then
			core:getAchievementToTrack()
		end
	else
		if core:has_value(core.mobCache, id) ~= true then
			table.insert(core.mobCache, id)
		end
	end
end

--Where the player enters combat, check if any of the mobs/bosses need to be tracked or not
function detectBoss(id)
	--Fallback method for detecting boss fights and also used to detect trash mobs for some achievements
	core:sendDebugMessage("Found the following boss ID: " .. id)

	for boss,_ in pairs(core.Instances[core.expansion][core.instanceType][core.instance]) do
		if boss ~= "name" then
			if core.Instances[core.expansion][core.instanceType][core.instance][boss].bossIDs ~= nil and core.encounterDetected == false then
				--Detect boss by the ID of the npc
				--core:sendDebugMessage("Detecting boss by npc ID")
				if #core.Instances[core.expansion][core.instanceType][core.instance][boss].bossIDs > 0 then
					for i = 1, #core.Instances[core.expansion][core.instanceType][core.instance][boss].bossIDs do
						local bossID = core.Instances[core.expansion][core.instanceType][core.instance][boss].bossIDs[i]
						if string.find(id, bossID) then
							if core:has_value(currentBossNums, boss) == false then
								core:sendDebugMessage("Adding the following boss: " .. boss)
								table.insert(core.currentBosses, core.Instances[core.expansion][core.instanceType][core.instance][boss])
								table.insert(currentBossNums, boss)
							end
							if core:has_value(core.achievementIDs, core.Instances[core.expansion][core.instanceType][core.instance][boss].achievement) == false then
								core:sendDebugMessage("Adding the following achievement ID beacuse it doesn't exist: " .. core.Instances[core.expansion][core.instanceType][core.instance][boss].achievement)
								table.insert(core.achievementIDs, core.Instances[core.expansion][core.instanceType][core.instance][boss].achievement)
							end
							if core.Instances[core.expansion][core.instanceType][core.instance][boss].enabled == true then
								core.outputTrackingStatus = true
							end
							core.foundBoss = true
						end
					end
				end
			end
		end
	end

	--If a boss has been found then output the achievements that will be tracked to chat.
	--If an id is found by not in the database then add to cache to prevent the same ID being checked against the database over and over again
	if core.foundBoss == true then
		--Display tracking achievement for that boss if it has not been output yet for the fight. Make sure we are in combat as well before calling this function
		if core.encounterStarted == true then
			core:getAchievementToTrack()
		end
	else
		if core:has_value(core.mobCache, id) ~= true then
			table.insert(core.mobCache, id)
		end
	end
end

--Display the "Tracking {achievement} for achievements"
--Wait a few seconds here before outputting which acheivements to track since the encounter ID can fire after ID has picked up by another source such as GUID
--This will prevent the wrong achievements being displayed into chat
function core:getAchievementToTrack()
	C_Timer.After(2, function() 
		--print("HERE 1")
		if core.achievementTrackedMessageShown == false then
			--print("HERE 2")
			core:sendDebugMessage("Length of array: " .. #core.currentBosses)
			for i = 1, #core.currentBosses do
				core:sendDebugMessage("Achievement: " .. core.currentBosses[i].achievement)
				if core.currentBosses[i].partial == false and core.currentBosses[i].enabled == true then
					--core.currentBosses[i].players = L["No players in the group need this achievement"] --DEBUG ONLY
					
					if core.onlyTrackMissingAchievements == false or (core.onlyTrackMissingAchievements == true and core.currentBosses[i].players ~= L["No players in the group need this achievement"]) then
						printMessage("Tracking: "  .. GetAchievementLink(core.currentBosses[i].achievement))
					else
						--User has decided to supress achievement so will get a lower rank in the addon syncing
						core:sendDebugMessage("User supressing addon tracking")
						core:sendDebugMessage(core.currentBosses[i].players)
						core.trackingSupressed = true					
					end

					core:sendMessage("setup") --This is sent at the start of the encounter to elect a leader rather than waiting for the first message to output
					core.achievementTrackedMessageShown = true

					--Announce to chat if enabled
					if core.announceTrackedAchievementsToChat == true then
						if core.onlyTrackMissingAchievements == false or (core.onlyTrackMissingAchievements == true and core.currentBosses[i].players ~= L["No players in the group need this achievement"]) then
							core:sendMessage("Tracking: "  .. GetAchievementLink(core.currentBosses[i].achievement),true)
						end
					end
				end
	
				--Setup failed and completed achievements tablse
				table.insert(core.achievementsFailed, false)
				table.insert(core.achievementsCompleted, false)
			end
		end	
	end)
end

------------------------------------------------------
---- Messaging Functions
------------------------------------------------------

--Output messages to the chat. All messages get sent this function for easy management
function core:sendMessage(message, outputToRW, messageType)
	if message ~= lastMessageSent then
		if debugModeChat == false then
			if masterAddon == true and electionFinished == true then
				if message ~= "setup" then
					if outputToRW == true and core.chatType == "RAID" and announceToRaidWarning == true and (UnitIsGroupAssistant("Player") or UnitIsGroupLeader("Player")) then
						--Important message output to raid warning from user request
						--print("Outputting to Raid Warning")
						SendChatMessage("[IAT] " .. message,"RAID_WARNING",DEFAULT_CHAT_FRAME.editBox.languageID)
					elseif outputToRW == true and announceToRaidWarning == true then
						SendChatMessage("[IAT] " .. message,core.chatType,DEFAULT_CHAT_FRAME.editBox.languageID)
						RaidNotice_AddMessage(RaidWarningFrame, "[IAT] " .. message, ChatTypeInfo["RAID_WARNING"])
					else
						--print("Outputting normally")
						SendChatMessage("[IAT] " .. message,core.chatType,DEFAULT_CHAT_FRAME.editBox.languageID)
					end

					if outputToRW == true and enableSound == true and messageType == "completed" then
						--print(type(completedSound))
						--print(completedSound)
						if type(completedSound) == "number" then
							--print(1)
							PlaySound(completedSound, "Master")
						else
							--print(2)
							PlaySoundFile(completedSound, "Master")
						end
					elseif outputToRW == true and enableSound == true and messageType == "failed" then
						if type(failedSound) == "number" then
							--print(3)
							PlaySound(failedSound, "Master")
						else
							--print(4)
							PlaySoundFile(failedSound, "Master")
						end						
					end
				end
			elseif masterAddon == true and requestToRun == true then
				--We need to store the messages in a queue while the master addon is being decided
				table.insert(messageQueue, message)
			else
				if requestToRun == false then
					requestToRun = true

					--Broadcast addon info to decide whether it should be the master addon or not
					core:sendDebugMessage("Setting Master Addon 8")
					masterAddon = true
					local name, realm = UnitName("Player")
					C_ChatInfo.SendAddonMessage("Whizzey", "info," .. tostring(addonID) .. "," .. name .. "," .. tostring(masterAddon) .. "," .. tostring(playerRank) .. "," .. tostring(core.Config.majorVersion) .. "," .. tostring(core.Config.minorVersion) .. "," .. tostring(core.trackingSupressed), "RAID")

					C_Timer.After(3, function()
						if masterAddon == true then
							core:sendDebugMessage("This addon is in charge of outputting messages")
							if message ~= "setup" then
								if outputToRW == true and core.chatType == "RAID" and announceToRaidWarning == true and (UnitIsGroupAssistant("Player") or UnitIsGroupLeader("Player")) then
									--Important message output to raid warning from user request
									--print("Outputting to Raid Warning")
									SendChatMessage("[IAT] " .. message,"RAID_WARNING",DEFAULT_CHAT_FRAME.editBox.languageID)
								elseif outputToRW == true and announceToRaidWarning == true then
									SendChatMessage("[IAT] " .. message,core.chatType,DEFAULT_CHAT_FRAME.editBox.languageID)
									RaidNotice_AddMessage(RaidWarningFrame, "[IAT] " .. message, ChatTypeInfo["RAID_WARNING"])
								else
									--print("Outputting normally")
									SendChatMessage("[IAT] " .. message,core.chatType,DEFAULT_CHAT_FRAME.editBox.languageID)
								end

								if outputToRW == true and enableSound == true and messageType == "completed" then
									--print(type(completedSound))
									--print(completedSound)
									if type(completedSound) == "number" then
										--print(5)
										PlaySound(completedSound, "Master")
									else
										--print(6)
										PlaySoundFile(completedSound, "Master")
									end
								elseif outputToRW == true and enableSound == true and messageType == "failed" then
									if type(failedSound) == "number" then
										--print(7)
										PlaySound(failedSound, "Master")
									else
										--print(8)
										PlaySoundFile(failedSound, "Master")
									end						
								end
							end

							--If the message queue has messages in then ouput these messages as well
							if #messageQueue > 0 then
								for k, v in pairs(messageQueue) do
									if outputToRW == true and core.chatType == "RAID" and announceToRaidWarning == true and (UnitIsGroupAssistant("Player") or UnitIsGroupLeader("Player")) then
										--Important message output to raid warning from user request
										print("Outputting to Raid Warning")									
										SendChatMessage("[IAT] " .. v,"RAID_WARNING",DEFAULT_CHAT_FRAME.editBox.languageID)
									elseif outputToRW == true and announceToRaidWarning == true then
										SendChatMessage("[IAT] " .. message,core.chatType,DEFAULT_CHAT_FRAME.editBox.languageID)
										RaidNotice_AddMessage(RaidWarningFrame, "[IAT] " .. message, ChatTypeInfo["RAID_WARNING"])
									else
										print("Outputting to normal")										
										SendChatMessage("[IAT] " .. v,core.chatType,DEFAULT_CHAT_FRAME.editBox.languageID)
									end

									if outputToRW == true and enableSound == true and messageType == "completed" then
										--print(type(completedSound))
										--print(completedSound)
										if type(completedSound) == "number" then
											--print(9)
											PlaySound(completedSound, "Master")
										else
											--print(10)
											PlaySoundFile(completedSound, "Master")
										end
									elseif outputToRW == true and enableSound == true and messageType == "failed" then
										if type(failedSound) == "number" then
											--print(11)
											PlaySound(failedSound, "Master")
										else
											--print(12)
											PlaySoundFile(failedSound, "Master")
										end						
									end
								end
							end
							messageQueue = {}
						else
							core:sendDebugMessage("Another addon is currently in charge of outputting messages for this fight")
						end
						electionFinished = true
					end)
				end
			end
		elseif debugModeChat == true then
			core:sendDebugMessage("[DEBUG] " .. message)
		end
		lastMessageSent = message
	else
		--DEBUG
		core:sendDebugMessage("Cannot Send Message: " .. message)
	end

	--When a chat message needs to be sent, If the addon is not the master addon then request if there is currently a master addon in the group for the particular fight
	--The master addon check will be reset after every boss fight so we don't have to worry about players out of range/offline players etc
end

function core:sendMessageSafe(message)
	message = message:gsub("[\r\n]+","") --Remove newlines before ouputting to chat
	local openBracketOpen = false
	local tmpMessageStr = ""
	local tmpMessageArr = {}
	local lastSpacePosition = 0
	local currentStrPosition = 0
	for i = 1, string.utf8len(message) do
		currentStrPosition = currentStrPosition + 1
		if string.utf8sub(message, i, i) == "[" then
			--If we are opening a bracket we don't want to check for whitespaces as this will break links if they are cutoff between multiple lines.
			openBracketOpen = true
		elseif string.utf8sub(message, i, i) == "]" then
			--Brackets have been closed so we free to break to a new line again
			openBracketOpen = false
		end

		--Add this character to a tmp string. The string must not go above 255 words (blizzard limit) and cannot break between brackets
		--If the chracter is a space, we need to record the position of this so we can split at the correct position if limit goes over
		--The reason 249 is used is because we have to take into account the [IAT] prefix at the start of each message
		if currentStrPosition < 249 then
			--Room left to add characters.
			--This does not take into account whether we can complete a word before the limit. Therefore need to get position of last space in order to break
			tmpMessageStr = tmpMessageStr .. string.utf8sub(message, i, i)
			--print(tmpMessageStr .. " I(" .. i .. " ) CSP(" .. currentStrPosition .. ")" .. "L(" .. string.utf8len(tmpMessageStr) .. ")")

		else
			--Not enough room to add any more chracters.
			--1: If current character is white space and not in brackets then add to tmpArr and empty string
			--2: If we are in a middle of word then break the string at last space position. Add first half to array and 2nd half set as current string

			--print("Splitting String")

			if string.utf8sub(message, i, i) == " " and openBracketOpen == false then
				--Since we are on a space and not in brackets, we can just split here
				table.insert(tmpMessageArr, tmpMessageStr)
				tmpMessageStr = ""
				currentStrPosition = 0
			else
				--Split the current str at the position of the last space and the beginning and add to tmpArr
				table.insert(tmpMessageArr, string.utf8sub(tmpMessageStr, 1, lastSpacePosition)) --We don't need the space at the end of the line
				--print(string.utf8sub(tmpMessageStr, 1, lastSpacePosition))

				--Split the current str at the position of the last space till the end and set this as the new str.
				tmpMessageStr = string.utf8sub(tmpMessageStr, lastSpacePosition + 1) --We don't need the space since we are going to new line
				tmpMessageStr = tmpMessageStr .. string.utf8sub(message, i, i)
				currentStrPosition = string.utf8len(tmpMessageStr)

				--print(tmpMessageStr)
			end
		end

		if string.utf8sub(message, i, i) == " " and openBracketOpen == false then
			--Only count spaces that are not inside of brackets
			lastSpacePosition = currentStrPosition
			--print("Space Detected: " .. lastSpacePosition)
		end
	end

	--Insert the remaining string into array if length is greater than 0
	if string.utf8len(tmpMessageStr) > 0 then
		table.insert(tmpMessageArr, tmpMessageStr)
		--print("Inserting Remaining String...")
		--print("---" .. tmpMessageStr)
	end

	--print(tmpMessageArr[1])

	--Print the chat
	for i in ipairs(tmpMessageArr) do
		if debugMode == false then
			--print("Printing Safe Message")
			SendChatMessage("[IAT] " .. tmpMessageArr[i],core.chatType,DEFAULT_CHAT_FRAME.editBox.languageID)
		else
			print("[DEBUG] " .. tmpMessageArr[i])
		end
	end
end

function core:sendMessage2(message)

end

--Output messages depending on a counter and the specified interval
function core:sendMessageDelay(message, counter, interval)
	if counter - math.floor(counter/interval)*interval == 0 then
		core:sendMessage(message)
	end
end

--Output debug messages to the chat for testing purposes
function core:sendDebugMessage(message)
	if sendDebugMessages == true then
		print("[DEBUG] " .. message)
	end
end

--TODO: tidy this up so it can print out any colour
function printMessage(message)
	print("|cff00ccffIAT: |cffffffff" .. message)
end

function core:printMessage(message)
	print("|cff00ccffIAT: |cffffffff" .. message)
end

--Get the current achievement being tracked for custom output messages
function core:getAchievement(index)
	local value = index
	if index == nil then
		value = 1
	end
	return GetAchievementLink(core.achievementIDs[value])
end

------------------------------------------------------
---- Failed Achievment Functions
------------------------------------------------------

--Display the failed achievement message for achievements
function core:getAchievementFailed(index)
	local value = index
	if index == nil then
		value = 1
	end
	if core.achievementsFailed[value] == false then
		core:sendMessage(GetAchievementLink(core.achievementIDs[value]) .. " FAILED!",true,"failed")
		core.achievementsFailed[value] = true
	end
end

--Display the failed achievement message for achievements with message before
function core:getAchievementFailedWithMessageBefore(message, index)
	local value = index
	if index == nil then
		value = 1
	end
	if core.achievementsFailed[value] == false then

		core:sendMessage(message .. " " .. GetAchievementLink(core.achievementIDs[value]) .. " FAILED!",true,"failed")
		core.achievementsFailed[value] = true
	end
end

--Display the failed achievement message for achievements with message after
function core:getAchievementFailedWithMessageAfter(message, index)
	local value = index
	if index == nil then
		value = 1
	end
	if core.achievementsFailed[value] == false then
		core:sendMessage(GetAchievementLink(core.achievementIDs[value]) .. " FAILED! " .. message,true,"failed")
		core.achievementsFailed[value] = true
	end
end

--Display the failed achievement message for achievements with message before and after
function core:getAchievementFailedWithMessageBeforeAndAfter(messageBefore, messageAfter, index)
	local value = index
	if index == nil then
		value = 1
	end
	if core.achievementsFailed[value] == false then
		core:sendMessage(messageBefore .. " " .. GetAchievementLink(core.achievementIDs[value]) .. " FAILED! " .. messageAfter,true,"failed")
		core.achievementsFailed[value] = true
	end
end

--Display the failed achievement message for personal achievements
function core:getAchievementFailedPersonal(index)
	local value = index
	if index == nil then
		value = 1
	end
	if core.playersFailedPersonal[core.destName] == nil then
		--Players has not been hit already
		--Check if the player actually needs the achievement
		if core:has_value(core.currentBosses[value].players, core.destName) then
			--Player needs achievement but has failed it
			core:sendMessage(core.destName .. " has failed " .. GetAchievementLink(core.achievementIDs[value]) .. " (Personal Achievement)",true,"failed")
		end
		core.playersFailedPersonal[core.destName] = true
	end
end

--Display the failed achievement message for personal achievements with reason
function core:getAchievementFailedPersonalWithReason(reason, index)
	local value = index
	if index == nil then
		value = 1
	end
	if core.playersFailedPersonal[core.destName] == nil then
		--Players has not been hit already
		--Check if the player actually needs the achievement
		if core:has_value(core.currentBosses[value].players, core.destName) then
			--Player needs achievement but has failed it
			core:sendMessage(core.destName .. " has failed " .. GetAchievementLink(core.achievementIDs[value]) .. " (Personal Achievement) (Reason: " .. reason .. ")",true,"failed")
		end
		core.playersFailedPersonal[core.destName] = true
	end
end

------------------------------------------------------
---- Completed Achievment Functions
------------------------------------------------------

--Display the requirements completed message for achievements
function core:getAchievementSuccess(index)
	local value = index
	if index == nil then
		value = 1
	end
	if core.achievementsCompleted[value] == false then
		core:sendMessage(GetAchievementLink(core.achievementIDs[value]) .. " Criteria has been met. Boss can now be killed!",true,"completed")
		core.achievementsCompleted[value] = true
	end
end

--Display the requirements completed message for achievements with message before
function core:getAchievementSuccessWithMessageBefore(message, index)
	local value = index
	if index == nil then
		value = 1
	end
	if core.achievementsCompleted[value] == false then
		core:sendMessage(message .. " " .. GetAchievementLink(core.achievementIDs[value]) .. " Criteria has been met. Boss can now be killed!",true,"completed")
		core.achievementsCompleted[value] = true
	end
end

--Display the requirements completed message for achievements with message after
function core:getAchievementSuccessWithMessageAfter(message, index)
	local value = index
	if index == nil then
		value = 1
	end
	if core.achievementsCompleted[value] == false then
		core:sendMessage(GetAchievementLink(core.achievementIDs[value]) .. " Criteria has been met. Boss can now be killed! " .. message,true,"completed")
		core.achievementsCompleted[value] = true
	end
end

--Display the requirements completed message for achievements with message before and after
function core:getAchievementSuccessWithMessageBeforeAndAfter(messageBefore, messageAfter, index)
	local value = index
	if index == nil then
		value = 1
	end
	if core.achievementsCompleted[value] == false then
		core:sendMessage(messageBefore .. " " .. GetAchievementLink(core.achievementIDs[value]) .. " Criteria has been met. Boss can now be killed!" .. messageAfter,true,"completed")
		core.achievementsCompleted[value] = true
	end
end

--Display the requirements completed message for achievements with custom message
function core:getAchievementSuccessWithCustomMessage(messageBefore, messageAfter, index)
	local value = index
	if index == nil then
		value = 1
	end
	if core.achievementsCompleted[value] == false then
		core:sendMessage(messageBefore .. " " .. GetAchievementLink(core.achievementIDs[value]) .. " " .. messageAfter,true,"completed")
		core.achievementsCompleted[value] = true
	end
end

--Display the failed achievement message for personal achievements
function core:getAchievementSuccessPersonal(index, location)
	local value = index
	if index == nil then
		value = 1
	end
	if location == nil then
		location = "dest"
	end
	if location == "dest" then
		if core.playersSuccessPersonal[core.destName] == nil then
			--Players has not been hit already
			--Check if the player actually needs the achievement
			if core:has_value(core.currentBosses[value].players, core.destName) then
				--Player needs achievement but has failed it
				core:sendMessage(core.destName .. " has completed " .. GetAchievementLink(core.achievementIDs[value]) .. " (Personal Achievement)",true,"completed")
			end
			core.playersSuccessPersonal[core.destName] = true
		end
	elseif location == "source" then
		if core.playersSuccessPersonal[core.sourceName] == nil then
			--Players has not been hit already
			--Check if the player actually needs the achievement
			if core:has_value(core.currentBosses[value].players, core.sourceName) then
				--Player needs achievement but has failed it
				core:sendMessage(core.sourceName .. " has completed " .. GetAchievementLink(core.achievementIDs[value]) .. " (Personal Achievement)",true,"completed")
			end
			core.playersSuccessPersonal[core.sourceName] = true
		end	
	end
end

------------------------------------------------------
---- Tracking certain achievement objectives
------------------------------------------------------

function core:trackMob(mobID, mobName, threshold, message, interval, trackAchiev, id)
    --Add detected
    if core.sourceID == mobID and core.mobCounter <= threshold and core.thresholdAnnounced == false then
        if core.mobUID[core.spawn_uid] == nil and core.mobUID[core.spawn_uid] ~= "Dead" then
            core.mobUID[core.spawn_uid] = core.spawn_uid
            core.mobCounter = core.mobCounter + 1
			core:sendMessageDelay(mobName ..  " Counter (" .. core.mobCounter .. "/" .. threshold .. ")",core.mobCounter,interval)
			--core:sendDebugMessage(core.mobCounter)
        end
    end
    if core.destID == mobID and core.mobCounter <= threshold and core.thresholdAnnounced == false then
        if core.mobUID[core.spawn_uid_dest] == nil and core.mobUID[core.spawn_uid_dest] ~= "Dead" then
            core.mobUID[core.spawn_uid_dest] = core.spawn_uid_dest
            core.mobCounter = core.mobCounter + 1
			core:sendMessageDelay(mobName .. " Counter (" .. core.mobCounter .. "/" .. threshold ..")",core.mobCounter,interval)
			--core:sendDebugMessage(core.mobCounter)
        end
	end

	--Unit Died
	if core.type == "UNIT_DIED" and core.destID == mobID and core.mobCounter > 0 then
        core.mobUID[core.spawn_uid_dest] = "Dead"
		core.mobCounter = core.mobCounter - 1
		core:sendDebugMessage(core.mobCounter)
	end

	--Requirements Met
	if core.mobCounter >= threshold and core.thresholdAnnounced == false and trackAchiev == nil then
		core.thresholdAnnounced = true
		core:sendMessage(core:getAchievement() .. message)
	elseif core.mobCounter >= threshold and core.thresholdAnnounced == false and trackAchiev ~= nil then
		core:getAchievementSuccess(id)
	end
end

function core:trackAura(auraID, maxCount, type)
	core:detectGroupType()
	for i = 1, core.groupSize do
		local unit = nil
		if core.chatType == "PARTY" then
			if i < core.groupSize then
				unit = "party" .. i
			else
				unit = "player"
			end
		elseif core.chatType == "RAID" then
			unit = "raid" .. i
		elseif core.chatType == "SAY" then
			unit = "player"
		end

		local count = 0
        for i=1,40 do
			local _, _, count2, _, _, _, _, _, _, spellId = UnitDebuff(unit, i)
			if spellId == auraID then
				count = count2
            end
        end

		if count ~= nil then
			if count >= maxCount then
				return true
			end
		end
	end
end

------------------------------------------------------
---- Resetting variables between fights
------------------------------------------------------

--Clears global variables between fights such as the current boss/achievement being tracked
function core:clearVariables()
	------------------------------------------------------
	---- Reset Variables
	------------------------------------------------------
	core:sendDebugMessage("Resetting Global Variables")

	core.inCombat = false
	core.achievementsFailed = {}
	core.achievementsCompleted = {}
	core.achievementTrackedMessageShown = false
	core.foundBoss = false
	core.encounterDetected = false
	core.playersFailedPersonal = {}
	core.outputTrackingStatus = false
	lastMessageSent = nil

	core.mobCounter = 0
	core.mobUID = {}
	core.thresholdAnnounced = false
	core.displayAchievements = false

	core.currentBosses = {}
	core.achievementIDs = {}
	currentBossNums = {}

	currentBoss = nil

	--Addon Syncing variables
	masterAddon = false
	requestToRun = false
	electionFinished = false
	messageQueue = {}
	core.trackingSupressed = false
end

--Clears variables for the current instance the player is in
function core:clearInstanceVariables()
	--If a boss was pulled then clear the variables for that raid
	if core.instance ~= nil then
		--print(core.instanceClear)
		core:sendDebugMessage("Clearing Instance Variables if exists")
		local retOK, ret1 = pcall(function() core[core.instanceClear]:clearVariables() end);
		if (retOK) then
			core:sendDebugMessage("Clearing Instance Variables")
			core[core.instanceClear]:clearVariables()
		else
			core:sendDebugMessage("Function failed, error text: " .. ret1 .. ".")
		end
		core:sendDebugMessage("Clearing Instance Variables if exists")
		local retOK, ret1 = pcall(function() core[core.instanceClear]:ClearVariables() end);
		if (retOK) then
			core:sendDebugMessage("Clearing Instance Variables")
			core[core.instanceClear]:ClearVariables()
		else
			core:sendDebugMessage("Function failed, error text: " .. ret1 .. ".")
		end
	end


end

------------------------------------------------------
---- Utility Functions
------------------------------------------------------

--Check whether a table contains a certain value
function core:has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function core:has_value2(tab, val)
    for index, value in pairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function core:getHealthPercent(boss)
	return (UnitHealth(boss) / UnitHealthMax(boss)) * 100
end

function getKeysSortedByValue(tbl, sortFunction)
	local keys = {}
	for key in pairs(tbl) do
	  table.insert(keys, key)
	end
  
	table.sort(keys, function(a, b)
	  return sortFunction(tbl[a], tbl[b])
	end)
  
	return keys
  end

--Check if Blizzard Achievement Tracking has completed/failed
function core:getBlizzardTrackingStatus(achievementID, index)
	if index ~= nil then
		--Achievement has a criteria so we need to select that criteria to see if it has been completed/failed
		local _, _, _, _, _, _, _, _, _, _, eligible, _, _ = GetAchievementCriteriaInfo(achievementID, index);
		return eligible
	else
		--Achievement has no criteria so we can just check whether criteria has failed or completed
		return IsAchievementEligible(achievementID)
	end
end

function core:getPlayersInGroupForAchievement()
	local players = {}
    if core.groupSize > 1 then
        --We are in a group
        local currentUnit
        core:detectGroupType() --Detect the type of group the player is in so we can do the appropriate scanning
        for i = 1, core.groupSize do
            if core.chatType == "PARTY" then
                if i < core.groupSize then
                    currentUnit = "party" .. i
                else
                    currentUnit = "player"
                end
            elseif core.chatType == "RAID" then
                currentUnit = "raid" .. i
			end
			
			--Add to the current group so we can remove players that have left the group
			local name, realm = UnitName(currentUnit)
            if name ~= "Unknown" then
                table.insert(players, name)
            end
        end
    else
        currentUnit = "player"
        local name, realm = UnitName(currentUnit)
        if name ~= "Unknown" then
            table.insert(players, name)
        end
	end
	return players
end

function core:getTableIndexByValue(tab,el)
	for index, value in pairs(tab) do
		if value == el then
			return index
		end
	end
end
	