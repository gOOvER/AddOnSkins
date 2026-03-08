local AS, _, S, R = unpack(AddOnSkins)
if not AS:CheckAddOn('ElvUI') then return end

local _G = _G

local hooksecurefunc = hooksecurefunc
local UnitAffectingCombat = UnitAffectingCombat

local ES = AS.EmbedSystem

local E, L = unpack(ElvUI)

function AS:UpdateMedia()
	S.Media.Blank = AS.Libs.LSM:Fetch('background', 'ElvUI Blank')
	S.Media.StatusBar = AS.Libs.LSM:Fetch('statusbar', E.private.general.normTex)

	S.Media.defaultBackdrop = E.media.backdropcolor
	S.Media.transparentBackdrop = E.media.backdropfadecolor
	S.Media.borderColor = E.media.bordercolor
	S.Media.valueColor = E.media.rgbvaluecolor

	S.Media.TexCoords = { 0, 1, 0, 1 }
	local modifier = 0.04 * E.db.general.cropIcon
	for i, v in ipairs(S.Media.TexCoords) do
		if i % 2 == 0 then
			S.Media.TexCoords[i] = v - modifier
		else
			S.Media.TexCoords[i] = v + modifier
		end
	end
end

function ES:Hooks()
	if not E then
		E, L = unpack(ElvUI)
	end

	hooksecurefunc(E:GetModule('Chat'), 'PositionChat', function(_, override)
		if override then
			ES:Check()
		end
	end)
	hooksecurefunc(E:GetModule('Layout'), 'ToggleChatPanels', function() ES:Check() end)

	if RightChatToggleButton then
		-- Keep AnyUp consistent with ElvUI's own registration (Layout.lua)
		RightChatToggleButton:RegisterForClicks('AnyUp')
		RightChatToggleButton:SetScript('OnClick', function(s, btn)
			if btn == 'RightButton' then
				if ES.Main:IsShown() then
					AS:SetOption('EmbedIsHidden', true)
				else
					AS:SetOption('EmbedIsHidden', false)
				end

				ES.Main:SetShown(not AS:CheckOption('EmbedIsHidden'))
			else
				local panel = s.parent
				local panelName = panel:GetName()..'Faded'
				if E.db[panelName] then
					E.db[panelName] = nil
					-- E:UIFrameFadeOut preserves panel.FadeObject (incl. finishedFunc = FinishFade)
					-- so the panel shows/hides correctly via ElvUI's own animation system
					panel:Show()
					E:UIFrameFadeOut(panel, 0.2, panel:GetAlpha(), 1)
					E:UIFrameFadeOut(s, 0.2, s:GetAlpha(), 1)
					if not AS:CheckOption('EmbedIsHidden') then
						ES.Main:Show()
					end
				else
					E.db[panelName] = true
					-- FinishFade (in panel.FadeObject) hides the panel when alpha reaches 0
					E:UIFrameFadeOut(panel, 0.2, panel:GetAlpha(), 0)
					E:UIFrameFadeOut(s, 0.2, s:GetAlpha(), 0)
				end
			end
		end)

		RightChatToggleButton:SetScript('OnEnter', function(s)
			local panel = s.parent
			if E.db[panel:GetName()..'Faded'] then
				panel:Show()
				E:UIFrameFadeOut(panel, 0.2, panel:GetAlpha(), 1)
				E:UIFrameFadeOut(s, 0.2, s:GetAlpha(), 1)
				if not AS:CheckOption('EmbedIsHidden') then
					ES.Main:Show()
				end
			end

			-- Use IsForbidden() instead of the removed editboxforced property
			if not _G.GameTooltip:IsForbidden() then
				_G.GameTooltip:SetOwner(s, 'ANCHOR_TOPLEFT', 0, 4)
				_G.GameTooltip:ClearLines()
				_G.GameTooltip:AddDoubleLine(L["Left Click:"], L["Toggle Chat Frame"], 1, 1, 1)
				_G.GameTooltip:AddDoubleLine(L["Right Click:"], L["Toggle Embedded Addon"], 1, 1, 1)
				_G.GameTooltip:Show()
			end
		end)
	end
end

function ES:Resize()
	if UnitAffectingCombat('player') then return end
	local ChatPanel = AS:CheckOption('EmbedRightChat') and _G.RightChatPanel or _G.LeftChatPanel
	local ChatTab = AS:CheckOption('EmbedRightChat') and _G.RightChatTab or _G.LeftChatTab

	ES.Main:SetParent(ChatPanel)
	ES.Main:ClearAllPoints()
	ES.Main:SetPoint('TOPRIGHT', ChatTab, AS:CheckOption('EmbedBelowTop') and 'BOTTOMRIGHT' or 'TOPRIGHT', 0, AS:CheckOption('EmbedBelowTop') and -1 or 0)
	ES.Main:SetPoint('BOTTOMLEFT', ChatPanel, 'BOTTOMLEFT', 0, (E.PixelMode and 0 or -1))

	ES.Left:SetSize(AS:CheckOption('EmbedLeftWidth'), ES.Main:GetHeight())
	ES.Right:SetSize((ES.Main:GetWidth() - AS:CheckOption('EmbedLeftWidth')) - 1, ES.Main:GetHeight())

	ES.Left:SetPoint('LEFT', ES.Main, 'LEFT', 0, 0)
	ES.Left:SetPoint('RIGHT', ES.Right, 'LEFT', 0, 0)
	ES.Right:SetPoint('RIGHT', ES.Main, 'RIGHT', 0, 0)
end
