"""Personal overlays through actual client manifests and an audited static atlas."""
from collections import Counter
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

from tests.lua.navigation_v2_sectors.test_prepared import prepared


ROOT = Path(__file__).resolve().parents[2]


class PersonalIntegrationTests(unittest.TestCase):
    def test_client_manifests_register_each_library_script_once(self):
        toc = (ROOT / "APR.toc").read_text(encoding="utf-8-sig").splitlines()
        for client in ("Standard", "Camelot"):
            with self.subTest(client=client):
                entries = [line.strip().replace("[Game]", client) for line in toc
                           if line.strip() and not line.startswith("#")]
                library = "APR-Core/libs/LibAPRNavigation-2.0/LibAPRNavigation.xml"
                self.assertEqual(entries.count(library), 1)
                xml = ROOT / library
                scripts = [(xml.parent / element.attrib["file"]).resolve()
                           for element in ET.parse(xml).getroot()
                           if element.tag.rsplit("}", 1)[-1] == "Script"]
                duplicates = {path.relative_to(ROOT).as_posix(): count
                              for path, count in Counter(scripts).items() if count != 1}
                self.assertEqual(duplicates, {}, "XML scripts must not execute twice")
                adapter = "APR-Core/features/navigation/NavigationV2Personal.lua"
                host = "APR-Core/features/navigation/NavigationV2.lua"
                self.assertEqual(entries.count(adapter), 1)
                self.assertLess(entries.index(library), entries.index(adapter))
                self.assertLess(entries.index(adapter), entries.index(host))
                for entry in entries:
                    if entry.startswith("Routes/RouteList_"):
                        self.assertTrue((ROOT / entry).is_file())

    def test_personal_overlay_cost_and_snapshot_disable_static_certificates(self):
        lua, _, _ = prepared([[0, 0, 0]] * 4,
                             [[1, 2, 11000], [2, 3, 11000], [3, 4, 11000]],
                             landmarks=2, node_limit=2)
        lua.execute(b'''
            local before=finish(plan(1,4))
            assert(before.estimatedSeconds==33 and before.status=='complete')
            local d={{id='recall',kind='spell',spellID=901,to=refs[3],name='Recall',
                destination={space='world',phase='present'},useSeconds=2,loadingSeconds=1,
                cooldownSeconds=60,timeoutSeconds=20}}
            local o={revision=1,observedAt=100,combat=false,casting=false,loading=false,
                origin={node=refs[1],reliable=true,space='cave',phase='present',indoors=true},
                actions={recall={known=true,loaded=true,usable=true,readyAt=0}}}
            planner=assert(ns.LibAPRNavigationV2.New(source,{clock=function()return 100 end,
                profileClock=options.profileClock,personal=d,personalObservation=o}))
            local r=finish(plan(1,4),1)
            assert(r.status=='complete' and r.estimatedSeconds==14)
            assert(r.segments[1].personalId=='recall' and not r.diagnostics.certificateComplete)
            local graph=planner.preparation.compiled
            assert(graph.stats.potentialLoads==0 and graph.stats.witnessLoads==0 and graph.stats.geometryLoads==0)
            assert(planner:SetPersonalCosts('recall',{useSeconds=30}))
            assert(not planner:IsCurrent(r) and finish(plan(1,4)).estimatedSeconds==33)
            assert(planner:SetPersonalCosts('recall',{useSeconds=1}))
            assert(finish(plan(1,4)).estimatedSeconds==13)
            o.revision=2;o.actions.recall.usable=false
            assert(planner:ObservePersonal(o));assert(finish(plan(1,4)).estimatedSeconds==33)
            assert(graph.stats.potentialLoads==0 and graph.stats.witnessLoads==0)
            assert(planner.budgets.sliceMs==1 and planner.budgets.cpuMs==100 and planner.budgets.elapsedMs==5000)
        ''')
