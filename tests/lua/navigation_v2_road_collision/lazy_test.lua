local H=assert(loadfile('tests/lua/navigation_v2_road_collision/support.lua'))()
local api=H.Load()
local overlays={}
for i=1,300 do
    overlays[i]={id='remote-'..i,originX=-100-i*2,originY=-100,cellSize=1,
        width=1000000,height=1000000,rows={}}
    -- Deliberately malformed, unvisited rows must not be read as a global precondition.
    overlays[i].rows[999999]='not a row'
end
local mask=H.Mask('local',{'..'});mask.height=1000000
mask.rows[2]='not a row'
local options=H.Clocks()
local source=assert(api.New({worldID=1,base=mask,overlays=overlays},options))
assert(source:GetState().operations==0 and source:GetState().validatedRows==0)
local job,why=source:Query({from={x=3.8,y=3.8},to={x=3.2,y=3.2},mode='walk'})
assert(not job and why=='source_not_ready')
assert(source:Step(1).operations==1,'Preparation observes operation budget')
local state=H.Finish(source)
assert(state.status=='ready' and state.validatedRows==0 and state.preparedMasks==301)
job=assert(source:Query({from={x=3.8,y=3.8},to={x=3.2,y=3.2},mode='walk'}))
assert(source:GetState().validatedRows==0,'Query construction does not scan rows')
state=H.Finish(job)
assert(state.status=='complete' and state.validationScope=='visited_rows_only' and state.globallyValidated==false)
assert(source:GetState().validatedRows==1 and source:GetState().cachedRows==1)
assert(H.Query(source,{x=3.7,y=3.7},{x=3.3,y=3.3}).status=='complete')
assert(source:GetState().validatedRows==1,'Validated row reused across requests')
assert(H.Query(source,{x=2.8,y=3.8},{x=2.2,y=3.2}).reason=='invalid_row')
assert(H.Query(source,{x=1.8,y=3.8},{x=1.2,y=3.2}).reason=='missing_row')

options=H.Clocks();options.maxCachedRows=2;options.maxCachedSpans=4
source=assert(api.New({worldID=0,base=H.Mask('bounded',{'..','..','..'}),overlays={}},options))
assert(H.Finish(source).status=='ready')
for row=1,3 do
    local x=4-row+.5
    assert(H.Query(source,{x=x,y=3.8},{x=x,y=3.2}).status=='complete')
end
state=source:GetState()
assert(state.cachedRows<=2 and state.cachedSpans<=4 and state.validatedRows==3)
assert(H.Query(source,{x=3.5,y=3.8},{x=3.5,y=3.2}).status=='complete')
assert(source:GetState().validatedRows==4,'An evicted row is revalidated, never assumed')
print('Road collision: large unvisited world, local row validation and bounded reusable cache passed')
