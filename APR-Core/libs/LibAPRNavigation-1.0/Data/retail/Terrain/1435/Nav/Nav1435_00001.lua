local terrain=LibStub("LibAPRNavigation-1.0")
if not terrain:MatchesGeneratedTerrain("retail","12.1.5.70961") then return end
local L=LibStub("LibAPRNavigation-1.0")
local D=assert(L._TerrainPackStages[1435])
D.packed.area[4]={"eNoLcs0DAAHxAQY="}
D.packed.graph[4]={"eNpzdHIEA2cw7QZFri6OTkg8ALUaCZQ="}
D.packed.grid[4]={"eNoLcdQfBaNgFIxUYAkAzRu8oA=="}
D.packed.height[4]={"eNqLAgAAWwBb"}
D.packed.area[2]={"eNpzdHTUHwWjYBSMNKAd5JrnCM/9lkGueQA8JL+X"}
D.packed.class[2]={"eNpz1B8Fo2AUjFSg7QwAOOW8gQ=="}
D.packed.floor[2]={"eNpzdHRy0XZ0ckp3dHcEAQAjLAQt"}
D.packed.graph[2]={"eNpzdHLRdnRydHT2cHR0dHSFIlcXkJgbFLkCALMjCYU="}
D.packed.grid[2]={"eNpz1B8Fo2AUjDSgHeIIZVkCAPdrvN0="}
D.packed.height[2]={"eNqLAAAAWQBZ"}
D.packed.area[3]={"eNpzdHTUhwCLINe8cgAazAPB"}
D.packed.class[3]={"eNpz1IcAC+dyAA16An0="}
D.packed.graph[3]={"eNpVy7ENADAIxMCBUjCDnzz7jxRFogDJzRUm0QESBXCNoDoLhrxUX+6s9T27qBYl"}
D.packed.grid[3]={"eNpz1IcAi6AQR/1RMApGwUgD2gA8Qr0u"}
D.packed.height[3]={"eNpLDAcAARsAuQ=="}
D.packed.area[1]={"eNpzdHTUHwWjYBSMVGAR5JpXAQB8k75K"}
D.packed.class[1]={"eNpz1B8Fo2AUjFRg6VwOAPYHvQY="}
D.packed.floor[1]={"eNpzdHRy0dd2ckp3dHd0dXR0BAAiegQf"}
D.packed.graph[1]={"eNpzdHbR13ZydHR20dd3dHR0cXV0cnR0gyJXD0dHJJ4rCs8NheeBog8As+8WFQ=="}
D.packed.grid[1]={"eNpz1B8Fo2AUjFRgEVIOAPYmvRY="}
D.packed.height[1]={"eNqLSAQAARMAug=="}
L:RegisterTerrainData("retail",1435,D,20261123,true)
L._TerrainPackStages[1435]=nil
if not next(L._TerrainPackStages) then L._TerrainPackStages=nil end
