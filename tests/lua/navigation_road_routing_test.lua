-- Source topology uses invented worlds, doors and floors, never live journeys.
local fixture=dofile("tests/lua/navigation_fixture.lua")
fixture.profile="forever"
fixture:Load({})
local lib=LibStub("LibAPRNavigation-1.0")
local revision=0
local function setup(data)
    revision=revision+1
    data.format=1
    lib:RegisterRoadData("synthetic-roads",data,revision)
    return lib:New({profile="synthetic-roads",environment={}})
end
local function point(x,y,z) return {instanceID=8,x=x,y=y,z=z} end
local function finish(instance,from,to,options)
    options=options or {};options.start,options.goal,options.walkSpeed=from,to,1
    local job=instance:CreateRoadRoute(options)
    for _=1,20000 do
        local status,result,reason=job:Step(3,1)
        assert(job.workLastStep<=3)
        if status~="planning" then return status,result,reason end
    end
    error("road routing failed to terminate")
end
local function near(first,last) assert(math.abs(first-last)<0.00001,tostring(first).." ~= "..tostring(last)) end
local function edge(a,b,x1,y1,x2,y2) return {a,b,0,0,x1,y1,x2,y2} end

-- A declared mouth joins halfway along a road; its shape is retained both ways.
local instance=setup({roads={[8]={n={0,0,20,0},e={edge(1,2,0,0,20,0)}}},
    overlays={[8]={{n={10,0,10,10},e={edge(1,2,10,0,10,10)},joins={1},indoor=true,nz={false,false}}}}})
local status,result=finish(instance,point(0,0),point(10,10),{roadAttachmentRadius=0})
assert(status=="ready");near(result.totalSeconds,20)
assert(result.polyline[2].x==10 and result.polyline[2].y==0,"the source doorway cannot become a diagonal chord")
assert(result.polyline[2].z==nil,"false source heights remain unknown")
status,result=finish(instance,point(10,10),point(20,0),{roadAttachmentRadius=0})
assert(status=="ready");near(result.totalSeconds,20)

-- Equal XY does not authorize a zero-cost connection to another floor.
instance=setup({roads={[8]={n={-10,0,0,0},z={0,0},e={edge(1,2,-10,0,0,0)}}},
    overlays={[8]={{n={0,0,0,10},nz={20,20},e={edge(1,2,0,0,0,10)},joins={1},indoor=true}}}})
status=finish(instance,point(-10,0,0),point(0,10,20),{roadAttachmentRadius=0})
assert(status~="ready","an unrelated high floor must remain disconnected")

-- Unknown native height cannot choose between overlapping known floors.
instance=setup({roads={[8]={n={0,0,10,0,0,0,10,0},nz={10,10,30,30},
    e={edge(1,2,0,0,10,0),edge(3,4,0,0,10,0)}}}})
status=finish(instance,point(0,0),point(10,0),{roadAttachmentRadius=0})
assert(status=="waiting_data")
status,result=finish(instance,point(0,0,10),point(10,0,10),{roadAttachmentRadius=0})
assert(status=="ready");near(result.totalSeconds,10)
assert(instance:RoadSegmentCost(point(0,0,100),point(10,0,100))==nil,"source proof must match the observed floor")

-- A drop is directed and requires an explicit surviving-height allowance.
instance=setup({roads={[8]={n={0,0,10,0},z={5,0},e={edge(1,2,0,0,10,0)}}},drops={[8]={[1]=5}}})
status=finish(instance,point(0,0,5),point(10,0,0),{roadAttachmentRadius=0})
assert(status~="ready")
status,result=finish(instance,point(0,0,5),point(10,0,0),{roadAttachmentRadius=0,maxDrop=5})
assert(status=="ready");near(result.totalSeconds,math.sqrt(125))
status=finish(instance,point(10,0,0),point(0,0,5),{roadAttachmentRadius=0,maxDrop=5})
assert(status~="ready","a fall never becomes a ladder")

-- A lift has the declared travel cost even at equal horizontal coordinates.
instance=setup({roads={[8]={n={0,0,0,0},z={5,25},e={{1,2,70,5,0,0,0,0}}}}})
status,result=finish(instance,point(0,0,5),point(0,0,25),{roadAttachmentRadius=0})
assert(status=="ready");near(result.totalSeconds,70)
near(instance:RoadSegmentCost(point(0,0,5),point(0,0,25)),70)

-- Recorded floor paths supply all intermediate points and explicit heights.
instance=setup({roads={[8]={n={0,0,10,0,10,10,20,10},
    e={edge(1,2,0,0,10,0),edge(3,4,10,10,20,10)}}},
    roadTracks={[12345]=true},floorTracks={[8]={{time=12345,op="add",stair=true,
        pts={10,0,10,5,10,10},zs={false,5,5}}}}})
status,result=finish(instance,point(0,0),point(20,10),{roadAttachmentRadius=0})
assert(status=="ready");near(result.totalSeconds,30)
local found=false
for _,p in ipairs(result.polyline) do if p.x==10 and p.y==5 and p.z==5 then found=true end end
assert(found,"an already-shipped track identity must not discard its separate floor geometry")

-- Source wall erasers open raster cells, including building masks, while an
-- explicit wall continues to reject the same segment.
local grid={tx0=32,ty0=32,cell=1,w=12,h=12,rows={}}
for i=1,12 do grid.rows[i]="r" end -- one run: twelve blocked cells
local opened={roads={[8]={n={-3,-3,-8,-3},e={edge(1,2,-3,-3,-8,-3)}}},terrain={[8]=grid},
    buildings={[8]={4,3,6}},wallOpens={[8]={{pts={-2,-2,-9,-2,-9,-4,-2,-4},area=true}}}}
instance=setup(opened)
near(instance:RoadSegmentCost(point(-3.2,-3.2),point(-7.8,-3.2)),4.6)
opened.walls={[8]={{-5,-2,-5,-4}}}
instance=setup(opened)
assert(instance:RoadSegmentCost(point(-3.2,-3.2),point(-7.8,-3.2))==nil,"opening ground must never erase an explicit wall")
print("Road routing: explicit joins, unknown heights, distinct floors, directed drops and lift costs passed")
