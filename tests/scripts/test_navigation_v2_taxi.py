"""Taxi contracts execute the actual XML, planner and opt-in host."""
from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


class TaxiTests(unittest.TestCase):
    def test_contracts(self):
        suites = sorted((Path(__file__).parents[1] / "lua/navigation_v2_taxi").glob("*_test.lua"))
        self.assertTrue(suites, "No taxi contracts discovered")
        for path in suites:
            with self.subTest(suite=path.name):
                LuaRuntime(unpack_returned_tuples=True).execute(
                    path.read_text(encoding="utf-8"), name="@" + path.as_posix()
                )

    def test_dynamic_taxi_disables_static_witnesses(self):
        from tests.lua.navigation_v2_sectors.test_prepared import prepared

        lua, _, _ = prepared(
            [[0, 0, 0]] * 3, [[1, 2, 60000], [2, 3, 60000], [1, 3, 100000]], node_limit=1
        )
        lua.execute(b'''
            local static=finish(plan(1,3))
            assert(static.estimatedSeconds==100)
            local fixture=dofile('tests/lua/navigation_v2_taxi/fixture.lua')
            local route=fixture.Route('shortcut',refs[2],refs[3],6,1)
            local dynamic=assert(ns.LibAPRNavigationV2.New(source,fixture.Options({route},6)))
            local result=finish(dynamic:Plan({from=refs[1],to=refs[3]}))
            assert(result.status=='complete' and result.optimal and result.estimatedSeconds==63,
                'Static witness100 cannot hide approach60 + taxi3')
            assert(result.segments[2].taxiId=='shortcut' and result.resourcesSpent.money==6)
            assert(dynamic.preparation.compiled.stats.geometryLoads==0)
            assert(dynamic:SetResources({money=5}) and not dynamic:IsCurrent(result))
            local changed=finish(dynamic:Plan({from=refs[1],to=refs[3]}))
            assert(changed.estimatedSeconds==100 and #changed.segments==1)
            assert(dynamic.budgets.sliceMs==1 and dynamic.budgets.cpuMs==100 and dynamic.budgets.elapsedMs==5000)
        ''')

    def test_personal_shortcut_disables_static_witnesses(self):
        from tests.lua.navigation_v2_sectors.test_prepared import prepared

        lua, _, _ = prepared(
            [[0, 0, 0]] * 3, [[1, 2, 60000], [2, 3, 60000], [1, 3, 100000]], node_limit=1
        )
        lua.execute(b'''
            assert(finish(plan(1,3)).estimatedSeconds==100)
            local d={id='recall',kind='spell',spellID=901,from=refs[1],to=refs[3],
                destination={space='world',phase='shared'},useSeconds=1,loadingSeconds=1,
                cooldownSeconds=60,timeoutSeconds=20,moneyCopper=2,
                reagents={powder={itemID=902,count=1}}}
            local o={revision=1,observedAt=100,loading=false,combat=false,casting=false,
                moneyCopper=2,items={[902]=1},origin={node=refs[1],space='cave',phase='shared',reliable=true},
                actions={recall={known=true,loaded=true,usable=true,readyAt=100}}}
            local dynamic=assert(ns.LibAPRNavigationV2.New(source,{personal={d},personalObservation=o,
                clock=function()return 100 end,profileClock=options.profileClock}))
            local result=finish(dynamic:Plan({from=refs[1],to=refs[3]}))
            assert(result.status=='complete' and result.optimal and result.estimatedSeconds==2,
                'A static certificate100 must not mask the available recall2')
            assert(result.segments[1].personalId=='recall' and result.resourcesSpent.money==2)
            assert(dynamic.preparation.compiled.stats.geometryLoads==0)
            assert(dynamic:SetPersonalCosts('recall',{loadingSeconds=200}) and not dynamic:IsCurrent(result))
            local changed=finish(dynamic:Plan({from=refs[1],to=refs[3]}))
            assert(changed.estimatedSeconds==100 and changed.segments[1].personalId==nil)
        ''')
