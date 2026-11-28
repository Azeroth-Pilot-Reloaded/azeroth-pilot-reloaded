-- SPDX-License-Identifier: GPL-3.0-or-later
local runtime = LibStub("LibAPRNavigation-1.0")._TerrainNamespace
local enemyBits = { Alliance = 16, Horde = 8 }
local hostileMultiplier = 20
local styles = {
    balanced = { 1, 0.8, 1.3, 2.5, 2, 1 },
    fastest = { 1, 1, 1, 1.2, 2, 1 },
    roads = { 1, 0.5, 1.6, 4, 2, 1 },
}

function runtime.Prices(request, swim)
    local rates = styles[request.style] or styles.balanced
    local enemy = enemyBits[request.profile]
    local land, water = {}, {}
    for class = 0, 31 do
        local penalty = enemy and math.floor(class / enemy) % 2 == 1 and hostileMultiplier or 1
        land[class] = (rates[class % 8 + 1] or 1) * penalty
        water[class] = land[class] * (request.waterWalking and 1 or swim)
    end
    return land, water
end

function runtime.FactionCostContext(st, faction, load)
    local enemy = enemyBits[faction]
    if st and enemy and st.data.factionCosts == true then
        return {st = st, enemy = enemy, load = load, tiles = {}}
    end
end

local function HasEnemy(context, x, y)
    local grid, st = runtime.PathGrid, context.st
    local key, cell = grid.locate(st, x, y)
    if not key then return false end
    local tile = context.tiles[key]
    if tile == nil then
        tile = st.grid[key]
        if not tile and context.load then tile = grid.grid(st, key) end
        if not tile then
            if not context.load then return nil end
            context.tiles[key] = false
        else
            context.tiles[key] = tile
        end
    end
    if not tile then return false end
    return math.floor((tile.class[cell] or 0) / context.enemy) % 2 == 1
end

function runtime.HostileFraction(context, a, b)
    if not context then return 0 end
    local st = context.st
    local dx, dy = b.x - a.x, b.y - a.y
    if dx == 0 and dy == 0 then return 0 end
    local gx, gy = (a.x - st.x0) / st.unit, (a.y - st.y0) / st.unit
    local stepX, stepY = math.huge, math.huge
    local nextX, nextY = math.huge, math.huge
    if dx ~= 0 then
        stepX = st.unit / math.abs(dx)
        nextX = (dx > 0 and (math.floor(gx) + 1 - gx) or (gx - math.ceil(gx) + 1)) * stepX
    end
    if dy ~= 0 then
        stepY = st.unit / math.abs(dy)
        nextY = (dy > 0 and (math.floor(gy) + 1 - gy) or (gy - math.ceil(gy) + 1)) * stepY
    end
    local position, hostile = 0, 0
    while position < 1 do
        runtime.Work()
        local limit = math.min(1, nextX, nextY)
        if limit > position then
            local midpoint = (position + limit) / 2
            local enemy = HasEnemy(context, a.x + midpoint * dx, a.y + midpoint * dy)
            if enemy == nil then return nil end
            if enemy then hostile = hostile + limit - position end
        end
        if nextX == limit then nextX = nextX + stepX end
        if nextY == limit then nextY = nextY + stepY end
        position = limit
    end
    return hostile
end

function runtime.HostileDistance(context, a, b)
    local fraction = runtime.HostileFraction(context, a, b)
    if fraction == nil then return nil end
    return math.sqrt((b.x - a.x)^2 + (b.y - a.y)^2) * fraction
end

function runtime.WithFactionCost(seconds, hostileFraction)
    return seconds * (1 + (hostileMultiplier - 1) * hostileFraction)
end
