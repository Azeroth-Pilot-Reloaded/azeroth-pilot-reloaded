local terrain=LibStub("LibAPRNavigation-1.0")
if not terrain:MatchesGeneratedTerrain("retail","12.1.5.70961") then return end
local L=LibStub("LibAPRNavigation-1.0")
local D=assert(L._TerrainPackStages[1434])
D.packed.area[4]={"eNoLcvMFAAHSAOY="}
D.packed.graph[4]={"eNpzdHIEA2cw7QZFri6OTkg8ALUaCZQ="}
D.packed.grid[4]={"eNoLcdQfBaNgFIxUYAkAzRu8oA=="}
D.packed.height[4]={"eNqLAgAAWwBb"}
D.packed.area[2]={"eNpzdHTUHwWjYBSMNKAd5OYLANgpvC0="}
D.packed.class[2]={"eNpz1B8Fo2AUjDSg7QwAWie7CQ=="}
D.packed.graph[2]={"eNpzdHLRdnR0dHT2AJGuUOTq4ujk6OgGRa4AswMJhA=="}
D.packed.grid[2]={"eNpz1B8Fo2AUjDSgHeIIZVkCAPdrvN0="}
D.packed.height[2]={"eNpLBAAAYgBi"}
D.packed.area[3]={"eNpzdHTUHwWjYBSMVKAd5OZbDgB8Er4c"}
D.packed.class[3]={"eNpz1B8Fo2AUjFSg7VwOAPXdvPg="}
D.packed.floor[3]={"eNpzdHR2dNJ2ckp3dHN0dXTSB7FcHT0dHR0BW80G3A=="}
D.packed.graph[3]={"eNpzdHZ00nZydHR2dNIHUa6OTo6OblDk6uToiMRzReG5gXiuUOQKAJ2iEoM="}
D.packed.grid[3]={"eNpz1IcAi5ByR/1RMApGwUgD2gDPZr1T"}
D.packed.height[3]={"eNqLDAcAAQsAsQ=="}
D.packed.area[1]={"eNpzdHTUHwWjYBSMVKAd5OZbDgB8Er4c"}
D.packed.class[1]={"eNpz1B8Fo2AUjFRg4eLoXA4AcIu9ig=="}
D.packed.floor[1]={"eNpzdHR20dd2ckp3dHd0ddHXh7A8HR0dAVnPBr8="}
D.packed.graph[1]={"eNpzdHbR13ZydHR20dcHUa6OTo6OblDk6uHoiMRzReG5ofAAloYSbA=="}
D.packed.grid[1]={"eNpz1B8Fo2AUjFRgERQCAPX/vPE="}
D.packed.height[1]={"eNqLKAcAASkA0A=="}
L:RegisterTerrainData("retail",1434,D,20261123,true)
L._TerrainPackStages[1434]=nil
if not next(L._TerrainPackStages) then L._TerrainPackStages=nil end
