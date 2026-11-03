-- Unreviewed points remain metadata; they must not become executable travel.
local fixture = dofile("tests/lua/navigation_fixture.lua")
fixture.profile = "forever"
local outside = {space="world",instanceID=0,uiMapID=501,x=0,y=0,region="open"}
local inside = {space="world",instanceID=0,uiMapID=501,x=10,y=0,region="open"}
local data = fixture:Load({connections={
    {id="invented-candidate",kind="portal",reviewStatus="candidate",from=outside,to=inside,seconds=1},
    {id="invented-confirmed",kind="portal",reviewStatus="confirmed",from=outside,to=inside,seconds=10},
},entrances={
    {id="invented-candidate-entry",kind="dungeon",reviewStatus="candidate",instanceID=4,
        exterior=outside,interiorMapIDs={}},
    {id="invented-confirmed-entry",kind="dungeon",reviewStatus="confirmed",instanceID=5,
        exterior=outside,interiorMapIDs={}},
}})
local edges = data:BuildEdges({})
assert(#edges==1 and edges[1].seconds==10,
    "The cheaper candidate connection must remain excluded from the executable graph")
assert(data:GetEntranceForInstance(4)==nil,
    "Candidate exterior metadata cannot claim a confirmed arrival target")
local entrance = data:GetEntranceForInstance(5)
assert(entrance and entrance.id=="invented-confirmed-entry",
    "A confirmed exterior remains usable independently of other uncertain interiors")
print("Instance review status: candidate connections and entrances are excluded; confirmed metadata remains usable")
