-- SPDX-License-Identifier: GPL-3.0-or-later
local runtime = LibStub("LibAPRNavigation-1.0")._TerrainNamespace
local G, work = runtime.PathGrid, runtime.Work
local floor, abs, sqrt = math.floor, math.abs, math.sqrt
local min, max = math.min, math.max
local diagonalExtra = sqrt(2) - 1
local fineChordLimit = 20
local dx, dy = { 1, -1, 0, 0, 1, 1, -1, -1 }, { 0, 0, 1, -1, 1, -1, 1, -1 }
local opposite = { 2, 1, 4, 3, 8, 7, 6, 5 }
local fineColumnOffsets = {}
local originColumn = G.columnKey(0, 0)
for direction = 1, 8 do
    fineColumnOffsets[direction] = G.columnKey(dx[direction], dy[direction]) - originColumn
end
local function bit(n, mask)
    return n and floor(n / mask) % 2 == 1
end
local directionBits = {}
for d = 1, 8 do
    local flags = {}
    for value = 0, 255 do flags[value] = bit(value, 2 ^ (d - 1)) end
    directionBits[d] = flags
end

local function side(a, u, b, v, d)
    if not a.z[u] or not b.z[v] then return false end
    if d == 1 then return not directionBits[1][a.bits[u]] end
    if d == 2 then return not directionBits[1][b.bits[v]] end
    if d == 3 then return not directionBits[2][a.bits[u]] end
    return not directionBits[2][b.bits[v]]
end

local function linked(a, u, b, v, d)
    local cell = b.cell[v] or v
    if directionBits[d][a.steps[u]] and (not b.layers[cell] or G.closest(b, cell, a.z[u]) == v) then return true end
    local links = a.links[u * 8 + d - 1]
    if links then
        for _, layer in ipairs(links) do
            if G.layer(b, cell, layer) == v then return true end
        end
    end
    return false
end

local function edgeOpen(a, u, b, v, d)
    if a.cell[u] or b.cell[v] then
        return linked(a, u, b, v, d) or (a == b and not a.cell[u] and linked(b, v, a, u, opposite[d]))
    end
    if d <= 4 then return side(a, u, b, v, d) end
    -- Orthogonal edges allow a turn around an obstacle. Only the diagonal
    -- edge certifies that the straight line through that corner is open.
    return directionBits[dx[d] == dy[d] and 3 or 4][dx[d] == 1 and a.bits[u] or b.bits[v]]
end

local function canTurn(tile, u, v, middle, first, second)
    if tile.z[middle] and edgeOpen(tile, u, tile, middle, first)
        and edgeOpen(tile, middle, tile, v, second) then return true end
    local layers = tile.layers[middle]
    for i = 1, layers and #layers or 0 do
        local node = layers[i]
        if edgeOpen(tile, u, tile, node, first) and edgeOpen(tile, node, tile, v, second) then return true end
    end
    return false
end

local function canStep(tile, u, v, d, columns)
    if not edgeOpen(tile, u, tile, v, d) then return false end
    if d <= 4 or not (tile.cell[u] or tile.cell[v]) or tile.z[u] ~= tile.z[v] then return true end
    local cell = tile.cell[u] or u
    local east, north = dx[d], dy[d]
    local xd, yd = east == 1 and 1 or 2, north == 1 and 3 or 4
    -- At a layered corner, one certified bend and a blocked opposite side
    -- can mark a thin obstruction. Keep the bend on that surface.
    return canTurn(tile, u, v, cell + east * columns, xd, yd) == canTurn(tile, u, v, cell + north, yd, xd)
end

-- Priority queue entries are immutable. A lower-cost revisit makes the old
-- entry stale; the caller discards it when it reaches the head.
local function push(q, id, score, rank)
    local item = q.free
    if item then q.free, item.next = item.next, nil else item = {} end
    item.id, item.score, item.rank = id, score, rank or score
    local p = #q + 1
    while p > 1 do
        local parent = floor(p / 2)
        if q[parent].rank <= item.rank then break end
        q[p], p = q[parent], parent
    end
    q[p] = item
end
local function pop(q)
    local head, tail = q[1], table.remove(q)
    if #q > 0 then
        local p = 1
        while p * 2 <= #q do
            local child = p * 2
            if q[child + 1] and q[child + 1].rank < q[child].rank then child = child + 1 end
            if tail.rank <= q[child].rank then break end
            q[p], p = q[child], child
        end
        q[p] = tail
    end
    head.next, q.free = q.free, head
    return head.id, head.score
end

-- With a destination this is A*. Without one, retain the shortest tree
-- from the endpoint to all reachable entrances in its tile.
local function walk(ctx, startTile, source, target, reverse, crossing, entrances, aimX, aimY)
    local remaining = entrances and entrances.count
    local c, unit = ctx.st.c, ctx.st.unit
    local limit = (crossing or entrances) and 4096
    local endTile = crossing and crossing.tile or startTile
    local endNode = target and (crossing and target - crossing.offset or target)
    local endCell = endNode and (endTile.cell[endNode] or endNode)
    local ex, ey = endCell and floor(endCell / c), endCell and endCell % c
    if aimX then ex, ey = aimX, aimY end
    if crossing then ex, ey = ex + crossing.x, ey + crossing.y end
    -- Exact single and batched queries must settle equal-price alternatives
    -- in the same order. Their smoothed polylines can have different lengths.
    if not ctx.quick and ctx.st.data.portalCostPerYard == nil and not reverse and not crossing
        and ctx.startTile == startTile and ctx.source == source then ex, ey = nil, nil end
    -- The preview only needs reachable entrances facing the objective. Give
    -- that direction extra weight while leaving exact intra-tile costs alone.
    local heuristicRate = (aimX or ctx.quick) and 2 * ctx.minimum or ctx.minimum
    local q, prev, cost = {}, {}, { [source] = 0 }
    local tree = not reverse and not crossing and not entrances and ctx.startTile == startTile
        and ctx.source == source and ctx.originTree
    if tree then
        -- One Dijkstra frontier serves all exact queries from this departure.
        -- A new destination resumes it only until that surface is settled.
        ex, ey = nil, nil
        if tree.source == source and tree.tile and tree.tile.key == startTile.key then
            q, prev, cost = tree.queue, tree.prev, tree.cost
            if tree.complete or tree.settled[target] then return cost, prev end
        else
            tree.source, tree.tile, tree.settled, tree.complete = source, startTile, {}, false
            tree.graph = nil
            tree.queue, tree.prev, tree.cost = q, prev, cost
            push(q, source, 0)
        end
    end
    local function relax(u, v, nextCost, x, y)
        if cost[v] and nextCost >= cost[v] then return end
        prev[v], cost[v] = u, nextCost
        local estimate = 0
        if ex then
            local xLeft, yLeft = abs(x - ex), abs(y - ey)
            estimate = (max(xLeft, yLeft) + diagonalExtra * min(xLeft, yLeft)) * heuristicRate
        end
        push(q, v, nextCost, nextCost + estimate)
    end
    if not tree then push(q, source, 0) end
    while #q > 0 do
        work()
        local u, score = pop(q)
        if score == cost[u] then
            if not tree and u == target then break end
            if entrances and entrances[u] then
                entrances[u] = nil
                remaining = remaining - 1
                if remaining == 0 then break end
            end
            if limit then
                if limit == 0 then
                    if entrances then return cost, prev end
                    return {}, {}
                end
                limit = limit - 1
            end
            local east = crossing and u >= crossing.offset
            local offset = east and crossing.offset or 0
            local shiftX, shiftY = east and crossing.x or 0, east and crossing.y or 0
            local tile, node = east and endTile or startTile, u - offset
            local cell = tile.cell[node] or node
            local x, y = floor(cell / c), cell % c
            local reverseRate
            if reverse then
                local rates = tile.bits[node] >= 32 and ctx.water or ctx.land
                reverseRate = rates[tile.class[node] or 0]
            end
            for d = 1, 8 do
                work()
                local xx, yy = x + dx[d], y + dy[d]
                if xx >= 0 and yy >= 0 and xx < c and yy < c then
                    local dest = xx * c + yy
                    local layers = tile.layers[dest]
                    local length = d <= 4 and unit or ctx.diagonal
                    for i = 0, layers and #layers or 0 do
                        if i > 0 then work() end
                        local v = i == 0 and dest or layers[i]
                        local id = v + offset
                        local previous = cost[id]
                        if tile.z[v] and (not previous or previous > score) then
                            local rate = reverseRate
                            if not rate then
                                local rates = tile.bits[v] >= 32 and ctx.water or ctx.land
                                rate = rates[tile.class[v] or 0]
                            end
                            local nextCost = score + length * rate
                            -- Only a cheaper label needs a layered movement check.
                            -- Equal-cost labels retain the same predecessor.
                            if (not previous or nextCost < previous)
                                and (reverse and canStep(tile, v, node, opposite[d], c)
                                    or not reverse and canStep(tile, node, v, d, c)) then
                                relax(u, id, nextCost, xx + shiftX, yy + shiftY)
                            end
                        end
                    end
                end
            end
            local links = crossing and crossing.links[u]
            if links then
                local otherTile = east and startTile or endTile
                local otherX, otherY = east and 0 or crossing.x, east and 0 or crossing.y
                for _, v in ipairs(links) do
                    work()
                    local surface = v % crossing.offset
                    local cell = otherTile.cell[surface] or surface
                    local rates = otherTile.bits[surface] >= 32 and ctx.water or ctx.land
                    local nextCost = score + unit * rates[otherTile.class[surface] or 0]
                    relax(u, v, nextCost, floor(cell / c) + otherX, cell % c + otherY)
                end
            end
            if tree then
                tree.settled[u] = true
                if u == target then break end
            end
        end
    end
    if tree then tree.complete = #q == 0 end
    return cost, prev
end

local function unravel(prev, dest)
    local reversed = {}
    while dest do
        work()
        reversed[#reversed + 1], dest = dest, prev[dest]
    end
    return reversed
end

local function appendWalk(ctx, k, tile, prev, dest, crossing)
    local nodes = unravel(prev, dest)
    for i = #nodes, 1, -1 do
        work()
        local node = nodes[i]
        local other = crossing and node >= crossing.offset
        local key, page = other and crossing.key or k, other and crossing.tile or tile
        if other then node = node - crossing.offset end
        local cell = page.cell[node] or node
        local x, y = G.position(ctx.st, key, cell)
        local points, z = ctx.points, G.centerHeight(page, node)
        local b, a = points[#points], points[#points - 1]
        if not b or b.x ~= x or b.y ~= y or b.z ~= z then
            -- Compress equal consecutive grid steps, preserving slopes and turns.
            local gx = floor(key / ctx.st.data.ny) * ctx.st.c + floor(cell / ctx.st.c)
            local gy = key % ctx.st.data.ny * ctx.st.c + cell % ctx.st.c
            local rates = page.bits[node] >= 32 and ctx.water or ctx.land
            local rate = rates[page.class[node] or 0]
            local cellPoint = {x = x, y = y, z = z, gx = gx, gy = gy, rate = rate}
            ctx.cells[#ctx.cells+1] = cellPoint
            if a then
                local ux, uy, uz = b.gx - a.gx, b.gy - a.gy, b.z - a.z
                local vx, vy, vz = gx - b.gx, gy - b.gy, z - b.z
                if abs(gx - a.gx) + abs(gy - a.gy) <= 256 and ux * vy == uy * vx and ux * vz == uz * vx
                    and uy * vz == uz * vy and ux * vx + uy * vy > 0 then
                    rate = math.min(rate, b.rate)
                    points[#points] = nil
                end
            end
            points[#points + 1] = rate == cellPoint.rate and cellPoint
                or {x = x, y = y, z = z, gx = gx, gy = gy, rate = rate}
        end
    end
end

local function surface(tile, entry)
    return assert(G.layer(tile, entry.cell, entry.layer), "missing terrain entrance surface")
end

function runtime.ApproachOrigin(request)
    local st, from = G.State(request.map), request.from
    local key, cell = G.locate(st, from.x, from.y)
    local tile = G.grid(st, key)
    local source = G.endpoint(st, tile, cell, from.z, from.x, from.y)
    local land, water = runtime.Prices(request, st.data.swim)
    local ctx = {st = st, startTile = tile, source = source, land = land, water = water,
        originTree = request.originTree, minimum = st.unit * min(land[1], water[1]), diagonal = st.unit * sqrt(2)}
    local costs = walk(ctx, tile, source)
    local page = assert(G.graphPage(st, key))
    for _, entry in ipairs(page.nodes) do
        work()
        if costs[surface(tile, entry)] then return key, costs, true end
    end
    return key, costs, false
end

-- Search neighbouring tiles together for a short guide leg. Their directed
-- portal links are the only crossings, even when both tiles look walkable.
local function nearby(ctx, k, tile, start, j, goalTile, goal)
    local st = ctx.st
    local x = floor(j / st.data.ny) - floor(k / st.data.ny)
    local y = j % st.data.ny - k % st.data.ny
    if abs(x) + abs(y) ~= 1 then return end
    local a, b = G.graphPage(st, k), G.graphPage(st, j)
    if not a or not b then return end
    local offset = st.c * st.c * 64
    local crossing = {tile = goalTile, key = j, x = x * st.c, y = y * st.c, offset = offset, links = {}}
    for _, reverse in ipairs({false, true}) do
        local graph, otherGraph = reverse and b or a, reverse and a or b
        local key, otherKey = reverse and j or k, reverse and k or j
        local page, otherPage = reverse and goalTile or tile, reverse and tile or goalTile
        for _, entry in ipairs(graph.nodes) do
            work()
            for n = 0, entry.degree - 1 do
                work()
                local destination, index = G.edge(st, key, graph.bytes, entry.first + n * 14)
                if destination == otherKey then
                    local other = assert(otherGraph.nodes[index], "invalid terrain entrance")
                    local gx = floor(other.cell / st.c) - floor(entry.cell / st.c) + (reverse and -x or x) * st.c
                    local gy = other.cell % st.c - entry.cell % st.c + (reverse and -y or y) * st.c
                    if abs(gx) + abs(gy) == 1 then
                        local from = surface(page, entry) + (reverse and offset or 0)
                        local to = surface(otherPage, other) + (reverse and 0 or offset)
                        local links = crossing.links[from] or {}
                        links[#links + 1], crossing.links[from] = to, links
                    end
                end
            end
        end
    end
    if not next(crossing.links) then return end
    local target = goal + offset
    local costs, prev = walk(ctx, tile, start, target, false, crossing)
    if costs[target] then appendWalk(ctx, k, tile, prev, target, crossing) end
end

local function isolatedApproach(st, startKey, endKey, finishCosts)
    if startKey == endKey then return false end
    local queue, seen, pages = {}, {}, {}
    for i in pairs(finishCosts) do
        local id = endKey * 4096 + i
        queue[#queue + 1], seen[id] = id, true
    end
    local count, cursor = 0, 1
    while cursor <= #queue and #queue <= 256 do
        work()
        local id = queue[cursor]
        cursor = cursor + 1
        local key = floor(id / 4096)
        if key == startKey then return false end
        if not pages[key] then
            if count == 6 then return false end
            pages[key] = G.incoming(st, key)
            count = count + 1
        end
        local links = pages[key][id % 4096]
        for n = 1, links and #links or 0 do
            local from = links[n]
            if not seen[from] then queue[#queue + 1], seen[from] = from, true end
        end
    end
    if cursor > #queue then return pages end
end

local function goalTree(ctx, tile, node, key)
    local st = ctx.st
    local cache = st.goalTrees or {}
    st.goalTrees = cache
    local tag = table.concat({key, node, tostring(ctx.profile), tostring(ctx.style), ctx.water[0]}, ":")
    for i, entry in ipairs(cache) do
        if entry.tag == tag then
            table.remove(cache, i)
            cache[#cache + 1] = entry
            return entry.costs, entry.parents
        end
    end
    local costs, parents = walk(ctx, tile, node, nil, true)
    -- Publish only a finished reverse search. No job can observe a partial tree.
    if #cache >= 4 then table.remove(cache, 1) end
    cache[#cache + 1] = {tag = tag, costs = costs, parents = parents}
    return costs, parents
end

local publishEnds
local function across(ctx, startKey, startTile, start, endKey, endTile, goal, sketch)
    local st = ctx.st
    local first = assert(G.graphPage(st, startKey))
    local lastPage = assert(G.graphPage(st, endKey))
    if #first.nodes == 0 or #lastPage.nodes == 0 then return end
    -- Try a small connected set of nearby entrances for foreground guidance.
    -- If those cannot form a chain the caller runs the complete search.
    local function entrances(tile, node, page, reverse, key, towards)
        if not sketch then return walk(ctx, tile, node, nil, reverse) end
        local wanted = { count = min(3, #page.nodes) }
        for _, entry in ipairs(page.nodes) do
            work()
            wanted[surface(tile, entry)] = true
        end
        local x, y = G.position(st, key, 0)
        local aimX, aimY = (towards.x - x) / st.unit, (towards.y - y) / st.unit
        return walk(ctx, tile, node, nil, reverse, nil, wanted, aimX, aimY)
    end
    local finalCosts, finalPrev
    if sketch then
        finalCosts, finalPrev = entrances(endTile, goal, lastPage, true, endKey, ctx.from)
    else
        finalCosts, finalPrev = goalTree(ctx, endTile, goal, endKey)
        ctx.goalPredecessors = finalCosts
    end
    local finishCosts = {}
    for i, entry in ipairs(lastPage.nodes) do
        work()
        finishCosts[i] = finalCosts[surface(endTile, entry)]
    end
    -- A room with no incoming portal cannot be reached via a different tile.
    local portalReachable = st.data.partitionSchema and runtime.PartitionPortalReachable
    local confined
    if not next(finishCosts) then confined = {}
    elseif not sketch and not portalReachable then confined = isolatedApproach(st, startKey, endKey, finishCosts) end
    if confined then
        if not sketch then
            local allowed = {[endKey] = true}
            for key in pairs(confined) do allowed[key] = true end
            ctx.approachPages = allowed
        end
        -- Every predecessor of this destination is trapped in the same
        -- incoming subgraph. A manual marker can reject those alternatives
        -- together when finding a reachable stopping point.
        if not sketch and ctx.rejected and not (startKey == endKey and finalCosts[start]) then
            local nodes = ctx.rejected[endKey] or {}
            for node in pairs(finalCosts) do work(); nodes[node] = true end
            ctx.rejected[endKey] = nodes
        end
        return
    end
    local initialCost, initialPrev = entrances(startTile, start, first, false, startKey, ctx.to)
    if portalReachable then
        local possible = false
        for i, entry in ipairs(first.nodes) do
            if initialCost[surface(startTile, entry)] then
                for j in pairs(finishCosts) do
                    work()
                    -- Only an explicit negative can discard a portal pair.
                    -- Pricing and reconstruction always use the directed graph.
                    if portalReachable(st.data, startKey + 1, i, endKey + 1, j) ~= false then
                        possible = true
                        break
                    end
                end
            end
            if possible then break end
        end
        if not possible then return end
    end
    local tree = not sketch and ctx.originTree
    local saved = tree and tree.graph
    -- Published packs certify a geometric lower bound on every encoded edge,
    -- including rounded costs and directed crossings. Old/custom packs and
    -- trees shared by several targets can still use the same Dijkstra frontier.
    local metric = st.data.portalCostPerYard
    local goalX, goalY = G.position(st, endKey, endTile.cell[goal] or goal)
    local cheapest = ctx.minimum / st.unit
    local rate = not tree and type(metric) == "number" and metric > 0 and math.min(metric, cheapest) or 0
    if sketch then rate = math.max(rate, cheapest) end
    local ranks = rate > 0 and {} or nil
    local distance, parent, queue = {}, {}, {}
    if saved then distance, parent, queue = saved.distance, saved.parent, saved.queue end
    local function relax(k, i, value, from)
        local id = k * 4096 + i
        if not distance[id] or value < distance[id] then
            distance[id], parent[id] = value, from
            local rank = value
            if ranks then
                local estimate = ranks[id]
                if not estimate then
                    local entry = assert(G.graphPage(st, k).nodes[i], "invalid terrain entrance")
                    local x, y = G.position(st, k, entry.cell)
                    local dx, dy = x - goalX, y - goalY
                    estimate = sqrt(dx * dx + dy * dy) * rate
                    ranks[id] = estimate
                end
                rank = rank + estimate
            end
            push(queue, id, value, rank)
        end
    end
    if not saved then
        for i, entry in ipairs(first.nodes) do
            work()
            local v = surface(startTile, entry)
            if initialCost[v] then relax(startKey, i, initialCost[v]) end
        end
        if tree then
            saved = {distance = distance, parent = parent, queue = queue, settled = {}}
            tree.graph = saved
        end
    end
    local best, last
    local function consider(id, score)
        if not best or score < best or (score == best and id < last) then best, last = score, id end
    end
    if saved then
        for i, finish in pairs(finishCosts) do
            work()
            local id = endKey * 4096 + i
            if saved.settled[id] then consider(id, distance[id] + finish) end
        end
    end
    while #queue > 0 do
        work()
        if best and queue[1].rank > best then break end
        local id, score = pop(queue)
        if distance[id] == score then
            local k, i = floor(id / 4096), id % 4096
            local graph = assert(G.graphPage(st, k), "missing target terrain graph")
            local entry = assert(graph.nodes[i], "invalid terrain entrance")
            local finish = k == endKey and finishCosts[i]
            if finish then consider(id, score + finish) end
            if saved then saved.settled[id] = true end
            for n = 0, entry.degree - 1 do
                work()
                local key, index, price = G.edge(st, k, graph.bytes, entry.first + n * 14, ctx.profile)
                relax(key, index, score + price, id)
            end
        end
    end
    if not last then return end
    local chain = unravel(parent, last)
    if ctx.preview and startKey ~= endKey then
        publishEnds(ctx, chain, startKey, startTile, initialPrev, endKey, endTile, finalPrev, goal)
    end
    local previousKey, previousNode
    for n = #chain, 1, -1 do
        work()
        local id = chain[n]
        local k, i = floor(id / 4096), id % 4096
        local tile = assert(G.grid(st, k))
        local node = surface(tile, G.graphPage(st, k).nodes[i])
        local prev = {}
        if not previousNode then
            prev = initialPrev
        elseif previousKey == k then
            local costs
            costs, prev = walk(ctx, tile, previousNode, node)
            assert(costs[node], "invalid intra-tile connection")
        end
        appendWalk(ctx, k, tile, prev, node)
        previousKey, previousNode = k, node
    end
    local prev = {}
    while previousNode ~= goal do
        work()
        local node = assert(finalPrev[previousNode], "missing route to destination")
        prev[node] = previousNode
        previousNode = node
    end
    appendWalk(ctx, endKey, endTile, prev, goal)
    return true
end

local function staysNear(raw, first, last, a, b, width)
    local dx, dy = b.x - a.x, b.y - a.y
    local length = dx * dx + dy * dy
    if length == 0 then return false end
    local limit = width * width * length
    for i = first, last - 1 do
        work()
        local ox, oy = raw[i].x - a.x, raw[i].y - a.y
        local along = ox * dx + oy * dy
        if along < 0 or along > length or (ox * dy - oy * dx)^2 > limit then return false end
    end
    return true
end

-- Refine a short uncertified part of the coarse route on neighbouring
-- surfaces. Every expansion and the final join use the guidance predicate.
local function localDetour(ctx, map, from, to)
    local st = ctx.st
    if max(abs(to.x-from.x), abs(to.y-from.y)) > 12*st.unit then return end
    local queue, seen = {from}, {}
    for index = 1, 64 do
        local point = queue[index]
        if not point then return end
        work()
        if index > 1 and runtime.Sight(map, point.x, point.y, point.z, to.x, to.y, to.z, ctx) then
            local reverse = {}
            while point.parent do
                reverse[#reverse+1] = {x = point.x, y = point.y, z = point.z}
                point = point.parent
            end
            return reverse
        end
        local key, cell = G.locate(st, point.x, point.y)
        local x, y = G.position(st, key, cell)
        for d = 1, 8 do
            work()
            local tx, ty = x + dx[d]*st.unit, y + dy[d]*st.unit
            local k, c = G.locate(st, tx, ty)
            local tile = k and G.grid(st, k)
            if tile then
                seen[k] = seen[k] or {}
                local layers = tile.layers[c]
                for i = 0, layers and #layers or 0 do
                    work()
                    local node = i == 0 and c or layers[i]
                    if tile.z[node] and not seen[k][node] then
                        local z = G.surfaceHeight(st, tile, node, tx, ty)
                        if runtime.Sight(map, point.x, point.y, point.z, tx, ty, z, ctx) then
                            seen[k][node] = true
                            queue[#queue+1] = {x = tx, y = ty, z = z, parent = point}
                        end
                    end
                end
            end
        end
    end
end

local function verifyPath(request, ctx, raw, preview, progress)
    local from, to = request.from, request.to
    local st, result = ctx.st, {from}
    local first, last = raw[1], raw[#raw]
    local i = 1
    -- Keep the cell centre as an anchor until a ray from the observed world
    -- position proves that bypassing it is safe on this side of the corner.
    if first.x ~= from.x or first.y ~= from.y then i = 0 end
    if last.x ~= to.x or last.y ~= to.y then
        raw[#raw + 1] = { x = to.x, y = to.y, z = to.z, rate = last.rate }
    end
    -- A short lookahead bounds repeated casts in a winding corridor. The
    -- underlying cells and the chosen shortcut still use the same proof.
    local lookahead = preview and 8 or (st.data.portalCostPerYard and 12 or 32)
    local ceilings, corridorCeilings = {}, {}
    while i < #raw do
        work()
        local anchor = result[#result]
        local nextIndex = i + 1
        local lastIndex = math.min(#raw, i + lookahead)
        local ceiling = raw[nextIndex].rate
        local corridorCeiling = ceiling
        for candidate = nextIndex + 1, lastIndex do
            work()
            ceiling = math.min(ceiling, raw[candidate].rate)
            corridorCeiling = math.max(corridorCeiling, raw[candidate].rate)
            ceilings[candidate] = ceiling
            corridorCeilings[candidate] = corridorCeiling
        end
        -- A short chord can hit a blocked corner even when a longer chord
        -- has a clear angle. Try furthest first and verify the full segment.
        local verified
        for candidate = lastIndex, nextIndex, -1 do
            work()
            local point = candidate == #raw and to or raw[candidate]
            local rate = candidate == i + 1 and math.huge or ceilings[candidate]
            -- Price changes alone may subdivide a straight corridor. Use the
            -- wider price bound only when the shortcut stays close to it.
            if candidate > i + 1 and rate < corridorCeilings[candidate]
                and staysNear(raw, nextIndex, candidate, anchor, point, st.unit / 3) then
                rate = corridorCeilings[candidate]
            end
            if runtime.Sight(request.map, anchor.x, anchor.y, anchor.z, point.x, point.y, point.z, ctx, rate) then
                nextIndex = candidate
                verified = true
                break
            end
        end
        if not verified then
            for candidate = min(nextIndex + 2, lastIndex), nextIndex, -1 do
                local point = candidate == #raw and to or raw[candidate]
                local bend = localDetour(ctx, request.map, anchor, point)
                if bend then
                    for n = #bend, 1, -1 do result[#result + 1] = bend[n] end
                    nextIndex, verified = candidate, true
                    break
                end
            end
        end
        if not verified then
            return nil, "unverified", i == 0 and "start" or (nextIndex == #raw and "goal" or "interior")
        end
        i = nextIndex
        if i < #raw then
            local p = raw[i]
            result[#result + 1] = { x = p.x, y = p.y, z = p.z }
            if progress then progress(result) end
        end
    end
    result[#result + 1] = to
    return result
end

local function previewRow(ctx, points, mapID, split)
    if not points or #points < 2 then return end
    local path = {}
    local endpoint = split and ctx.preview.to or ctx.preview.from
    for i, point in ipairs(points) do
        work()
        path[i] = {instanceID=endpoint.instanceID, x=point.x, y=point.y, z=point.z, uiMapID=mapID,
            region=endpoint.region, accessKey=endpoint.accessKey, floor=endpoint.floor, indoors=endpoint.indoors}
    end
    return {kind="walk", path=path, pathCursor=1, breakBefore=split}
end

publishEnds=function(ctx, chain, startKey, startTile, initialPrev, endKey, endTile, finalPrev, goal)
    local st = ctx.st
    local first = assert(G.graphPage(st,startKey).nodes[chain[#chain]%4096])
    local last = assert(G.graphPage(st,endKey).nodes[chain[1]%4096])
    local departure, arrival = surface(startTile,first), surface(endTile,last)
    local function section(key, tile, prev, finish, from, to)
        local fragment = {st=st,land=ctx.land,water=ctx.water,points={},cells={}}
        appendWalk(fragment,key,tile,prev,finish)
        if #fragment.cells==0 or (from.x==to.x and from.y==to.y and from.z==to.z) then return end
        local request = {map=ctx.preview.from.instanceID,from=from,to=to}
        return verifyPath(request,ctx,fragment.points,true)
            or (#fragment.points~=#fragment.cells and verifyPath(request,ctx,fragment.cells,true))
    end
    local x,y = G.position(st,startKey,first.cell)
    local start = previewRow(ctx,section(startKey,startTile,initialPrev,departure,ctx.from,
        {x=x,y=y,z=G.centerHeight(startTile,departure)}),ctx.preview.from.uiMapID)
    if start then ctx.preview.walkingPreview={start} end
    local previous, node = {}, arrival
    while node~=goal do
        work()
        local nextNode = assert(finalPrev[node], "missing route to destination")
        previous[nextNode], node = node, nextNode
    end
    x,y = G.position(st,endKey,last.cell)
    local finish = previewRow(ctx,section(endKey,endTile,previous,goal,
        {x=x,y=y,z=G.centerHeight(endTile,arrival)},ctx.to),ctx.preview.to.uiMapID,true)
    if finish then
        local fragments = start and {start,finish} or {finish}
        if start and #chain > 2 then
            local skeleton, stride = {}, math.max(1, math.ceil((#chain - 1) / 64))
            local function add(index)
                local id = chain[index]
                local key = floor(id / 4096)
                local node = G.graphPage(st,key).nodes[id % 4096]
                local x,y = G.position(st,key,node.cell)
                skeleton[#skeleton+1] = {x=x,y=y}
            end
            for index = #chain, 2, -stride do work(); add(index) end
            add(1)
            fragments.estimate = previewRow(ctx,skeleton,nil,true)
            fragments.estimate.estimated = true
        end
        ctx.preview.walkingPreview = fragments
        ctx.previewFinish = finish
    end
end

local function findPath(request)
    local st = G.State(request.map)
    local from, to = request.from, request.to
    local k, a = G.locate(st, from.x, from.y)
    local j, b = G.locate(st, to.x, to.y)
    local t, u = G.grid(st, k), G.grid(st, j)
    local start = G.endpoint(st, t, a, from.z, from.x, from.y)
    local goal = G.endpoint(st, u, b, to.z, to.x, to.y)
    local land, water = runtime.Prices(request, st.data.swim)
    local ctx = {
        st = st,
        profile = request.profile,
        style = request.style,
        land = land,
        water = water,
        points = {},
        cells = {},
        originTree = not request.quick and request.originTree,
        rejected = request.rejected,
        quick = request.quick,
        preview = request.preview,
        startTile = t, source = start,
        from = from, to = to,
        diagonal = st.unit * sqrt(2),
        minimum = st.unit * math.min(land[1], water[1]),
    }
    -- A straight, uniformly cheapest chord needs no expansion. On the
    -- foreground corridor permit ordinary land, preserving costly hazards.
    local rate = request.quick and math.min(1, land[0]) or ctx.minimum / st.unit
    if runtime.Sight(request.map, from.x, from.y, from.z, to.x, to.y, to.z, ctx, rate) then
        return {from, to}
    end
    local refused
    if request.refusedApproachAnchors and not request.quick then
        -- The same coarse anchors can recur when proving nearby stopping
        -- points. Keep the refusal scoped to this exact departure surface.
        local key = k .. ":" .. start .. ":" .. j
        refused = request.refusedApproachAnchors[key] or {}
        request.refusedApproachAnchors[key] = refused
        if refused[goal] then return nil, "unreachable" end
    end
    if k == j then
        local costs, prev = walk(ctx, t, start, goal)
        if costs[goal] then appendWalk(ctx, k, t, prev, goal) end
    elseif request.quick then
        nearby(ctx, k, t, start, j, u, goal)
    end
    local preview
    if request.quick and k ~= j and #ctx.points == 0 then
        preview = across(ctx, k, t, start, j, u, goal, true)
    end
    if #ctx.points == 0 and not across(ctx, k, t, start, j, u, goal) then
        if refused and ctx.goalPredecessors then
            -- If the directed graph cannot reach this anchor, no reachable
            -- anchor can walk to it in the same tile. Still test direct
            -- chords and alternate endpoint joins for each world position.
            for node in pairs(ctx.goalPredecessors) do
                work()
                refused[node] = true
            end
        end
        return nil, "unreachable", ctx.approachPages
    end
    local compressed = #ctx.points ~= #ctx.cells
    local progress
    if ctx.preview and ctx.preview.walkingPreview then
        local nextUpdate = 48
        progress = function(points)
            if #points < nextUpdate then return end
            nextUpdate = nextUpdate * 2
            local prefix = previewRow(ctx,points,nil,false)
            ctx.preview.walkingPreview = {prefix,ctx.previewFinish}
        end
    end
    local path, reason, location = verifyPath(request, ctx, ctx.points, preview, progress)
    if not path and compressed then
        return verifyPath(request, ctx, ctx.cells, preview)
    end
    return path, reason, location
end

local function accessPoints(st, id, point, departure)
    local key, cell = G.locate(st, point.x, point.y)
    local x, y = G.position(st, key, cell)
    local pages = {}
    local function clear(a, b)
        if not departure then a, b = b, a end
        return runtime.Sight(id, a.x, a.y, a.z, b.x, b.y, b.z, pages)
    end
    local tile = G.grid(st, key)
    local center = {x = x, y = y, z = G.centerHeight(tile, G.endpoint(st, tile, cell, point.z, point.x, point.y))}
    if clear(point, center) then return {{point = point}} end
    local points = {}
    for d = 1, 8 do
        work()
        local px, py = x + dx[d] * st.unit, y + dy[d] * st.unit
        local k, c = G.locate(st, px, py)
        local page = k and G.grid(st, k)
        if page then
            local layers = page.layers[c]
            for i = 0, layers and #layers or 0 do
                local z = G.centerHeight(page, i == 0 and c or layers[i])
                if z then
                    local candidate = {x = px, y = py, z = z}
                    if clear(point, candidate) then
                        points[#points + 1] = {point = candidate}
                    elseif clear(center, candidate) then
                        -- Join the open centre line inside the endpoint cell.
                        -- Both the join and the remaining directed edge must
                        -- pass the same proof used by guidance.
                        for n = 1, 3 do
                            local bend = {x = x + dx[d] * st.unit * n / 8, y = y + dy[d] * st.unit * n / 8}
                            bend.z = G.surfaceHeight(st, tile, G.endpoint(st, tile, cell, point.z, point.x, point.y), bend.x, bend.y)
                            if clear(point, bend) and clear(bend, candidate) then
                                points[#points + 1] = {point = candidate, bend = bend}
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    return points
end

function runtime.Route(request)
    local st = G.State(request.map)
    local function restricted(point)
        local k, c = G.locate(st, point.x, point.y)
        local tile = G.grid(st, k)
        local node = G.endpoint(st, tile, c, point.z, point.x, point.y)
        return (tile.clearance and tile.clearance[node]) or (tile.support and tile.support[node])
    end
    local starts, goals, refusal
    if restricted(request.from) or restricted(request.to) then
        starts = accessPoints(st, request.map, request.from, true)
        goals = accessPoints(st, request.map, request.to, false)
    end
    if not starts or (starts[1] and starts[1].point == request.from and goals[1] and goals[1].point == request.to) then
        local path, reason, location = findPath(request)
        if reason ~= "unverified" then return path, reason, location end
        refusal = location or "unknown"
        starts = accessPoints(st, request.map, request.from, true)
        goals = accessPoints(st, request.map, request.to, false)
    end
    for _, start in ipairs(starts) do
        for _, goal in ipairs(goals) do
            if start.point ~= request.from or goal.point ~= request.to then
                local alternate = {map = request.map, from = start.point, to = goal.point, profile = request.profile,
                    style = request.style, quick = request.quick, waterWalking = request.waterWalking,
                    refusedApproachAnchors = request.refusedApproachAnchors}
                local route = findPath(alternate)
                if route then
                    if start.bend then table.insert(route, 1, start.bend) end
                    if start.point ~= request.from then table.insert(route, 1, request.from) end
                    if goal.bend then route[#route + 1] = goal.bend end
                    if goal.point ~= request.to then route[#route + 1] = request.to end
                    return route
                end
            end
        end
    end
    if not refusal then return findPath(request) end
    return nil, "unverified", refusal
end

local function fineSpan(f,a,b)
    if f.nz <= 1e-10 then return end
    local low,high=0,1
    for i=1,3 do
        local p,q=f[i],f[i%3+1]
        local x,y=q[1]-p[1],q[2]-p[2]
        local u=x*(a.y-p[2])-y*(a.x-p[1])
        local v=x*(b.y-p[2])-y*(b.x-p[1])
        if u < -1e-8 and v < -1e-8 then return end
        if u < -1e-8 then low=max(low,u/(u-v)) end
        if v < -1e-8 then high=min(high,u/(u-v)) end
    end
    if high-low>1e-9 then return low,high end
end

local function fineHeight(f,x,y)
    local p=f[1]
    return p[3]-(f.nx*(x-p[1])+f.ny*(y-p[2]))/f.nz
end

local function fineHeights(page, point)
    local bin=page.bins[G.columnKey(floor(point.x/4),floor(point.y/4))]
    local heights={}
    for i=1,bin and #bin or 0 do
        work()
        local f=bin[i]
        G.prepareFace(page,f)
        if not f.liquid and (not f.steep or not f.model) and fineSpan(f,point,point) then
            heights[#heights+1]=fineHeight(f,point.x,point.y)
        end
    end
    table.sort(heights)
    local unique={}
    for _,z in ipairs(heights) do
        if #unique==0 or z-unique[#unique]>=0.002 then unique[#unique+1]=z end
    end
    return unique
end

local function clipped(poly,axis,bound,sign)
    local out={}
    for i=1,#poly do
        local a,b=poly[i],poly[i%#poly+1]
        local u,v=(a[axis]-bound)*sign,(b[axis]-bound)*sign
        if u>=0 then out[#out+1]=a end
        if (u<0 and v>0) or (v<0 and u>0) then
            local t=u/(u-v)
            out[#out+1]={a[1]+t*(b[1]-a[1]),a[2]+t*(b[2]-a[2]),a[3]+t*(b[3]-a[3])}
        end
    end
    return out
end

local function bodyClear(faces,a,b)
    local x,y=b.x-a.x,b.y-a.y
    local span=sqrt(x*x+y*y)
    if span<1e-9 then return true end
    local ux,uy=x/span,y/span
    local x0,x1=min(a.x,b.x)-.45,max(a.x,b.x)+.45
    local y0,y1=min(a.y,b.y)-.45,max(a.y,b.y)+.45
    local z0,z1=min(a.z,b.z)+.35,max(a.z,b.z)+1.6
    for _,f in ipairs(faces) do
        work()
        if f.high>=z0 and f.low<=z1 and f.xmax>=x0 and f.xmin<=x1 and f.ymax>=y0 and f.ymin<=y1 then
            local poly={}
            for i=1,3 do
                local v=f[i]
                local dx,dy=v[1]-a.x,v[2]-a.y
                local along=dx*ux+dy*uy
                poly[i]={along,dy*ux-dx*uy,v[3]-a.z-along*(b.z-a.z)/span}
            end
            poly=clipped(poly,1,0,1)
            poly=clipped(poly,1,span,-1)
            poly=clipped(poly,2,-.45,1)
            poly=clipped(poly,2,.45,-1)
            poly=clipped(poly,3,.35,1)
            if #clipped(poly,3,1.6,-1)>0 then return false end
        end
    end
    return true
end

-- Trace both the supporting surface and the rendered chord. Geometry is
-- complete within the source page halo for short endpoint connectors.
local grade,descentGrade=math.tan(math.rad(50)),math.tan(math.rad(60))
local function supportsDirection(face,dx,dy,length)
    if not face.steep then return true end
    if face.model or face.liquid or face.nz<=1e-10 then return false end
    local limit=grade*length*face.nz
    local downhill=face.nx*dx+face.ny*dy
    return downhill>=limit and downhill<=descentGrade*length*face.nz and abs(face.nx*dy-face.ny*dx)<=limit
end
local function fineJoin(page,a,b,stepDown)
    local dx,dy=b.x-a.x,b.y-a.y
    local length=sqrt(dx*dx+dy*dy)
    if length<1e-8 then
        for _,height in ipairs(fineHeights(page,a)) do
            if abs(a.z-height)<.01 and abs(b.z-height)<.01 then return true end
        end
        return false
    end
    local faces,seen,spans,cuts={},{},{},{0,1}
    local x0,x1=min(a.x,b.x)-.45,max(a.x,b.x)+.45
    local y0,y1=min(a.y,b.y)-.45,max(a.y,b.y)+.45
    local z0,z1=min(a.z,b.z)-2,max(a.z,b.z)+3.6
    for x=floor(x0/4),floor(x1/4) do
        for y=floor(y0/4),floor(y1/4) do
            local bin=page.bins[G.columnKey(x,y)]
            for i=1,bin and #bin or 0 do
                work()
                local f=bin[i]
                if not seen[f] then
                    seen[f]=true
                    G.prepareFace(page,f)
                    if f.high>=z0 and f.low<=z1 and f.xmax>=x0 and f.xmin<=x1 and f.ymax>=y0 and f.ymin<=y1 then
                        if f.liquid then return false end
                        if f.model or f.steep then faces[#faces+1]=f end
                        local lo,hi=fineSpan(f,a,b)
                        if lo then
                            cuts[#cuts+1]=lo
                            cuts[#cuts+1]=hi
                            if supportsDirection(f,dx,dy,length) then spans[#spans+1]={f,lo,hi,#spans+1} end
                        end
                    end
                end
            end
        end
    end
    local parts=math.ceil(length/.45)
    for i=1,parts-1 do cuts[#cuts+1]=i/parts end
    table.sort(cuts)
    table.sort(spans,function(left,right) return left[2]<right[2] end)
    local active,nextSpan={},1
    local t,z=0,a.z
    local previous, stepped
    for _,u in ipairs(cuts) do
        if (u-t)*length>=.001 or (u==1 and t<1) then
            local from={x=a.x+t*dx,y=a.y+t*dy}
            local to={x=a.x+u*dx,y=a.y+u*dy}
            local m=(u+t)/2
            while spans[nextSpan] and spans[nextSpan][2]<=m do
                work()
                active[#active+1]=spans[nextSpan]
                nextSpan=nextSpan+1
            end
            local support,supportOrder
            for index=#active,1,-1 do
                work()
                local s=active[index]
                if s[3]<m then
                    active[index]=active[#active]
                    active[#active]=nil
                else
                    local hz=fineHeight(s[1],from.x,from.y)
                    local endZ=fineHeight(s[1],to.x,to.y)
                    local drop=stepDown and not stepped and previous and previous.model and z-hz
                    if (abs(hz-z)<=(t==0 and .01 or .35) or drop and drop>.35 and drop<=.65)
                        and (not to.z or endZ>to.z or (endZ==to.z and s[4]<supportOrder)) then
                        from.z,to.z,support,supportOrder=hz,endZ,s[1],s[4]
                    end
                end
            end
            if not to.z then return false end
            if stepDown then
                if max(from.z,to.z)>a.z+.05 or min(from.z,to.z)<b.z-.05 then return false end
                if z-from.z>.35 then stepped=true end
            elseif abs(from.z-a.z-t*(b.z-a.z))>.35 or abs(to.z-a.z-u*(b.z-a.z))>.35
                or not bodyClear(faces,from,to) then return false end
            t,z,previous=u,to.z,support
        end
    end
    if abs(z-b.z)>.01 then return false end
    if stepDown then
        -- Keep the body above the lip until it clears the riser. The
        -- caller validates the whole landing footprint at the lower height.
        return stepped and bodyClear(faces,a,{x=b.x,y=b.y,z=a.z})
    end
    return bodyClear(faces,a,b)
end

-- At a tight endpoint a sampled compass can miss the only free heading.
-- Split the lateral body's orientations at clipped vertices and intersections
-- with its footprint circle. At a bend require the entire rotation disk.
local function footprint(page,point,angles,radius)
    radius=radius or .45
    local seen={}
    for ix=floor((point.x-radius)/4),floor((point.x+radius)/4) do
        for iy=floor((point.y-radius)/4),floor((point.y+radius)/4) do
            local bin=page.bins[G.columnKey(ix,iy)]
            for i=1,bin and #bin or 0 do
                work()
                local f=bin[i]
                if not seen[f] then
                    seen[f]=true
                    G.prepareFace(page,f)
                    if (f.model or f.steep) and f.high>=point.z+.35 and f.low<=point.z+1.6 then
                        local poly=clipped(clipped(f,3,point.z+.35,1),3,point.z+1.6,-1)
                        local positive,negative,area=false,false,0
                        for k=1,#poly do
                            local a,b=poly[k],poly[k%#poly+1]
                            local x,y=a[1]-point.x,a[2]-point.y
                            local dx,dy=b[1]-a[1],b[2]-a[2]
                            local length,dot=dx*dx+dy*dy,x*dx+y*dy
                            local c=x*x+y*y-radius*radius
                            local cross=x*dy-y*dx
                            area=area+cross
                            positive,negative=positive or cross>0,negative or cross<0
                            if not angles then
                                local t=length>0 and max(0,min(1,-dot/length)) or 0
                                if (x+t*dx)^2+(y+t*dy)^2<=radius*radius then return false end
                            else
                                if c<=0 then angles[#angles+1]=math.atan2(y,x)%math.pi end
                                local disc=dot*dot-length*c
                                if length>0 and disc>=0 then
                                    local root=sqrt(disc)
                                    for sign=-1,1,2 do
                                        local t=(-dot+sign*root)/length
                                        if t>=0 and t<=1 then
                                            angles[#angles+1]=math.atan2(y+t*dy,x+t*dx)%math.pi
                                        end
                                    end
                                end
                            end
                        end
                        if not angles and abs(area)>1e-10 and positive~=negative then return false end
                    end
                end
            end
        end
    end
    return true
end

local function fineStepDown(page,a,b)
    local drop=a.z-b.z
    local span=(a.x-b.x)^2+(a.y-b.y)^2
    return drop>.35 and drop<=.65 and span>=.5 and span<=2.000001
        and fineJoin(page,a,b,true) and footprint(page,b)
end

-- Both windows carry native triangles in a two-yard halo. A short handoff
-- must follow the same floor and clear the swept body in both extracts.
local function windowJoin(page,other,a,b)
    return abs(a.z-b.z)<=2 and fineJoin(page,a,b) and (not other or fineJoin(other,a,b))
end

local function fineNodes(st,page,point,outgoing)
    local nodes,bends,used={},{},{}
    local unit=page.step
    local function clear(a,b)
        return outgoing and fineJoin(page,a,b) or not outgoing and fineJoin(page,b,a)
    end
    local function connect(mid,radius)
        for ix=math.ceil((mid.x-radius)/unit),floor((mid.x+radius)/unit) do
            for iy=math.ceil((mid.y-radius)/unit),floor((mid.y+radius)/unit) do
                local x,y=ix*unit,iy*unit
                local p=G.surfacePage(st,x,y,true,page)
                local col=p and p.columns[G.columnKey(x,y)]
                for i=1,col and #col or 0 do
                    local n=col[i]
                    if not used[n.id] and abs(n.z-mid.z)<=2 and (mid==point or
                        p==page and (x-mid.x)^2+(y-mid.y)^2<=radius^2) and clear(mid,n) then
                        nodes[#nodes+1],used[n.id]=n,true
                        if mid~=point then bends[n.id]=mid end
                    end
                end
            end
        end
    end
    connect(point,1)
    if #nodes==0 then
        local angles={0,math.pi}
        footprint(page,point,angles)
        table.sort(angles)
        for i=2,#angles do
            if angles[i]-angles[i-1]>1e-12 then
                local az=(angles[i]+angles[i-1]+math.pi)/2
                for sign=-1,1,2 do
                    for j=1,2 do
                        local r=sign*j*.5
                        local mid={x=point.x+r*math.cos(az),y=point.y+r*math.sin(az)}
                        if G.surfacePage(st,mid.x,mid.y,true,page)==page then
                            for _,z in ipairs(fineHeights(page,mid)) do
                                mid.z=z
                                if abs(z-point.z)<=1.2 and footprint(page,mid) and clear(point,mid) then
                                    -- The same XY can support more than one height.
                                    connect({x=mid.x,y=mid.y,z=z},1.5)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return nodes,bends
end

local function fineDistance(a,b)
    return sqrt((a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2)
end

local function joinDistance(a,b,via)
    if via then return fineDistance(a,via)+fineDistance(via,b) end
    return fineDistance(a,b)
end

local function chooseHeight(heights,observed,tolerance)
    if observed==nil then return #heights==1 and heights[1] or nil end
    local z,gap
    for _,h in ipairs(heights) do
        local d=abs(h-observed)
        if d<=tolerance and (not gap or d<gap) then z,gap=h,d
        elseif d==gap then z=nil end
    end
    return z
end

local function precisePoint(p,z) return {x=p.x,y=p.y,z=z} end

local function standingHeights(page, point)
    local heights = {}
    for _, height in ipairs(fineHeights(page, point)) do
        -- A floor above terrain can obstruct the body's centre on that
        -- terrain. Lateral clearance is checked by the actual join.
        if footprint(page, precisePoint(point, height), nil, 0) then
            heights[#heights + 1] = height
        end
    end
    return heights
end

local function departureHeight(page, point)
    local heights = point.z ~= nil and fineHeights(page, point) or standingHeights(page, point)
    return chooseHeight(heights, point.z, 1.05)
end

function runtime.UniqueSurfaceHeight(st, point)
    local page = G.surfacePage(st, point.x, point.y, true)
    return page and chooseHeight(standingHeights(page, point))
end

function runtime.PreviewHeight(st, point, coarseHeight)
    local page, covered = G.surfacePage(st, point.x, point.y, true)
    if page then return departureHeight(page, point), page end
    if not covered then return coarseHeight(st, point, 1.05) end
end

function runtime.MatchSurfaceHeights(st, point, coarse, load)
    local page, covered = G.surfacePage(st, point.x, point.y, load)
    local key = G.locate(st, point.x, point.y)
    local raw = st.data.surface or st.data.packed and st.data.packed.surface
    if not page and (covered or key and raw and raw[key + 1] and not st.surface[key]) then return {} end
    if not page then return coarse end
    local heights, seen = {}, {}
    local fine = standingHeights(page, point)
    for _, z in ipairs(coarse) do
        local height = chooseHeight(fine, z, 5)
        if height and not seen[height] then
            seen[height] = true
            heights[#heights + 1] = height
        end
    end
    return heights
end

function runtime.StackedSurfaceGoal(map,from,goal)
    local st=G.State(map)
    if not st then return end
    local page=G.surfacePage(st,goal.x,goal.y,true)
    return page and G.sameWindow(page,G.surfacePage(st,from.x,from.y,true)) and #fineHeights(page,goal)>1
end

local function dryFooting(page,p)
    for x=floor((p.x-.45)/4),floor((p.x+.45)/4) do
        for y=floor((p.y-.45)/4),floor((p.y+.45)/4) do
            local bin=page.bins[G.columnKey(x,y)]
            for i=1,bin and #bin or 0 do
                work()
                local f=bin[i]
                if f.liquid then
                    G.prepareFace(page,f)
                    if f.high>=p.z-.35 and f.low<=p.z+1.6
                        and max(f[1][1],f[2][1],f[3][1])>=p.x-.45 and min(f[1][1],f[2][1],f[3][1])<=p.x+.45
                        and max(f[1][2],f[2][2],f[3][2])>=p.y-.45 and min(f[1][2],f[2][2],f[3][2])<=p.y+.45 then
                        return false
                    end
                end
            end
        end
    end
    return true
end

local function fineColumn(st,page,x,y)
    if x<page.xmin or x>page.xmax or y<page.ymin or y>page.ymax then return end
    local key=G.columnKey(x,y)
    local column=page.columns[key]
    if column then return column end
    local other=G.surfacePage(st,x,y,true,page)
    return other and other.columns[key]
end

local function intersectingWindows(st,minX,maxX,minY,maxY,visit)
    local span=st.unit*st.c
    for x=max(0,floor((minX-st.x0)/span)),min(st.data.nx-1,floor((maxX-st.x0)/span)) do
        for y=max(0,floor((minY-st.y0)/span)),min(st.data.ny-1,floor((maxY-st.y0)/span)) do
            local key=x*st.data.ny+y
            for _,entry in ipairs(G.surfaceAtlas(st,key,true) or {}) do
                work()
                if entry.xmin<=maxX and entry.xmax>=minX and entry.ymin<=maxY and entry.ymax>=minY
                    and visit(key,entry) then
                    return true
                end
            end
        end
    end
end

local crossesPage
local function certifiedStep(st,a,b,d,load,tiles)
    local k,j=a.canonical.key,b.canonical.key
    local t=G.canonicalTopology(st,k,tiles)
    local u=k==j and t or G.canonicalTopology(st,j,tiles)
    if not t or not u then return end
    local n,m=G.layer(t,a.cell,a.layer),G.layer(u,b.cell,b.layer)
    if not n or not m then return end
    if k==j then return canStep(t,n,m,d,st.c) end
    return d<=4 and crossesPage(st,k,t,n,j,u,m,load and {} or nil)
end

local function mixedNeighbors(st,n,score,cost,visit,tiles,deferChecks,windows)
    local function join(other,page,second)
        local total=score+fineDistance(n,other)
        if (not cost[other.id] or total<cost[other.id]) and windowJoin(page,second,n,other) then
            visit(other,total,n.id)
        end
    end
    if n.canonical then
        -- PCG1 supplies the directed physical arc. The active grid and
        -- portals must independently permit the same surface transition.
        local column,row=floor(n.cell/st.c),n.cell%st.c
        for p=n.first,n.first+2*n.count-1,2 do
            work()
            local dir,layer=n.bytes:byte(p,p+1)
            local d=dir+1
            local cx,cy=column+dx[d],row+dy[d]
            local page,c=n.canonical,cx*st.c+cy
            if cx<0 or cx>=st.c or cy<0 or cy>=st.c then
                local k
                k,c=G.locate(st,n.x+dx[d]*st.unit,n.y+dy[d]*st.unit)
                page=G.canonicalPage(st,k,true)
            end
            local other=page and G.canonicalNode(st,page,c,layer)
            if other and (deferChecks or certifiedStep(st,n,other,d,true,tiles)) then
                if not deferChecks then
                    n.allowed=n.allowed or {}
                    n.allowed[p]=true
                end
                visit(other,score+fineDistance(n,other),n.id)
            end
        end
    elseif tiles then
        -- At supported lattice spacings only the containing or adjacent
        -- coarse centres can be within the endpoint geometry halo.
        for ix=math.ceil((n.x-1-st.x0)/st.unit-.5),floor((n.x+1-st.x0)/st.unit-.5) do
            for iy=math.ceil((n.y-1-st.y0)/st.unit-.5),floor((n.y+1-st.y0)/st.unit-.5) do
                local x,y=st.x0+(ix+.5)*st.unit,st.y0+(iy+.5)*st.unit
                local k,c=G.locate(st,x,y)
                if k then
                    local page=G.canonicalPage(st,k,true)
                    local tile=page and G.canonicalTopology(st,k,tiles)
                    local layers=tile and tile.layers[c]
                    for layer=0,tile and (layers and #layers or 0) or -1 do
                        local other=G.canonicalNode(st,page,c,layer)
                        if other then join(other,n.page) end
                    end
                end
            end
        end
    end
    local minX,maxX,minY,maxY=n.x-1,n.x+1,n.y-1,n.y+1
    intersectingWindows(st,minX,maxX,minY,maxY,function(key,entry)
        if G.sameWindow(n.page,entry)
            or windows and not (G.sameWindow(windows[1],entry) or G.sameWindow(windows[2],entry)) then return end
        local window=G.surfaceWindow(st,key,entry,true)
        local unit=window.step
        for ix=math.ceil(minX/unit),floor(maxX/unit) do
            for iy=math.ceil(minY/unit),floor(maxY/unit) do
                local column=window.columns[G.columnKey(ix*unit,iy*unit)]
                for i=1,column and #column or 0 do
                    join(column[i],window,n.page)
                end
            end
        end
    end)
end

-- For an optional map-pin approach, choose a dry stopping point within the
-- actual departure component before considering imprecise coarse candidates.
function runtime.SurfaceApproach(map,from,goal,accept,radius)
    local st=G.State(map)
    local page=G.surfacePage(st,from.x,from.y,true)
    if not page then return end
    local z=departureHeight(page,from)
    if not z then return end
    local queue=fineNodes(st,page,precisePoint(from,z),true)
    local best=(from.x-goal.x)^2+(from.y-goal.y)^2
    local seen,selected={},nil
    for _,n in ipairs(queue) do seen[n.id]=true end
    local head=1
    while head<=#queue do
        work()
        local n=queue[head]
        head=head+1
        local distance=(n.x-goal.x)^2+(n.y-goal.y)^2
        if radius and distance<radius*radius and dryFooting(n.page,n) and accept(n) then
            return precisePoint(n,n.z)
        end
        if not radius and distance>.000001 and distance<best and dryFooting(n.page,n) and accept(n) then
            best,selected=distance,n
        end
        for pos=n.first,n.first+2*n.count-1,2 do
            work()
            local d,ord=n.bytes:byte(pos,pos+1)
            assert(d<8,"invalid fine terrain direction")
            local col=fineColumn(st,n.page,n.x+dx[d+1]*n.page.step,n.y+dy[d+1]*n.page.step)
            local other=assert(col and col[ord+1],"missing fine terrain landing")
            if not seen[other.id] then queue[#queue+1],seen[other.id]=other,true end
        end
    end
    if selected then return precisePoint(selected,selected.z) end
end

-- Roofs and isolated landings often form small directed components. Exhaust
-- their predecessors before making a forward search visit the whole window.
local function isolatedFloor(st,links,startIds)
    local queue,seen={},{}
    for _,node in ipairs(links) do
        queue[#queue+1],seen[node.id]=node,true
    end
    local head=1
    while head<=#queue do
        work()
        if #queue>1024 then return false end
        local node=queue[head]
        if startIds[node.id] then return false end
        head=head+1
        for d=1,8 do
            local step=node.page.step
            local col=fineColumn(st,node.page,node.x-dx[d]*step,node.y-dy[d]*step)
            for i=1,col and #col or 0 do
                local prev=col[i]
                if not seen[prev.id] then
                    for p=prev.first,prev.first+2*prev.count-1,2 do
                        work()
                        local dir,ordinal=prev.bytes:byte(p,p+1)
                        if dir==d-1 and ordinal==node.ordinal then
                            queue[#queue+1],seen[prev.id]=prev,true
                            break
                        end
                    end
                end
            end
        end
    end
    return true
end

-- Collapse each 8x8 block to estimate the detour around impassable terrain.
-- A block boundary only supplies a search priority. Every returned point
-- still comes from the directed lattice or an individually verified join.
local function previewDistances(st,from,to)
    if st.c%8~=0 then return end
    local unit=8*st.unit
    local function sector(p) return floor((p.x-st.x0)/unit)*65536+floor((p.y-st.y0)/unit) end
    local source,goal=sector(from),sector(to)
    local distance,queue={[goal]=0},{goal}
    local head=1
    while head<=#queue do
        work()
        local id=queue[head]
        head=head+1
        if distance[source] and distance[id]>distance[source]+3 then break end
        local sx,sy=floor(id/65536),id%65536
        for d=1,8 do
            local x,y=sx+dx[d],sy+dy[d]
            local prev=x*65536+y
            if not distance[prev] and x>=0 and y>=0 and x*8<st.c*st.data.nx and y*8<st.c*st.data.ny then
                local k=floor(x*8/st.c)*st.data.ny+floor(y*8/st.c)
                local page=G.canonicalPage(st,k,true)
                if page and page.sectors[prev] and page.sectors[prev][id] then
                    distance[prev]=distance[id]+1
                    queue[#queue+1]=prev
                end
            end
        end
    end
    if distance[source] then
        return function(p,lower)
            return (distance[sector(p)] or distance[source]+5)*unit + .15*lower
        end
    end
end

local function simplifySurfacePath(st, map, path)
    local result, first = {path[1]}, 1
    while first < #path do
        work()
        local anchor, nextIndex = path[first], first + 1
        local page = G.surfacePage(st, anchor.x, anchor.y, true)
        if page then
            local candidate = min(#path, first + floor(2 * fineChordLimit / page.step))
            while candidate > first + 1 do
                work()
                local point = path[candidate]
                if max(abs(point.x - anchor.x), abs(point.y - anchor.y)) <= fineChordLimit then
                    if runtime.Sight(map, anchor.x, anchor.y, anchor.z, point.x, point.y, point.z, {}, nil, nil, true) then
                        nextIndex = candidate
                        break
                    end
                    if G.surfacePage(st, point.x, point.y, true) == page then
                        -- Inside one window, shorten failed shortcuts near a bend.
                        -- At window seams, inspect every candidate for the join.
                        candidate = first + floor((candidate - first) * .75)
                    else
                        candidate = candidate - 1
                    end
                else
                    candidate = candidate - 1
                end
            end
        end
        result[#result + 1] = path[nextIndex]
        first = nextIndex
    end
    return result
end

-- A detailed corridor can start or end outside its fine windows. Attach the
-- actual floor through a certified cell centre in the direction of travel.
local function coarseConnector(st, request, point, departing)
    local key,cell=G.locate(st,point.x,point.y)
    local page=G.canonicalPage(st,key,true)
    if not page then return end
    local service = not departing and request.serviceTarget
    local z = request.resolveEndpoint(st, point, service and 5 or 1.05)
    if not z then return end
    local tile = G.grid(st, page.key)
    if not tile then return end
    local floorNode = G.endpoint(st, tile, cell, z, point.x, point.y)
    local layers = tile.layers[cell]
    for layer = 0, layers and #layers or 0 do
        work()
        if G.layer(tile, cell, layer) == floorNode then
            local node = G.canonicalNode(st, page, cell, layer)
            if node then
                local height = service and z or point.z or z
                local endpoint = precisePoint(point,height)
                local a,b=node,endpoint
                if departing then a,b=b,a end
                if runtime.Sight(request.map,a.x,a.y,a.z,b.x,b.y,b.z,{}) then return node,height end
            end
            return
        end
    end
end

function runtime.SurfaceRoute(request,eager,allWindows,stepDown)
    local st=G.State(request.map)
    local from,to=request.from,request.to
    local startPage=G.surfacePage(st,from.x,from.y,true)
    local goalPage=G.surfacePage(st,to.x,to.y,true)
    if not startPage and not goalPage then return false end
    local mixed=not G.sameWindow(startPage,goalPage)
    local multipleWindows=mixed or allWindows
    local departure,sourceZ,arrival,arrivalHeight
    if startPage then
        sourceZ=departureHeight(startPage,from)
    else
        departure,sourceZ=coarseConnector(st,request,from,true)
        if not departure then return false end
    end
    if not goalPage then
        arrival,arrivalHeight=coarseConnector(st,request,to,false)
        if not arrival then return false end
    end
    local heights=goalPage and fineHeights(goalPage,to) or {arrivalHeight}
    if goalPage and to.z==nil then
        for _,h in ipairs(heights) do
            if not dryFooting(goalPage,precisePoint(to,h)) then
                -- A stacked dry surface cannot identify a submerged map pin.
                -- An observed departure in the requested region may approach
                -- along its own directed dry component.
                local observedRegion=from.region and from.region==to.region and from.z~=nil and sourceZ
                return true,nil,"surface",{unresolvedSurface=true,unresolvedTo=true,
                    unresolvedFrom=not sourceZ,wetFloor=#heights==1 and h or nil,
                    dryApproach=not not observedRegion}
            end
        end
    end
    if goalPage and to.z~=nil then
        local gz=chooseHeight(heights,to.z,request.serviceTarget and 5 or 1.05)
        heights=gz and dryFooting(goalPage,precisePoint(to,gz)) and {gz} or {}
    elseif #heights>1 and not request.resolveGoalXY then
        return true,nil,"surface",{unresolvedSurface=true,unresolvedFrom=not sourceZ,unresolvedTo=true}
    end
    if not sourceZ or #heights==0 then
        return true,nil,"surface",{unresolvedSurface=true,unresolvedFrom=not sourceZ,unresolvedTo=#heights==0}
    end
    local start=precisePoint(from,sourceZ)
    local starts,startBends
    if departure then
        start.coarseEndpoint=true
        starts,startBends={departure},{}
    else
        starts,startBends=fineNodes(st,startPage,start,true)
    end
    if #starts==0 then return true,nil,"unverified","start" end
    local finishes, floorLinks, endBends, connectedFloors={},{},{},0
    local connectorDiscount=.12
    for index,z in ipairs(heights) do
        local links,bends
        if arrival then links,bends={arrival},{} else links,bends=fineNodes(st,goalPage,precisePoint(to,z),false) end
        endBends[index]=bends
        if next(bends) then connectorDiscount=.21 end
        floorLinks[index]=links
        if #links>0 then connectedFloors=connectedFloors+1 end
        for _,node in ipairs(links) do
            local list=finishes[node.id] or {}
            list[#list+1]=index
            finishes[node.id]=list
        end
    end
    if connectedFloors==0 then return true,nil,"unverified","goal" end
    local queue,cost,parent,nodes={},{},{},{}
    -- Nearby windows can share a short corridor. The weighted preview can
    -- send that walk toward a coarse portal even when an exact route is cheap.
    local localSpan = st.unit * st.c
    local distant = (from.x-to.x)^2 + (from.y-to.y)^2 > localSpan^2
    local preview=mixed and distant and request.quick and connectedFloors==1 and {} or nil
    local estimate=preview and previewDistances(st,from,to)
    local function visit(node,score,prev)
        if preview and preview[node.id] then return end
        if not cost[node.id] or score<cost[node.id] then
            nodes[node.id],cost[node.id],parent[node.id]=node,score,prev
            local x,y=abs(node.x-to.x),abs(node.y-to.y)
            -- Lattice steps change one or both axes. Only the final connector
            -- (at most one yard per axis) escapes that octile lower bound.
            local octile=max(x,y)+diagonalExtra*min(x,y)
            local lower=sqrt(x*x+y*y)
            if not multipleWindows then lower=max(lower,octile-connectorDiscount) end
            -- The immediate preview may choose the first proven corridor.
            -- The exact comparison and ambiguous floors keep ordinary A*.
            if preview then lower=estimate and 1.5*estimate(node,lower) or 2*lower end
            push(queue,node.id,score,score+lower)
        end
    end
    for _,n in ipairs(starts) do visit(n,joinDistance(start,n,startBends[n.id])) end
    local winner,storey,best,checkedFloors
    local tiles=mixed and {} or nil
    -- Keep the continental search on the certified coarse mesh. Only enter
    -- the detailed windows at the endpoints unless they cannot be connected.
    local windows=mixed and not allWindows and {startPage or goalPage,startPage and goalPage} or nil
    while #queue>0 do
        work()
        if connectedFloors==1 and best and queue[1].rank>best then break end
        local id,score=pop(queue)
        if cost[id]==score then
            local n=nodes[id]
            if preview then preview[id]=true end
            for _,i in ipairs(finishes[id] or {}) do
                if storey and i~=storey then return true,nil,"surface",{unresolvedSurface=true,unresolvedTo=true} end
                local value=score+joinDistance(n,precisePoint(to,heights[i]),endBends[i][id])
                if not best or value<best then winner,storey,best=id,i,value end
            end
            if not multipleWindows and best and connectedFloors>1 and not checkedFloors then
                checkedFloors=true
                local startIds={}
                for _,node in ipairs(starts) do startIds[node.id]=true end
                for i,links in ipairs(floorLinks) do
                    if i~=storey and #links>0 and isolatedFloor(st,links,startIds) then
                        connectedFloors=connectedFloors-1
                    end
                end
            end
            if multipleWindows then
                mixedNeighbors(st,n,score,cost,visit,tiles,preview and not eager,windows)
            end
            if not n.canonical then
                local page, key = n.page, G.columnKey(n.x, n.y)
                local columns, step = page.columns, page.step
                local stepSquared = step * step
                for pos=n.first,n.first+2*n.count-1,2 do
                    work()
                    local dir,ord=n.bytes:byte(pos,pos+1)
                    assert(dir<8,"invalid fine terrain direction")
                    local d = dir + 1
                    local column = columns[key + step * fineColumnOffsets[d]]
                        or fineColumn(st, page, n.x + dx[d]*step, n.y + dy[d]*step)
                    local other=assert(column and column[ord+1],"missing fine terrain landing")
                    local previous = cost[other.id]
                    if not previous or score < previous then
                        local dz = other.z - n.z
                        local horizontal = d <= 4 and stepSquared or 2 * stepSquared
                        visit(other, score + sqrt(horizontal + dz * dz), id)
                    end
                end
            end
            if stepDown and not n.canonical then
                for d=1,8 do
                    work()
                    local column=fineColumn(st,n.page,n.x+dx[d],n.y+dy[d])
                    for _,other in ipairs(column or {}) do
                        if (not cost[other.id] or score<cost[other.id]) and fineStepDown(n.page,n,other) then
                            visit(other,score+fineDistance(n,other),id)
                        end
                    end
                end
            end
        end
    end
    if not winner then
        if not stepDown and from.indoors == true then return runtime.SurfaceRoute(request,eager,allWindows,true) end
        if windows then return runtime.SurfaceRoute(request,eager,true,stepDown) end
        if not multipleWindows and intersectingWindows(st,startPage.xmin-1,startPage.xmax+1,
            startPage.ymin-1,startPage.ymax+1,function(_,entry) return not G.sameWindow(startPage,entry) end) then
            return runtime.SurfaceRoute(request,eager,true,stepDown)
        end
        if arrival or departure then return false end
        return true,nil,"unverified","interior"
    end
    local path={start}
    local chain=unravel(parent,winner)
    if preview and not eager then
        -- Validate the winning preview against this exact grid and its
        -- portals before publishing. A rejected edge triggers eager search.
        for i=#chain,2,-1 do
            work()
            local a,b=nodes[chain[i]],nodes[chain[i-1]]
            if a.canonical and b.canonical then
                local valid=false
                for p=a.first,a.first+2*a.count-1,2 do
                    local dir,layer=a.bytes:byte(p,p+1)
                    local d=dir+1
                    if layer==b.layer and abs(a.x+dx[d]*st.unit-b.x)<1e-6
                        and abs(a.y+dy[d]*st.unit-b.y)<1e-6 and certifiedStep(st,a,b,d,true,tiles) then
                        a.allowed=a.allowed or {}
                        a.allowed[p],valid=true,true
                        break
                    end
                end
                if not valid then return runtime.SurfaceRoute(request,true,allWindows,stepDown) end
            end
        end
    end
    if startBends[chain[#chain]] then path[#path+1]=startBends[chain[#chain]] end
    for i=#chain,1,-1 do
        local n=nodes[chain[i]]
        if fineDistance(path[#path],n)>1e-8 then path[#path+1]=precisePoint(n,n.z) end
    end
    local goal=precisePoint(to,heights[storey])
    if endBends[storey][winner] then path[#path+1]=endBends[storey][winner] end
    if #path==1 or fineDistance(path[#path],goal)>1e-8 then
        goal.coarseEndpoint=arrival and true or nil
        path[#path+1]=goal
    end
    return true,simplifySurfacePath(st,request.map,path)
end

-- Return the interpolated height on a directed PCG1 edge that contains
-- both observations. Only edges already checked against this revision's
-- navigation graph may guide the passive cursor.
local function canonicalChord(st,x,y,z,tx,ty,tz,load)
    local key=G.locate(st,x,y)
    if not G.canonicalPage(st,key,load) then return end
    local unit,height,proven=st.unit,nil,false
    local ax,ay=(x-st.x0)/unit-.5,(y-st.y0)/unit-.5
    local bx,by=(tx-st.x0)/unit-.5,(ty-st.y0)/unit-.5
    -- Client world coordinates are single precision; comparisons in cell
    -- units must survive a round trip through the observed world position.
    local eps=max(1e-7,max(abs(x),abs(y),abs(tx),abs(ty))*2^-23/unit)
    for ix=math.ceil(ax-1-eps),floor(ax+1+eps) do
        for iy=math.ceil(ay-1-eps),floor(ay+1+eps) do
            for d=1,8 do
                local vx,vy=dx[d],dy[d]
                local length=vx*vx+vy*vy
                local a=((ax-ix)*vx+(ay-iy)*vy)/length
                local b=((bx-ix)*vx+(by-iy)*vy)/length
                if a>=-eps and b>=a-eps and b<=1+eps and
                    abs((ax-ix)*vy-(ay-iy)*vx)<eps and abs((bx-ix)*vy-(by-iy)*vx)<eps then
                    local sx,sy=st.x0+(ix+.5)*unit,st.y0+(iy+.5)*unit
                    local k,c=G.locate(st,sx,sy)
                    local j,v=G.locate(st,sx+vx*unit,sy+vy*unit)
                    local page=G.canonicalPage(st,k,load)
                    local dest=G.canonicalPage(st,j,load)
                    if page and dest then
                        if load or not z and page.upper[c] then
                            for layer=0,page.upper[c] or 0 do G.canonicalNode(st,page,c,layer) end
                        end
                        for _,n in ipairs(page.visited[c] or {}) do
                            for p=n.first,n.first+2*n.count-1,2 do
                                if n.bytes:byte(p)==d-1 and (not z or load or n.allowed and n.allowed[p]) then
                                    local m=G.canonicalNode(st,dest,v,n.bytes:byte(p+1))
                                    local allowed=n.allowed and n.allowed[p] or load and m and certifiedStep(st,n,m,d,true,{})
                                    if m and (allowed or not z) then
                                        local h=n.z+a*(m.z-n.z)
                                        if z and tz then
                                            if abs(h-z)<.01 and abs(n.z+b*(m.z-n.z)-tz)<.01 then
                                                n.allowed=n.allowed or {}
                                                n.allowed[p]=true
                                                return h
                                            end
                                        elseif height and abs(height-h)>.01 then return
                                        else height,proven=h,proven or allowed end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return proven and height or nil
end

function runtime.GuidanceHeight(id, x, y)
    local st = G.State(id)
    if not st then return end
    local page, covered=G.surfacePage(st,x,y,false)
    if page then
        return chooseHeight(standingHeights(page,{x=x,y=y}))
    end
    if covered then return end
    local physical=canonicalChord(st,x,y,nil,x,y,nil)
    if physical then return physical end
    local k, c = G.locate(st, x, y)
    local raw = st.data.surface or st.data.packed and st.data.packed.surface
    if k and raw and raw[k+1] and not st.surface[k] then return end
    local t = st.grid[k]
    if t and G.uniqueHeight(t, c) ~= nil then
        return G.surfaceHeight(st, t, t.z[c] and c or t.layers[c][1], x, y)
    end
end

function runtime.ContinueWalkingHeight(point, previous)
    local map = point.instanceID
    local st = G.State(map)
    if not st then return end
    local page = G.surfacePage(st, point.x, point.y, false)
    if not page or not G.sameWindow(page, G.surfacePage(st, previous.x, previous.y, false)) then return end
    local height
    for _, z in ipairs(standingHeights(page, point)) do
        local clear = runtime.Sight(map, previous.x, previous.y, previous.z,
            point.x, point.y, z, nil, nil, nil, true)
        if clear == nil or (clear and height ~= nil) then return end
        if clear then height = z end
    end
    return height
end

-- Traverse the cells intersected by the actual segment, keeping the same
-- connected surface. Guidance reads the resident pages without inflating any.
local function gridCoordinate(world, origin, unit)
    local value = (world - origin) / unit
    local center = floor(value) + 0.5
    -- Undo floating-point cancellation when converting a generated centre
    -- back to grid space. A centre-to-centre diagonal crosses an exact corner.
    if abs(value - center) < 1e-10 then return center end
    return value
end

crossesPage=function(st, k, t, node, j, dest, candidate, ctx)
    local source = st.graph[k] or (ctx and G.graphPage(st, k))
    local target = st.graph[j] or (ctx and G.graphPage(st, j))
    if not source or not target then return end
    local cell = t.cell[node] or node
    local layer = 0
    if t.cell[node] then
        for i, surface in ipairs(t.layers[cell]) do
            if surface == node then layer = i; break end
        end
    end
    local entry = source.bySurface[cell * 64 + layer]
    if not entry then return false end
    for n = 0, entry.degree - 1 do
        if ctx then work() end
        local key, index = G.edge(st, k, source.bytes, entry.first + n * 14)
        if key == j then
            local other = target.nodes[index]
            if other and G.layer(dest, other.cell, other.layer) == candidate then return true end
        end
    end
    return false
end

local maxRise = math.tan(math.rad(50))
local function followsFan(fan, x, y, mx, my, first, last, width, z, tz)
    if last <= first then return true end
    local one = mx ~= my and (y - x) / (mx - my) or last
    local two = mx ~= -my and -(x + y) / (mx + my) or last
    one, two = max(first, min(last, one)), max(first, min(last, two))
    if one > two then one, two = two, one end
    local span = sqrt(mx*mx + my*my)
    local limit = maxRise * width
    local previous = G.fanHeight(fan, x + mx*first, y + my*first)
    local function supported(north, west)
        if sqrt(north*north + west*west) + 0.1 <= limit then return true end
        local along, lateral = (north*mx + west*my) / span, (north*my - west*mx) / span
        return along + 0.1 <= -limit and abs(lateral) + 0.1 <= limit
    end
    local function reaches(a, b)
        if a == b then return true end
        local mid = (a + b) / 2
        local px, py = x + mx*mid, y + my*mid
        local north, west = G.gradient(fan, px, py)
        if not supported(north, west) then
            -- On a shared triangle edge both faces have the same line of
            -- heights. Either incident face may support that exact traverse.
            if abs(abs(mx) - abs(my)) > 1e-10 or abs(abs(px) - abs(py)) > 1e-10 then return false end
            if abs(px) >= abs(py) then py = py + (py < 0 and -1e-8 or 1e-8)
            else px = px + (px < 0 and -1e-8 or 1e-8) end
            if not supported(G.gradient(fan, px, py)) then return false end
        end
        local height = G.fanHeight(fan, x + mx*b, y + my*b)
        if z and tz and abs(z + (tz - z)*b - height) > 1 then return false end
        local ok = height - previous <= span * (limit - 0.1) * (b - a)
        previous = height
        return ok
    end
    return reaches(first, one) and reaches(one, two) and reaches(two, last)
end

-- A coarse chord may enter or leave a fine window between its endpoints.
-- Inspect the part inside each window against native geometry as well.
local function fineInterval(st, key, window, load, x, y, z, tx, ty, tz, first, last)
    local function trim(origin, delta, low, high)
        if delta==0 then return origin>=low and origin<=high end
        local a,b=(low-origin)/delta,(high-origin)/delta
        first,last=max(first,min(a,b)),min(last,max(a,b))
        return first<=last
    end
    if not trim(x,tx-x,window.xmin,window.xmax) or not trim(y,ty-y,window.ymin,window.ymax) then return true end
    local page = G.surfaceWindow(st, key, window, load)
    if not page then return nil end
    if not z or not tz then return false end
    local function point(t)
        local p={x=x+(tx-x)*t,y=y+(ty-y)*t,z=z+(tz-z)*t}
        p.z=chooseHeight(fineHeights(page,p),p.z,st.data.zstep/2+.05)
        return p.z and p
    end
    local a,b=point(first),point(last)
    return a and b and fineJoin(page,a,b) or false
end

function runtime.Sight(id, x, y, z, tx, ty, tz, ctx, ceiling, unbranched,nativeOnly,shortJoin)
    local st = G.State(id)
    if not st then return end
    local fine,fineCovered,finePending=G.surfacePage(st,x,y,ctx~=nil)
    local other,otherCovered,otherPending=G.surfacePage(st,tx,ty,ctx~=nil)
    if z and tz and canonicalChord(st,x,y,z,tx,ty,tz,nativeOnly and ctx~=nil) then return true end
    -- A cold atlas cannot disprove a previously certified segment. Let the
    -- guidance cursor reload it through its bounded terrain job.
    if nativeOnly and (finePending or otherPending) then return nil end
    if G.sameWindow(fine,other) then
        if not z or not tz then return false end
        local unit=fine.step
        if x%unit==0 and y%unit==0 and tx%unit==0 and ty%unit==0 and (x~=tx or y~=ty) then
            local a,b=fine.columns[G.columnKey(x,y)],other.columns[G.columnKey(tx,ty)]
            if max(abs(tx-x),abs(ty-y))==unit then
                for i=1,a and #a or 0 do
                    local n=a[i]
                    if abs(n.z-z)<.001 then
                        for p=n.first,n.first+2*n.count-1,2 do
                            local d,ord=n.bytes:byte(p,p+1)
                            if d<8 and x+dx[d+1]*unit==tx and y+dy[d+1]*unit==ty and b and b[ord+1]
                                and abs(b[ord+1].z-tz)<.001 then return true end
                        end
                    end
                end
            end
        end
        local span = max(abs(tx-x),abs(ty-y))
        if span > fineChordLimit or (fine ~= other and span > 1) then return false end
        local a,b={x=x,y=y,z=z},{x=tx,y=ty,z=tz}
        if not nativeOnly then
            local tolerance=st.data.zstep/2+.05
            a.z=chooseHeight(fineHeights(fine,a),z,tolerance)
            b.z=chooseHeight(fineHeights(other,b),tz,tolerance)
        end
        return a.z~=nil and b.z~=nil and (fineJoin(fine,a,b) or fineStepDown(fine,a,b))
    end
    if (fine or not fineCovered) and (other or not otherCovered)
        and (fine or other) and z and tz and max(abs(tx-x),abs(ty-y))<=1 then
        local a,b={x=x,y=y,z=z},{x=tx,y=ty,z=tz}
        if windowJoin(fine or other,fine and other,a,b) then return true end
    end
    if nativeOnly and (not shortJoin or fineCovered or otherCovered) then return false end
    local function at(ix, iy)
        local c = st.c
        if ix < 0 or iy < 0 or ix >= st.data.nx * c or iy >= st.data.ny * c then return end
        local key = floor(ix / c) * st.data.ny + floor(iy / c)
        return st.grid[key] or (ctx and G.grid(st, key)), ix % c * c + iy % c, key
    end
    local fx, fy = gridCoordinate(x, st.x0, st.unit), gridCoordinate(y, st.y0, st.unit)
    local gx, gy = floor(fx), floor(fy)
    local ex, ey = gridCoordinate(tx, st.x0, st.unit), gridCoordinate(ty, st.y0, st.unit)
    local mx, my = ex - fx, ey - fy
    local sx, sy = mx >= 0 and 1 or -1, my >= 0 and 1 or -1
    local ax, ay = abs(mx), abs(my)
    local centerFrom = fx % 1 == 0.5 and fy % 1 == 0.5
    local centerTo = ex % 1 == 0.5 and ey % 1 == 0.5
    local diagonal = (centerFrom or centerTo) and abs(ax - ay) < 1e-10
    -- A sequence of collinear centre-to-centre edges is individually
    -- certified by the pack. Other chords need subcell clearance as well.
    local onEdges = (centerFrom and centerTo or ((centerFrom or centerTo) and max(ax, ay) < 1
        and (gx ~= floor(ex) or gy ~= floor(ey)))) and (ax == 0 or ay == 0 or diagonal)
    local mask
    if not onEdges and ax + ay > 0 then mask = 2 ^ (floor(math.atan2(my, mx) * 8 / math.pi + 0.5) % 16) end
    local missingSurface
    local function clears(tile, node, ix, iy, first, last)
        local pageKey=floor(ix/st.c)*st.data.ny+floor(iy/st.c)
        local raw=st.data.surface or st.data.packed and st.data.packed.surface
        if raw and raw[pageKey+1] then
            local atlas=G.surfaceAtlas(st,pageKey,ctx~=nil)
            if not atlas then missingSurface=true; return false end
            for _,window in ipairs(atlas) do
                local clear = fineInterval(st,pageKey,window,ctx~=nil,x,y,z,tx,ty,tz,first,last)
                if clear == nil then missingSurface = true end
                if not clear then return false end
            end
        end
        local fan = G.fan(tile, node)
        -- A graph edge identifies the surface transition. Its centre line
        -- still has to follow the actual terrain triangles when supplied.
        if not mask and not fan then return true end
        if fan and not followsFan(fan, fx-ix-0.5, fy-iy-0.5, mx, my, first, last, st.unit, z, tz) then
            return false
        end
        if fan and fan.occupied == 0 then return true end
        local offset = tile.subclearance and tile.subclearance[node]
        if not fan and not offset then return not (tile.clearance and bit(tile.clearance[node], mask)) end
        -- Visit open subcell intervals in their traversal order, including
        -- the occupied start and end subcells when the chord stays in one cell.
        local function indexAt(f, delta, cell, t)
            return max(0, min(3, floor(4 * (f + delta * t - cell))))
        end
        local function blocked(t)
            local index = indexAt(fx, mx, ix, t) * 4 + indexAt(fy, my, iy, t)
            if fan then return bit(fan.occupied, 2 ^ index) end
            return bit(G.submask(tile, offset, index), mask)
        end
        if blocked(first) or blocked(last) then return false end
        local here = first
        while here < last do
            local cut = last
            for b = 1, 3 do
                local a = mx ~= 0 and (ix + b / 4 - fx) / mx
                local c = my ~= 0 and (iy + b / 4 - fy) / my
                if a and a > here and a < cut then cut = a end
                if c and c > here and c < cut then cut = c end
            end
            if blocked((here + cut) / 2) then return false end
            here = cut
        end
        return true
    end
    local cx = sx > 0 and gx + 1 - fx or fx - gx
    local cy = sy > 0 and gy + 1 - fy or fy - gy
    local t, cell, key = at(gx, gy)
    if not t then return end
    local node, gap = G.endpoint(st, t, cell, z, x, y)
    if not node or gap > 10 then return false end
    ex, ey = floor(ex), floor(ey)
    local function cellExit(ix, iy, bx, by)
        return min(ix == ex and 1 or bx / ax, iy == ey and 1 or by / ay, 1)
    end
    local exit = cellExit(gx, gy, cx, cy)
    if not clears(t, node, gx, gy, 0, exit) then
        if missingSurface then return end
        return false
    end
    if abs(ex - gx) + abs(ey - gy) > 512 then return end
    while gx ~= ex or gy ~= ey do
        if ctx then work() end
        local stepX = gx ~= ex and (gy == ey or cx * ay <= cy * ax)
        local stepY = gy ~= ey and (gx == ex or cy * ax <= cx * ay)
        if diagonal and gx ~= ex and gy ~= ey then stepX, stepY = true, true end
        local xx, yy = gx + (stepX and sx or 0), gy + (stepY and sy or 0)
        local enter = exit
        if stepX then cx = cx + 1 end
        if stepY then cy = cy + 1 end
        exit = cellExit(xx, yy, cx, cy)
        local dest, v, nextKey = at(xx, yy)
        if not dest then return end
        local d
        if stepX and stepY then
            d = sx == 1 and (sy == 1 and 5 or 6) or (sy == 1 and 7 or 8)
        elseif stepX then
            d = sx == 1 and 1 or 2
        else
            d = sy == 1 and 3 or 4
        end
        local layers, nextNode = dest.layers[v], nil
        local required = xx == ex and yy == ey and G.endpoint(st, dest, v, tz, tx, ty)
        for i = 0, layers and #layers or 0 do
            local candidate = i == 0 and v or layers[i]
            if
                (not required or required == candidate)
                and dest.z[candidate]
                and clears(dest, candidate, xx, yy, enter, exit)
                and ((key == nextKey and canStep(t, node, candidate, d, st.c))
                    or (key ~= nextKey and d <= 4 and crossesPage(st, key, t, node, nextKey, dest, candidate, ctx)))
            then
                -- A known path can choose the closest connected next layer.
                -- With a single witness, an earlier fork makes the player's
                -- unobserved floor indeterminate even if one branch lines up.
                if unbranched and nextNode then return nil end
                if not nextNode or abs(dest.z[candidate] - t.z[node]) < abs(dest.z[nextNode] - t.z[node]) then
                    nextNode = candidate
                end
            end
        end
        if not nextNode then
            if missingSurface then return end
            return false
        end
        if (dest.clearance or dest.subclearance or dest.support) and (xx ~= ex or yy ~= ey) and z and tz then
            local nearest = ((xx + 0.5 - fx) * mx + (yy + 0.5 - fy) * my) / (mx * mx + my * my)
            local height = z + (tz - z) * max(enter, min(exit, nearest))
            if abs(G.centerHeight(dest, nextNode) - height) > (onEdges and 1e-6 or max(1, st.data.zstep / 2)) then return false end
        end
        if ceiling then
            local costs = dest.bits[nextNode] >= 32 and ctx.water or ctx.land
            if costs[dest.class[nextNode] or 0] > ceiling then return false end
        end
        t, node, gx, gy, cell, key = dest, nextNode, xx, yy, v, nextKey
    end
    local target, gap = G.endpoint(st, t, cell, tz, tx, ty)
    return node == target and gap <= 10
end
