-- Exercise the real browser/dialog factories with provider adapters, including repeated texture stripping.
-- External primitives model the documented skin operations; visual validation still happens in WoW.
for _, provider in ipairs({"ElvUI", "EllesmereUI"}) do
    for _, loadLate in ipairs({false, true}) do
        ElvUI, EllesmereUI, EllesmereUIQuestTracker, UISpecialFrames = nil, nil, nil, {}
        local env = dofile("tests/lua/route_browser_test_env.lua")
        local methods = env.methods
        local createTexture = methods.CreateTexture
        function methods:CreateTexture(...)
            local texture = createTexture(self, ...)
            self.regions = self.regions or {}
            self.regions[#self.regions + 1] = texture
            return texture
        end
        function methods:SetTexture(path) self.texture = path end
        function methods:SetVertexColor(...) self.vertex = {...} end
        function methods:SetColorTexture(...) self.fill = {...} end
        function methods:SetTextColor(...) self.textColor = {...} end
        function methods:SetFont(path, size, flags) self.font, self.fontSize, self.flags = path, size, flags; return true end
        function methods:GetFont() return self.font or "native.ttf", self.fontSize or 12, self.flags or "" end
        function methods:SetTemplate(template)
            assert(not InCombatLockdown())
            self:SetBackdrop({external = template})
            self.skin = "Panel"
        end
        function methods:StripTextures()
            for _, texture in ipairs(self.regions or {}) do texture:SetAlpha(0) end
        end
        function hooksecurefunc(target, method, callback)
            local original = target[method]
            target[method] = function(...) original(...); callback(...) end
        end
        local originalLibStub = LibStub
        function LibStub(name)
            if name == "LibSharedMedia-3.0" then
                return {GetDefault = function() return "Native" end, Fetch = function() return "native.ttf" end}
            end
            return originalLibStub(name)
        end
        function APR:ResolveUIFileAsset(path) return path end
        dofile("APR-Core/ui/foundations/TextStyles.lua")
        -- This fixture owns the browser; gameplay-panel relayout has separate integration coverage.
        APR.RefreshTextAppearance = APR.ApplyAllTextStyles

        local calls, stripped = 0, {}
        local function primitive(frame, kind, options)
            assert(not InCombatLockdown(), "Skin operations wait until combat ends")
            calls = calls + 1
            frame.skin, frame.skinOptions = kind, options
            frame:StripTextures()
            stripped[frame] = true
        end
        local accent, border = {0.15, 0.7, 0.9, 1}, {0.2, 0.2, 0.2, 1}
        local background = {0.11, 0.12, 0.13, 0.9}
        APR.settings.profile.uiThemeCustomization = {customColor = true, color = {0.8, 0.2, 0.4, 1}, radius = 16, rounded = true}
        local recolor, enable
        if provider == "ElvUI" then
            local S = {}
            function S:HandleButton(frame) primitive(frame, "Button"); frame:SetBackdrop({external = true}) end
            function S:HandleScrollBar(frame) primitive(frame, "ScrollBar") end
            function S:HandleEditBox(frame)
                assert(not frame:GetBackdrop(), "Native input border is removed before ElvUI adds its backdrop")
                primitive(frame, "EditBox")
            end
            local E = {media = {rgbvaluecolor = accent, bordercolor = border, backdropcolor = background, backdropfadecolor = background},
                GetModule = function() return S end, UpdateMedia = function() end}
            ElvUI = {E}
            dofile("APR-Core/integrations/ElvUISkin.lua")
            enable = function() APR.ElvUISkin:OnEnable() end
            recolor = function() E:UpdateMedia() end
        else
            local callback, looksChanged
            EllesmereUI = {RegisterSkin = function(_, fn) callback = fn end}
            local S = {IsEnabled = function() return true end,
                GetAccentColor = function() return unpack(accent) end,
                GetPanelColor = function() return unpack(background) end,
                GetFont = function() return "eui.ttf", "OUTLINE" end,
                OnLooksChanged = function(fn) looksChanged = fn end}
            for _, kind in ipairs({"Shell", "Panel", "Button", "EditBox", "ScrollBar"}) do
                local name = kind
                S[name] = function(frame, options)
                    assert(not frame:GetBackdrop(), "EUI replaces native window, panel, button and input art")
                    primitive(frame, name, options)
                end
            end
            function S.Font(font) font:SetFont("eui.ttf", font.fontSize or 12, "OUTLINE") end
            function S.FadeRegions(frame) frame:StripTextures() end
            dofile("APR-Core/integrations/EllesmereUISkin.lua")
            enable = function() callback(S) end
            recolor = function() looksChanged() end
        end

        local browser = APR.RouteBrowser
        APRData.test.first = 4
        APRZoneCompleted.test["Older route"] = true
        if not loadLate then enable() end
        browser:Show()
        browser.category.scripts.OnClick()
        local dialog = APR.UI:ShowSelectionDialog("Choose an expansion", "Description", {
            {label = "Available"}, {label = "Locked", enabled = false},
        }, function() end)
        local chooseButton = dialog.list.active[1].button
        local chooseClick = chooseButton.scripts.OnClick
        local lockedButton = dialog.list.active[2].button
        if loadLate then
            env.setCombat(true)
            enable()
            assert(APR:AreSkinsPending() and not browser.prefabs[1].skin)
            env.setCombat(false)
            APR:RefreshRegisteredSkins()
        end
        assert(APR:GetSkinProviderName() == provider)
        assert(APR:GetThemeStyle() == "modern" and browser.frame.backdrop.edgeSize == 1 and dialog.backdrop.edgeSize == 1,
            "External providers reuse Modern surfaces with square corners")
        assert(browser.frame.backdropColor[1] == background[1] and dialog.backdropColor[2] == background[2]
            and APR:GetThemeRadius(8) == 0, "Provider backgrounds and square corners override APR custom accents/radius")
        assert(browser.prefabs[1].backdrop.edgeSize == 1
            and browser.search.backdrop.edgeSize == 1)
        local guideHeader = CreateFrame("Frame", nil, CurrentStepScreenPanel)
        guideHeader.Background = guideHeader:CreateTexture()
        guideHeader:SetPoint("BOTTOM", CurrentStepScreenPanel, "TOP", 0, -1)
        guideHeader.Text = APR.UI:Label(guideHeader, "Guide", 14, "accent", "currentStep")
        APR:RegisterSkinTarget(guideHeader, "header")
        local providerBorder = APR:GetThemeColor("border", "currentStep")
        local chrome = guideHeader.aprModernHeader
        assert(chrome.backdrop.edgeSize == 1 and not chrome.marker:IsShown())
        if provider == "EllesmereUI" then
            assert(chrome.line.fill[2] == accent[2] and chrome.line.point[1] == "BOTTOMRIGHT"
                and chrome.borderColor[4] == 0 and chrome.backdropColor[1] == 0.035 and chrome.backdropColor[4] == 0.75,
                "EUI gameplay headers above the body retain their own tracker fill and accent underline without borders")
        else
            assert(chrome.line.fill[2] == providerBorder[2] and chrome.borderColor[2] == providerBorder[2]
                and chrome.borderColor[4] == 1, "ElvUI retains its neutral header border")
        end
        local divider = CreateFrame("Frame", nil, CurrentStepScreenPanel, "BackdropTemplate")
        divider.rowKind = "divider"
        divider.dividerLine = divider:CreateTexture()
        divider.dividerLine:SetVertexColor(0.78, 0.66, 0.35, 0.95)
        APR:RegisterSkinTarget(divider, "row")
        assert(divider.dividerLine.vertex[2] == providerBorder[2],
            "A divider registered as a pooled row cannot keep native gold under an external skin")
        local body = CreateFrame("Frame", nil, CurrentStepScreenPanel, "BackdropTemplate")
        APR:RegisterSkinTarget(body, "panel", {roundedGameplay = true})
        APR:SetPanelColor(body, {0, 0, 0, 0.4})
        local gameplayBackground = APR:GetThemeColor("background", "currentStep")
        assert(body.backdropColor[4] == gameplayBackground[4], "Untouched gameplay opacity adopts the provider fill")
        if provider == "EllesmereUI" then
            assert(gameplayBackground[1] == 0.035 and gameplayBackground[4] == 0.75 and body.borderColor[4] == 0,
                "EUI gameplay uses the borderless quest tracker fill, not the window shell")
        end
        APR:SetPanelColor(body, {0, 0, 0, 0.6})
        assert(body.backdropColor[4] == 0.6, "Explicit opacity remains adjustable")
        APR:SetPanelColor(body, {0, 0, 0, 0})
        assert(body.backdropColor[4] == 0 and body.borderColor[4] == 0, "Collapsed fills and borders remain invisible")
        assert(chooseButton.aprListRow and chooseButton.scripts.OnClick == chooseClick,
            "Choice rows retain their MDI list chrome and original callback under external skins")
        assert(not lockedButton:IsEnabled(), "Skinning cannot unlock a restricted expansion")
        assert(not dialog.close.skin and not browser.list.active[1].add.skin, "MDI actions remain borderless")

        -- The engine can re-fade directly owned textures long after the initial skin pass.
        for frame in pairs(stripped) do frame:StripTextures() end
        for _, texture in ipairs({browser.frame.logo, browser.frame.headerLine, browser.headerBand,
            browser.search.searchIcon, browser.category.arrow, browser.favorites.icon, dialog.close.icon}) do
            assert(texture.alpha ~= 0, "Functional art must survive EUI's texture refresh")
        end
        assert(browser.frame.logo.vertex[1] == 1 and browser.frame.logo.vertex[2] == 1, "Logo keeps its original colors")
        assert(dialog.title.textColor[2] == accent[2] and dialog.close.icon.vertex[2] == accent[2])

        browser.selectedKey = "first"
        browser:Refresh()
        local selectedRow
        for _, row in pairs(browser.list.active) do if row.item.key == "first" then selectedRow = row end end
        assert(selectedRow and selectedRow.aprListRow.background.backdropColor[2] == accent[2]
            and selectedRow.aprListRow.background.backdropColor[4] == 0.13)
        local progressColor = APR:GetThemeStatusColor("routeInProgress")
        assert(selectedRow.name.textColor[3] == progressColor[3] and selectedRow.progressMarker.fill[3] == progressColor[3])
        local frames, fonts, applied = env.frames(), env.fonts(), calls
        accent[1], accent[2] = 0.9, 0.25
        env.setCombat(true)
        recolor()
        assert(dialog.close.icon.vertex[2] == 0.7, "Theme refresh is deferred during combat")
        env.setCombat(false)
        recolor()
        assert(dialog.close.icon.vertex[2] == 0.25 and dialog.title.textColor[2] == 0.25)
        if provider == "EllesmereUI" then
            assert(chrome.line.fill[2] == 0.25 and chrome.borderColor[4] == 0 and chrome.backdropColor[4] == 0.75,
                "Live EUI accent refresh preserves the underline and visible header background")
        end
        assert(selectedRow.aprListRow.background.backdropColor[2] == 0.25
            and selectedRow.aprListRow.background.backdropColor[4] == 0.13)
        assert(selectedRow.name.textColor[2] == progressColor[2] and selectedRow.progressMarker.fill[2] == progressColor[2],
            "Skin accents cannot change the meaning of a route's progress color")
        assert(browser.legend.items[1].text.textColor[2] == APR:GetThemeStatusColor("routeCompleted")[2])
        assert(env.frames() == frames and env.fonts() == fonts and calls == applied, "Recolor reuses controls and skin hooks")

        if provider == "EllesmereUI" then
            for _, name in ipairs({"FillersScreenPanel", "QuestOrderListPanel", "AfkFrameScreen", "PartyScreenPanel",
                "BuffFrameScreen", "HeirloomPanel", "CoordinateScreenPanel"}) do
                local root = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
                APR:RegisterSkinTarget(root, "panel")
                APR:SetPanelColor(root, {0, 0, 0, 0.4})
                local sectionHeader = CreateFrame("Frame", nil, root)
                sectionHeader:SetPoint("BOTTOM", root, "TOP", 0, 0)
                APR:RegisterSkinTarget(sectionHeader, "header")
                local look = sectionHeader.aprModernHeader
                assert(root.backdropColor[1] == 0.035 and root.backdropColor[4] == 0.75 and root.borderColor[4] == 0
                    and look.backdropColor[1] == root.backdropColor[1]
                    and look.backdropColor[4] == root.backdropColor[4] and look.borderColor[4] == 0
                    and look.line.fill[2] == accent[2] and look.line.point[1] == "BOTTOMRIGHT",
                    "Every small EUI gameplay panel uses the tracker fill and accent underline")
                root.collapsed = true
                APR:SetPanelColor(root, {0, 0, 0, 0})
                APR:RefreshThemeRegions()
                assert(root.backdropColor[4] == 0 and look.backdropColor[4] == 0.75 and look.borderColor[4] == 0,
                    "Collapsing the body leaves the independently positioned header background visible")
            end
            local trackerConfig = {bgR = 0.04, bgG = 0.05, bgB = 0.06, bgAlpha = 0.65}
            EllesmereUIQuestTracker = {DB = function() return trackerConfig end, ApplyBackground = function() end}
            recolor() -- Install the optional tracker's background hook.
            APR:SetPanelColor(body, {0, 0, 0, 0.4})
            trackerConfig.bgG, trackerConfig.bgAlpha = 0.08, 0.55
            EllesmereUIQuestTracker.ApplyBackground()
            assert(body.backdropColor[2] == 0.08 and body.backdropColor[4] == 0.55 and body.borderColor[4] == 0
                and chrome.backdropColor[2] == 0.08 and chrome.backdropColor[4] == 0.55 and chrome.line.fill[2] == accent[2],
                "EUI tracker background changes refresh both the APR body and its header live")
            APR:SetPanelColor(body, {0, 0, 0, 0.6})
            trackerConfig.bgAlpha = 0
            EllesmereUIQuestTracker.ApplyBackground()
            assert(body.backdropColor[4] == 0.6, "Explicit APR opacity survives EUI background refresh")
            APR:SetPanelColor(body, {0, 0, 0, 0.4})
            assert(body.backdropColor[4] == 0, "A fully transparent EUI tracker background remains transparent")
            EllesmereUIQuestTracker = nil
        end

        local accepted = 0
        local confirmation = APR.UI:ShowConfirmationDialog("Clear routes?", function() accepted = accepted + 1 end)
        assert(confirmation == dialog and confirmation.acceptButton.backdrop.edgeSize == 1)
        assert(confirmation.acceptButton:GetFontString().textColor[2] == accent[2])
        confirmation.acceptButton.scripts.OnClick()
        assert(accepted == 1)
        APR.UI:ShowSelectionDialog("Choose again", nil, {{label = "New option"}}, function() accepted = accepted + 1 end)
        dialog.list.active[1].button.scripts.OnClick()
        assert(accepted == 2, "Recycled skinned buttons retain their newly bound action")
    end
end
print("Route browser skins: both providers, early/late/combat application, texture preservation, live accents and dialog actions passed")
