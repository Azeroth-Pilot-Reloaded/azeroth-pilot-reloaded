-- A native map match does not need projected coordinates on a moving vessel.
-- Keep the controller, step-zone selection and map helpers real; no live guide.
local noop = function() end
for _, profile in ipairs({ "retail", "forever" }) do
    local f = dofile("tests/lua/navigation_fixture.lua")
    f.profile, f.currentMap = profile, 82002
    f.maps = {
        [82001] = { mapID = 82001, mapType = 3, parentMapID = 0 },
        [82002] = { mapID = 82002, mapType = 3, parentMapID = 0 },
        [82003] = { mapID = 82003, mapType = 3, parentMapID = 0 },
        [82004] = { mapID = 82004, mapType = 5, parentMapID = 82002 },
        [82005] = { mapID = 82005, mapType = 3, parentMapID = 0 },
    }
    f.translations = setmetatable({}, { __index = function(_, key) return key end })
    f.player = {} -- UnitPosition is unavailable, but native map identity is known.
    C_Map.GetBestMapForUnit = function() return f.currentMap end
    local data = f:Load({ config = { IsolatedAreas = {} } })
    dofile("APR-Core/utils/Utils.lua")
    dofile("APR-Core/utils/StepUtils.lua")
    APR.Debug = noop
    dofile("APR-Core/utils/NavigationZones.lua")

    local step = { PickUp = { 930001 }, Zones = { 82001, 82002, 82003 } }
    local steps, rows = { step }, {}
    APR.PlayerID, APR.ActiveRoute = "player", "invented-vessel"
    APR.RouteQuestStepList = { [APR.ActiveRoute] = steps }
    APR.settings = { profile = { enableAddon = true } }
    APR.GAME_VERSIONS = { Forever = "forever" }
    APRData = { player = { [APR.ActiveRoute] = 1 } }
    function APR:NewModule() return {} end
    function APR:GetGameVersion() return profile end
    function APR:GetCurrentStep() return step, 1, steps end
    function APR:PeekCurrentStep() return step end
    function APR:GetCurrentRouteMapIDsAndName() return { 82001 }, 82001 end
    function APR:GetScenarioStepTarget() return nil end
    local scenarioRequired = false
    function APR:GetScenarioMapIDForStep() return scenarioRequired and 82005 or nil end
    function APR:IsInScenarioStep() return false end
    function APR:GetScenarioZoneInfo() return nil end
    function UnitIsDeadOrGhost() return false end
    APR.Arrow = { SetCoord = noop, SetArrowActive = noop }
    APR.event, APR.SendMessage = { QueueStepRefresh = noop }, noop
    APR.currentStep = { questsList = rows, pendingRemoval = {}, questsExtraTextList = {} }
    function APR.currentStep:AddQuestSteps(key, text, id) rows[key .. "-" .. id] = { text = text } end
    function APR.currentStep:FlushPendingContainers()
        for key in pairs(self.pendingRemoval) do rows[key] = nil end
        self.pendingRemoval = {}
    end
    C_Timer = { NewTimer = function(_, callback)
        return { callback = callback, Cancel = noop }
    end }
    dofile("APR-Core/features/questing/StepTransitions.lua")
    local plans = 0
    APR.NavigationPlanner = { Create = function()
        plans = plans + 1
        error("Positionless instructions must not invent a travel destination")
    end }
    dofile("APR-Core/features/navigation/Navigation.lua")
    local nav = APR.navigation
    local function update()
        APR:InvalidatePlayerZoneCache(false)
        nav:ForceRefresh(); nav:Update()
    end
    local function ready()
        assert(nav:GetState() == "ready" and APR.IsInRouteZone and not nav.search and not nav:IsNavigating())
        assert(next(rows) == nil and plans == 0, "A local instruction has no waiting/calculating row or invented path")
        assert(APRData.player[APR.ActiveRoute] == 1, "Zone readiness never completes an authored instruction")
    end

    nav:Update(); ready()
    assert(APR:GetContinent() == 0, "A missing continent cannot invalidate an explicit current-map match")
    for _ = 1, 10 do nav:Update() end
    ready()

    -- Available world coordinates do not change positionless zone selection.
    f.player = { x = 20, y = 30, z = 0, instanceID = 73 }
    update(); ready()
    f.player = {}
    f.currentMap = 82004 -- A micro map inside one declared zone.
    update(); ready()

    f.currentMap = 82005
    update()
    assert(nav:GetState() == "waiting_data" and not APR.IsInRouteZone and next(rows),
        "An unrelated map cannot satisfy a positionless instruction")
    f.currentMap = nil
    update()
    assert(nav:GetState() == "waiting_data" and not APR.IsInRouteZone,
        "Missing native map identity must remain pending")
    f.currentMap = 82002
    update(); ready()

    -- A real coordinate target still needs its world data, even with a valid start.
    f.player = { x = 20, y = 30, z = 0, instanceID = 73 }
    local mapToWorld = C_Map.GetWorldPosFromMapPos
    C_Map.GetWorldPosFromMapPos = function() return nil end
    step.Coord = { x = 40, y = 50 }
    update()
    assert(nav:GetState() == "waiting_data" and not APR.IsInRouteZone)
    C_Map.GetWorldPosFromMapPos = mapToWorld
    step.Coord = nil
    scenarioRequired = true
    update()
    assert(nav:GetState() == "waiting_data" and not APR.IsInRouteZone,
        "A local zone match cannot bypass a required scenario entrance")
    scenarioRequired = false
    update(); ready()

    -- A single Zone and the route fallback follow the same map-only rule.
    step.Zones, step.Zone = nil, 82002
    update(); ready()
    step.Zone, f.currentMap = nil, 82001
    update(); ready()
    assert(data.profile == profile)
end
print("Positionless navigation: declared maps, missing positions, parent zones, recovery and entrance guards passed")
