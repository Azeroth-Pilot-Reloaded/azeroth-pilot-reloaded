-- SPDX-License-Identifier: GPL-3.0-or-later
local runtime = LibStub("LibAPRNavigation-1.0")._TerrainNamespace
local styles = {
    balanced = { 1, 0.8, 1.3, 2.5, 2, 1 },
    fastest = { 1, 1, 1, 1.2, 2, 1 },
    roads = { 1, 0.5, 1.6, 4, 2, 1 },
}

function runtime.Prices(request, swim)
    local rates = styles[request.style] or styles.balanced
    local enemy = ({ Alliance = 16, Horde = 8 })[request.profile]
    local land, water = {}, {}
    for class = 0, 31 do
        local penalty = enemy and math.floor(class / enemy) % 2 == 1 and 20 or 1
        land[class] = (rates[class % 8 + 1] or 1) * penalty
        water[class] = land[class] * (request.waterWalking and 1 or swim)
    end
    return land, water
end
