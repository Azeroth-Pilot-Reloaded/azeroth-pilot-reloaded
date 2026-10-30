-- A reusable candidate avoids enumerating a large journal for every replan;
-- ownership and usability remain native, live observations.
local function fixture(profile)
    local state = { now = 10, allCollected = true, ownership = {}, usableID = 1000,
        counts = { ids = 0, dragonIDs = 0, info = 0, usable = 0 } }
    local function noop() end
    function GetTime() return state.now end
    function IsFlyableArea() return state.flyable ~= false end
    function IsIndoors() return state.indoors == true end
    function CreateFrame() return { RegisterEvent = noop, SetScript = noop } end
    function LibStub() return { GetLocale = function() return {} end } end
    APR = { GAME_VERSIONS = { Forever = "forever" }, NewModule = function() return {} end }
    function APR:GetGameVersion() return profile end
    function APR:CanAccessValue(value) return not rawequal(value, state.opaque) end
    C_PlayerInfo = { GetGlidingInfo = function() return false, state.gliding == true, 0 end }
    local ids = {}
    for index = 1, 1000 do ids[index] = index end
    function state:Collected(id)
        local value = self.ownership[id]
        if value ~= nil then return value end
        return self.allCollected
    end
    C_MountJournal = {
        IsDragonridingUnlocked = function() return state.unlocked ~= false end,
        GetCollectedDragonridingMounts = function()
            state.counts.dragonIDs = state.counts.dragonIDs + 1
            if state.missingList then return nil end
            local collected = {}
            for _, id in ipairs(ids) do if state:Collected(id) then collected[#collected + 1] = id end end
            return collected
        end,
        GetMountIDs = function()
            state.counts.ids = state.counts.ids + 1
            return not state.missingList and ids or nil
        end,
        GetMountInfoByID = function(id)
            state.counts.info = state.counts.info + 1
            if state.missingInfo then return nil end
            return "Synthetic mount", id, 1, false, id == state.usableID,
                1, false, false, nil, false, state:Collected(id)
        end,
        GetMountUsabilityByID = function(id, checkIndoors)
            assert(checkIndoors == true)
            state.counts.usable = state.counts.usable + 1
            return state.secretUsability and state.opaque or id == state.usableID
        end,
    }
    dofile("APR-Core/features/navigation/Navigation.lua")
    state.nav = APR.navigation
    return state
end

local state = fixture("retail")
local nav, counts = state.nav, state.counts
assert(nav:GetThreshold() == 10000 and counts.dragonIDs == 1 and counts.usable == 1000,
    "The cold synthetic journal really requires checking its last collected mount")
local info, usable = counts.info, counts.usable
for _ = 1, 100 do nav:InvalidatePathCache("QUEST_LOG_UPDATE"); assert(nav:GetThreshold() == 10000) end
assert(counts.dragonIDs == 1 and counts.info == info + 100 and counts.usable == usable + 100,
    "Replans revalidate one candidate without allocating/enumerating another mount list")
state.ownership[1000], state.usableID = false, 500
assert(nav:GetThreshold() == 10000 and nav._skyridingMountID == 500 and counts.dragonIDs == 2,
    "Lost ownership rejects the former candidate and finds another currently owned mount")
state.usableID = nil
assert(nav:GetThreshold() == 2000, "A formerly usable mount cannot preserve flight estimates after native rejection")
state.usableID = 100
assert(nav:GetThreshold() == 10000, "A previously negative search cannot hide newly usable mount data")
local lists = counts.dragonIDs
state.missingInfo = true
assert(nav:GetThreshold() == 10000 and counts.dragonIDs == lists + 1,
    "Unknown ownership falls back to the current collected list instead of trusting the cached candidate")
state.missingList = true
assert(nav:GetThreshold() == 2000, "Missing native observations retain the conservative ground threshold")
state.missingInfo, state.missingList = false, false
assert(nav:GetThreshold() == 10000, "Unavailable mount data remains retryable on the next observation")
lists, info, usable = counts.dragonIDs, counts.info, counts.usable
state.indoors = true
assert(nav:GetThreshold() == 2000)
state.indoors, state.flyable = false, false
assert(nav:GetThreshold() == 2000)
state.flyable, state.unlocked = true, false
assert(nav:GetThreshold() == 2000)
assert(counts.dragonIDs == lists and counts.info == info and counts.usable == usable,
    "Indoor, grounded and locked-flight contexts avoid the journal entirely")
state.unlocked, state.gliding = true, true
assert(nav:GetThreshold() == 10000 and counts.dragonIDs == lists,
    "The native current-mount capability takes priority without journal reads")
state.gliding, state.secretUsability, state.opaque = false, true, {}
assert(nav:GetThreshold() == 2000, "Opaque usability never becomes evidence of a usable mount")
state.secretUsability = false

state.allCollected, state.ownership, state.usableID = false, { [1000] = true }, 1000
nav._mountCapability, nav._usableMountID = nil, nil
lists, info, usable = counts.ids, counts.info, counts.usable
assert(nav:HasUsableMount() and counts.ids == lists + 1 and counts.info == info + 1000,
    "Ground discovery also encounters the last owned entry in a large journal")
lists, info, usable = counts.ids, counts.info, counts.usable
for _ = 1, 100 do nav:InvalidatePathCache("BAG_UPDATE_DELAYED"); assert(nav:HasUsableMount()) end
assert(counts.ids == lists and counts.info == info + 100 and counts.usable == usable + 100,
    "Inventory-triggered replans cannot repeatedly enumerate unowned ground mounts")
info, usable = counts.info, counts.usable
for _ = 1, 100 do assert(nav:HasUsableMount()) end
assert(counts.info == info and counts.usable == usable, "The existing short capability cache still avoids unchanged API reads")
state.now = state.now + 3
assert(nav:HasUsableMount() and counts.ids == lists and counts.info == info + 1,
    "An expired capability cache revalidates its candidate without rescanning the full journal")
state.usableID = nil
nav:InvalidatePathCache("SPELLS_CHANGED")
assert(not nav:HasUsableMount())
state.ownership[20], state.usableID = true, 20
nav:InvalidatePathCache("SPELLS_CHANGED")
assert(nav:HasUsableMount() and nav._usableMountID == 20, "Collection/ability changes can replace an unusable ground candidate")
state.ownership[20] = false
nav:InvalidatePathCache("collection")
assert(not nav:HasUsableMount(), "Ownership remains required even when native usability is still true for an unlearned mount")

state = fixture("forever")
assert(state.nav:GetThreshold() == 2000 and state.counts.dragonIDs == 0 and state.counts.usable == 0,
    "Forever never queries skyriding capabilities")
state.allCollected, state.ownership = false, { [1000] = true }
assert(state.nav:HasUsableMount())
local oldIDs = state.counts.ids
state.nav:InvalidatePathCache()
assert(state.nav:HasUsableMount() and state.counts.ids == oldIDs,
    "Forever shares the same revalidated ground-mount optimization")
state.missingInfo = true
state.nav:InvalidatePathCache()
assert(not state.nav:HasUsableMount(), "Missing ownership records cannot be reused as proof of ground mount availability")
state.missingInfo = false
state.nav:InvalidatePathCache()
assert(state.nav:HasUsableMount(), "A later native ownership observation recovers after unavailable data")
C_MountJournal.GetMountUsabilityByID = nil
state.nav:InvalidatePathCache()
assert(state.nav:HasUsableMount(), "Clients lacking a separate usability query retain the structured mount-info fallback")
C_MountJournal = nil
state.nav:InvalidatePathCache()
assert(not state.nav:HasUsableMount(), "Clients without a mount journal retain conservative estimates")
print("Navigation mounts: bounded repeat probes, live ownership/usability, unavailable data, restrictions and client fallbacks passed")
