-- Exercise authored associations through the real renderer, row pools and windows.
for _, client in ipairs({ "retail", "forever" }) do
    local env = dofile("tests/lua/route_ui_test_env.lua")
    dofile("APR-Core/utils/Utils.lua")
    function APR:GetGameVersion() return client end
    function strtrim(value) return value:match("^%s*(.-)%s*$") end
    function APR:ShouldHideFrames() return false end
    function APR:GetSnapAnchorFrame() return CurrentStepScreenPanel, 90 end
    function APR:ResolveUIFileAsset(path)
        if not path:find("missing.jpg", 1, true) then return path end
    end
    function APR:RegisterUiSpecialFrame() end
    function APR:AddTooltipLine() end
    function env.methods:SetTexture(value) self.texture = value end
    function env.methods:GetTexture() return self.texture end
    function env.methods:GetTextureFileWidth() return self.fileWidth end
    function env.methods:GetTextureFileHeight() return self.fileHeight end
    local hide = env.methods.Hide
    function env.methods:Hide()
        local shown = self:IsShown()
        hide(self)
        if shown and self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    local profile = APR.settings.profile
    profile.fillersFrame, profile.currentStepScale = {}, 1
    profile.fillersFrameSnapToCurrentStep = false
    APR.PlayerID = "Synthetic player"
    APRData = { [APR.PlayerID] = { BonusSkips = {} } }
    APR.QUEST_STATUS = { COMPLETE = "complete", PROGRESS = "progress" }
    APR.ActiveQuests = {
        [101] = { objectives = { { status = "progress" }, { status = "progress" } } },
        [202] = { objectives = { { status = "progress" } } },
    }
    local completed = {}
    function C_QuestLog.IsQuestFlaggedCompleted(id) return completed[id] or false end
    function APR:GetQuestTextForProgressBar(id, objective) return "Optional " .. id .. ":" .. objective end
    APR.Buff = { RemoveAllBuffIcon = function() end }
    dofile("APR-Core/ui/route/FillersFrame.lua")
    dofile("APR-Core/ui/route/CurrentStepImagePreview.lua")
    dofile("APR-Core/features/questing/StepInstructions.lua")
    local current, fillers, preview = APR.currentStep, APR.fillersFrame, APR.currentStepImagePreview
    current:PreviousNextStepButton()
    preview:ConfigureCurrentStepPreview(CurrentStepFrame_StepHolder, 250)
    local source = {
        Fillers = { [101] = { 1, 2 }, [202] = { 1 } },
        PreviewImages = { "main.jpg" },
        FillerPreviewImages = { [101] = { "optional.jpg", "missing.jpg" }, [202] = { "other.jpg" } },
    }
    local function render(step, details, mainQuest)
        current:BeginContentUpdate()
        current:Reset()
        if details ~= false then
            preview:SetPreviewImages(current, step)
        else
            preview:ClearPreviewImages(current)
        end
        APR.stepHandlers.RenderRequirements(step, details ~= false, 1)
        if mainQuest then current:AddQuestSteps(mainQuest, "Primary objective", 1) end
        current:EndContentUpdate(true)
    end
    local function imageRow(list, quest)
        for _, row in pairs(list) do
            if row.rowKind == "preview" and row.questID == quest then return row end
        end
    end
    render(source)
    local main = imageRow(current.questsList)
    local optional, other = imageRow(current.fillersList, 101), imageRow(current.fillersList, 202)
    assert(main and optional and other and optional ~= main)
    assert(main:GetParent() == CurrentStepFrame_StepHolder and optional:GetParent() == fillers.StepHolder)
    assert(
        #optional.imagePaths == 1 and optional.imagePaths[1] == "Interface\\AddOns\\APR\\APR-Core\\assets\\optional.jpg",
        "Invalid assets are omitted from filler thumbnails"
    )
    local first, second = current.fillersList["101-1"], current.fillersList["101-2"]
    assert(
        optional.layoutOffset == second.layoutOffset + second:GetHeight() and other.layoutOffset > optional.layoutOffset,
        "Each preview follows its quest's objectives"
    )
    assert(optional.backdropColor[4] == 0, "Filler preview rows share the panel background")

    -- Stable refreshes reuse rows and do not tear down enlarged images.
    local optionalButton = optional.previewButtons[1]
    optionalButton.scripts.OnClick(optionalButton)
    local optionalWindow = APRCurrentStepImagePreviewFrame1
    assert(optionalWindow:IsShown() and optionalWindow.previewWindow.previewContainer == optional)
    main.previewButtons[1].scripts.OnClick(main.previewButtons[1])
    local mainWindow = APRCurrentStepImagePreviewFrame2
    local frames, fonts, hides = env.frames(), env.fonts(), optional.hideCount
    for _ = 1, 100 do
        render(source)
    end
    assert(imageRow(current.fillersList, 101) == optional and optional.hideCount == hides)
    assert(env.frames() == frames and env.fonts() == fonts and optionalWindow:IsShown() and mainWindow:IsShown())

    -- Width/aspect updates relayout the filler panel, not the main panel.
    fillers:SetContentWidth(410)
    assert(optional:GetWidth() == 410 and main:GetWidth() == 250)
    local originalWidth = optionalButton:GetWidth()
    optionalButton.previewTexture.fileWidth, optionalButton.previewTexture.fileHeight = 100, 200
    optional.scripts.OnUpdate(optional, 0.05)
    assert(not optional.scripts.OnUpdate and optionalButton:GetWidth() < originalWidth)
    fillers.FrameHeader.MinimizeButton.scripts.OnClick()
    assert(fillers.Frame.collapsed and not fillers.StepHolder:IsShown())
    fillers.FrameHeader.MinimizeButton.scripts.OnClick()
    assert(not fillers.Frame.collapsed and fillers.StepHolder:IsShown())

    APR.ActiveQuests[101].objectives[1].status = "complete"
    render(source)
    assert(
        not current.fillersList["101-1"] and imageRow(current.fillersList, 101) == optional,
        "A quest preview remains while another associated objective is active"
    )
    APR.ActiveQuests[101].objectives[2].status = "complete"
    render(source)
    assert(not imageRow(current.fillersList, 101) and optional.inRowPool and not optionalWindow:IsShown())
    assert(
        mainWindow:IsShown() and not optional.scripts.OnUpdate and not optionalButton.imagePath,
        "Completing a filler releases its preview and window without closing the main preview"
    )

    -- No primary preview must leave the independently owned filler window open.
    source.PreviewImages = nil
    render(source)
    assert(not imageRow(current.questsList) and not mainWindow:IsShown())
    other.previewButtons[1].scripts.OnClick(other.previewButtons[1])
    local otherWindow
    for _, window in ipairs({ APRCurrentStepImagePreviewFrame1, APRCurrentStepImagePreviewFrame2 }) do
        if window.previewWindow and window.previewWindow.previewContainer == other then otherWindow = window end
    end
    render(source)
    assert(otherWindow and otherWindow:IsShown(), "Clearing an absent main preview preserves filler windows")

    -- Completed, skipped, unavailable and hidden fillers never leave an orphan image.
    completed[202] = true
    render(source)
    assert(not next(current.fillersList) and not fillers.Frame:IsShown() and not otherWindow:IsShown())
    completed[202] = nil
    APRData[APR.PlayerID].BonusSkips[202] = true
    render(source)
    assert(not next(current.fillersList))
    APRData[APR.PlayerID].BonusSkips[202] = nil
    APR.ActiveQuests[202] = nil
    render(source)
    assert(not next(current.fillersList))
    APR.ActiveQuests[202] = { objectives = { { status = "progress" } } }
    render(source, false)
    assert(not next(current.fillersList))
    render(source, true, 202)
    assert(not next(current.fillersList), "A primary objective supersedes the filler and its preview")

    -- Combat retirement and reappearance reuse the same plain thumbnail row.
    render(source)
    local reused = imageRow(current.fillersList, 202)
    frames = env.frames()
    env.setCombat(true)
    render({})
    assert(not next(current.fillersList) and reused.inRowPool)
    env.setCombat(false)
    fillers:FlushPendingLayout()
    render(source)
    assert(imageRow(current.fillersList, 202) == reused and env.frames() == frames)
    source.FillerPreviewImages[202] = { "missing.jpg" }
    render(source)
    assert(current.fillersList["202-1"] and not imageRow(current.fillersList, 202))
    source.FillerPreviewImages[202] = { "replacement.jpg" }
    render(source)
    assert(
        imageRow(current.fillersList, 202) == reused
            and reused.previewButtons[1].imagePath == "Interface\\AddOns\\APR\\APR-Core\\assets\\replacement.jpg"
    )
    source.FillerPreviewImages[202] = { "replacement.jpg", "pending.jpg" }
    render(source)
    local pendingRow = imageRow(current.fillersList, 202)
    pendingRow.previewButtons[1].previewTexture.fileWidth = 100
    pendingRow.previewButtons[1].previewTexture.fileHeight = 200
    current:AddQuestSteps(202, "Now the primary objective", 1)
    pendingRow.scripts.OnUpdate(pendingRow, 0.05)
    assert(
        not imageRow(current.fillersList, 202) and pendingRow.inRowPool and not pendingRow.scripts.OnUpdate,
        "Late texture loading safely stops when the last filler becomes a primary objective"
    )
    render({})
end
print(
    "Filler previews: independent panels/windows, active objectives, layout, pooling and combat passed on both clients"
)
