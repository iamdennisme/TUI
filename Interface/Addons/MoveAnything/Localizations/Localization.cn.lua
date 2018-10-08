if GetLocale() ~= "zhCN" then
	return
end

local MOVANY = {
	ADD = "增加",
	ADDNEW = "增加新的",
	CLOSEGUIONESC = "ESC键关闭插件主窗口",
	CMD_SYNTAX_DELETE = "Syntax: /movedelete ProfileName", -- Missing translation
	CMD_SYNTAX_EXPORT = "Syntax: /moveexport ProfileName", -- Missing translation
	CMD_SYNTAX_HIDE = "Syntax: /hide ProfileName", -- Missing translation
	CMD_SYNTAX_IMPORT = "Syntax: /moveimport ProfileName", -- Missing translation
	CMD_SYNTAX_MAFE = "Syntax: /mafe frameName", -- Missing translation
	CMD_SYNTAX_UNMOVE = "Syntax: /unmove frameName", -- Missing translation
	DELETE = "删除",
	DISABLED_DURING_COMBAT = "战斗中禁用",
	DISERRORMES = "切换屏幕上的错误信息 开/关",
	DISERRORMESNO = "禁用错误信息",
	DONSEARCHFRAMENAME = "禁用搜索目前框架的名称",
	DONTSEARCH = "禁用搜索框体名称",
	DONTSYNCINCOMBAT = "Toggles if MoveAnything will synchronize pending frames when leaving combat.\n\nDisabling this may result in protected frames requiring a manual sync when leaving combat.", -- Missing translation
	DONTSYNCINCOMBATNO = "禁用离开战斗时同步",
	ELEMENT_NOT_FOUND = "UI element not found", -- Missing translation
	ELEMENT_NOT_FOUND_NAMED = "UI element not found: %s", -- Missing translation
	ERROR_FRAME_FAILED = "An error occured while syncing %s. Resetting the frame and /reload'ing before modifying it again might solve the issue. You can disable this message in the options. If the problem persists please report the following to the author: %s %s %s", -- Missing translation
	ERROR_MODULE_FAILED = "An error occured while adjusting %s for %s. You can disable this message in the options. If the problem persists please report the following to the author: %s %s %s %s", -- Missing translation
	ERROR_NOT_A_TABLE = "\"%s\" 是一个未支持的类型",
	FE_FORCED_LOCK_POSITION_CONFIRM = "强制锁定位置? 5秒内再次点击以确认",
	FE_FORCED_LOCK_POSITION_TOOLTIP = "Overwrites the element's SetPoint method,\nreplacing it with an empty stub\n\nMay cause taint if the element is protected\nand the stub gets called during combat\n\nRequires a reload or relog after unchecking to\nrestore the original SetPoint method", -- Missing translation
	FE_GROUP_RESET_CONFIRM = "重置队伍 %i? 5秒内再次点击以确认",
	FE_GROUPS_TOOLTIP = "队伍 %i",
	FE_UNREGISTER_ALL_EVENTS_CONFIRM = "注销所有事件? 5秒内再次点击以确认",
	FE_UNREGISTER_ALL_EVENTS_TOOLTIP = "Unregisters any events that the frame is listening to,\nrendering the frame inert\n\nRe-enabling unregistered events will require a reload\nor relog after unchecking this checkbox", -- Missing translation
	FRAME_NO_FRAME_EDITOR = "Frame editors is disabled for %s", -- Missing translation
	FRAME_ONLY_ONCE_OPENED = "Can only interact with %s once it has been shown", -- Missing translation
	FRAME_ONLY_WHEN_BANK_IS_OPEN = "Can only interact with %s while the bank is open", -- Missing translation
	FRAME_ONLY_WHEN_VOIDSTORAGE_IS_OPEN = "Can only interact %s is open", -- Missing translation
	FRAME_PROTECTED_DURING_COMBAT = "Can't interact with %s during combat", -- Missing translation
	FRAME_UNPOSITIONED = "%s is currently unpositioned and can't be moved till it is", -- Missing translation
	FRAME_VISIBILITY_ONLY = "%s can only be hidden", -- Missing translation
	HOOKALLOWED = "Toggles if MoveAnything will hook CreateFrame.\n\nRequires reload to take effect.", -- Missing translation
	HOOKALLOWEDNO = "关闭窗口创建监视",
	LIST_HEADING_CATEGORY_AND_FRAMES = "Categories and Frames", -- Missing translation
	LIST_HEADING_HIDE = "隐藏",
	LIST_HEADING_MOVER = "Mover", -- Missing translation
	LIST_HEADING_SEARCH_RESULTS = "搜索结果: %i",
	NOMMWP = "Toggles Minimap mousewheel zoom on/off., -- Missing translation\n\nRequires reload to take effect.",
	NOMMWPNO = "禁用小地图鼠标滚轮",
	NO_NAMED_FRAMES_FOUND = "No named elements found", -- Missing translation
	NUDGER1 = "显示Nudger于主窗口",
	ONLY_ONCE_CREATED = "%s 只有建立后才可被修改",
	OPTBAGS1 = "Toggles if MoveAnything will hook containers.\n\nThis should be checked if you use another addon to move your bags.", -- Missing translation
	OPTBAGSTOOLTIP = "关闭背包容器监视",
	OPTIONTOOLTIP1 = "启用主介面显示Nudger\n\n默认情况下Nudger只与显示的框架相互作用.",
	OPTIONTOOLTIP2 = "Toggles display of tooltips on/off\n\nPressing Shift when mousing over elements will reverse tooltip display behavior.", -- Missing translation
	PLAYSOUND = "播放音效",
	PLAYSOUNDS = "当MoveAnything在开/关主窗口时播放音效",
	PROFILE_ADD_TEXT = "输入新配置名称",
	PROFILE_ALREADY_EXISTS = "已有配置 \"%s\"",
	PROFILE_CANT_DELETE_CURRENT_IN_COMBAT = "战斗中不能删除当前配置",
	PROFILE_CANT_DELETE_DEFAULT = "默认配置不能删除",
	PROFILE_CURRENT = "当前的",
	PROFILE_DELETED = "已删除配置: %s",
	PROFILE_DELETE_TEXT = "是否删除配置 \"%s\"?",
	PROFILE_EXPORTED = "\"%s\" 导出到 \"%s\"",
	PROFILE_IMPORTED = "\"%s\" 已被导入到 \"%s\"",
	PROFILE_RENAME_TEXT = "为 \"%s\" 输入新名称",
	PROFILE_RESET_CONFIRM = "MoveAnything: 重置当前配置的所有框体?",
	PROFILES = "配置",
	PROFILE_SAVE_AS_TEXT = "输入新配置名称",
	PROFILES_CANT_SWITCH_DURING_COMBAT = "战斗中不能切换配置",
	PROFILE_UNKNOWN = "未知配置: %s",
	RENAME = "重命名",
	RESETALL1 = "Reset all\n\nReset MoveAnything to default settings. Deletes all frame settings, as well as the custom frame list", -- Missing translation
	RESET_ALL_CONFIRM = "MoveAnything: Reset MoveAnything to installation state?\n\nWarning: this will delete all frame settings and clear out the custom frame list.", -- Missing translation
	RESET_FRAME_CONFIRM = "重置 %s? 5秒内再次点击以确认",
	RESETPROFILE1 = "Reset profile\n\nResets the profile, deleting all stored frame settings for this profile.", -- Missing translation
	RESETTING_FRAME = "重置 %s",
	SAVE = "保存",
	SAVEAS = "保存为",
	SEARCH_TEXT = "搜索",
	SHOWTOOLTIPS = "显示工具提示",
	SQUARMAP = "Toggles square MiniMap on/off.\n\nHide \"Round Border\" in the \"Minimap\" category to get rid of the overlaying border.", -- Missing translation
	SQUARMAPNO = "开启方形地图",
	UNSERIALIZE_FRAME_INVALID_FORMAT = "Invalid format", -- Missing translation
	UNSERIALIZE_FRAME_NAME_DIFFERS = "Imported frame name differs from import target", -- Missing translation
	UNSERIALIZE_PROFILE_COMPLETED = "Imported %i element(s) into profile \"%s\"", -- Missing translation
	UNSERIALIZE_PROFILE_NO_NAME = "Unable to locate profile name", -- Missing translation
	UNSUPPORTED_FRAME = "不支持的框体: %s",
	UNSUPPORTED_TYPE = "不支持的类型: %s"
}

_G.MOVANY = MOVANY
