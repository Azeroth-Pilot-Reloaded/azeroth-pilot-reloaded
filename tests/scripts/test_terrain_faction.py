import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from tools.forever.terrain_faction import area_owners, collect_hubs, faction_policy_path, prepare


def area(world, mask, parent=0, name="Synthetic area"):
    return {"ContinentID": world, "FactionGroupMask": mask,
            "ParentAreaID": parent, "AreaName_lang": name}


class TerrainFactionTests(unittest.TestCase):
    def test_explicit_neutral_area_keeps_its_children_neutral(self):
        areas = {851: area(1, 4), 852: area(1, 0, 851), 853: area(1, 6, 851),
                 854: area(1, 0, 853), 855: area(0, 0, 851), 856: area(1, 0, 856)}
        self.assertEqual(area_owners(areas, {0, 1}),
                         {0: {}, 1: {"851": "Horde", "852": "Horde", "853": "Neutral", "854": "Neutral"}})

    def test_hubs_in_rival_territory_are_retained_and_shared_areas_skipped(self):
        areas = {851: area(0, 4), 852: area(0, 6)}
        owners = area_owners(areas, {0})[0]
        report = {reason: [] for reason in ("shared", "inconsistent", "outsideCoverage", "overlapsTerritory")}
        records = '\n'.join([
            '{ id = "rival", side = "Alliance", name = "source", areaId = 851, disks = { { 100, -100, 25 } } },',
            '{ id = "shared", side = "Horde", name = "source", areaId = 852, disks = { { 100, -100, 25 } } },',
            '{ id = "missing-tile", side = "Alliance", name = "source", areaId = 851, disks = { { 900, 900, 25 } } },',
        ])
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "hubs.txt"
            path.write_text(records, encoding="utf-8")
            hubs = collect_hubs(0, path, areas, owners, {(32, 31)}, report)
        self.assertEqual([hub["id"] for hub in hubs], ["rival"])
        self.assertEqual(report["overlapsTerritory"], ["rival", "missing-tile"])
        self.assertEqual(report["shared"], ["shared"])
        self.assertEqual(report["outsideCoverage"], ["missing-tile"])

    def test_preparation_writes_the_policy_and_review_to_the_build_directory(self):
        build = "1.0.0.12345"
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)

            def write(name, data):
                path = root / name
                path.write_text(json.dumps(data), encoding="utf-8")
                return path

            identity = {"product": "wowf", "build": build}
            tile = {"x": 32, "y": 31}
            geometry = write("geometry.json", identity | {"selection": "maps", "maps": [
                {"id": world, "tiles": [tile]} for world in (0, 1, 2991)]})
            areas = write("areas.json", identity | {"rows": [
                area(0, 2) | {"ID": 851}, area(1, 4) | {"ID": 852}]})
            factions = write("factions.json", identity | {"rows": [
                {"ID": template, "FactionGroup": group}
                for group, templates in ((2, (1, 3, 4, 115)), (4, (2, 5, 6, 116)))
                for template in templates]})
            joins = write("joins.json", {"cuts": [], "joins": [{"id": "candidate"}]})
            hubs = []
            for world, side, area_id in ((0, "Alliance", 851), (1, "Horde", 852)):
                path = root / f"hubs-{world}.txt"
                path.write_text(f'{{ id = "camp-{world}", side = "{side}", name = "Camp", '
                                f'areaId = {area_id}, disks = {{ {{ 100, -100, 25 }} }} }},\n', encoding="utf-8")
                hubs.append((world, path))

            with patch("tools.forever.terrain_faction.FACTION_DATA", root / "terrain"):
                prepare(SimpleNamespace(geometry=geometry, areas=areas, factions=factions, joins=joins,
                                        hubs=hubs, source_revision="fixture", out=None, report=None))
                policy = faction_policy_path(build)
            self.assertEqual(policy, root / "terrain" / build / "faction.json")
            self.assertEqual(json.loads(policy.read_bytes())["build"], build)
            report = json.loads(policy.with_name("faction-review.json").read_bytes())
            self.assertEqual(report["unverifiedJoins"], ["candidate"])
