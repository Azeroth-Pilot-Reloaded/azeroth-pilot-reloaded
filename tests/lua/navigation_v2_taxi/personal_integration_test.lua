local F=dofile('tests/lua/navigation_v2_taxi/fixture.lua')
local ns=F.Load()
assert(ns.NavigationV2Personal,'Personal must be loaded by actual XML')
local declaration={id='recall',kind='spell',spellID=901,from='cave',to='hub',name='Recall',
    destination={space='world',phase='shared'},useSeconds=1,loadingSeconds=0,cooldownSeconds=0,
    timeoutSeconds=20,moneyCopper=6,reagents={powder={itemID=902,count=1}}}
local observation={revision=1,observedAt=100,combat=false,casting=false,loading=false,moneyCopper=10,
    items={[902]=2},origin={node='cave',space='cave',phase='shared',indoors=true,reliable=true},
    actions={recall={known=true,loaded=true,usable=true,readyAt=100}}}
local taxi=F.Route('flight','hub','goal',6,1)
local options=F.Options({taxi},10)
options.personal,options.personalObservation={declaration},observation
local graph={complete=true,nodes={'cave','hub','goal'},edges={
    {id='free approach',from='cave',to='hub',seconds=8},
    {id='whole walk',from='cave',to='goal',seconds=30}}}
local planner=assert(ns.LibAPRNavigationV2.New(graph,options))
local result=F.Finish(planner:Plan({from='cave',to='goal'}))
assert(result.estimatedSeconds==11 and result.resourcesSpent.money==6,
    'Personal6 + taxi6 cannot reset the shared budget10')
observation.revision,observation.moneyCopper=2,12
assert(planner:ObservePersonal(observation))
result=F.Finish(planner:Plan({from='cave',to='goal'}))
assert(result.estimatedSeconds==4 and result.segments[1].personalId=='recall')
assert(result.resourcesSpent.money==12 and result.resourcesSpent['item:powder']==1)
local journey=assert(ns.LibAPRNavigationV2.NewJourney(result.objective))
local travel=assert(planner:StartTravel(result,nil,journey))
assert(travel:GetAction().kind=='personal' and travel:GetAction().phase=='ready' and not travel:GetAction().position)
local action=assert(travel:BeginPersonal())
assert(action.phase=='awaiting_transition' and action.attempt and not journey:RemainingRequest())
local attempt=action.attempt
-- A new catalogue generation makes plans stale, not this committed receipt.
observation.revision,observation.loading,observation.casting=3,true,true
assert(planner:ObservePersonal(observation) and not planner:IsCurrent(result))
assert(travel:GetAction().phase=='awaiting_transition' and travel:GetAction().attempt==attempt)
assert(travel:Observe({sequence=1,reliable=true,node='hub',space='world',phase='shared',loading=false}).kind=='personal')
local proof={personalId='recall',from='cave',to='hub',attempt=attempt,complete=true}
assert(travel:Observe({sequence=2,reliable=true,node='hub',space='world',phase='shared',loading=false,transition=proof}).kind=='replan')
assert(journey:RemainingRequest().from=='hub' and journey.objective.to=='goal')
-- A money-only refresh cannot erase known inventory. Missing new inventory revokes it.
assert(planner:SetResources({money=10,['item:powder']=2}))
observation.revision,observation.loading,observation.casting,observation.items=4,false,false,{}
assert(planner:ObservePersonal(observation))
assert(planner.resources['item:powder']==nil)
assert(planner:SetResources({money=13,['item:powder']=1}))
assert(planner.resources['item:powder']==1)
observation.revision,observation.moneyCopper,observation.items=5,12,{[902]=2}
assert(planner:ObservePersonal(observation))
result=F.Finish(planner:Plan({from='cave',to='goal'}))
travel=assert(planner:StartTravel(result));action=assert(travel:BeginPersonal())
proof={personalId='recall',from='cave',to='hub',attempt=action.attempt,complete=true}
assert(travel:Observe({sequence=1,reliable=true,loading=false,node='hub',space='world',phase='wrong',transition=proof}).reason=='personal_destination_mismatch')
travel=assert(planner:StartTravel(result));action=assert(travel:BeginPersonal())
local fixedDeadline=action.deadline
observation.revision,observation.casting=6,true
assert(planner:ObservePersonal(observation))
assert(travel:GetAction().deadline==fixedDeadline)
planner.clock=function()return fixedDeadline end
assert(travel:Tick().reason=='transition_timeout')
assert(travel:Observe({sequence=1,reliable=true,loading=false,node='hub',space='world',phase='shared',transition=proof}).kind=='failed')
-- Unknown declared resources count toward the common32-key limit atomically.
local many={}
for i=1,33 do many['reagent '..i]={itemID=1000+i,count=1}end
declaration.reagents=many
assert(select(2,ns.LibAPRNavigationV2.New(graph,options))=='resource_limit_exceeded')
