-- Invented routes and peers exercise real serialization, import and engine positions.
local env = dofile("tests/lua/route_prefab_test_env.lua")
local now, raid, instance, grouped, combat = 10, false, false, true, false
local timers, sent, printed = {}, {}, {}
local profile = { enableAddon = true }
function GetTime() return now end
function wipe(value) for key in pairs(value) do value[key] = nil end; return value end
function IsInRaid() return raid end
function IsInGroup(category) return grouped and (not category or instance) end
function InCombatLockdown() return combat end
LE_PARTY_CATEGORY_INSTANCE = 2
function GetNormalizedRealmName() return "Home" end
function APR:SafeUnitName(unit)
    if unit == "party1" then return "Peer", "Home" end
    if unit == "party2" then return "Peer", "Away" end
    if unit == "player" then return "Local", "Home" end
end
APR.Username = "Local"
function APR:GetSettingsProfile() return profile end
function APR:IsTemporaryRouteActive() return false end
DEFAULT_CHAT_FRAME = { AddMessage = function(_, value) printed[#printed + 1] = value end }
function APR:WrapTextWithAppearanceColor(value) return value end
function APR:Debug() end
function APR:NewModule()
    return { RegisterEvent = function() end, UnregisterAllEvents = function() end }
end
local function timer(delay, callback)
    local item = { at = now + delay, callback = callback, Cancel = function(self) self.cancelled = true end }
    timers[#timers + 1] = item
    return item
end
C_Timer = { NewTimer = timer, After = timer }
local function flush()
    for iteration = 1, 10000 do
        local due, keep = {}, {}
        for _, item in ipairs(timers) do
            if not item.cancelled then
                if item.at <= now then due[#due + 1] = item else keep[#keep + 1] = item end
            end
        end
        timers = keep
        if #due == 0 then return end
        for _, item in ipairs(due) do item.callback() end
    end
    error("unbounded timer loop")
end
Enum = { SendAddonMessageResult = { Success = 0 } }
C_ChatInfo = {
    RegisterAddonMessagePrefix = function() return true end,
    SendAddonMessage = function(prefix, message, channel)
        sent[#sent + 1] = { prefix = prefix, message = message, channel = channel }
        return 0
    end,
}
local L = setmetatable({}, { __index = function(_, key) return key .. " %s" end })
LibStub = nil
strmatch = string.match
dofile("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
dofile("APR-Core/libs/AceSerializer-3.0/AceSerializer-3.0.lua")
local serializer, realStub = LibStub("AceSerializer-3.0"), LibStub
LibStub = function(name, optional)
    if name == "AceLocale-3.0" then return { GetLocale = function() return L end } end
    return realStub(name, optional)
end
local dialog
local function show(settings)
    if dialog and dialog.onCancel then local cancel = dialog.onCancel; dialog.onCancel = nil; cancel() end
    dialog = settings
    dialog.dialogGeneration = 1
    dialog.description = { SetText = function(_, text) settings.text = text end }
    function dialog:Hide()
        local cancel = self.onCancel
        self.onCancel = nil
        if cancel then cancel() end
    end
    return dialog
end
APR.UI = {
    ShowConfirmationDialog = function(_, text, accept, cancel)
        return show({ text = text, onAccept = accept, onCancel = cancel })
    end,
    ShowSelectionDialog = function(_, title, description, options, select, cancel)
        return show({ title = title, text = description, options = options, onSelect = select, onCancel = cancel })
    end,
}
local function choose(value)
    local current = dialog
    local callback = current.onAccept or current.onSelect
    current.onAccept, current.onSelect, current.onCancel = nil, nil, nil
    callback(value)
end
local updates, catalogs = 0, 0
function APR.routeconfig:SendCustomPathUpdate() updates = updates + 1 end
function APR.routeconfig:SendMessage() catalogs = catalogs + 1 end
dofile("APR-Core/features/questing/StepTransitions.lua")
dofile("APR-Core/features/group/PartyProtocol.lua")
dofile("APR-Core/features/group/PartyFinderProtocol.lua")
dofile("APR-Core/features/group/PathSharingProtocol.lua")
dofile("APR-Core/features/group/PathSharing.lua")
dofile("APR-Core/features/group/PathSharingImport.lua")
local nativeMenu = dofile("tests/lua/native_member_menu_test_env.lua")
dofile("APR-Core/features/group/PathSharingUI.lua")
local S, P = APR.PathSharing, APR.PathSharingProtocol
local function receive(message, sender, channel)
    S:OnAddonMessage("CHAT_MSG_ADDON", P.PREFIX, message, channel or "PARTY", sender or "Peer-Home")
end
local first = env.route("alpha", "First", {}, nil)
first.steps = { { Note = "one" }, { Note = "two", Class = "MAGE" }, { Note = "three" } }
env.route("beta", "Second", {}, nil)
APRCustomPath.player = { "First", "Second" }
APRData.player.alpha, APRData.player.beta = 1, 2
APR.ActiveRoute = "alpha"

for _, diagnostics in ipairs({ false, true }) do
    APRInstrumentation.enabled = diagnostics
    local previous = #printed
    assert(not S:SharePath("Peer-Home"), "Old/unadvertised peers are not recipients")
    assert(#printed == previous + 1 and printed[#printed] == "APR: " .. S.status,
        "Sharing reports through the real APR chat helper with diagnostics on or off")
end
APRInstrumentation.enabled = false
receive("H|1", "Stranger-Home")
assert(not next(S.peers), "Nonmembers cannot advertise or open a dialog")
receive("H|1")
assert(S.peers["Peer-Home"] and sent[#sent].message == "h|1")
assert(not S.peers["Peer-Away"], "Namesakes are distinct peers")
assert(S:SharePath("Peer-Home"))
local offered
for _, request in pairs(S.outgoing) do offered = request end
assert(offered and offered.packet.path[1] == "alpha" and offered.packet.path[2] == "beta")
receive("R|" .. offered.id, "Peer-Away")
assert(not offered.index, "Only the intended namesake can request data")
receive("R|" .. offered.id)
flush()
local chunks = {}
for _, message in ipairs(sent) do
    local id, index, total, data = message.message:match("^D|([^|]+)|(%d+)|(%d+)|(.*)$")
    if id == offered.id then chunks[tonumber(index)] = data end
end
assert(table.concat(chunks) == offered.wire, "The actual outgoing fragments reconstruct the payload")
receive("A|" .. offered.id)
assert(not next(S.outgoing))

local sequence = 0
local function deliver(packet)
    sequence = sequence + 1
    now = now + 11
    local wire, id = serializer:Serialize(packet), "incoming-" .. sequence
    receive("O|" .. id .. "|Local-Home|" .. packet.kind .. "|" .. #wire)
    local request = assert(S.incoming[id])
    choose() -- explicit consent to receive; no state has been imported
    assert(request.state == "receiving")
    local total = math.ceil(#wire / P.CHUNK)
    for index = total, 1, -1 do
        receive("D|" .. id .. "|" .. index .. "|" .. total .. "|" .. wire:sub((index - 1) * P.CHUNK + 1, index * P.CHUNK))
    end
    assert(request.state == "ready" and not request.parts)
    return request
end
local packet = assert(S:BuildPacket("path"))
local oldPath = APRCustomPath.player
local request = deliver(packet)
assert(APRCustomPath.player == oldPath and updates == 0)
choose({ value = "resume" })
assert(updates == 1 and APRCustomPath.player ~= oldPath)
assert(APRCustomPath.player[1] == "First" and APRCustomPath.player[2] == "Second")
assert(APRData.player.alpha == 1 and APRData.player.beta == 2, "Resume preserves both routes' progress")

packet.position = { route = "alpha", id = "main:2", fingerprint = S.Fingerprint(first) }
request = deliver(packet)
choose({ value = "join" })
assert(APRData.player.alpha == 3, "A sender step filtered for this character projects onto the following step")
assert(APRData.player.beta == 2 and updates == 2)

-- Invalid/stale acceptance cannot replace a path edited while the dialog is open.
request = deliver(packet)
APRCustomPath.player = { "Second" }
local before = updates
assert(not S:Apply(request, false, true))
assert(updates == before and APRCustomPath.player[1] == "Second")
S:Decline(request)

local custom = { label = "Recorded", steps = { { Coord = { x = 3, y = 8 }, PickUp = { 123 } }, { Note = "finish" } } }
assert(APR:RegisterCustomRoute("recorded", custom))
flush()
local routePacket = assert(S:BuildPacket("route", "recorded"))
APRData.CustomRoute.recorded.steps[1].PickUp[1] = 321
local stage = assert(S:Prepare(routePacket))
assert(stage.mapping.recorded == "recorded (1)" and stage.labels.recorded == "Recorded (1)")
oldPath, before = APRCustomPath.player, updates
request = deliver(routePacket)
choose()
assert(APRCustomPath.player == oldPath and updates == before, "A standalone route does not edit the path")
assert(APRData.CustomRoute["recorded (1)"].steps[1].PickUp[1] == 123)
assert(APRData.CustomRoute.recorded.steps[1].PickUp[1] == 321, "The local definition remains intact")
local saved = P.Copy(APRData.CustomRoute["recorded (1)"])
APR:LoadCustomRoutes()
assert(P.Equal(saved.steps, APR:GetRouteData("recorded (1)").steps), "Imported definitions survive a reload")

-- Missing official prerequisites exclude dependent custom routes, with explicit partial consent.
local missing = P.Copy(packet)
missing.position = nil
missing.path = { "alpha", "missing", "dependent" }
missing.routes[#missing.routes + 1] = { key = "missing", label = "Absent", custom = false, required = {} }
missing.routes[#missing.routes + 1] = { key = "dependent", label = "Dependent", custom = true, required = { "missing" },
    data = { label = "Dependent", requiredRoute = { "missing" }, steps = { { Note = "dependent" } } } }
stage = assert(S:Prepare(missing))
assert(#stage.path == 1 and stage.path[1] == "alpha" and #stage.missing == 2)
request = deliver(missing)
choose({ value = "resume" })
assert(dialog.onAccept, "Partial imports require a separate confirmation")
choose()
assert(#APRCustomPath.player == 1 and APRCustomPath.player[1] == "First")
assert(not APRData.CustomRoute.dependent)

-- Identical local parents must not be rewritten when a child receives an alias.
local parent = { label = "Parent", requiredRoute = { "recorded" }, steps = { { Note = "parent" } } }
APR:RegisterCustomRoute("parent", parent)
local parents = P.Copy(routePacket)
parents.path = { "parent" }
parents.routes[#parents.routes + 1] = { key = "parent", label = "Parent", custom = true, required = { "recorded" }, data = parent }
stage = assert(S:Prepare(parents))
assert(stage.mapping.parent ~= "parent")
assert(stage.imports.parent.data.requiredRoute[1] == stage.mapping.recorded)
assert(APRData.CustomRoute.parent.requiredRoute[1] == "recorded")

-- Reused definitions are retained exactly; a failed batch rolls back earlier registrations.
local unchanged = P.Copy(routePacket)
unchanged.routes[1].key, unchanged.routes[1].label = "recorded (1)", "Recorded (1)"
unchanged.routes[1].data.label, unchanged.path[1] = "Recorded (1)", "recorded (1)"
stage = assert(S:Prepare(unchanged))
assert(not next(stage.imports) and stage.mapping["recorded (1)"] == "recorded (1)")
request = deliver(parents)
local register, registered = APR.RegisterCustomRoute, {}
function APR:RegisterCustomRoute(key, data, deferred)
    registered[#registered + 1] = key
    if #registered == 2 then return false end
    return register(self, key, data, deferred)
end
before, oldPath = updates, APRCustomPath.player
assert(not S:Apply(request, false, true))
assert(#registered == 2 and not APRData.CustomRoute[registered[1]])
assert(APRCustomPath.player == oldPath and updates == before)
APR.RegisterCustomRoute = register

-- Both client contracts use the same packet schema; cross-client imports stay rejected.
env.gameVersion = APR.GAME_VERSIONS.Retail
local retail = P.Copy(routePacket); retail.client = env.gameVersion
request = deliver(retail)
choose()
assert(not S.incoming[request.id])
env.gameVersion = APR.GAME_VERSIONS.Forever

-- The right-click action targets exactly the selected member; the route chooser
-- leaves unadvertised members disabled rather than silently broadcasting.
S:ShowMemberMenu("Peer-Home")
assert(nativeMenu.which == "PARTY" and nativeMenu.context.unit == "party1")
assert(nativeMenu.root.additions[1].enabled)
local target, sharedRoute
local sharePath, shareRoute = S.SharePath, S.ShareRoute
function S:SharePath(name) target = name end
nativeMenu.root.additions[1].callback(); assert(target == "Peer-Home")
function S:ShareRoute(key, name) sharedRoute, target = key, name end
S:ChooseRecipient("recorded")
local disabled
for _, option in ipairs(dialog.options) do
    if option.value == "Peer-Away" then disabled = option.enabled == false end
end
assert(disabled)
choose({ value = "Peer-Home" })
assert(sharedRoute == "recorded" and target == "Peer-Home")
S.SharePath, S.ShareRoute = sharePath, shareRoute

-- Joining a newly received definition projects after installation, including aliases.
local customJoin = P.Copy(routePacket)
customJoin.kind = "path"
customJoin.position = { route = "recorded", id = "main:2",
    fingerprint = S.Fingerprint(APR:NormalizeCustomRouteDefinition("recorded", customJoin.routes[1].data)) }
request = deliver(customJoin)
assert(dialog.options[2].enabled)
choose({ value = "join" })
local joined = APRData.player.RouteChoices[APRCustomPath.player[1]]
assert(joined ~= "recorded" and APRData.player[joined] == 2)
assert(APR:GetRouteData(joined).steps[1].PickUp[1] == 123)

-- Malformed data and resource exhaustion are rejected before engine registration.
assert(not P.Definition({ steps = { { PickUp = "bad" } } }))
assert(not P.Definition({ steps = { { Note = true } } }))
assert(not P.Definition({ steps = { { UseSpell = { spellID = "bad" } } } }))
assert(not P.Definition({ steps = { { UseSpell = {} } } }))
assert(not P.Definition({ steps = { { Qpart = { [123] = true } } } }))
assert(P.Definition({ steps = { { Note = "target", Level = { level = 4, xp = 25 } } } }))
assert(P.Definition({ steps = { { Group = { questID = 222, Number = 2 }, Dungeon = "synthetic-instance" } } }))
local cycle = {}; cycle.self = cycle
assert(not P.Data(cycle))
assert(not P.Data({ callback = function() end }))
assert(not P.Data({ value = math.huge }))
assert(not P.Array({ [1] = "a", [3] = "b" }, 3))
local bad = P.Copy(routePacket); bad.routes[1].required = { "unknown" }
assert(not P.Packet(bad))
bad = P.Copy(packet); bad.client = "other-client"
assert(not S:Prepare(bad))

-- Cancellation, fragment duplication/conflicts, expiry, combat and channel isolation.
now = now + 11
local externalShown = true
APR.UI.selectionDialog = { IsShown = function() return externalShown end, dialogGeneration = 99 }
receive("O|other-dialog|Local-Home|path|100")
assert(S.incoming["other-dialog"] and not S.prompt, "Sharing must not cancel another APR dialog")
externalShown = false
S:ShowNext()
assert(S.prompt == S.incoming["other-dialog"])
S:Decline(S.prompt)
APR.UI.selectionDialog = nil
flush()
now = now + 11
receive("O|pending|Local-Home|path|280")
request = assert(S.incoming.pending)
choose()
receive("D|pending|1|2|" .. string.rep("x", P.CHUNK))
local count = request.count
receive("D|pending|1|2|" .. string.rep("x", P.CHUNK))
assert(request.count == count)
receive("D|pending|1|2|" .. string.rep("y", P.CHUNK))
assert(not S.incoming.pending)
now = now + 11
combat = true
receive("O|combat|Local-Home|path|100")
request = assert(S.incoming.combat)
assert(S.prompt == nil and request.state == "offered")
combat = false; S:ShowNext(); assert(S.prompt == request)
now = now + P.IDLE_TTL + 1; S:Sweep()
assert(not S.incoming.combat and not S.prompt)
instance = true
receive("H|1", "Peer-Away", "PARTY")
assert(not S.peers["Peer-Away"])
receive("H|1", "Peer-Away", "INSTANCE_CHAT")
assert(S.peers["Peer-Away"])
raid = true; S:Sweep()
assert(not next(S.peers) and not S:SharePath())
raid = false; grouped = false; S:RefreshRoster()
assert(not S:IsAvailable(), "The UI shares the transport's solo guard")
assert(not next(S.incoming) and not next(S.outgoing))
grouped, instance = true, false
receive("H|1")
local completion
ChatThrottleLib = { SendAddonMessage = function(_, _, _, _, _, _, _, callback) completion = callback end }
assert(S:SharePath("Peer-Home"))
for _, outgoing in pairs(S.outgoing) do offered = outgoing end
receive("R|" .. offered.id)
assert(completion and offered.index == 1)
S:OnDisable()
completion(nil, true); flush()
assert(not next(S.outgoing), "A queued callback cannot revive a cancelled transfer")
print("Path sharing: real wire, consent, progress, filtered joining, standalone routes, aliases, dependencies, partial imports and bounded lifecycle passed")
