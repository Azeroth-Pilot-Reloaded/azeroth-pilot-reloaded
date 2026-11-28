local terrain=LibStub("LibAPRNavigation-1.0")
if not terrain:MatchesGeneratedTerrain("retail","12.1.5.70961") then return end
local L=LibStub("LibAPRNavigation-1.0")
local D=assert(L._TerrainPackStages[1371])
D.packed.area[4]={"eNoLMvFzdHTUhwDtIGTeKBgFo2DkAMsgEz8AcUzACQ=="}
D.packed.class[4]={"eNpz1IcCZ0f9UTAKRsFIAxbOAEm8vRI="}
D.packed.floor[4]={"eNpzdHR2dHR0ckp3dHMEM5zSHd0dvRwdHQFeIgcC"}
D.packed.graph[4]={"eNpVx8EJACAQA8HaJhr7L0mQ+wizj7UQFskrdHR/VzijF7jZDwA="}
D.packed.grid[4]={"eNoLKXfUhwDLEBhrFIyCUTBygAUAJ8G9tQ=="}
D.packed.height[4]={"eNqLiIwCAAIXAQw="}
D.packed.area[2]={"eNpzdHTUHwWjYBSMVKAdZOIHAL3EvZQ="}
D.packed.floor[2]={"eNpzdHRxsXByckp3dHfMcNF2BLFcHN1dtKFi3o6OjgC0Hgm8"}
D.packed.graph[2]={"eNpzdHGxcHR0dHR20XZ0cnR0ctF2cnJ0dHYFcVyhyNUFpALOc0XjIal080DRBwBZ+xfn"}
D.packed.grid[2]={"eNpz1B8Fo2AUjBSgHRLsCGVahsBYFgA2Ar3O"}
D.packed.height[2]={"eNqLjIgEAAIXAQs="}
D.packed.area[3]={"eNpzdHTUhwDzIBM/ABbFAxg="}
D.packed.graph[3]={"eNpNykEKACAMA8Enefa4qSno/x8khYLCXJaEQBMINIBlBLsdVbnZ8G1Zlc0i3jMvxQ8WTw=="}
D.packed.grid[3]={"eNpz1IcA86DyEEf9UTAKRsFIA9oAFCW9pA=="}
D.packed.height[3]={"eNqLiCwHAAI0ASk="}
D.packed.area[1]={"eNpzdHTUHwWjYBSMVGAeZOLn6OhYHmTiVw4Ate3AJQ=="}
D.packed.floor[1]={"eNpzdHR2sdR3ckp3dHJ0ctGHspwdQcLark4u+truTgCqegkS"}
D.packed.graph[1]={"eNpzdHGx1HdydHR20bd0dHR0ctEH81wdnR0dXaHI1c3REYnngcJzRZNzQvDcAE9/F8g="}
D.packed.grid[1]={"eNpz1B8Fo2AUjDRgHhLsCGVahJQ7AgDwW75H"}
D.packed.height[1]={"eNqLSIwsBwADsAGK"}
L:RegisterTerrainData("retail",1371,D,20261123,true)
L._TerrainPackStages[1371]=nil
if not next(L._TerrainPackStages) then L._TerrainPackStages=nil end
