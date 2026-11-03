-- Every currently shipped road declaration obeys the same source contract.
local fixture=dofile("tests/lua/navigation_fixture.lua")
fixture.profile="forever"
fixture:Load()
local lib=LibStub("LibAPRNavigation-1.0")
local function finite(value) return type(value)=="number" and value==value and math.abs(value)<math.huge end
for profile,record in pairs(lib.roadDatasets or {}) do
    local instance=lib:New({profile=profile,environment={}})
    assert(instance:HasRoadData())
    for level,source in pairs(record.data.networks or record.data.roads) do
        local native=record.data.format==2
        local metadata=native and source or record.data.levels and record.data.levels[level]
        local first=native and source.sections[1] and source.sections[1].nodes[1]
        local point={instanceID=metadata and (metadata.instanceID or metadata.base) or level,roadLevel=level,
            x=native and (first and first.x or 0) or source.n[1] or 0,
            y=native and (first and first.y or 0) or source.n[2] or 0}
        local job=instance:CreateRoadRoute({start=point,goal=point})
        local iterations=0
        while not job.graph.ready and job.status=="planning" do
            job:Step(32,1);iterations=iterations+1
            assert(job.workLastStep<=32,"compilation obeys the operation budget")
            assert(iterations<100000,"road graph compilation must terminate")
        end
        assert(job.graph.ready and not job.graph.error,tostring(level)..": "..tostring(job.reason))
        local expectedNodes,expectedEdges=0,0
        if native then
            local nodes,edges,sections={},{},{}
            for _,section in ipairs(source.sections) do
                assert(type(section.id)=="string" and not sections[section.id]);sections[section.id]=true
                for _,node in ipairs(section.nodes) do
                    assert(type(node.id)=="string" and not nodes[node.id]);nodes[node.id]=node
                    assert(finite(node.x) and finite(node.y) and (node.z==nil or finite(node.z)))
                    expectedNodes=expectedNodes+1
                end
            end
            for _,section in ipairs(source.sections) do
                for _,id in ipairs(section.joins or {}) do assert(nodes[id],"declared junction must exist") end
                for _,edge in ipairs(section.edges) do
                    assert(type(edge.id)=="string" and not edges[edge.id]);edges[edge.id]=true
                    assert(nodes[edge.from] and nodes[edge.to] and type(edge.points)=="table" and #edge.points>=2)
                    expectedEdges=expectedEdges+1
                    for _,position in ipairs(edge.points) do
                        assert(finite(position.x) and finite(position.y) and (position.z==nil or finite(position.z)))
                    end
                end
            end
            local binding=source.collision or {}
            if binding.base then assert(record.data.collision[binding.base],"named base mask must exist") end
            for _,id in ipairs(binding.overlays or {}) do assert(record.data.collision[id],"named local mask must exist") end
        else
        local declarations={source}
        for _,overlay in ipairs(record.data.overlays and record.data.overlays[level] or {}) do declarations[#declarations+1]=overlay end
        for _,declaration in ipairs(declarations) do
            assert(type(declaration.n)=="table" and #declaration.n%2==0)
            assert(type(declaration.e)=="table")
            expectedNodes,expectedEdges=expectedNodes+#declaration.n/2,expectedEdges+#declaration.e
            for _,edge in ipairs(declaration.e) do
                assert(finite(edge[1]) and edge[1]%1==0 and edge[1]>=1 and edge[1]<=#declaration.n/2)
                assert(finite(edge[2]) and edge[2]%1==0 and edge[2]>=1 and edge[2]<=#declaration.n/2)
            end
        end
        for _,track in ipairs(record.data.floorTracks and record.data.floorTracks[level] or {}) do
            if (track.op==nil or track.op=="add") and type(track.pts)=="table" and #track.pts>=4 then
                assert(#track.pts%2==0)
                expectedNodes,expectedEdges=expectedNodes+#track.pts/2,expectedEdges+#track.pts/2-1
                for _,value in ipairs(track.pts) do assert(finite(value)) end
                for _,height in pairs(track.zs or {}) do assert(height==false or finite(height)) end
            end
        end
        end
        assert(#job.graph.nodes==expectedNodes,"all discovered source nodes remain available")
        assert(#job.graph.edges==expectedEdges,"all discovered source roads remain represented")
        for _,node in ipairs(job.graph.nodes) do assert(finite(node.x) and finite(node.y) and (node.z==nil or finite(node.z))) end
        for _,edge in ipairs(job.graph.edges) do
            assert(finite(edge.length) and edge.length>=0 and #edge.points%2==0 and #edge.points>=4)
            assert(job.graph.nodes[edge.a] and job.graph.nodes[edge.b])
            for _,value in ipairs(edge.points) do assert(finite(value)) end
        end
        job:Cancel()
    end
end
print("Road data contracts: all discovered graphs compile incrementally, preserving nodes, polylines and valid references")
