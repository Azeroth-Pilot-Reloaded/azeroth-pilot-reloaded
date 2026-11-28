local lib = LibStub("LibAPRNavigation-1.0")
local grid = auditGrid
local instance = setmetatable({ profile = "retail", env = {} }, lib.Instance)
local provider

local function isIndoor(tile, node)
    return (tile.class[node] or 0) % 8 == 4
end

local function point(st, world, ui, key, tile, cell, node)
    local x, y = grid.position(st, key, cell)
    return { instanceID = world, uiMapID = ui, x = x, y = y, z = grid.centerHeight(tile, node),
        indoors = isIndoor(tile, node) }
end

local function inside(box, p)
    return p.x >= box[1] and p.x <= box[3] and p.y >= box[2] and p.y <= box[4]
end

local function finish(job, deadline)
    repeat
        local status, result = job:Step(8192, 20)
        if status ~= "planning" then return status, result, job.error end
    until clock() >= deadline
    job:Cancel()
    return "timeout"
end

local function position(p)
    return { x = p.x, y = p.y, z = p.z, indoors = p.indoors }
end

local function walk(kind, a, b, milliseconds)
    local start = clock()
    local deadline = start + milliseconds
    local check = { kind = kind, from = position(a), to = position(b), outcome = "fail" }
    local status, result, error = finish(provider:CreatePathJob(a, b, { clock = clock, walkSpeed = 7 }), deadline)
    check.status, check.error = status, error
    check.unverifiedGeometry = result and result.unverifiedGeometry
    check.unresolvedSurface = result and result.unresolvedSurface
    if status == "ready" then
        local path = result.path or {}
        local first, last = path[1], path[#path]
        check.yards, check.geometryVerified = result.yards, result.geometryVerified == true
        check.points = #path
        local function matches(actual, expected)
            return actual and actual.instanceID == expected.instanceID and actual.z
                and math.abs(actual.x - expected.x) < .01 and math.abs(actual.y - expected.y) < .01
                and math.abs(actual.z - expected.z) <= 2.5
        end
        if #path < 2 or not matches(first, a) or not matches(last, b) then
            check.status = "wrong_endpoint"
        else
            check.outcome = "pass"
            for index = 2, #path do
                local segment = provider:CreateWalkingSegmentJob(path[index - 1], path[index], { clock = clock })
                local observed, _, segmentError = finish(segment, deadline)
                if observed ~= "ready" then
                    check.status, check.segmentStatus = "unverified_segment", observed
                    check.segment, check.error = index - 1, segmentError
                    check.outcome = "fail"
                    break
                end
            end
        end
    end
    check.milliseconds = math.floor(clock() - start + .5)
    return check
end

local function rejectShortcut(a, b, milliseconds)
    local job = provider:CreateWalkingSegmentJob(a, b, { clock = clock })
    local status, _, error = finish(job, clock() + milliseconds)
    return { kind = "stacked_shortcut", from = position(a), to = position(b), status = status, error = error,
        outcome = status == "no_path" and "pass" or "fail" }
end

local function ambiguousOrigin(a, b, milliseconds)
    local origin = { instanceID = a.instanceID, uiMapID = a.uiMapID, x = a.x, y = a.y, indoors = a.indoors }
    local job = provider:CreatePathJob(origin, b, { clock = clock, walkingOrigin = origin, walkingGoal = b })
    local status, result, error = finish(job, clock() + milliseconds)
    local declined = (status == "unavailable" or status == "no_path") and not error
    return { kind = "unknown_origin_floor", from = position(origin), to = position(b), status = status,
        ambiguous = result and result.ambiguousFrom == true, error = error, outcome = declined and "pass" or "fail" }
end

local function keysInBounds(st, box, field)
    local size = st.unit * st.c
    local keys = {}
    for packedKey in pairs(st.data.packed[field] or {}) do
        local key = packedKey - 1
        local x = st.x0 + math.floor(key / st.data.ny) * size
        local y = st.y0 + key % st.data.ny * size
        if x < box[3] and x + size > box[1] and y < box[4] and y + size > box[2] then
            keys[#keys + 1] = key
        end
    end
    table.sort(keys)
    return keys
end

local limits = { local_walk = 2, tile_boundary = 2, indoor_outdoor = 2, elevation_change = 2,
    stacked_shortcut = 2 }

local function sample(st, world, ui, box)
    local samples, counts = {}, {}
    local function add(kind, a, b)
        counts[kind] = (counts[kind] or 0) + 1
        samples[#samples + 1] = { kind, a, b }
    end
    local function needs(kind, pageKinds)
        return not pageKinds[kind] and (counts[kind] or 0) < limits[kind]
    end
    local keys = keysInBounds(st, box, "graph")
    -- Visit well-spaced pages first, then look through the remaining pages for rare cases.
    local order = {}
    for offset = 1, math.min(4, #keys) do
        for index = offset, #keys, 4 do order[#order + 1] = keys[index] end
    end
    for _, key in ipairs(order) do
        local pageKinds, seenCells = {}, {}
        local page, tile = grid.graphPage(st, key), grid.grid(st, key)
        if page and tile then
            for _, vertex in ipairs(page.nodes) do
                local node = grid.layer(tile, vertex.cell, vertex.layer)
                local a = node and point(st, world, ui, key, tile, vertex.cell, node)
                if a and inside(box, a) then
                    if needs("stacked_shortcut", pageKinds) and not seenCells[vertex.cell] then
                        seenCells[vertex.cell] = true
                        local other
                        for _, candidate in ipairs(tile.layers[vertex.cell] or {}) do
                            local here = point(st, world, ui, key, tile, vertex.cell, candidate)
                            if math.abs(a.z - here.z) >= 8 then
                                other = here
                                break
                            end
                        end
                        if other then
                            add("stacked_shortcut", a, other)
                            pageKinds.stacked_shortcut = true
                        end
                    end
                    for edge = 0, vertex.degree - 1 do
                        local destination, index = grid.edge(st, key, page.bytes, vertex.first + 14 * edge)
                        local targetPage = destination == key and page or grid.graphPage(st, destination)
                        local targetTile = destination == key and tile or grid.grid(st, destination)
                        local target = targetPage and targetPage.nodes[index]
                        local landing = target and targetTile and grid.layer(targetTile, target.cell, target.layer)
                        local b = landing and point(st, world, ui, destination, targetTile, target.cell, landing)
                        if b and inside(box, b) then
                            local horizontal = (a.x - b.x)^2 + (a.y - b.y)^2
                            local vertical = math.abs(a.z - b.z)
                            local kind
                            if destination ~= key and needs("tile_boundary", pageKinds) then
                                kind = "tile_boundary"
                            elseif vertical >= 8 and horizontal >= 16 and needs("elevation_change", pageKinds) then
                                kind = "elevation_change"
                            elseif a.indoors ~= b.indoors and horizontal >= 16 and needs("indoor_outdoor", pageKinds) then
                                kind = "indoor_outdoor"
                            elseif horizontal >= 400 and vertical < 8 and needs("local_walk", pageKinds) then
                                kind = "local_walk"
                            end
                            if kind then
                                add(kind, a, b)
                                pageKinds[kind] = true
                            end
                        end
                    end
                end
            end
        end
        if #samples >= 10 then break end
    end
    return samples, #keys
end

local function localGridWitness(st, world, ui, box)
    local keys = keysInBounds(st, box, "grid")
    for _, key in ipairs(keys) do
        local tile = grid.grid(st, key)
        for cell = 0, st.c * st.c - 1 do
            if cell % st.c < st.c - 1 then
                local bits = tile.bits[cell]
                if tile.z[cell] and tile.z[cell + 1] and bits and math.floor(bits / 2) % 2 == 0 then
                    local a = point(st, world, ui, key, tile, cell, cell)
                    local b = point(st, world, ui, key, tile, cell + 1, cell + 1)
                    if bits < 32 and (tile.bits[cell + 1] or 0) < 32
                        and math.abs(a.z - b.z) <= 1 and inside(box, a) and inside(box, b) then
                        return { "grid_neighbor", a, b }, #keys
                    end
                end
                for _, node in ipairs(tile.layers[cell] or {}) do
                    for _, layer in ipairs(tile.links[node * 8 + 2] or {}) do
                        local target = grid.layer(tile, cell + 1, layer)
                        if target then
                            local a = point(st, world, ui, key, tile, cell, node)
                            local b = point(st, world, ui, key, tile, cell + 1, target)
                            if inside(box, a) and inside(box, b) then
                                return { "grid_neighbor", a, b }, #keys
                            end
                        end
                    end
                end
            end
        end
    end
    return nil, #keys
end

local function nativeWindowChecks(st, world, ui, box, height, milliseconds)
    local x, y = (box[1] + box[3]) / 2, (box[2] + box[4]) / 2
    local window = grid.surfacePage(st, x, y, true)
    local checks = {}
    if not window then return checks end
    local function onFloor(node)
        return node and node.z >= height[1] and node.z <= height[2] and inside(box, node)
    end
    local function endpoint(node)
        return { instanceID = world, uiMapID = ui, x = node.x, y = node.y, z = node.z, indoors = true }
    end
    local dx, dy = { 1, -1, 0, 0, 1, 1, -1, -1 }, { 0, 0, 1, -1, 1, -1, 1, -1 }
    local function landing(start)
        local queue, seen = { start }, { [start.id] = true }
        for index = 1, 128 do
            local node = queue[index]
            if not node then return end
            if (start.x - node.x)^2 + (start.y - node.y)^2 >= 64 then return node end
            for edge = node.first, node.first + 2 * node.count - 1, 2 do
                local direction, layer = node.bytes:byte(edge, edge + 1)
                local col = grid.columnKey(node.x + dx[direction + 1] * window.step,
                    node.y + dy[direction + 1] * window.step)
                local other = window.columns[col] and window.columns[col][layer + 1]
                if onFloor(other) and not seen[other.id] then
                    seen[other.id] = true
                    queue[#queue + 1] = other
                end
            end
        end
    end
    local starts = {}
    for _, column in pairs(window.columns) do
        for _, node in ipairs(column) do
            if onFloor(node) and node.count > 0 then starts[#starts + 1] = node end
        end
    end
    local function rank(node) return (node.x - x)^2 + (node.y - y)^2 end
    table.sort(starts, function(a, b)
        if rank(a) ~= rank(b) then return rank(a) < rank(b) end
        return a.id < b.id
    end)
    for _, start in ipairs(starts) do
        local goal = landing(start)
        if goal then
            local check = walk("native_delve_floor", endpoint(start), endpoint(goal), milliseconds)
            if check.outcome == "pass" and not check.geometryVerified then
                check.status, check.outcome = "missing_native_proof", "fail"
            end
            checks[1] = check
            return checks
        end
    end
    return checks
end

local function replay(world, ui, box, milliseconds, height)
    provider = instance:GetWalkingProvider()
    local st = provider and provider:HasMap(world) and grid.State(world)
    if not st then return { status = "pack_not_loaded" } end
    if height then
        local checks = nativeWindowChecks(st, world, ui, box, height, milliseconds)
        return { status = #checks > 0 and "checked" or "no_witness", checks = checks }
    end
    local samples, pages = sample(st, world, ui, box)
    local gridPages
    if #samples == 0 then
        local witness
        witness, gridPages = localGridWitness(st, world, ui, box)
        samples[1] = witness
    end
    local checks = {}
    for _, probe in ipairs(samples) do
        local kind, a, b = unpack(probe)
        if kind == "stacked_shortcut" then
            checks[#checks + 1] = rejectShortcut(a, b, milliseconds)
            checks[#checks + 1] = rejectShortcut(b, a, milliseconds)
            if a.indoors == b.indoors then
                checks[#checks + 1] = ambiguousOrigin(a, b, milliseconds)
            end
        else
            checks[#checks + 1] = walk(kind, a, b, milliseconds)
            if kind == "indoor_outdoor" then checks[#checks + 1] = walk(kind, b, a, milliseconds) end
        end
    end
    return { status = #samples > 0 and "checked" or "no_witness",
        graphPages = pages, fallbackGridPages = gridPages, checks = checks }
end

local function plan(owner, from, to, edges, milliseconds, terrain, strict)
    local options = { start = from, goal = to, edges = edges, walkSpeed = 7, clock = clock,
        walkingProvider = terrain and owner:GetWalkingProvider() or nil, walkingIsTransitive = not terrain,
        requireVerifiedWalks = strict,
        canWalk = function(a, b) return owner:CanWalk(a, b) end }
    return finish(owner:CreateSearch(options), clock() + milliseconds)
end

local function newOwner(maps, projections, progress, character, art)
    return lib:New({ profile = "retail", environment = {
        clock = clock,
        getCharacter = character,
        isQuestCompleted = progress,
        isQuestCompletedOnAccount = progress,
        isQuestActive = progress,
        isAchievementCompleted = progress,
        getMapInfo = function(ui) return maps[ui] end,
        getMapArtID = function(ui) return art and art[tostring(ui)] end,
        mapToWorld = function(ui, east, south)
            local p = projections[ui]
            if p then
                return p[1], p[4] - south * (p[4] - p[2]), p[5] - east * (p[5] - p[3])
            end
        end,
    } })
end

local function transitions(maps, projections, regionMaps, milliseconds, hub)
    local unlocked = true
    local function progress() return unlocked end
    local owner = newOwner(maps, projections, progress, function()
        return { level = 90, faction = "Alliance" }
    end)
    local checks, allEdges = {}, {}
    for _, connection in ipairs(owner:GetConnections()) do
        local a, b = connection.from and connection.from.uiMapID, connection.to and connection.to.uiMapID
        if a and b and a ~= b and regionMaps[a] and regionMaps[b] then
            local edges = owner:BuildEdges({ connectionID = connection.id, walkSpeed = 7, deferInstructions = true })
            local expected = connection.bidirectional and 2 or 1
            local row = { id = connection.id, kind = connection.kind, fromMap = a, toMap = b, directions = {},
                status = #edges == expected and "checked" or "missing_directions" }
            for _, edge in ipairs(edges) do
                allEdges[#allEdges + 1] = edge
                local status, result, error = plan(owner, edge.from, edge.to, edges, milliseconds, true)
                local used = false
                for _, segment in ipairs(result and result.segments or {}) do
                    if segment.id == edge.id then used = true end
                end
                row.directions[#row.directions + 1] = {
                    fromMap = edge.from.uiMapID, toMap = edge.to.uiMapID,
                    fromWorld = edge.from.instanceID, toWorld = edge.to.instanceID,
                    status = status, error = error, used = used,
                }
            end
            if connection.requirements then
                unlocked = false
                local locked = owner:BuildEdges({ connectionID = connection.id, walkSpeed = 7, deferInstructions = true })
                row.directionsWithoutProgress = #locked
                unlocked = true
            end
            checks[#checks + 1] = row
        end
    end
    local trips = {}
    local function trip(a, b)
        local from = owner:NormalizeLocation({ space = "map", uiMapID = a, x = .5, y = .5 })
        local to = owner:NormalizeLocation({ space = "map", uiMapID = b, x = .5, y = .5 })
        local row = { fromMap = a, toMap = b, status = "missing_projection" }
        if from and to then
            local status, result, error = plan(owner, from, to, allEdges, milliseconds, false)
            row.status, row.error, row.segments = status, error, {}
            for _, segment in ipairs(result and result.segments or {}) do
                row.segments[#row.segments + 1] = segment.id or segment.kind
            end
        end
        trips[#trips + 1] = row
    end
    if hub then
        local zones = {}
        for ui, mapType in pairs(regionMaps) do
            if mapType == 3 and ui ~= hub then zones[#zones + 1] = ui end
        end
        table.sort(zones)
        for _, ui in ipairs(zones) do
            trip(hub, ui)
            trip(ui, hub)
        end
    end
    return checks, trips
end

local function journey(maps, projections, case, milliseconds)
    local currentMap
    local owner = newOwner(maps, projections, function() return true end, function()
        return { level = case.level or 90, faction = case.faction or "Alliance", mapID = currentMap }
    end, case.mapArt)
    local function direction(start, goal)
        currentMap = start.uiMapID
        local from, to = owner:NormalizeLocation(start), owner:NormalizeLocation(goal)
        if not from or not to or not from.region or not to.region then return { status = "missing_access_region" } end
        local edges = {}
        for _, id in ipairs(case.connections or {}) do
            for _, edge in ipairs(owner:BuildEdges({ connectionID = id, walkSpeed = 7, deferInstructions = true })) do
                edges[#edges+1] = edge
            end
        end
        local status, result, err = plan(owner, from, to, edges, milliseconds, true, true)
        local row = { status = status, error = err, from = from, to = to, segments = {}, walked = 0 }
        for _, segment in ipairs(result and result.segments or {}) do
            row.segments[#row.segments+1] = segment.id or segment.kind
            if segment.kind == "walk" then
                if not segment.path or #segment.path < 2 then row.status = "missing_walking_path" end
                row.walked = row.walked + 1
            end
        end
        if status == "ready" and row.walked == 0 then row.status = "missing_walking_path" end
        return row
    end
    return { name = case.name, outbound = direction(case.from, case.to),
        ["return"] = direction(case.returnFrom or case.to, case.returnTo or case.from) }
end

return replay, transitions, journey
