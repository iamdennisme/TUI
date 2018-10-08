local a=...
local nQ=CreateFrame('frame',a)
local MAX_QUESTS=MAX_QUESTS
local TRACKER_HEADER_QUESTS=TRACKER_HEADER_QUESTS
local OBJECTIVES_TRACKER_LABEL=OBJECTIVES_TRACKER_LABEL
local MAP_AND_QUEST_LOG=MAP_AND_QUEST_LOG
nQ:RegisterEvent('QUEST_LOG_UPDATE')
nQ:SetScript('OnEvent',function()
	local numQuests=tostring(select(2,GetNumQuestLogEntries()))
	local Quests=numQuests.."/"..MAX_QUESTS.." "..TRACKER_HEADER_QUESTS
	local Objectives=numQuests.."/"..MAX_QUESTS.." "..OBJECTIVES_TRACKER_LABEL
	local WorldMap=MAP_AND_QUEST_LOG.." ("..numQuests.."/"..MAX_QUESTS..")"

--  ======== DO NOT EDIT ANYTHING ABOVE THIS LINE ========
--	THE FOLLOWING THREE LINES REPRESENT THE THREE PLACES THIS ADDON EDITS
--	TYPE TWO DASHES AT THE BEGINNING OF THE LINE YOU WANT TO DISABLE
--	EXACTLY LIKE THE DASHES AT THE BEGINNING OF THESE THREE LINES

	ObjectiveTrackerBlocksFrame.QuestHeader.Text:SetText(Quests) -- edits the "Quests" tracker header

	ObjectiveTrackerFrame.HeaderMenu.Title:SetText(Objectives) -- edits the "Objectives" text when the tracker is minimized

	WorldMapFrame.BorderFrame.TitleText:SetText(WorldMap) -- edits the title at the top of the world map frame

--  ======== DO NOT EDIT ANYTHING BELOW THIS LINE ========

end) -- seriously, do not delete this line, it is very important
-- it's probably the most important "end)" you have ever seen