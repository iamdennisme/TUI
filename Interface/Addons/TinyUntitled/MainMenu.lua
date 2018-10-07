
local locale = GetLocale()

--自定義菜單 (BLIZ保護機制,inherits表示原按鈕)
local menus = {
    { zhTW = "角色", zhCN = "角色", text = "Player", inherits = CharacterMicroButton },
    { zhTW = "法術", zhCN = "法术", text = "Spell", inherits = SpellbookMicroButton },
    { zhTW = "天賦", zhCN = "天赋", text = "Talent", inherits = TalentMicroButton },
    { zhTW = "成就", zhCN = "成就", text = "Achi", inherits = AchievementMicroButton },
    { zhTW = "任務", zhCN = "任务", text = "Quest", inherits = QuestLogMicroButton },
    { zhTW = "公會", zhCN = "公会", text = "Guild", inherits = GuildMicroButton },
    { zhTW = "找團", zhCN = "找团", text = "LFD", inherits = LFDMicroButton, r=0, g=1, b=0.82 },
    { zhTW = "收藏", zhCN = "收藏", text = "Collects", inherits = CollectionsMicroButton },
    { zhTW = "指南", zhCN = "指南", text = "Guide", inherits = EJMicroButton },
    { zhTW = "商城", zhCN = "商城", text = "Shop", inherits = StoreMicroButton },
    { zhTW = "菜單", zhCN = "菜单", text = "Menu", inherits = MainMenuMicroButton },
    { zhTW = "背包", zhCN = "背包", text = "Bag", func = ToggleAllBags },
    --{ zhTW = "幫助", zhCN = "帮助", text = "Help", inherits = HelpMicroButton },
}

--按钮宽度
local buttonWidth = 36

--按鈕字體大小
local buttonFontSize = locale:sub(1,2) == "zh" and 12 or 9

--按鈕點擊
local function click(self)
    if (self.func) then self.func(self) end
end

--創建按鈕
local function CreateButton(prefix, index, config)
    local button
    if (config.inherits) then
        button = CreateFrame("Frame", prefix..index, _G["MenuMainFrame"] or UIParent)
        button:SetHeight(20)
        button:SetWidth(config.width or buttonWidth)
        config.inherits:SetParent(button)
        config.inherits:ClearAllPoints()
        config.inherits:SetHitRectInsets(0,0,0,0)
        config.inherits:SetWidth(button:GetWidth())
        config.inherits:SetHeight(button:GetHeight())
        config.inherits:SetPoint("CENTER")
        config.inherits:SetAlpha(0)
        hooksecurefunc(config.inherits, "Enable", function(self) self:SetAlpha(0) end)
    else
        button = CreateFrame("Button", prefix..index, _G["MenuMainFrame"] or UIParent)
        button:SetHeight(20)
        button:SetWidth(config.width or buttonWidth)
        button.func = config.func
        button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        button:RegisterForClicks("LeftButtonUp")
        button:SetScript("OnClick", click)
    end
    button:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    button:SetBackdropColor(0, 0, 0, 0.3)
    button:SetBackdropBorderColor(1, 0.8, 0.2, 0.4)
    if (index == 1) then
        button:SetPoint("LEFT", _G["MenuMainFrame"] or UIParent, "LEFT", 0, 0)
    else
        button:SetPoint("LEFT", _G[prefix..(index-1)], "RIGHT", 1, 0)
    end
    button.text = button:CreateFontString(nil, "ARTWORK")
    button.text:SetWidth(button:GetWidth())
    button.text:SetFont(UNIT_NAME_FONT, buttonFontSize, "THINOUTLINE")
    if (config.r and config.g and config.b) then
        button.text:SetTextColor(config.r, config.g, config.b)
    else
        button.text:SetTextColor(1, 0.82, 0)
    end
    button.text:SetPoint("CENTER", button, "CENTER", 1, 0)
    button.text:SetJustifyH("CENTER")
    button.text:SetText(config[locale] or config.text)
    return button
end

do
    --創建菜單框架
    local MenuMainFrame = CreateFrame("Frame", "MenuMainFrame", UIParent)
    MenuMainFrame:SetSize(#menus*(buttonWidth+1), 20)
    MenuMainFrame:SetPoint("CENTER", UIParent, "CENTER", -12, 12)
    for i, v in ipairs(menus) do CreateButton("MenuMainFrameButton", i, v) end
    --創建菜單控制按鈕
    local MenuMainButton = CreateFrame("Button", "MenuMainButton", UIParent)
    MenuMainButton:SetWidth(18)
    MenuMainButton:SetHeight(18)
    MenuMainButton:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    MenuMainButton:SetBackdropColor(0, 0, 0, 0.8)
    MenuMainButton:SetBackdropBorderColor(1, 1, 1, 0.9)
    MenuMainButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    MenuMainButton:SetPoint("TOP", UIParent, "TOP", #menus*buttonWidth/2+20, -2)
    MenuMainButton:SetMovable(true)
    MenuMainButton:SetClampedToScreen(true)
    MenuMainButton:SetFrameStrata("HIGH")
    MenuMainButton:RegisterForDrag("LeftButton", "RightButton")
    MenuMainButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    MenuMainButton:SetScript("OnDragStart", function(self) self:StartMoving() end)
    MenuMainButton:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    MenuMainButton:SetScript("OnClick", function() ToggleFrame(MenuMainFrame) end)
    MenuMainButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    MenuMainButton:SetScript("OnEnter", function(self)
        local _, _, latencyHome, latencyWorld = GetNetStats()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(format(MAINMENUBAR_LATENCY_LABEL, latencyHome, latencyWorld))
        local totalMem, addons, mem = 0, {}, 0
        UpdateAddOnMemoryUsage()
        for i = 1, GetNumAddOns() do
            mem = GetAddOnMemoryUsage(i)
            totalMem = totalMem + mem
            addons[i] = { name = GetAddOnInfo(i), mem = mem }
        end
        if (totalMem > 0) then
            GameTooltip:AddLine(" ")
            if (totalMem > 1000) then
                GameTooltip:AddLine(format(TOTAL_MEM_MB_ABBR, totalMem/1000))
            else
                GameTooltip:AddLine(format(TOTAL_MEM_KB_ABBR, totalMem))
            end
            for _, v in pairs(addons) do
                if (v.mem > 1000) then
                    GameTooltip:AddLine(format(ADDON_MEM_MB_ABBR, v.mem/1000, v.name),1,1,1)
                elseif (v.mem > 0) then
                    GameTooltip:AddLine(format(ADDON_MEM_KB_ABBR, v.mem, v.name),1,1,1)
                end
            end
        end
        GameTooltip:Show()
    end)
    MenuMainButton:SetScript("OnUpdate", function(self, elapsed)
        self.timer = (self.timer or 0) + elapsed
        if (self.timer > 5) then
            local _, _, latencyHome, latencyWorld = GetNetStats()
            if (latencyHome < 100 and latencyWorld < 100) then
                self:SetBackdropColor(0, 1, 0, 0.2)
                self.icon:SetVertexColor(0, 1, 0)
            elseif (latencyHome < 600 and latencyWorld < 600) then
                self:SetBackdropColor(0.8, 0.6, 0.2, 0.2)
                self.icon:SetVertexColor(0.8, 0.6, 0.2)
            else
                self:SetBackdropColor(1, 0, 0, 0.2)
                self.icon:SetVertexColor(1, 0, 0)
            end
            self.timer = 0
        end
    end)
    MenuMainButton.icon = MenuMainButton:CreateTexture(nil, "ARTWORK")
	MenuMainButton.icon:SetTexture("Interface\\Buttons\\UI-OptionsButton")
	MenuMainButton.icon:SetWidth(10)
	MenuMainButton.icon:SetHeight(10)
	MenuMainButton.icon:SetPoint("CENTER")
    if (#menus == 0) then MenuMainButton:Hide() end
    --重設位置
    MenuMainFrame:ClearAllPoints()
    MenuMainFrame:SetParent(MenuMainButton)
    MenuMainFrame:SetPoint("TOPRIGHT", MenuMainButton, "TOPLEFT", -2, 0)
    --隐藏右下背包和菜单
    MicroButtonAndBagsBar:Hide()
    --下载具后需要重新设置角色按钮
    hooksecurefunc("PlayerFrame_OnEvent", function(self, event, arg1, ...)
        if (event == "UNIT_EXITED_VEHICLE" and arg1 == "player") then
            if (_G["MenuMainFrameButton1"]) then
                C_Timer.After(2, function()
                    CharacterMicroButton:SetParent(_G["MenuMainFrameButton1"])
                    CharacterMicroButton:ClearAllPoints()
                    CharacterMicroButton:SetPoint("CENTER")
                end)
            end
        end
    end)
end
