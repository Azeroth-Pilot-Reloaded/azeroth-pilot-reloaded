local terrain=LibStub("LibAPRNavigation-1.0")
if not terrain:MatchesGeneratedTerrain("retail","12.1.5.70961") then return end
local L=LibStub("LibAPRNavigation-1.0")
local D=assert(L._TerrainPackStages[1300])
D.packed.graph[4]={"eNpzdAQAAMUAgw=="}
D.packed.grid[4]={"eNpz1B8Fo2AUjFSgDQB8Vbw+"}
D.packed.height[4]={}
D.packed.area[2]={"eNpzdHTUHwWjYBQMOxBUZuAIz90WKDwYsAwqMyhHCGujKDKH8OBkOQAIackj"}
D.packed.class[2]={"eNpz1B8Fo2AUjBSg7VLuiCZk6ewIgi4A7ka/FA=="}
D.packed.floor[2]={"eNoti7sJwDAQQwdKZ4xxK538wRjSZYXsv0E4Xxrx9ISApQTyBdGU6CQ8ShZuKTNoKv9uq5zHRFeJB2+Vsxq2LgY1YCiDVEXzGFSlVzpZ5wdliSGC"}
D.packed.graph[2]={"eNpzdHExcnRydHRxMXN0hFBOjo7OriAyGIqCXB2dHR0NoSjLBaTQFYpcXUE8TyjyAqssgaJEF5ApSCqdECq9UeQ8AGpUI80="}
D.packed.grid[2]={"eNpz1B8Fo2AUDDsQ4ghlWATDWJZwMcug8hBMUXMAjF3AIg=="}
D.packed.height[2]={"eNqLiIxIDC8PAwAKCgKP"}
D.packed.graph[3]={"eNpzdAQAAMUAgw=="}
D.packed.grid[3]={"eNpz1B8Fo2AUjFSgDQB8Vbw+"}
D.packed.height[3]={}
D.packed.area[1]={"eNpzdHTUHwWjYBQMV2AeVGZQ4QjP5maoXBiwDCozQIhqQxVBBIPKDMoB6ATIVw=="}
D.packed.class[1]={"eNpz1B8Fo2AUjDRg4eIIZWk7Ozo7VjgDAGo4vo8="}
D.packed.floor[1]={"eNolybENgDAQQ9GBUkRUh0v7DJyAPdh/A5Sk+XrSJ8uxSx+lcrSh4uboQ8nbWJdpYMj5GvNWPu5Y9yDtwCmjzVz6AUu/F7M="}
D.packed.graph[1]={"eNpzdHYx1nd0dHRyMdd3cnR0cnN0dHR0hSJXN0cnJB4A9soLJw=="}
D.packed.grid[1]={"eNpz1B8Fo2AUDFdgHlge4ghlmwUFw9kWIREwpmVIOVw0KAQAm9nBow=="}
D.packed.height[1]={"eNqLMIiMiAorjwAAC5YCuQ=="}
L:RegisterTerrainData("retail",1300,D,20261123,true)
L._TerrainPackStages[1300]=nil
if not next(L._TerrainPackStages) then L._TerrainPackStages=nil end
