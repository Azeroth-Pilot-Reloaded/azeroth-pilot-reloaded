-- Physical faction restrictions differ from neutral travel through enemy land.
local fixture=dofile("tests/lua/navigation_fixture.lua")
local function point(x)
    return {space="world",instanceID=7,uiMapID=701,x=x,y=0,z=0,region="shared-land"}
end
local connections={
    {id="alliance-gateway",kind="portal",from=point(0),to=point(10),bidirectional=true,
        requirements={faction="Alliance"}},
    {id="horde-gateway",kind="portal",from=point(20),to=point(30),bidirectional=true,
        requirements={faction="Horde"}},
    {id="neutral-carriage",kind="tram",from=point(40),to=point(50),bidirectional=true},
}
for _,known in ipairs({"Alliance","Horde","unknown"}) do
    local faction=known~="unknown" and known or nil
    local data=fixture:Load({connections=connections})
    data.env.getCharacter=function()return {faction=faction,level=90} end
    local edges,metadata=data:BuildEdges({playerPosition=point(0)})
    local byID={}
    for _,edge in ipairs(edges) do byID[edge.id]=edge end
    for _,side in ipairs({"forward","reverse"}) do
        assert(byID["retail:neutral-carriage:"..side],"Neutral physical transport remains available for either faction")
        for _,expected in ipairs({"Alliance","Horde"}) do
            local id="retail:"..expected:lower().."-gateway:"..side
            assert((byID[id]~=nil)==(faction==expected),"Both transport directions must preserve their real faction requirement")
        end
    end
    assert(metadata.waitingData==(known=="unknown"),"Unknown faction cannot silently unlock a faction-restricted gate")
    assert(data:CanWalk(point(0),point(50)),"Faction-locked transports cannot make the surrounding terrain unwalkable")
    if faction then
        local edge=byID["retail:"..faction:lower().."-gateway:forward"]
        assert(edge.canStart(edge.from,true)==true)
        faction=faction=="Alliance" and "Horde" or "Alliance"
        assert(edge.canStart(edge.from,true)==false,"Retained actions must recheck the live faction observation")
    end
end
print("Faction travel: restricted gates, neutral bidirectionality, unknown identity and live eligibility passed")
