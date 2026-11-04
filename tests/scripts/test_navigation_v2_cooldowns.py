"""Future availability through the real graph loader and standard discovery."""
from pathlib import Path
import unittest

from tests.lua.navigation_v2_sectors.test_prepared import prepared


ROOT = Path(__file__).resolve().parents[2]


def atlas_runtime():
    return prepared(
        [[0, 0, 0]] * 4,
        [[1, 2, 11000], [2, 3, 11000], [3, 4, 11000]],
        landmarks=2,
        node_limit=2,
    )[0]


def atlas_contract(script):
    def contract(self):
        atlas_runtime().execute(script)
    return contract


class CooldownIntegrationTests(unittest.TestCase):
    test_conditional_sector_graph_cannot_consume_a_static_witness = atlas_contract(b'''
            assert(finish(plan(1,4)).estimatedSeconds==33)
            source.requirements={access={{key='open',allowed=true}}}
            local observation={sequence=1,worldState='ready',access={open=true}}
            planner=assert(ns.LibAPRNavigationV2.New(source,{clock=function()return 100 end,
                profileClock=options.profileClock,conditionObservation=observation}))
            local result=finish(plan(1,4),1)
            assert(result.estimatedSeconds==33 and not result.diagnostics.certificateComplete)
            local graph=planner.preparation.compiled
            assert(graph.stats.potentialLoads==0 and graph.stats.witnessLoads==0)
            observation.sequence=2;observation.access.open=false
            assert(planner:ObserveConditions(observation) and not planner:IsCurrent(result))
            assert(finish(plan(1,4),1).status=='no_path')
            observation.sequence=3;observation.access.open=nil;planner:ObserveConditions(observation)
            assert(finish(plan(1,4),1).status=='unknown')
            observation.sequence=4;observation.access.open=true;planner:ObserveConditions(observation)
            assert(finish(plan(1,4),1).estimatedSeconds==33)
            assert(graph.stats.potentialLoads==0 and graph.stats.witnessLoads==0)
        ''')

    def test_standard_discovery_includes_the_lua_family_once(self):
        suite = unittest.TestLoader().discover(
            str(ROOT / "tests"), pattern="test_*.py", top_level_dir=str(ROOT)
        )

        def cases(group):
            for test in group:
                if isinstance(test, unittest.TestSuite):
                    yield from cases(test)
                else:
                    yield test.id()

        self.assertEqual(
            list(cases(suite)).count(
                "tests.lua.navigation_v2_cooldowns.test_cooldowns.CooldownTests.test_contracts"
            ),
            1,
        )

    test_wait_cost_and_replacement_do_not_reuse_static_witnesses = atlas_contract(b'''
            assert(finish(plan(1,4)).estimatedSeconds==33)
            local declarations={{id='recall',kind='spell',spellID=901,to=refs[3],name='Recall',
                destination={space='world',phase='present'},useSeconds=2,loadingSeconds=1,
                cooldownSeconds=60,timeoutSeconds=20}}
            local observation={revision=1,observedAt=100,combat=false,casting=false,loading=false,
                origin={node=refs[1],reliable=true},
                actions={recall={known=true,loaded=true,usable=true,readyAt=112}}}
            planner=assert(ns.LibAPRNavigationV2.New(source,{clock=function()return 100 end,
                profileClock=options.profileClock,personal=declarations,personalObservation=observation}))
            local result=finish(plan(1,4),1)
            assert(result.estimatedSeconds==26 and result.segments[1].costDetail.waitSeconds==12)
            assert(not result.diagnostics.certificateComplete)
            local graph=planner.preparation.compiled
            assert(graph.stats.potentialLoads==0 and graph.stats.witnessLoads==0)
            observation.revision=2;observation.actions.recall.readyAt=120
            assert(planner:ObservePersonal(observation) and not planner:IsCurrent(result))
            assert(finish(plan(1,4),1).estimatedSeconds==33)
            observation.revision=3;observation.actions.recall.readyAt=102
            assert(planner:ObservePersonal(observation))
            assert(finish(plan(1,4),1).estimatedSeconds==16)
            assert(graph.stats.potentialLoads==0 and graph.stats.witnessLoads==0)
            assert(planner.budgets.sliceMs==1 and planner.budgets.cpuMs==100 and planner.budgets.elapsedMs==5000)
        ''')
