"""Calibration runtime dependencies in both actual client packages."""
from pathlib import Path
import unittest

from tools.validation.check_package import validate_runtime_files

ROOT = Path(__file__).resolve().parents[2]


class CalibrationManifestTests(unittest.TestCase):
    def test_real_client_dependency_order(self):
        for client in ("Standard", "Camelot"):
            with self.subTest(client=client):
                refs = validate_runtime_files(ROOT, ROOT / "APR.toc", client)
                paths = [path.relative_to(ROOT).as_posix() for path in refs]
                core = "APR-Core/libs/LibAPRNavigation-2.0/Calibration.lua"
                planner = "APR-Core/libs/LibAPRNavigation-2.0/Navigation.lua"
                adapter = "APR-Core/features/navigation/NavigationV2Calibration.lua"
                host = "APR-Core/features/navigation/NavigationV2.lua"
                for path in (core, planner, adapter, host):
                    self.assertEqual(refs[(ROOT / path).resolve()], 1)
                self.assertLess(paths.index(core), paths.index(planner))
                self.assertLess(paths.index(adapter), paths.index(host))

    def test_price_changes_cannot_reuse_a_prepared_witness(self):
        from tests.lua.navigation_v2_sectors.test_prepared import prepared

        lua, _, _ = prepared([[0, 0, 0]] * 3,
                             [[1, 2, 20000], [2, 3, 20000]], node_limit=1)
        lua.execute(b"""
            local before=finish(plan(1,3))
            assert(before.estimatedSeconds==40)
            assert(before.diagnostics.certificateComplete)
            planner=assert(ns.LibAPRNavigationV2.New(source,{
                clock=function()return 100 end,profileClock=options.profileClock,
                portals={{id='gate',from=refs[1],to=refs[3],phase='present',
                    destination={space='far',phase='present'},waitSeconds=0,useSeconds=1,
                    loadingSeconds=49,timeoutSeconds=60}},
                portalObservation={revision=1,phase='present',portals={gate={open=true,access=true}}}}))
            local old=finish(plan(1,3))
            assert(old.estimatedSeconds==40)
            local costs=assert(ns.NavigationV2Calibration.New({
                identity={client='Forever',build='test',character='test',computer='test'},
                definitions={{key='portal/gate/loading',component='loading',defaultSeconds=49}}}))
            assert(costs:SetManual('portal/gate/loading',1))
            local revision=planner.revision
            assert(planner:ApplyCalibrationCosts({{kind='portal',id='gate',costs={loadingSeconds=costs:Get('portal/gate/loading')}}}))
            assert(planner.revision==revision+1 and not planner:IsCurrent(old))
            local fresh=finish(plan(1,3),1)
            assert(fresh.status=='complete' and fresh.estimatedSeconds==2 and fresh.segments[1].kind=='portal')
            assert(not fresh.diagnostics.certificateComplete and not fresh.diagnostics.witnessEdges)
            local stats=planner.preparation.compiled.stats
            assert(stats.geometryLoads==0 and stats.witnessLoads==0 and stats.potentialLoads==0)
        """)
