-- One font callback per row must not remeasure the whole reader per callback.
local env = dofile("tests/lua/route_ui_test_env.lua")
dofile("tests/lua/localization_test_env.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/panels/ReleaseNotesPanel.lua")
local timers, fontCallbacks, measurements, lineHeight = {}, {}, 0, 12
C_Timer = { After = function(delay, callback)
    assert(delay == 0)
    timers[#timers + 1] = callback
end }
local function flush()
    local pending = timers
    timers = {}
    for _, callback in ipairs(pending) do callback() end
end
function env.methods:IsVisible()
    return self:IsShown() and (not self.parent or self.parent:IsVisible())
end
function APR:RegisterFontString(row, _, options)
    if options and options.onApplied then
        fontCallbacks[row] = options.onApplied
        options.onApplied(row)
    end
end
local blocks = {}
for index = 1, 200 do
    blocks[index] = { text = "Invented note " .. index, gap = 0, size = 12, indent = 0, role = "base" }
end
APR.changelog = { GetBlocks = function() return blocks end }
local reader = setmetatable({ rows = {} }, { __index = APR.ReleaseNotesPanel })
reader:CreateNotes(UIParent)
reader:RefreshNotes()
assert(#reader.rows == 200 and #timers == 0)
for _, row in ipairs(reader.rows) do
    function row:GetStringHeight() measurements = measurements + 1; return lineHeight end
end
reader:Layout()
assert(measurements == 200 and reader.content:GetHeight() == 4400)
measurements, lineHeight = 0, 32
for _, row in ipairs(reader.rows) do fontCallbacks[row](row) end
for _ = 1, 100 do reader.scroll.scripts.OnSizeChanged() end
assert(measurements == 0 and #timers == 1,
    "200 font callbacks plus a resize burst must schedule one deferred layout")
flush()
assert(measurements == 200 and reader.content:GetHeight() == 7600,
    "The final font metrics are measured once per row instead of 40,000 times")

measurements = 0
reader.notes:Hide()
for _, row in ipairs(reader.rows) do fontCallbacks[row](row) end
assert(#timers == 0 and measurements == 0, "Hidden readers never queue font-driven measurement")
reader.notes:Show()
UIParent:Hide()
reader:QueueLayout()
assert(#timers == 0, "A hidden ancestor also suppresses measurement")
UIParent:Show()
reader:QueueLayout()
reader.notes:Hide()
flush()
assert(measurements == 0 and not reader.layoutRequest, "Closing before the callback cancels its work")
reader.notes:Show()
lineHeight = 48
reader:RefreshNotes()
assert(measurements == 200 and reader.content:GetHeight() == 10800,
    "Reopening immediately catches up with hidden font changes")

-- An explicit content/layout refresh supersedes pending callbacks, while later
-- requests remain independent of an earlier stale callback in the same queue.
measurements, lineHeight = 0, 40
reader:QueueLayout()
reader:Layout()
assert(measurements == 200)
lineHeight = 44
reader:QueueLayout()
assert(#timers == 2)
flush()
assert(measurements == 400 and reader.content:GetHeight() == 10000,
    "A stale callback cannot consume or duplicate a newer layout request")
measurements = 0
reader:QueueLayout()
blocks = { blocks[1] }
reader:RefreshNotes()
assert(measurements == 1 and reader.content:GetHeight() == 50 and not reader.rows[2]:IsShown())
flush()
assert(measurements == 1, "A content publication cancels the earlier deferred layout")
print("Release layout: 200 font updates need 200 measurements instead of 40,000; resize, hidden parents, stale requests and reopen passed")
