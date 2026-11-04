-- Local collision proofs must not wait for unrelated continent joins/indexes.
local fixture=dofile("tests/lua/navigation_fixture.lua")
local function near(actual,expected)
    assert(actual and math.abs(actual-expected)<0.000001,tostring(actual).." ~= "..tostring(expected))
end
for _,profile in ipairs({"forever","retail"}) do
    fixture.profile=profile
    fixture:Load({})
    local lib=LibStub("LibAPRNavigation-1.0")
    local sequence=0
    local function point(x,y,z)
        return {instanceID=8,x=x,y=y,z=z}
    end
    local function section(id,x,y,z,shape)
        local a,b=id.."-a",id.."-b"
        return {id=id,kind="road",nodes={{id=a,x=x,y=y,z=z},{id=b,x=x+100,y=y,z=z}},
            joins={a},edges={{id=id.."-edge",from=a,to=b,points=shape or {
                {x=x,y=y,z=z},{x=x+100,y=y,z=z}}}}}
    end
    local function setup(sections,state,walls)
        sequence=sequence+1
        local name="direct-fixture-"..sequence
        local rows={}
        for i=1,200 do rows[i]={{from=1,to=200,state=state or "open"}} end
        lib:RegisterRoadCollision(name,{id="invented-mask",originX=300,originY=300,
            cellSize=10,width=200,height=200,rows=rows},1)
        local definition={id="invented-world",instanceID=8,kind="world",sections=sections,
            collision={base="invented-mask"},walls=walls}
        lib:RegisterRoadNetwork(name,definition,1)
        return lib:New({profile=name,environment={}}),name,definition
    end
    local function create(owner,from,to)
        return owner:CreateRoadRoute({start=from or point(0,0),goal=to or point(100,0),walkSpeed=1,
            roadAttachmentRadius=0})
    end
    local function finish(job,operations,bound)
        for slice=1,bound or 20000 do
            local status,result,reason=job:Step(operations or 3,1)
            assert((job.workLastStep or 0)<=(operations or 3),"Every phase retains the operation bound")
            if status~="planning" then return status,result,reason,slice end
        end
        error("Local road proof exceeded its incremental work bound")
    end
    local distant={}
    for i=1,256 do
        distant[i]=section("invented-distant-"..i,-1000+i%8,-1000+math.floor(i/8))
    end
    local owner=setup(distant)
    local job=create(owner)
    local status,result,reason,slices=finish(job,1,128)
    assert(status=="ready" and slices<=128)
    near(result.length,100)
    assert(#result.polyline==2 and result.segments[1].road)
    assert(job.graph.topologyReady and not job.graph.ready and next(job.graph.adj)==nil
        and next(job.graph.index)==nil,
        "A proved local optimum leaves unrelated graph indexes, collision checks and joins dormant")

    -- Door searches inspect their tolerance, not every road across a city block.
    local spread={}
    for i=1,256 do
        spread[i]=section("invented-spread-"..i,-1000+i%16*32,-1000+math.floor(i/16)*32)
    end
    owner=setup(spread)
    job=create(owner,point(0,0),point(0,0))
    status,result,reason,slices=finish(job,1,1024)
    assert(status=="ready" and job.graph.ready and slices<=1024,
        "A bounded door radius must not scan hundreds of unrelated nearby roads")

    -- Finer door cells must retain linear storage for long diagonal geometry.
    local references={}
    for _,length in ipairs({2048,4096}) do
        local diagonal={id="invented-diagonal",kind="road",nodes={
            {id="diagonal-a",x=-length,y=-length},{id="diagonal-b",x=0,y=0}},
            edges={{id="diagonal-edge",from="diagonal-a",to="diagonal-b",points={
                {x=-length,y=-length},{x=0,y=0}}}}}
        owner=setup({diagonal})
        job=create(owner,point(0,10),point(0,10))
        assert(finish(job,64)=="ready")
        local count=0
        for _,bucket in pairs(job.graph.joinIndex) do count=count+#bucket/2 end
        references[#references+1]=count
    end
    assert(references[2]<=3*references[1] and references[2]<4096,
        "Doubling a road's length cannot quadruple the door index storage")

    -- Two jobs share validation/compilation without stealing one another's work.
    owner=setup(distant)
    local direct,compiler=create(owner),create(owner,point(0,0),point(0,0))
    for _=1,128 do
        direct:Step(1,1)
        compiler:Step(1,1)
        if direct.status~="planning" then break end
    end
    assert(direct.status=="ready" and compiler.status=="planning" and not compiler.graph.ready)
    status,result=finish(compiler,64)
    assert(status=="ready" and compiler.graph.ready)
    near(result.length,0)
    compiler.graph.topologyReady,compiler.graph.phase=nil,nil -- Earlier embedded copy's completed graph.
    assert(finish(create(owner,point(0,0),point(0,0)),64)=="ready",
        "A completed graph from an older module never resumes its dead compiler")

    -- Finer cells preserve the earlier coarse-cell order when distances tie.
    local function vertical(id,x)
        return {id=id,kind="road",nodes={{id=id.."-a",x=x,y=0},{id=id.."-b",x=x,y=100}},
            edges={{id=id.."-edge",from=id.."-a",to=id.."-b",points={{x=x,y=0},{x=x,y=100}}}}}
    end
    local mouth={id="invented-mouth",kind="building",joinRadius=40,
        nodes={{id="mouth-a",x=32,y=50},{id="mouth-b",x=32,y=60}},joins={"mouth-a"},
        edges={{id="mouth-edge",from="mouth-a",to="mouth-b",points={{x=32,y=50},{x=32,y=60}}}}}
    owner=setup({vertical("invented-first",64),vertical("invented-second",0),mouth})
    compiler=create(owner,point(32,50),point(32,50))
    assert(finish(compiler,64)=="ready")
    local tied=0
    for i=1,#compiler.graph.adj[5],2 do
        local edge=compiler.graph.adj[5][i]
        if edge.join then
            assert(edge.join.edge.name=="invented-first-edge","Equal-distance source selection retains its original order")
            tied=tied+1
        end
    end
    assert(tied==2)

    -- A wall or a water penalty cannot turn a direct segment into the winner.
    local detour={section("invented-detour",0,0,nil,
        {{x=0,y=0},{x=0,y=10},{x=100,y=10},{x=100,y=0}})}
    owner=setup(detour,"open",{{id="invented-fence",points={{x=50,y=-5},{x=50,y=5}}}})
    job=create(owner)
    status,result=finish(job)
    assert(status=="ready" and job.graph.ready)
    near(result.length,120)
    owner=setup(detour,"water")
    job=create(owner)
    status,result=finish(job)
    assert(status=="ready" and job.graph.ready)
    near(result.length,120)

    -- An open ground mask still cannot choose an unknown stacked road floor.
    owner=setup({section("invented-low-floor",0,0,10),section("invented-high-floor",0,0,30)})
    local unknown=point(0,0,0);unknown.positionSource="unit"
    job=create(owner,unknown,point(100,0))
    status,result,reason=finish(job)
    assert(status=="waiting_data" and reason=="road_floor_unknown" and job.graph.ready)
    owner=setup({section("invented-known-floor",0,0,10)})
    job=create(owner,point(0,0,10),point(100,0,10))
    status,result=finish(job)
    assert(status=="ready" and not job.graph.ready)
    near(result.length,100)

    -- Every source is validated, including declarations far from the direct leg.
    for _,damage in ipairs({"duplicate","reference","shape","join"}) do
        local broken=section("invented-bad",-1000,-1000)
        if damage=="duplicate" then broken.nodes[2].id=broken.nodes[1].id
        elseif damage=="reference" then broken.edges[1].to="absent-node"
        elseif damage=="shape" then broken.edges[1].points[2].x=-500
        else broken.joinRadius="invalid" end
        owner=setup({section("invented-valid",-900,-900),broken})
        job=create(owner)
        status=finish(job)
        assert(status=="invalid_data" and not job.graph.topologyReady,
            "A clear local mask cannot bypass malformed source declarations")
    end

    -- Cancelling a direct proof leaves the shared compiler available to others.
    owner=setup(distant)
    job=create(owner)
    repeat assert(job:Step(1,1)=="planning") until job.phase=="direct"
    job:Cancel()
    assert(job:Step(100,1)=="cancelled" and job.directCo==nil)
    compiler=create(owner,point(0,0),point(0,0))
    assert(finish(compiler,64)=="ready" and compiler.graph.ready)

    -- A replacement during direct verification cannot publish the old mask/graph.
    local name,definition
    owner,name,definition=setup(distant)
    job=create(owner)
    repeat assert(job:Step(1,1)=="planning") until job.phase=="direct"
    lib:RegisterRoadNetwork(name,definition,2)
    assert(job:Step(1,1)=="cancelled")
    status,result=finish(create(owner),1,128)
    assert(status=="ready")
    near(result.length,100)
end
print("Direct road proofs: bounded local work, dormant distant joins, walls/water, floors, validation, concurrency and source lifecycle passed")
