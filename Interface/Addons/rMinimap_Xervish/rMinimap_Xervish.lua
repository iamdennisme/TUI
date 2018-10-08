-- Sorry Zork! You hate it, but I need it because I have alts :(
-- On the flip side, your code has helped me learn quite a bit :)

-- Variables:
local lasttime = 0

-- Showing:
local function rMinimap_Xervish_Show()
  GarrisonLandingPageMinimapButton:SetAlpha(0.9)
end

-- Hiding function, taken from rMinimap:
local function rMinimap_Xervish_Hide()
  if Minimap:IsMouseOver() then return end
  if time() == lasttime then return end

  GarrisonLandingPageMinimapButton:SetAlpha(0)
end

local function rMinimap_Xervish_SetTimer()
  lasttime = time()
  C_Timer.After(1.5, rMinimap_Xervish_Hide)
end

local function rMinimap_Xervish_Adjust()
  GarrisonLandingPageMinimapButton:SetParent(Minimap)
  GarrisonLandingPageMinimapButton:SetScale(0.75)
  GarrisonLandingPageMinimapButton:ClearAllPoints()
  GarrisonLandingPageMinimapButton:SetPoint("BOTTOM",Minimap,1,30)
end

-- Register Minimap Events
-- HookScript preserves the original events in rMinimap
Minimap:HookScript("OnEnter", rMinimap_Xervish_Show)
Minimap:HookScript("OnLeave", rMinimap_Xervish_SetTimer)

-- Register Callbacks:
rLib:RegisterCallback("PLAYER_ENTERING_WORLD", rMinimap_Xervish_Adjust)
rLib:RegisterCallback("PLAYER_ENTERING_WORLD", rMinimap_Xervish_Hide)
