
------------------------------------------
-- 双击小地图顶部发送坐标
------------------------------------------
MinimapZoneTextButton:HookScript("OnDoubleClick", function(self)
    ChatEdit_ActivateChat(ChatEdit_ChooseBoxForSend())
    ChatEdit_InsertLink(MinimapZoneText:GetText())
    local position = C_Map.GetPlayerMapPosition(MapUtil.GetDisplayableMapForPlayer(), "player")
    if (position) then
        ChatEdit_InsertLink(format(" X:%.1f Y:%.1f", position.x*100, position.y*100))
    end
end)

-------------------------------------
-- 地圖縮小,隱藏放大縮小按鈕並支持滾輪
-------------------------------------

MinimapCluster:SetScale(0.85)
MinimapZoomIn:Hide()
MinimapZoomOut:Hide()
--MiniMapTracking:Hide()
Minimap:EnableMouseWheel(true)
Minimap:HookScript("OnMouseWheel", function(self, zoom)
    if (zoom > 0) then Minimap_ZoomIn()
    else Minimap_ZoomOut() end
end)

-------------------------------------
-- 大地圖顯示玩家坐標,鼠標坐標
-------------------------------------

WorldMapFrame.playerPos = WorldMapFrame.BorderFrame:CreateFontString(nil, 'ARTWORK')
WorldMapFrame.playerPos:SetFont(GameFontNormal:GetFont(), 12, 'THINOUTLINE')
WorldMapFrame.playerPos:SetJustifyH('RIGHT')
WorldMapFrame.playerPos:SetPoint('RIGHT', WorldMapFrameCloseButton, 'LEFT', -40, 0)
WorldMapFrame.playerPos:SetTextColor(1, 0.82, 0.1)
WorldMapFrame.mousePos = WorldMapFrame.BorderFrame:CreateFontString(nil, 'ARTWORK')
WorldMapFrame.mousePos:SetFont(GameFontNormal:GetFont(), 12, 'THINOUTLINE')
WorldMapFrame.mousePos:SetJustifyH('RIGHT')
WorldMapFrame.mousePos:SetPoint('RIGHT', WorldMapFrameCloseButton, 'LEFT', -120, 0)
WorldMapFrame:HookScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if (self.elapsed < 0.2) then return end
    self.elapsed = 0
    --玩家坐标
    local position = C_Map.GetPlayerMapPosition(MapUtil.GetDisplayableMapForPlayer(), "player")
    if (position) then
        self.playerPos:SetText(format("X:%.1f  Y:%.1f", position.x*100, position.y*100))
    else
        self.playerPos:SetText("")
    end
    --鼠标坐标
    local mapInfo = C_Map.GetMapInfo(self:GetMapID())
    if (mapInfo and mapInfo.mapType == 3) then
        local x, y = self.ScrollContainer:GetNormalizedCursorPosition()
        if (x and y and x > 0 and x < 1 and y > 0 and y < 1) then
            self.mousePos:SetText(format("X:%.1f  Y:%.1f", x*100, y*100))
        else
            self.mousePos:SetText("")
        end
    else
        self.mousePos:SetText("")
    end
end)
