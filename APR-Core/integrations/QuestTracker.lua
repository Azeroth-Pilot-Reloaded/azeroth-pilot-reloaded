-- Tracker adapters own temporary placement, never the provider's saved settings.
-- APR's secure children stay anchored to UIParent, outside the tracker hierarchy.
APR.QuestTracker = { headers = setmetatable({}, { __mode = "k" }) }
local Tracker = APR.QuestTracker
local native = CreateFrame("Frame")
local setPoint, clearPoints = native.SetPoint, native.ClearAllPoints
local setHeight, setClamped = native.SetHeight, native.SetClampedToScreen
local setParent, setScale = native.SetParent, native.SetScale
local KALIEL_GAP, SURFACE_PADDING, SCREEN_MARGIN = 4, 8, 12

function Tracker:GetKaliel()
    local frame = _G["!KalielsTrackerFrame"] or _G.KalielsTrackerFrame
    if not frame then return end
    if self.kalielAddon and self.kalielAddon.frame == frame then return self.kalielAddon end
    -- MSA-AceAddon explicitly removes Kaliel from AceAddon's registry. Its
    -- embedded event library retains the live addon instance (and profile).
    local events = LibStub("MSA-Event-1.0", true)
    for addon in pairs(events and events.embeds or {}) do
        if type(addon) == "table" and addon.frame == frame and addon.Tracker_SetSize then
            self.kalielAddon = addon
            return addon
        end
    end
    local addons = LibStub("MSA-AceAddon-3.0", true)
    return addons and addons.GetAddon and addons:GetAddon("!KalielsTracker", true)
end

function Tracker:GetGap()
    local _, _, provider = self:Resolve()
    return provider == "kaliel" and KALIEL_GAP or 12
end

function Tracker:GetBelowOffset()
    local _, _, provider = self:Resolve()
    local headerHeight = _G.CurrentStepFrameHeader and CurrentStepFrameHeader:GetHeight() or 22
    return provider == "kaliel" and headerHeight + KALIEL_GAP or 35
end

function Tracker:GetSide(profile)
    -- Deliberately no AceDB default: an old true boolean means the old BELOW layout.
    if profile.currentStepTrackerSide == nil then
        profile.currentStepTrackerSide = profile.currentStepAttachFrameToQuestLog and "below" or "above"
    end
    return profile.currentStepTrackerSide
end

function Tracker:SetSide(side)
    local profile = APR:GetSettingsProfile()
    if not profile or (side ~= "above" and side ~= "below") or self:GetSide(profile) == side then return end
    self:Release()
    profile.currentStepTrackerSide = side
    profile.currentStepTrackerOffset = nil
    profile.currentStepTrackerPosition = nil
    APR.currentStep:RefreshCurrentStepFrameAnchor()
end

function Tracker:Resolve()
    local kaliel = _G["!KalielsTrackerFrame"] or _G.KalielsTrackerFrame
    if kaliel and kaliel.Background then
        return kaliel, kaliel.Background, "kaliel", _G.KT_ObjectiveTrackerFrame and KT_ObjectiveTrackerFrame.Header
    end
    local questie = _G.Questie and Questie.db and Questie.db.profile
    if _G.Questie_BaseFrame and questie and questie.trackerEnabled then
        return Questie_BaseFrame, Questie_BaseFrame, "questie", _G.Questie_HeaderFrame
    end
    local frame = _G.ObjectiveTrackerFrame or _G.QuestWatchFrame
    return frame, frame, "blizzard", frame and frame.Header
end

local function number(value)
    return APR:CanAccessValue(value) and type(value) == "number" and value == value
end

local function points(frame)
    if not frame.GetNumPoints or not frame.GetPoint then return nil end
    local result = {}
    for i = 1, frame:GetNumPoints() do
        local point, relative, relativePoint, x, y = frame:GetPoint(i)
        if not point or not number(x) or not number(y) then return nil end
        result[i] = { point, relative, relativePoint, x, y }
    end
    return #result > 0 and result or nil
end

local function samePoints(a, b)
    if not a or not b or #a ~= #b then return false end
    for i, p in ipairs(a) do
        for j = 1, 5 do
            if j < 4 then
                if p[j] ~= b[i][j] then return false end
            elseif math.abs(p[j] - b[i][j]) > 0.01 then
                return false
            end
        end
    end
    return true
end

local function place(frame, anchors, dx, dy)
    -- Kaliel intentionally shadows the container's setters. Call the native frame
    -- methods without replacing those locks or changing its stored configuration.
    local buttons = frame.Buttons
    local oldX, oldY
    if buttons then oldX, oldY = frame:GetCenter(), frame:GetTop() end
    clearPoints(frame)
    local applied = {}
    for i, p in ipairs(anchors) do
        applied[i] = { p[1], p[2], p[3], p[4] + dx, p[5] + dy }
        setPoint(frame, unpack(applied[i]))
    end
    if buttons and number(oldX) and number(oldY) then
        -- Kaliel's item buttons are a separate UIParent child, not tracker children.
        local x, y = frame:GetCenter(), frame:GetTop()
        local buttonPoints = points(buttons)
        if number(x) and number(y) and buttonPoints then
            local scale = frame:GetEffectiveScale() / buttons:GetEffectiveScale()
            clearPoints(buttons)
            for _, p in ipairs(buttonPoints) do
                setPoint(buttons, p[1], p[2], p[3], p[4] + (x - oldX) * scale, p[5] + (y - oldY) * scale)
            end
        end
    end
    -- WoW can normalize/round anchors. Remember what it actually stored so a
    -- later detach recognizes our placement and restores the original points.
    return points(frame)
end

function Tracker:Release(preservePosition)
    if InCombatLockdown() then return end
    self.baseX, self.baseTop = nil, nil
    local state = self.displacement
    if state then
        self.displacement = nil -- Provider callbacks must not reapply this state.
        local ownsPosition = samePoints(points(state.frame), state.applied)
        if state.kaliel then
            local owner = self:GetKaliel()
            if owner and owner.Tracker_SetSize then
                owner:Tracker_SetSize(true)
            else
                setHeight(state.frame, state.rootHeight)
                state.frame.Background:SetHeight(state.visibleHeight)
            end
            if ownsPosition and not preservePosition then
                if owner and owner.Tracker_Move then
                    owner:Tracker_Move()
                else
                    place(state.frame, state.original, 0, 0)
                end
            end
            setClamped(state.frame, state.clamped)
            if owner and owner.QuestButtons_Move then owner.QuestButtons_Move() end
            return
        end
        if state.blizzard then
            -- Rejoin Blizzard's layout only when we still own the temporary
            -- placement. Edit Mode or another addon may already have moved it.
            if ownsPosition and not preservePosition then
                if state.managed then
                    setParent(state.frame, state.parent)
                    setScale(state.frame, state.localScale)
                    state.frame.ignoreFramePositionManager = state.ignoreManager
                end
                place(state.frame, state.original, 0, 0)
                if state.managed then state.manager:AddManagedFrame(state.frame) end
            elseif state.managed and state.frame.ignoreFramePositionManager == true then
                state.frame.ignoreFramePositionManager = state.ignoreManager
            end
            setHeight(state.frame, state.rootHeight)
            state.frame:UpdateHeight()
            setClamped(state.frame, state.clamped)
            return
        end
        -- A user move or another addon owns any anchors it changed in the meantime.
        if ownsPosition and not preservePosition then place(state.frame, state.original, 0, 0) end
    end
end

function Tracker:WatchKaliel(owner)
    if not owner or self.kalielOwner == owner then return end
    self.kalielOwner = owner
    -- Kaliel resets its viewport when quests change, and its anchors when its
    -- own options change. Post-hooks retain its methods and never write its DB.
    local function refreshed(moved)
        local state = self.displacement
        if self.kalielUpdating or not state or not state.kaliel then return end
        if moved then
            state.ownerMoved = true
        else
            -- Kaliel skips SetHeight when its content height is unchanged. Its
            -- cached height is the natural size; Background may still be capped
            -- by our previous viewport and must not become the new maximum.
            state.visibleHeight = number(state.frame.height) and state.frame.height or state.frame.Background:GetHeight()
        end
        if InCombatLockdown() then return end
        self:GetAnchor()
    end
    if owner.Tracker_SetSize then hooksecurefunc(owner, "Tracker_SetSize", function() refreshed(false) end) end
    if owner.Tracker_Move then hooksecurefunc(owner, "Tracker_Move", function() refreshed(true) end) end
end

function Tracker:GetKalielAnchor(frame, bounds)
    local owner = self:GetKaliel()
    self:WatchKaliel(owner)
    local side = self:GetSide(APR:GetSettingsProfile())
    local state = self.displacement
    if state and (not state.kaliel or state.side ~= side or state.ownerMoved or not samePoints(points(frame), state.applied)) then
        self:Release(state.ownerMoved or not samePoints(points(frame), state.applied))
        state = nil
    end
    if not state then
        local x, top, scale = self:Geometry(bounds, "top")
        local anchors = points(frame)
        if not x or not scale or scale <= 0 or not anchors then return end
        state = {
            frame = frame,
            kaliel = true,
            side = side,
            original = anchors,
            baseX = x,
            baseTop = top,
            rootHeight = frame:GetHeight(),
            visibleHeight = bounds:GetHeight(),
            clamped = frame.IsClampedToScreen and frame:IsClampedToScreen() or false
        }
        self.displacement = state
    end
    local _, _, scale = self:Geometry(frame, "top")
    if not scale or scale <= 0 then return end
    local offset = APR:GetSettingsProfile().currentStepTrackerOffset or {}
    local dx, dy = tonumber(offset.x) or 0, tonumber(offset.y) or 0
    local headerHeight = _G.CurrentStepFrameHeader and CurrentStepFrameHeader:GetHeight() or 22
    local x, top = state.baseX + dx, state.baseTop + dy
    local stackHeight = APR:GetSnappedStackHeight()
    local reserved = headerHeight + stackHeight + KALIEL_GAP
    local trackerTop = side == "above" and top - reserved or top
    local config = owner and owner.db and owner.db.profile
    local maximum = config and config.maxHeight or state.rootHeight
    -- A full-height, screen-clamped Kaliel root is pushed back over APR by WoW.
    -- Reserve APR's complete stack on BOTH sides, without changing maxHeight.
    -- Below, Kaliel keeps its top and scrolls within a shorter viewport so APR
    -- is not pushed off the bottom of the screen.
    local available = side == "below" and trackerTop - reserved or trackerTop
    local viewport = math.min(maximum, math.max(40, (available - SCREEN_MARGIN) / scale))
    local visible = math.min(state.visibleHeight, viewport)
    self.kalielUpdating = true
    setClamped(frame, false)
    local height = frame.directionUp and visible or viewport
    if frame:GetHeight() ~= height then setHeight(frame, height) end
    if bounds:GetHeight() ~= visible then bounds:SetHeight(visible) end
    local anchors = { { "TOP", UIParent, "BOTTOMLEFT", x / scale, trackerTop / scale } }
    if not samePoints(points(frame), anchors) then
        state.applied = place(frame, anchors, 0, 0)
    else
        state.applied = points(frame)
    end
    if owner and owner.QuestButtons_Move then owner.QuestButtons_Move() end
    if frame.Scroll and frame.Scroll.GetVerticalScrollRange then
        local scroll = frame.Scroll
        local value = math.min(scroll:GetVerticalScroll(), scroll:GetVerticalScrollRange())
        if value ~= scroll:GetVerticalScroll() then scroll:SetVerticalScroll(value) end
        scroll.value = value
    end
    self.kalielUpdating = nil
    local aprTop = side == "below" and trackerTop - visible * scale - KALIEL_GAP - headerHeight or top - headerHeight
    self.baseX = state.baseX
    self.baseTop = side == "below" and aprTop - dy or state.baseTop
    return x, aprTop
end

function Tracker:Geometry(frame, edge)
    if not frame then return end
    local x = frame:GetCenter()
    local y = edge == "top" and frame:GetTop() or frame:GetBottom()
    local scale = frame:GetEffectiveScale()
    local parentScale = UIParent:GetEffectiveScale()
    if not number(x) or not number(y) or not number(scale) or not number(parentScale) or parentScale <= 0 then return end
    scale = scale / parentScale
    return x * scale, y * scale, scale
end

function Tracker:GetBlizzardAnchor(frame)
    local state = self.displacement
    if state and (not state.blizzard or not samePoints(points(frame), state.applied)) then
        self:Release(not samePoints(points(frame), state.applied))
        state = nil
    end
    local screenHeight = UIParent:GetHeight()
    local x, top, scale = self:Geometry(frame, "top")
    if not x or not scale or scale <= 0 or not number(screenHeight) then return end
    if not state then
        local anchors, height = points(frame), frame:GetHeight()
        if not anchors or not number(height) then return end
        state = {
            frame = frame,
            blizzard = true,
            original = anchors,
            baseX = x,
            baseTop = top,
            rootHeight = height,
            clamped = frame.IsClampedToScreen and frame:IsClampedToScreen() or false
        }
        -- The default tracker is a child of RightManagedFrameContainer. Merely
        -- shifting its points loses to the next managed layout. Use Blizzard's
        -- existing opt-out while attached, without editing any saved layout.
        local manager = frame.GetManagedFrameContainer and frame:GetManagedFrameContainer()
        if manager and frame:IsInDefaultPosition() and not frame.ignoreFramePositionManager then
            state.managed, state.manager = true, manager
            state.parent, state.localScale = frame:GetParent(), frame:GetScale()
            state.ignoreManager = frame.ignoreFramePositionManager
            frame.ignoreFramePositionManager = true
            manager:RemoveManagedFrame(frame)
            setParent(frame, UIParent)
            setScale(frame, scale)
        end
        self.displacement = state
    end
    local offset = APR:GetSettingsProfile().currentStepTrackerOffset or {}
    local dx, dy = tonumber(offset.x) or 0, tonumber(offset.y) or 0
    local headerHeight = _G.CurrentStepFrameHeader and CurrentStepFrameHeader:GetHeight() or 22
    local reserved = headerHeight + APR:GetSnappedStackHeight() + self:GetGap()
    local trackerTop = state.baseTop + dy - reserved
    -- A screen-clamped full-height tracker is otherwise pushed back UP over
    -- APR. Keep its entire viewport below all snapped frames and their gaps.
    -- Native OnSizeChanged schedules the module layout; never hook Update or
    -- MarkDirty, which would join APR's secure children to Blizzard's updates.
    local height = math.max(20, math.min(state.rootHeight, (trackerTop - SCREEN_MARGIN) / scale))
    setClamped(frame, false)
    if frame:GetHeight() ~= height then setHeight(frame, height) end
    local anchors = { { "TOP", UIParent, "TOPLEFT", (state.baseX + dx) / scale, (trackerTop - screenHeight) / scale } }
    if not samePoints(points(frame), anchors) then
        state.applied = place(frame, anchors, 0, 0)
    else
        state.applied = points(frame)
    end
    self.baseX, self.baseTop = state.baseX, state.baseTop
    return state.baseX + dx, state.baseTop + dy - headerHeight
end

function Tracker:GetAnchor()
    if InCombatLockdown() then return end
    local profile = APR:GetSettingsProfile()
    local frame, bounds, provider, header = self:Resolve()
    if not frame then
        self:Release(); return
    end
    if self.displacement and self.displacement.frame ~= frame then self:Release() end
    if frame.IsShown and not frame:IsShown() then
        self:Release(); return
    end
    local editing
    if provider == "kaliel" then
        local editMode = LibStub("MSA-EditMode-1.0", true)
        local movers = editMode and editMode.movers and editMode.movers["!KalielsTracker"]
        local mover = movers and frame.GetName and movers[frame:GetName()]
        editing = mover and mover.mover and mover.mover:IsShown()
    end
    if editing or (_G.EditModeManagerFrame and EditModeManagerFrame:IsShown()) or frame.isMoving or frame.isSizing then
        self:Release()
        return
    end
    self:RefreshWidths()
    if provider == "kaliel" then return self:GetKalielAnchor(frame, bounds) end
    if provider == "blizzard" and frame.UpdateHeight and self:GetSide(profile) == "above" then
        return self:GetBlizzardAnchor(frame)
    end
    if self:GetSide(profile) == "below" then
        if self.displacement and (self.displacement.kaliel or self.displacement.blizzard) then self:Release() end
        local offset = profile.currentStepTrackerOffset or {}
        local dx, dy = tonumber(offset.x) or 0, tonumber(offset.y) or 0
        if dx == 0 and dy == 0 then
            self:Release()
        else
            -- Moving the editor's group moves the tracker too, keeping the gap
            -- between its content and APR unchanged on either attachment side.
            local anchors = points(frame)
            local _, _, scale = self:Geometry(bounds, "top")
            if not anchors or not scale or scale <= 0 then return end
            local state = self.displacement
            if not state or not samePoints(anchors, state.applied) then
                state = { frame = frame, original = anchors }
                self.displacement = state
            end
            local nextDX, nextDY = dx / scale, dy / scale
            if not state.applied or state.dx ~= nextDX or state.dy ~= nextDY then
                state.applied = place(frame, state.original, nextDX, nextDY)
                state.dx, state.dy = nextDX, nextDY
            end
        end
        local anchor = bounds
        if provider == "blizzard" then
            anchor = header or frame
            for i = #(frame.modules or {}), 1, -1 do
                if frame.modules[i]:IsShown() then
                    anchor = frame.modules[i]; break
                end
            end
        end
        local x, y = self:Geometry(anchor, "bottom")
        if x then
            self.baseX, self.baseTop = x - dx, y - 35 - dy
            return x, y - 35
        end
        return
    end

    local anchors = points(frame)
    local x, top = self:Geometry(bounds, "top")
    local rawScale, parentScale = frame:GetEffectiveScale(), UIParent:GetEffectiveScale()
    if not number(rawScale) or not number(parentScale) or parentScale <= 0 then return end
    local scale = rawScale / parentScale
    if not anchors or not x or not number(scale) or scale <= 0 then return end
    local state = self.displacement
    if state and not state.baseTop then
        self:Release()
        return self:GetAnchor()
    end
    if not state or not samePoints(anchors, state.applied) then
        state = { frame = frame, original = anchors, dx = 0, dy = 0, baseX = x, baseTop = top }
        self.displacement = state
    end
    -- Keep an unshifted baseline until the owner changes its anchors. Repeated
    -- updates and screen clamping must never accumulate our own displacement.
    local baseX, baseTop = state.baseX, state.baseTop
    local width, boundsHeight = bounds:GetWidth(), bounds:GetHeight()
    if state.scale and state.scale ~= scale then
        baseX, baseTop = x - state.dx * scale, top - state.dy * scale
        state.correctionX, state.correctionY = nil, nil
    elseif state.lastTop then
        local deltaX, deltaY = x - state.lastX, top - state.lastTop
        if width ~= state.width then
            state.correctionX = (state.correctionX or 0) - deltaX
        else
            baseX = baseX + deltaX
        end
        if boundsHeight ~= state.height then
            state.correctionY = (state.correctionY or 0) - deltaY
        else
            baseTop = baseTop + deltaY
        end
    end
    state.baseX, state.baseTop = baseX, baseTop
    local offset = profile.currentStepTrackerOffset or {}
    local dx, dy = tonumber(offset.x) or 0, tonumber(offset.y) or 0
    local height = APR:GetSnappedStackHeight()
    local headerHeight = _G.CurrentStepFrameHeader and CurrentStepFrameHeader:GetHeight() or 22
    local shift = headerHeight + height + 12
    local nextDX, nextDY = (dx + (state.correctionX or 0)) / scale, (dy - shift + (state.correctionY or 0)) / scale
    if not state.applied or state.dx ~= nextDX or state.dy ~= nextDY then
        state.applied = place(frame, state.original, nextDX, nextDY)
        state.dx, state.dy = nextDX, nextDY
    end
    state.lastX, state.lastTop = self:Geometry(bounds, "top")
    state.width, state.height, state.scale = width, boundsHeight, scale
    self.baseX, self.baseTop = baseX, baseTop
    return baseX + dx, baseTop + dy - headerHeight
end

function Tracker:SavePreviewPosition(preview)
    local profile = APR:GetSettingsProfile()
    local scale = preview:GetEffectiveScale() / UIParent:GetEffectiveScale()
    profile.currentStepTrackerPosition = {
        x = (preview:GetLeft() + preview:GetWidth() / 2) * scale,
        y = preview:GetTop() * scale,
    }
    self:ApplyPendingPosition()
end

function Tracker:ApplyPendingPosition()
    local profile = APR:GetSettingsProfile()
    local position = profile.currentStepTrackerPosition
    if not position then return end
    if self.baseX and self.baseTop then
        local headerHeight = self:GetSide(profile) == "above" and
            (_G.CurrentStepFrameHeader and CurrentStepFrameHeader:GetHeight() or 22) or 0
        profile.currentStepTrackerOffset = {
            x = position.x - self.baseX,
            y = position.y + headerHeight - self.baseTop,
        }
        profile.currentStepTrackerPosition = nil
        return true
    end
end

local scopes = { currentStep = true, fillers = true, questOrderList = true, afk = true }
local function rgba(color)
    if color then return { color.r, color.g, color.b, color.a or 1 } end
end

function Tracker:Style(scope)
    local profile = APR:GetSettingsProfile()
    if not profile or not profile.currentStepAttachFrameToQuestLog or profile.currentStepMatchTrackerStyle == false then return end
    if not scopes[scope] then return end
    if scope == "fillers" and not profile.fillersFrameSnapToCurrentStep then return end
    if scope == "questOrderList" and not profile.questOrderListSnapToCurrentStep then return end
    if scope == "afk" and not profile.afkSnapToCurrentStep then return end
    local frame, bounds, provider, header = self:Resolve()
    if not frame or provider == "blizzard" then return end
    local fontString = header and (header.Text or (header.trackedQuests and header.trackedQuests.label))
    local font, size, flags
    if fontString and fontString.GetFont then font, size, flags = fontString:GetFont() end
    local headerFont, headerSize, headerFlags = font, size, flags
    if provider == "questie" then
        local config = Questie.db.profile
        local media = LibStub("LibSharedMedia-3.0", true)
        font = media and media:Fetch("font", config.trackerFontObjective, true) or font
        size, flags = config.trackerFontSizeObjective or size, config.trackerFontOutline or flags
    elseif size then
        size = size - 1
    end                                  -- Kaliel's header is one point larger than its objectives.
    local color = bounds.GetBackdropColor and { bounds:GetBackdropColor() }
    local border = bounds.GetBackdropBorderColor and { bounds:GetBackdropBorderColor() }
    local backdrop = bounds.GetBackdrop and bounds:GetBackdrop()
    local accent = fontString and fontString.GetTextColor and { fontString:GetTextColor() }
    local style = {
        font = font,
        size = size,
        flags = flags,
        color = color,
        border = border,
        backdrop = backdrop,
        headerFont = headerFont,
        headerSize = headerSize,
        headerFlags = headerFlags,
        headerBackground = header and header.Background,
        accent = accent,
        provider = provider
    }
    local owner = provider == "kaliel" and self:GetKaliel()
    local config = owner and owner.db and owner.db.profile
    if config then
        style.owner, style.config = owner, config
        style.scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
        style.font, style.size, style.flags = owner.font, config.fontSize * style.scale, config.fontFlag
        style.headerFont, style.headerSize, style.headerFlags = owner.font, (config.fontSize + 1) * style.scale,
            config.fontFlag
        style.shadow = config.fontShadow
        style.accent = rgba(config.hdrTxtColorShare and owner.borderColor or config.hdrTxtColor)
        style.headerColor = rgba(config.hdrBgrColorShare and owner.borderColor or config.hdrBgrColor)
        style.buttonColor = rgba(owner.hdrBtnColor or config.hdrBtnColor)
        local colors = _G.KT_OBJECTIVE_TRACKER_COLOR or {}
        style.textColors = { base = rgba(colors.Normal), title = rgba(colors.Header), muted = rgba(colors.Complete) }
    end
    return style
end

local function textureSnapshot(texture)
    if not texture or not texture.GetTexture then return end
    return {
        path = texture:GetTexture(),
        atlas = texture:GetAtlas(),
        coords = { texture:GetTexCoord() },
        color = { texture:GetVertexColor() },
        alpha = texture:GetAlpha(),
        height = texture:GetHeight(),
        width = texture.GetWidth and texture:GetWidth(),
        points = points(texture),
        shown = texture:IsShown(),
        desaturated = texture.IsDesaturated and texture:IsDesaturated()
    }
end

local function textureApply(texture, saved)
    if not texture then return end
    if not saved then
        texture:Hide(); return
    end
    if saved.atlas then texture:SetAtlas(saved.atlas) else texture:SetTexture(saved.path) end
    if #saved.coords > 0 then texture:SetTexCoord(unpack(saved.coords)) end
    if #saved.color > 0 then texture:SetVertexColor(unpack(saved.color)) end
    texture:SetAlpha(saved.alpha)
    if saved.desaturated ~= nil then texture:SetDesaturated(saved.desaturated) end
    if saved.points then
        texture:ClearAllPoints()
        for _, p in ipairs(saved.points) do texture:SetPoint(unpack(p)) end
    end
    if saved.width then texture:SetWidth(saved.width) end
    texture:SetHeight(saved.height)
    texture:SetShown(saved.shown)
end

local function skinButton(button, style, kind, collapsed)
    if not button or not button.GetNormalTexture then return end
    local kaliel = style and style.owner and style.owner.MEDIA_PATH
    local saved = button.aprTrackerStyle
    if kaliel then
        if not saved then
            saved = { width = button:GetWidth(), height = button:GetHeight(), textures = {} }
            for _, state in ipairs({ "Normal", "Pushed", "Highlight", "Disabled" }) do
                local texture = button["Get" .. state .. "Texture"](button)
                saved.textures[state] = { value = textureSnapshot(texture) }
            end
            button.aprTrackerStyle = saved
        end
        local arrow = kind == "left" or kind == "right"
        local scale = style.scale or 1
        button:SetSize((arrow and 20 or 16) * scale, (arrow and 22 or 16) * scale)
        for _, state in ipairs({ "Normal", "Pushed", "Highlight", "Disabled" }) do
            local path = kaliel .. "UI-KT-HeaderButtons"
            button["Set" .. state .. "Texture"](button, path)
            local texture = button["Get" .. state .. "Texture"](button)
            if texture then
                if arrow then
                    texture:ClearAllPoints()
                    texture:SetPoint("CENTER", button, "CENTER", 0, 0)
                    style.owner.SetSprite(texture, "arrow-" .. kind, true)
                    texture:SetSize(8 * scale, 21 * scale)
                elseif kind == "settings" then
                    -- Kaliel's framed book glyph opens APR's menu; keep its
                    -- existing tooltip and click action, without the WoW gear.
                    texture:SetTexCoord(0.5, 1, 0, 0.25)
                else
                    texture:SetTexCoord(0, 0.5, collapsed and 0 or 0.25, collapsed and 0.25 or 0.5)
                end
                local color = state == "Highlight" and { 1, 1, 1, 1 } or style.buttonColor or style.accent
                if color then texture:SetVertexColor(unpack(color)) end
                texture:SetAlpha(state == "Disabled" and 0.35 or 1)
                if texture.SetDesaturated then texture:SetDesaturated(false) end
            end
        end
    elseif saved then
        button:SetSize(saved.width, saved.height)
        for state, texture in pairs(saved.textures) do
            textureApply(button["Get" .. state .. "Texture"](button), texture.value)
        end
        button.aprTrackerStyle = nil
    end
end

function Tracker:RefreshHeaders()
    for header, scope in pairs(self.headers) do
        local style = self:Style(scope)
        local parent = header.GetParent and header:GetParent()
        if style and style.owner and parent then
            if not header.aprTrackerWidth then header.aprTrackerWidth = header:GetWidth() end
            if not header.aprTrackerHeight then header.aprTrackerHeight = header:GetHeight() end
            header:SetWidth(parent:GetWidth())
            header:SetHeight(header.aprTrackerHeight * (style.scale or 1))
        elseif header.aprTrackerWidth then
            header:SetWidth(header.aprTrackerWidth)
            header:SetHeight(header.aprTrackerHeight)
            header.aprTrackerWidth, header.aprTrackerHeight = nil, nil
        end
        local background = header.Background
        if background then
            if style then
                if not header.aprTrackerBackground then header.aprTrackerBackground = { value = textureSnapshot(
                    background) } end
                if style.owner and style.owner.SetSprite then
                    local config = style.config
                    local main = scope == "currentStep"
                    local visible = config.hdrBgr > 1 and (not main or config.hdrTrackerBgrShow)
                    if visible then
                        style.owner.SetSprite(background,
                            (main and "tracker" or "module") .. "-header-bgr-" .. (config.hdrBgr - 1))
                        background:ClearAllPoints()
                        background:SetPoint("TOPLEFT", header, "TOPLEFT", -4, -1)
                        background:SetPoint("TOPRIGHT", header, "TOPRIGHT", 4, -1)
                        background:SetHeight((main and 29 or 24) * (style.scale or 1))
                        background:SetAlpha(1)
                        if style.headerColor then background:SetVertexColor(unpack(style.headerColor)) end
                    end
                    background:SetShown(visible)
                else
                    local appearance = textureSnapshot(style.headerBackground)
                    if appearance then appearance.points = nil end -- Keep the APR header's own anchors.
                    textureApply(background, appearance)
                end
            elseif header.aprTrackerBackground then
                textureApply(background, header.aprTrackerBackground.value)
                header.aprTrackerBackground = nil
            end
        end
        skinButton(header.MinimizeButton, style, "collapse", parent and parent.collapsed)
        if header.MinimizeButton and not header.aprTrackerClickHook then
            header.aprTrackerClickHook = true
            header.MinimizeButton:HookScript("OnClick", function(button)
                local saved = button.aprTrackerStyle
                if saved then
                    -- APR's original click handler has just set its new +/- art.
                    -- Save that state for opt-out, then reapply Kaliel's equivalent.
                    for _, name in ipairs({ "Normal", "Pushed" }) do
                        saved.textures[name] = { value = textureSnapshot(button["Get" .. name .. "Texture"](button)) }
                    end
                    if InCombatLockdown() then
                        self.styleSignature = nil; return
                    end
                    skinButton(button, self:Style(scope), "collapse", parent and parent.collapsed)
                end
            end)
        end
        if scope == "currentStep" then
            skinButton(_G.CurrentStepFrameSettingsButton, style, "settings")
            skinButton(_G.CurrentStepFrame_StepHolder_RollbackButton, style, "left")
            skinButton(_G.CurrentStepFrame_StepHolder_SkipButton, style, "right")
        end
    end
end

function Tracker:PanelScope(frame)
    local current = frame
    for _ = 1, 8 do
        if current == _G.CurrentStepScreenPanel then return "currentStep" end
        if current == _G.FillersScreenPanel then return "fillers" end
        if current == _G.QuestOrderListPanel then return "questOrderList" end
        if current == _G.AfkFrameScreen then return "afk" end
        current = current and current.GetParent and current:GetParent()
        if not current then return end
    end
end

function Tracker:RefreshWidths()
    if InCombatLockdown() or self.resizing then return end
    self.resizing = true
    self.widths = self.widths or setmetatable({}, { __mode = "k" })
    local _, bounds, provider = self:Resolve()
    local width
    if provider == "kaliel" and bounds then
        local scale = bounds:GetEffectiveScale() / UIParent:GetEffectiveScale()
        width = bounds:GetWidth() * scale - 2 * SURFACE_PADDING
    end
    local function resize(frame, scope, module)
        if not frame or not module or not module.SetContentWidth then return end
        local target
        if provider == "kaliel" and self:Style(scope) and number(width) and width > 100 then
            if not self.widths[frame] then self.widths[frame] = frame:GetWidth() end
            target = width
        elseif self.widths[frame] then
            target, self.widths[frame] = self.widths[frame], nil
        end
        if target and math.abs(frame:GetWidth() - target) > 0.01 then
            module:SetContentWidth(target)
            self.styleSignature = nil
        end
    end
    resize(_G.CurrentStepScreenPanel, "currentStep", APR.currentStep)
    resize(_G.FillersScreenPanel, "fillers", APR.fillersFrame)
    self.resizing = nil
end

function Tracker:ApplyPanel(frame, fallback)
    local scope = self:PanelScope(frame)
    local style = scope and self:Style(scope)
    if style and style.provider == "kaliel" then
        -- One continuous surface covers the real content height, including the
        -- linked panels. The current-step root itself is only 30px high.
        self.panelColors = self.panelColors or setmetatable({}, { __mode = "k" })
        self.panelColors[frame] = fallback
        return { 0, 0, 0, 0 }
    end
    if style and style.color and #style.color >= 4 and fallback[4] ~= 0 then
        -- Only the outer panels get a border; rows remain transparent inside them.
        local root = frame == _G.CurrentStepScreenPanel or frame == _G.FillersScreenPanel or
        frame == _G.QuestOrderListPanel
        if root and frame.GetBackdrop then
            if not frame.aprTrackerBackdrop then
                frame.aprTrackerBackdrop = {
                    value = frame:GetBackdrop(),
                    border = frame.GetBackdropBorderColor and { frame:GetBackdropBorderColor() }
                }
            end
            frame:SetBackdrop(style.backdrop)
            if style.border and #style.border >= 4 then frame:SetBackdropBorderColor(unpack(style.border)) end
        end
        return style.color
    end
    if frame.aprTrackerBackdrop then
        frame:SetBackdrop(frame.aprTrackerBackdrop.value)
        local border = frame.aprTrackerBackdrop.border
        if border and #border >= 4 then frame:SetBackdropBorderColor(unpack(border)) end
        frame.aprTrackerBackdrop = nil
    end
    return fallback
end

function Tracker:RefreshSurface()
    local style = self:Style("currentStep")
    if not style or style.provider ~= "kaliel" then
        if self.surface then self.surface:Hide() end
        if self.panelColors then
            for frame, color in pairs(self.panelColors) do APR:SetPanelColor(frame, color) end
            self.panelColors = nil
        end
        return
    end
    local root = _G.CurrentStepScreenPanel
    if not root then return end
    if not self.surface then
        self.surface = CreateFrame("Frame", nil, root, "BackdropTemplate")
        self.surface:EnableMouse(false)
    end
    local surface = self.surface
    surface:SetFrameLevel(math.max(0, root:GetFrameLevel() - 1))
    local headerHeight = _G.CurrentStepFrameHeader and CurrentStepFrameHeader:GetHeight() or 22
    if surface.aprHeaderHeight ~= headerHeight then
        surface:ClearAllPoints()
        surface:SetPoint("TOP", root, "TOP", 0, headerHeight + 4)
        surface.aprHeaderHeight = headerHeight
    end
    local width = root:GetWidth()
    for _, entry in ipairs(APR:GetSnappedStack()) do width = math.max(width, entry.frame:GetWidth()) end
    local height = headerHeight + APR:GetSnappedStackHeight() + 8
    if surface:GetWidth() ~= width + 2 * SURFACE_PADDING or surface:GetHeight() ~= height then
        surface:SetSize(width + 2 * SURFACE_PADDING, height)
    end
    surface:SetBackdrop(style.backdrop)
    if style.color then surface:SetBackdropColor(unpack(style.color)) end
    if style.border then surface:SetBackdropBorderColor(unpack(style.border)) end
    surface:Show()
end

function Tracker:RefreshAppearance()
    if InCombatLockdown() then return end
    self:RefreshWidths()
    self:RefreshSurface()
    local parts = {}
    for _, scope in ipairs({ "currentStep", "fillers", "questOrderList", "afk" }) do
        local style = self:Style(scope)
        parts[#parts + 1] = scope
        if style then
            for _, key in ipairs({ "provider", "font", "size", "flags", "shadow", "scale" }) do parts[#parts + 1] =
                tostring(style[key]) end
            for _, key in ipairs({ "color", "border", "accent", "headerColor", "buttonColor" }) do
                for _, value in ipairs(style[key] or {}) do parts[#parts + 1] = tostring(value) end
            end
            if style.config then
                parts[#parts + 1] = tostring(style.config.hdrBgr)
                parts[#parts + 1] = tostring(style.config.hdrTrackerBgrShow)
            end
            for _, key in ipairs({ "bgFile", "edgeFile", "edgeSize", "tileSize" }) do
                parts[#parts + 1] = tostring(style.backdrop and style.backdrop[key])
            end
            local background = textureSnapshot(style.headerBackground)
            if background then
                parts[#parts + 1] = tostring(background.path)
                parts[#parts + 1] = tostring(background.shown)
                for _, value in ipairs(background.coords) do parts[#parts + 1] = tostring(value) end
                for _, value in ipairs(background.color) do parts[#parts + 1] = tostring(value) end
            end
        end
    end
    -- Include late-created controls; collapse clicks are handled immediately.
    for _, name in ipairs({ "CurrentStepFrame_StepHolder_RollbackButton", "CurrentStepFrame_StepHolder_SkipButton" }) do
        parts[#parts + 1] = tostring(_G[name])
    end
    local signature = table.concat(parts, ":")
    if self.styleSignature == signature then return end
    self.styleSignature = signature
    self:RefreshHeaders()
    for _, scope in ipairs({ "currentStep", "fillers", "questOrderList", "afk" }) do
        if APR.RefreshTextAppearance then APR:RefreshTextAppearance(scope) end
    end
    if APR.currentStep then APR.currentStep:UpdateBackgroundColorAlpha() end
    if APR.questOrderList then APR.questOrderList:UpdateBackgroundColorAlpha() end
    self:RefreshSurface()
end

-- Reuse the geometry probe storage: observing an unchanged tracker must not scan
-- quest rows, rebuild styles or mutate any frames. Provider internals remain untouched.
local OBSERVED_FRAME_METHODS = {"IsShown", "GetWidth", "GetHeight", "GetEffectiveScale"}
local OBSERVED_GEOMETRY_METHODS = {"GetCenter", "GetTop", "GetBottom"}
local OBSERVED_PROFILE_KEYS = {"currentStepTrackerSide", "currentStepMatchTrackerStyle", "afkSnapToCurrentStep",
    "fillersFrameSnapToCurrentStep", "fillersFrameSnapGap", "fillersFrameShowHeader", "questOrderListSnapToCurrentStep"}
local OBSERVED_PANEL_NAMES = {"CurrentStepScreenPanel", "AfkFrameScreen", "FillersScreenPanel", "QuestOrderListPanel"}

local function ObserveValue(state, value, trusted)
    state.count = state.count + 1
    if not trusted and not APR:CanAccessValue(value) then
        state.changed = true
        value = nil
    end
    if state[state.count] ~= value then state.changed = true end
    state[state.count] = value
end

local function ObserveFrame(state, frame, geometry)
    ObserveValue(state, frame, true)
    if not frame then return end
    for _, method in ipairs(OBSERVED_FRAME_METHODS) do
        ObserveValue(state, frame[method] and frame[method](frame))
    end
    if geometry then
        for _, method in ipairs(OBSERVED_GEOMETRY_METHODS) do
            ObserveValue(state, frame[method] and frame[method](frame))
        end
    end
end

function Tracker:LayoutInputsChanged(profile)
    local state = self.layoutObservation or {}
    self.layoutObservation = state
    local previousCount = state.count
    state.count, state.changed = 0, not state.initialized
    local frame, bounds, provider, header = self:Resolve()
    ObserveValue(state, APR.snappedLayoutRevision)
    ObserveValue(state, profile, true)
    ObserveValue(state, provider)
    for _, key in ipairs(OBSERVED_PROFILE_KEYS) do ObserveValue(state, profile[key]) end
    local offset, position = profile.currentStepTrackerOffset, profile.currentStepTrackerPosition
    ObserveValue(state, offset and offset.x); ObserveValue(state, offset and offset.y)
    ObserveValue(state, position and position.x); ObserveValue(state, position and position.y)
    ObserveFrame(state, UIParent)
    ObserveFrame(state, frame, true)
    if bounds ~= frame then ObserveFrame(state, bounds, true) end
    ObserveFrame(state, header)
    ObserveValue(state, frame and frame.isMoving)
    ObserveValue(state, frame and frame.isSizing)
    ObserveValue(state, _G.EditModeManagerFrame and EditModeManagerFrame:IsShown())
    if provider == "blizzard" and self:GetSide(profile) == "below" then
        local anchor = header or frame
        for i = #(frame and frame.modules or {}), 1, -1 do
            if frame.modules[i]:IsShown() then anchor = frame.modules[i]; break end
        end
        ObserveFrame(state, anchor, true)
    end
    for _, name in ipairs(OBSERVED_PANEL_NAMES) do
        ObserveFrame(state, _G[name])
    end
    local current = _G.CurrentStepScreenPanel
    ObserveValue(state, current and current.collapsed)
    if current and current.GetPoint then
        local point, relative, relativePoint, x, y = current:GetPoint(1)
        ObserveValue(state, point); ObserveValue(state, relative, true)
        ObserveValue(state, relativePoint); ObserveValue(state, x); ObserveValue(state, y)
    end
    state.initialized = true
    return state.changed or previousCount ~= state.count
end

function Tracker:RefreshObservedLayout(elapsed)
    if InCombatLockdown() or (APR.LayoutEditor and APR.LayoutEditor.active) then
        self.layoutObservation = nil
        return
    end
    local profile = APR:GetSettingsProfile()
    if not profile or not profile.enableAddon or not profile.currentStepAttachFrameToQuestLog or
        not CurrentStepScreenPanel:IsShown() then
        self.layoutObservation, self.layoutSafetyElapsed = nil, 0
        if self.displacement then self:Release() end
        return
    end
    self.layoutSafetyElapsed = (self.layoutSafetyElapsed or 0) + (elapsed or 0.2)
    local probeStart = APR.StartPerformanceSample and APR:StartPerformanceSample()
    local changed = self:LayoutInputsChanged(profile)
    if APR.FinishPerformanceSample then APR:FinishPerformanceSample("TrackerGeometryProbe", probeStart) end
    -- The safety pass catches third-party changes not exposed by the geometry probe.
    if not changed and self.layoutSafetyElapsed < 1 then return end
    self.layoutSafetyElapsed = 0
    local started = APR.StartPerformanceSample and APR:StartPerformanceSample()
    if APR:ShouldHideFrames() then
        self:Release()
        self.layoutObservation = nil
    else
        APR:RefreshSnappedFrames()
        APR.currentStep:RefreshQuestTrackerAnchor()
        -- Remember applied geometry, including the revision from our own snapping.
        self:LayoutInputsChanged(profile)
    end
    if APR.FinishPerformanceSample then APR:FinishPerformanceSample("TrackerLayoutUpdate", started) end
end

function Tracker:Initialize()
    if self.observer then return end
    self.observer = CreateFrame("Frame")
    local elapsed, appearanceElapsed = 0, 0
    self.observer:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        appearanceElapsed = appearanceElapsed + delta
        if elapsed < 0.2 then return end
        local interval = elapsed
        elapsed = 0
        if InCombatLockdown() or (APR.LayoutEditor and APR.LayoutEditor.active) then
            self.layoutObservation = nil
            return
        end
        local profile = APR:GetSettingsProfile()
        if not profile or not profile.enableAddon then
            appearanceElapsed = 0
            self:RefreshObservedLayout(interval)
            return
        end
        -- External font/theme changes need a safety poll; settings already refresh
        -- appearance explicitly. Keep it separate from the cheap geometry probe.
        if appearanceElapsed >= 1 then
            appearanceElapsed = 0
            local started = APR.StartPerformanceSample and APR:StartPerformanceSample()
            self:RefreshAppearance()
            if APR.FinishPerformanceSample then APR:FinishPerformanceSample("TrackerAppearanceUpdate", started) end
        end
        self:RefreshObservedLayout(interval)
    end)
    self.observer:RegisterEvent("PLAYER_LOGOUT")
    self.observer:SetScript("OnEvent", function() self:Release() end)
end
