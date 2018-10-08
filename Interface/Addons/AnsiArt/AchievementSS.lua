local delay = 1
local time = 0
local frame = CreateFrame("Frame")
frame:Hide()
frame:RegisterEvent("ACHIEVEMENT_EARNED")

frame:SetScript("OnUpdate", function(self, elapsed)
   time = time + elapsed
   if time >= delay then
     Screenshot()
     time = 0
     self:Hide()
   end
end)

frame:SetScript("OnEvent", function(self, event, ...)
   self:Show()
end)

