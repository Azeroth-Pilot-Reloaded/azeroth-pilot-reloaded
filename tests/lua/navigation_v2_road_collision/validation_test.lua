local H=assert(loadfile('tests/lua/navigation_v2_road_collision/support.lua'))()
local api=H.Load()
local function make(mask,extras,options)
    local definition={worldID=0,base=mask,overlays={}}
    for key,value in pairs(extras or {}) do definition[key]=value end
    return api.New(definition,options or H.Clocks())
end
local mask=H.Mask('rle',{'....'})
mask.rows[1]={{from=1,to=4,state='open'}}
local source=assert(make(mask));assert(H.Finish(source).status=='ready')
assert(H.Query(source,{x=3.8,y=3.8},{x=3.2,y=.2}).status=='complete')
for _,row in ipairs({{{from=2,to=4,state='open'}},{{from=1,to=2,state='open'}},
    {{from=1,to=3,state='open'},{from=3,to=4,state='open'}},{{from=1,to=4,state='invented'}}}) do
    mask=H.Mask('invalid',{'....'});mask.rows[1]=row
    source=assert(make(mask));assert(H.Finish(source).status=='ready')
    assert(H.Query(source,{x=3.8,y=3.8},{x=3.2,y=3.2}).reason=='invalid_row')
end
mask=H.Mask('sparse',{'....'});mask.rows[1][2]=nil
source=assert(make(mask));H.Finish(source)
assert(H.Query(source,{x=3.8,y=3.8},{x=3.2,y=3.2}).reason=='invalid_row')
mask=H.Mask('bad-header',{'.'});mask.originX=math.huge
source=assert(make(mask));assert(H.Finish(source).status=='invalid')
assert(not make(H.Mask('open',{'.'}),{openings={{}}}),'Unresolved opening geometry cannot be silently ignored')
local options=H.Clocks();options.maxMasks=false
assert(not make(H.Mask('open',{'.'}),nil,options),'False is not an omitted numeric option')
assert(not make(H.Mask('open',{'.'}),{identity=false}),'False is not an absent constraint table')
source=H.Source(api,H.Mask('invalid-budget',{'.'}))
local job=assert(source:Query({from={x=3.8,y=3.8},to={x=3.2,y=3.2},mode='walk'}))
assert(job:Step(false).reason=='invalid_step_budget')
options=H.Clocks();options.maxCachedSpans=1
source=assert(make(H.Mask('small-cache',{'..'}),nil,options));H.Finish(source)
assert(H.Query(source,{x=3.8,y=3.8},{x=3.2,y=3.2}).reason=='row_span_limit')
source=H.Source(api,H.Mask('open',{'.'}))
assert(not source:Query({from={x=0/0,y=3},to={x=3,y=3},mode='walk'}))
assert(not source:Query({from={x=3,y=3},to={x=3,y=3},mode='fly'}))
local a={x=3.8,y=3.8};local b={x=3.2,y=3.2}
assert(H.Query(source,a,b).status=='complete')
assert(H.Query(source,{x=4,y=3.5},b).reason=='outside_domain','Outer boundary has an unproved touching side')
print('Road collision: bounded schema, dense RLE validation and conservative domain boundary passed')
