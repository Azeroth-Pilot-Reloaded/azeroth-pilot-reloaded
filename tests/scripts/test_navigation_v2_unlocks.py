"""Real package/discovery and sector solver contracts for simple prerequisites."""
from pathlib import Path
import unittest

from tests.lua.navigation_v2_sectors.test_prepared import prepared
from tools.validation.check_package import validate_runtime_files

ROOT = Path(__file__).resolve().parents[2]


def case_ids(group):
    for test in group:
        if isinstance(test, unittest.TestSuite):
            yield from case_ids(test)
        else:
            yield test.id()


class UnlockIntegrationTests(unittest.TestCase):
    def test_actual_manifests_and_standard_discovery(self):
        core = "APR-Core/libs/LibAPRNavigation-2.0/Unlocks.lua"
        library = "APR-Core/libs/LibAPRNavigation-2.0/Navigation.lua"
        for client in ("Standard", "Camelot"):
            with self.subTest(client=client):
                refs = validate_runtime_files(ROOT, ROOT / "APR.toc", client)
                self.assertEqual(refs[(ROOT / core).resolve()], 1)
                self.assertLess(list(refs).index((ROOT / core).resolve()), list(refs).index((ROOT / library).resolve()))
        suite = unittest.TestLoader().discover(str(ROOT / "tests"), pattern="test_*.py", top_level_dir=str(ROOT))
        self.assertEqual(list(case_ids(suite)).count("tests.lua.navigation_v2_unlocks.test_unlocks.UnlockTests.test_contracts"), 1)

    def test_partitioned_approach_and_usable_detour(self):
        for detour in (False, True):
            with self.subTest(detour=detour):
                edges = [[1, 2, 2000]] + ([[1, 3, 100000]] if detour else [])
                lua, _, _ = prepared([[0, 0, 0]] * 3, edges, node_limit=1)
                lua.globals().hasDetour = detour
                lua.execute(b'''
                    local gate={access={{key='garden-open',allowed=true}}}
                    planner=assert(ns.LibAPRNavigationV2.New(source,{clock=function()return 100 end,
                        profileClock=options.profileClock,
                        portals={{id='garden-door',from=refs[1],to=refs[3],phase='present',
                            destination={space='garden',phase='present'},waitSeconds=0,useSeconds=1,
                            loadingSeconds=1,timeoutSeconds=10,requirements=gate}},
                        portalObservation={revision=1,phase='present',portals={['garden-door']={open=true,access=true}}},
                        conditionObservation={sequence=1,worldState='ready',access={['garden-open']=false}},
                        unlocks={{id='speak-keeper',destination=refs[3],node=refs[2],title='Speak to the keeper',opens=gate}}}))
                    local result=finish(plan(1,3),1)
                    assert(result.status=='complete')
                    if hasDetour then assert(not result.unlock and result.estimatedSeconds==100)
                    else assert(result.unlock and result.estimatedSeconds==2 and result.travelObjective.to==refs[2])end
                    local graph=planner.preparation.compiled
                    assert(not result.diagnostics.certificateComplete)
                    assert(graph.stats.potentialLoads==0 and graph.stats.witnessLoads==0)
                ''')

    def test_missing_sector_never_starts_an_unlock(self):
        lua, _, _ = prepared([[0, 0, 0]] * 3, [[1, 2, 2000]], node_limit=1, enabled=False)
        lua.execute(b'''
            source.loader.catalog={}
            local gate={access={{key='garden-open',allowed=true}}}
            planner=assert(ns.LibAPRNavigationV2.New(source,{clock=function()return 100 end,
                profileClock=options.profileClock,
                conditionObservation={sequence=1,worldState='ready',access={['garden-open']=false}},
                unlocks={{id='keeper',destination=refs[3],node=refs[2],title='Speak to the keeper',opens=gate}}}))
            local result=finish(plan(1,3),1)
            assert(result.status=='unknown' and result.reason=='sector_absent' and not result.unlock)
        ''')
