local _G = _G
local _, HN = ...
local L = LibStub("AceLocale-3.0"):GetLocale("HandyNotes_MoleMachine")
local HandyNotes = LibStub("AceAddon-3.0"):GetAddon("HandyNotes")
_G.HNMoleMachine = HN

local pairs, next = _G.pairs, _G.next
local IsQuestFlaggedCompleted = _G.IsQuestFlaggedCompleted
local GetMapChildrenInfo = _G.C_Map.GetMapChildrenInfo
local ElvUI = _G.ElvUI

HN.Plugin = {}
HN.CurrentMap = 0
HN.ContinentData = {}

HN.DefaultSettings = {["Alpha"] = 1, ["Scale"] = 2.5}
HN.Options = {
  type = "group",
  name = L["Mole Machine"],
  get = function(info)
    return HN.Config[info.arg]
  end,
  set = function(info, v)
    HN.Config[info.arg] = v
    HandyNotes:SendMessage("HandyNotes_NotifyUpdate", "MoleMachine")
  end,
  args = {
    scale = {
      type = "range",
      name = L["Icon scale"],
      desc = L["The scale of the icons."],
      min = 0.25, max = 5, step = 0.05,
      arg = "Scale",
      order = 10,
    },
    alpha = {
      type = "range",
      name = L["Icon alpha"],
      desc = L["The alpha transparency of the icons."],
      min = 0, max = 1, step = 0.01,
      arg = "Alpha",
      order = 20,
    },
  },
}

HN.Drills = {
  [13534680] = {["mapID"] = 26, ["name"] = L["Aerie Peak"], ["questID"] = 53585},
  [31517359] = {["mapID"] = 376, ["name"] = L["Stormstout Brewery"], ["questID"] = 53598},
  [33302480] = {["mapID"] = 35, ["name"] = L["The Masonary"], ["questID"] = 53587, ["note"] = L["Inside Blackrock Mountain"]},
  [39110930] = {["mapID"] = 199, ["name"] = L["The Great Divide"], ["questID"] = 53600},
  [44667290] = {["mapID"] = 650, ["name"] = L["Neltharion's Vault"], ["questID"] = 53593},
  [45354992] = {["mapID"] = 115, ["name"] = L["Ruby Dragonshrine"], ["questID"] = 53596},
  [46693876] = {["mapID"] = 543, ["name"] = L["Blackrock Foundry Overlook"], ["questID"] = 53588},
  [50773530] = {["mapID"] = 104, ["name"] = L["Fel Pits"], ["questID"] = 53599},
  [50931607] = {["mapID"] = 35, ["name"] = L["Shadowforge City"], ["questID"] = nil, ["note"] = L["Inside Blackrock Mountain"]},
  [52885576] = {["mapID"] = 78, ["name"] = L["Fire Plume Ridge"], ["questID"] = 53591},
  [53096487] = {["mapID"] = 100, ["name"] = L["Honor Hold"], ["questID"] = 53592},
  [57187711] = {["mapID"] = 198, ["name"] = L["Throne of Flame"], ["questID"] = 53601},
  [57686281] = {["mapID"] = 379, ["name"] = L["One Keg"], ["questID"] = 53595},
  [61293718] = {["mapID"] = 27, ["name"] = L["Ironforge"], ["questID"] = nil},
  --[61442435] = {["mapID"] = 1186, ["name"] = L["Shadowforge City"], ["questID"] = nil, ["note"] = L["Inside Blackrock Mountain"]},
  [61971280] = {["mapID"] = 17, ["name"] = L["Nethergarde Keep"], ["questID"] = 53594},
  [63333734] = {["mapID"] = 84, ["name"] = L["Stormwind"], ["questID"] = nil},
  [65750825] = {["mapID"] = 550, ["name"] = L["Elemental Plateau"], ["questID"] = 53590},
  [71694799] = {["mapID"] = 646, ["name"] = L["Broken Shore"], ["questID"] = 53589},
  [72421764] = {["mapID"] = 105, ["name"] = L["Skald"], ["questID"] = 53597},
  [76971866] = {["mapID"] = 118, ["name"] = L["Argent Tournament Grounds"], ["questID"] = 53586}
}

local function ElvUISwag(sender)
  if sender == "Livarax-BurningLegion" then
    return [[|TInterface\PvPRankBadges\PvPRank09:0|t ]]
  end
  return nil
end

function HN:CheckMap(mapID)
  for _, p in pairs(HN.ContinentData[HN.CurrentMap]) do
    if mapID == p.mapID then
      return true
    end
  end
  return false
end

function HN.Plugin:OnEnter(_, coord)
  local tooltip = self:GetParent() == _G.WorldMapButton and _G.WorldMapTooltip or _G.GameTooltip
  if self:GetCenter() > _G.UIParent:GetCenter() then
    tooltip:SetOwner(self, "ANCHOR_LEFT")
  else
    tooltip:SetOwner(self, "ANCHOR_RIGHT")
  end
  local drill = HN.Drills[coord]
  if drill then
    tooltip:AddLine(drill.name)
    if drill.note then
      tooltip:AddLine(drill.note, 1, 1, 1)
    end
    if drill.questID and not IsQuestFlaggedCompleted(drill.questID) then
      tooltip:AddLine(L["Undiscovered"], 1, 0, 0)
    end
    tooltip:Show()
  end
end

function HN.Plugin:OnLeave(_, _)
  local tooltip = self:GetParent() == _G.WorldMapButton and _G.WorldMapTooltip or _G.GameTooltip
  tooltip:Hide()
end

local function Iterator(t, last)
  if not t or HN.CurrentMap == 946 then return end
  local k, v = next(t, last)
  while k do
    if v then
      if v.mapID == HN.CurrentMap or (HN.ContinentData[HN.CurrentMap] and HN.ContinentData[HN.CurrentMap] ~= 0 and HN:CheckMap(v.mapID)) then
        local icon = (v.questID and not IsQuestFlaggedCompleted(v.questID)) and "MiniMap-DeadArrow" or "MiniMap-QuestArrow"
        return k, v.mapID, "Interface\\Minimap\\"..icon, HN.Config.Scale, HN.Config.Alpha
      end
    end
    k, v = next(t, k)
  end
end

function HN.Plugin:GetNodes2(mapID, _)
  HN.CurrentMap = mapID
  if not HN.ContinentData[HN.CurrentMap] and HN.CurrentMap ~= 946 then
    HN.ContinentData[HN.CurrentMap] = GetMapChildrenInfo(HN.CurrentMap, nil, true) or 0
  end
  return Iterator, HN.Drills
end

HN.Frame = CreateFrame("Frame")
HN.Frame:RegisterEvent("PLAYER_LOGIN")
HN.Frame:SetScript("OnEvent", function(self, event, ...) return self[event](self, ...) end)

function HN.Frame:PLAYER_LOGIN()
  if not _G.HNMoleMachineConfig then _G.HNMoleMachineConfig = HN.DefaultSettings end
  HN.Config = _G.HNMoleMachineConfig
  for key, value in pairs(HN.DefaultSettings) do
    if HN.Config[key] == nil then
      HN.Config[key] = value
    end
  end

  if ElvUI then
    ElvUI[1]:GetModule("Chat"):AddPluginIcons(ElvUISwag)
  end

  HandyNotes:RegisterPluginDB("MoleMachine", HN.Plugin, HN.Options)
end
