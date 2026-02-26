APR.questionDialog = APR:NewModule("QuestionDialog")
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

local routeTriggerPopupFrame

local function EnsureRouteTriggerPopup()
    if routeTriggerPopupFrame then
        return routeTriggerPopupFrame
    end

    local frame = CreateFrame("Frame", "APRRouteTriggerPopup", UIParent, "BackdropTemplate")
    frame:SetSize(420, 250)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -16)
    frame.title:SetWidth(380)
    frame.title:SetWordWrap(true)
    frame.title:SetJustifyH("CENTER")
    frame.title:SetText("APR")

    frame.message = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.message:SetPoint("TOP", frame.title, "BOTTOM", 0, -10)
    frame.message:SetWidth(380)
    frame.message:SetJustifyH("CENTER")
    frame.message:SetText("")
    frame.message:Hide()

    frame.routeButtonContainer = CreateFrame("Frame", nil, frame)
    frame.routeButtonContainer:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", -172, -12)
    frame.routeButtonContainer:SetPoint("TOPRIGHT", frame.title, "BOTTOMRIGHT", 172, -12)
    frame.routeButtonContainer:SetHeight(1)

    frame.routeButtons = {}

    frame.cancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.cancelButton:SetSize(120, 24)
    frame.cancelButton:SetPoint("BOTTOM", frame, "BOTTOM", 65, 12)
    frame.cancelButton:SetText(CANCEL)
    frame.cancelButton:SetScript("OnClick", function()
        frame:Hide()
        if frame.onCancel then
            frame.onCancel()
        end
    end)

    frame.routeSelectionButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.routeSelectionButton:SetSize(120, 24)
    frame.routeSelectionButton:SetPoint("BOTTOM", frame, "BOTTOM", -65, 12)
    frame.routeSelectionButton:SetText(L["ROUTE_SELECTION"])
    if frame.routeSelectionButton.Text then
        frame.routeSelectionButton.Text:SetWidth(104)
        frame.routeSelectionButton.Text:SetWordWrap(true)
        frame.routeSelectionButton.Text:SetJustifyH("CENTER")
    end
    frame.routeSelectionButton:SetScript("OnClick", function()
        frame:Hide()
        if APR and APR.settings and APR.settings.OpenSettings then
            APR.settings:OpenSettings(L["ROUTE"])
        end
    end)

    frame:Hide()
    routeTriggerPopupFrame = frame
    return frame
end

local function EnsureRouteButton(frame, index)
    local button = frame.routeButtons[index]
    if button then
        return button
    end

    button = CreateFrame("Button", nil, frame.routeButtonContainer, "UIPanelButtonTemplate")
    button:SetSize(320, 30)
    button:SetNormalFontObject("GameFontNormalSmall")

    if button.Text then
        button.Text:SetWidth(300)
        button.Text:SetWordWrap(true)
        button.Text:SetJustifyH("CENTER")
    end

    frame.routeButtons[index] = button
    return button
end

---------------------------------------------------------------------------------------
--------------------------- Dialog for some actions xD --------------------------------
---------------------------------------------------------------------------------------
function APR.questionDialog:CreateQuestionPopup(dialogName, text, onAcceptFunction, onCancelFunction, acceptButtonText,
                                                cancelButtonText, hideOnEscape)
    dialogName = dialogName or "QUESTION_DIALOG"
    StaticPopup_Hide(dialogName)

    StaticPopupDialogs[dialogName] = {
        text = text or CONFIRM_CONTINUE,
        button1 = acceptButtonText or ACCEPT or "YES",
        button2 = cancelButtonText or CANCEL or "YES",
        OnAccept = onAcceptFunction,
        OnCancel = onCancelFunction,
        timeout = 0,
        whileDead = true,
        hideOnEscape = hideOnEscape or true,
    }

    StaticPopup_Show(dialogName)
end

function APR.questionDialog:CreateMessagePopup(text, closeButtonText)
    local dialogName = "MESSAGE_DIALOG"
    StaticPopupDialogs[dialogName] = {
        text = text or CONFIRM_CONTINUE,
        button1 = closeButtonText or OKAY or "YES",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    StaticPopup_Show(dialogName)
end

function APR.questionDialog:CreateMandatoryAction(text, onAcceptFunction)
    local dialogName = "MANDATORY_DIALOG"
    StaticPopupDialogs[dialogName] = {
        text = text or CONFIRM_CONTINUE,
        button1 = OKAY or "YES",
        OnAccept = onAcceptFunction,
        timeout = 0,
        whileDead = true,
        hideOnEscape = false,
        showAlert = true,
        notClosableByLogout = true,
        noCancelOnReuse = true,
    }

    StaticPopup_Show(dialogName)
end

function APR.questionDialog:CreateEditBoxPopup(text, closeButtonText, editBoxText)
    local dialogName = "EDITBOX_DIALOG"
    StaticPopupDialogs[dialogName] = {
        text = text or "General Kenobi",
        hasEditBox = 1,
        button1 = closeButtonText or OKAY or "YES",
        OnShow = function(self)
            if editBoxText then
                local box = getglobal(self:GetName() .. "EditBox")
                if box then
                    box:SetWidth(275)
                    box:SetText(editBoxText)
                    box:HighlightText()
                    box:SetFocus()
                end
            end
        end,
        EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    StaticPopup_Show(dialogName)
end

function APR.questionDialog:CreateRouteTriggerPopup(titleText, routes, onRouteSelected, onCancel)
    local frame = EnsureRouteTriggerPopup()
    frame.onCancel = onCancel

    frame.title:SetText(titleText or "APR")
    frame.message:SetText("")
    frame.message:Hide()

    local titleHeight = math.max(20, frame.title:GetStringHeight() or 20)

    local footerButtonHeight = 24
    if frame.routeSelectionButton.Text then
        frame.routeSelectionButton.Text:SetWidth(104)
        frame.routeSelectionButton.Text:SetWordWrap(true)
        frame.routeSelectionButton.Text:SetJustifyH("CENTER")
        local routeSelectionTextHeight = frame.routeSelectionButton.Text:GetStringHeight()
        footerButtonHeight = math.max(24, routeSelectionTextHeight + 10)
    end

    frame.routeSelectionButton:SetHeight(footerButtonHeight)
    frame.cancelButton:SetHeight(footerButtonHeight)
    frame.routeSelectionButton:SetPoint("BOTTOM", frame, "BOTTOM", -65, 12)
    frame.cancelButton:SetPoint("BOTTOM", frame, "BOTTOM", 65, 12)

    local listToFooterGap = 8

    local yOffset = 0
    local routeCount = routes and #routes or 0

    for i = 1, routeCount do
        local route = routes[i]
        local button = EnsureRouteButton(frame, i)
        button:ClearAllPoints()
        button:SetPoint("TOP", frame.routeButtonContainer, "TOP", 0, -yOffset)
        button:SetWidth(320)
        button:SetText(route.label or route.key or ("Route " .. i))

        if button.Text then
            button.Text:SetWidth(300)
            button.Text:SetWordWrap(true)
            local textHeight = button.Text:GetStringHeight()
            button:SetHeight(math.max(30, textHeight + 10))
        else
            button:SetHeight(30)
        end

        button:SetScript("OnClick", function()
            frame:Hide()
            if onRouteSelected then
                onRouteSelected(route)
            end
        end)

        yOffset = yOffset + button:GetHeight()
        if i < routeCount then
            yOffset = yOffset + 6
        end
        button:Show()
    end

    for i = routeCount + 1, #frame.routeButtons do
        frame.routeButtons[i]:Hide()
    end

    frame.routeButtonContainer:SetHeight(math.max(1, yOffset))

    local minFrameHeight = 120
    local baseHeight = 48 + titleHeight + footerButtonHeight + listToFooterGap
    local desiredFrameHeight = baseHeight + yOffset
    frame:SetHeight(math.max(minFrameHeight, desiredFrameHeight))

    frame:Show()
end
