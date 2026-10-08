-- Exercise the real browser/dialog factories with provider adapters, including repeated texture stripping.
-- External primitives model the documented skin operations; visual validation still happens in WoW.
for _, provider in ipairs({"ElvUI", "EllesmereUI"}) do
    for _, loadLate in ipairs({false, true}) do
        ElvUI, EllesmereUI, UISpecialFrames = nil, nil, {}
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
        local recolor, enable
        if provider == "ElvUI" then
            local S = {}
            function S:HandleButton(frame) primitive(frame, "Button"); frame:SetBackdrop({external = true}) end
            function S:HandleScrollBar(frame) primitive(frame, "ScrollBar") end
            function S:HandleEditBox(frame)
                assert(not frame:GetBackdrop(), "Native input border is removed before ElvUI adds its backdrop")
                primitive(frame, "EditBox")
            end
            local E = {media = {rgbvaluecolor = accent, bordercolor = border},
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
        assert(browser.frame.skin == (provider == "ElvUI" and "Panel" or "Shell"))
        assert(dialog.skin == (provider == "ElvUI" and "Panel" or "Shell"))
        if provider == "EllesmereUI" then assert(dialog.skinOptions.noTopBar and browser.frame.skinOptions.noTopBar) end
        assert(browser.prefabs[1].skin == "Button" and browser.search.skin == "EditBox")
        assert(browser.scroll.ScrollBar.skin == "ScrollBar" and dialog.scroll.ScrollBar.skin == "ScrollBar")
        assert(chooseButton.skin == "Button" and chooseButton.scripts.OnClick == chooseClick)
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
        assert(selectedRow and selectedRow.background.fill[2] == accent[2] and selectedRow.background.fill[4] == 0.3)
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
        assert(selectedRow.background.fill[2] == 0.25 and selectedRow.background.fill[4] == 0.3)
        assert(selectedRow.name.textColor[2] == progressColor[2] and selectedRow.progressMarker.fill[2] == progressColor[2],
            "Skin accents cannot change the meaning of a route's progress color")
        assert(browser.legend.items[1].text.textColor[2] == APR:GetThemeStatusColor("routeCompleted")[2])
        assert(env.frames() == frames and env.fonts() == fonts and calls == applied, "Recolor reuses controls and skin hooks")

        local accepted = 0
        local confirmation = APR.UI:ShowConfirmationDialog("Clear routes?", function() accepted = accepted + 1 end)
        assert(confirmation == dialog and confirmation.acceptButton.skin == "Button")
        assert(confirmation.acceptButton:GetFontString().textColor[2] == accent[2])
        confirmation.acceptButton.scripts.OnClick()
        assert(accepted == 1)
        APR.UI:ShowSelectionDialog("Choose again", nil, {{label = "New option"}}, function() accepted = accepted + 1 end)
        dialog.list.active[1].button.scripts.OnClick()
        assert(accepted == 2, "Recycled skinned buttons retain their newly bound action")
    end
end
print("Route browser skins: both providers, early/late/combat application, texture preservation, live accents and dialog actions passed")
