APR.currentStepImagePreview = APR:NewModule("CurrentStepImagePreview")

local _G = _G

local overlayFrame = nil
local overlayPanel = nil
local overlayTexture = nil

local function EnsureOverlayFrame()
    if overlayFrame then
        return
    end

    overlayFrame = CreateFrame("Frame", "APRCurrentStepImagePreviewFrame", UIParent, "BackdropTemplate")
    overlayFrame:SetAllPoints(UIParent)
    overlayFrame:SetFrameStrata("DIALOG")
    overlayFrame:SetFrameLevel(800)
    overlayFrame:EnableMouse(true)
    overlayFrame:Hide()
    overlayFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 16,
    })
    overlayFrame:SetBackdropColor(0, 0, 0, 0.82)

    overlayPanel = CreateFrame("Frame", nil, overlayFrame, "BackdropTemplate")
    overlayPanel:SetSize(720, 430)
    overlayPanel:SetPoint("CENTER", overlayFrame, "CENTER", 0, 0)
    overlayPanel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    overlayPanel:SetBackdropColor(0.04, 0.04, 0.04, 0.96)
    overlayPanel:EnableMouse(true)
    overlayPanel:SetScript("OnMouseDown", function()
        -- Consume clicks so clicks on the panel do not close the overlay.
    end)

    overlayTexture = overlayPanel:CreateTexture(nil, "ARTWORK")
    overlayTexture:SetPoint("TOPLEFT", overlayPanel, "TOPLEFT", 12, -12)
    overlayTexture:SetPoint("BOTTOMRIGHT", overlayPanel, "BOTTOMRIGHT", -12, 12)
    overlayTexture:SetTexCoord(0, 1, 0, 1)

    local closeButton = CreateFrame("Button", nil, overlayPanel, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", overlayPanel, "TOPRIGHT", 2, 2)

    overlayFrame:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            overlayFrame:Hide()
        end
    end)

    APR:RegisterUiSpecialFrame("APRCurrentStepImagePreviewFrame")
end

function APR.currentStepImagePreview:Show(imagePath)
    if not imagePath then
        return
    end

    EnsureOverlayFrame()

    if not overlayTexture then
        return
    end

    overlayTexture:SetTexture(imagePath)
    if not overlayTexture:GetTexture() then
        return
    end

    if overlayFrame then
        overlayFrame:Show()
    end
end
