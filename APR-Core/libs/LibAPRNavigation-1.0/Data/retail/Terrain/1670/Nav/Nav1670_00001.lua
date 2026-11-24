local terrain=LibStub("LibAPRNavigation-1.0")
if not terrain:MatchesGeneratedTerrain("retail","12.1.5.70961") then return end
local L=LibStub("LibAPRNavigation-1.0")
local D=assert(L._TerrainPackStages[1670])
D.packed.graph[1]={"eNpzdAQAAMUAgw=="}
D.packed.grid[1]={"eNoLTdaHAIvE0FHmKHOUOcocZdKYGQRlWYYAAIraTJ4="}
D.packed.height[1]={"eNqL0B8Fo2AUjFSgDQDYbLxV"}
L:RegisterTerrainData("retail",1670,D,20261123,true)
L._TerrainPackStages[1670]=nil
if not next(L._TerrainPackStages) then L._TerrainPackStages=nil end
