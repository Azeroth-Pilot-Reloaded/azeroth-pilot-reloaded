local terrain=LibStub("LibAPRNavigation-1.0")
if not terrain:MatchesGeneratedTerrain("retail","12.1.5.70961") then return end
local L=LibStub("LibAPRNavigation-1.0")
local D=assert(L._TerrainPackStages[1254])
D.packed.area[4]={"eNoLMi4AAAHPAPY="}
D.packed.class[4]={"eNpzBgAARABE"}
D.packed.graph[4]={"eNpzdHIEAycnR2dHR1cocgUARsIF7Q=="}
D.packed.grid[4]={"eNoLcdQfBaNgFIxUYAkAzRu8oA=="}
D.packed.height[4]={"eNqLBAAAWgBa"}
D.packed.area[2]={"eNpzdHTUHwWjYBQMN6AdZFzgCM/dlkHGBeUIrgUqVx9JGFVPJQCGKcYi"}
D.packed.class[2]={"eNpz1B8Fo2AUDDeg7QwAVL61KQ=="}
D.packed.floor[2]={"eNpzdHR1sXB0ckp3dHLycLFwArGcnX1ctMFirk7uLtpgMSdHZ0dHRwAhGgxJ"}
D.packed.graph[2]={"eNpVjEEKACEMAx/kdQ9esyZF//+hJWuRCqEwTFKIDwAMdrwA2Ta1n+S7MotWykim44RRHL0rzUrTu8jcLi4XrD/jA517LAE="}
D.packed.grid[2]={"eNpz1B8Fo2AUDDegHewIZVmGJsKYFkEhjmjqLOAilgAKeL9r"}
D.packed.height[2]={"eNqLKI+MiAwHAAfeAjE="}
D.packed.area[3]={"eNpzdHTUhwDLIOMCABbtAzs="}
D.packed.graph[3]={"eNpzdHJ00nd0dHRycnR2dHSFIlcARYAF3A=="}
D.packed.grid[3]={"eNpz1IcAyxBH/VEwCkbBSAPaAPf2vN0="}
D.packed.height[3]={"eNqLAgAAWwBb"}
D.packed.area[1]={"eNpzdHTUHwWjYBQMd2ARZFzgiJHbUUW1g4wLTACP4cFr"}
D.packed.class[1]={"eNpz1B8Fo2AUjFSg7QwAOOW8gQ=="}
D.packed.floor[1]={"eNotyTEKgDAQRNEDWSwiYUk5s6Nol1Oorbl/IdHtPu8DhxYjLxC3yjRq5ayS1uV1VHCTf5c85f+NrprWVNMeIGRGymznC97BGZs="}
D.packed.graph[1]={"eNpVjEkKwDAMA5/kUw49TmyZhPz/P8VgSgoDQmghYtgEj6ckwgxwMWE3OwHUSOW+TDic5mTtrublcv1eXl6lH0I="}
D.packed.grid[1]={"eNpz1B8Fo2AUDHdgEeKILhIBE9EOCgEA9Pm+JA=="}
D.packed.height[1]={"eNqLjAiPBAADdwFi"}
L:RegisterTerrainData("retail",1254,D,20261123,true)
L._TerrainPackStages[1254]=nil
if not next(L._TerrainPackStages) then L._TerrainPackStages=nil end
