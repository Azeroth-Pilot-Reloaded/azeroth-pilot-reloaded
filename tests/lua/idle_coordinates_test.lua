local env = dofile("tests/lua/route_ui_test_env.lua")
APR.Color.defaultLightBackdrop = {0, 0, 0, 1}
local x, y, reads = 10, 20, 0
function UnitPosition() reads = reads + 1; return y, x end
dofile("APR-Core/ui/panels/Coordinates.lua")
local frame = CoordinateScreenPanel
local tick = frame.scripts.OnUpdate
local formats, writes = 0, 0
local round, setText = APR.coordinate.RoundCoords, frame.Text.SetText
function APR.coordinate:RoundCoords(...)
    formats = formats + 1
    return round(self, ...)
end
function frame.Text:SetText(text) writes = writes + 1; setText(self, text) end
for _ = 1, 600 do tick(frame, 1 / 60) end
assert(reads >= 49 and reads <= 50, "Coordinates are sampled at 5 Hz, independently of FPS")
assert(formats == 1 and writes == 1, "Stationary coordinates are formatted and written once")
x = x + 1
tick(frame, 0.2)
assert(frame.Text:GetText() == "11.00, 20.00" and formats == 2 and writes == 2)
x = x + 0.001
tick(frame, 0.2)
assert(writes == 2, "Subpixel movement cannot rewrite identical displayed coordinates")
x, y = nil, nil
tick(frame, 0.2)
tick(frame, 0.2)
assert(frame.Text:GetText() == "--------" and writes == 3, "Missing positions clear the display once")
x, y = 11, 20
tick(frame, 0.2)
assert(frame.Text:GetText() == "11.00, 20.00" and writes == 4, "Returning coordinates restore the display")
tick(frame, 3)
local afterStall = reads
for _ = 1, 6 do tick(frame, 1 / 60) end
assert(reads <= afterStall + 1, "A stalled frame cannot create a backlog of coordinate API calls")
print("Idle coordinates: 5 Hz sampling, unchanged-text reuse, unavailable-position recovery and no catch-up bursts")
