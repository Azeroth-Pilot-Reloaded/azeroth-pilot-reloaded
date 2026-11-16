-- Invented objects only: real note resolution, formatting and pooled guide rows.
for _, client in ipairs({ "retail", "forever" }) do
    local env = dofile("tests/lua/route_ui_test_env.lua")
    APR.GetGameVersion = function() return client end
    local locale = { NOTE_HINT = "Keep |Hitem:94001|hOld label|h for later." }
    local previousLibStub = LibStub
    function LibStub(name, ...)
        if name == "AceLocale-3.0" then return { GetLocale = function() return locale end } end
        return previousLibStub(name, ...)
    end
    dofile("APR-Core/utils/StepUtils.lua")
    dofile("APR-Core/utils/TextStyleUtils.lua")
    local data, requests, reads, timers = {}, {}, 0, {}
    C_Item = {
        GetItemInfo = function(payload)
            reads = reads + 1
            local item = data[payload]
            if item then return item.name, item.link, item.quality, nil, nil, nil, nil, nil, nil, item.icon end
        end,
        RequestLoadItemDataByID = function(id) requests[id] = (requests[id] or 0) + 1 end,
    }
    C_Timer = { NewTimer = function(_, callback)
        local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
        timers[#timers + 1] = timer
        return timer
    end }
    function env.methods:RegisterEvent(event) self.events = self.events or {}; self.events[event] = true end
    function env.methods:UnregisterEvent(event) if self.events then self.events[event] = nil end end
    function env.methods:IsOwned(owner) return self.owner == owner end
    function env.methods:SetHyperlink(link) self.hyperlink = link end
    function env.methods:SetHyperlinksEnabled(enabled) self.hyperlinks = enabled end
    local originalHide, originalShow = env.methods.Hide, env.methods.Show
    function env.methods:Hide()
        local shown = self.shown
        originalHide(self)
        if shown and self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function env.methods:Show()
        local shown = self.shown
        originalShow(self)
        if not shown and self.scripts.OnShow then self.scripts.OnShow(self) end
    end
    local step = APR.currentStep
    local function event(id, success)
        local frame = step.itemTextFrame
        if frame and frame.events.ITEM_DATA_LOAD_RESULT then
            frame.scripts.OnEvent(frame, "ITEM_DATA_LOAD_RESULT", id, success)
        end
    end
    local function flush()
        local batch = timers
        timers = {}
        for _, timer in ipairs(batch) do if not timer.cancelled then timer.callback() end end
    end
    local function add(key, text)
        step:AddExtraLineText(key, text, nil, false)
        return step.questsExtraTextList[key]
    end
    local original = locale.NOTE_HINT
    local raw = APR:ResolveStepText("NOTE_HINT")
    assert(raw == original, "Resolution preserves translation hyperlink markup")
    local row = add("NOTE_1", raw)
    assert(row.font:GetText() == "Keep |cffffffff|Hitem:94001|hOld label|h|r for later.")
    assert(requests[94001] == 1 and row.hyperlinks)
    add("NOTE_1", raw)
    assert(requests[94001] == 1, "An unchanged render cannot issue duplicate requests")
    data["item:94001"] = { name = "Clef inventée", link = "|cff0070dd|Hitem:94001|h[Clef inventée]|h|r", icon = 777 }
    local layouts = 0
    local reorder = step.ReOrderQuestSteps
    function step:ReOrderQuestSteps() layouts = layouts + 1; return reorder(self) end
    for _ = 1, 50 do event(94001, true); event(94999, true) end
    assert(#timers == 1, "Item event bursts share one refresh")
    flush()
    assert(layouts == 1)
    assert(row.font:GetText() == "Keep |T777:0|t |cff0070dd|Hitem:94001|hClef inventée|h|r for later.")
    assert(not step.itemTextFrame.events.ITEM_DATA_LOAD_RESULT, "No idle item listener remains")
    assert(locale.NOTE_HINT == original, "Rendering never rewrites translations")
    -- Native text fields can retain escaped markup when a note is pasted.
    -- Existing custom notes must render without rewriting their saved value.
    local customNote = "Use ||Hitem:94001||hOld label||h; keep || literal."
    local custom = add("CUSTOM_NOTE", APR:ResolveStepText(customNote))
    assert(custom.font:GetText() == "Use |T777:0|t |cff0070dd|Hitem:94001|hClef inventée|h|r; keep || literal.",
        "Complete escaped item links in custom notes must reach native rendering as links")
    assert(custom._rawExtraLineText == customNote, "Custom note data remains intact")
    local before = reads
    local writes = 0
    local setText = env.methods.SetText
    function env.methods:SetText(text)
        if self == row.font then writes = writes + 1 end
        return setText(self, text)
    end
    for _ = 1, 30 do add("NOTE_1", raw) end
    for _ = 1, 30 do step:ReOrderQuestSteps() end
    assert(reads == before, "Layout uses rendered text without native lookups")
    assert(writes == 0, "Unchanged notes do not rewrite the font string")
    row.scripts.OnHyperlinkEnter(row, "item:94001")
    assert(GameTooltip.owner == row and GameTooltip.hyperlink == "item:94001" and GameTooltip:IsShown())
    row.scripts.OnHyperlinkLeave(row)
    assert(not GameTooltip:IsShown())
    row.scripts.OnHyperlinkEnter(row, "spell:94001")
    assert(not GameTooltip:IsShown(), "Only item links open item tooltips")

    local variant = "item:94001:0:0:0:0:0:0:42:90"
    data[variant] = { name = "Variant", quality = 2 }
    ITEM_QUALITY_COLORS = { [2] = { hex = "|cff1eff00" } }
    local formatted = APR.TextStyleUtils:FormatItemLinks("|cffaabbcc|H" .. variant .. "|h[Before]|h|r |Hspell:12|hOther|h")
    assert(formatted == "|cffaabbcc|cff1eff00|H" .. variant .. "|hVariant|h|r|r |Hspell:12|hOther|h")
    data[variant].icon = 781
    local expectedVariant = "|T781:0|t |cff1eff00|H" .. variant .. "|hVariant|h|r"
    assert(APR.TextStyleUtils:FormatItemLinks("|H" .. variant .. "|hBefore|h") == expectedVariant,
        "Native quality markup must appear once, with icon-space-name and no brackets")
    ITEM_QUALITY_COLORS[2].hex = "ff1eff00"
    assert(APR.TextStyleUtils:FormatItemLinks("|H" .. variant .. "|hBefore|h") == expectedVariant,
        "Bare quality hex values remain compatible")
    for _, invalidColor in ipairs({ "", "|c", "bad value", 42, "ff00" }) do
        ITEM_QUALITY_COLORS[2].hex = invalidColor
        assert(APR.TextStyleUtils:FormatItemLinks("|H" .. variant .. "|hBefore|h") ==
            "|T781:0|t |cffffffff|H" .. variant .. "|hVariant|h|r",
            "Missing or invalid colors cannot leak control markup into the note")
    end
    ITEM_QUALITY_COLORS[2].hex = "|cff1eff00"
    data[variant].icon = nil
    assert(APR.TextStyleUtils:FormatItemLinks("||Hitem:94001|hLiteral|h") == "||Hitem:94001|hLiteral|h")
    local mixed = "||Hspell:12||hLiteral spell||h |Hitem:94001||hMixed||h ||Hitem:94001||hIncomplete|h"
    assert(APR.TextStyleUtils:FormatItemLinks(mixed) == mixed,
        "Other escaped links and mixed or incomplete item delimiters stay literal")
    local escapedVariant = "||H" .. variant .. "||hBefore||h"
    assert(APR.TextStyleUtils:FormatItemLinks(escapedVariant) == "|cff1eff00|H" .. variant .. "|hVariant|h|r",
        "Escaped custom links retain the exact variant payload")
    assert(APR.TextStyleUtils:FormatItemLinks("|Hitem:0|hInvalid|h |Hitem:abc|hBad|h |Hitem:44|hunfinished") ==
        "|Hitem:0|hInvalid|h |Hitem:abc|hBad|h |Hitem:44|hunfinished")

    local stale = add("NOTE_2", "|Hitem:94002|hPending|h")
    event(94002, true)
    local oldTimer = timers[1]
    step:ReleaseRow(step.questsExtraTextList, "NOTE_2")
    local replacement = add("NOTE_3", "Replacement")
    assert(replacement == stale, "The fixture must reuse the retired row")
    oldTimer.callback() -- A native callback already queued at cancellation is harmless.
    assert(replacement.font:GetText() == "Replacement" and oldTimer.cancelled)
    flush()

    local hidden = add("NOTE_4", "|Hitem:94003|hAwaited|h")
    hidden:Hide()
    assert(not step.itemTextFrame.events.ITEM_DATA_LOAD_RESULT)
    data["item:94003"] = { name = "Available after hide", icon = 778 }
    hidden:Show()
    assert(hidden.font:GetText():find("Available after hide", 1, true))

    local failed = add("NOTE_5", "|Hitem:94004|hMissing object|h")
    event(94004, false); flush()
    assert(failed.font:GetText() == "|cffffffff|Hitem:94004|hMissing object|h|r")
    assert(not step.itemTextFrame.events.ITEM_DATA_LOAD_RESULT)
    add("NOTE_5", "|Hitem:94004|hMissing object|h")
    assert(requests[94004] == 1, "Failed data keeps a readable fallback without a retry loop")

    local pasted = add("CUSTOM_PENDING", "Collect ||Hitem:94012||hUnknown name||h.")
    assert(pasted.font:GetText() == "Collect |cffffffff|Hitem:94012|hUnknown name|h|r.")
    assert(requests[94012] == 1)
    data["item:94012"] = { name = "Loaded pasted object", icon = 780 }
    event(94012, true); flush()
    assert(pasted.font:GetText() == "Collect |T780:0|t |cffffffff|Hitem:94012|hLoaded pasted object|h|r.",
        "Pasted links participate in the same deferred data lifecycle")
    pasted.scripts.OnHyperlinkEnter(pasted, "item:94012")
    assert(GameTooltip.hyperlink == "item:94012" and GameTooltip:IsShown())
    pasted.scripts.OnHyperlinkLeave(pasted)

    local changed = add("NOTE_CHANGE", "|Hitem:94008|hOld demand|h")
    add("NOTE_CHANGE", "|Hitem:94009|hNew demand|h")
    event(94008, true); flush()
    assert(not changed.font:GetText():find("Old demand", 1, true), "An old item cannot restore replaced text")
    data["item:94009"] = { name = "New binding" }
    event(94009, true); flush()
    assert(changed.font:GetText():find("New binding", 1, true))

    local sharedA = add("SHARED_A", "|Hitem:94010|hFirst|h")
    local sharedB = add("SHARED_B", "|Hitem:94010|hSecond|h and |Hitem:94011|hThird|h")
    assert(requests[94010] == 1 and requests[94011] == 1, "Rows share native requests by item ID")
    data["item:94010"] = { name = "Shared" }
    event(94010, true); flush()
    assert(sharedA.font:GetText():find("Shared", 1, true) and sharedB.font:GetText():find("Shared", 1, true))
    assert(step.itemTextFrame.events.ITEM_DATA_LOAD_RESULT, "Another item in the same note is still pending")
    data["item:94011"] = { name = "Last" }
    event(94011, true)
    local liveTimer = timers[1]
    oldTimer.callback()
    assert(not liveTimer.cancelled, "A retired callback cannot cancel current work")
    flush()
    assert(sharedB.font:GetText():find("Last", 1, true))
    assert(not step.itemTextFrame.events.ITEM_DATA_LOAD_RESULT)

    local combat = add("NOTE_6", "|Hitem:94005|hCombat pending|h")
    combat.secure, combat.hasSecureControls = true, true
    local anchors = combat.anchors
    env.setCombat(true)
    data["item:94005"] = { name = "Combat ready", icon = 779 }
    event(94005, true); flush()
    assert(combat.font:GetText():find("Combat ready", 1, true))
    assert(combat.anchors == anchors, "Late item data cannot reposition a secure row during combat")
    step:ReleaseRow(step.questsExtraTextList, "NOTE_6")
    assert(combat.hiddenInCombat, "Secure row retirement uses the existing combat deferral")
    GameTooltip:Hide()
    combat.scripts.OnHyperlinkEnter(combat, "item:94005")
    assert(not GameTooltip:IsShown(), "A combat-retired row cannot open a ghost tooltip")
    env.setCombat(false)
    step:RemoveQuestStepsAndExtraLineTexts()
    assert(not step.itemTextFrame.events.ITEM_DATA_LOAD_RESULT)

    -- Older/partial hosts retain the standard hyperlink and readable label.
    local getInfo = C_Item.GetItemInfo
    C_Item = nil; GetItemInfo = getInfo
    assert(APR.TextStyleUtils:FormatItemLinks("|Hitem:94003|hOld|h"):find("Available after hide", 1, true))
    GetItemInfo = nil
    assert(APR.TextStyleUtils:FormatItemLinks("|Hitem:94007|hUnavailable|h") == "|cffffffff|Hitem:94007|hUnavailable|h|r")
end
print("Note item links: localized display, payloads, tooltips, async lifecycle and combat passed")
