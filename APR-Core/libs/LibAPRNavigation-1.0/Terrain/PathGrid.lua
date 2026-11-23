-- SPDX-License-Identifier: GPL-3.0-or-later
-- Reader for the wire layout documented in the generated map declaration.
local runtime = LibStub("LibAPRNavigation-1.0")._TerrainNamespace
local G = {}
runtime.PathGrid = G
local work, floor = runtime.Work, math.floor
local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local digits = {}
for i = 1, #alphabet do
    digits[alphabet:byte(i)] = i - 1
end
local function integer(s, p, width)
    if width == 1 then return digits[s:byte(p)] end
    local a, b, c = s:byte(p, p + width - 1)
    local pair = digits[a] * 64 + digits[b]
    if width == 2 then return pair end
    return pair * 64 + digits[c]
end

local function field(st, name, k)
    local data = st.data
    if data.partitionSchema and not runtime.EnsureTerrainPage(data, k + 1) then return nil end
    local blocks = data.packed and data.packed[name] and data.packed[name][k + 1]
    if not blocks then return data[name] and data[name][k + 1] end
    local api = C_EncodingUtil
    local method = Enum and Enum.CompressionMethod and Enum.CompressionMethod.Zlib
    assert(method and api and type(api.DecompressString) == "function", "terrain decoder unavailable")
    local binary = data.blocks == "zlib"
    assert(binary or type(api.DecodeBase64) == "function", "base64 decoder unavailable")
    local chunks = {}
    for i = 1, #blocks do
        work()
        local compressed = binary and blocks[i] or api.DecodeBase64(blocks[i])
        local chunk = api.DecompressString(assert(compressed), method)
        assert(type(chunk) == "string" and #chunk <= 16384, "invalid terrain block")
        chunks[i] = chunk
    end
    return table.concat(chunks)
end

local states, stamp, residency
function G.Reset()
    states, stamp, residency = {}, 0, { grid = {}, graph = {}, surface = {}, canonical = {} }
end
G.Reset()

function G.State(id)
    if states[id] then return states[id] end
    local data = runtime.Data(id)
    if not data then return end
    local tile = 1600 / 3
    local st = {
        data = data,
        c = data.cells,
        unit = tile / data.cells,
        x0 = data.cx0 * tile,
        y0 = data.cy0 * tile,
        grid = {},
        graph = {}, surface = {}, canonical = {},
    }
    states[id] = st
    return st
end

function G.locate(st, x, y)
    local gx, gy = floor((x - st.x0) / st.unit), floor((y - st.y0) / st.unit)
    local c = st.c
    if gx < 0 or gy < 0 or gx >= st.data.nx * c or gy >= st.data.ny * c then return end
    return floor(gx / c) * st.data.ny + floor(gy / c), gx % c * c + gy % c
end

function G.position(st, tile, cell)
    return st.x0 + (floor(tile / st.data.ny) * st.c + floor(cell / st.c) + 0.5) * st.unit,
        st.y0 + (tile % st.data.ny * st.c + cell % st.c + 0.5) * st.unit
end

-- Only complete pages enter the shared cache. Concurrent suspended readers
-- may finish the same page independently. Jobs retain their own live references.
local function cached(st, kind, k, read, budget)
    local page = st[kind][k]
    if not page then
        page = read(st, k)
        if not page then return end
        page = st[kind][k] or page
        if not st[kind][k] then
            local pool = residency[kind]
            local total, oldest = page.weight, nil
            for _, entry in ipairs(pool) do
                total = total + entry.weight
            end
            while #pool > 0 and (#pool >= 64 or total > budget) do
                oldest = 1
                for i = 2, #pool do
                    if pool[i].stamp < pool[oldest].stamp then oldest = i end
                end
                local evicted = table.remove(pool, oldest)
                evicted.owner[kind][evicted.key] = nil
                total = total - evicted.weight
            end
            page.owner, page.key = st, k
            pool[#pool + 1], st[kind][k] = page, page
        end
    end
    stamp = stamp + 1
    page.stamp = stamp
    return page
end

-- The fine graph stores directed lattice steps and native triangle geometry.
-- Vertices and surface heights are IEEE-754 doubles in the producer's coordinates.
local function uint16(s, p)
    local a, b = s:byte(p, p + 1)
    return a + b * 256
end

local function int16(s, p)
    local n = uint16(s, p)
    return n >= 32768 and n - 65536 or n
end

local function uint32(s, p)
    local a,b,c,d = s:byte(p,p+3)
    return a + b*256 + c*65536 + d*16777216
end

local function double(s, p)
    local a,b,c,d,e,f,g,h = s:byte(p,p+7)
    local lo = a + b*256 + c*65536 + d*16777216
    local hi = e + f*256 + g*65536 + h*16777216
    local exponent = floor(hi / 1048576) % 2048
    assert(exponent ~= 2047, "non-finite terrain coordinate")
    local mantissa = (hi % 1048576 + lo / 4294967296) / 1048576
    local value = exponent == 0 and mantissa * 2^-1022 or (1 + mantissa) * 2^(exponent - 1023)
    return hi >= 2147483648 and -value or value
end

local function columnKey(x, y)
    return (2*x + 65536) * 131072 + 2*y + 65536
end
G.columnKey = columnKey

local cdx,cdy={1,-1,0,0,1,1,-1,-1},{0,0,1,-1,1,-1,1,-1}
local function readCanonical(st,key)
    local bytes=field(st,"canonical",key)
    if not bytes then return end
    assert(#bytes>=10 and bytes:sub(1,4)=="PCG1" and uint16(bytes,5)==st.c,"invalid canonical terrain page")
    local count=uint32(bytes,7)
    local page={bytes=bytes,offsets={},nodes={},visited={},upper={},sectors={},key=key,weight=#bytes+count*340}
    local ox,oy=floor(key/st.data.ny)*st.c,(key%st.data.ny)*st.c
    local at=11
    for i=1,count do
        work()
        assert(at+11<=#bytes,"truncated canonical floor")
        local cell,layer=uint16(bytes,at),bytes:byte(at+2)
        local id=cell*256+layer
        assert(cell<st.c*st.c and not page.offsets[id] and uint16(bytes,at+9)%32768<32752,"invalid canonical floor")
        page.offsets[id]=at
        if layer>0 then page.upper[cell]=math.max(layer,page.upper[cell] or 0) end
        local last=at+11+2*bytes:byte(at+11)
        assert(last<=#bytes,"truncated canonical links")
        local gx,gy=ox+floor(cell/st.c),oy+cell%st.c
        local sx,sy=floor(gx/8),floor(gy/8)
        local sector=sx*65536+sy
        local exits=page.sectors[sector] or {}
        page.sectors[sector]=exits
        local boundary=gx%8==0 or gx%8==7 or gy%8==0 or gy%8==7
        for p=at+12,last,2 do
            work()
            local d=bytes:byte(p)+1
            assert(d<=8,"invalid canonical direction")
            if boundary then
                local nextSector=floor((gx+cdx[d])/8)*65536+floor((gy+cdy[d])/8)
                if nextSector~=sector then exits[nextSector]=true end
            end
        end
        at=last+1
    end
    assert(at==#bytes+1,"trailing canonical terrain data")
    return page
end

function G.canonicalPage(st,key,load)
    if not key or not (st.data.canonical or st.data.packed and st.data.packed.canonical) then return end
    return st.canonical[key] or load and cached(st,"canonical",key,readCanonical,48*1024*1024)
end

function G.canonicalNode(st,page,cell,layer)
    local wire=cell*256+layer
    local at=page.offsets[wire]
    if not at then return end
    local n=page.nodes[wire]
    if not n then
        local x,y=G.position(st,page.key,cell)
        n={x=x,y=y,z=double(page.bytes,at+3),cell=cell,layer=layer,canonical=page,
            first=at+12,count=page.bytes:byte(at+11),bytes=page.bytes,
            id=-(1+page.key*st.c*st.c*256+wire)}
        page.nodes[wire]=n
        local column=page.visited[cell] or {}
        column[#column+1]=n
        page.visited[cell]=column
    end
    return n
end

local function halfCoordinate(s,p)
    local value=uint32(s,p)
    return (value>=2147483648 and value-4294967296 or value)/2
end

local slopeLimitSquared = math.tan(math.rad(50))^2

-- Most faces in a loaded page never participate in an endpoint or a chord.
-- Build their XY index eagerly, then decode vertical geometry on first use.
function G.prepareFace(page,f)
    if f.nz then return end
    for i=1,3 do
        local v=f[i]
        if not v[3] then v[3]=double(page.bytes,v.offset) end
    end
    local a,b,c=f[1],f[2],f[3]
    local u,v,w=b[1]-a[1],b[2]-a[2],b[3]-a[3]
    local U,V,W=c[1]-a[1],c[2]-a[2],c[3]-a[3]
    local nx,ny,nz=v*W-w*V,w*U-u*W,u*V-v*U
    f.nx,f.ny,f.nz=nx,ny,nz
    f.steep=nx*nx+ny*ny>slopeLimitSquared*nz*nz
    f.low,f.high=math.min(a[3],b[3],c[3]),math.max(a[3],b[3],c[3])
    f.xmin,f.xmax=math.min(a[1],b[1],c[1]),math.max(a[1],b[1],c[1])
    f.ymin,f.ymax=math.min(a[2],b[2],c[2]),math.max(a[2],b[2],c[2])
end

local function readWindow(st, key, s)
    local format=s:sub(1,4)
    assert(format=="SFC1" or format=="SFC2", "unsupported terrain surface")
    local width=format=="SFC2" and 4 or 2
    local coordinate=width==4 and halfCoordinate or int16
    local page = {xmin=int16(s,5), ymin=int16(s,7), xmax=int16(s,9), ymax=int16(s,11),
        columns={}, bins={}, step=2/width,bytes=s}
    -- The format and bounds identify the same window across tile extracts.
    -- Two resolutions covering the same coordinates can have different arcs.
    local windowID = s:sub(1,12)
    local n, nv, nf = uint32(s,13), uint32(s,17), uint32(s,21)
    local at = 25
    assert(page.xmin <= page.xmax and page.ymin <= page.ymax and n*(2*width+11) + nv*24 + nf*13 <= #s-24)
    for i = 1, n do
        work()
        local x,y = coordinate(s,at),coordinate(s,at+width)
        at=at+2*width
        local h, ord, count = double(s,at), s:byte(at+8), uint16(s,at+9)
        assert(x >= page.xmin and x <= page.xmax and y >= page.ymin and y <= page.ymax
            and G.locate(st,x,y) == key, "invalid local terrain node")
        local id = columnKey(x,y)
        local column = page.columns[id] or {}
        assert(ord == #column and at+10+2*count <= #s, "invalid terrain floor ordinal")
        column[ord+1] = {x=x,y=y,z=h,first=at+11,count=count,bytes=s,page=page,
            id=windowID..s:sub(at-2*width,at-1)..string.char(ord),ordinal=ord}
        page.columns[id] = column
        at = at + 11 + 2*count
    end
    assert(at+nv*24+nf*13 == #s+1, "invalid terrain triangle data")
    local vertices = {}
    for i = 1, nv do
        work()
        assert(uint16(s,at+22)%32768 < 32752, "non-finite terrain vertex")
        vertices[i] = {double(s,at),double(s,at+8),offset=at+16}
        at=at+24
    end
    local x0 = st.x0 + floor(key/st.data.ny) * st.c * st.unit
    local y0 = st.y0 + key%st.data.ny * st.c * st.unit
    for i = 1, nf do
        work()
        local kind = s:byte(at)
        local a,b,c = vertices[uint32(s,at+1)+1],vertices[uint32(s,at+5)+1],vertices[uint32(s,at+9)+1]
        assert(kind <= 3 and a and b and c, "invalid terrain triangle")
        at=at+13
        local f={a,b,c,model=kind%2==1,liquid=kind>=2}
        -- The page carries a halo for joins from arbitrary endpoints.
        local left = math.max(x0-2,page.xmin-2,math.min(a[1],b[1],c[1]))
        local right = math.min(x0+st.c*st.unit+2,page.xmax+2,math.max(a[1],b[1],c[1]))
        local bottom = math.max(y0-2,page.ymin-2,math.min(a[2],b[2],c[2]))
        local top = math.min(y0+st.c*st.unit+2,page.ymax+2,math.max(a[2],b[2],c[2]))
        for x=floor(left/4),floor(right/4) do
            for y=floor(bottom/4),floor(top/4) do
                work()
                local id=columnKey(x,y)
                local bin=page.bins[id] or {}
                bin[#bin+1],page.bins[id]=f,bin
            end
        end
    end
    return page
end

local function readSurface(st, key)
    local bytes = field(st, "surface", key)
    if not bytes then return end
    assert(#bytes >= 8 and bytes:sub(1,4) == "SFA1", "unsupported terrain surface atlas")
    local count = uint32(bytes,5)
    assert(count > 0 and count <= (#bytes-8)/28, "invalid terrain window count")
    local atlas, at = {weight=0}, 9
    for i=1,count do
        work()
        local size = uint32(bytes,at)
        assert(size >= 24 and at+3+size <= #bytes, "invalid terrain window length")
        local start = at + 4
        local format = bytes:sub(start, start + 3)
        assert(format == "SFC1" or format == "SFC2", "unsupported terrain surface")
        local n, nv, nf = uint32(bytes,start+12), uint32(bytes,start+16), uint32(bytes,start+20)
        local step = format == "SFC2" and .5 or 1
        assert(n * (step == .5 and 19 or 15) + nv * 24 + nf * 13 <= size - 24, "invalid terrain surface size")
        local window = {xmin=int16(bytes,start+4), ymin=int16(bytes,start+6),
            xmax=int16(bytes,start+8), ymax=int16(bytes,start+10), step=step,
            bytes=bytes, first=start, last=start+size-1}
        assert(window.xmin <= window.xmax and window.ymin <= window.ymax, "invalid terrain surface bounds")
        atlas[i], atlas.weight = window, atlas.weight + 2*size + n*260 + nf*380 + nv*120
        at = at+4+size
    end
    assert(at == #bytes+1, "trailing terrain atlas data")
    return atlas
end

function G.surfaceAtlas(st, key, load)
    if not (st.data.packed and st.data.packed.surface or st.data.surface) then return end
    if not key then return end
    local job=load and runtime.active
    local retained=job and job.surfacePages
    if retained and retained.owner==st and retained[key] then return retained[key] end
    local page=st.surface[key]
    -- Keep both detailed endpoint atlases available to the passive cursor
    -- when a route crosses a tile boundary and its job releases the pages.
    if not page and load then page=cached(st,"surface",key,readSurface,128*1024*1024) end
    if job and page then
        if not retained or retained.owner~=st or retained.count>=4 then
            retained={owner=st,count=0}
            job.surfacePages=retained
        end
        retained[key],retained.count=page,retained.count+1
    end
    return page
end

function G.surfaceWindow(st, key, entry, load)
    if not entry.page and load then
        local window = readWindow(st, key, entry.bytes:sub(entry.first, entry.last))
        entry.page = entry.page or window
    end
    return entry.page
end

function G.sameWindow(a,b)
    return a and b and a.step==b.step and a.xmin==b.xmin and a.xmax==b.xmax and a.ymin==b.ymin and a.ymax==b.ymax
end

function G.surfacePage(st, x, y, load, source)
    local key=G.locate(st,x,y)
    local page=G.surfaceAtlas(st,key,load)
    if page then
        local best
        for _, window in ipairs(page) do
            if x>=window.xmin and x<=window.xmax and y>=window.ymin and y<=window.ymax
                and (not source or G.sameWindow(source,window)) and (not best or window.step<best.step) then
                best=window
            end
        end
        if best then
            local window = G.surfaceWindow(st,key,best,load)
            return window, true, not window
        end
    elseif not load and key then
        local data = st.data
        local packed = data.packed and data.packed.surface
        if packed and packed[key+1] or data.surface and data.surface[key+1] then
            return nil, false, true
        end
    end
end

local function runs(s, limit)
    local values, length, last = {}, 0
    for p = 1, #s do
        work()
        local symbol = digits[s:byte(p)]
        local count = 1
        if symbol >= 48 then
            count = symbol - 47
            assert(last, "terrain run without value")
        else
            last = symbol
        end
        assert(length + count <= limit, "terrain run overflow")
        for i = length, length + count - 1 do
            values[i] = last
        end
        length = length + count
    end
    return values, length
end

local function heights(t, s, c, step, width, bias)
    local p, remaining, delta, last = 1, 0, nil, 0
    for cell = 0, c * c - 1 do
        work()
        if t.bits[cell] >= 16 then
            local base = (cell % c > 0 and t.z[cell - 1]) or t.z[cell - c] or last
            if remaining == 0 then
                local v = digits[s:byte(p)]
                p = p + 1
                if v == 47 then
                    base, delta, p = (integer(s, p, width) - bias) * step, nil, p + width
                elseif v < 47 then
                    delta = (v - 23) * step
                else
                    assert(delta, "invalid height repeat")
                    remaining = v - 48
                end
            else
                remaining = remaining - 1
            end
            last = base + (delta or 0)
            t.z[cell] = last
        end
    end
    assert(p == #s + 1 and remaining == 0, "unused heights")
end

-- Extra storeys carry absolute integer yards, independent of the base height quantum.
local function floors(t, s, count, width, bias)
    if not s then return count end
    local p = 4
    local nextNode = count
    for _ = 1, integer(s, 1, 3) do
        work()
        local cell, layers = integer(s, p, 3), digits[s:byte(p + 3)]
        p = p + 4
        assert(cell < count and not t.layers[cell])
        local list = {}
        t.layers[cell] = list
        for i = 1, layers do
            work()
            local node = nextNode
            nextNode = node + 1
            list[i], t.cell[node] = node, cell
            local value = digits[s:byte(p)]
            assert(value == 1 or value == 2)
            t.bits[node] = value * 16
            t.z[node] = integer(s, p + 1, width) - bias
            t.steps[node] = integer(s, p + 1 + width, 2)
            p = p + 3 + width
        end
    end
    local links = integer(s, p, 3)
    p = p + 3
    for _ = 1, links do
        work()
        local node, dir, layer = integer(s, p, 3), digits[s:byte(p + 3)], digits[s:byte(p + 4)]
        p = p + 5
        assert(node < nextNode and dir < 8 and layer)
        local key = node * 8 + dir
        local list = t.links[key] or {}
        list[#list + 1], t.links[key] = layer, list
    end
    assert(p == #s + 1, "unused floor records")
    return nextNode
end

local function validateRecords(bytes, width)
    assert(#bytes % width == 0, "incomplete terrain records")
    -- Lua string.find runs to completion before the worker can suspend.
    -- Bound each native scan, including on pages with no invalid byte.
    for p = 1, #bytes, 512 do
        work()
        assert(not bytes:sub(p, p + 511):find("[^A-Za-z0-9+/]"), "invalid terrain record character")
    end
end

local function readGrid(st, k, topologyOnly)
    local grid = field(st, "grid", k)
    if not grid then return end
    local c = st.c
    local bits, n = runs(grid, c * c)
    assert(n == c * c, "short terrain grid")
    local t = { bits = bits, z = {}, layers = {}, steps = {}, links = {}, cell = {} }
    local heightWidth = st.data.heightDigits or 2
    local heightBias = heightWidth == 3 and 131072 or 2048
    heights(t, assert(field(st, "height", k)), c, st.data.zstep, heightWidth, heightBias)
    local size = floors(t, field(st, "floor", k), n, heightWidth, heightBias)
    if topologyOnly then return t end
    local clearance = field(st, "clearance", k)
    if clearance then
        assert(#clearance % 6 == 0, "incomplete terrain clearance mask")
        t.clearance = {}
        for p = 1, #clearance, 6 do
            work()
            local node, mask = integer(clearance, p, 3), integer(clearance, p + 3, 3)
            assert(node < size and t.z[node] and mask <= 65535 and t.clearance[node] == nil,
                "invalid terrain clearance mask")
            t.clearance[node] = mask
        end
    end
    local sub = field(st, "subclearance", k)
    if sub then
        validateRecords(sub, 51)
        t.subclearance, t.subBytes = {}, sub
        for p = 1, #sub, 51 do
            work()
            local node = integer(sub, p, 3)
            assert(node < size and t.z[node] and not t.subclearance[node], "invalid terrain subcell surface")
            for first = p + 3, p + 48, 3 do
                assert(digits[sub:byte(first)] < 16, "invalid terrain subcell mask")
            end
            t.subclearance[node] = p + 3
        end
    end
    local support = field(st, "support", k)
    if support then
        validateRecords(support, 21)
        t.support, t.supportBytes = {}, support
        for p = 1, #support, 21 do
            work()
            local node = integer(support, p, 3)
            assert(node < size and t.z[node] and not t.support[node] and digits[support:byte(p + 3)] < 16)
            t.support[node] = p + 3
        end
    end
    t.class = runs(field(st, "class", k) or "", size)
    t.weight = size * 60 + (clearance and #clearance * 6 or 0) + (sub and #sub * 2 or 0)
        + (support and #support * 12 or 0)
    return t
end

-- PCG1 supplies the swept-body proof. Its independent topology check needs
-- the grid, heights, floor links and portal graph of the same generation.
-- Keep these light readers in the ongoing search only.
function G.canonicalTopology(st,k,tiles)
    local t=tiles[k]
    if not t then
        t=st.grid[k] or readGrid(st,k,true)
        if t then
            local slot=tiles.cursor or 1
            local order=tiles.order or {}
            if order[slot] then tiles[order[slot]]=nil end
            order[slot],tiles[k]=k,t
            tiles.order,tiles.cursor=order,slot%12+1
        end
    end
    return t
end

function G.submask(tile, offset, index)
    return integer(tile.subBytes, offset + 3 * index, 3)
end

function G.fan(tile, node)
    local offset = tile.support and tile.support[node]
    if type(offset) ~= "number" then return offset end
    local bytes = tile.supportBytes
    local fan = {occupied = integer(bytes, offset, 3)}
    for vertex = 1, 5 do fan[vertex] = (integer(bytes, offset + vertex * 3, 3) - 131072) / 32 end
    tile.support[node] = fan
    return fan
end

function G.fanHeight(fan, x, y)
    -- Barycentric interpolation in the triangle between the centre and
    -- the two corners on the side containing this point.
    if math.abs(x) >= math.abs(y) then
        if x >= 0 then return (1 - 2*x)*fan[1] + (x-y)*fan[3] + (x+y)*fan[4] end
        return (1 + 2*x)*fan[1] + (-x-y)*fan[2] + (y-x)*fan[5]
    end
    if y >= 0 then return (1 - 2*y)*fan[1] + (y+x)*fan[4] + (y-x)*fan[5] end
    return (1 + 2*y)*fan[1] + (-y-x)*fan[2] + (x-y)*fan[3]
end

function G.gradient(fan, x, y)
    if math.abs(x) >= math.abs(y) then
        if x >= 0 then return fan[3]+fan[4]-2*fan[1], fan[4]-fan[3] end
        return 2*fan[1]-fan[2]-fan[5], fan[5]-fan[2]
    end
    if y >= 0 then return fan[4]-fan[5], fan[4]+fan[5]-2*fan[1] end
    return fan[3]-fan[2], 2*fan[1]-fan[2]-fan[3]
end

function G.surfaceHeight(st, tile, node, x, y)
    local fan = G.fan(tile, node)
    if not fan then return tile.z[node] end
    return G.fanHeight(fan, (x - st.x0) / st.unit % 1 - 0.5, (y - st.y0) / st.unit % 1 - 0.5)
end

function G.centerHeight(tile, node)
    local fan = G.fan(tile, node)
    return fan and fan[1] or tile.z[node]
end

function G.endpoint(st, tile, cell, height, x, y)
    if not tile.support then return G.closest(tile, cell, height) end
    local best, gap = nil, math.huge
    local layers = tile.layers[cell]
    for i = 0, layers and #layers or 0 do
        local node = i == 0 and cell or layers[i]
        if tile.z[node] then
            local supportZ = G.surfaceHeight(st, tile, node, x, y)
            local diff = math.abs((height or supportZ) - supportZ)
            if diff < gap then best, gap = node, diff end
        end
    end
    return best, gap
end

function G.grid(st, k)
    return cached(st, "grid", k, readGrid, 8 * 1024 * 1024)
end

local function readGraph(st, k)
    local s = field(st, "graph", k)
    if not s then return end
    local n = integer(s, 1, 2)
    local p, edge = 3, 3 + 7 * n
    local g = { nodes = {}, bySurface = {}, bytes = s, weight = #s + n * 220 }
    for i = 1, n do
        work()
        local cell, layer, degree = integer(s, p, 3), integer(s, p + 3, 1), integer(s, p + 6, 1)
        assert(cell < st.c * st.c)
        g.nodes[i] = { cell = cell, layer = layer, first = edge, degree = degree }
        g.bySurface[cell * 64 + layer] = g.nodes[i]
        p, edge = p + 7, edge + 14 * degree
    end
    assert(edge == #s + 1, "incorrect terrain graph size")
    return g
end

function G.graphPage(st, k)
    return cached(st, "graph", k, readGraph, 16 * 1024 * 1024)
end

-- A reverse row needs only the neighbouring graph pages. Costs and
-- surface grids are immaterial to a directed disconnection proof.
function G.incoming(st, key)
    local result = {}
    local x, y = floor(key / st.data.ny), key % st.data.ny
    for xx = math.max(0, x - 1), math.min(st.data.nx - 1, x + 1) do
        for yy = math.max(0, y - 1), math.min(st.data.ny - 1, y + 1) do
            local source = xx * st.data.ny + yy
            local page = G.graphPage(st, source)
            local direction = (x - xx + 1) * 3 + y - yy + 1
            for i = 1, page and #page.nodes or 0 do
                work()
                local node = page.nodes[i]
                for n = 0, node.degree - 1 do
                    work()
                    local p = node.first + 14 * n
                    local encoded = digits[page.bytes:byte(p)]
                    assert(encoded and encoded < 9, "invalid terrain direction")
                    if encoded == direction then
                        local target = integer(page.bytes, p + 1, 2) + 1
                        assert(target < 4096, "invalid incoming terrain entrance")
                        local links = result[target] or {}
                        links[#links + 1] = source * 4096 + i
                        result[target] = links
                    end
                end
            end
        end
    end
    return result
end

function G.edge(st, k, bytes, p, profile)
    local offset, a, b = bytes:byte(p, p + 2)
    local index = 1 + digits[a] * 64 + digits[b]
    assert(index < 4096, "invalid terrain entrance index")
    local price = profile == "Alliance" and 3 or profile == "Horde" and 6 or 9
    local cost = integer(bytes, p + price, 3)
    if offset == 69 then return k, index, cost end -- Base64 E: edge stays on this page.
    offset = digits[offset]
    local x, y = floor(k / st.data.ny) + floor(offset / 3) - 1, k % st.data.ny + offset % 3 - 1
    assert(offset < 9 and x >= 0 and x < st.data.nx and y >= 0 and y < st.data.ny)
    return x * st.data.ny + y, index, cost
end

function G.layer(t, cell, layer)
    if layer == 0 then return t.z[cell] and cell end
    return t.layers[cell] and t.layers[cell][layer]
end

function G.uniqueHeight(t, cell)
    local layers = t.layers[cell]
    if not layers or #layers == 0 then return t.z[cell] end
    if #layers == 1 and t.z[cell] == nil then return t.z[layers[1]] end
end

function G.closest(t, cell, height)
    local heights = t.z
    local base = heights[cell]
    local best = base and cell
    local gap = base and math.abs(base - (height or base)) or math.huge
    local layers = t.layers[cell]
    if layers and height and gap > 0 then
        for index = 1, #layers do
            local node = layers[index]
            local dz = math.abs(heights[node] - height)
            if dz < gap then
                best, gap = node, dz
                if gap == 0 then break end
            end
        end
    end
    return best, gap
end
