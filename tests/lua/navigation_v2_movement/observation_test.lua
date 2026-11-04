local ns={}
assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/Movement/Forever.lua'))('APR',ns)
APR={}
local Adapter=assert(loadfile('APR-Core/features/navigation/NavigationV2Movement.lua'))('APR',ns)
local state={level=40,owned=true,usable=true,active=false,swimming=false,run=7,swim=4.7,kind=241}
local api={UnitLevel=function(unit) assert(unit=='player');return state.level end,
    IsSwimming=function(unit) assert(unit=='player');return state.swimming end,
    GetUnitSpeed=function(unit) assert(unit=='player');return 0,state.run,0,state.swim end,
    C_MountJournal={
        GetMountIDs=function() return {31} end,
        GetMountInfoByID=function(id)
            assert(id==31)
            return 'Horse',123,1,state.active,state.usable,1,false,false,nil,false,state.owned,31,false
        end,
        GetMountInfoExtraByID=function(id) assert(id==31);return nil,'description','source',false,state.kind end,
        GetMountUsabilityByID=function(id,indoors)
            assert(id==31 and type(indoors)=='boolean')
            if indoors and state.indoors then return false end
            return state.usable
        end,
    }}
local observation=Adapter.Observe(api)
assert(observation.level==40 and observation.mountOwned==true and observation.mountUsable==true)
assert(observation.initialMode=='walk' and observation.mountID==31)
local p,capture=Adapter.Capture(api)
assert(p and capture and p.initialMode=='walk' and Adapter.Same(observation,Adapter.Observe(api)))
local _,repeatCapture=Adapter.Capture(api)
assert(Adapter.Same(capture,repeatCapture))
local _,changedCosts=Adapter.Capture(api,{mountSeconds=8})
assert(not Adapter.Same(capture,changedCosts),'settings changes invalidate a captured profile')
state.indoors=true
local indoor=Adapter.Capture(api)
assert(indoor:Evaluate({movement={mode='mount',distance=112,canMount='available'}},'walk',true).access=='unavailable')
assert(indoor:Evaluate({movement={mode='mount',distance=112,canMount='available'}},'walk',false).access=='available',
    'origin indoor observation is not applied to future outdoor nodes')
state.indoors=false
state.level=39
assert(not Adapter.Same(observation,Adapter.Observe(api)))
assert(Adapter.Capture(api):Evaluate({movement={mode='mount',distance=112,canMount='available'}},'walk').access=='unavailable')
state.level=40;state.owned=false
assert(Adapter.Observe(api).mountOwned==false)
state.owned=true;state.usable=false
assert(Adapter.Observe(api).mountUsable==false)
state.usable=nil
assert(Adapter.Observe(api).mountUsable==nil,'nil usability is not false')
state.usable=true;state.active=true;state.run=14
assert(Adapter.Observe(api).initialMode=='mount')
assert(Adapter.Capture(api):Evaluate({movement={mode='mount',distance=140}},'mount').seconds==10)
assert(Adapter.Capture(api,{mountSpeed=7}):Evaluate({movement={mode='mount',distance=140}},'mount').seconds==20,
    'manual cost setting has priority over observation')
state.kind=9999
assert(Adapter.Observe(api).mountOwned==nil,'unclassified mount type stays unknown')
state.kind=241;state.swimming=true
assert(Adapter.Observe(api).initialMode=='swim')
local loading=Adapter.Observe(api,true)
assert(loading.loading==true and loading.initialMode==nil and loading.mountUsable==nil)
assert(not Adapter.Same(loading,Adapter.Observe(api)))
assert(Adapter.Observe({}).initialMode==nil)
api.C_MountJournal.GetMountIDs=function() error('not ready') end
assert(Adapter.Observe(api).mountOwned==nil)
api.C_MountJournal=nil;api.UnitLevel=function() return -1 end
assert(Adapter.Observe(api).level==nil)
local secret=setmetatable({}, {__eq=function() error('secret compared') end})
api.issecretvalue=function(value) return rawequal(value,secret) end
api.UnitLevel=function() return secret end
assert(Adapter.Observe(api).level==nil)
api.UnitLevel=function() return 40 end
api.issecretvalue=function(value) return value==40 end
assert(Adapter.Observe(api).level==nil,'secret numeric values are discarded before arithmetic')
assert(APR.NavigationV2Movement==Adapter and ns.NavigationV2Movement==Adapter)

local records={
    [51]={owned=true,usable=true,active=false,kind=241},
    [52]={owned=true,usable=true,active=true,kind=283},
}
api={UnitLevel=function() return 40 end,IsSwimming=function() return false end,
    GetUnitSpeed=function() return 0,14,0,4.7 end,
    C_MountJournal={GetMountIDs=function() return {51,52} end,
        GetMountInfoByID=function(id)
            local r=records[id]
            if r.missing then return end
            return 'Mount',id,1,r.active,r.usable,1,false,false,nil,false,r.owned,id,false
        end,
        GetMountInfoExtraByID=function(id) return nil,'','',false,records[id].kind end,
        GetMountUsabilityByID=function(id) return records[id].usable end}}
assert(Adapter.Observe(api).initialMode=='mount','active ground mount need not be selected capability')
records[51].usable=false;records[52].usable=nil;records[52].active=false
assert(Adapter.Observe(api).mountUsable==nil,'unknown capability beats a known unusable mount')
records[52].missing=true
assert(Adapter.Observe(api).mountUsable==nil,'missing mount record cannot prove no usable mount')
assert(Adapter.Observe(api).initialMode==nil,'missing active flag cannot prove walking')
api.C_MountJournal.GetMountIDs=function() return {} end
local empty=Adapter.Observe(api)
assert(empty.mountOwned==false and empty.initialMode=='walk')
