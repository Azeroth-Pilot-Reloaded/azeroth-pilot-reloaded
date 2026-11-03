"""Conditional chains through real partitioned loading and standard discovery."""
from pathlib import Path
import unittest

from tests.lua.navigation_v2_sectors.test_prepared import prepared
from tests.scripts.test_navigation_v2_unlocks import case_ids

ROOT = Path(__file__).resolve().parents[2]


class UnlockChainIntegrationTests(unittest.TestCase):
    def test_discovery(self):
        suite = unittest.TestLoader().discover(
            str(ROOT / "tests"), pattern="test_*.py", top_level_dir=str(ROOT)
        )
        self.assertEqual(
            list(case_ids(suite)).count(
                "tests.lua.navigation_v2_unlock_chains.test_chains.ChainTests.test_contracts"
            ),
            1,
        )

    def test_partitioned_total_cost_and_native_prefix(self):
        for detour in (False, True):
            with self.subTest(detour=detour):
                edges = [[1, 2, 2000]] + ([[1, 3, 100000]] if detour else [])
                lua, _, _ = prepared([[0, 0, 0]] * 3, edges, node_limit=1)
                lua.globals().hasDetour = detour
                lua.execute(b'''
                    local function Gate(key)return {access={{key=key,allowed=true}}}end
                    local entries={
                        {id='first',destination=refs[3],node=refs[2],title='Speak to the keeper',
                            completionSeconds=3,opens=Gate('first')},
                        {id='second',destination=refs[3],node=refs[2],title='Ask for passage',
                            completionSeconds=5,opens=Gate('second'),requirements=Gate('first')}}
                    planner=assert(ns.LibAPRNavigationV2.New(source,{clock=function()return 100 end,
                        profileClock=options.profileClock,
                        portals={{id='door',from=refs[2],to=refs[3],phase='present',
                            destination={space='garden',phase='present'},waitSeconds=0,useSeconds=1,
                            loadingSeconds=1,timeoutSeconds=10,
                            requirements={access={{key='first',allowed=true},{key='second',allowed=true}}}}},
                        portalObservation={revision=1,phase='present',portals={door={open=true,access=true}}},
                        conditionObservation={sequence=1,worldState='ready',access={first=false,second=false}},
                        unlocks=entries}))
                    local result=finish(plan(1,3),1)
                    assert(result.status=='complete' and result.objective.to==refs[3])
                    if hasDetour then assert(not result.unlock and result.estimatedSeconds==100)
                    else
                        assert(result.unlock.id=='first' and result.estimatedSeconds==2)
                        assert(result.unlockPlan.estimatedSeconds==12 and result.unlockPlan.optimal)
                        assert(#result.unlockPlan.steps==2 and #result.segments==1)
                        assert(result.travelObjective.to==refs[2])
                        assert(planner.conditions.snapshot.access.first==false)
                    end
                    local graph=planner.preparation.compiled
                    assert(not result.diagnostics.certificateComplete)
                    assert(graph.stats.potentialLoads==0 and graph.stats.witnessLoads==0)
                ''')
