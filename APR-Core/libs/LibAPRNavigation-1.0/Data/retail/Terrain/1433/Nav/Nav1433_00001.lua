local terrain=LibStub("LibAPRNavigation-1.0")
if not terrain:MatchesGeneratedTerrain("retail","12.1.5.70961") then return end
local L=LibStub("LibAPRNavigation-1.0")
local D=assert(L._TerrainPackStages[1433])
D.packed.area[4]={"eNoLci1zdHTUHwWjYBSMVGAZ5FoGAPrJvug="}
D.packed.class[4]={"eNpzcdQfBaNgFIxUYOkCAEnevNQ="}
D.packed.floor[4]={"eNpzdHRydHR0ckp3dHcEAQAkDQRA"}
D.packed.graph[4]={"eNpzdHYEAycwdnIG0Y7eUOTqBBJ3hSJXFxAPLgcAuvYPHQ=="}
D.packed.grid[4]={"eNoLcdQfBaNgFIxUYAkAzRu8oA=="}
D.packed.height[4]={"eNqLBAAAWgBa"}
D.packed.area[2]={"eNpzdHTUHwWjYBSMNKAd5FrmCM/9lkGuZQA8pL+n"}
D.packed.class[2]={"eNpz1B8Fo2AUjDSg7QIAWii7Cg=="}
D.packed.floor[2]={"eNpzdHRy0XZ0ckp39HAEAQAjMgQu"}
D.packed.graph[2]={"eNpzdHbRdnR0dHRy0XZ0cnRy9gBxvKHI1cPRCYnnAuK5QZErALYJDwY="}
D.packed.grid[2]={"eNpz1B8Fo2AUjDSgHeIIZVkCAPdrvN0="}
D.packed.height[2]={"eNqLBAAAWgBa"}
D.packed.area[3]={"eNpzdHTUhwCLINeyckc4dxSMglEwcoB2kGsZAAyMwB0="}
D.packed.class[3]={"eNpz1IcAC2cXR/1RMApGwUgD2i4AfkC9Uw=="}
D.packed.floor[3]={"eNpzdHRydNJ3ckp3dHf0dHR0BAAjcwQ3"}
D.packed.graph[3]={"eNpNysEJACAQA8GCfFjD5kw+9t+PCCcI81kSCg1QoSm0jGC3CMDNvpWW/E/r1tt8AMFzFkk="}
D.packed.grid[3]={"eNpz1IcAi5ByR/1RMApGwUgD2gDPZr1T"}
D.packed.height[3]={"eNqLjAAAAQwAsg=="}
D.packed.area[1]={"eNpzdHTUHwWjYBSMVGAR5FpWAQB8o75S"}
D.packed.class[1]={"eNpz1B8Fo2AUjFRg6eIMAPXVvNM="}
D.packed.floor[1]={"eNpzdHRy0dd3ckp39HAEAQAinAQg"}
D.packed.graph[1]={"eNotx8EJADAIBMGC8rCGPT0R0n8/ISDMZ8iKA1JFCOUA9HIj8PL83eUHrNoO1w=="}
D.packed.grid[1]={"eNpz1B8Fo2AUjFRgEVIOAPYmvRY="}
D.packed.height[1]={"eNqLjAAAAQwAsg=="}
L:RegisterTerrainData("retail",1433,D,20261123,true)
L._TerrainPackStages[1433]=nil
if not next(L._TerrainPackStages) then L._TerrainPackStages=nil end
