local terrain=LibStub("LibAPRNavigation-1.0")
if not terrain:MatchesGeneratedTerrain("retail","12.1.5.70961") then return end
local L=LibStub("LibAPRNavigation-1.0")
local D=assert(L._TerrainPackStages[1394])
D.packed.area[4]={"eNoLKEt1dHTUHwWjYBSMVGAZUJYKAHQivyQ="}
D.packed.floor[4]={"eNpzdHRydHR0ckp39HAEAQAkEwRB"}
D.packed.graph[4]={"eNpzdHJ0dHRydHR2cnRxdHSFIlcXR2ckHgC1RgmT"}
D.packed.grid[4]={"eNoLcdQfBaNgFIxUYAkAzRu8oA=="}
D.packed.height[4]={"eNqLBAAAWgBa"}
D.packed.area[2]={"eNpzdHTUHwWjYBQMN6AdUJbqCM/dlgFlqeUIrgUqVx+7MIhbAQB35sel"}
D.packed.floor[2]={"eNpzdHRxsXB0ckp3dHaKcLFwArFcnH1ctMFiHk7Ojo6OALOnCbY="}
D.packed.graph[2]={"eNp1jUEKgDAQAx/Uqwev003Q/v9DEizSHoSwMMyGYB0ApZMOUnuphcq5Y2YoyjN26HOmFqf0ls++Of25694WHkv2KFU="}
D.packed.grid[2]={"eNpz1B8Fo2AUDDegHewIZVmGJsKYFkEhjmjqLELK4bIAzMW/4Q=="}
D.packed.height[2]={"eNqLjDAAAAHuAOI="}
D.packed.area[3]={"eNpzdHTUhwCLgLLUckc4dxSMglEwcoB2QFkqAIUEwFk="}
D.packed.floor[3]={"eNpzdHRydNJ3ckp3dHcEAQAjUwQv"}
D.packed.graph[3]={"eNpVybEJACAQxdCBLJzhfT33H8nG4oRACLFlIDKfwopFPSp2q8P3qtUFHr4UMg=="}
D.packed.grid[3]={"eNpz1IcAi5ByR/1RMApGwUgD2gDPZr1T"}
D.packed.height[3]={"eNqLCgcAAQ0Asg=="}
D.packed.area[1]={"eNpzdHTUHwWjYBQMV2AZUJbqCM/lFgFlqeU4ueYoarUDylINAZbuxuY="}
D.packed.floor[1]={"eNpzdHRzsdR2ckp3dHZKc7HUB7OcfVz0LUEsF0dXF32wrJujt4s+WNbD2dnR0REAproOzw=="}
D.packed.graph[1]={"eNpdTTkOgDAMexBDJgZGp05pAQn+/xoUFKGmkhffqFwFQOEmCpCyKGAUF0lxsRgU6IFeAcACZs5+z8DBq97LyTvwpM3j652Bq00PmjbLwNr0MLC9peQLShw8UA=="}
D.packed.grid[1]={"eNpz1B8Fo2AUDFdgmegIZVmEIphRITCmOZylHVIOAIdwwEo="}
D.packed.height[1]={"eNqLjDAEAAHvAOM="}
L:RegisterTerrainData("retail",1394,D,20261123,true)
L._TerrainPackStages[1394]=nil
if not next(L._TerrainPackStages) then L._TerrainPackStages=nil end
