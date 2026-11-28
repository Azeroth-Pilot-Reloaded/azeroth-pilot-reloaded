-- Exercise the real settings callbacks and LibWindow against two synthetic characters.
local env = dofile("tests/lua/route_ui_test_env.lua")
UIParent:SetSize(1920, 1080)
local character = "First"
function UnitNameUnmodified() return character end
function GetRealmName() return "Test" end
function GetLocale() return "enUS" end
function UnitFactionGroup() return "Neutral" end
function UnitClass() return "Mage", "MAGE" end
function UnitRace() return "Human", "Human" end
function GetCurrentRegionName() return "US" end
function GetCurrentRegion() return 1 end
min, max, abs = math.min, math.max, math.abs
table.wipe, strmatch = wipe, string.match
strlenutf8 = string.len
function securecallfunction(callback, ...) return callback(...) end

local watcher
function env.methods:RegisterEvent(event)
    self.events = self.events or {}
    self.events[event] = true
    if event == "PLAYER_ENTERING_WORLD" then watcher = self end
end
function env.methods:UnregisterEvent(event) self.events[event] = nil end
function env.methods:GetLeft() return self.left end
function env.methods:GetRight() return self.left + self:GetWidth() end
function env.methods:GetTop() return self.top end
function env.methods:GetBottom() return self.top - self:GetHeight() end

LibStub = nil
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
dofile("APR-Core/libs/HereBeDragons/CallbackHandler-1.0/CallbackHandler-1.0.lua")
dofile("APR-Core/libs/LibWindow-1.1/LibWindow-1.1.lua")
LibStub:NewLibrary("AceLocale-3.0", 1).GetLocale = function() return {} end
LibStub:NewLibrary("AceConfig-3.0", 1)
LibStub:NewLibrary("LibDataBroker-1.1", 1)
LibStub:NewLibrary("LibDBIcon-1.0", 1)
function APR:CreateTextAppearanceDefaults() return {} end
function APR:RequestReload() end
APR.Color.orange = { 1, 0.5, 0, 1 }
APR.currentStep = nil

dofile("APR-Core/ui/panels/LayoutEditor.lua")
dofile("APR-Core/config/Config.lua")
local editor, window = APR.LayoutEditor, LibStub("LibWindow-1.1")
local shared = {}
for index, definition in ipairs(editor.definitions) do
    if definition.frame then
        shared[definition.key] = { point = "TOPLEFT", x = index * 25, y = -index * 30, scale = 1.25 }
        local target = CreateFrame("Frame", definition.frame, UIParent)
        target:SetSize(180, 40)
        target:Hide()
        if definition.linked then shared[definition.linked] = false end
    end
end
APRSettings = {
    profileKeys = { ["First - Test"] = "Shared", ["Second - Test"] = "Shared" },
    profiles = { Shared = shared },
}

local function login()
    LibStub.libs["AceDB-3.0"], LibStub.minors["AceDB-3.0"] = nil, nil
    dofile("APR-Core/libs/AceDB-3.0/AceDB-3.0.lua")
    APR.settings:InitializeSettings()
    assert(APR.settings.db:GetCurrentProfile() == "Shared")
    for _, definition in ipairs(editor.definitions) do
        if definition.frame then
            -- A per-character native anchor has been restored after addon initialization.
            _G[definition.frame]:SetPoint("CENTER", UIParent, "CENTER", -400, -100)
        end
    end
    watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    watcher.scripts.OnEvent(watcher, "PLAYER_ENTERING_WORLD")
    assert(not watcher.events.PLAYER_ENTERING_WORLD)
end

local function checkSharedPositions()
    for index, definition in ipairs(editor.definitions) do
        if definition.frame then
            local target = _G[definition.frame]
            local point, _, _, x, y = target:GetPoint()
            assert(point == "TOPLEFT" and x == index * 20 and y == -index * 24, definition.frame)
            assert(target:GetScale() == 1.25 and not target:IsShown(), definition.frame)
        end
    end
end

login()
checkSharedPositions()
local dbFrame = LibStub("AceDB-3.0").frame
dbFrame.scripts.OnEvent(dbFrame, "PLAYER_LOGOUT")
character = "Second"
login()
checkSharedPositions()

local db = APR.settings.db
local xp = APRXPBuffOverlay
xp.secure = true
env.setCombat(true)
db:SetProfile("Other")
assert(watcher.events.PLAYER_REGEN_ENABLED and xp:GetScale() == 1.25)
env.setCombat(false)
watcher.scripts.OnEvent(watcher, "PLAYER_REGEN_ENABLED")
assert(not watcher.events.PLAYER_REGEN_ENABLED)
assert(select(4, xp:GetPoint()) == 280)

db:CopyProfile("Shared")
checkSharedPositions()
xp.left, xp.top = 200, 560
window.SavePosition(xp)
assert(db.profile.xpBuffFrame.x == 250 and db.profile.xpBuffFrame.y == 135)
assert(shared.xpBuffFrame.x == 200 and shared.xpBuffFrame.y == -240)
db:ResetProfile()
assert(select(4, xp:GetPoint()) == 280)
db:SetProfile("Shared")
checkSharedPositions()
print("Profile placement: both characters, hidden windows, native cache recovery, combat deferral, copy and reset passed")
