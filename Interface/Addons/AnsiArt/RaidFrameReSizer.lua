--This is how you make the raid frames even more resizable :)
local n,w,h="CompactUnitFrameProfilesGeneralOptionsFrame" h,w=
_G[n.."HeightSlider"],
_G[n.."WidthSlider"] 
h:SetMinMaxValues(1,150) 
w:SetMinMaxValues(1,150)