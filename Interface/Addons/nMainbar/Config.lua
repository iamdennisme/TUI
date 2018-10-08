local _, nMainbar = ...

nMainbar.Config = {

	showPicomenu = true,
	useFakeBottomRightBar = false,

    button = {
		showVehicleKeybinds = true,
		showKeybinds = true,
        showMacroNames = true,

        watchbarFontsize = 13,
        watchbarFont = STANDARD_TEXT_FONT,

        countFontsize = 18,
        countFont = "Interface\\AddOns\\nMainbar\\Media\\font.ttf",

        macronameFontsize = 15,
        macronameFont = "Interface\\AddOns\\nMainbar\\Media\\font.ttf",

        hotkeyFontsize = 18,
        hotkeyFont = "Interface\\AddOns\\nMainbar\\Media\\font.ttf",

        petHotKeyFontsize = 15,
    },

    color = {   -- Red, Green, Blue, Alpha
        Normal = { 1, 1, 1, 1 },
        IsEquipped = { 0, 1, 0 },

        HotKeyText = { 0.6, 0.6, 0.6 },
        MacroText = { 1, 1, 1 },
        CountText = { 1, 1, 1 },
    },

    MainMenuBar = {
		moveableExtraBars = true,
		hideGryphons = false,
		scale = 1,
    },

    vehicleBar = {
        scale = 0.8,
    },

	petBar = {
        mouseover = false,
        scale = 1,
        hiddenAlpha = 0,
        alpha = 1,
		vertical = false,
    },

	stanceBar = {
		hide = false,
		scale = 1,
		alpha = 1,
	},

	possessBar = {
		scale = 1,
		alpha = 1,
	},

    multiBarRight = {
        mouseover = false,
        scale = 1,
        hiddenAlpha = 0,
        alpha = 1,
    },

    multiBarBottomLeft = {
        mouseover = false,
        scale = 1,
        hiddenAlpha = 0,
        alpha = 1,
    },
}
