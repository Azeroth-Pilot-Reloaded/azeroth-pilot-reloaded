local terrain=LibStub("LibAPRNavigation-1.0")
if not terrain:MatchesGeneratedTerrain("retail","12.1.5.70961") then return end
local L=LibStub("LibAPRNavigation-1.0")
local D=assert(L._TerrainPackStages[2481])
D.packed.graph[19]={"eNpzdAQAAMUAgw=="}
D.packed.grid[19]={"eNpz1B8Fo2AUjFSgDQB8Vbw+"}
D.packed.height[19]={}
D.packed.graph[10]={"eNpzdAQAAMUAgw=="}
D.packed.grid[10]={"eNpz1B8Fo2AUjFSgDQB8Vbw+"}
D.packed.height[10]={}
D.packed.graph[1]={"eNpzdAQAAMUAgw=="}
D.packed.grid[1]={"eNpz1B8Fo2AUjFSgDQB8Vbw+"}
D.packed.height[1]={}
L:RegisterTerrainData("retail",2481,D,20261123,true)
L._TerrainPackStages[2481]=nil
if not next(L._TerrainPackStages) then L._TerrainPackStages=nil end
