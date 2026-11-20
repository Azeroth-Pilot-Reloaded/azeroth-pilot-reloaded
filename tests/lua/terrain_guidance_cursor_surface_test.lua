-- Real provider with an invented collision map; synchronous guidance never decodes.
local F=dofile("tests/lua/terrain_runtime_fixture.lua")
local lib=F.load()
local provider=F.provider(lib)
local a,b=F.point(1,1,0),F.point(6,1,0)
assert(type(provider.GetGuidanceHeight)=="function","The provider must expose a conservative cached guidance height")
assert(provider:GetGuidanceHeight(a)==nil,"Cold guidance reads do not decode a cluster")
assert(provider:CanFollowWalkingSegment(a,b)==nil,"A cold line proof is unavailable")
assert(F.finish(provider:CreatePathJob(a,b,{walkSpeed=7}))=="ready")
assert(provider:GetGuidanceHeight(F.point(1,1))==0,"One walkable surface supplies the missing height, including zero")
assert(provider:CanFollowWalkingSegment(a,b)==true,"Warm connected ground proves a traversable corridor")
assert(provider:CanFollowWalkingSegment(F.point(1,1,30),b)==false,"The wrong native height cannot choose the ground")
assert(provider:CanFollowWalkingSegment(F.point(1,1),b)==nil,"Line proofs require resolved height")
assert(provider:GetGuidanceHeight(F.point(20,1))==nil,"Off-map observations remain unresolved")
local other=F.point(6,1,0)
other.instanceID=901
assert(provider:CanFollowWalkingSegment(a,other)==nil,"Different worlds cannot share a line proof")

F.provider(lib,F.map({wall=true}),2)
assert(provider:GetGuidanceHeight(a)==nil,"A terrain replacement retires cached guidance evidence")
assert(F.finish(provider:CreatePathJob(a,b,{walkSpeed=7}))=="ready")
assert(provider:CanFollowWalkingSegment(a,b)==false,"A valid detour does not prove a chord through its wall")
assert(provider:GetGuidanceHeight(F.point(3,1))==nil,"A blocked cell has no standing surface")

local floors=F.map()
local cell=6*8+1
floors.floor[1]=F.number(1,3)..F.number(cell,3)..F.number(1,1)
    ..F.number(1,1)..F.number(2068,2).."AA".."AAA"
F.provider(lib,floors,3)
assert(F.finish(provider:CreatePathJob(a,b,{walkSpeed=7}))=="ready")
assert(provider:GetGuidanceHeight(F.point(6,1))==nil,"Overlapping disconnected floors remain ambiguous")
assert(provider:CanFollowWalkingSegment(a,F.point(6,1,20))==false,"A line cannot jump to an overlapping upper floor")

for index,class in ipairs({"E","F"}) do
    F.provider(lib,F.map({class=class}),3+index)
    assert(F.finish(provider:CreatePathJob(a,b,{walkSpeed=7}))=="ready")
    assert(provider:CanFollowWalkingSegment(a,b)==true,"Following a connected published path remains possible indoors")
end
local wet=F.map()
wet.grid[1]=string.rep("g",64)
F.provider(lib,wet,6)
assert(F.finish(provider:CreatePathJob(a,b,{walkSpeed=7}))=="ready")
assert(provider:CanFollowWalkingSegment(a,b)==true,"Following a published swimming path must not stall at a wet cell")

-- Cold packed input has tripwire decoders, proving the guidance read stays cheap.
local data=F.map()
data.packed={grid={{"cold"}},height={{"cold"}},graph={{"cold"}}}
data.grid,data.height,data.graph=nil,nil,nil
F.provider(lib,data,7)
C_EncodingUtil={DecodeBase64=function() error("guidance decoded a cold cluster") end,
    DecompressString=function() error("guidance decompressed a cold cluster") end}
Enum={CompressionMethod={Zlib=1}}
for _=1,100 do
    assert(provider:GetGuidanceHeight(a)==nil and provider:CanFollowWalkingSegment(a,b)==nil)
end
print("Terrain guidance surfaces: unique cached height, cold reads, walls, overlapping floors and replacement passed")
