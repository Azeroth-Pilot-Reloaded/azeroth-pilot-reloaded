-- A prudent itinerary avoids hostile-controlled transit without inventing locks.
local fixture=dofile("tests/lua/navigation_fixture.lua")
local function point(map,x)
    return {space="world",instanceID=7,uiMapID=map,x=x or 0,y=0,z=0,region="shared-land"}
end
local outside,enemyA,enemyB,own=point(704),point(701),point(702),point(703)
local spaces={
    [701]={id="capital-a",transitFaction="Alliance",transitRegion="capital-a"},
    [702]={id="capital-b",transitFaction="Alliance",transitRegion="capital-b"},
    [703]={id="home",transitFaction="Horde",transitRegion="home"},
    [706]={id="shared-hub",transitFaction="Neutral",transitRegion="shared-hub"},
}
local data=fixture:Load({connections={
    {id="public-neutral",kind="boat",from=outside,to=point(704,10),bidirectional=true},
    {id="public-capital",kind="portal",from=outside,to=enemyA,bidirectional=true},
    {id="public-carriage",kind="tram",from=enemyA,to=enemyB,bidirectional=true},
    {id="faction-gate",kind="portal",from=enemyA,to=outside,requirements={faction="Alliance"}},
    {id="home-gate",kind="portal",from=own,to=outside,bidirectional=true},
    {id="personal-capital",kind="item",from={dynamic="player"},to=enemyA,
        actions={{type="item",id=900001}}},
}})
assert(type(data.CheckTransitAccess)=="function","Transport safety needs a generic location policy distinct from physical requirements")
local faction="Horde"
data.env.getCharacter=function()return {faction=faction,level=90} end
data.env.getActionUsability=function()return true end
local unavailable={[708]="navigation_space_identity_unavailable",[709]="cyclic_navigation_space",
    [710]="navigation_space_parent_unavailable",[711]="navigation_space_world_mismatch"}
data.ResolveNavigationSpace=function(_,position)
    if position.uiMapID==705 then return nil,"ambiguous_navigation_space" end
    if position.uiMapID==707 then return nil,"navigation_space_unavailable" end
    if unavailable[position.uiMapID] then return nil,unavailable[position.uiMapID] end
    return spaces[position.uiMapID] or {id="native",known=false}
end
local function build(start,goal)
    local edges,meta=data:BuildEdges({start=start,playerPosition=start,goal=goal})
    local byID={}
    for _,edge in ipairs(edges) do byID[edge.id]=edge end
    return byID,meta
end
local function present(edges,id,side)return edges["retail:"..id..":"..(side or "forward")] end
local edges,meta=build(outside,point(704,10))
assert(present(edges,"public-neutral") and present(edges,"public-neutral","reverse"))
assert(present(edges,"home-gate") and not present(edges,"public-capital")
    and not present(edges,"public-carriage") and not present(edges,"personal-capital"),
    "Ordinary travel must not enter a hostile controlled region through a public or personal transport")
assert(not present(edges,"faction-gate") and #((meta.blockedEdges or {}))==0,
    "A refused safety policy cannot reappear as a relaxed unlock shortcut")
assert(data:CanWalk(outside,enemyA),"A prudent transit policy must preserve physical terrain walking")
edges=build(enemyA,outside)
assert(present(edges,"public-capital") and present(edges,"public-capital","reverse"),
    "An existing position in the hostile region permits leaving it")
assert(not present(edges,"public-carriage"),"Starting in one hostile capital cannot authorize entering another")
edges=build(outside,enemyA)
assert(present(edges,"public-capital") and present(edges,"personal-capital"),
    "An explicit objective in the hostile region permits reaching that region")
assert(not present(edges,"public-carriage") and not present(edges,"faction-gate"),
    "Objective intent cannot unlock another hostile region or a physically faction-locked service")
edges=build(enemyA,enemyB)
assert(present(edges,"public-carriage") and present(edges,"public-carriage","reverse"))
local retained=present(edges,"public-carriage")
assert(retained.canStart(enemyA,true)==true)
assert(retained.canStart(outside,true)==false,"A live departure outside the formerly authorized region must be rechecked")
edges=build(enemyB,enemyA)
assert(present(edges,"personal-capital").canStart(outside,true)==true,
    "A personal action must check its actual departure instead of its old recorded player position")
faction="Alliance"
edges=build(outside,point(704,10))
assert(present(edges,"public-capital") and present(edges,"public-carriage") and present(edges,"faction-gate"))
assert(not present(edges,"home-gate"),"Safety must work symmetrically for either faction")
faction=nil
edges,meta=build(outside,point(704,10))
assert(present(edges,"public-neutral") and not present(edges,"public-capital") and meta.waitingData,
    "Unknown faction cannot silently approve controlled access")
assert(data:CheckTransitAccess(point(706),outside,{},{})==true,
    "An explicitly neutral controlled hub remains usable without a faction observation")
assert(data:CheckTransitAccess(point(705),outside,{start=outside,goal=outside},{faction="Horde"})==nil,
    "Ambiguous location identity must wait instead of authorizing a controlled shortcut")
assert(data:CheckTransitAccess(point(707),outside,{start=outside,goal=outside},{faction="Horde"})==nil,
    "Missing location identity must wait instead of becoming an implicitly neutral transit")
for map,expected in pairs(unavailable) do
    local allowed,reason=data:CheckTransitAccess(point(map),outside,{start=outside,goal=outside},{faction="Horde"})
    assert(allowed==nil and reason==expected,"Every unresolved declared identity must retain its reason and remain pending")
    allowed,reason=data:CheckTransitAccess(enemyA,outside,{start=point(map),goal=outside},{faction="Horde"})
    assert(allowed==nil and reason==expected,"Unknown origin identity cannot become an implicitly neutral exception")
    assert(data:CheckTransitAccess(enemyA,outside,{start=point(map),goal=enemyA},{faction="Horde"})==true,
        "A proved explicit objective remains sufficient even when the independent origin identity is unknown")
end
data.ResolveNavigationSpace=false
assert(data:CheckTransitAccess(enemyA,enemyB,{},{faction="Horde"})==true,
    "Consumers without location policies retain legacy physical transport behavior")
print("Transit safety: hostile nodes, explicit intent, escape, neutral services and live eligibility passed")
