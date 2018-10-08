--all credits: 上官曉霧
--http://bbs.nga.cn/read.php?tid=9727518

--顯示當前裝等與最高裝等
hooksecurefunc('PaperDollFrame_SetItemLevel', function(self, unit) 
	if (unit ~= 'player') then return end 

	local total, equip = GetAverageItemLevel() 
	if (total > 0) then total = string.format('%.1f', total) end 
	if (equip > 0) then equip = string.format('%.1f', equip) end 

	local ilvl = equip 
	if (equip < total) then 
		ilvl = equip .. ' / ' .. total 
	end 

	-- local ilvlLine = _G[self:GetName() .. 'StatText'] 
	CharacterStatsPane.ItemLevelFrame.Value:SetText(ilvl) 

	self.tooltip =  "|cffffffff".. STAT_AVERAGE_ITEM_LEVEL .. ' ' .. ilvl 
end) 

--顯示屬性數值小數點
local t={ 
	[STAT_CRITICAL_STRIKE]=true,
	[STAT_MASTERY]=true, 
	[STAT_HASTE]=true, 
	[STAT_VERSATILITY]=true, 
	[STAT_LIFESTEAL]=true, 
	[STAT_AVOIDANCE]=true, 
	[STAT_DODGE]=true, 
	[STAT_BLOCK]=true, 
	[STAT_PARRY]=true, } 
	
function PaperDollFrame_SetLabelAndText(statFrame, label, text, isPercentage, numericValue) 
	if ( statFrame.Label ) then
		statFrame.Label:SetText(format(STAT_FORMAT, label)); 
	end 
	 
	if ( isPercentage ) then 
		text = format("%d%%", numericValue + 0.5); 
	end 
	if(t[label]) then 
		text = format("%.2F%%", numericValue) 
	end 
	
	statFrame.Value:SetText(text); 
	statFrame.numericValue = numericValue; 
end

--顯示詳細的人物屬性
do
	PAPERDOLL_STATCATEGORIES= { 
		[1] = { 
			categoryFrame = "AttributesCategory", 
			stats = { 
				[1] = { stat = "ATTACK_DAMAGE" }, 
				[2] = { stat = "STRENGTH", primary = LE_UNIT_STAT_STRENGTH }, 
				[3] = { stat = "AGILITY", primary = LE_UNIT_STAT_AGILITY }, 
				[4] = { stat = "INTELLECT", primary = LE_UNIT_STAT_INTELLECT }, 
				[5] = { stat = "STAMINA" }, 
				[6] = { stat = "ARMOR" }, 
				[7] = { stat = "ENERGY_REGEN", hideAt = 0 }, 
				[8] = { stat = "RUNE_REGEN", hideAt = 0 }, 
				[9] = { stat = "FOCUS_REGEN", hideAt = 0 }, 
				[10] = { stat = "MANAREGEN", roles =  { "HEALER" } }, 
			}, 
		}, 
		[2] = { 
			categoryFrame = "EnhancementsCategory", 
			stats = { 
				[1] = { stat = "CRITCHANCE", hideAt = 0 }, 
				[2] = { stat = "HASTE", hideAt = 0 }, 
				[3] = { stat = "MASTERY", hideAt = 0 }, 
				[4] = { stat = "VERSATILITY", hideAt = 0 }, 
				[5] = { stat = "LIFESTEAL", hideAt = 0 }, 
				[6] = { stat = "AVOIDANCE", hideAt = 0 }, 
				[7] = { stat = "DODGE", roles =  { "TANK" } }, 
				[8] = { stat = "PARRY", hideAt = 0, roles =  { "TANK" } }, 
				[9] = { stat = "BLOCK", hideAt = 0, roles =  { "TANK" } }, 
			}, 
		}, 
	}; 
	
--若獲取不到能量值，就設為0，套用hideAt
	PAPERDOLL_STATINFO["ENERGY_REGEN"].updateFunc = function(statFrame, unit) statFrame.numericValue=0; PaperDollFrame_SetEnergyRegen(statFrame, unit); end 
	
	PAPERDOLL_STATINFO["RUNE_REGEN"].updateFunc = function(statFrame, unit) statFrame.numericValue=0; PaperDollFrame_SetRuneRegen(statFrame, unit); end 
	
	PAPERDOLL_STATINFO["FOCUS_REGEN"].updateFunc = function(statFrame, unit) statFrame.numericValue=0; PaperDollFrame_SetFocusRegen(statFrame, unit); end 
	
--移動速度
	PAPERDOLL_STATINFO["MOVESPEED"].updateFunc =  function(statFrame, unit) PaperDollFrame_SetMovementSpeed(statFrame, unit); end 
	
--根據職業增加顯示的屬性
	local _,_,classid = UnitClass("player") 
	if (classid==1)then --戰士 

	elseif (classid==2)then --聖騎士
	
	elseif (classid==3)then --獵人

	elseif (classid==4)then --盜賊 

	elseif (classid==5)then --牧師 
		PAPERDOLL_STATCATEGORIES[1].stats[1].roles={}	--隱藏傷害 
	elseif (classid==6)then --死騎

	elseif (classid==7)then --薩滿 
	
	elseif (classid==8)then --法師，回魔
		PAPERDOLL_STATCATEGORIES[1].stats[1].roles={} 
		table.insert(PAPERDOLL_STATCATEGORIES[1].stats,{ stat = "MANAREGEN" }) 
	elseif (classid==9)then --術士
		PAPERDOLL_STATCATEGORIES[1].stats[1].roles={}	--隱藏傷害 
	elseif (classid==10)then --武僧 

	elseif (classid==11)then --德魯伊 

	elseif (classid==12)then --DH 

	end 
	
--顯示移動速度
	table.insert(PAPERDOLL_STATCATEGORIES[1].stats,{ stat = "MOVESPEED" }) 
	
	local tempstatFrame 
	hooksecurefunc("PaperDollFrame_SetMovementSpeed",function(statFrame, unit) 
		if(tempstatFrame and tempstatFrame~=statFrame)then 
		  tempstatFrame:SetScript("OnUpdate",nil); 
		end 
		statFrame:SetScript("OnUpdate", MovementSpeed_OnUpdate); 
		tempstatFrame = statFrame; 
		statFrame:Show(); 
	end) 
end
