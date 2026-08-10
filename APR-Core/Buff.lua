local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local LibWindow = LibStub("LibWindow-1.1")

-- Initialize module
APR.Buff = APR:NewModule("Buff")

local FRAME_WIDTH = 250
local FRAME_HEIGHT = 40
local FRAME_OFFSET_DEFAULT = 5
local FRAME_OFFSET = 35
local ICON_SIZE = 30
local DEFAULT_SPELL_ICON = 134400
local PLAYER_UNIT = "player"
local AURA_SLOT_PREFIX = "APRTrackedBuff"
local EMPTY_SPELL_FILTER = {}
local INTERFACE_VERSION = select(4, GetBuildInfo())
local UNIT_AURA_PAYLOAD_CAN_BE_FULLY_SECRET = INTERFACE_VERSION >= 120100

APR.Buff.auras = {}
APR.Buff.iconPool = {}
APR.Buff.auraSlots = {}

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
BuffFrameHeader:SetPoint("BOTTOM", BuffFrame, "TOP", 0, -1)
BuffFrameHeader.Text:SetText(L["BUFF"])
APR:RegisterFontString(BuffFrameHeader.Text, "general", { role = "accent", sizeDelta = 2 })
BuffFrameHeader.MinimizeButton:Hide()
BuffFrameHeader:SetScript("OnMouseDown", function(self)
    self:GetParent():StartMoving()
end)

BuffFrameHeader:SetScript("OnMouseUp", function(self)
    self:GetParent():StopMovingOrSizing()
    LibWindow.SavePosition(BuffFrameScreen)
end)

-- Blizzard_AuraContainer is an optional dependency so older 12.0 clients keep loading APR.
-- Checking its exported API instead of only the interface number also makes the fallback safe
-- if the Blizzard module is unavailable for any reason.
local hasAuraContainerSupport = C_AuraContainerUtil and AuraContainerSortMethod and
    AuraContainerSortDirection and CustomAuraContainerSlotDefaultOptions
local BuffAuraContainer

if hasAuraContainerSupport then
    BuffAuraContainer = CreateFrame("AuraContainer", "APRBuffAuraContainer", BuffFrame_body,
        "CustomAuraContainerTemplate")
    BuffAuraContainer:SetAllPoints(BuffFrame_body)
    BuffAuraContainer:SetFrameLevel(BuffFrame_body:GetFrameLevel() + 10)
    BuffAuraContainer:SetUnit(PLAYER_UNIT)
end

---------------------------------------------------------------------------------------
-------------------------------- Function Buff Frames ---------------------------------
---------------------------------------------------------------------------------------

local function GetSlotOffset(index)
    return FRAME_OFFSET_DEFAULT + ((index - 1) * FRAME_OFFSET), -FRAME_OFFSET_DEFAULT
end

local function GetSpellIcon(spellID, aura)
    if aura and aura.icon then
        return aura.icon
    end

    local spellInfo = C_Spell.GetSpellInfo(spellID)
    local spellTexture = C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)
    return spellInfo and spellInfo.iconID or spellTexture or DEFAULT_SPELL_ICON
end

local function SetIconEnabled(icon, enabled)
    icon.texture:SetVertexColor(unpack(enabled and APR.Color.white or APR.Color.midGray))
end

local function ShowTrackedBuffTooltip(icon)
    GameTooltip:SetOwner(icon, "ANCHOR_BOTTOM")

    if not UNIT_AURA_PAYLOAD_CAN_BE_FULLY_SECRET and icon.auraId and icon.auraId ~= 0 then
        GameTooltip:SetUnitBuffByAuraInstanceID(PLAYER_UNIT, icon.auraId)
        APR:AddTooltipLine(GameTooltip, L[icon.tooltipMessage], "general", "muted")
    else
        APR:AddTooltipLine(GameTooltip, L[icon.tooltipMessage], "general", "base")
    end

    GameTooltip:Show()
end

local function CreateTrackedBuffIcon()
    local icon = CreateFrame("Frame", nil, BuffFrame_body)
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:EnableMouse(true)
    icon:Hide()

    local texture = icon:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints(icon)

    icon:SetScript("OnEnter", ShowTrackedBuffTooltip)
    icon:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    icon.texture = texture
    icon.auraId = 0

    return icon
end

local function ConfigureTrackedBuffIcon(icon, buff, index, aura)
    local xOffset, yOffset = GetSlotOffset(index)

    icon:ClearAllPoints()
    icon:SetPoint("TOPLEFT", BuffFrame_body, "TOPLEFT", xOffset, yOffset)
    icon.texture:SetTexture(GetSpellIcon(buff.spellId, aura))
    icon.spellId = buff.spellId
    icon.tooltipMessage = buff.tooltipMessage
    icon.auraId = 0
    icon:Show()
end

local function InitializeAuraButton(auraButton, index)
    local xOffset, yOffset = GetSlotOffset(index)

    auraButton:SetSize(ICON_SIZE, ICON_SIZE)
    auraButton:SetPoint("TOPLEFT", BuffAuraContainer, "TOPLEFT", xOffset, yOffset)
    auraButton:SetMouseMotionEnabled(true)
    auraButton:SetTooltipAnchorPoint("ANCHOR_BOTTOM")

    local texture = auraButton:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints(auraButton)
    auraButton:SetIcon(texture)

    local cooldown = CreateFrame("Cooldown", nil, auraButton, "CooldownFrameTemplate")
    cooldown:SetAllPoints(auraButton)
    cooldown:SetDrawEdge(false)
    auraButton:SetDurationCooldown(cooldown)

    local applicationCount = auraButton:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    applicationCount:SetPoint("BOTTOMRIGHT", auraButton, "BOTTOMRIGHT", -1, 1)
    auraButton:SetApplicationCount(applicationCount)

    -- Slots only become visible after the managed container assigns a matching aura.
    auraButton:Hide()
end

local function EnsureAuraSlot(index)
    local slot = APR.Buff.auraSlots[index]
    if slot then
        return slot
    end

    local placeholder = CreateTrackedBuffIcon()
    local slotKey = AURA_SLOT_PREFIX .. index
    local auraButton = BuffAuraContainer:AddAuraSlot(slotKey, "HELPFUL", {
        candidateFilters = { includeSpellIDs = EMPTY_SPELL_FILTER },
        initializeFrame = function(frame)
            InitializeAuraButton(frame, index)
        end,
        sortMethod = AuraContainerSortMethod.Default,
        sortDirection = AuraContainerSortDirection.Normal,
    })

    slot = {
        auraButton = auraButton,
        key = slotKey,
        placeholder = placeholder,
    }
    APR.Buff.auraSlots[index] = slot

    return slot
end

local function SetLegacyAura(icon, aura)
    icon.auraId = aura and aura.auraInstanceID or 0
    SetIconEnabled(icon, aura ~= nil)
end

local function SetQueriedAura(icon, aura)
    if UNIT_AURA_PAYLOAD_CAN_BE_FULLY_SECRET then
        icon.auraId = 0
        SetIconEnabled(icon, aura ~= nil)
    else
        SetLegacyAura(icon, aura)
    end
end

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

function APR.Buff:UsesAuraContainer()
    return BuffAuraContainer ~= nil
end

function APR.Buff:AddBuffIcon(buff)
    local index = #self.auras + 1

    if self:UsesAuraContainer() then
        local slot = EnsureAuraSlot(index)
        ConfigureTrackedBuffIcon(slot.placeholder, buff, index)
        SetIconEnabled(slot.placeholder, false)

        BuffAuraContainer:SetAuraSlotCandidateFilters(slot.key, {
            includeSpellIDs = { [buff.spellId] = true },
        })
        table.insert(self.auras, slot.placeholder)
    else
        local icon = self.iconPool[index] or CreateTrackedBuffIcon()
        self.iconPool[index] = icon
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(buff.spellId)
        local iconAura = not UNIT_AURA_PAYLOAD_CAN_BE_FULLY_SECRET and aura or nil

        ConfigureTrackedBuffIcon(icon, buff, index, iconAura)
        SetQueriedAura(icon, aura)
        table.insert(self.auras, icon)
    end

    self:RefreshFrameAnchor()
end

function APR.Buff:UpdateBuffIcon(aura)
    if self:UsesAuraContainer() or not aura or not aura.spellId then
        return
    end

    for _, icon in ipairs(self.auras) do
        if icon.spellId == aura.spellId then
            SetLegacyAura(icon, aura)
        end
    end
end

function APR.Buff:DisableBuffIcon(auraId)
    if self:UsesAuraContainer() then
        return
    end

    for _, icon in ipairs(self.auras) do
        if icon.auraId == auraId then
            SetLegacyAura(icon, nil)
        end
    end
end

function APR.Buff:RefreshLegacyBuffs()
    if self:UsesAuraContainer() then
        return
    end

    for _, icon in ipairs(self.auras) do
        SetQueriedAura(icon, C_UnitAuras.GetPlayerAuraBySpellID(icon.spellId))
    end
end

function APR.Buff:HandleUnitAuraUpdate(unitTarget, updateInfo)
    if self:UsesAuraContainer() then
        return
    end

    -- In 12.1 the UNIT_AURA payload can be fully secret. A rare fallback where the
    -- Blizzard AuraContainer module failed to load therefore refreshes only the
    -- explicitly tracked spell IDs and never reads that payload.
    if UNIT_AURA_PAYLOAD_CAN_BE_FULLY_SECRET then
        self:RefreshLegacyBuffs()
        return
    end

    if unitTarget ~= PLAYER_UNIT then
        return
    end

    if not updateInfo or updateInfo.isFullUpdate then
        self:RefreshLegacyBuffs()
        return
    end

    if updateInfo.addedAuras then
        for _, aura in ipairs(updateInfo.addedAuras) do
            self:UpdateBuffIcon(aura)
        end
    end

    if updateInfo.updatedAuraInstanceIDs then
        for _, auraId in ipairs(updateInfo.updatedAuraInstanceIDs) do
            local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unitTarget, auraId)
            if aura then
                self:UpdateBuffIcon(aura)
            else
                self:DisableBuffIcon(auraId)
            end
        end
    end

    if updateInfo.removedAuraInstanceIDs then
        for _, auraId in ipairs(updateInfo.removedAuraInstanceIDs) do
            self:DisableBuffIcon(auraId)
        end
    end
end

function APR.Buff:RemoveAllBuffIcon()
    if self:UsesAuraContainer() then
        for index, icon in ipairs(self.auras) do
            local slot = self.auraSlots[index]
            icon:Hide()
            if slot then
                BuffAuraContainer:SetAuraSlotCandidateFilters(slot.key, {
                    includeSpellIDs = EMPTY_SPELL_FILTER,
                })
            end
        end
    else
        for _, icon in ipairs(self.auras) do
            icon:Hide()
            icon.auraId = 0
        end
    end

    self.auras = {}
    self:RefreshFrameAnchor()
end
