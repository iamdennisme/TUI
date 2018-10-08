-- Author: Nerino1
-- Create Date : 9/25/2018
-- Version 1.0

local f=CreateFrame("frame");
f:RegisterEvent("PLAYER_LOGIN");
f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
f:RegisterEvent("QUEST_COMPLETE");
f:RegisterEvent("QUEST_FINISHED");
f:RegisterEvent('QUEST_ACCEPTED')
f:RegisterEvent('QUEST_REMOVED')
f:RegisterEvent('PLAYER_ENTERING_WORLD')

local lohimage = CreateFrame("frame","lohimageFrame")
lohimage:SetBackdrop({
      bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", 
      tile=1, tileSize=256, edgeSize=32, 
      insets={left=11, right=12, top=12, bottom=11}
})
lohimage:SetWidth(256)
lohimage:SetHeight(256)
lohimage:SetPoint("CENTER",UIParent)
lohimage:EnableMouse(true)
lohimage:SetMovable(true)
lohimage:RegisterForDrag("LeftButton")
lohimage:SetScript("OnDragStart", function(self) self:StartMoving() end)
lohimage:SetScript("OnDragStart", function(self) self:StartMoving() end)
lohimage:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
lohimage:SetFrameStrata("FULLSCREEN_DIALOG")

local t= lohimage:CreateTexture(nil, "HIGH")
t:SetAllPoints(lohimage)
lohimage.texture = t


local LohQuests = {
		[51632]=true,
		[51633]=true,
		[51635]=true,
		[51636]=true,
	}

f:SetScript("OnEvent",function(self,event,arg1,arg2)
	if event == 'QUEST_ACCEPTED' then
		if arg2 and LohQuests[arg2] then
			self:RegisterEvent('UNIT_ENTERED_VEHICLE')
			self:RegisterEvent('UNIT_EXITED_VEHICLE')
			i=arg2
			--print(i)
		end
	elseif event == 'QUEST_REMOVED' then
		if arg1 and LohQuests[arg1] then
			lohimageFrame:Hide()
			self:UnregisterEvent('UNIT_ENTERED_VEHICLE')
			self:UnregisterEvent('UNIT_EXITED_VEHICLE')
		end
	elseif event == 'UNIT_ENTERED_VEHICLE' then
		if arg1 ~= "player" then
			--print(i)
			return	 
		end
		--print(i)
		if i == 51632 then
			DEFAULT_CHAT_FRAME:AddMessage("Make Loh Go! - 32122, 12322, 3223, 222123, 21212, 21232, 232");
			t:SetTexture("Interface\\AddOns\\Loh\\51632.blp")
			lohimageFrame:Show()
		elseif i == 51635 then
			DEFAULT_CHAT_FRAME:AddMessage("Make Loh Go! - 22223, 23222, 21212, 32121, 23223, 23212, 12");
			t:SetTexture("Interface\\AddOns\\Loh\\51635.blp")
			lohimageFrame:Show()
		elseif i == 51636 then
			DEFAULT_CHAT_FRAME:AddMessage("Make Loh Go! - 232223, 21212222, 122221, 221222");
			t:SetTexture("Interface\\AddOns\\Loh\\51636.blp")
			lohimageFrame:Show()
		elseif i == 51633 then
			DEFAULT_CHAT_FRAME:AddMessage("Make Loh Go! - 32122, 12322, 323212, 322212, 2122, 12322, 32");
			t:SetTexture("Interface\\AddOns\\Loh\\51633.blp")
			lohimageFrame:Show()
		end
	elseif event == 'UNIT_EXITED_VEHICLE' then
		if arg1 ~= "player" then
			return
		end
		lohimageFrame:Hide()
	elseif event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		lohimageFrame:Hide()
		for i=1,GetNumQuestLogEntries() do
			local title, _, _, _, _, _, _, questID = GetQuestLogTitle(i)
			if questID and LohQuests[questID] then
				return self:GetScript("OnEvent")(self,'QUEST_ACCEPTED',i,questID)
			end
		end
	end
end)



	
