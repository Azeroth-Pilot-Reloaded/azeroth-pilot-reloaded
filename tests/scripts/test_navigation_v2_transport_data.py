"""Discovered data contracts plus invented bindings through the real V2 engine."""
from copy import deepcopy
import importlib.util
import json
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[2]
LIB = ROOT/'APR-Core/libs/LibAPRNavigation-2.0'
DIRECTORY = LIB/'Data/forever/Transports'
GEN = ROOT.parent/'Route-generator'
spec = importlib.util.spec_from_file_location('transport_importer', GEN/'tools/navigation_v2/import_transports.py')
importer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(importer)


def runtime():
    lua = LuaRuntime(unpack_returned_tuples=True)
    ns = lua.table()
    for element in ET.parse(LIB/'LibAPRNavigation.xml').iter():
        if element.tag.rsplit('}', 1)[-1] == 'Script':
            path = LIB/element.attrib['file']
            lua.execute(path.read_text(encoding='utf-8-sig'), 'tests', ns)
    return lua, ns


class TransportContentTests(unittest.TestCase):
    def test_every_discovered_document_has_the_common_schema_and_reproducible_export(self):
        sources = sorted((GEN/'data/navigation_v2').rglob('transports.json'))
        self.assertTrue(sources, 'No transport authoring documents discovered')
        for path in sources:
            with self.subTest(path=path):
                doc = json.loads(path.read_text(encoding='utf-8'))
                importer.validate(doc)
                output = LIB/'Data'/doc['client']/'Transports/Catalog.lua'
                self.assertEqual(output.read_text(encoding='utf-8'), importer.render(doc))

    def test_discovered_runtime_scripts_are_registered_exactly_once(self):
        scripts = [LIB/e.attrib['file'] for e in ET.parse(LIB/'LibAPRNavigation.xml').iter()
                   if e.tag.rsplit('}',1)[-1] == 'Script']
        for path in DIRECTORY.glob('*.lua'):
            with self.subTest(path=path):
                self.assertEqual(scripts.count(path), 1)

    def test_every_exported_route_and_exclusion_is_visible_without_admitting_travel(self):
        lua, ns = runtime()
        data = ns.NavigationV2ForeverTransportsData
        doc = json.loads((GEN/'data/navigation_v2/forever/transports.json').read_text(encoding='utf-8'))
        for value in doc['routes']:
            with self.subTest(id=value['id']):
                record = data.routes[value['id']]
                self.assertEqual(record.id, value['id'])
                self.assertEqual(record.kind, value['kind'])
                result, why = ns.NavigationV2ForeverTransports.Bind(value['id'], None)
                self.assertIsNone(result)
                self.assertEqual(why, 'transport_binding_missing')
        for value in doc['excluded']:
            with self.subTest(excluded=value['id']):
                self.assertIsNone(data.routes[value['id']])
                self.assertEqual(data.excluded[value['id']].reason, value['reason'])


class TransportBindingTests(unittest.TestCase):
    def setUp(self):
        self.lua, self.ns = runtime()
        self.lua.globals().ns = self.ns

    def test_explicit_directions_costs_and_conditions_use_the_existing_solver(self):
        self.lua.execute('''
            ns.NavigationV2ForeverTransportsData={routes={crossing={id='crossing',kind='boat',
                bidirectional=true,seconds=37,requirements={faction='Alliance',class='MAGE',minLevel=20,
                    quests={{questID=901,completed=true}}},
                from={space='map',uiMapID=71,x=.2,y=.3},to={space='map',uiMapID=72,x=.4,y=.5}}},excluded={}}
            local b={from={node='garden',space='island',phase='ordinary',worldID=8,floorID=2},
                to={node='harbour',space='coast',phase='ordinary',worldID=9,floorID=1},access='available',
                costs={approach=1,boarding=2,ride=17,loading=3,disembark=4,final=5},
                wait={mode='known',seconds=5},timeoutSeconds=90}
            local bundle=assert(ns.NavigationV2ForeverTransports.Bind('crossing',b))
            assert(#bundle.options.scheduled==2 and #bundle.graph.edges==0 and not bundle.graph.complete)
            assert(bundle.options.scheduled[1].origin.position.mapID==71)
            assert(bundle.options.scheduled[2].origin.position.mapID==72)
            local o=bundle.options
            o.clock=function()return 100 end; o.profileClock=function()return 0 end
            o.conditionObservation={sequence=1,worldState='ready',quests={[901]=true},
                access={['faction-alliance']=true,['class-mage']=true,['minimum-level:20']=true}}
            local planner=assert(ns.LibAPRNavigationV2.New(bundle.graph,o))
            local function finish(from,to)
                local job=planner:Plan({from=from,to=to})
                for i=1,100 do local r=job:Step(64);if r.status~='running' then return r end end
                error('synthetic job did not finish')
            end
            local r=finish('garden','harbour'); assert(r.status=='complete' and r.estimatedSeconds==37)
            r=finish('harbour','garden'); assert(r.status=='complete' and r.estimatedSeconds==37)
            assert(planner:ObserveConditions({sequence=2,worldState='ready',quests={[901]=false},access={}}))
            r=finish('garden','harbour'); assert(r.status=='unknown' and r.estimatedSeconds==nil)
        ''')

    def test_missing_identity_cost_direction_and_unsupported_walk_remain_explicit(self):
        self.lua.execute('''
            local record={id='crossing',kind='boat',bidirectional=false,seconds=37,
                from={space='world',instanceID=8,x=1,y=2},to={space='world',instanceID=9,x=3,y=4}}
            ns.NavigationV2ForeverTransportsData={routes={crossing=record},excluded={}}
            local api=ns.NavigationV2ForeverTransports
            local bundle,why=api.Bind('crossing',{}); assert(not bundle and why=='transport_endpoint_identity_missing')
            local b={from={node='a',space='one',phase='normal',worldID=8,floorID=1},
                to={node='b',space='two',phase='normal',worldID=9,floorID=1},access='available',timeoutSeconds=40}
            record.seconds=nil
            bundle,why=api.Bind('crossing',b);assert(not bundle and why=='transport_cost_components_missing')
            record.seconds=37
            b.costs={approach=0,boarding=0,ride=37,loading=0,disembark=0,final=0}
            b.wait={mode='known',seconds=0}
            bundle=assert(api.Bind('crossing',b));assert(#bundle.options.scheduled==1)
            record.bidirectional=nil
            bundle,why=api.Bind('crossing',b);assert(not bundle and why=='transport_direction_unspecified')
            record.bidirectional=false;record.kind='walk'
            bundle,why=api.Bind('crossing',b);assert(not bundle and why=='transport_kind_unsupported')
            record.kind='boat';b.to.worldID=8
            bundle,why=api.Bind('crossing',b);assert(not bundle and why=='transport_world_mismatch')
        ''')

    def test_portal_and_personal_preserve_their_existing_catalogue_contracts(self):
        self.lua.execute('''
            local row={id='gate',kind='portal',bidirectional=false,seconds=11,
                from={space='world',instanceID=8,x=1,y=2,accessKey='garden-door'},
                to={space='world',instanceID=9,x=3,y=4}}
            ns.NavigationV2ForeverTransportsData={routes={gate=row},excluded={}}
            local b={from={node='a',space='one',phase='normal',worldID=8,floorID=1},
                to={node='b',space='two',phase='normal',worldID=9,floorID=1},
                costs={waitSeconds=1,useSeconds=4,loadingSeconds=6},timeoutSeconds=30}
            local bundle=assert(ns.NavigationV2ForeverTransports.Bind('gate',b))
            local d=bundle.options.portals[1]
            assert(d.requirements.access[1].key=='location-access:garden-door')
            assert(ns.NavigationV2Portals.New(bundle.options.portals))
            row.kind='spell';row.from={dynamic='player'};row.to={dynamic='bind'}
            row.actions={{type='spell',id=810,reagentID=811,groupSpellID=812}}
            b.costs={useSeconds=4,loadingSeconds=6};b.cooldownSeconds=30
            b.consumable=false;b.rare=false;b.chargeBased=false
            b.reagents={dust={itemID=811,count=2}}
            local rejected,why=ns.NavigationV2ForeverTransports.Bind('gate',b)
            assert(not rejected and why=='transport_bind_destination_unobserved')
            b.bindObserved=true
            bundle=assert(ns.NavigationV2ForeverTransports.Bind('gate',b))
            d=bundle.options.personal[1];assert(d.spellID==810 and d.reagents.dust.count==2)
            assert(ns.NavigationV2Personal.New(bundle.options.personal))
            assert(row.actions[1].groupSpellID==812 and row.from.dynamic=='player')
            b.reagents={}
            local missing,reason=ns.NavigationV2ForeverTransports.Bind('gate',b)
            assert(not missing and reason=='transport_reagent_quantity_missing')
        ''')

    def test_declared_aggregate_costs_do_not_require_an_invented_schedule_or_split(self):
        self.lua.execute('''
            local row={id='crossing',kind='boat',bidirectional=true,seconds=41,
                from={space='world',instanceID=8,x=1,y=2},to={space='world',instanceID=9,x=3,y=4}}
            ns.NavigationV2ForeverTransportsData={routes={crossing=row},excluded={}}
            local b={from={node='a',space='one',phase='normal',worldID=8,floorID=1},
                to={node='b',space='two',phase='normal',worldID=9,floorID=1},
                access='available',timeoutSeconds=90}
            local bundle=assert(ns.NavigationV2ForeverTransports.Bind('crossing',b))
            local d=bundle.options.scheduled[1]
            assert(d.totalSeconds==41 and d.wait==nil and d.costs==nil)
            for _,invalid in ipairs({false,'41',-1,math.huge}) do
                b.totalSeconds=invalid
                local missing,reason=ns.NavigationV2ForeverTransports.Bind('crossing',b)
                assert(not missing and reason=='transport_total_invalid')
            end
            b.totalSeconds=nil
            local catalog=assert(ns.NavigationV2Scheduled.NewCatalog(bundle.options.scheduled))
            local total,detail=ns.NavigationV2Scheduled.Cost(catalog.byId[d.id],999,100)
            assert(total==41 and detail.totalSeconds==41 and detail.waitSeconds==nil and detail.ride==nil)
            local overridden=assert(ns.NavigationV2Scheduled.NewCatalog(bundle.options.scheduled,{[d.id]={totalSeconds=23}}))
            assert(overridden:Edge('a',1,100).seconds==23 and d.totalSeconds==41)
            local invalid=ns.NavigationV2Scheduled.NewCatalog(bundle.options.scheduled,{[d.id]={ride=5}})
            assert(not invalid)
            local source={complete=false,nodes={'start','a','b','end'},edges={
                {id='approach',from='start',to='a',seconds=3},
                {id='final',from='b',to='end',seconds=7},
                {id='detour',from='start',to='end',seconds=80}}}
            bundle.options.clock=function()return 100 end;bundle.options.profileClock=function()return 0 end
            local planner=assert(ns.LibAPRNavigationV2.New(source,bundle.options))
            local function finish()
                local job=planner:Plan({from='start',to='end'})
                for i=1,100 do local r=job:Step(64);if r.status~='running' then return r end end
                error('synthetic job did not finish')
            end
            local r=finish();assert(r.status=='complete' and r.estimatedSeconds==51)
            local changed,why=planner:SetScheduled(bundle.options.scheduled,{[d.id]={loading=1}})
            assert(changed==nil and planner:IsCurrent(r))
            assert(planner:SetScheduled(bundle.options.scheduled,{[d.id]={totalSeconds=90}}))
            assert(not planner:IsCurrent(r));r=finish();assert(r.status=='complete' and r.estimatedSeconds==80)
        ''')

    def test_aggregate_portal_cost_updates_are_atomic_and_calibration_skips_unknown_components(self):
        self.lua.execute((ROOT/'APR-Core/features/navigation/NavigationV2Calibration.lua').read_text(encoding='utf-8'), 'tests', self.ns)
        self.lua.execute('''
            local portal={id='gate',from='a',to='b',phase='ordinary',
                destination={space='two',phase='ordinary'},totalSeconds=19,timeoutSeconds=40}
            local catalog=assert(ns.NavigationV2Portals.New({portal},{revision=1,phase='ordinary',
                portals={gate={open=true,access=true}}}))
            assert(catalog:Edge('a',1).seconds==19)
            assert(catalog:SetCosts('gate',{totalSeconds=13}))
            assert(catalog:Edge('a',1).seconds==13)
            assert(catalog:SetCosts('gate',{loadingSeconds=1})==nil)
            assert(catalog:Edge('a',1).seconds==13)
            portal.loadingSeconds=2
            assert(ns.NavigationV2Portals.New({portal})==nil)
            local route={id='ride',kind='boat',from='a',to='b',totalSeconds=31,
                origin={id='dock-a',worldID=8,floorID=1,phaseID='ordinary'},
                destination={id='dock-b',worldID=9,floorID=1,phaseID='ordinary'}}
            local scheduled=assert(ns.NavigationV2Scheduled.NewCatalog({route}))
            local definitions=ns.NavigationV2CalibrationAdapter.Describe({scheduled=scheduled,portals=catalog},{})
            assert(#definitions==0)
        ''')

    def test_invalid_or_mixed_aggregate_costs_are_rejected(self):
        self.lua.execute('''
            local base={id='ride',kind='boat',from='a',to='b',totalSeconds=17,
                origin={id='dock-a',worldID=8,floorID=1,phaseID='ordinary'},
                destination={id='dock-b',worldID=9,floorID=1,phaseID='ordinary'}}
            local copy=ns.NavigationV2WaypointTarget.Copy
            for _,value in ipairs({-1,true,'17',math.huge,0/0}) do
                local d=copy(base);d.totalSeconds=value
                assert(ns.NavigationV2Scheduled.Compile(d)==nil)
                d={id='gate',from='a',to='b',phase='ordinary',destination={space='two',phase='ordinary'},
                    timeoutSeconds=40,totalSeconds=value}
                assert(ns.NavigationV2Portals.New({d})==nil)
            end
            for _,field in ipairs({'costs','wait'}) do
                local d=copy(base);d[field]={}
                assert(ns.NavigationV2Scheduled.Compile(d)==nil)
            end
            for _,field in ipairs({'waitSeconds','useSeconds','loadingSeconds'}) do
                local d={id='gate',from='a',to='b',phase='ordinary',destination={space='two',phase='ordinary'},
                    timeoutSeconds=40,totalSeconds=17};d[field]=0
                assert(ns.NavigationV2Portals.New({d})==nil)
            end
            local d=copy(base);d.totalSeconds=0
            local route=assert(ns.NavigationV2Scheduled.Compile(d))
            assert(ns.NavigationV2Scheduled.Cost(route,0,0)==0)
            assert(ns.NavigationV2Scheduled.Cost(route,-1,0)==nil)
            local partial=ns.NavigationV2Scheduled.Compile(base,{totalSeconds=5,ride=0})
            assert(not partial)
        ''')

    def test_tram_aggregate_uses_the_same_observed_cycle_and_deadline(self):
        self.lua.execute('''
            local d={id='tram',kind='tram',from='a',to='b',totalSeconds=29,
                origin={id='station-a',worldID=8,floorID=1,phaseID='ordinary'},
                destination={id='station-b',worldID=8,floorID=1,phaseID='ordinary'}}
            local catalog=assert(ns.NavigationV2Scheduled.NewCatalog({d}))
            local e=assert(catalog:NewExecution('tram',{objectiveID='trip',now=100,timeoutSeconds=80}))
            local initial=e:GetState();assert(initial.wait==nil and initial.deadline==180)
            local sequence=0
            local function observe(kind,stop,onTransport,now)
                sequence=sequence+1
                return e:Observe({kind=kind,sequence=sequence,objectiveID='trip',routeID='tram',confirmed=true,
                    attempt=initial.attempt,stopID=stop,worldID=8,floorID=1,phaseID='ordinary',
                    onTransport=onTransport},now)
            end
            assert(observe('origin','station-a',false,101).phase=='waiting')
            assert(observe('transport_ready','station-a',false,102).phase=='boarding')
            assert(observe('boarded','station-a',true,103).phase=='riding')
            assert(observe('destination','station-b',true,104).phase=='riding')
            observe('departed',nil,true,105)
            assert(observe('destination','wrong-station',true,106).phase=='riding')
            assert(observe('destination','station-b',true,107).phase=='disembarking')
            assert(observe('disembarked','station-b',false,108).status=='complete')
            assert(e:GetState().deadline==180 and e:GetState().wait==nil)
            e=assert(catalog:NewExecution('tram',{objectiveID='trip',now=100,timeoutSeconds=80}))
            assert(e:Tick(180).status=='timeout' and e:Cancel().status=='timeout')
            e=assert(catalog:NewExecution('tram',{objectiveID='trip',now=100,timeoutSeconds=80}))
            assert(e:Cancel().status=='cancelled' and e:Tick(180).status=='cancelled')
        ''')

    def test_bound_aggregate_uses_existing_host_and_preserves_legacy_default(self):
        self.lua.execute('''
            local R=dofile('tests/lua/navigation_v2_scheduled/runtime_fixture.lua')
            local host,env,ws,awp,actual=R.Host(false)
            actual.NavigationV2ForeverTransportsData={routes={crossing={id='crossing',kind='boat',
                bidirectional=false,seconds=41,from={space='map',uiMapID=71,x=.2,y=.3},
                to={space='map',uiMapID=72,x=.4,y=.5}}},excluded={}}
            local bundle=assert(actual.NavigationV2ForeverTransports.Bind('crossing',{
                from={node='a',space='one',phase='ordinary',worldID=8,floorID=1},
                to={node='b',space='two',phase='ordinary',worldID=9,floorID=1},
                access='available',timeoutSeconds=90}))
            assert(bundle.travelOptions.scheduledTimeoutSeconds==90)
            assert(host:Enable(bundle.graph,bundle.options));host:ObserveWorld(false)
            host:Plan({from='a',to='b'},env.context)
            local result=R.Finish(host.job)
            assert(result.status=='complete' and result.estimatedSeconds==41 and #ws.creates==0)
            bundle.travelOptions.objectiveID='crossing-trip'
            local action=assert(host:StartTravel(result,bundle.travelOptions))
            assert(action.wait==nil and action.deadline==190 and action.kind=='scheduled')
            local d=bundle.options.scheduled[1]
            for i,event in ipairs({'origin','transport_ready','boarded','departed','destination','disembarked'}) do
                local proof=R.Proof(d,action,event,i,event=='destination' or event=='disembarked')
                local state=host:ObserveTravel(proof)
                if event=='disembarked' then assert(state.kind=='complete') else assert(state.wait==nil) end
            end
            assert(env.questCalls==0 and APR.navigation.legacy)
            host:Disable();assert(APR.navigation.legacy)
        ''')


if __name__=='__main__':
    unittest.main()
