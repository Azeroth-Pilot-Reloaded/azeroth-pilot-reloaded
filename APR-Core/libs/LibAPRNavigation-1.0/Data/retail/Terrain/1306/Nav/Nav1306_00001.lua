local terrain=LibStub("LibAPRNavigation-1.0")
if not terrain:MatchesGeneratedTerrain("retail","12.1.5.70961") then return end
local L=LibStub("LibAPRNavigation-1.0")
local D=assert(L._TerrainPackStages[1306])
D.packed.area[4]={"eNpzdHQMMvZ0dHTUhwCLIGNPADIqBKQ="}
D.packed.floor[4]={"eNpzdHRxdHRyckp3dHXMd3R2BLFcnNwdncFiLs7ejo6OALgaCfE="}
D.packed.graph[4]={"eNpzdHEEAxdHRycwwxlEO7s6Ojs6ukKRqxNIDMZzc0GRcwVpgvNcQAbBeQBoQhgS"}
D.packed.grid[4]={"eNoLKXfUhwCLoBAYcxSMglEwcoAFAGzJvgY="}
D.packed.height[4]={"eNqLDC+PAAADswGA"}
D.packed.area[2]={"eNpzdHTUHwWjYBSMFKAdZOwJAP4Bup4="}
D.packed.class[2]={"eNpz1B8Fo2AUjDjgDABaL7sN"}
D.packed.graph[2]={"eNpdjMEJACAMAwdyAb+nqdX9F5JiHyochHAhSBVAKhFdpUUzGlhiRoeVuGJ4Of7lSI7zxN/P+bQNN2ci6g=="}
D.packed.grid[2]={"eNpz1B8Fo2AUjBSgHZroCGVaBIXAmQD2cL4u"}
D.packed.height[2]={"eNqLiIyIBAADeAFj"}
D.packed.floor[3]={"eNpzdHRydNF3ckp3dHZ0dnR0cnTSdnUCADvmBWU="}
D.packed.graph[3]={"eNpdyjEKACEQQ9EDbWG95c+Y8f43WkSRceEXeRCMXkDoATpqgOlNECImVukqmw5jNzSVOxv9n0cJRTpzPeN6Vn2Pjyvh"}
D.packed.grid[3]={"eNpz1IcA85CgEEco2wLOGgWjYBSMAAAAAQa+Iw=="}
D.packed.height[3]={"eNqLjKgAAAI2ASo="}
D.packed.area[1]={"eNpzdHTUHwWjYBSMNGAZZOzpCM/9IF45APk6v64="}
D.packed.class[1]={"eNpz1B8Fo2AUjFjgXA4A9em8/A=="}
D.packed.floor[1]={"eNpzdHRxsdR2ckp3dHR0crHUB7GcHQtc9MFizk7ujo4uro6Ozk4u+pYgQt/DCQBbAw0w"}
D.packed.graph[1]={"eNp1jEEKgDAMBB/kIeceJ93E+v8PSTFoBYW5LLMMqWaAq5mDZA3osu1a0ykBoohAcBR73GK6j2cWOVaXgf9WxnRLxZ/KuxmDvjxPA+g0zg=="}
D.packed.grid[1]={"eNpz1B8Fo2AUjDRgGeIIZZmHOIYAADC9vdI="}
D.packed.height[1]={"eNqLiIoAAAIXAQs="}
L:RegisterTerrainData("retail",1306,D,20261123,true)
L._TerrainPackStages[1306]=nil
if not next(L._TerrainPackStages) then L._TerrainPackStages=nil end
