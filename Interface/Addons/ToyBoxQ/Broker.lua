local ToyBoxQ = LibStub("AceAddon-3.0"):GetAddon("ToyBoxQ");

ToyBoxQ.LDB = ToyBoxQ:NewModule("LDB");

local ToyTimer = LibStub("AceTimer-3.0");

local ldb = LibStub:GetLibrary("LibDataBroker-1.1");
local LibQTip = LibStub("LibQTip-1.0");
local LibIcon = LibStub("LibDBIcon-1.0");
local appName = ...
local TBQ = ToyBoxQ.TBQ;

local TBQicon = "Interface\\Icons\\INV_Misc_Toy_10"

TBQ.IconFormat = "|T%s:20:20|t"
TBQ.TimerIsScheduled = false;

TBQ.VIEW_ALL = 1;
TBQ.VIEW_TRANSFORM = 2;
TBQ.VIEW_OTHER = 3;
local ViewMsgs = { "All", "Transform", "Non Transform" };

TBQ.ShownToys = {};

BINDING_HEADER_TOYBOXQ = "ToyBoxQ";
_G[ "BINDING_NAME_CLICK ToyBoxQBtn:LeftButton" ] = "Use Random Toy"
_G[ "BINDING_NAME_CLICK ToyBoxQTrans:LeftButton" ] = "Use Random Transformation"

function ToyBoxQ.LDB:OnInitialize()
	TBQ.broker = ldb:NewDataObject("ToyBoxQ", {
		type = "data source",
		icon = TBQicon,
		label = "ToyBoxQ",
		text = "ToyBoxQ",
		OnEnter = function(self, button) ToyBoxQ.LDB:OnEnter(self, button) end,
	});

	LibIcon:Register(appName, TBQ.broker, TBQ.db.global.minimap);
end

function ToyBoxQ.LDB:ChangeIcon(val)
	if val then
		LibIcon:Show(appName)
	else
		LibIcon:Hide(appName)
	end
end


local TBQ_Button;
function SecureTooltipEnter(self, toy)
	TBQ_Button = self;
	if InCombatLockdown() then return end
	
	ToyBoxQMenu:SetScript("OnEnter", function(self)
		if TBQ_Button then TBQ_Button:GetScript("OnEnter")(self); end
	end);
	ToyBoxQMenu:SetScript("OnLeave", function(self)
		if TBQ_Button then TBQ_Button:GetScript("OnLeave")(self); end
		ToyBoxQMenu:Hide();
	end)	
	self:SetScript("OnHide", function()
		ToyBoxQMenu:Hide();
	end)
	ToyBoxQMenu:SetScript('PreClick', function (_, btn) 
		if toy == nil then
			ToyBoxQ.LDB:MenuViewSwap()
		else
			ToyBoxQ.LDB:SecurePreClick(btn, ToyBoxQMenu, toy)
		end
	end);
	ToyBoxQMenu:SetScript('PostClick', function (_, btn) 
		ToyBoxQ.LDB:SecurePostClick(ToyBoxQMenu)
	end)
	ToyBoxQMenu:SetFrameStrata(self:GetFrameStrata())
	ToyBoxQMenu:SetFrameLevel(self:GetFrameLevel()+1)
	ToyBoxQMenu:SetAllPoints(self)
	ToyBoxQMenu:Show()
end

function TBQ_CooldownTime(toy)
	local startTime, duration, enable = GetItemCooldown(toy:GetID());
	if enable == 1 and duration > 0 then
		local cooldown = duration - (GetTime() - startTime);
		if cooldown >= 60 then
			cooldown = math.floor(cooldown / 60);
			if cooldown >= 60 then
				cooldown = math.floor(cooldown / 60);
				cooldown = cooldown.."h";
			else
				cooldown = cooldown.."m";
			end
		elseif cooldown > 0 and cooldown < 60 then
			cooldown = math.floor(cooldown).."s";
		end
		return "|cffffff00"..cooldown.."|r";
	end
	return nil
end

local function SortToys(a, b)
	local toyA = ToyBoxQ.ToyDB:GetToy(a);
	local toyB = ToyBoxQ.ToyDB:GetToy(b);

	if toyA:GetName() < toyB:GetName() then
		return 1;
	else
		return nil;
	end
end

function ToyBoxQ.LDB:UpdateShownToys(viewtype, offcooldown)
	TBQ.ShownToys = {};
	
	for i, j in pairs(TBQ.db.char.ToyBoxQList) do
		local toy = ToyBoxQ.ToyDB:GetToy(i);
		local cat, catlist;
		local filter_check = false;

		if toy == nil then 
			filter_check = false;
		elseif viewtype == TBQ.VIEW_ALL then
			filter_check = true;
		elseif viewtype == TBQ.VIEW_TRANSFORM then
			catlist = toy:GetCategories();
			for _,cat in pairs(catlist) do
				if cat == TBQ.TRANSFORM_MOVE or cat == TBQ.TRANSFORM_MOUNT then
					filter_check = true;
				end
			end
		else
			filter_check = true;
			catlist = toy:GetCategories();
			for _,cat in pairs(catlist) do
				if cat == TBQ.TRANSFORM_MOVE or cat == TBQ.TRANSFORM_MOUNT then
					filter_check = false;
				end
			end
		end

		if toy ~= nil then
			if toy:GetName() == nil then 
				filter_check = false;
			end
			if not toy:FactionCheck() then
				filter_check = false;
			end
			if not toy:CanUse() then
				filter_check = false;
			end
		end
		if filter_check == true then
			if offcooldown == true then
				local startTime, duration, enable = GetItemCooldown(i);
				if enable ~= 1 or duration == 0 then
					table.insert(TBQ.ShownToys, i);
				end
			else
				table.insert(TBQ.ShownToys, i);
			end
		end
	end
	table.sort(TBQ.ShownToys, SortToys);

end

function ToyBoxQ.LDB:SecurePreClick(btn, secure, toy, view)
	if btn == "RightButton" then
		ToyBoxQ:UIOpen();
		return;
	end

	if toy == nil then
		if view == nil then view = TBQ.db.global.BrokerView end
		ToyBoxQ.LDB:UpdateShownToys(view, true);
		if #TBQ.ShownToys == 0 then
			ToyBoxQ:Print("No toys on list are off cooldown.");
			return;
		end
		local rnd = fastrandom(#TBQ.ShownToys);
		toy = ToyBoxQ.ToyDB:GetToy(TBQ.ShownToys[rnd]);
	end

	local cooldown = TBQ_CooldownTime(toy);
	if cooldown ~= nil then
		ToyBoxQ:Print(toy:GetName(), "is on cooldown for", cooldown..".");
		return;
	end

	ToyBoxQ:Print("Using", toy:GetName());
	local found = false;


	if toy:IsCustom() then
		for x = 0,4 do
			for y = 1, GetContainerNumSlots(x) do
				local id = GetContainerItemID(x,y);
				if id == toy:GetID() then
					found = true;
				end
			end
		end
		if found == false then
			ToyBoxQ:Print(toy:GetName(), "is not found in your current inventory.");
			return;
		end
	end
	secure:SetAttribute("type", "item");
	secure:SetAttribute("item", toy:GetName());
--	secure:SetAttribute("item", "item:"..toy:GetID());
	if TBQ.TimerIsScheduled == false then
		ToyTimer:ScheduleTimer("CheckCooldown", .5);
		TBQ.TimerIsScheduled = true;
	end
end

function ToyBoxQ.LDB:SecurePostClick(secure)
	secure:SetAttribute("type", nil);
	secure:SetAttribute("item", nil);
end

function ToyBoxQ.LDB:OnEnable()
	CreateFrame("Button", "ToyBoxQBtn", UIParent, "SecureActionButtonTemplate");
	ToyBoxQBtn:SetScript('PreClick', function (_, btn) 
		ToyBoxQ.LDB:SecurePreClick(btn, ToyBoxQBtn, nil, nil);
	end);
	ToyBoxQBtn:SetScript('PostClick', function (_, btn) 
		ToyBoxQ.LDB:SecurePostClick(ToyBoxQBtn);
	end);
	ToyBoxQBtn:SetScript("OnEnter", function(self) 
		ToyBoxQ.LDB:OnEnterSecure(self, button);
	end);
	ToyBoxQBtn:SetScript("OnLeave", function(self)
		if TBQ.chocolate and TBQ.chocolate.autohide then
			TBQ.chocolate:HideAll();
		end
	end);
	ToyBoxQBtn:RegisterForClicks('AnyUp');
	ToyBoxQBtn:Hide();

	CreateFrame("Button", "ToyBoxQTrans", UIParent, "SecureActionButtonTemplate");
	ToyBoxQTrans:SetScript('PreClick', function (_, btn) 
		ToyBoxQ.LDB:SecurePreClick(btn, ToyBoxQTrans, nil, TBQ.VIEW_TRANSFORM);
	end);
	ToyBoxQTrans:SetScript('PostClick', function (_, btn) 
		ToyBoxQ.LDB:SecurePostClick(ToyBoxQTrans);
	end);
	ToyBoxQTrans:SetScript("OnEnter", function(self) 
		ToyBoxQ.LDB:OnEnterSecure(self, button);
	end);
	ToyBoxQTrans:RegisterForClicks('AnyUp');
	ToyBoxQTrans:Hide();

	CreateFrame("Button", "ToyBoxQMenu", UIParent, "SecureActionButtonTemplate") 
	ToyBoxQMenu:RegisterForClicks('LeftButtonUp');
	ToyBoxQMenu:Hide()
end 

function TBQ.OpenConfig()
	ToyBoxQ:UIOpen();
end

function ToyBoxQ.LDB:MenuViewSwap(self)
	if TBQ.db.global.BrokerView == TBQ.VIEW_ALL then
		TBQ.db.global.BrokerView = TBQ.VIEW_TRANSFORM;
	elseif TBQ.db.global.BrokerView == TBQ.VIEW_TRANSFORM then
		TBQ.db.global.BrokerView = TBQ.VIEW_OTHER;
	else
		TBQ.db.global.BrokerView = TBQ.VIEW_ALL;
	end
	local msg = "View: "..ViewMsgs[TBQ.db.global.BrokerView].." (Click to Change)";
	local tooltip = LibQTip:Acquire("ToyBoxQTooltip", 1, "LEFT", "LEFT");
	if tooltip:IsShown() then
		tooltip:Clear();
		ToyBoxQ.LDB:Tooltip_Generate(tooltip);
	end
end

local function Tooltip_AddRows(tooltip)
	local format = "%s";
	local empty = true;
	format = "|cffffc1c1"..format.."|r";

	if TBQ.db.global.BrokerView == nil then
		TBQ.db.global.BrokerView = TBQ.VIEW_ALL;
	end

	ToyBoxQ.LDB:UpdateShownToys(TBQ.db.global.BrokerView, false);

	for i, j in pairs(TBQ.ShownToys) do
		local toy = ToyBoxQ.ToyDB:GetToy(j);
		local name = toy:GetName();
		local icon = toy:GetIcon();
		local line;
		
		local cooldown = TBQ_CooldownTime(toy);
		if cooldown ~= nil then
			name = name.." "..cooldown;

			if TBQ.TimerIsScheduled == false then
				ToyTimer:ScheduleTimer("CheckCooldown", 1);
				TBQ.TimerIsScheduled = true;
			end
		end
		
		if empty == true then
			line = tooltip:AddLine();
			local msg = "Viewing: "..ViewMsgs[TBQ.db.global.BrokerView].." (Click to Change)";
			tooltip:SetCell(line, 1, msg, nil, "CENTER", 1);
			tooltip:SetCellScript(line, 1, "OnEnter", SecureTooltipEnter, nil);
			tooltip:AddSeparator();
		end
		empty = false;
		line = tooltip:AddLine();
		tooltip:SetCell(line, 1, string.format(TBQ.IconFormat, icon).." "..name, nil, "LEFT", 1);
		tooltip:SetCellScript(line, 1, "OnEnter", SecureTooltipEnter, toy);
	end
	
	if empty == true then
		line = tooltip:AddLine();
		local msg = "Viewing: "..ViewMsgs[TBQ.db.global.BrokerView].." (Click to Change)";
		tooltip:SetCell(line, 1, msg, nil, "CENTER", 1);
		tooltip:SetCellScript(line, 1, "OnEnter", SecureTooltipEnter, nil);
		tooltip:AddSeparator();
		local line = tooltip:AddLine();
		tooltip:SetCell(line, 1, "Right Click to add toys to this menu.");
		line = tooltip:AddLine();
		tooltip:SetCell(line, 1, "Left Click to pick a random transformation.");
		line = tooltip:AddLine();
		tooltip:SetCell(line, 1, "Click pet in menu to use a specific toy.");
		tooltip:SetColumnScript(1, "OnMouseDown", TBQ.OpenConfig);
	end

end

function ToyBoxQ.LDB:Tooltip_Generate_Category(tooltip)
	tooltip:SetScale(TBQ.db.profile.Scale);
	local line = tooltip:AddLine()

	tooltip:SetCell(line, 1, "|cff00E5EECategory|r", nil, "CENTER", 1);
	tooltip:AddSeparator();
end

function ToyBoxQ.LDB:Tooltip_Generate(tooltip)
	tooltip:SetScale(TBQ.db.profile.Scale);
	local line = tooltip:AddLine()

	tooltip:SetCell(line, 1, "|cff00E5EEToyBoxQ|r", nil, "CENTER", 1);
	tooltip:AddSeparator();

	if TBQ.db.global.mod == 1 or
	   (TBQ.db.global.mod == 2 and IsControlKeyDown()) or
	   (TBQ.db.global.mod == 3 and IsShiftKeyDown()) or
	   (TBQ.db.global.mod == 4 and IsAltKeyDown()) then
		Tooltip_AddRows(tooltip);
	end
end

function ToyTimer:CheckCooldown()
	TBQ.TimerIsScheduled = false;
	local tooltip = LibQTip:Acquire("ToyBoxQTooltip", 1, "LEFT", "LEFT");
	if tooltip:IsShown() then
		tooltip:Clear();
		ToyBoxQ.LDB:Tooltip_Generate(tooltip);
	end
end

function ToyBoxQ.LDB:OnEnter(brokerframe, button)
	if GameTooltip ~= nil then GameTooltip:Hide(); end
	if InCombatLockdown() then return end;
	if brokerframe.bar ~= nil and brokerframe.bar.chocolist ~= nil then
		TBQ.chocolate = brokerframe.bar;
	end

	ToyBoxQBtn:RegisterForDrag("LeftButton")
	ToyBoxQBtn:SetMovable(true)
	ToyBoxQBtn:SetScript("OnDragStart", function(self)
		if InCombatLockdown() then return end
		if GameTooltip ~= nil then GameTooltip:Hide() end
		brokerframe:GetScript("OnDragStart")(brokerframe)
		self:SetScript("OnUpdate", function(self)
			self:SetAllPoints(brokerframe)
			if not IsMouseButtonDown("LeftButton") then
				brokerframe:GetScript("OnDragStop")(brokerframe)
				self:SetScript("OnUpdate",nil)
			end
		end)
		self:Show()
	end)

	brokerframe:SetScript("OnHide", function()
		if not InCombatLockdown() then ToyBoxQBtn:Hide(); end
	end)

	ToyBoxQBtn:SetFrameStrata(brokerframe:GetFrameStrata())
	ToyBoxQBtn:SetFrameLevel(brokerframe:GetFrameLevel()+1)
	ToyBoxQBtn:SetAllPoints(brokerframe)
	ToyBoxQBtn:Show()
end

function ToyBoxQ.LDB:OnEnterSecure(self, button)
	if TBQ.chocolate and TBQ.chocolate.autohide then
		TBQ.chocolate:ShowAll();
	end
	local tooltip = LibQTip:Acquire("ToyBoxQTooltip", 1, "LEFT", "LEFT");
	if tooltip:IsShown() then
		return;
	end

	tooltip:SmartAnchorTo(self);

	tooltip:Clear();

	ToyBoxQ.LDB:Tooltip_Generate(tooltip);

	tooltip:EnableMouse();
	tooltip:SmartAnchorTo(self);
	tooltip:SetAutoHideDelay(0.25, self);
	tooltip:UpdateScrolling();
	tooltip:Show();
end

function ToyBoxQ.LDB:LibIconToggle(val)
	if val then
		LibIcon:Show(appName);
	else
		LibIcon:Hide(appName);
	end
end
