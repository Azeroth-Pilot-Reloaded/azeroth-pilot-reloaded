-- Local missing topology cannot be replaced by a cross-world item itinerary.
local fixture=dofile("tests/lua/navigation_fixture.lua")
local data=fixture:Load({connections={}})
assert(type(data.CreateLocalExitCheck)=="function","Incremental physical-exit checks must be available")
local function point(x,space,fields)
    local p={instanceID=8,uiMapID=18,x=x,y=0,z=0,region=space,spaceID=space}
    for key,value in pairs(fields or {}) do p[key]=value end
    return p
end
data.ResolveNavigationSpace=function(_,p)
    return {id=p.spaceID,kind=p.spaceID=="outside" and "outdoor" or p.spaceID=="floor" and "floor" or "cave",requiresExit=p.spaceID~="outside",known=true}
end
data.IsSameAccessRegion=function(_,a,b)
    return a.instanceID==b.instanceID and a.spaceID==b.spaceID and a.floor==b.floor and a.accessKey==b.accessKey
end
local start,goal=point(0,"cave"),point(50,"outside")
local function request(edges)
    return {start=start,goal=goal,edgeGroups={edges},budget=0,walkSpeed=1,
        canWalk=function(a,b)return not a.noAutoconnect and not b.noAutoconnect and data:IsSameAccessRegion(a,b)end}
end
local function finish(job)
    for _=1,10000 do
        local state,metadata=job:Step(1,100)
        assert(job.workLastStep<=1,"Exit collection and shared search obey the requested operation budget")
        if state~="planning" then return state,metadata end
    end
    error("Synthetic local exit check did not finish")
end
local remote=point(0,"remote",{instanceID=9})
local cycle={{kind="item",sourceFree=true,from=start,to=remote,seconds=1},
    {kind="portal",from=remote,to=goal,seconds=1}}
local status,metadata=finish(data:CreateLocalExitCheck(request(cycle)))
assert(status=="missing_data" and metadata.reason=="navigation_exit_unavailable" and not metadata.route,
    "A cross-world toy cycle cannot prove the cave's physical local exit")
local entry,turn,exit=point(5,"cave"),point(10,"cave",{noAutoconnect=true}),point(15,"outside")
local physical={{kind="passage",id="corner-one",from=entry,to=turn,seconds=5},
    {kind="passage",id="corner-two",from=turn,to=exit,seconds=5}}
status,metadata=finish(data:CreateLocalExitCheck(request(physical)))
assert(status=="ready" and metadata.applicable and metadata.physicalEdges==2 and not metadata.route,
    "Both mandatory corners can prove an exit without publishing the virtual probe path")
local prefixRequest=request(physical); prefixRequest.route=true
status,metadata=finish(data:CreateLocalExitCheck(prefixRequest))
local prefix=metadata.exitRoute
assert(status=="ready" and prefix and prefix.localExitOnly and #prefix.segments==3
    and prefix.segments[3].to.x==15 and prefix.totalSeconds==15,
    "An optional exit prefix ends at the physical outside and keeps its actual elapsed cost")
for _,segment in ipairs(prefix.segments)do
    assert(not segment.localExitProbe and not (segment.to.region or ""):find("local%-exit%-probe"),
        "The private sink and probe edge never enter the published prefix")
end
local denied=request(physical); denied.canWalk=function()return false end
assert(finish(data:CreateLocalExitCheck(denied))=="missing_data",
    "An explicit terrain-coverage denial cannot fall back to a broader geography walking predicate")
status=finish(data:CreateLocalExitCheck(request({physical[2]})))
assert(status=="missing_data","An unreachable second corner cannot authorize the missing first connection")
status=finish(data:CreateLocalExitCheck(request({{kind="portal",from=entry,to=exit,seconds=1}})))
assert(status=="ready","A localized same-world portal is a valid physical exit")
for _,kind in ipairs({"item","spell"}) do
    status=finish(data:CreateLocalExitCheck(request({{kind="portal",from=start,to=goal,actions={{type=kind,data=1}},seconds=1}})))
    assert(status=="missing_data","An action-only teleport does not become a physical exit by changing its edge caption")
end
local oldGoal=goal
goal=point(20,"building")
assert(finish(data:CreateLocalExitCheck(request(physical)))=="ready","Reaching the origin's outside is sufficient before entering another same-world building")
goal=point(20,"cave",{floor="upper"})
local nestedStatus,nestedMetadata=finish(data:CreateLocalExitCheck(request({})))
assert(nestedStatus=="ready" and not nestedMetadata.applicable,
    "A target floor inside the same cave does not require leaving the entire cave first")
local containerStart=start
start,goal=point(0,"floor",{floor="lower"}),point(20,"floor",{floor="upper"})
assert(finish(data:CreateLocalExitCheck(request({})))=="missing_data","An origin that is itself a floor retains its observed floor boundary")
start=containerStart
goal=point(20,"cave",{accessKey="other-phase"})
assert(finish(data:CreateLocalExitCheck(request({})))=="missing_data","A different known access phase is not the origin's local space")
goal=point(20,"cave")
local same=data:CreateLocalExitCheck(request({}))
assert(same:Step(0,0)=="ready" and not same.metadata.applicable,"An objective inside the origin does not require an exit check")
goal=point(20,"remote",{instanceID=9})
assert(data:CreateLocalExitCheck(request({})):Step(0,0)=="ready","An explicit different-world objective retains normal transport planning")
goal=oldGoal
local cancelled=data:CreateLocalExitCheck(request(physical))
assert(cancelled:Step(0,100)=="planning" and cancelled.workLastStep==0)
cancelled:Cancel()
assert(cancelled:Step(100,100)=="cancelled","Cancelled exit checks perform no later graph work")
local many={}
for index=1,20 do many[index]=physical[index%2+1] end
local timed=request(many)
local ticks=0
timed.clock=function()ticks=ticks+0.1;return ticks end
local sliced=data:CreateLocalExitCheck(timed)
assert(sliced:Step(10000,0.15)=="planning" and sliced.workLastStep>0 and sliced.workLastStep<10000,
    "Elapsed-time budgets yield during edge collection before processing the full physical catalogue")
sliced:Cancel()
local waiting=request({}); waiting.waitingData=true
assert(finish(data:CreateLocalExitCheck(waiting))=="waiting_data","A pending terrain source remains pending rather than a definitive missing exit")
print("Local exits: isolated origins, physical corner chains, item exclusion, floors/phases, world intent and bounded cancellation")
