-- Child geometry cannot erase a containing phase or observed floor constraint.
local fixture=dofile("tests/lua/navigation_fixture.lua")
local data=fixture:Load({config={NavigationSpaces={
    {id="phase-parent",kind="building",worldID=8,mapIDs={72001},accessKey="phase-a",requiresExit=true},
    {id="phase-child",kind="building",worldID=8,mapIDs={72002},parentSpace="phase-parent",
        bounds={minX=0,maxX=10,minY=0,maxY=10,minZ=0,maxZ=5}},
    {id="floor-parent",kind="floor",worldID=8,mapIDs={72003},floor="lower",requiresExit=true},
    {id="plain-room",kind="building",worldID=8,mapIDs={72004},parentSpace="floor-parent"},
    {id="proved-room",kind="building",worldID=8,mapIDs={72005},parentSpace="floor-parent",
        bounds={minX=0,maxX=10,minY=0,maxY=10,minZ=0,maxZ=5}},
    {id="own-floor",kind="floor",worldID=8,mapIDs={72006},parentSpace="floor-parent",floor="upper",
        bounds={minX=0,maxX=10,minY=0,maxY=10,minZ=20,maxZ=25}},
}},connections={}})
local function point(map,fields)
    local p={instanceID=8,uiMapID=map,x=1,y=1,z=1}
    for key,value in pairs(fields or {})do p[key]=value end
    return p
end
local unknown,reason=data:ResolveNavigationSpace(point(72002))
assert(not unknown and reason=="navigation_space_identity_unavailable",
    "A unique bounded child does not prove its containing phase when the channel is unobserved")
local wrong=point(72002,{accessKey="phase-b"})
assert(data:ResolveNavigationSpace(wrong)==nil and data:GetPositionRegion(wrong)==nil,
    "A known foreign phase cannot acquire the child's declared region through a permissive ancestor")
local child=data:ResolveNavigationSpace(point(72002,{accessKey="phase-a"}))
assert(child and child.id=="phase-child" and child.accessKey=="phase-a",
    "A compatible observed phase is retained in the effective child descriptor")
unknown,reason=data:ResolveNavigationSpace(point(72004))
assert(not unknown and reason=="navigation_space_identity_unavailable",
    "An unbounded child cannot infer a containing floor without an observation")
assert(data:ResolveNavigationSpace(point(72004,{floor="upper"}))==nil,
    "A known wrong floor cannot be erased by selecting a more specific child map")
assert(data:ResolveNavigationSpace(point(72004,{floor="lower"})).floor=="lower")
assert(data:ResolveNavigationSpace(point(72005)).floor=="lower",
    "An explicit bounded child with known height can attest its containing floor")
unknown,reason=data:ResolveNavigationSpace(point(72005,{positionSource="unit",z=0}))
assert(not unknown and reason=="navigation_space_identity_unavailable",
    "A native placeholder height does not provide the missing floor observation")
assert(data:ResolveNavigationSpace(point(72006,{z=22,floor="upper"})).floor=="upper",
    "A nested space's explicit physical floor is not overwritten by its parent's floor label")
print("Space ancestors: inherited phase, missing/wrong floor observations, physical bounds and explicit child floors")
