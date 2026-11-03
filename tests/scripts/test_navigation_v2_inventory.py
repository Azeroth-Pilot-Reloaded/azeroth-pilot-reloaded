"""Synthetic identity/evidence contracts; never freeze a shipped place list."""
import copy
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from tools.navigation_v2 import inventory


def source():
    return {
        "schema_version": 1, "client": "forever", "build": "1.2.3.4",
        "sources": [],
        "worlds": [{"world_id": 17, "name": "Amber Vault", "directory": "Vault",
                    "instance_type": 1, "expansion_id": 0, "wdt_file_id": 80}],
        "ui_maps": [{"ui_map_id": 51, "name": "Amber Halls", "parent_ui_map_id": 0,
                     "ui_type": 4}],
        "assignments": [{"ui_map_id": 51, "world_id": 17, "area_id": 3}],
        "entrances": [{"world_id": 17, "kind": "dungeon", "review_status": "confirmed",
                       "interior_ui_map_ids": [51], "exterior_ui_map_id": 66}],
        "spaces": [{"world_id": 17, "kind": "instance", "ui_map_ids": [51]}],
        "dungeons": [{"key": "AMBER", "world_id": 17, "name": "The Amber Vault",
                      "instance_type": "party", "status": "", "boss_count": 2,
                      "encounter_count": 2}],
    }


def write_sources(base):
    tables = base / "tables/wowf/1.2.3.4"
    tables.mkdir(parents=True)
    rows = {
        "Map": [{"ID": "17", "MapName_lang": "Amber Vault", "Directory": "Vault",
                 "InstanceType": "1", "ExpansionID": "0", "WdtFileDataID": "80"}],
        "UiMap": [{"ID": "51", "Name_lang": "Amber Halls", "Type": "4", "ParentUiMapID": "0"}],
        "UiMapAssignment": [{"UiMapID": "51", "MapID": "17", "AreaID": "3"}],
    }
    for name, values in rows.items():
        (tables / (name + ".json")).write_text(json.dumps({"product": "wowf", "build": "1.2.3.4", "rows": values}), encoding="utf-8")
    data = base / "APR-Core/libs/LibAPRNavigation-1.0/Data/forever"
    data.mkdir(parents=True)
    (data / "InstanceEntrances.lua").write_text('''
        LibStub("LibAPRNavigation-1.0"):RegisterData("forever", "instance_entrances", {
            entrances = {{instanceID=17, kind="dungeon", reviewStatus="confirmed",
                interiorMapIDs={51}, exterior={uiMapID=66,x=0.123,y=0.456}}}})
    ''', encoding="utf-8")
    (data / "NavigationSpaces.lua").write_text('''
        LibStub("LibAPRNavigation-1.0"):RegisterData("forever", "navigation-spaces", {
            config={NavigationSpaces={{worldID=17,kind="instance",mapIDs={51},bounds={minX=123}}}}})
    ''', encoding="utf-8")
    dungeons = base / "APR-Core/data/Dungeons"
    dungeons.mkdir(parents=True)
    (dungeons / "DungeonsForever.lua").write_text('''-- Client 1.2.3.3; independent source build.
        APR.DungeonData={forever={AMBER={instanceID=17,name="The Amber Vault",
            instanceType="party",bosses={[200]=true},encounters={[300]=200}}}}
    ''', encoding="utf-8")
    return base / "tables"


class InventoryTests(unittest.TestCase):
    def test_collector_reads_only_declarations_and_pins_source_builds(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            tables = write_sources(base)
            data = inventory.collect_client(base, tables, "forever", "1.2.3.4")
            self.assertEqual(data["worlds"][0]["world_id"], 17)
            self.assertEqual(data["dungeons"][0]["encounter_count"], 1)
            self.assertEqual(data["spaces"], [{"world_id": 17, "kind": "instance", "ui_map_ids": [51]}])
            self.assertEqual(data["entrances"][0]["interior_ui_map_ids"], [51])
            self.assertEqual(len(data["sources"]), 6)
            fact, = [r for r in data["sources"] if r["path"].endswith("DungeonsForever.lua")]
            self.assertEqual(fact["build"], "1.2.3.3")
            self.assertEqual(len(fact["sha256"]), 64)
            self.assertNotIn('"x"', json.dumps(data))
            self.assertEqual(inventory.collect_client(base, tables, "forever", "1.2.3.4"), data)

    def test_collector_rejects_mixed_build_and_wrong_declaration_client(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            tables = write_sources(base)
            native = tables / "wowf/1.2.3.4/Map.json"
            document = json.loads(native.read_text())
            document["build"] = "2.0"
            native.write_text(json.dumps(document))
            with self.assertRaisesRegex(ValueError, "product/build mismatch"):
                inventory.collect_client(base, tables, "forever", "1.2.3.4")
            document["build"] = "1.2.3.4"
            native.write_text(json.dumps(document))
            path = base / "APR-Core/libs/LibAPRNavigation-1.0/Data/forever/InstanceEntrances.lua"
            path.write_text(path.read_text().replace('"forever"', '"retail"'))
            with self.assertRaisesRegex(ValueError, "unexpected declaration"):
                inventory.collect_client(base, tables, "forever", "1.2.3.4")

    def test_declaration_environment_has_no_filesystem_or_python_globals(self):
        from lupa.lua51 import LuaError
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "isolated.lua"
            for expression in ["os.time()", "python.eval('1 + 1')", "io.open('anything')"]:
                path.write_text('APR.result = ' + expression, encoding="utf-8")
                with self.subTest(expression=expression), self.assertRaises(LuaError):
                    inventory.declarations(path)

    def test_exact_identity_joins_aliases_without_name_guessing(self):
        result = inventory.reconcile(source())
        world, = result["worlds"]
        self.assertEqual(world["aliases"], ["Amber Halls", "Amber Vault", "The Amber Vault"])
        self.assertEqual(world["classification"], "playable")
        self.assertEqual(world["ui_map_ids"], [51])
        self.assertFalse(world["activated"])
        self.assertFalse(result["ui_maps"][0]["activated"])
        self.assertEqual(result["ambiguities"], [])
        self.assertEqual(world["kind"], "dungeon")
        self.assertTrue(world["has_navigation_spaces"])

    def test_snapshot_encoding_preserves_readable_unicode_and_stable_key_order(self):
        self.assertEqual(inventory.encoded({"b": 1, "a": "Été"}),
                         '{\n  "a": "Été",\n  "b": 1\n}\n'.encode("utf-8"))

    def test_same_name_different_worlds_remain_distinct_variants(self):
        data = source()
        other = dict(data["worlds"][0], world_id=18, instance_type=2, directory="VaultRaid")
        data["worlds"].append(other)
        result = inventory.reconcile(data)
        self.assertEqual([r["kind"] for r in result["worlds"]], ["dungeon", "raid"])
        self.assertEqual([r["has_navigation_spaces"] for r in result["worlds"]], [True, False])
        ambiguity, = result["ambiguities"]
        self.assertEqual(ambiguity["type"], "name_variants")
        self.assertEqual(ambiguity["world_ids"], [17, 18])

    def test_candidate_entrance_does_not_become_confirmed_from_bosses(self):
        data = source()
        data["entrances"][0]["review_status"] = "candidate"
        self.assertEqual(inventory.reconcile(data)["worlds"][0]["classification"], "candidate")

    def test_entrance_without_world_resolves_only_unique_native_map_identity(self):
        data = source()
        data["entrances"][0].update(world_id=None, kind="delve")
        data["dungeons"] = []
        result = inventory.reconcile(data)
        self.assertEqual(result["worlds"][0]["entrance_kinds"], ["delve"])
        self.assertEqual(result["worlds"][0]["classification"], "playable")
        self.assertEqual(result["unlocated_entrances"], [])
        self.assertIsNone(data["entrances"][0]["world_id"])
        data["assignments"].append({"ui_map_id": 51, "world_id": 18, "area_id": 4})
        result = inventory.reconcile(data)
        unresolved, = result["unlocated_entrances"]
        self.assertEqual(unresolved["possible_world_ids"], [17, 18])
        self.assertNotEqual(result["worlds"][0]["classification"], "playable")

    def test_announced_ticket_resolves_name_without_fabricating_world_identity(self):
        data = source()
        data["dungeons"] = [dict(data["dungeons"][0], name="Future Hall", world_id=None,
                                status="announced", boss_count=0, encounter_count=0)]
        ticket = {"ticket_id": "FI-dungeon-future", "client": "forever", "name": "Future Hall",
                  "kind": "dungeon", "expansion_id": None}
        proposal = inventory.propose([inventory.reconcile(data)], [ticket])
        row, = proposal["tickets"]
        self.assertEqual(row["resolution"], "unlocated")
        self.assertEqual(row["proposed_action"], "resolve_identity")
        self.assertIsNone(row["matches"][0]["world_id"])

    def test_backlog_expansion_prefers_matching_variant_but_reports_bad_native_metadata(self):
        data = source()
        data["worlds"].append(dict(data["worlds"][0], world_id=18, expansion_id=2))
        ticket = {"ticket_id": "RI-wrath-dungeon-amber", "client": "forever", "name": "Amber Vault",
                  "kind": "dungeon", "expansion_id": 2}
        row, = inventory.propose([inventory.reconcile(data)], [ticket])["tickets"]
        self.assertEqual([r["world_id"] for r in row["matches"]], [18])
        ticket["expansion_id"] = 9
        row, = inventory.propose([inventory.reconcile(data)], [ticket])["tickets"]
        self.assertEqual(row["resolution"], "ambiguous")
        self.assertTrue(all(r["expansion_mismatch"] for r in row["matches"]))

    def test_technical_markers_override_catalog_confirmation(self):
        for marker in ["Prototype Amber", "Unused Amber", "Amber Test", "Transport: Amber", "CashTest"]:
            with self.subTest(marker=marker):
                data = source()
                data["worlds"][0]["name"] = marker
                world = inventory.reconcile(data)["worlds"][0]
                self.assertEqual(world["classification"], "technical")
                self.assertFalse(world["activated"])

    def test_charting_one_zone_does_not_confirm_other_subsites_in_the_same_world(self):
        data = source()
        data["worlds"][0]["instance_type"] = 0
        data["entrances"] = []
        data["dungeons"] = []
        data["ui_maps"][0]["ui_type"] = 3
        data["ui_maps"].append(dict(data["ui_maps"][0], ui_map_id=52, name="Unreviewed Cave", ui_type=5))
        data["assignments"].append({"ui_map_id": 52, "world_id": 17, "area_id": 4})
        result = inventory.reconcile(data)
        self.assertEqual(result["ui_maps"][0]["classification"], "playable")
        self.assertEqual(result["ui_maps"][1]["classification"], "candidate")

    def test_unregistered_native_maps_referenced_by_catalogs_are_explicit_gaps(self):
        data = source()
        data["entrances"][0]["interior_ui_map_ids"].append(77)
        data["spaces"][0]["ui_map_ids"].append(78)
        result = inventory.reconcile(data)
        self.assertEqual({r["ui_map_id"] for r in result["gaps"]}, {66, 77, 78})
        self.assertTrue(all(r["type"] == "missing_native_ui_map" for r in result["gaps"]))

    def test_orphan_dungeon_and_announced_without_world_are_retained(self):
        data = source()
        data["dungeons"] = [dict(data["dungeons"][0], world_id=99, name="Lost Hall"),
                            {"key": "FUTURE", "world_id": None, "name": "Future Hall",
                             "instance_type": "party", "status": "announced",
                             "boss_count": 0, "encounter_count": 0}]
        result = inventory.reconcile(data)
        lost = next(r for r in result["worlds"] if r["world_id"] == 99)
        self.assertEqual(lost["classification"], "candidate")
        self.assertIn("missing_native_world", lost["reasons"])
        announced, = result["unlocated"]
        self.assertEqual(announced["name"], "Future Hall")
        self.assertEqual(announced["classification"], "candidate")
        self.assertFalse(announced["activated"])

    def test_conflicting_native_and_entrance_map_links_are_not_silently_merged(self):
        data = source()
        data["assignments"][0]["world_id"] = 18
        result = inventory.reconcile(data)
        conflict = next(a for a in result["ambiguities"] if a["type"] == "ui_world_conflict")
        self.assertEqual(conflict["ui_map_id"], 51)
        self.assertEqual(conflict["native_world_ids"], [18])
        self.assertEqual(conflict["entrance_world_ids"], [17])

    def test_missing_uimap_and_multiple_world_assignments_are_explicit(self):
        data = source()
        data["ui_maps"].append({"ui_map_id": 52, "name": "Empty", "ui_type": 3,
                                "parent_ui_map_id": 0})
        data["assignments"].append({"ui_map_id": 51, "world_id": 18, "area_id": 4})
        result = inventory.reconcile(data)
        self.assertEqual(result["ui_maps"][0]["world_ids"], [17, 18])
        self.assertIn("multiple_world_assignments", result["ui_maps"][0]["reasons"])
        self.assertEqual(result["ui_maps"][1]["classification"], "candidate")
        self.assertIn("missing_world_assignment", result["ui_maps"][1]["reasons"])

    def test_invalid_duplicate_ids_fail_at_input_boundary(self):
        data = source()
        data["worlds"].append(copy.deepcopy(data["worlds"][0]))
        with self.assertRaisesRegex(ValueError, "duplicate.*world_id"):
            inventory.reconcile(data)
        data = source()
        data["assignments"][0]["world_id"] = "17"
        with self.assertRaisesRegex(ValueError, "world_id"):
            inventory.reconcile(data)

    def test_schema_client_and_numeric_id_boundaries_are_checked(self):
        for field, value in [("schema_version", 9), ("client", "unknown")]:
            data = source()
            data[field] = value
            with self.assertRaisesRegex(ValueError, "schema/client"):
                inventory.reconcile(data)
        data = source()
        data["worlds"][0]["world_id"] = 0
        self.assertEqual(inventory.reconcile(data)["worlds"][0]["world_id"], 0)
        for value in [True, 1.5, -1, "2", None]:
            data["worlds"][0]["world_id"] = value
            with self.assertRaisesRegex(ValueError, "world_id"):
                inventory.reconcile(data)
        for value in [True, -2, 1.5]:
            data = source()
            data["entrances"][0]["world_id"] = value
            with self.assertRaisesRegex(ValueError, "world_id"):
                inventory.reconcile(data)
        data = source()
        data["assignments"][0]["world_id"] = -1.0
        with self.assertRaisesRegex(ValueError, "world_id"):
            inventory.reconcile(data)

    def test_encounter_evidence_requires_nonzero_count_and_nonannounced_status(self):
        data = source()
        data["entrances"] = []
        data["dungeons"][0]["encounter_count"] = 1
        self.assertEqual(inventory.reconcile(data)["worlds"][0]["classification"], "playable")
        data["dungeons"][0]["encounter_count"] = 0
        self.assertEqual(inventory.reconcile(data)["worlds"][0]["classification"], "candidate")
        data["dungeons"][0].update(encounter_count=2, status="announced")
        self.assertEqual(inventory.reconcile(data)["worlds"][0]["classification"], "candidate")

    def test_zone_ticket_qualifiers_and_client_variants_stay_scoped(self):
        first = source()
        first["worlds"][0]["instance_type"] = 0
        first["ui_maps"][0]["ui_type"] = 3
        first["worlds"].append(dict(first["worlds"][0], world_id=99, expansion_id=3, name="Unrelated"))
        second = copy.deepcopy(first)
        second["client"] = "retail"
        second["ui_maps"][0]["ui_map_id"] = 52
        ticket = {"ticket_id": "FZ-amber", "name": "Amber Halls — public spaces", "client": "forever",
                  "kind": "outdoor", "expansion_id": 0}
        result = inventory.propose([inventory.reconcile(first), inventory.reconcile(second)], [ticket])
        row, = result["tickets"]
        self.assertEqual(row["resolution"], "resolved")
        self.assertEqual([r["ui_map_id"] for r in row["matches"]], [51])
        self.assertEqual(row["matches"][0]["expansion_ids"], [0])
        self.assertFalse(any(r["client"] == "forever" and r.get("ui_map_id") == 51
                             for r in result["additional_places"]))
        self.assertTrue(any(r["client"] == "retail" and r.get("ui_map_id") == 52
                            for r in result["additional_places"]))

    def test_outdoor_world_requires_a_charted_zone_not_only_type_or_navigation(self):
        for ui_type, spaces in [(3, []), (4, source()["spaces"])]:
            data = source()
            data["worlds"][0]["instance_type"] = 0
            data["entrances"] = []
            data["dungeons"] = []
            data["ui_maps"][0]["ui_type"] = ui_type
            data["spaces"] = spaces
            self.assertEqual(inventory.reconcile(data)["worlds"][0]["classification"], "candidate")

    def test_unlocated_names_require_the_same_activity_kind(self):
        data = source()
        data["dungeons"] = [dict(data["dungeons"][0], name="Future Hall", world_id=None),
                            dict(data["dungeons"][0], name="Another", world_id=None, instance_type="raid")]
        ticket = {"ticket_id": "FI-raid-future", "client": "forever", "name": "Future Hall",
                  "kind": "raid", "expansion_id": None}
        row, = inventory.propose([inventory.reconcile(data)], [ticket])["tickets"]
        self.assertEqual(row["matches"], [])
        self.assertEqual(row["resolution"], "unmatched")

    def test_proposal_quarantines_technical_and_preserves_candidates(self):
        data = source()
        data["worlds"][0]["name"] = "Prototype Vault"
        ticket = {"ticket_id": "FI-dungeon-amber", "name": "Prototype Vault", "client": "forever",
                  "kind": "dungeon", "expansion_id": None}
        row, = inventory.propose([inventory.reconcile(data)], [ticket])["tickets"]
        self.assertEqual(row["proposed_action"], "quarantine_technical")
        data["worlds"][0]["name"] = "Amber Vault"
        data["entrances"][0]["review_status"] = "disabled"
        ticket["name"] = "Amber Vault"
        row, = inventory.propose([inventory.reconcile(data)], [ticket])["tickets"]
        self.assertEqual(row["proposed_action"], "verify_before_coverage")

    def test_native_unassigned_world_sentinel_is_not_a_real_world(self):
        data = source()
        data["assignments"][0]["world_id"] = -1
        result = inventory.reconcile(data)
        self.assertEqual([r["world_id"] for r in result["worlds"]], [17])
        self.assertEqual(result["ui_maps"][0]["world_ids"], [])
        data["assignments"][0]["world_id"] = -2
        with self.assertRaisesRegex(ValueError, "world_id"):
            inventory.reconcile(data)

    def test_reordering_inputs_produces_identical_output(self):
        data = source()
        data["worlds"].append(dict(data["worlds"][0], world_id=18, name="Second", directory="Two"))
        other = copy.deepcopy(data)
        for value in other.values():
            if isinstance(value, list):
                value.reverse()
        self.assertEqual(inventory.reconcile(data), inventory.reconcile(other))

    def test_backlog_uses_kind_and_reports_missing_and_additional_places(self):
        data = source()
        data["worlds"].append(dict(data["worlds"][0], world_id=18, instance_type=2))
        result = inventory.reconcile(data)
        tickets = [{"ticket_id": "FI-dungeon-amber", "client": "forever", "name": "Amber Vault",
                    "kind": "dungeon", "expansion_id": None},
                   {"ticket_id": "FI-raid-absent", "client": "forever", "name": "Absent",
                    "kind": "raid", "expansion_id": None}]
        proposal = inventory.propose([result], tickets)
        first, second = proposal["tickets"]
        self.assertEqual(first["resolution"], "resolved")
        self.assertEqual(first["matches"][0]["world_id"], 17)
        self.assertEqual(second["resolution"], "unmatched")
        self.assertTrue(any(p["world_id"] == 18 for p in proposal["additional_places"]))
        self.assertFalse(proposal["applied"])

    def test_backlog_header_parser_keeps_client_expansion_and_variant(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "place.md"
            path.write_text("# RI-wrath-dungeon-amber — Guider vers et dans Amber — variante donjon — retail / wrath\n", encoding="utf-8")
            Path(tmp, "engine.md").write_text("# NAV-99 — Engine\n", encoding="utf-8")
            ticket, = inventory.read_backlog(Path(tmp))
            self.assertEqual(ticket["name"], "Amber — variante donjon")
            self.assertEqual(ticket["expansion_id"], 2)
            self.assertEqual(ticket["kind"], "dungeon")

    def test_backlog_rejects_unrecognized_place_header(self):
        with tempfile.TemporaryDirectory() as tmp:
            Path(tmp, "broken.md").write_text("# FI-dungeon-amber — malformed\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "unrecognized place ticket"):
                inventory.read_backlog(Path(tmp))

    def test_cli_build_exercises_the_offline_entry_point(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            (base / "forever.json").write_text(json.dumps(source()), encoding="utf-8")
            (base / "backlog.json").write_text("[]", encoding="utf-8")
            with patch("sys.argv", ["inventory.py", "build", "--inputs", str(base), "--output", str(base / "out")]):
                inventory.main()
            self.assertTrue(json.loads((base / "out/inventory.json").read_text())["clients"][0]["worlds"])

    def test_cli_collect_writes_sources_and_backlog(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            tables = write_sources(base)
            issues = base / "issues"
            issues.mkdir()
            output = base / "nested/snapshots"
            args = ["inventory.py", "collect", "--addon-root", str(base), "--tables-root", str(tables),
                    "--forever-build", "1.2.3.4", "--retail-build", "9.8.7.6",
                    "--backlog", str(issues), "--output", str(output)]
            with patch("sys.argv", args), patch.dict(inventory.CLIENTS, {"forever": ("wowf", "DungeonsForever.lua")}, clear=True):
                inventory.main()
                before = {p.name: p.read_bytes() for p in output.iterdir()}
                inventory.main()
                self.assertEqual(before, {p.name: p.read_bytes() for p in output.iterdir()})
            self.assertEqual(json.loads((output / "forever.json").read_text())["build"], "1.2.3.4")
            self.assertEqual(json.loads((output / "backlog.json").read_text()), [])

    def test_cli_reports_all_missing_required_arguments(self):
        with patch("sys.argv", ["inventory.py"]), patch("sys.stderr", new=io.StringIO()):
            with self.assertRaises(SystemExit) as error:
                inventory.main()
            self.assertEqual(error.exception.code, 2)
        for command, options in [("build", ["--inputs", "--output"]),
                                 ("collect", ["--tables-root", "--forever-build", "--retail-build", "--backlog", "--output"])]:
            for absent in options:
                args = ["inventory.py", command] + [part for key in options if key != absent for part in (key, "value")]
                with self.subTest(command=command, absent=absent), patch("sys.argv", args), patch("sys.stderr", new=io.StringIO()):
                    with self.assertRaises(SystemExit) as error:
                        inventory.main()
                    self.assertEqual(error.exception.code, 2)

    def test_build_is_reproducible_and_check_never_repairs_output(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            inputs = base / "inputs"
            inputs.mkdir()
            (inputs / "forever.json").write_text(json.dumps(source()), encoding="utf-8")
            (inputs / "backlog.json").write_text("[]", encoding="utf-8")
            output = base / "nested/output"
            inventory.build(inputs, output)
            expected = {p.name: p.read_bytes() for p in output.iterdir()}
            inventory.build(inputs, output, check=True)
            inventory.build(inputs, output)
            self.assertEqual(expected, {p.name: p.read_bytes() for p in output.iterdir()})
            (output / "inventory.json").write_text("changed", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "stale"):
                inventory.build(inputs, output, check=True)
            self.assertEqual((output / "inventory.json").read_text(), "changed")


if __name__ == "__main__":
    unittest.main()
