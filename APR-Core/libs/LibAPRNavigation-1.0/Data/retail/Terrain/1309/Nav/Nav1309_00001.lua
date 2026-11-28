local terrain=LibStub("LibAPRNavigation-1.0")
if not terrain:MatchesGeneratedTerrain("retail","12.1.5.70961") then return end
local L=LibStub("LibAPRNavigation-1.0")
local D=assert(L._TerrainPackStages[1309])
D.packed.area[4]={"eNoLcs0BAAHvAQQ="}
D.packed.graph[4]={"eNpzdHIEA2cw7QZFri6OTkg8ALUaCZQ="}
D.packed.grid[4]={"eNoLcdQfBaNgFIxUYAkAzRu8oA=="}
D.packed.height[4]={"eNqLAgAAWwBb"}
D.packed.area[2]={"eNpzdHTUHwWjYBSMNKAd5JrjCM/9lkGuOQA8BL+T"}
D.packed.class[2]={"eNpz1B8Fo2AUjFSg7QwAOOW8gQ=="}
D.packed.floor[2]={"eNpzdHRy0XZ0ckp3dHcEAQAjLAQt"}
D.packed.graph[2]={"eNpzdHLRdnRydHT2cHR0dHSFIlcXkJgbFLkCALMjCYU="}
D.packed.grid[2]={"eNpz1B8Fo2AUjDSgHeIIZVkCAPdrvN0="}
D.packed.height[2]={"eNqLAAAAWQBZ"}
D.packed.area[3]={"eNpzdHTUhwCLINccRzhvFIyCUTCCQJBrDgAFo7+W"}
D.packed.class[3]={"eNpz1IcAC2dH/VEwCkbBiAPOAG2GvRI="}
D.packed.floor[3]={"eNpzdHRydNJ3ckp3dHX0dHR0BAAjZwQ1"}
D.packed.graph[3]={"eNpVy7ENADAIxMCBUjCDnzz7jxRFogDJzRUm0QESheAaQXUWDHmpvtxZ63u78hYm"}
D.packed.grid[3]={"eNpz1IcAi5ByR/1RMApGwUgD2gDPZr1T"}
D.packed.height[3]={"eNpLDAUAARkAtw=="}
D.packed.area[1]={"eNpzdHTUHwWjYBSMVKAd5JpTDgB8Tb46"}
D.packed.class[1]={"eNpz1B8Fo2AUjFSg7VwOAPXdvPg="}
D.packed.floor[1]={"eNpzdHR20dd2ckp3dHd0ddHXh7A8HR0dAVnPBr8="}
D.packed.graph[1]={"eNpzdHbR13ZydHR20dd3cnR0cXV0cnR0gyJXD0dHJJ4rCs8NheeBog8AtDkWFg=="}
D.packed.grid[1]={"eNpz1B8Fo2AUjFRgERQCAPX/vPE="}
D.packed.height[1]={"eNqLKAcAASkA0A=="}
L:RegisterTerrainData("retail",1309,D,20261123,true)
L._TerrainPackStages[1309]=nil
if not next(L._TerrainPackStages) then L._TerrainPackStages=nil end
