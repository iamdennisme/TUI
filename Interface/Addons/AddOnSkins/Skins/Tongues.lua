local AS = unpack(AddOnSkins)

if not AS:CheckAddOn('Tongues') then return end

function AS:Tongues()
	AS:SkinFrame(Tongues.UI.MainMenu.Frame)
	AS:SkinFrame(Tongues.UI.MainMenu.AdvancedOptions.Frame)
	AS:SkinButton(Tongues.UI.MiniMenu.Frame)
	Tongues.UI.MiniMenu.Frame:HookScript('OnUpdate', function(self)
		self:SetText("|cFFFFFFFFTongues\10|cff1784d1"..Tongues.Settings.Character.Language)
	end)
	AS:SkinButton(Tongues.UI.MainMenu.SpeakButton.Frame)
	AS:SkinButton(Tongues.UI.MainMenu.UnderstandButton.Frame)
	AS:SkinButton(Tongues.UI.MainMenu.HearButton.Frame)
	AS:SkinCloseButton(Tongues.UI.MainMenu.CloseButton.Frame)
	AS:SkinDropDownBox(Tongues.UI.MainMenu.Speak.LanguageDropDown.Frame)
	AS:SkinDropDownBox(Tongues.UI.MainMenu.Speak.DialectDropDown.Frame)
	AS:SkinDropDownBox(Tongues.UI.MainMenu.Speak.AffectDropDown.Frame)
	AS:SkinSlideBar(Tongues.UI.MainMenu.Speak.AffectFrequency.Frame)
--	AS:SkinCheckBox(Tongues.UI.MainMenu.Speak.DialectDrift.Frame)
	AS:SkinCheckBox(Tongues.UI.MainMenu.Speak.LanguageLearn.Frame)
	AS:SkinCheckBox(Tongues.UI.MainMenu.Speak.ShapeshiftLanguage.Frame)
	AS:SkinCheckBox(Tongues.UI.MainMenu.Speak.MiniHide.Frame)
--	AS:SkinCheckBox(Tongues.UI.MainMenu.Speak.LoreCompatibility.Frame)
	AS:SkinEditBox(Tongues.UI.MainMenu.Understand.Language.Frame)
	AS:SkinSlideBar(Tongues.UI.MainMenu.Understand.Fluency.Frame)
	AS:SkinButton(Tongues.UI.MainMenu.Understand.UpdateButton.Frame)
	AS:SkinButton(Tongues.UI.MainMenu.Understand.ClearLanguagesButton.Frame)
	AS:SkinButton(Tongues.UI.MainMenu.Understand.ListLanguagesButton.Frame)
	AS:SkinTooltip(Lib_DropDownList1Backdrop)
	AS:SkinDropDownBox(Tongues.UI.MainMenu.Hear.Filter.Frame)
	AS:SkinButton(Tongues.UI.MainMenu.AdvancedButton.Frame)
	AS:SkinCheckBox(Tongues.UI.MainMenu.Translations.Self.Frame)
	AS:SkinCheckBox(Tongues.UI.MainMenu.Translations.Targetted.Frame)
	AS:SkinCheckBox(Tongues.UI.MainMenu.Translations.Party.Frame)
	AS:SkinCheckBox(Tongues.UI.MainMenu.Translations.Guild.Frame)
	AS:SkinCheckBox(Tongues.UI.MainMenu.Translations.Officer.Frame)
	AS:SkinCheckBox(Tongues.UI.MainMenu.Translations.Raid.Frame)
	AS:SkinCheckBox(Tongues.UI.MainMenu.Translations.RaidAlert.Frame)
	AS:SkinCheckBox(Tongues.UI.MainMenu.Translations.Battleground.Frame)
	AS:SkinCheckBox(Tongues.UI.MainMenu.Screen.Self.Frame)
	AS:SkinCheckBox(Tongues.UI.MainMenu.Screen.Targetted.Frame)
	AS:SkinCheckBox(Tongues.UI.MainMenu.Screen.Party.Frame)
	AS:SkinCheckBox(Tongues.UI.MainMenu.Screen.Guild.Frame)
	AS:SkinCheckBox(Tongues.UI.MainMenu.Screen.Officer.Frame)
	AS:SkinCheckBox(Tongues.UI.MainMenu.Screen.Raid.Frame)
	AS:SkinCheckBox(Tongues.UI.MainMenu.Screen.RaidAlert.Frame)
	AS:SkinCheckBox(Tongues.UI.MainMenu.Screen.Battleground.Frame)
	AS:SkinEditBox(Tongues.UI.MainMenu.Translators.TranslatorEditbox.Frame)
	AS:SkinButton(Tongues.UI.MainMenu.Translators.AddTranslatorButton.Frame)
	AS:SkinButton(Tongues.UI.MainMenu.Translators.ClearTranslatorButton.Frame)
	AS:SkinButton(Tongues.UI.MainMenu.Translators.ListTranslatorButton.Frame)
	Tongues.UI.MainMenu.Minimize.Frame:SetPoint("TOPLEFT", Tongues.UI.MainMenu.Frame, 2, -2)
	AS:CreateBackdrop(Tongues.UI.MainMenu.Minimize.Frame)
	AS:SkinTexture(Tongues.UI.MainMenu.Minimize.texture[1])
end

AS:RegisterSkin('Tongues', AS.Tongues)
