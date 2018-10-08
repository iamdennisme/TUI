local QuickMenuFrame = nil
local QuickMenuButtons = {}
local QuickMenuTextures = {}
local QuickMenuVisible = false

local function HideQuickMenu()
	QuickMenuFrame:Hide()
	QuickMenuVisible = false
end

function TeleQuickMenu_OnHide()
	QuickMenuVisible = false
end

function TeleQuickMenuOnClick(frame,button)
	if button == "RightButton" then
		QuickMenuFrame:Hide()
	end
end

function TeleToggleQuickMenu(favourites, size)
	if not QuickMenuFrame then
		QuickMenuFrame = TeleporterQuickMenuFrame
		QuickMenuFrame:SetFrameStrata("HIGH")
		tinsert(UISpecialFrames,TeleporterQuickMenuFrame:GetName());
		
		QuickMenuFrame:SetBackdropColor(1, 1, 1, 1);	
	end
	
	if QuickMenuVisible then
		HideQuickMenu()
	else
		local favCount = 0
		for spellId, isItem in pairs(favourites) do
			favCount = favCount + 1
		end
		
		local x, y = GetCursorPosition()
		QuickMenuFrame:SetPoint("TOPLEFT", nil, "BOTTOMLEFT", x - size, y)
		QuickMenuFrame:SetPoint("BOTTOMRIGHT", nil, "BOTTOMLEFT", x, y - size * favCount)
		

	
		for i = #QuickMenuButtons + 1, favCount do
			QuickMenuButtons[i] = CreateFrame( "Button", "TeleporterQuickMenuFrame"..i, QuickMenuFrame,"SecureActionButtonTemplate")
			QuickMenuButtons[i]:SetWidth(size)
			QuickMenuButtons[i]:SetHeight(size)
			QuickMenuButtons[i]:SetPoint("TOPLEFT",QuickMenuFrame,"TOPLEFT",0,-size*(i-1))
			QuickMenuButtons[i]:SetPoint("BOTTOMRIGHT",QuickMenuFrame,"TOPLEFT",size,-size*i)
			QuickMenuButtons[i]:SetAttribute("type", "macro")
			
			QuickMenuTextures[i] = QuickMenuButtons[i]:CreateTexture()
			QuickMenuTextures[i]:SetAllPoints(QuickMenuButtons[i])
			
			QuickMenuButtons[i]:SetScript(
				"OnLeave",
				function()
					GameTooltip:Hide()
				end )
		end
		
		local index = 1
		for i, spell in pairs(favourites) do
			local button = QuickMenuButtons[index]
			
			local isItem = spell.isItem
			local spellId = spell.spellId
			
			local texture
			local name
			
			if isItem then
				name, _, _, _, _, _, _, _, _, texture = GetItemInfo( spellId )
			
				button:SetScript(
					"OnEnter",
					function()
						TeleporterShowItemTooltip( name, button )
					end )
				
				if PlayerHasToy(spellId) then			
					button:SetAttribute(
						"macrotext1",
						"/teleportercastspell " .. GetItemSpell(spellId) .. "\n" ..
						"/cast " .. name .. "\n" )
				else
					button:SetAttribute(
						"macrotext1",
						"/teleporteruseitem " .. name .. "\n" ..
						"/use " .. name .. "\n" )
				end
			else				
				name,_,texture = GetSpellInfo( spellId )				
				
				button:SetScript(
					"OnEnter",
					function()
						TeleporterShowSpellTooltip( name, button )
					end )
					
				button:SetAttribute(
					"macrotext1",
					"/teleportercastspell " .. name .. "\n" ..
					"/cast " .. name .. "\n" )
			end
								
			QuickMenuTextures[index]:SetTexture(texture)
			
			QuickMenuButtons[index]:Show()
			
			QuickMenuButtons[index]:SetScript("OnMouseUp", TeleQuickMenuOnClick)
			
			index = index + 1
		end
		
		while index <= #QuickMenuButtons do
			QuickMenuButtons[index]:Hide()
			index = index + 1
		end
	
		QuickMenuFrame:Show()
		QuickMenuVisible = true
	end
end
