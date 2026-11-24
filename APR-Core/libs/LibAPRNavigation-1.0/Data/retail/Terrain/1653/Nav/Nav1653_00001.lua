local terrain=LibStub("LibAPRNavigation-1.0")
if not terrain:MatchesGeneratedTerrain("retail","12.1.5.70961") then return end
local L=LibStub("LibAPRNavigation-1.0")
local D=assert(L._TerrainPackStages[1653])
D.packed.graph[1]={"eNpzdAQAAMUAgw=="}
D.packed.grid[1]={"eNpz1B8Fo2AUjFSgDQB8Vbw+"}
D.packed.height[1]={}
L:RegisterTerrainData("retail",1653,D,20261123,true)
L._TerrainPackStages[1653]=nil
if not next(L._TerrainPackStages) then L._TerrainPackStages=nil end
