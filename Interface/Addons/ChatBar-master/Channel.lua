--[[
	Channel.lua
        频道文字缩写，时间戳和聊天复制功能
        TODO:分离本地化文本到本地化文件
        插件更新地址 http://nga.178.com/read.php?tid=9633520
--]]
--[[============================== 基本设置区域 ==========================]] --
-- true(启用)/false(关闭)
local ShortChannel = true -- 精简公共频道
local TimeStampFormat = false -- 聊天时间戳
--
-- 获取语言
local Language = GetLocale()
--[[============================== 默认的聊天标签,可修改汉字自定义 ==========================]]
if (Language == "zhTW") then
    --公会
    CHAT_GUILD_GET = "|Hchannel:GUILD|h[公會]|h %s: "
    CHAT_OFFICER_GET = "|Hchannel:OFFICER|h[官員]|h %s: "

    --团队
    CHAT_RAID_GET = "|Hchannel:RAID|h[團隊]|h %s: "
    CHAT_RAID_WARNING_GET = "[通知] %s: "
    CHAT_RAID_LEADER_GET = "|Hchannel:RAID|h[團長]|h %s: "

    --队伍
    CHAT_PARTY_GET = "|Hchannel:PARTY|h[隊伍]|h %s: "
    CHAT_PARTY_LEADER_GET = "|Hchannel:PARTY|h[隊長]|h %s: "
    CHAT_PARTY_GUIDE_GET = "|Hchannel:PARTY|h[向導]|h %s: "

    --战场
    CHAT_BATTLEGROUND_GET = "|Hchannel:BATTLEGROUND|h[戰場]|h %s: "
    CHAT_BATTLEGROUND_LEADER_GET = "|Hchannel:BATTLEGROUND|h[領袖]|h %s: "

    --说 / 喊
    CHAT_SAY_GET = "%s: "
    CHAT_YELL_GET = "%s: "

    --密语
    CHAT_WHISPER_INFORM_GET = "發送給%s: "
    CHAT_WHISPER_GET = "%s悄悄話: "

    --flags
    CHAT_FLAG_AFK = "[暫離] "
    CHAT_FLAG_DND = "[勿擾] "
    CHAT_FLAG_GM = "[GM] "
elseif (Language == "zhCN") then
    --公会
    CHAT_GUILD_GET = "|Hchannel:GUILD|h[公会]|h %s: "
    CHAT_OFFICER_GET = "|Hchannel:OFFICER|h[官员]|h %s: "

    --团队
    CHAT_RAID_GET = "|Hchannel:RAID|h[团队]|h %s: "
    CHAT_RAID_WARNING_GET = "[通知] %s: "
    CHAT_RAID_LEADER_GET = "|Hchannel:RAID|h[团长]|h %s: "

    --队伍
    CHAT_PARTY_GET = "|Hchannel:PARTY|h[队伍]|h %s: "
    CHAT_PARTY_LEADER_GET = "|Hchannel:PARTY|h[队长]|h %s: "
    CHAT_PARTY_GUIDE_GET = "|Hchannel:PARTY|h[向导]:|h %s: "

    --战场
    CHAT_BATTLEGROUND_GET = "|Hchannel:BATTLEGROUND|h[副本]|h %s: "
    CHAT_BATTLEGROUND_LEADER_GET = "|Hchannel:BATTLEGROUND|h[领袖]|h %s: "

    --密语
    CHAT_WHISPER_INFORM_GET = "发送给%s: "
    CHAT_WHISPER_GET = "%s悄悄的说: "
    CHAT_BN_WHISPER_INFORM_GET = "发送给%s: "
    CHAT_BN_WHISPER_GET = "悄悄的说%s: "

    --说 / 喊
    CHAT_SAY_GET = "%s: "
    CHAT_YELL_GET = "%s: "

    --flags
    CHAT_FLAG_AFK = "[暂离] "
    CHAT_FLAG_DND = "[勿扰] "
    CHAT_FLAG_GM = "[GM] "
else
    CHAT_GUILD_GET = "|Hchannel:GUILD|hG|h %s "
    CHAT_OFFICER_GET = "|Hchannel:OFFICER|hO|h %s "
    CHAT_RAID_GET = "|Hchannel:RAID|hR|h %s "
    CHAT_RAID_WARNING_GET = "RW %s "
    CHAT_RAID_LEADER_GET = "|Hchannel:RAID|hRL|h %s "
    CHAT_PARTY_GET = "|Hchannel:PARTY|hP|h %s "
    CHAT_PARTY_LEADER_GET = "|Hchannel:PARTY|hPL|h %s "
    CHAT_PARTY_GUIDE_GET = "|Hchannel:PARTY|hPG|h %s "
    CHAT_BATTLEGROUND_GET = "|Hchannel:BATTLEGROUND|hB|h %s "
    CHAT_BATTLEGROUND_LEADER_GET = "|Hchannel:BATTLEGROUND|hBL|h %s "
    CHAT_WHISPER_INFORM_GET = "to %s "
    CHAT_WHISPER_GET = "from %s "
    CHAT_BN_WHISPER_INFORM_GET = "to %s "
    CHAT_BN_WHISPER_GET = "from %s "
    CHAT_SAY_GET = "%s "
    CHAT_YELL_GET = "%s "
    CHAT_FLAG_AFK = "[AFK] "
    CHAT_FLAG_DND = "[DND] "
    CHAT_FLAG_GM = "[GM] "
end

--================================公共频道和自定义频道精简================================--
local gsub = _G.string.gsub
local newAddMsg = {}
local chn = {
    "%[%d+%. General.-%]",
    "%[%d+%. Trade.-%]",
    "%[%d+%. LocalDefense.-%]",
    "%[%d+%. LookingForGroup%]",
    "%[%d+%. WorldDefense%]",
    "%[%d+%. GuildRecruitment.-%]",
    "%[%d+%. BigFootChannel.-%]",
    "%[%d+%. CustomChannel.-%]" -- 自定义频道英文名随便填写
}

local rplc = {
    "[GEN]",
    "[TR]",
    "[WD]",
    "[LD]",
    "[LFG]",
    "[GR]",
    "[BFC]",
    "[CL]" -- 英文缩写
}

if (Language == "zhCN") then ---国服
    rplc[1] = "[%1综]"
    rplc[2] = "[%1交]"
    rplc[3] = "[%1防]"
    rplc[4] = "[%1组]"
    rplc[5] = "[%1守]"
    rplc[6] = "[%1招]"
    rplc[7] = "[%1世]"
    rplc[8] = "[%1自定义]" -- 自定义频道缩写请自行修改
elseif (Language == "zhTW") then ---台服
    rplc[1] = "[%1綜合]"
    rplc[2] = "[%1貿易]"
    rplc[3] = "[%1防務]"
    rplc[4] = "[%1組隊]"
    rplc[5] = "[%1守備]"
    rplc[6] = "[%1招募]"
    rplc[7] = "[%1世界]"
    rplc[8] = "[%1自定义]" -- 自定义频道缩写请自行修改
end

if Language == "zhCN" then
    ---------------------------------------- 国服简体中文 ---------------------------------------------
    chn[1] = "%[%d+%. 综合.-%]"
    chn[2] = "%[%d+%. 交易.-%]"
    chn[3] = "%[%d+%. 本地防务.-%]"
    chn[4] = "%[%d+%. 寻求组队%]"
    chn[5] = "%[%d+%. 世界防务%]"
    chn[6] = "%[%d+%. 公会招募.-%]"
    chn[7] = "%[%d+%. 大脚世界频道.-%]"
    chn[8] = "%[%d+%. 自定义频道.-%]" -- 请修改频道名对应你游戏里的频道
elseif Language == "zhTW" then
    ---------------------------------------- 台服繁体中文 ---------------------------------------------
    chn[1] = "%[%d+%. 綜合.-%]"
    chn[2] = "%[%d+%. 貿易.-%]"
    chn[3] = "%[%d+%. 本地防務.-%]"
    chn[4] = "%[%d+%. 尋求組隊%]"
    chn[5] = "%[%d+%. 世界防務%]"
    chn[6] = "%[%d+%. 公會招募.-%]"
    chn[7] = "%[%d+%. 大脚世界频道.-%]"
    chn[8] = "%[%d+%. 自定义频道.-%]" -- 请修改频道名对应你游戏里的频道
end

local rules = {
    --!!不要改
    {pat = "|c%x+|HChatCopy|h.-|h|r", repl = ""},
    {pat = "|c%x%x%x%x%x%x%x%x(.-)|r", repl = "%1"},
    --左鍵
    {pat = "|Hchannel:.-|h.-|h", repl = "", button = "LeftButton"},
    {pat = "|Hplayer:.-|h.-|h" .. ":", repl = "", button = "LeftButton"},
    {pat = "|Hplayer:.-|h.-|h" .. "：", repl = "", button = "LeftButton"},
    {pat = "|HBNplayer:.-|h.-|h" .. ":", repl = "", button = "LeftButton"},
    {pat = "|HBNplayer:.-|h.-|h" .. "：", repl = "", button = "LeftButton"},
    --右鍵
    {pat = "|Hchannel:.-|h(.-)|h", repl = "%1", button = "RightButton"},
    {pat = "|Hplayer:.-|h(.-)|h", repl = "%1", button = "RightButton"},
    {pat = "|HBNplayer:.-|h(.-)|h", repl = "%1", button = "RightButton"},
    --!!不要改
    {pat = "|H.-|h(.-)|h", repl = "%1"},
    {pat = "|TInterface\\TargetingFrame\\UI%-RaidTargetingIcon_(%d):0|t", repl = "{rt%1}"},
    {pat = "|T.-|t", repl = ""},
    {pat = "^%s+", repl = ""}
}

-- 时间格式化字符串
local ts = "%H:%M:%S"
-- 文字修改函数
local function AddMessage(frame, text, ...)
    -- 频道标签精简
    if ShortChannel then
        for i = 1, 8 do -- 对应上面几个频道(如果有9个频道就for i = 1, 9 do)
            text = gsub(text, chn[i], rplc[i])
        end
        text = gsub(text, "%[(%d0?)%. .-%]", "%1.")
    end

    if (type(text) ~= "string") then
        text = tostring(text)
    end

    -- 聊天时间戳与聊天复制
    if SimpleChat_Config.TimeStampFormat then
        text = format("|cff68ccef|HChatCopy|h%s|h|r %s", date(ts), text)
    else
        text = format("|cff68ccef|HChatCopy|h%s|h|r %s", "+", text)
    end

    return newAddMsg[frame:GetName()](frame, text, ...)
end

--RemoveChatWindowMessages(ChatFrame1,"messageGroup") -- 屏蔽出入频道信息
for i = 1, NUM_CHAT_WINDOWS do -- 对非战斗记录聊天框的信息进行处理
    if i ~= 2 then -- 跳过战斗记录框
        local f = _G[format("%s%d", "ChatFrame", i)]
        newAddMsg[format("%s%d", "ChatFrame", i)] = f.AddMessage
        f.AddMessage = AddMessage
    end
end

-- 显示信息到输入框
local function showMessage(msg, button)
    local editBox = ChatEdit_ChooseBoxForSend()

    -- 清理链接规则
    for _, rule in ipairs(rules) do
        if (not rule.button or rule.button == button) then
            msg = msg:gsub(rule.pat, rule.repl)
        end
    end

    -- 激活聊天窗 将文本写入
    ChatEdit_ActivateChat(editBox)
    editBox:SetText(editBox:GetText() .. msg)
    editBox:HighlightText()
end

-- 获取信息信息
local function getMessage(...)
    local object
    for i = 1, select("#", ...) do
        object = select(i, ...)
        if (object:IsObjectType("FontString") and MouseIsOver(object)) then
            return object:GetText()
        end
    end
    return ""
end

-- 聊天链接文字钩子
function SimpleChat_InitChannel()
    local _SetItemRef = SetItemRef
    SetItemRef = function(link, text, button, chatFrame)
        if (link:sub(1, 8) == "ChatCopy") then
            local msg = getMessage(chatFrame.FontStringContainer:GetRegions())
            return showMessage(msg, button)
        end
        if (link:sub(1, 12) == "ChatLinkIcon") then
            return
        end
        _SetItemRef(link, text, button, chatFrame)
    end
end
