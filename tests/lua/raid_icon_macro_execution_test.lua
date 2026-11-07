-- A deliberately small native-command simulator. It cannot certify taint/security;
-- it checks the generated command sequence against synthetic named NPCs.
APR, APRData = {}, { NPCList = { [101] = "Premier", [202] = "Second" } }
dofile("APR-Core/utils/SecretUtils.lua")
dofile("APR-Core/utils/TargetUtils.lua")
local version = "retail"
function APR:GetGameVersion() return version end
function GetBuildInfo() return "", "", "", 120007 end
function UnitExists() return false end
function SetRaidTarget() error("The addon must not call this protected API") end
function GetRaidTargetIndex() return nil end
local macro = APR:BuildRaidIconMacro({ 101, 202 })
local function click(world)
    local target, changes = nil, 0
    for line in macro:gmatch("[^\n]+") do
        local name = line:match("^/targetexact (.+)$")
        local prefix, value = line:match("^/targetmarker %[@target,exists,nodead%] ([!~])(%d)$")
        local marker = tonumber(value)
        if version == "forever" and prefix == "~" then marker = nil end
        if line == "/cleartarget" then target = nil
        elseif name then target = world[name] or target
        elseif marker and target and not target.dead and
            ((prefix == "~" and not target.marker) or (prefix == "!" and target.marker ~= marker)) then
            target.marker, changes = marker, changes + 1
        elseif line == "/stopmacro [exists,nodead]" and target and not target.dead then break
        elseif line == "/cleartarget [dead]" and target and target.dead then target = nil end
    end
    return target, changes
end
local first, second = { id = 101 }, { id = 202 }
local target, changes = click({ Premier = first, Second = second, Unrelated = { id = 999 } })
assert(target == first and first.marker == 8 and not second.marker and changes == 1,
    "The first living candidate stops the macro before later NPCs can overwrite its marker")
target, changes = click({ Premier = first, Second = second })
assert(target == first and first.marker == 8 and changes == 0, "A repeated click does not toggle")
target, changes = click({ Second = second })
assert(target == second and second.marker == 7 and first.marker == 8 and changes == 1,
    "An absent first candidate falls through to the second candidate's own marker")
second.marker = 2
target, changes = click({ Premier = { id = 101, dead = true }, Second = second })
assert(target == second and second.marker == 2 and changes == 0, "Skip a dead candidate and preserve an existing group marker")
target, changes = click({ Premier = { id = 101, dead = true }, Unrelated = { id = 999 } })
assert(not target and changes == 0, "An exhausted search clears a corpse without marking unrelated units")
target, changes = click({ Unrelated = { id = 999 } })
assert(not target and changes == 0, "Missing candidates never fall back to an unrelated target")
print("RaidIcon native command sequence: living order, fallback, distinct markers and preservation passed")

version = "forever"
macro = APR:BuildRaidIconMacro(101)
local unmarked = {id = 101}
target, changes = click({Premier = unmarked})
assert(target == unmarked and unmarked.marker == 8 and changes == 1,
    "Forever's native ! syntax must actually apply skull, not silently ignore unsupported ~")
target, changes = click({Premier = unmarked})
assert(unmarked.marker == 8 and changes == 0, "Repeated Forever presses keep skull instead of toggling it off")
