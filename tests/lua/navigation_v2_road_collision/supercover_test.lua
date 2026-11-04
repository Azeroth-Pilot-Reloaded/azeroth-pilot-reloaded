local H=assert(loadfile('tests/lua/navigation_v2_road_collision/support.lua'))()
local api=H.Load()
local source=H.Source(api,H.Mask('corner',{'.#..','....','....','....'}))
assert(H.Query(source,{x=3.5,y=3.5},{x=.5,y=.5}).status=='blocked','Corner touch must check both side cells')
assert(H.Query(source,{x=3.5,y=3},{x=.5,y=3}).status=='blocked','A grid line touches cells on both sides')
local shift,scale=1000000,.001
source=H.Source(api,H.Mask('small-translated',{'.#..','....','....','....'},
    {originX=shift+4*scale,originY=shift+4*scale,cellSize=scale}))
assert(H.Query(source,{x=shift+3.5*scale,y=shift+3.5*scale},
    {x=shift+.5*scale,y=shift+.5*scale}).status=='blocked','World-offset rounding must not lose a corner obstacle')
source=H.Source(api,H.Mask('fine-base',{'....','....','....','....'}),
    {H.Mask('fine-obstacle',{'#'},{originX=2.75,originY=2.75,cellSize=.25})})
assert(H.Query(source,{x=3.5,y=2.6},{x=.5,y=2.6}).status=='blocked','Fine overlay boundaries cannot be skipped')

-- Independent exhaustive rectangle clipping oracle, not grid-event traversal.
local function touches(a,b,minX,maxX,minY,maxY)
    local low,high=0,1
    for _,axis in ipairs({{'x',minX,maxX},{'y',minY,maxY}}) do
        local start,delta=a[axis[1]],b[axis[1]]-a[axis[1]]
        if delta==0 then
            if start<axis[2] or start>axis[3] then return false end
        else
            local p,q=(axis[2]-start)/delta,(axis[3]-start)/delta
            low,high=math.max(low,math.min(p,q)),math.min(high,math.max(p,q))
            if low>high then return false end
        end
    end
    return true
end
for seed=1,60 do
    local lines={}
    for row=1,4 do
        lines[row]=''
        for col=1,4 do lines[row]=lines[row]..((row*17+col*11+seed*7)%9==0 and '#' or '.') end
    end
    local a={x=((seed*7)%13+1)/4,y=((seed*11)%13+1)/4}
    local b={x=((seed*3+2)%13+1)/4,y=((seed*5+1)%13+1)/4}
    local expected='complete'
    for row=1,4 do for col=1,4 do
        if lines[row]:sub(col,col)=='#' and touches(a,b,4-row,5-row,4-col,5-col) then expected='blocked' end
    end end
    source=H.Source(api,H.Mask('generated',lines))
    local actual=H.Query(source,a,b)
    assert(actual.status==expected,'Independent rectangle oracle mismatch seed '..seed..': '..tostring(actual.reason))
end
print('Road collision: conservative supercover and 60 independent rectangle-oracle cases passed')
