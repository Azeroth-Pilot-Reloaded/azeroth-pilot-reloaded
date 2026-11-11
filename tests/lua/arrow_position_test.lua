-- Screen coordinates must round-trip through UIParent units at every UI scale.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
UIParent:SetSize(1600, 900)
UIParent:SetScale(0.64)
function GetScreenWidth() return 1024 end
function GetScreenHeight() return 576 end
function env.methods:StartMoving() self.moving = true end
function env.methods:GetLeft() return self.left end
function env.methods:GetTop() return self.top end
function env.methods:SetDontSavePosition(value) self.dontSavePosition = value end
function APR:IsPetBattleActive() return false end
function APR:IsInstanceWithUI() return true end
dofile("APR-Core/features/navigation/Arrow.lua")
local arrow, profile, anchor = APR.Arrow, APR.settings.profile, APR.ArrowFrameM
profile.arrowScale, profile.arrowStyle = 1, "classic"
profile.arrowleft, profile.arrowtop = 3000, -2000
arrow:Init()
assert(profile.arrowleft == 1544 and profile.arrowtop == -858)
assert(anchor.point[4] == 1544 and anchor.point[5] == -858)

profile.arrowleft, profile.arrowtop = -500, 200
arrow:RestorePosition()
assert(profile.arrowleft == 0 and profile.arrowtop == 0)
profile.arrowleft, profile.arrowtop = 350, -420
arrow:Init()
assert(profile.arrowleft == 350 and profile.arrowtop == -420)

-- The native layout cache must not compete with the profile or identify the
-- artwork and drag anchor as the same frame. Reattach legacy cached artwork
-- when entering the world, even when the saved profile itself is unchanged.
assert(anchor.name ~= APR.ArrowFrame.name, "Anchor and artwork need distinct native identities")
assert(anchor.dontSavePosition and APR.ArrowFrame.dontSavePosition, "Only the profile persists arrow placement")
APR.ArrowFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
anchor.scripts.OnEvent(anchor, "PLAYER_ENTERING_WORLD")
assert(anchor.point[4] == 350 and anchor.point[5] == -420)
assert(APR.ArrowFrame.point[2] == anchor and APR.ArrowFrame.point[4] == 0 and APR.ArrowFrame.point[5] == 0,
    "Loading restores artwork attachment instead of leaving it at a cached screen position")

-- Drag capture uses effective-scale ratios, never the physical screen height.
anchor.left, anchor.top = 500, 700
APR.ArrowFrame.scripts.OnMouseDown(APR.ArrowFrame, "LeftButton")
APR.ArrowFrame.scripts.OnMouseUp(APR.ArrowFrame, "LeftButton")
assert(profile.arrowleft == 500 and profile.arrowtop == -200)
local draft = env.widget(UIParent)
draft:SetScale(1.5)
draft.left, draft.top = 200, 400
arrow:SavePosition(draft)
assert(profile.arrowleft == 300 and profile.arrowtop == -300)

-- Bad legacy values recover without corrupting valid coordinates on the other axis.
profile.arrowleft, profile.arrowtop = 0 / 0, -100
arrow:RestorePosition()
assert(math.abs(profile.arrowleft - 1600 / 2.05) < 0.001 and profile.arrowtop == -100)
profile.arrowleft, profile.arrowtop = "invalid", math.huge
arrow:RestorePosition()
assert(math.abs(profile.arrowleft - 1600 / 2.05) < 0.001 and profile.arrowtop == -600)
profile.arrowleft, profile.arrowtop = 1500, -800
profile.arrowScale = 3
arrow:ApplySize()
assert(profile.arrowleft == 1432 and profile.arrowtop == -774)
UIParent:SetSize(1000, 600)
anchor.scripts.OnEvent(anchor, "DISPLAY_SIZE_CHANGED")
assert(profile.arrowleft == 832 and profile.arrowtop == -474)
UIParent:SetSize(800, 500)
UIParent:SetScale(0.8)
anchor.scripts.OnEvent(anchor, "UI_SCALE_CHANGED")
assert(profile.arrowleft == 632 and profile.arrowtop == -374)
local left, top = arrow:ClampPosition(-20, -1000, 2000, 1000)
assert(left == 0 and top == 0, "Oversized artwork keeps its top-left visible")
UIParent:SetSize(0, 0)
arrow:RestorePosition()
assert(profile.arrowleft == 632 and profile.arrowtop == -374)
UIParent:SetSize(1600, 900)

-- Real editor opening recovers an off-screen preview without committing the draft.
SAVE, PREVIEW = "SAVE", "PREVIEW"
local oldLibStub = LibStub
function LibStub(name, ...)
    if name == "LibWindow-1.1" then
        return { RegisterConfig = function() end, RestorePosition = function() end }
    end
    return oldLibStub(name, ...)
end
function APR:SetupFrameDrag() end
function APR:PrintInfo() end
dofile("APR-Core/utils/Utils.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/panels/LayoutEditor.lua")
APR.currentStep = { RefreshCurrentStepFrameAnchor = function() end }
APR.fillersFrame = { RefreshFillersFrame = function() end }
APR.AFK = { RefreshFrameAnchor = function() end }
APR.questOrderList = { RefreshFrameAnchor = function() end }
profile.arrowleft, profile.arrowtop = 3000, -2000
local editor = APR.LayoutEditor
editor:Show()
local preview
for _, candidate in ipairs(editor.previews) do
    if candidate.definition.arrow then preview = candidate end
end
assert(preview:IsShown() and preview.point[4] == 1432 and preview.point[5] == -774)
assert(profile.arrowleft == 3000 and profile.arrowtop == -2000)
editor:Hide()
assert(profile.arrowleft == 3000 and profile.arrowtop == -2000, "Cancel preserves the saved anchor")
editor:Show()
preview.left, preview.top = 2000, -100
anchor.scripts.OnEvent(anchor, "UI_SCALE_CHANGED")
assert(preview.point[4] == 1432 and preview.point[5] == -774)
editor:Hide()
assert(profile.arrowleft == 1432 and profile.arrowtop == -774)
profile.arrowleft, profile.arrowtop = 3000, -2000
editor:Show()
preview:SetScale(1.5)
preview.left, preview.top, preview.changed = 200, 400, true
assert(editor:Save())
assert(math.abs(profile.arrowleft - 300) < 0.001 and math.abs(profile.arrowtop + 300) < 0.001)
assert(math.abs(anchor.point[4] - 300) < 0.001 and math.abs(anchor.point[5] + 300) < 0.001)
print("Arrow placement: scaled dragging, bounds, recovery, resize and transactional editor preview passed")
