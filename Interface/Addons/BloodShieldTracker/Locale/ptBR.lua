local L = LibStub("AceLocale-3.0"):NewLocale("BloodShieldTracker", "ptBR", false)

if not L then return end

L["Absorbed/Total Shields/Percent:"] = "Absorvido/Escudos Totais/Percentagem:"
L["Appearance"] = "Aparência"
L["Applied Sound"] = "Som Aplicado"
L["AppliedSoundDesc"] = "O som a tocar quando um Escudo de Sangue é aplicada."
L["Bar Color"] = "Cor da Barra"
L["Bar Depleted Color"] = "Cor da Barra Esgotada"
L["BarColor_OptionDesc"] = "Alterar a cor da barra"
L["BarHeight_Desc"] = "Alterar a altura da barra."
L["BarTextColor_OptionDesc"] = "Altera a cor do texto na barra."
L["BarTexture_OptionDesc"] = "Textura a usar na barra"
L["BarWidth_Desc"] = "Alterar a largura da barra."
L["Blizzard"] = true
L["Blood Shield"] = "Escudo de Sangue"
L["Blood Shield Bar"] = "Barra do Escudo de Sangue"
L["Blood Shield bar height"] = "Altura da barra do Escudo de Sangue"
L["Blood Shield bar width"] = "Largura da barra do Escudo de Sangue"
L["Blood Shield Data"] = "Dados do Escudo de Sangue"
L["Blood Shield Max Value"] = "Valor Máximo do Escudo de Sangue"
L["Blood Shield Usage"] = "Uso do Escudo de Sangue"
L["BloodShieldBar_Desc"] = "A Barra do Escudo de Sangue é exibida toda vez que um Escudo de Sangue está presente no Cavaleiro da Morte. A barra irá calcular o valor inicial, máximo do escudo e rastreará o valor restante do escudo baseado em ataques absorvidos que estão por vir. Quando o escudo é removido do Cavaleiro da Morte, a barra é removida."
L["BloodShieldBarColor_OptionDesc"] = "Alterar a cor da barra do Escudo de Sangue"
L["BloodShieldBarTextColor_OptionDesc"] = "Alterar a cor do texto na barra do Escudo de Sangue"
L["BloodShieldDepletedBarColor_OptionDesc"] = "Muda a cor de esgotada da Barra de Escudo. Isso mudará que cor é mostrada para a parte da barra que não estiver cheia."
L["BloodShieldTracker_Desc"] = "Blood Shield Tracker é um addon para tanques Cavaleiro da Morte de Sangue. Ele fornece uma barra para rastrear o Escudo de Sangue e uma barra para rastrear a cura estimada do Golpe da Morte."
L["Change the height of the blood shield bar."] = "Alterar a altura da barra do Escudo de Sangue"
L["Change the height of the estimated healing bar."] = "Alterar a altura da barra de Cura Estimada"
L["Change the width of the blood shield bar."] = "Alterar a largura da barra do Escudo de Sangue"
L["Change the width of the estimated healing bar."] = "Alterar a largura da barra de Cura Estimada"
L["Colors"] = "Cores"
L["Colors for Minimum Heal"] = "Cores para Cura Mínima"
L["Colors for Optimal Heal"] = "Aparência"
L["Config Mode"] = "Modo de Configuração"
L["Could not determine talents."] = "Não pôde determinar talentos."
L["Current and Maximum"] = "Atual e Máximo"
L["Current Value"] = "Valor Atual"
L["Death Strike"] = "Golpe da Morte"
L["Death Strike Heal"] = "Cura do Golpe da Morte"
L["Dimensions"] = "Dimensões"
L["Enable the Blood Shield Bar."] = "Ativar a Barra do Escudo de Sangue"
L["Enable the Estimated Healing Bar."] = "Ativar Barra de Cura Estimada"
L["EnableBarDesc"] = "Ativar a barra."
L["Enabled"] = "Ativado"
L["EstHealBarMinBackgroundColor_OptionDesc"] = "Muda a cor de fundo da Barra de Cura Estimada para curas mínimas do Golpe da Morte."
L["EstHealBarMinColor_OptionDesc"] = "Alterar a cor da Barra de Cura Estimada para as curas mínimas com Golpe da Morte"
L["EstHealBarMinTextColor_OptionDesc"] = "Alterar a cor do texto na Barra de Cura Estimada para as curas mínimas com Golpe da Morte"
L["EstHealBarOptColor_OptionDesc"] = "Mudar a cor da Barra de Cura Estimada para curas ideais do Golpe da Morte(ou seja, maiores que o mínimo)"
L["EstHealBarOptTextColor_OptionDesc"] = "Mudar a cor do texto da Barra de Cura Estimada para curas ideais do Golpe da Morte(ou seja, maiores que o mínimo)"
L["EstHealBarShowText_OptDesc"] = "Ativar mostrar o texto na barra de cura estimada. Se o texto não for mostrado, apenas a cura estimada aparecerá."
L["EstimateBarBSText"] = "EdS. Est"
L["Estimated Healing Bar"] = "Barra de Cura Estimada"
L["Estimated Healing bar height"] = "Altura da barra de Cura Estimada"
L["Estimated Healing bar width"] = "Largura da barra de Cura Estimada"
L["EstimatedHealingBar_Desc"] = "A Barra de Cura Estimada fornece uma estimativa do tamanho da cura do Golpe da Morte se o Golpe da Morte for usado naquele momente. Se a cura for do valor mínimo(ou seja, 10% dos pontos de vida máximos), então a barra é vermelha por padrão. Se a cura for maior que o mínimo, uma cura ideal, então a barra fica verde por padrão. Você pode usar estas duas cores para saber quando é a melhor hora de usar Golpe da Morte. Você pode configurar as cores de ambos estados abaixo."
L["Fight Duration:"] = "Duração da Luta:"
L["Fixed"] = "Consertado"
L["Font"] = "Fonte"
L["Font size"] = "Tamanho da Fonte"
L["Font size for the bars."] = "Tamanha da fonte para as barras"
L["Font to use for this panel."] = "Fonte para usar neste painel"
L["Font to use."] = "Fonte a usar."
L["FontMonochrome_OptionDesc"] = "Ativar se a fonte está sendo renderizada sem antisserrilhamento."
L["FontOutline_OptionDesc"] = "Ativar se um contorno escuro está aparecendo ao redor da fonte."
L["FontThickOutline_OptionDesc"] = "Ativar se a fonte está aparecendo com um contorno escuro grosso."
L["Full"] = "Completo"
L["General Options"] = "Opções Gerais"
L["HealBarText"] = "Cura Est."
L["Height"] = "Altura"
L["Hide out of combat"] = "Esconder fora de combate"
L["HideOOC_OptionDesc"] = "Esconder a Barra de Cura Estimada quando fora de combate"
L["IllumBar_Desc"] = "A Barra da Cura Iluminada mostra o total de todos os escudos da Cura Iluminada atualmente no jogador. Cura Iluminada é o escudo fornecido por Paladinos Sagrados."
L["Illuminated Healing Bar"] = "Barra da Cura Iluminada"
L["Last Fight Data"] = "Dados da Última Luta"
L["Latency"] = "Latência"
L["Left"] = "Esquerda"
L["Lock bar"] = "Travar barra"
L["Lock damage bar"] = "Trava a barra de dano"
L["Lock estimated healing bar"] = "Trava a barra de cura estimada"
L["Lock shield bar"] = "Trava a barra de escudo"
L["Lock status bar"] = "Trava a barra de status"
L["Lock the damage bar from moving."] = "Impede a barra de dano de se mover"
L["Lock the estimated healing bar from moving."] = "Impede a barra de cura estimada de se mover"
L["Lock the shield bar from moving."] = "Impede a barra de escudo de se mover"
L["Lock the status bar from moving."] = "Impede a barra de status de se mover"
L["LockBarDesc"] = "Impossibilita a barra de se mover."
L["Min - Max / Avg:"] = "Mín - Máx / Média:"
L["Minimap Button"] = "Botão do Minimapa"
L["Minimum Bar Background Color"] = "Cor de Fundo da Barra Mínima"
L["Minimum Bar Color"] = "Cor da Barra Mínima"
L["Minimum Text Color"] = "Cor de Texto Mínima"
L["Mode"] = "Modo"
L["Monochrome"] = "Monocromático"
L["None"] = "Nenhum"
L["Number of Minimum Shields:"] = "Número de Escudos Mínimos:"
L["Only Current"] = "Apenas Atual"
L["Only for Blood DK"] = "Apenas para CdM de Sangue."
L["Only Maximum"] = "Apenas Máximo"
L["Only Percent"] = "Apenas Percentagem"
L["OnlyForBlood_OptionDesc"] = "Ative se o addon está apenas ativado para CdM de Sangue ou se está ativado para qualquer CdM. A Barra de Cura Estimada ainda funcionará para CdM que não são de Sangue, se isto estiver marcado para falso."
L["Optimal Bar Color"] = "Cor da Barra Ideal"
L["Optimal Text Color"] = "Cor de Texto Ideal"
L["Outline"] = "Contorno"
L["Position"] = "Posição"
L["Progress Bar"] = "Barra de Progresso"
L["PW:S Bar"] = "Barra da Palavra de Poder: Escudo"
L["PWSBar_Desc"] = "Quando ativado, rastreia o valor da Palavra de Poder: Escudo atual no jogador."
L["Removed Sound"] = "Som Removido"
L["RemovedSoundDesc"] = "O som a tocar quando um Escudo de Sangue é removido."
L["Right"] = "Direita"
L["Scale"] = "Escala"
L["ScaleDesc"] = "Determina a escala da barra"
L["seconds"] = "segundos"
L["Shield Frequency:"] = "Frequência do Escudo:"
L["ShieldProgress_OptionDesc"] = "Estabelece o que a barra de progresso da Barra do Escudo de Sangue rastreia. Pode ser acertado para o tempo restante do Escudo de Sangue, o valor atual do Escudo de Sangue, ou nada se a barra não tiver que mudar."
L["Shields Total/Refreshed/Removed:"] = "Total dos Escudos/Atualizado/Removido:"
L["ShieldSoundEnabledDesc"] = "Ativar o toque de sons para o Escudo de Sangue"
L["ShieldTextFormat_OptionDesc"] = "Especifica o formato do texto na barra de escudo."
L["Shift + Left-Click to reset."] = "Shift + Botão-Esquerdo do Mouse para resetar."
L["Show Text"] = "Mostrar Texto"
L["Show Time"] = "Mostrar Tempo"
L["ShowBar"] = "Mostrar fundo"
L["ShowBarDesc"] = "Mostrar a barra e a borda, quando desativado apenas o texto aparecerá"
L["ShowBorder"] = "Mostrar Borda"
L["ShowBorderDesc"] = "Mostrar a borda ao redor da barra."
L["ShowTime_OptionDesc"] = "Ative se o tempo restante estiver sendo mostrado na barra."
L["Sound"] = "Som"
L["StatusBarTexture"] = "Textura da BarradeStatus"
L["Text Color"] = "Cor do Texto"
L["Text Format"] = "Formato do Texto"
L["Texture"] = "Textura"
L["Thick Outline"] = "Contorno Grosso"
L["Time Remaining"] = "Tempo Restante"
L["TimePosition_OptionDesc"] = "Posição da barra para mostrar o tempo restante."
L["Toggle config mode"] = "Ativa modo de configuração"
L["Toggle the minimap button"] = "Ativa Botão do Minimapa"
L["Toggles the display of informational messages"] = "Ativa a exibição de mensagens informativas"
L["Total Data"] = "Dados Totais"
L["Usage Min - Max / Avg:"] = "Uso Mín- Máx / Média:"
L["Use Aura"] = "Usar Aura"
L["UseAura_OptionDesc"] = "Ativar se a Barra de Escudo de Sangue usa a aura ou os dados do registro de combate."
L["Width"] = "Largura"

