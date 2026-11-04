-- Dense collision cells must answer local proof queries within bounded work.
local fixture = dofile("tests/lua/navigation_fixture.lua")
local data = fixture:Load({connections={}})
data.env.requestTerrainData=function()return "ready" end
local lib=LibStub("LibAPRNavigation-1.0")
local function point(x,y,z)
    return {x=x,y=y,z=z or 0,instanceID=8,uiMapID=18,region="fixture"}
end
local raw={format=1,nodes={},edges={},anchors={}}
for x=0,99 do
    for y=0,49 do
        local id=#raw.nodes+1
        local node=point(x+.5,y+.5);node.id=id
        raw.nodes[id]=node
        raw.anchors[id]={node=id,minX=x,maxX=x+1,minY=y,maxY=y+1,minZ=-1,maxZ=1}
    end
end
local large=point(1400,1400);large.id="large"
raw.nodes[#raw.nodes+1]=large
raw.anchors[#raw.anchors+1]={node="large",minX=900,maxX=1900,minY=900,maxY=1900,minZ=-1,maxZ=1}
lib:RegisterTerrainData("retail",8,raw,1,"dense")
local start,goal=point(10.125,10.375),point(10.875,10.375)
local job=data:CreateTerrainEdgeBuild({start=start,goal=goal})
for _=1,30000 do
    local state=job:Step(11,100)
    assert(job.workLastStep<=11,"Index construction must remain incremental")
    if state~="planning" then break end
end
assert(job.status=="ready")
assert(data:CanTraverseTerrain(start,goal,"ground")==true,
    "A fractional one-yard movement in a dense room cannot exhaust the proof query")
assert(data:CanTraverseTerrain(point(5.125,5.375),point(26.125,26.375),"ground")==true,
    "A diagonal ground lookahead visits the line's cells rather than its enclosing rectangle")
assert(data:CanTraverseTerrain(point(1000.125,1000.375),point(1000.875,1000.625),"ground")==true,
    "Large proved volumes retain their coarser index level")
assert(data:CanTraverseTerrain(point(26.125,26.375),point(5.125,5.375),"ground")==true,
    "Reverse diagonal queries visit the same proved union")
assert(data:CanTraverseTerrain(point(10,10),point(12,12),"ground")==true
    and data:CanTraverseTerrain(point(12,12),point(10,10),"ground")==true,
    "Exact grid edges and corners remain traversable in both directions")
assert(data:CanTraverseTerrain(start,start,"ground")==true,"A stationary observation has a finite local query")
local clear,prefix=data:CanTraverseTerrain(point(99.5,10.375),point(101.5,10.375),"ground")
assert(clear==nil and prefix and prefix.x<100 and prefix.x>99.99,
    "A local proof must stop at the physical coverage boundary")
local references,preparedAnchors=0,0
for _,anchors in pairs(data._terrainGeometryCache.anchors) do preparedAnchors=preparedAnchors+#anchors end
for _,buckets in pairs(data._terrainVisibility.worlds[8]) do
    for _,bucket in pairs(buckets) do references=references+#bucket end
end
assert(references<=preparedAnchors*4,
    "A smaller local bucket cannot replicate each anchor beyond its four intersected buckets")
local source,target=point(10.25,10.25),point(12.75,10.25)
local guidance=data:CreateGuidance({totalSeconds=1,segments={{kind="walk",terrain=true,
    from=source,to=target,polyline={source,target},seconds=1,movementMode="ground"}}},
    {arrivalRange=.05,canTraverse=function(a,b,mode)return data:CanTraverseTerrain(a,b,mode) end})
local arrow,state=guidance:Update(point(10.625,10.375))
assert(state=="guiding" and arrow,
    "A slight observed offset inside a proved dense cell must retain usable guidance")
print("Dense terrain visibility: local and diagonal proof, bounded indexing, coarse volumes and offset guidance passed")
