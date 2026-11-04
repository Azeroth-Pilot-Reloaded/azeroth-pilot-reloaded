local F=dofile('tests/lua/navigation_v2_scheduled/fixture.lua')
local S=F.Scheduled

for _,omit in ipairs({'floorID','phaseID','both'}) do
    local route=F.Route()
    for _,stop in ipairs({route.origin,route.destination}) do
        if omit~='phaseID' then stop.floorID=nil end
        if omit~='floorID' then stop.phaseID=nil end
    end
    local captured=assert(S.Compile(route),'Unconstrained stops must compile')
    assert(captured.origin.floorID==route.origin.floorID and captured.origin.phaseID==route.origin.phaseID)
    for _,observed in ipairs({false,true}) do
        local e=F.New(route)
        local function observation(kind,sequence,destination)
            local o=F.Observation(kind,sequence,destination)
            if omit~='phaseID' then o.floorID=observed and 91 or nil end
            if omit~='floorID' then o.phaseID=observed and 'observed elsewhere' or nil end
            return o
        end
        local o=observation('origin',1);o.loading=true
        assert(e:Observe(o,101).phase=='approach','Loading is not a localized stop')
        assert(e:Observe(observation('origin',2),102).phase=='waiting')
        assert(e:Observe(observation('transport_ready',3),103).phase=='boarding')
        assert(e:Observe(observation('boarded',4),104).phase=='riding')
        assert(e:Observe(observation('destination',5,true),105).phase=='riding','Departure is mandatory')
        assert(e:Observe(observation('departed',6),106).phase=='riding')
        o=observation('destination',7,true);o.attempt={}
        assert(e:Observe(o,107).phase=='riding','Another attempt cannot arrive')
        o=observation('destination',8,true);o.loading=true
        assert(e:Observe(o,108).phase=='riding')
        assert(e:Observe(observation('destination',9,true),109).phase=='disembarking')
        assert(e:Observe(observation('disembarked',9,true),110).status=='running','Sequences remain strict')
        assert(e:Observe(observation('disembarked',10,true),111).status=='complete')
    end
end

for _,key in ipairs({'floorID','phaseID'}) do
    for _,value in ipairs({false,'',-1,1.5,{}}) do
        local r=F.Route();r.origin[key]=value
        assert(S.Compile(r)==nil,'Invalid declared constraint: '..key)
    end
    local e=F.New();F.Ride(e)
    local o=F.Observation('destination',5,true);o[key]=nil
    assert(e:Observe(o,105).phase=='riding','Missing expected constraint: '..key)
    o=F.Observation('destination',6,true);o[key]=key=='floorID' and 77 or 'different'
    assert(e:Observe(o,106).phase=='riding','Mismatched expected constraint: '..key)
    assert(e:Observe(F.Observation('destination',7,true),107).phase=='disembarking')
end

local route=F.Route();route.origin.floorID,route.origin.phaseID=nil,nil
local e=F.New(route);assert(e:Cancel().status=='cancelled')
assert(e:Observe(F.Observation('origin',1),101).status=='cancelled')
route.origin.worldID=nil;assert(S.Compile(route)==nil,'World remains required')
