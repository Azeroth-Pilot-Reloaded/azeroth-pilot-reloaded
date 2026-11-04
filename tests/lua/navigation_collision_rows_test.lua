-- Clear collision ranges distinguish water from local inheritance.
local fixture=dofile("tests/lua/navigation_fixture.lua")
local instance=fixture:Load({})
local lib=LibStub("LibAPRNavigation-1.0")
local sequence=0
local function range(first,last,state) return {from=first,to=last,state=state} end
local function point(x,y) return {instanceID=8,x=x,y=y} end
local function near(actual,expected) assert(actual and math.abs(actual-expected)<0.000001,tostring(actual).." ~= "..expected) end
local function setup(baseRows,localRows,width)
    sequence=sequence+1
    local profile="plain-fixture-"..sequence
    width=width or 5
    lib:RegisterRoadCollision(profile,{id="plain-ground",originX=0,originY=0,
        cellSize=1,width=width,height=#baseRows,rows=baseRows},1)
    local overlays={}
    if localRows then
        lib:RegisterRoadCollision(profile,{id="plain-interior",originX=0,originY=0,
            cellSize=1,width=width,height=#localRows,rows=localRows},1)
        overlays[1]="plain-interior"
    end
    lib:RegisterRoadNetwork(profile,{id="plain-world",instanceID=8,kind="world",
        collision={base="plain-ground",overlays=overlays},sections={}},1)
    return lib:New({profile=profile,environment={}}),profile
end
local function horizontal(owner,column)
    return owner:RoadSegmentCost(point(-0.5,-column+0.8),point(-0.5,-column+0.2))
end

local base={{range(1,1,"water"),range(2,5,"open")}}
local localRows={{range(1,1,"open"),range(2,2,"inherit"),range(3,3,"water"),
    range(4,4,"blocked"),range(5,5,"unknown-floor")}}
local owner,profile=setup(base,localRows)
near(horizontal(owner,1),0.6) -- local open overrides base water
near(horizontal(owner,2),0.6) -- inheritance reads base open
near(horizontal(owner,3),0.9) -- local water is water, never inheritance
local cost,reason=horizontal(owner,4)
assert(cost==nil and reason=="road_blocked")
cost,reason=horizontal(owner,5)
assert(cost==nil and reason=="road_floor_unknown")
owner=setup({{range(1,1,"water"),range(2,2,"blocked"),range(3,5,"open")}},localRows)
cost,reason=horizontal(owner,2)
assert(cost==nil and reason=="road_blocked","Local inheritance must retain a blocked base cell")

-- Inclusive boundaries, one-cell intervals and water weighting remain exact.
owner=setup({{range(1,2,"open"),range(3,3,"water"),range(4,5,"open")}})
near(owner:RoadSegmentCost(point(-0.5,-0.5),point(-0.5,-4.5)),4.5)
local record=lib.Roads.Record(owner)
local grids,grid=lib.Roads.Grids(record,"plain-world")
assert(lib.Roads.Cell(record,grid,1,2,"plain-world")==0)
assert(lib.Roads.Cell(record,grid,1,3,"plain-world")==1)
assert(lib.Roads.Cell(record,grid,1,4,"plain-world")==0)
assert(lib.Roads.Cell(record,grid,1,0,"plain-world")==nil)
assert(lib.Roads.Cell(record,grid,1,6,"plain-world")==nil)

-- Unknown floors stay unknown in the base mask too. Inheritance requires a
-- lower mask and is invalid when bound as the authoritative base.
owner=setup({{range(1,5,"unknown-floor")}})
cost,reason=horizontal(owner,2)
assert(cost==nil and reason=="road_floor_unknown")
owner=setup({{range(1,2,"open"),range(3,5,"inherit")}})
cost,reason=horizontal(owner,1)
assert(cost==nil and reason=="road_terrain_missing")

-- Reject malformed rows lazily, before any cell can prove a route.
local invalid={
    {range(1,2,"open"),range(4,5,"blocked")}, -- gap
    {range(1,3,"open"),range(3,5,"blocked")}, -- overlap
    {range(1,6,"open")}, -- extends past declared width
    {range(1,4,"open")}, -- incomplete row
    {range(1,5,"unrecognised")},
    {{from=1,to=5,state="open",encoded="ignored"}},
    {range(1,2.5,"open"),range(3.5,5,"blocked")},
}
for _,row in ipairs(invalid) do
    owner=setup({row})
    cost,reason=horizontal(owner,1)
    assert(cost==nil and reason=="road_terrain_missing")
end

-- Registration refuses encoded strings and removed metadata atomically.
local revision=owner:GetRoadRevision()
local malformed={id="invalid-mask",originX=0,originY=0,cellSize=1,width=5,height=1,rows="4"}
assert(not pcall(lib.RegisterRoadCollision,lib,profile,malformed,1))
malformed.rows={{range(1,5,"open")}}
for _,field in ipairs({"rowsEncoding","shortRun","longRun","role"}) do
    malformed[field]="removed"
    assert(not pcall(lib.RegisterRoadCollision,lib,profile,malformed,1))
    malformed[field]=nil
end
malformed.height=2
assert(not pcall(lib.RegisterRoadCollision,lib,profile,malformed,1))
malformed.height=1;malformed.width=0
assert(not pcall(lib.RegisterRoadCollision,lib,profile,malformed,1))
assert(owner:GetRoadRevision()==revision)

-- Author mutation and source replacement cannot alter cached old rows.
local authored={{range(1,5,"open")}}
owner,profile=setup(authored)
near(horizontal(owner,2),0.6)
authored[1][1].state="blocked"
near(horizontal(owner,2),0.6)
lib:RegisterRoadCollision(profile,{id="plain-ground",originX=0,originY=0,
    cellSize=1,width=5,height=1,rows=authored},2)
cost,reason=horizontal(owner,2)
assert(cost==nil and reason=="road_blocked")

-- A long row validates in resumable work, once; cache hits do no row work.
local many={}
for column=1,200 do many[column]=range(column,column,"open") end
owner=setup({many},nil,200)
record=lib.Roads.Record(owner)
grids,grid=lib.Roads.Grids(record,"plain-world")
local work=0
local coroutineJob=coroutine.create(function()
    return lib.Roads.Cell(record,grid,1,100,"plain-world",function()
        work=work+1;coroutine.yield()
    end)
end)
local pauses=0
while coroutine.status(coroutineJob)~="dead" do
    local ok,result=coroutine.resume(coroutineJob)
    assert(ok)
    if coroutine.status(coroutineJob)=="dead" then assert(result==0) else pauses=pauses+1 end
end
assert(work==200 and pauses==200)
assert(lib.Roads.Cell(record,grid,1,100,"plain-world",function() error("Validated row must be cached") end)==0)
print("Plain collision rows: named states, inheritance, boundaries, invalid ranges, immutable revisions and resumable caching passed")
