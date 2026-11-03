local F=dofile('tests/lua/navigation_v2_sectors/fixture.lua')
local function Expect(edit, reason)
    local p=F.New({edit=edit})
    local r=F.Finish(F.Route(p))
    assert(r.status=='invalid' and r.reason==reason, r.status..':'..tostring(r.reason))
end
Expect(function(index) index.meadow.name='' end, 'invalid_sector_index')
Expect(function(index) index.meadow.nodes=3 end, 'sector_index_mismatch')
Expect(function(index) index.meadow.links[1].to=3 end, 'invalid_boundary')
Expect(function(index) index.meadow.links[1].seconds=-1 end, 'invalid_boundary')
Expect(function(index) index.meadow.links[1].access=false end, 'invalid_boundary')
Expect(function(index) index.meadow.links[1].access='maybe' end, 'invalid_boundary')
Expect(function(index) index.meadow.links[1].name=' ' end, 'invalid_boundary')
Expect(function(index) index.meadow.links[1].sector='not:a:sector' end, 'invalid_boundary')
Expect(function(index) index.meadow.links[1].from=0 end, 'invalid_boundary')
Expect(function(index) index.meadow.links[2].id=index.meadow.links[1].id end, 'invalid_boundary')
Expect(function(index) index.meadow.links[4]=index.meadow.links[2];index.meadow.links[2]=nil end, 'invalid_boundary')
Expect(function(index) index.pass.name=false end, 'invalid_sector_index')
Expect(function(_,catalog) catalog.meadow.blocks[1].edges=0 end, 'invalid_block')

local p,_,_,source,ns=F.New()
for _,id in ipairs({'meadow:terrain:0','meadow:terrain:3','meadow:terrain:01','meadow:terrain:1:extra','terrain:1'}) do
    assert(F.Finish(F.Route(p,id)).status=='invalid')
end
assert(F.Finish(F.Route(p,'unknown:terrain:1')).reason=='sector_absent')
source.cacheSize=false
assert(select(2,ns.LibAPRNavigationV2.New(source,{}))=='invalid_sector_graph')
source.cacheSize=9
assert(select(2,ns.LibAPRNavigationV2.New(source,{}))=='invalid_sector_graph')

-- An unreachable invalid catalog value is never touched during a useful request.
p=F.New({edit=function(index,catalog)
    index.island=setmetatable({}, {__index=function() error('unrelated index read') end})
    catalog.island=setmetatable({}, {__index=function() error('unrelated decode') end})
end})
assert(F.Finish(F.Route(p)).estimatedSeconds==8)
