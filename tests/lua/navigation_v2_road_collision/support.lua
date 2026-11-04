local H = {}
function H.Load()
    local ns = {NavigationV2Graph={Budgets={sliceMs=1,cpuMs=100,elapsedMs=5000}}}
    assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/Data/RoadCollision.lua'))('test', ns)
    return assert(ns.NavigationV2RoadCollision)
end
local states={['.']='open',['#']='blocked',['~']='water',['?']='unknown-floor',['i']='inherit'}
function H.Mask(id, lines, options)
    options=options or {}
    local mask={id=id,originX=options.originX or 4,originY=options.originY or 4,
        cellSize=options.cellSize or 1,width=#lines[1],height=#lines,rows={}}
    for row,line in ipairs(lines) do
        mask.rows[row]={}
        for column=1,#line do
            mask.rows[row][column]={from=column,to=column,state=assert(states[line:sub(column,column)])}
        end
    end
    return mask
end
function H.Clocks()
    local time={wall=0,cpu=0}
    return {clock=function()return time.wall end,profileClock=function()return time.cpu end},time
end
function H.Finish(job, operations)
    local state
    for _=1,10000 do
        state=job:Step(operations or 32)
        if state.status~='running' then return state end
    end
    error('Synthetic job did not terminate')
end
function H.Source(api,mask,overlays,extras)
    local definition={worldID=0,base=mask,overlays=overlays or {}}
    for key,value in pairs(extras or {}) do definition[key]=value end
    local options,time=H.Clocks()
    local source=assert(api.New(definition,options))
    local state=H.Finish(source)
    assert(state.status=='ready',state.reason)
    return source,time,options
end
function H.Query(source,from,to,mode)
    return H.Finish(assert(source:Query({from=from,to=to,mode=mode or 'walk'})))
end
return H
