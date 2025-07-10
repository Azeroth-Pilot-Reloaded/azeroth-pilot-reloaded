local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")

-- Initialize module
APR.Buff = APR:NewModule("Buff")

local FRAME_WIDTH = 250
local FRAME_HEIGHT = 40
local FRAME_OFFSET_DEFAULT = 5
local FRAME_OFFSET = 35
local xOffset = 5
local yOffset = -5

APR.Buff.auras = {}

---------------------------------------------------------------------------------------
----------------------------------- Buff Frames ---------------------------------------
---------------------------------------------------------------------------------------

local BuffFrame = CreateFrame("Frame", "BuffFrameScreen", UIParent, "BackdropTemplate")
BuffFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
BuffFrame:SetFrameStrata("LOW")
BuffFrame:SetClampedToScreen(true)
BuffFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    tile = true,
    tileSize = 16
})
BuffFrame:SetBackdropColor(unpack(APR.Color.defaultBackdrop))

-- Create the body frame
local BuffFrame_body = CreateFrame("Frame", "BuffFrame_body", BuffFrame, "BackdropTemplate")
BuffFrame_body:SetAllPoints()

-- Create the frame header
local BuffFrameHeader = CreateFrame("Frame", "BuffFrameHeader", BuffFrame, "ObjectiveTrackerContainerHeaderTemplate")
BuffFrameHeader:SetPoint("bottom", BuffFrame, "top", 0, -1)
BuffFrameHeader.Text:SetText(L["BUFF"])
BuffFrameHeader.MinimizeButton:Hide()
BuffFrameHeader:SetScript("OnMouseDown", function(self, button)
    self:GetParent():StartMoving()
end)

BuffFrameHeader:SetScript("OnMouseUp", function(self, button)
    self:GetParent():StopMovingOrSizing()
    LibWindow.SavePosition(BuffFrameScreen)
end)



---------------------------------------------------------------------------------------
-------------------------------- Function Buff Frames ---------------------------------
---------------------------------------------------------------------------------------

function APR.Buff:BuffFrameOnInit()
    LibWindow.RegisterConfig(BuffFrameScreen, APR.settings.profile.buffFrame)
    BuffFrameScreen.RegisteredForLibWindow = true
    LibWindow.MakeDraggable(BuffFrameScreen)

    self:SetDefaultDisplay()
    self:RefreshFrameAnchor()
end

function APR.Buff:SetDefaultDisplay()
    BuffFrameScreen:SetPoint("center", UIParent, "center", 0, 0)
    BuffFrame_body:Show()
    BuffFrameHeader:Show()
    self:UpdateBackgroundColorAlpha()
end

function APR.Buff:RefreshFrameAnchor()
    if not APR.settings.profile.enableAddon or C_PetBattles.IsInBattle() or not next(self.auras) then
        BuffFrameScreen:Hide()
        return
    end
    BuffFrameScreen:EnableMouse(true)
    LibWindow.RestorePosition(BuffFrameScreen)
    BuffFrameScreen:Show()
end

function APR.Buff:UpdateBackgroundColorAlpha()
    BuffFrameScreen:SetBackdropColor(unpack(APR.settings.profile.currentStepbackgroundColorAlpha))
end

local function CreateBuffIcon(iconTexture, isDisabled, auraInstanceID, tooltipMessage)
    local icon = CreateFrame("Frame", nil, BuffFrame_body)
    icon:SetSize(30, 30)
    icon:EnableMouse(false)

    local texture = icon:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints(icon)
    texture:SetTexture(iconTexture)
    if isDisabled then
        texture:SetVertexColor(unpack(APR.Color.midGray))
    else
        texture:SetVertexColor(unpack(APR.Color.white))
    end

    icon:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        if not isDisabled and auraInstanceID then
            GameTooltip:SetUnitBuffByAuraInstanceID("player", auraInstanceID)
            GameTooltip:AddLine(L[tooltipMessage], unpack(APR.Color.darkblue))
        else
            GameTooltip:AddLine(L[tooltipMessage], unpack(APR.Color.white))
        end
        GameTooltip:Show()
    end)

    icon:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

    icon.texture = texture
    icon.tooltipMessage = tooltipMessage

    return icon
end

function APR.Buff:AddBuffIcon(buff)
    local aura = C_UnitAuras.GetPlayerAuraBySpellID(buff.spellId)
    local icon = aura and aura.icon or C_Spell.GetSpellInfo(buff.spellId).iconID
    local isDisabled = not aura
    local auraInstanceID = aura and aura.auraInstanceID or nil

    local iconFrame = CreateBuffIcon(icon, isDisabled, auraInstanceID, buff.tooltipMessage)
    if iconFrame then
        iconFrame.spellId = buff.spellId
        iconFrame.auraId = aura and aura.auraInstanceID or 0
        iconFrame:SetPoint("TOPLEFT", xOffset, yOffset)
        table.insert(self.auras, iconFrame)
        xOffset = xOffset + FRAME_OFFSET
    end
    APR.Buff:RefreshFrameAnchor()
end

function APR.Buff:UpdateBuffIcon(aura)
    for _, container in pairs(self.auras) do
        if aura.spellId and container.spellId == aura.spellId then
            container.texture:SetVertexColor(unpack(APR.Color.white))
            container.auraId = aura.auraInstanceID
            container:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
                GameTooltip:SetUnitBuffByAuraInstanceID("player", aura.auraInstanceID)
                GameTooltip:AddLine(L[container.tooltipMessage], unpack(APR.Color.darkblue))
                GameTooltip:Show()
            end)
        end
    end
end

function APR.Buff:DisableBuffIcon(auraId)
    for _, container in pairs(self.auras) do
        if container.auraId == auraId then
            container.texture:SetVertexColor(unpack(APR.Color.midGray))
            container.auraId = 0
            container:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
                GameTooltip:AddLine(L[container.tooltipMessage], unpack(APR.Color.white))
                GameTooltip:Show()
            end)
        end
    end
end

function APR.Buff:RemoveAllBuffIcon()
    for _, container in pairs(self.auras) do
        container:Hide()
        container:ClearAllPoints()
        container = nil
    end
    self.auras = {}
    xOffset = FRAME_OFFSET_DEFAULT
    APR.Buff:RefreshFrameAnchor()
end
