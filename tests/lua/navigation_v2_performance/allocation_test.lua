local ns={}
for _,name in ipairs({'Conditions','Graph','Search','Navigation'})do
    assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/'..name..'.lua'))('test',ns)
end
local g={complete=true,nodes={'a','b','c'},edges={{id='fast',from='a',to='b',seconds=1},
    {id='finish',from='b',to='c',seconds=1}}}
for i=1,20000 do g.edges[#g.edges+1]={id='slow'..i,from='a',to='b',seconds=i+10} end
local p=assert(ns.LibAPRNavigationV2.New(g,{clock=function()return 0 end,profileClock=function()return 0 end}))
assert(p:Plan({from='a',to='a'}):Step(1000000).status=='complete')
collectgarbage('collect');collectgarbage('stop')
local before=collectgarbage('count')
local result=p:Plan({from='a',to='c'}):Step(1000000)
local allocated=collectgarbage('count')-before
collectgarbage('restart')
assert(result.status=='complete' and result.estimatedSeconds==2 and #result.segments==2)
assert(allocated<2048,'non-improving parallel edges allocated '..allocated..' KiB; budget is 2 MiB')
