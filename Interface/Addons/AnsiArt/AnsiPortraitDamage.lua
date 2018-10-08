local txt=TargetFrameTextureFrame:CreateFontString("TargetHitIndicator","OVERLAY","NumberFontNormalHuge");
txt:SetPoint("CENTER",TargetFrameTextureFrame,"TOPRIGHT",-73,-42);
txt:Hide();
CombatFeedback_Initialize(TargetFrame,txt,30);
 
TargetFrame:RegisterUnitEvent("UNIT_COMBAT","target");
TargetFrame:HookScript("OnEvent",function(self,event,unit,...)
    if event=="UNIT_COMBAT" then CombatFeedback_OnCombatEvent(self,...); end
end);
 
TargetFrame:HookScript("OnUpdate",CombatFeedback_OnUpdate);