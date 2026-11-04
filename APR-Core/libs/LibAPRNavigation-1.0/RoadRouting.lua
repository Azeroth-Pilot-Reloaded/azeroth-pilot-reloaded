-- Incremental routing over declared road polylines. This is not a native mesh.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("road-routing", 4) then return end
local Instance, Roads = Lib.Instance, Lib.Roads
local Finite, EPSILON, BUCKET, JOIN_BUCKET = Roads.Finite, 1e-7, 256, 32
local Job = {}; Job.__index = Job
local function Key(x, y) return tostring(x) .. ":" .. tostring(y) end
local function Distance(x1, y1, x2, y2) return math.sqrt((x2-x1)^2 + (y2-y1)^2) end
local function Breather()
    local work = 0
    return function() work = work + 1; if work % 32 == 0 then coroutine.yield() end end
end
local function AddArc(graph, node, edge, reverse)
    local list = graph.adj[node] or {}; graph.adj[node] = list
    list[#list + 1], list[#list + 2] = edge, reverse == true
end
local function Height(edge, along)
    if edge.heights then
        for i=1,#edge.cumulative-1 do
            if along<=edge.cumulative[i+1] then
                local first,last=edge.heights[i],edge.heights[i+1]
                if not Finite(first) or not Finite(last) then return nil end
                local length=edge.cumulative[i+1]-edge.cumulative[i]
                return first+(last-first)*(length>0 and (along-edge.cumulative[i])/length or 0)
            end
        end
    end
    if edge.z1 and edge.z2 then
        return edge.z1 + (edge.z2-edge.z1) * (edge.horizontal > 0 and along/edge.horizontal or 0)
    end
end
local function Point(graph, x, y, z)
    return { x=x, y=y, z=z, instanceID=graph.world, roadLevel=graph.level }
end
local function EdgePoint(graph, edge, index)
    local z=edge.heights and edge.heights[index]
    if z==false then z=nil end
    if z==nil then z=index==1 and edge.z1 or index==#edge.cumulative and edge.z2 or Height(edge,edge.cumulative[index]) end
    return Point(graph, edge.points[index*2-1], edge.points[index*2], z)
end
local function IndexEdge(graph, edge, breathe)
    for i=1,#edge.points-3,2 do
        breathe()
        local x1,y1,x2,y2=edge.points[i],edge.points[i+1],edge.points[i+2],edge.points[i+3]
        for x=math.floor(math.min(x1,x2)/BUCKET),math.floor(math.max(x1,x2)/BUCKET) do
            for y=math.floor(math.min(y1,y2)/BUCKET),math.floor(math.max(y1,y2)/BUCKET) do
                local key=Key(x,y); local list=graph.index[key] or {}; graph.index[key]=list
                list[#list+1],list[#list+2]=edge,i
            end
        end
        if not edge.group.cave and not edge.group.indoor then
            -- Small segment boxes cover every crossed cell without filling
            -- the quadratic bounding rectangle of a long diagonal road.
            local dx,dy=x2-x1,y2-y1
            local chunks=math.max(1,math.ceil(math.max(math.abs(dx),math.abs(dy))/JOIN_BUCKET))
            for chunk=1,chunks do
                local ax,ay=x1+dx*(chunk-1)/chunks,y1+dy*(chunk-1)/chunks
                local bx,by=x1+dx*chunk/chunks,y1+dy*chunk/chunks
                for x=math.floor((math.min(ax,bx)-EPSILON)/JOIN_BUCKET),math.floor((math.max(ax,bx)+EPSILON)/JOIN_BUCKET) do
                    for y=math.floor((math.min(ay,by)-EPSILON)/JOIN_BUCKET),math.floor((math.max(ay,by)+EPSILON)/JOIN_BUCKET) do
                        breathe()
                        local key=Key(x,y);local joins=graph.joinIndex[key] or {};graph.joinIndex[key]=joins
                        if joins[#joins-1]~=edge or joins[#joins]~=i then
                            joins[#joins+1],joins[#joins+2]=edge,i
                        end
                    end
                end
            end
        end
    end
end
local function ConnectJoins(record,level,graph,joins,breathe)
    -- Source joins identify doors/mouths. Connect them to the nearest earlier
    -- declared road within the source format's twelve-yard join tolerance.
    for _,join in ipairs(joins) do
        breathe()
        local node,best=graph.nodes[join.node],nil
        local radius=node.group.joinRadius
        local bx,by=math.floor(node.x/BUCKET),math.floor(node.y/BUCKET)
        local orderMinX=math.min(bx-1,math.floor((node.x-radius)/BUCKET))
        local orderMinY=math.min(by-1,math.floor((node.y-radius)/BUCKET))
        for x=math.floor((node.x-radius)/JOIN_BUCKET),math.floor((node.x+radius)/JOIN_BUCKET) do
            for y=math.floor((node.y-radius)/JOIN_BUCKET),math.floor((node.y+radius)/JOIN_BUCKET) do
            local bucket=graph.joinIndex[Key(x,y)] or {}
            for i=1,#bucket,2 do
                breathe()
                local edge,p=bucket[i],bucket[i+1]
                if edge.group.id<join.group and not edge.blocked then
                    local ax,ay,dx,dy=edge.points[p],edge.points[p+1],edge.points[p+2]-edge.points[p],edge.points[p+3]-edge.points[p+1]
                    local length2=dx*dx+dy*dy
                    local t=length2>0 and math.max(0,math.min(1,((node.x-ax)*dx+(node.y-ay)*dy)/length2)) or 0
                    local px,py=ax+t*dx,ay+t*dy;local distance=Distance(node.x,node.y,px,py)
                    -- Keep the previous coarse-cell traversal's tie order,
                    -- even though the lookup now visits only a door's radius.
                    local orderX=math.max(orderMinX,math.floor(math.min(ax,ax+dx)/BUCKET))
                    local orderY=math.max(orderMinY,math.floor(math.min(ay,ay+dy)/BUCKET))
                    local earlier=best and (orderX<best.orderX or orderX==best.orderX and
                        (orderY<best.orderY or orderY==best.orderY and
                        (edge.id<best.edge.id or edge.id==best.edge.id and p<best.p)))
                    if distance<=radius and (not best or distance<best.distance or distance==best.distance and earlier) then
                        best={edge=edge,p=p,t=t,x=px,y=py,distance=distance,orderX=orderX,orderY=orderY,
                            along=edge.cumulative[(p+1)/2]+t*math.sqrt(length2)}
                    end
                end
            end
        end end
        if best then
            local edge=best.edge
            local entry=Point(graph,node.x,node.y,node.z)
            local projection=Point(graph,best.x,best.y,Height(edge,best.along))
            local crossed=Roads.WallHit(record,level,entry,projection,breathe)
            if entry.z and projection.z and math.abs(entry.z-projection.z)>5 then crossed=true end
            local cost=not crossed and (best.distance<=EPSILON and 0 or Roads.SegmentCost(record,level,entry,projection,breathe))
            -- A declared source doorway can cross a coarse terrain cell which
            -- says steep/unknown. Its source topology authorizes this short
            -- connector; an explicit wall still rejects it.
            if not crossed and cost==nil then cost=best.distance end
            if cost then
                -- Virtual junction arcs preserve the earlier road's full shape.
                local fraction=edge.horizontal>0 and best.along/edge.horizontal or 0
                local left={a=join.node,b=edge.a,join=best,joinSide="a",length=cost+edge.length*fraction,group=node.group}
                local right={a=join.node,b=edge.b,join=best,joinSide="b",length=cost+edge.length*(1-fraction),group=node.group}
                if not edge.drop and not edge.forwardOnly then AddArc(graph,join.node,left,false) end
                AddArc(graph,edge.a,left,true)
                AddArc(graph,join.node,right,false)
                if not edge.drop and not edge.forwardOnly then AddArc(graph,edge.b,right,true) end
            end
        end
    end
end
local function FinishGraph(record,level,graph,joins,breathe)
    -- Validate every declaration before a direct path may be published, but
    -- leave continent-wide collision, indexes and joins dormant until needed.
    graph.topologyReady,graph.phase=true,"compile_graph"
    coroutine.yield()
    for _,edge in ipairs(graph.edges) do
        breathe()
        if not edge.group.indoor then
            for i=1,#edge.points-3,2 do
                breathe()
                if Roads.WallHit(record,level,EdgePoint(graph,edge,(i+1)/2),EdgePoint(graph,edge,(i+3)/2),breathe) then
                    edge.blocked=true;break
                end
            end
        end
        if not edge.blocked then
            AddArc(graph,edge.a,edge,false)
            if not edge.drop and not edge.forwardOnly then AddArc(graph,edge.b,edge,true) end
        end
        IndexEdge(graph,edge,breathe)
    end
    ConnectJoins(record,level,graph,joins,breathe)
    graph.ready,graph.phase=true,"ready"
end
local function CompileNative(record,level,graph)
    local network,breathe=record.data.networks[level],Breather()
    local nodeIDs,sectionIDs,edgeIDs,groups,joins={},{},{},{},{}
    for index,section in ipairs(network.sections) do
        breathe()
        if type(section.id)~="string" or sectionIDs[section.id] then error("invalid_road_section_id") end
        if section.joinRadius~=nil and not Finite(section.joinRadius) then error("invalid_road_join_radius") end
        sectionIDs[section.id]=true
        local group={id=index,name=section.id,indoor=section.kind=="building",cave=section.kind=="cave",
            capital=section.kind=="city",joinRadius=section.joinRadius or 12,joins={}}
        groups[index]=group
        for _,raw in ipairs(section.nodes or {}) do
            breathe()
            if type(raw.id)~="string" or raw.id=="" or nodeIDs[raw.id] then error("invalid_road_node_id") end
            if not Finite(raw.x) or not Finite(raw.y) or raw.z~=nil and not Finite(raw.z) then error("invalid_road_node") end
            local node={id=raw.id,x=raw.x,y=raw.y,z=raw.z,group=group}
            graph.nodes[#graph.nodes+1]=node
            nodeIDs[raw.id]=#graph.nodes
        end
    end
    for index,section in ipairs(network.sections) do
        local group=groups[index]
        for _,id in ipairs(section.joins or {}) do
            breathe()
            local node=nodeIDs[id]
            if not node or graph.nodes[node].group~=group then error("invalid_road_join") end
            graph.nodes[node].join=true
            joins[#joins+1]={node=node,group=index}
        end
        for _,raw in ipairs(section.edges or {}) do
            breathe()
            if type(raw.id)~="string" or raw.id=="" or edgeIDs[raw.id] then error("invalid_road_edge_id") end
            edgeIDs[raw.id]=true
            local a,b=nodeIDs[raw.from],nodeIDs[raw.to]
            local from,to=graph.nodes[a],graph.nodes[b]
            if not from or not to then error("unknown_road_node") end
            local points,heights,cumulative,total,length={},{},{0},0,0
            local function add(point)
                if not Finite(point.x) or not Finite(point.y) or point.z~=nil and not Finite(point.z) then error("invalid_road_polyline") end
                local count=#points/2
                if count>0 then
                    local dx,dy=point.x-points[#points-1],point.y-points[#points]
                    local previous=heights[count]
                    local dz=Finite(previous) and point.z and point.z-previous or 0
                    total=total+math.sqrt(dx*dx+dy*dy)
                    length=length+math.sqrt(dx*dx+dy*dy+dz*dz)
                    cumulative[#cumulative+1]=total
                end
                points[#points+1],points[#points+2]=point.x,point.y
                heights[#heights+1]=point.z or false
            end
            local declared=raw.points or {}
            if #declared<2 then error("invalid_road_polyline") end
            local first,last=declared[1],declared[#declared]
            if first.x~=from.x or first.y~=from.y or last.x~=to.x or last.y~=to.y then error("road_polyline_endpoint_mismatch") end
            for _,point in ipairs(declared) do breathe();add(point) end
            local kind=raw.kind or "road"
            if kind~="road" and kind~="stairs" and kind~="elevator" and kind~="swim" then error("invalid_road_edge_kind") end
            if raw.costDistance~=nil then
                if not Finite(raw.costDistance) or raw.costDistance<0 then error("invalid_road_cost") end
                length=math.max(length,raw.costDistance)
            end
            if kind=="swim" then length=length*1.5 end
            if raw.dropHeight~=nil and (not Finite(raw.dropHeight) or raw.dropHeight<0) then error("invalid_road_drop") end
            local edge={id=#graph.edges+1,name=raw.id,a=a,b=b,points=points,heights=heights,cumulative=cumulative,
                horizontal=total,length=length,z1=from.z,z2=to.z,group=group,kind=kind,drop=raw.dropHeight,forwardOnly=raw.bidirectional==false}
            graph.edges[#graph.edges+1]=edge
        end
    end
    FinishGraph(record,level,graph,joins,breathe)
end
local function Compile(record, level, graph)
    if record.data.format==2 then return CompileNative(record,level,graph) end
    local data, breathe = record.data, Breather()
    local sources={data.roads[level]}
    for _,extra in ipairs(data.overlays and data.overlays[level] or {}) do sources[#sources+1]=extra end
    -- The identity set roadTracks marks edits already baked into roads/walls.
    -- It has no coordinates of its own. Floor tracks are intentionally kept
    -- separately by the source to preserve every recorded height and stair.
    for _,track in ipairs(data.floorTracks and data.floorTracks[level] or {}) do
        breathe()
        if (track.op==nil or track.op=="add") and type(track.pts)=="table" and #track.pts>=4 then
            local source={n={},z={},e={},joins={1,#track.pts/2},joinRadius=25,worldHeights=true,
                indoor=track.indoors==true,floorTrack=true}
            for i=1,#track.pts do breathe();source.n[i]=track.pts[i] end
            for i=1,#track.pts/2 do
                breathe();source.z[i]=track.zs and track.zs[i] or false
                if i>1 then source.e[#source.e+1]={i-1,i,0,track.stair and 6 or 2} end
            end
            sources[#sources+1]=source
        end
    end
    local levelData=data.levels and data.levels[level]
    local joins={}
    for group,source in ipairs(sources) do
        if type(source.n)~="table" or type(source.e)~="table" or #source.n%2~=0 then error("invalid_road_graph") end
        if source.joinRadius~=nil and not Finite(source.joinRadius) then error("invalid_road_join_radius") end
        local offset=#graph.nodes
        local groupInfo={id=group,indoor=source.indoor==true,cave=source.cave==true,capital=source.capital,
            joins={},joinRadius=source.joinRadius or 12,floorTrack=source.floorTrack==true}
        for _,id in ipairs(source.joins or {}) do groupInfo.joins[id]=true end
        for i=1,#source.n,2 do
            breathe()
            local x,y=source.n[i],source.n[i+1]
            if not Finite(x) or not Finite(y) then error("invalid_road_node") end
            local id=(i+1)/2
            local z=source.z and source.z[id] or source.nz and source.nz[id]
            if z==false then z=nil end
            if z==0 and source.nz then z=nil end
            if z~=nil and not Finite(z) then error("invalid_road_height") end
            if z and source.z and not source.worldHeights and levelData and Finite(levelData.zoff) then z=z+levelData.zoff end
            graph.nodes[#graph.nodes+1]={x=x,y=y,z=z,group=groupInfo,join=groupInfo.joins[id]}
        end
        for index,raw in ipairs(source.e) do
            breathe()
            if type(raw)~="table" or not Finite(raw[1]) or not Finite(raw[2])
                or raw[1]%1~=0 or raw[2]%1~=0 or raw[1]<1 or raw[2]<1 then error("invalid_road_edge") end
            local from,to=graph.nodes[offset+raw[1]],graph.nodes[offset+raw[2]]
            if not from or not to or raw[1]>#source.n/2 or raw[2]>#source.n/2 then error("unknown_road_node") end
            local points=Roads.Unpack(raw,source.n)
            if not points or #points%2~=0 then error("invalid_road_polyline") end
            if #points<2 then points={from.x,from.y} end
            if points[1]~=from.x or points[2]~=from.y then table.insert(points,1,from.y);table.insert(points,1,from.x) end
            if points[#points-1]~=to.x or points[#points]~=to.y then points[#points+1],points[#points+2]=to.x,to.y end
            local cumulative,total={0},0
            for i=1,#points-3,2 do
                breathe()
                if not Finite(points[i]) or not Finite(points[i+1]) or not Finite(points[i+2]) or not Finite(points[i+3]) then error("invalid_road_polyline") end
                total=total+Distance(points[i],points[i+1],points[i+2],points[i+3]);cumulative[#cumulative+1]=total
            end
            local dz=from.z and to.z and to.z-from.z or 0
            local length=math.sqrt(total*total+dz*dz)
            -- Lifts carry the source's equivalent travel cost, never zero XY.
            if raw[4]==5 and Finite(raw[3]) then length=math.max(length,raw[3]) end
            if raw[4]==7 then length=length*1.5 end
            local drop=source.drops and source.drops[index] or group==1 and data.drops and data.drops[level] and data.drops[level][index]
            local edge={a=offset+raw[1],b=offset+raw[2],points=points,cumulative=cumulative,horizontal=total,
                length=length,z1=from.z,z2=to.z,group=groupInfo,source=raw[4],drop=drop,id=#graph.edges+1}
            graph.edges[#graph.edges+1]=edge
        end
        for _,id in ipairs(source.joins or {}) do
            if graph.nodes[offset+id] then joins[#joins+1]={node=offset+id,group=group} end
        end
    end
    FinishGraph(record,level,graph,joins,breathe)
end
local function Graph(record,level)
    local graph=record.graphs[level]
    if not graph then
        local metadata=record.data.networks and record.data.networks[level] or record.data.levels and record.data.levels[level]
        graph={level=level,world=metadata and (metadata.instanceID or metadata.base) or level,
            phase="compile_topology",nodes={},edges={},adj={},index={},joinIndex={}}
        graph.co=coroutine.create(function() Compile(record,level,graph) end)
        record.graphs[level]=graph
    end
    return graph
end
local function Project(edge,p,point)
    local x,y=edge.points[p],edge.points[p+1]
    local dx,dy=edge.points[p+2]-x,edge.points[p+3]-y
    local squared=dx*dx+dy*dy
    local t=squared>0 and math.max(0,math.min(1,((point.x-x)*dx+(point.y-y)*dy)/squared)) or 0
    local px,py=x+t*dx,y+t*dy
    local along=edge.cumulative[(p+1)/2]+t*math.sqrt(squared)
    local fraction=edge.horizontal>0 and along/edge.horizontal or 0
    local z,ambiguous=Height(edge,along),nil
    if edge.horizontal==0 and edge.z1 and edge.z2 and edge.z1~=edge.z2 then
        local observed=Roads.Height(point)
        if observed then fraction=math.max(0,math.min(1,(observed-edge.z1)/(edge.z2-edge.z1)))
        else ambiguous=true end
        z=edge.z1+fraction*(edge.z2-edge.z1)
    end
    return {edge=edge,p=p,t=t,x=px,y=py,distance=Distance(point.x,point.y,px,py),along=along,z=z,fraction=fraction,ambiguous=ambiguous}
end
local function Allowed(edge,request)
    return not edge.blocked and (not edge.drop or edge.drop <= (request.maxDrop or 0))
end
local function Candidates(job,point,breathe)
    local graph,request=job.graph,job.request
    local radius=Finite(request.roadAttachmentRadius) and math.max(0,request.roadAttachmentRadius) or 1000
    local seen,candidates={},{}
    for x=math.floor((point.x-radius)/BUCKET),math.floor((point.x+radius)/BUCKET) do
        for y=math.floor((point.y-radius)/BUCKET),math.floor((point.y+radius)/BUCKET) do
            breathe()
            local bucket=graph.index[Key(x,y)] or {}
            for i=1,#bucket,2 do
                breathe()
                local edge,p=bucket[i],bucket[i+1]
                local key=tostring(edge.id)..":"..p
                if not seen[key] and Allowed(edge,request) then
                    seen[key]=true
                    local candidate=Project(edge,p,point)
                    local z=candidate.z
                    local observed=Roads.Height(point)
                    local floorOK=not observed or not z or math.abs(observed-z)<= (request.roadHeightTolerance or 5)
                    local internal=edge.group.indoor or edge.group.cave and not edge.group.capital
                    local outsideOK=not internal or point.indoors==true or observed or candidate.distance<=EPSILON
                        or graph.nodes[edge.a].join or graph.nodes[edge.b].join
                    if candidate.distance<=radius and floorOK and outsideOK then candidates[#candidates+1]=candidate end
                end
            end
        end
    end
    local result,reason,nearHeight,ambiguous,positions={},nil,nil,false,{}
    for _,candidate in ipairs(candidates) do
        breathe()
        local projection=Point(graph,candidate.x,candidate.y,candidate.z)
        local cost,why
        local key=tostring(candidate.edge.id)..":"..candidate.x..":"..candidate.y..":"..tostring(candidate.z)
        if not positions[key] then
            positions[key]=true
            if candidate.distance<=EPSILON then cost=0
            else cost,why=Roads.SegmentCost(job.record,graph.level,point,projection,breathe) end
        end
        if cost~=nil then
            candidate.cost=cost;result[#result+1]=candidate
            if candidate.ambiguous and candidate.distance<=4 then ambiguous=true end
            if not Roads.Height(point) and candidate.distance<=4 and candidate.z then
                if nearHeight and math.abs(nearHeight-candidate.z)>1 then ambiguous=true end
                nearHeight=nearHeight or candidate.z
            end
        else reason=reason or why end
    end
    if ambiguous then return nil,"road_floor_unknown" end
    return result,reason
end
local function Push(heap,node,cost)
    local index=#heap+1
    while index>1 do
        local parent=math.floor(index/2)
        if heap[parent][2]<=cost then break end
        heap[index]=heap[parent];index=parent
    end
    heap[index]={node,cost}
end
local function Pop(heap)
    local top,last=heap[1],table.remove(heap)
    if #heap>0 then
        local index=1
        while index*2<=#heap do
            local child=index*2
            if child<#heap and heap[child+1][2]<heap[child][2] then child=child+1 end
            if last[2]<=heap[child][2] then break end
            heap[index]=heap[child];index=child
        end
        heap[index]=last
    end
    return top
end
local function Append(out,point)
    local previous=out[#out]
    if not previous or previous.x~=point.x or previous.y~=point.y or previous.z~=point.z then out[#out+1]=point end
end
local function Along(graph,edge,first,last,out,breathe)
    local function at(along)
        for i=1,#edge.cumulative-1 do
            breathe()
            local a,b=edge.cumulative[i],edge.cumulative[i+1]
            if along<=b+EPSILON then
                local t=b>a and math.max(0,math.min(1,(along-a)/(b-a))) or 0
                return Point(graph,edge.points[2*i-1]+t*(edge.points[2*i+1]-edge.points[2*i-1]),
                    edge.points[2*i]+t*(edge.points[2*i+2]-edge.points[2*i]),Height(edge,along))
            end
        end
        return EdgePoint(graph,edge,#edge.cumulative)
    end
    Append(out,at(first))
    if first<=last then
        for i=2,#edge.cumulative-1 do breathe();if edge.cumulative[i]>first and edge.cumulative[i]<last then Append(out,EdgePoint(graph,edge,i)) end end
    else
        for i=#edge.cumulative-1,2,-1 do breathe();if edge.cumulative[i]<first and edge.cumulative[i]>last then Append(out,EdgePoint(graph,edge,i)) end end
    end
    Append(out,at(last))
end
local function EdgePath(graph,edge,reverse,out,breathe)
    if edge.join then
        local projection,road=edge.join,edge.join.edge
        local node=graph.nodes[edge.a]
        if not reverse then Append(out,Point(graph,node.x,node.y,node.z)) end
        local endpoint=edge.joinSide=="a" and 0 or road.horizontal
        Along(graph,road,reverse and endpoint or projection.along,reverse and projection.along or endpoint,out,breathe)
        if reverse then Append(out,Point(graph,node.x,node.y,node.z)) end
    elseif edge.horizontal==0 then
        Append(out,EdgePoint(graph,edge,reverse and #edge.cumulative or 1))
        Append(out,EdgePoint(graph,edge,reverse and 1 or #edge.cumulative))
    else Along(graph,edge,reverse and edge.horizontal or 0,reverse and 0 or edge.horizontal,out,breathe) end
end
local function CandidatePath(graph,candidate,side,entry,out,breathe)
    local edge=candidate.edge
    if edge.horizontal==0 then
        local projection=Point(graph,candidate.x,candidate.y,candidate.z)
        local endpoint=EdgePoint(graph,edge,side=="a" and 1 or #edge.cumulative)
        Append(out,entry and projection or endpoint);Append(out,entry and endpoint or projection)
    else Along(graph,edge,entry and candidate.along or side=="a" and 0 or edge.horizontal,
        entry and (side=="a" and 0 or edge.horizontal) or candidate.along,out,breathe) end
end
local function PublishRoute(job,polyline,length,breathe)
    local request,graph=job.request,job.graph
    local start,goal=request.start,request.goal
    local metadata=job.record.data.networks and job.record.data.networks[graph.level] or job.record.data.levels and job.record.data.levels[graph.level]
    for _,point in ipairs(polyline) do
        breathe()
        if point~=start and point~=goal then
            point.accessKey=start.accessKey
            if start.floor==goal.floor then point.floor=start.floor end
            if metadata and (metadata.uiMapID or metadata.map) then point.uiMapID=metadata.uiMapID or metadata.map end
        end
    end
    local speed=Finite(request.walkSpeed) and request.walkSpeed>0 and request.walkSpeed or 7
    local seconds=length/speed
    local segment={kind="walk",road=true,movementMode="ground",from=start,to=goal,seconds=seconds,polyline=polyline,
        copper=0,mandatory=false,roadRevision=job.revision,durationSource="apr-road-model"}
    job.result={segments={segment},totalSeconds=seconds,seconds=seconds,length=length,polyline=polyline,
        roadRevision=job.revision,coverage={road=true,attachmentRadius=request.roadAttachmentRadius or 1000,sourceLevel=graph.level}}
    job.status,job.phase="ready","ready"
end
local function NearbyKnownHeight(graph,point,breathe)
    if Roads.Height(point)~=nil then return false end
    -- A 2D collision mask cannot disambiguate stacked recorded roads. Be
    -- conservative whenever unknown native height could touch a known floor;
    -- the complete attachment search retains authority in that case.
    for _,edge in ipairs(graph.edges) do
        for p=1,#edge.points-3,2 do
            breathe()
            local i=(p+1)/2
            local first=edge.heights and edge.heights[i] or edge.z1
            local last=edge.heights and edge.heights[i+1] or edge.z2
            if Finite(first) and Finite(last) then
                local x,y=edge.points[p],edge.points[p+1]
                local dx,dy=edge.points[p+2]-x,edge.points[p+3]-y
                local squared=dx*dx+dy*dy
                local t=squared>0 and math.max(0,math.min(1,((point.x-x)*dx+(point.y-y)*dy)/squared)) or 0
                if (point.x-x-t*dx)^2+(point.y-y-t*dy)^2<=16 then return true end
            end
        end
    end
    return false
end
local function TryDirect(job)
    local request,graph,breathe=job.request,job.graph,Breather()
    local start,goal=request.start,request.goal
    local direct=Roads.SegmentCost(job.record,graph.level,start,goal,breathe)
    local lower=Distance(start.x,start.y,goal.x,goal.y)
    -- Every declared road, join and attachment costs at least horizontal
    -- distance. An unpenalized proved segment is therefore already optimal.
    if not direct or math.abs(direct-lower)>EPSILON then return end
    if NearbyKnownHeight(graph,start,breathe) or NearbyKnownHeight(graph,goal,breathe) then return end
    PublishRoute(job,{start,goal},direct,breathe)
end
local function Route(job)
    local request,graph,breathe=job.request,job.graph,Breather()
    local start,goal=request.start,request.goal
    job.phase="attachments"
    local direct,directReason=Roads.SegmentCost(job.record,graph.level,start,goal,breathe)
    local starts,startReason=Candidates(job,start,breathe)
    local goals,goalReason=Candidates(job,goal,breathe)
    if not starts or not goals then job.status,job.reason="waiting_data",startReason or goalReason;return end
    local scores,came,heap,exits={},{},{},{}
    local function relax(node,cost,previous,piece)
        if scores[node]==nil or cost<scores[node]-EPSILON then
            scores[node],came[node]=cost,{previous=previous,piece=piece};Push(heap,node,cost)
        end
    end
    if direct then relax(-1,direct,0,{kind="direct"}) end
    local startsByEdge={}
    for _,candidate in ipairs(starts) do
        breathe()
        local edge=candidate.edge;local fraction=candidate.fraction
        local entries=startsByEdge[edge] or {};startsByEdge[edge]=entries;entries[#entries+1]=candidate
        if not edge.drop and not edge.forwardOnly then relax(edge.a,candidate.cost+edge.length*fraction,0,{kind="entry",candidate=candidate,side="a"}) end
        relax(edge.b,candidate.cost+edge.length*(1-fraction),0,{kind="entry",candidate=candidate,side="b"})
    end
    for _,candidate in ipairs(goals) do
        breathe()
        local edge=candidate.edge;local fraction=candidate.fraction
        local list=exits[edge.a] or {};exits[edge.a]=list;list[#list+1]={candidate=candidate,cost=candidate.cost+edge.length*fraction,side="a"}
        if not edge.drop and not edge.forwardOnly then
            list=exits[edge.b] or {};exits[edge.b]=list;list[#list+1]={candidate=candidate,cost=candidate.cost+edge.length*(1-fraction),side="b"}
        end
        for _,entry in ipairs(startsByEdge[edge] or {}) do
            breathe()
            if entry.edge==edge and (not edge.drop and not edge.forwardOnly or entry.fraction<=candidate.fraction) then
                local fractionLength=math.abs(candidate.fraction-entry.fraction)
                relax(-1,entry.cost+candidate.cost+edge.length*fractionLength,0,{kind="same",entry=entry,exit=candidate})
            end
        end
    end
    job.phase="search"
    local settled={}
    while #heap>0 do
        breathe()
        local item=Pop(heap);local node,cost=item[1],item[2]
        if not settled[node] and scores[node]==cost then
            settled[node]=true
            if node==-1 then break end
            for _,exit in ipairs(exits[node] or {}) do relax(-1,cost+exit.cost,node,{kind="exit",candidate=exit.candidate,side=exit.side}) end
            local adjacency=graph.adj[node] or {}
            for i=1,#adjacency,2 do
                breathe()
                local edge,reverse=adjacency[i],adjacency[i+1]
                if Allowed(edge,request) then relax(reverse and edge.a or edge.b,cost+edge.length,node,{kind="edge",edge=edge,reverse=reverse}) end
            end
        end
    end
    if scores[-1]==nil then
        local reason=startReason or goalReason or directReason
        job.status,job.reason=reason=="road_floor_unknown" and "waiting_data" or reason=="road_terrain_missing" and "missing_data" or "no_path",reason or "road_disconnected"
        return
    end
    local chain,node={},-1
    while node~=0 do breathe();local entry=came[node];chain[#chain+1]=entry.piece;node=entry.previous end
    local polyline={start}
    for i=#chain,1,-1 do
        breathe()
        local piece=chain[i]
        if piece.kind=="direct" then Append(polyline,goal)
        elseif piece.kind=="entry" then
            CandidatePath(graph,piece.candidate,piece.side,true,polyline,breathe)
        elseif piece.kind=="exit" then
            CandidatePath(graph,piece.candidate,piece.side,false,polyline,breathe);Append(polyline,goal)
        elseif piece.kind=="same" then
            if piece.entry.edge.horizontal==0 then
                Append(polyline,Point(graph,piece.entry.x,piece.entry.y,piece.entry.z))
                Append(polyline,Point(graph,piece.exit.x,piece.exit.y,piece.exit.z))
            else Along(graph,piece.entry.edge,piece.entry.along,piece.exit.along,polyline,breathe) end
            Append(polyline,goal)
        else EdgePath(graph,piece.edge,piece.reverse,polyline,breathe) end
    end
    Append(polyline,goal)
    PublishRoute(job,polyline,scores[-1],breathe)
end
function Job:Step(operations,milliseconds)
    if self.status~="planning" then return self.status,self.result,self.reason end
    if self.revision~=self.owner:GetRoadRevision() then self.status,self.reason="cancelled","road_revision_changed";return self.status end
    operations=Finite(operations) and math.max(0,math.floor(operations)) or 64
    milliseconds=Finite(milliseconds) and math.max(0,milliseconds) or 1
    self.workLastStep=0
    if operations==0 or milliseconds==0 then return self.status end
    local deadline=self.request.clock and self.request.clock()+milliseconds
    for _=1,operations do
        if self.workLastStep>0 and deadline and self.request.clock()>=deadline then break end
        self.workLastStep=self.workLastStep+1
        local co
        if self.graph.error then self.status,self.reason="invalid_data",self.graph.error;break
        elseif not self.graph.topologyReady and not self.graph.ready then self.phase,co=self.graph.phase,self.graph.co
        elseif self.directEligible and not self.directDone then
            self.phase="direct"
            self.directCo=self.directCo or coroutine.create(function() TryDirect(self);self.directDone=true end)
            co=self.directCo
        elseif not self.graph.ready then self.phase,co=self.graph.phase,self.graph.co
        else
            if not self.co then self.phase="attachments";self.co=coroutine.create(function() Route(self) end) end
            co=self.co
        end
        local ok,reason=coroutine.resume(co)
        if not ok then
            if co==self.graph.co then self.graph.error=tostring(reason) end
            self.status,self.reason="invalid_data",tostring(reason);break
        end
        if coroutine.status(co)=="dead" and co==self.co and self.status=="planning" then self.status,self.reason="no_path","road_disconnected" end
        if self.status~="planning" then break end
    end
    return self.status,self.result,self.reason
end
function Job:Cancel() self.status,self.result,self.co,self.directCo="cancelled",nil,nil,nil end
function Instance:CreateRoadRoute(request)
    request=type(request)=="table" and request or {}
    local record=Roads.Record(self)
    local level=Roads.Level(record,request.start)
    local status,reason="planning",nil
    if not level or not request.goal or request.start.instanceID~=request.goal.instanceID or level~=Roads.Level(record,request.goal)
        or request.start.accessKey~=request.goal.accessKey then status,reason="missing_data","road_space_mismatch" end
    return setmetatable({owner=self,record=record,request=request,status=status,reason=reason,
        directEligible=request.start and request.goal and Finite(request.start.x) and Finite(request.start.y)
            and Finite(request.goal.x) and Finite(request.goal.y)
            and Distance(request.start.x,request.start.y,request.goal.x,request.goal.y)>EPSILON,
        revision=self:GetRoadRevision(),graph=level and Graph(record,level)},Job)
end
-- Following an exact declared road segment does not need an off-road grid.
-- This proof accepts only collinear subsegments, never a chord around a bend.
function Roads.ProvedSegmentCost(record,level,from,to)
    local graph=record.graphs[level]
    if not graph or not graph.ready then return nil end
    local wall=Roads.WallHit(record,level,from,to)
    if wall then return nil end
    local bx,by=math.floor(from.x/BUCKET),math.floor(from.y/BUCKET)
    local bucket=graph.index[Key(bx,by)] or {}
    for i=1,#bucket,2 do
        local edge,p=bucket[i],bucket[i+1]
        local a,b=Project(edge,p,from),Project(edge,p,to)
        if not edge.blocked and a.distance<=EPSILON and b.distance<=EPSILON and (not edge.drop and not edge.forwardOnly or a.fraction<=b.fraction) then
            local first,last=Roads.Height(from),Roads.Height(to)
            if (not first or not a.z or math.abs(first-a.z)<=5) and (not last or not b.z or math.abs(last-b.z)<=5) then
                return edge.length*math.abs(a.fraction-b.fraction)
            end
        end
    end
end
local SegmentCost=Instance.RoadSegmentCost
function Instance:RoadSegmentCost(from,to)
    local record=Roads.Record(self);local level=Roads.Level(record,from)
    if level and level==Roads.Level(record,to) and from.instanceID==to.instanceID then
        local proved=Roads.ProvedSegmentCost(record,level,from,to)
        if proved~=nil then return proved end
    end
    return SegmentCost(self,from,to)
end
