local terrain=LibStub("LibAPRNavigation-1.0")
if not terrain:MatchesGeneratedTerrain("retail","12.1.5.70961") then return end
local L=LibStub("LibAPRNavigation-1.0")
local D=assert(L._TerrainPackStages[1261])
D.packed.class[4]={"eNpzBgAARABE"}
D.packed.graph[4]={"eNpzdHYEAxdHRydHR0dnVxDlCkWuTig8FxDPDYpcXUHa4DwnR2ckHgDGwxZK"}
D.packed.grid[4]={"eNoLCnHUHwWjYBSMVGABABYvvPE="}
D.packed.height[4]={"eNqLjAAAAQwAsg=="}
D.packed.class[2]={"eNpz1B8Fo2AUjDjgDABaL7sN"}
D.packed.floor[2]={"eNpzdHRy0XZ0ckp3dHJ0dnR0drFwcnNy0XZycQIAWoYGqQ=="}
D.packed.graph[2]={"eNpVjcEJACAMAwdyAb/RxOr+C0mkDwsH5UhKQHYAIBvGO8MmixIJEzhJ0P0v+23bViL6rzYjibKwdtm7PGQmkQ=="}
D.packed.grid[2]={"eNpz1B8Fo2AUjBSgHRbsCGVahsBYFgA2LL3Q"}
D.packed.height[2]={"eNqLjIgEAAIXAQs="}
D.packed.class[3]={"eNpz1IcAS2cACv8CBw=="}
D.packed.graph[3]={"eNpVidEFAEAMxQbqx82QV6/7j1SljhIiQqIAEr2REdRinTKAF9fUfw2dIRKC"}
D.packed.grid[3]={"eNpz1IcA86DyEEf9UTAKRsFIA9oAFCW9pA=="}
D.packed.height[3]={"eNqLjCgHAAI1ASk="}
D.packed.area[1]={"eNpzdHTUHwWjYBSMNGAZGOzoCM/9IB4AOzi/ZQ=="}
D.packed.class[1]={"eNpz1B8Fo2AUjFRg4QwAOP+8jg=="}
D.packed.graph[1]={"eNplykEKwCAMRNEDuXDt8msm2vtfqKihSIUP4ZHBrGTALKd9lkSFJ+qigSI5HNJUj37LcS8PVfBIPvX9XiM7Jl4="}
D.packed.grid[1]={"eNpz1B8Fo2AUjDRgHhia6AhjhwSFAACwhL6U"}
D.packed.height[1]={"eNqLjAiPDC8HAAdgAjA="}
L:RegisterTerrainData("retail",1261,D,20261123,true)
L._TerrainPackStages[1261]=nil
if not next(L._TerrainPackStages) then L._TerrainPackStages=nil end
