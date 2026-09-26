-- Load the navigation arrow with WoW-like global-name checks. WoW rejects a
-- second CreateFrame call that reuses an existing global frame name.
local function noop() end
local names = {}
local methods = {}
local function widget(parent)
    return setmetatable({ parent = parent }, { __index = methods })
end

methods.CreateTexture = function() return widget() end
methods.CreateFontString = function() return widget() end
methods.GetStringWidth = function() return 20 end
methods.GetStringHeight = function() return 20 end
methods.SetScript = function(self, event, callback)
    local scripts = rawget(self, "scripts")
    if not scripts then
        scripts = {}
        self.scripts = scripts
    end
    scripts[event] = callback
end
methods.Show = function(self) self.shown = true end
methods.Hide = function(self) self.shown = false end
methods.IsShown = function(self) return self.shown end

setmetatable(methods, {
    __index = function()
        return noop
    end,
})

function CreateFrame(_, name, parent)
    assert(not name or not names[name], "Duplicate global frame name: " .. (name or "<anonymous>"))
    local frame = widget(parent)
    if name then
        names[name] = frame
        _G[name] = frame
    end
    return frame
end

function LibStub()
    return { GetLocale = function() return { SKIP_WAYPOINT = "Skip waypoint" } end }
end

UIParent = CreateFrame("Frame", "ArrowTestUIParent")
APR = {
    GAME_VERSIONS = { Forever = "forever" },
    settings = { profile = {} },
}

function APR:NewModule() return {} end
function APR:GetGameVersion() return "retail" end
function APR:RegisterFontString() end

dofile("APR-Core/features/navigation/Arrow.lua")

assert(APR.ArrowFrameM == APR_ArrowAnchor, "The movable anchor must retain its global frame")
assert(APR.ArrowFrame == APR_Arrow, "The visible arrow must retain its public global frame")
assert(APR.ArrowFrameM ~= APR.ArrowFrame, "Anchor and visible arrow must be separate frames")

APR.settings.profile.arrowFPS = 0
APR.Arrow:SetArrowActive(true, 1, 1)
assert(APR.Arrow.arrowUpdateRate == 0.02, "Invalid saved arrowFPS must use the default update interval")
local calculations = 0
APR.Arrow.CalculPosition = function() calculations = calculations + 1 end
APR.ArrowFrame.scripts.OnUpdate(APR.ArrowFrame, 0.01)
assert(calculations == 0, "Arrow update waits for the fallback interval")
APR.ArrowFrame.scripts.OnUpdate(APR.ArrowFrame, 0.01)
assert(calculations == 1, "Arrow update runs after the fallback interval")
print("Arrow frame names and invalid update intervals are handled safely")
