local F=dofile('tests/lua/navigation_v2_conditions/integration_fixture.lua')
for _,client in ipairs({'Standard','Camelot'})do for _,answer in ipairs({'true','false','nil','secret','error'})do
    local e=F.Host(client)
    if answer=='false' then e.completed=false elseif answer=='nil'then e.completed=nil
    elseif answer=='secret'then e.completed={secret=true} elseif answer=='error'then e.questError=true end
    e:EnableConditions()
    local job=assert(e.host:Plan({from='cave',to='goal'},e.context))
    assert(e.questReads==0)
    local r=e:Finish()
    assert(r.status=='observation_required' and e.host.job==job and e.questReads==0)
    local operations=r.diagnostics.operations
    for _=1,8 do assert(e.host:GetResult().status=='observation_required');assert(e.host:Step(1).status=='observation_required')end
    assert(e.questReads==0 and e.host:GetResult().diagnostics.operations==operations,'Suspended jobs never read/reprepare')
    assert(e.host:ResumeConditions().status=='running' and e.host.job==job and e.questReads==1)
    r=e:Finish()
    assert(r.status=='complete' and r.estimatedSeconds==(answer=='true' and 3 or 13))
    assert(e.questReads==1 and not e:HasMarker(),'Step/GetResult/relaxation do not query or publish')
    assert(e.host:ResumeConditions().status=='complete' and e.questReads==1 and e.host.job==job)
    e:Cleanup()
end end
-- No known alternative and a native nil remain explicit unknown after ONE useful capture.
local e=F.Host('Standard');e.completed=nil
local graph=F.Graph();table.remove(graph.edges,3)
e:EnableConditions(graph)
local r,job=e:FirstResult()
assert(r.status=='unknown' and r.objective.to=='goal' and e.questReads==1)
for _=1,5 do assert(e.host:ResumeConditions().status=='unknown' and e.host.job==job)end
assert(e.questReads==1,'Unchanged unknown does not trigger another capture or Plan')
e:Cleanup()
