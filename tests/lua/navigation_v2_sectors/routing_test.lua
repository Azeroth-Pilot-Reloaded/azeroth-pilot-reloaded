local F=dofile('tests/lua/navigation_v2_sectors/fixture.lua')
local p,decodes=F.New()
local r=F.Finish(F.Route(p))
assert(r.status=='complete' and r.estimatedSeconds==8 and #r.segments==5)
assert(r.nodes[1]=='meadow:terrain:1' and r.nodes[6]=='harbor:terrain:2')
assert(r.segments[2].edgeId=='meadow:mountain-pass')
assert(decodes.meadow==1 and decodes.pass==1 and decodes.harbor==1 and not decodes.island)
local reverse=F.Finish(F.Route(p,'harbor:terrain:2','meadow:terrain:1'))
assert(reverse.status=='no_path' and not reverse.segments, 'a boundary must not invent a reverse edge')
local via=F.Finish(F.Route(p,nil,nil,{'pass:terrain:2'}))
assert(via.status=='complete' and via.estimatedSeconds==8)

-- A known route wins over uncertain/absent neighbors, without pretending they connect.
p=F.New({edit=function(index,catalog)
    catalog.pass=nil
    index.meadow.links[2]=nil
end})
r=F.Finish(F.Route(p))
assert(r.status=='unknown' and r.reason=='sector_absent' and not r.segments)
assert(r.objective.to=='harbor:terrain:2')
p=F.New({edit=function(index) index.pass=nil end})
r=F.Finish(F.Route(p))
assert(r.status=='complete' and r.estimatedSeconds==20)
p=F.New({edit=function(index) index.meadow.links[1].access='unknown';index.meadow.links[2]=nil end})
r=F.Finish(F.Route(p))
assert(r.status=='unknown' and r.reason=='unknown_access')
p=F.New({edit=function(index) index.meadow.links[1].access='unavailable';index.meadow.links[2]=nil end})
assert(F.Finish(F.Route(p)).status=='no_path')
p=F.New({edit=function(index,catalog)
    index.meadow.complete=false;catalog.meadow.complete=false;index.meadow.links={}
end})
r=F.Finish(F.Route(p))
assert(r.status=='unknown' and r.reason=='incomplete_graph')
-- The destination's decoded existence is checked before a boundary route completes.
p=F.New({edit=function(_,catalog) catalog.harbor=nil end})
assert(F.Finish(F.Route(p)).status=='unknown')

-- Do not repeat a failing native decode for each boundary node in one request.
p,decodes=F.New({edit=function(index,_,data)
    data.pass=nil
    index.meadow.links={
        {id='lower-gate',name='Lower gate',from=1,sector='pass',to=1,seconds=1},
        {id='upper-gate',name='Upper gate',from=1,sector='pass',to=2,seconds=2},
    }
end})
r=F.Finish(F.Route(p))
assert(r.status=='unknown' and r.reason=='decode_failed' and decodes.pass==1)
