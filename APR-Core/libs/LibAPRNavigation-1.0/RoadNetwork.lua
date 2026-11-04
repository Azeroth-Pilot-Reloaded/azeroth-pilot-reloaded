-- Optional source road graphs are distinct from proved native collision packs.
-- Coordinates without a source height remain two-dimensional.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("road-network", 3) then return end
local Instance, Roads = Lib.Instance, {}
Lib.Roads = Roads
Lib.roadDatasets, Lib.roadRevision = Lib.roadDatasets or {}, Lib.roadRevision or 0
local TILE, EPSILON = 1600 / 3, 1e-9
local alphabet, digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_", {}
for i = 1, #alphabet do digits[alphabet:byte(i)] = i - 1 end

function Roads.Finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local Finite = Roads.Finite
local function ID(value)
    return type(value)=="string" and value~="" and value:match("^[a-z][a-z0-9%-]*$")~=nil
end
local function NativeRecord(profile)
    local record=Lib.roadDatasets[profile]
    if record and record.data.format==2 then return record end
    record={data={format=2,networks={},collision={}},revisions={networks={},collision={}},
        graphs={},rows={},buildingRows={}}
    Lib.roadDatasets[profile]=record
    return record
end
local function Registration(profile,definition,revision)
    assert(type(profile)=="string" and profile~="","road profile required")
    assert(type(definition)=="table" and ID(definition.id),"readable road identity required")
    revision=revision or 1
    assert(Finite(revision) and revision>0,"road revision required")
    return revision
end
local function Fields(definition,allowed)
    for key in pairs(definition) do assert(allowed[key],"unsupported road field: "..tostring(key)) end
end
local function Positions(points)
    assert(type(points)=="table" and #points>=2,"road positions required")
    for _,point in ipairs(points) do
        assert(type(point)=="table" and Finite(point.x) and Finite(point.y)
            and (point.z==nil or Finite(point.z)),"invalid road position")
    end
end
function Lib:RegisterRoadNetwork(profile,definition,revision)
    revision=Registration(profile,definition,revision)
    Fields(definition,{id=true,instanceID=true,uiMapID=true,kind=true,collision=true,sections=true,walls=true,openings=true})
    assert(Finite(definition.instanceID) and definition.instanceID>=0 and definition.instanceID%1==0,"native road world required")
    assert(definition.kind=="world" or definition.kind=="city" or definition.kind=="instance","road network kind required")
    assert(type(definition.sections)=="table","road network sections required")
    assert(definition.uiMapID==nil or Finite(definition.uiMapID) and definition.uiMapID>0,"invalid road map")
    if definition.collision then
        assert(type(definition.collision)=="table","road collision binding required")
        assert(definition.collision.base==nil or ID(definition.collision.base),"invalid base collision identity")
        for _,id in ipairs(definition.collision.overlays or {}) do assert(ID(id),"invalid local collision identity") end
    end
    for _,wall in ipairs(definition.walls or {}) do
        assert(ID(wall.id) and (wall.height==nil or Finite(wall.height)),"invalid road wall")
        Positions(wall.points)
    end
    for _,opening in ipairs(definition.openings or {}) do
        assert(ID(opening.id) and (opening.kind=="polygon" or opening.kind=="stroke"),"invalid road opening")
        assert(opening.radius==nil or Finite(opening.radius) and opening.radius>=0,"invalid road opening radius")
        Positions(opening.points)
    end
    local copy=Lib.Copy(definition)
    local record=NativeRecord(profile)
    local previous=record.revisions.networks[definition.id]
    if previous and previous>=revision then return false end
    record.data.networks[definition.id]=copy
    record.revisions.networks[definition.id]=revision
    record.graphs[definition.id]=nil
    if record.wallIndexes then record.wallIndexes[definition.id]=nil end
    record.pointLists=nil
    record.openedCells=nil
    Lib.roadRevision=Lib.roadRevision+1
    return true
end
function Lib:RegisterRoadCollision(profile,definition,revision)
    revision=Registration(profile,definition,revision)
    Fields(definition,{id=true,originX=true,originY=true,cellSize=true,width=true,height=true,
        rows=true,splitHeight=true,blockedRuns=true})
    assert(Finite(definition.originX) and Finite(definition.originY),"collision origin required")
    assert(Finite(definition.cellSize) and definition.cellSize>0,"collision cell size required")
    assert(Finite(definition.width) and definition.width>0 and definition.width%1==0
        and Finite(definition.height) and definition.height>0 and definition.height%1==0,"collision dimensions required")
    assert(type(definition.rows)=="table" and #definition.rows==definition.height,"collision rows required")
    for index,row in pairs(definition.rows) do
        assert(Finite(index) and index%1==0 and index>=1 and index<=definition.height and type(row)=="table",
            "collision rows must be a dense array of plain ranges")
    end
    for index=1,definition.height do assert(type(definition.rows[index])=="table","collision row required") end
    assert(definition.splitHeight==nil or Finite(definition.splitHeight),"invalid collision floor height")
    for _,run in ipairs(definition.blockedRuns or {}) do
        assert(type(run)=="table" and Finite(run.row) and run.row>=1 and run.row<=definition.height and run.row%1==0
            and Finite(run.column) and run.column>=1 and run.column%1==0 and Finite(run.count) and run.count>=1
            and run.count%1==0 and run.column+run.count-1<=definition.width,"invalid blocked collision run")
    end
    local copy=Lib.Copy(definition)
    local record=NativeRecord(profile)
    local previous=record.revisions.collision[definition.id]
    if previous and previous>=revision then return false end
    record.data.collision[definition.id]=copy
    record.revisions.collision[definition.id]=revision
    record.grids,record.graphs,record.rows,record.buildingRows,record.openedCells=nil,{},{},{},nil
    Lib.roadRevision=Lib.roadRevision+1
    return true
end
function Roads.Height(point)
    if point.positionSource == "unit" and point.z == 0 and point.heightSource ~= "terrain" then return nil end
    return Finite(point.z) and point.z or nil
end
function Lib:RegisterRoadData(profile, data, revision)
    assert(type(profile) == "string" and profile ~= "", "road profile required")
    assert(type(data) == "table" and data.format == 1 and type(data.roads) == "table", "unsupported road data")
    revision = revision or 1
    assert(Finite(revision) and revision > 0, "road revision required")
    local previous = self.roadDatasets[profile]
    -- An older embedded copy cannot replace the native catalogue after an
    -- in-session library upgrade, regardless of its old numeric revision.
    if previous and previous.data.format==2 then return false end
    if previous and previous.revision >= revision then return false end
    self.roadDatasets[profile] = { data = Lib.Copy(data), revision = revision, graphs = {}, rows = {}, buildingRows = {} }
    self.roadRevision = self.roadRevision + 1
    return true
end
function Instance:GetRoadRevision() return Lib.roadRevision end
function Instance:GetRoadData()
    local record = Lib.roadDatasets[self.profile]
    return record and record.data
end
function Roads.Record(owner) return Lib.roadDatasets[owner.profile] end
function Roads.Level(record, point)
    if not record or type(point) ~= "table" then return nil end
    local data, world = record.data, point.instanceID
    local explicit = point.roadLevel
    if data.format==2 then
        if explicit~=nil then
            local network=data.networks[explicit]
            return network and network.instanceID==world and explicit or nil
        end
        local fallback
        for id,network in pairs(data.networks) do
            if network.instanceID==world then
                if network.kind=="instance" or (network.kind=="city" and point.uiMapID and point.uiMapID==network.uiMapID) then return id end
                if network.kind=="world" then fallback=id end
            end
        end
        return fallback
    end
    if explicit ~= nil then
        local level = data.levels and data.levels[explicit]
        if data.roads[explicit] and (explicit == world or level and level.base == world) then return explicit end
        return nil
    end
    for id, level in pairs(data.levels or {}) do
        if level.base == world and data.roads[id] and
            ((point.uiMapID and level.map == point.uiMapID) or level.instance == true) then return id end
    end
    if data.roads[world] then return world end
end
function Instance:HasRoadData(from, to)
    local record = Roads.Record(self)
    if not from then return record ~= nil and next(record.data.networks or record.data.roads) ~= nil end
    local first = Roads.Level(record, from)
    if not first then return false end
    return not to or from.instanceID == to.instanceID and first == Roads.Level(record, to)
end

local function Rows(record, grid)
    local cache = record.rows[grid]
    if not cache then cache = {}; record.rows[grid] = cache end
    if not cache.source then
        cache.source = grid.rows
        if type(cache.source) == "string" then
            local source = {}
            for row in cache.source:gmatch("[^/]+") do source[#source + 1] = row end
            cache.source = source
        end
    end
    return cache
end
local function Decode(text, short, long)
    if type(text) ~= "string" then return nil end
    local out, width, index = {}, 0, 1
    while index <= #text do
        local byte, value, length = text:byte(index)
        if byte == 95 then
            value = tonumber(text:sub(index + 1, index + 1))
            length = 0
            for j = 1, long do
                local digit = digits[text:byte(index + 1 + j)]
                if not digit then return nil end
                length = length * 64 + digit
            end
            index = index + 2 + long
        else
            local digit = digits[byte]
            if not digit then return nil end
            value, length = math.floor(digit / short), digit % short + 1
            index = index + 1
        end
        if not value or length <= 0 then return nil end
        width = width + length
        out[#out + 1], out[#out + 2] = width, value
    end
    return out
end
local STATES={open=0,water=1,blocked=2,["unknown-floor"]=3,inherit=4}
local function PlainRow(row,width,breathe)
    if type(row)~="table" or #row==0 then return nil end
    local count=0
    for key in pairs(row) do
        if not Finite(key) or key%1~=0 or key<1 or key>#row then return nil end
        count=count+1
    end
    if count~=#row then return nil end
    local result,first={},1
    for _,range in ipairs(row) do
        if breathe then breathe() end
        if type(range)~="table" then return nil end
        for key in pairs(range) do if key~="from" and key~="to" and key~="state" then return nil end end
        local last,state=range.to,STATES[range.state]
        if range.from~=first or not Finite(last) or last%1~=0 or last<first or last>width or state==nil then return nil end
        result[#result+1],result[#result+2]=last,state
        if state==4 then result.inherits=true end
        first=last+1
    end
    if first~=width+1 then return nil end
    return result
end
local function Building(record, level, row, col)
    local rows = record.buildingRows[level]
    if not rows then
        rows = {}; record.buildingRows[level] = rows
        local source = record.data.buildings and record.data.buildings[level] or {}
        for i = 1, #source - 2, 3 do
            local list = rows[source[i]] or {}; rows[source[i]] = list
            list[#list + 1], list[#list + 2] = source[i + 1], source[i + 1] + source[i + 2] - 1
        end
    end
    local intervals = rows[row] or {}
    for i = 1, #intervals, 2 do if col >= intervals[i] and col <= intervals[i + 1] then return true end end
    return false
end
local function Points(record,declaration)
    record.pointLists=record.pointLists or {}
    if record.pointLists[declaration] then return record.pointLists[declaration] end
    local points={}
    for _,point in ipairs(declaration.points or {}) do points[#points+1],points[#points+2]=point.x,point.y end
    record.pointLists[declaration]=points
    return points
end
local function Grid(record,definition)
    record.grids=record.grids or {}
    local result=record.grids[definition]
    if result then return result end
    result={originX=definition.originX,originY=definition.originY,cell=definition.cellSize,w=definition.width,h=definition.height,
        rows=definition.rows,
        split=definition.splitHeight,blockedRuns=definition.blockedRuns,native=true}
    record.grids[definition]=result
    return result
end
local function GridOrigin(grid)
    return grid.originX or (32-grid.ty0)*TILE,grid.originY or (32-grid.tx0)*TILE
end
local function InPolygon(points,x,y)
    local inside=false
    local previous=#points-1
    for i=1,#points-1,2 do
        local ax,ay,bx,by=points[previous],points[previous+1],points[i],points[i+1]
        if (ay>y)~=(by>y) and x<(bx-ax)*(y-ay)/(by-ay)+ax then inside=not inside end
        previous=i
    end
    return inside
end
local function NearStroke(points,x,y,radius)
    for i=1,#points-3,2 do
        local ax,ay,dx,dy=points[i],points[i+1],points[i+2]-points[i],points[i+3]-points[i+1]
        local length=dx*dx+dy*dy
        local t=length>0 and math.max(0,math.min(1,((x-ax)*dx+(y-ay)*dy)/length)) or 0
        if (ax+t*dx-x)^2+(ay+t*dy-y)^2<=radius*radius then return true end
    end
    return false
end
local function Opened(record,level,grid,row,col)
    local network=record.data.networks and record.data.networks[level]
    local declarations=network and network.openings or record.data.wallOpens and record.data.wallOpens[level]
    if not declarations then return false end
    record.openedCells=record.openedCells or {}
    local cache=record.openedCells[grid] or {};record.openedCells[grid]=cache
    local key=tostring(row)..":"..col
    if cache[key]~=nil then return cache[key] end
    local originX,originY=GridOrigin(grid)
    local x=originX-(row-0.5)*grid.cell
    local y=originY-(col-0.5)*grid.cell
    local opened=false
    for _,declaration in ipairs(declarations) do
        local points=network and Points(record,declaration) or declaration.pts
        local area=network and declaration.kind=="polygon" or declaration.area
        if type(points)=="table" and #points>=4 and
            ((area and InPolygon(points,x,y)) or
                (not area and NearStroke(points,x,y,(declaration.radius or 6)+grid.cell/2))) then opened=true;break end
    end
    cache[key]=opened
    return opened
end
function Roads.Cell(record, grid, row, col, level, breathe)
    if not grid or not Finite(grid.cell) or grid.cell <= 0 then return nil end
    if row < 1 or col < 1 or row > grid.h or col > grid.w then return nil end
    if level and Opened(record,level,grid,row,col) then return 0 end
    if grid.native then
        local rows=record.buildingRows[grid]
        if not rows then
            rows={};record.buildingRows[grid]=rows
            for _,run in ipairs(grid.blockedRuns or {}) do
                local list=rows[run.row] or {};rows[run.row]=list
                list[#list+1],list[#list+2]=run.column,run.column+run.count-1
            end
        end
        for i=1,#(rows[row] or {}),2 do
            if col>=rows[row][i] and col<=rows[row][i+1] then return 2 end
        end
    elseif level and Building(record, level, row, col) then return 2 end
    local cache = Rows(record, grid)
    if type(cache.source) ~= "table" then return nil end
    local runs = cache[row]
    if runs==nil then
        if grid.native then runs=PlainRow(cache.source[row],grid.w,breathe)
        else runs=Decode(cache.source[row],grid.short or 21,grid.long or 3) end
        cache[row]=runs or false
    end
    if runs==false or runs==nil or (grid.native and level~=nil and runs.inherits) then return nil end
    local lo, hi = 1, #runs / 2
    while lo < hi do
        local middle = math.floor((lo + hi) / 2)
        if runs[middle * 2 - 1] < col then lo = middle + 1 else hi = middle end
    end
    if not runs[lo * 2 - 1] or runs[lo * 2 - 1] < col then return nil end
    return runs[lo * 2]
end
local function GridXY(grid, x, y)
    local originX,originY=GridOrigin(grid)
    return (originX-x)/grid.cell,(originY-y)/grid.cell
end
local function InGrid(grid, x, y)
    local row, col = GridXY(grid, x, y)
    return row >= 0 and col >= 0 and row < grid.h and col < grid.w
end
function Roads.Grids(record, level, from, to)
    local result = {}
    if record.data.format==2 then
        local network=record.data.networks[level]
        local binding=network and network.collision or {}
        for _,id in ipairs(binding.overlays or {}) do
            local definition=record.data.collision[id]
            if definition then
                local grid=Grid(record,definition)
                local intersects=not from or (math.max(from.x,to.x)>=grid.originX-grid.h*grid.cell-EPSILON
                    and math.min(from.x,to.x)<=grid.originX+EPSILON and math.max(from.y,to.y)>=grid.originY-grid.w*grid.cell-EPSILON
                    and math.min(from.y,to.y)<=grid.originY+EPSILON)
                if intersects then result[#result+1]=grid end
            end
        end
        local definition=binding.base and record.data.collision[binding.base]
        local base=definition and Grid(record,definition)
        if base then result[#result+1]=base end
        return result,base
    end
    for _, key in ipairs(record.data.halls and record.data.halls[level] or {}) do
        local grid = record.data.terrain and record.data.terrain[key]
        if grid and grid.overlay then
            local north,west=(32-grid.ty0)*TILE,(32-grid.tx0)*TILE
            local intersects=not from or (math.max(from.x,to.x)>=north-grid.h*grid.cell-EPSILON
                and math.min(from.x,to.x)<=north+EPSILON and math.max(from.y,to.y)>=west-grid.w*grid.cell-EPSILON
                and math.min(from.y,to.y)<=west+EPSILON)
            if intersects then result[#result + 1] = grid end
        end
    end
    local base = record.data.terrain and record.data.terrain[level]
    if base then result[#result + 1] = base end
    return result, base
end
local function At(record, level, grids, base, x, y, z, breathe)
    for _, grid in ipairs(grids) do
        if InGrid(grid, x, y) then
            if grid.split and not z then return nil, "road_floor_unknown" end
            if not grid.split or z <= grid.split then
                local r, c = GridXY(grid, x, y)
                local value = Roads.Cell(record, grid, math.floor(r) + 1, math.floor(c) + 1, grid == base and level or nil,breathe)
                if value == nil then return nil, "road_terrain_missing" end
                if value==3 and (grid.native or grid~=base) then return nil,"road_floor_unknown" end
                if grid.native and value==4 then
                    if grid==base then return nil,"road_terrain_missing" end
                else
                    if grid==base then return value end
                    if value==2 and base then
                        local br,bc=GridXY(base,x,y)
                        if Opened(record,level,base,math.floor(br)+1,math.floor(bc)+1) then return 0 end
                    end
                    if grid.native or value~=1 then return value end
                end
            end
        end
    end
    return nil, "road_terrain_missing"
end
local function Orient(ax, ay, bx, by, cx, cy) return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax) end
local function Between(a, b, c) return c >= math.min(a, b) - EPSILON and c <= math.max(a, b) + EPSILON end
local function Hits(ax, ay, bx, by, cx, cy, dx, dy)
    local a, b = Orient(ax, ay, bx, by, cx, cy), Orient(ax, ay, bx, by, dx, dy)
    local c, d = Orient(cx, cy, dx, dy, ax, ay), Orient(cx, cy, dx, dy, bx, by)
    if a * b < 0 and c * d < 0 then return true end
    return math.abs(a) <= EPSILON and Between(ax, bx, cx) and Between(ay, by, cy)
        or math.abs(b) <= EPSILON and Between(ax, bx, dx) and Between(ay, by, dy)
        or math.abs(c) <= EPSILON and Between(cx, dx, ax) and Between(cy, dy, ay)
        or math.abs(d) <= EPSILON and Between(cx, dx, bx) and Between(cy, dy, by)
end
local function WallIndex(record,level,breathe)
    record.wallIndexes=record.wallIndexes or {}
    local cache=record.wallIndexes[level]
    if cache then return cache end
    cache={cells={}}
    local network=record.data.networks and record.data.networks[level]
    for _,wall in ipairs(network and network.walls or record.data.walls and record.data.walls[level] or {}) do
        local points=network and Points(record,wall) or wall.pts or wall
        for i=1,#points-3,2 do
            if breathe then breathe() end
            local entry={points[i],points[i+1],points[i+2],points[i+3],floor=network and wall.height and {z=wall.height} or wall.fl}
            local x0,x1=math.floor(math.min(entry[1],entry[3])/128),math.floor(math.max(entry[1],entry[3])/128)
            local y0,y1=math.floor(math.min(entry[2],entry[4])/128),math.floor(math.max(entry[2],entry[4])/128)
            cache.minX,cache.maxX=math.min(cache.minX or x0,x0),math.max(cache.maxX or x1,x1)
            cache.minY,cache.maxY=math.min(cache.minY or y0,y0),math.max(cache.maxY or y1,y1)
            for x=x0,x1 do for y=y0,y1 do
                local key=tostring(x)..":"..y;local bucket=cache.cells[key] or {};cache.cells[key]=bucket
                bucket[#bucket+1]=entry
            end end
        end
    end
    record.wallIndexes[level]=cache
    return cache
end
function Roads.WallHit(record, level, from, to, breathe)
    local index=WallIndex(record,level,breathe)
    if not index.minX then return false end
    local x0,x1=math.floor(math.min(from.x,to.x)/128),math.floor(math.max(from.x,to.x)/128)
    local y0,y1=math.floor(math.min(from.y,to.y)/128),math.floor(math.max(from.y,to.y)/128)
    if x0>index.maxX or x1<index.minX or y0>index.maxY or y1<index.minY then return false end
    local seen={}
    for x=math.max(x0,index.minX),math.min(x1,index.maxX) do
        for y=math.max(y0,index.minY),math.min(y1,index.maxY) do
            if breathe then breathe() end
            for _,entry in ipairs(index.cells[tostring(x)..":"..y] or {}) do
                if not seen[entry] then
                    seen[entry]=true
                    if breathe then breathe() end
                    if Hits(from.x,from.y,to.x,to.y,entry[1],entry[2],entry[3],entry[4]) then
                        local floor=entry.floor
                        if not floor then return true,"road_wall" end
                        local first,last=Roads.Height(from),Roads.Height(to)
                        if not first or not last or not Finite(floor.z) then return true,"road_floor_unknown" end
                        if math.min(first,last)<=floor.z+5 and math.max(first,last)>=floor.z-5 then return true,"road_wall" end
                    end
                end
            end
        end
    end
    return false
end
-- The sweep visits every interval cut by every relevant grid boundary. At a
-- boundary, both sides are checked as well: a corner contact cannot hide a wall.
function Roads.SegmentCost(record, level, from, to, breathe)
    if not from or not to or not Finite(from.x) or not Finite(from.y) or not Finite(to.x) or not Finite(to.y) then
        return nil, "invalid_road_position"
    end
    local wall, reason = Roads.WallHit(record, level, from, to, breathe)
    if wall then return nil, reason end
    local grids, base = Roads.Grids(record, level, from, to)
    if not base then return nil, "road_terrain_missing" end
    local events, seen = { 0, 1 }, { [0] = true, [1] = true }
    local function event(value)
        if value > 0 and value < 1 and not seen[value] then seen[value] = true; events[#events + 1] = value end
    end
    for _, grid in ipairs(grids) do
        local r1, c1 = GridXY(grid, from.x, from.y)
        local r2, c2 = GridXY(grid, to.x, to.y)
        local function boundaries(first, last, maximum)
            if first == last then return end
            local low, high = math.max(0, math.ceil(math.min(first, last))), math.min(maximum, math.floor(math.max(first, last)))
            for index = low, high do if breathe then breathe() end; event((index - first) / (last - first)) end
        end
        if math.max(r1, r2) >= 0 and math.min(r1, r2) <= grid.h and math.max(c1, c2) >= 0 and math.min(c1, c2) <= grid.w then
            boundaries(r1, r2, grid.h); boundaries(c1, c2, grid.w)
        end
    end
    table.sort(events)
    local dx, dy, z1, z2 = to.x - from.x, to.y - from.y, Roads.Height(from), Roads.Height(to)
    local distance, cost = math.sqrt(dx * dx + dy * dy), 0
    -- A 2D cell cannot prove a staircase, lift, cliff or connection between
    -- floors. Known height changes use declared road links instead.
    if z1 and z2 and math.abs(z2-z1)>1 then return nil,"road_vertical_unknown" end
    local function sample(t, ox, oy)
        return At(record, level, grids, base, from.x + t * dx + (ox or 0), from.y + t * dy + (oy or 0),
            z1 and z2 and z1 + t * (z2 - z1) or nil,breathe)
    end
    for i = 1, #events do
        if breathe then breathe() end
        local t = events[i]
        local value, why = sample(t)
        if value == nil then return nil, why end
        if value == 2 then return nil, "road_blocked" end
        if i > 1 then
            local previous = events[i - 1]
            local middle, failure = sample((previous + t) / 2)
            if middle == nil then return nil, failure end
            if middle == 2 then return nil, "road_blocked" end
            cost = cost + (t - previous) * distance * (middle == 1 and 1.5 or 1)
        end
        -- Only check the additional incident cells at interior grid crossings.
        -- The offset is geometric tolerance, not a traversal sampling interval.
        if t > 0 and t < 1 then
            for _, ox in ipairs({ -1e-7, 1e-7 }) do
                for _, oy in ipairs({ -1e-7, 1e-7 }) do
                    local incident, failure = sample(t, ox, oy)
                    if incident == nil then return nil, failure end
                    if incident == 2 then return nil, "road_blocked" end
                end
            end
        end
    end
    if z1 and z2 and distance>0 then cost=cost*math.sqrt(distance*distance+(z2-z1)^2)/distance end
    return cost
end
function Instance:RoadSegmentCost(from, to)
    local record = Roads.Record(self)
    local level = Roads.Level(record, from)
    if not level or level ~= Roads.Level(record, to) or from.instanceID ~= to.instanceID then return nil, "road_space_mismatch" end
    return Roads.SegmentCost(record, level, from, to)
end

function Roads.Unpack(edge, nodes)
    if type(edge[5]) ~= "string" then
        local points = {}
        for i = 5, #edge do points[#points + 1] = edge[i] end
        return points
    end
    local x, y = nodes[edge[1] * 2 - 1], nodes[edge[1] * 2]
    local points, text = { x, y }, edge[5]
    if #text % 4 ~= 0 then return nil end
    for i = 1, #text, 4 do
        local a, b, c, d = text:byte(i, i + 3)
        a, b, c, d = digits[a], digits[b], digits[c], digits[d]
        if not a or not b or not c or not d then return nil end
        x, y = x + a * 64 + b - 2048, y + c * 64 + d - 2048
        points[#points + 1], points[#points + 2] = x, y
    end
    return points
end
