"""Native road authoring contracts, independent of maintained journeys."""

import copy
from pathlib import Path
import tempfile
import unittest

from tools.navigation.road_data import (
    DATA, read_declarations, render, validate_catalogue,
    validate_collision, validate_network,
)


def network():
    return {"id": "example-valley", "instanceID": 7, "kind": "world",
            "collision": {"base": "example-valley-ground", "overlays": []},
            "sections": [{"id": "example-valley-streets", "kind": "road", "joinRadius": 12,
                          "nodes": [{"id": "example-valley-bank", "x": 0, "y": 0, "z": 8},
                                    {"id": "example-valley-bridge", "x": 10, "y": 0, "z": 8}],
                          "edges": [{"id": "example-valley-bank-to-bridge",
                                     "from": "example-valley-bank", "to": "example-valley-bridge",
                                     "kind": "road", "points": [{"x": 0, "y": 0, "z": 8},
                                                                 {"x": 4, "y": 6, "z": 9},
                                                                 {"x": 10, "y": 0, "z": 8}]}],
                          "joins": ["example-valley-bank"]}], "walls": [], "openings": []}


def mask():
    return {"id": "example-valley-ground", "originX": 10, "originY": 10,
            "cellSize": 2, "width": 10, "height": 2,
            "rows": [[{"from": 1, "to": 10, "state": "open"}],
                     [{"from": 1, "to": 4, "state": "open"},
                      {"from": 5, "to": 5, "state": "blocked"},
                      {"from": 6, "to": 10, "state": "open"}]]}


class RoadDataTests(unittest.TestCase):
    def test_explicit_geometry_and_readable_ids_are_valid(self):
        value = network()
        original = copy.deepcopy(value)
        identities = validate_network(value)
        self.assertIn("example-valley-bank-to-bridge", identities)
        self.assertEqual(value, original, "Validation never rewrites author data")

    def test_unknown_fields_and_nonfinite_coordinates_are_rejected(self):
        for key in ("art", "texture", "heights", "hills", "history"):
            with self.subTest(key=key):
                value = network()
                value[key] = {}
                with self.assertRaises(ValueError):
                    validate_network(value)
        value = network()
        value["sections"][0]["nodes"][0]["z"] = float("nan")
        with self.assertRaises(ValueError):
            validate_network(value)

    def test_duplicate_names_bad_references_and_unknown_kinds_fail(self):
        for kind in ("duplicate", "endpoint", "join", "kind", "opaque"):
            with self.subTest(kind=kind):
                value = network()
                section = value["sections"][0]
                if kind == "duplicate":
                    section["nodes"].append(copy.deepcopy(section["nodes"][0]))
                elif kind == "endpoint":
                    section["edges"][0]["to"] = "missing-room"
                elif kind == "join":
                    section["joins"] = ["missing-room"]
                elif kind == "kind":
                    section["edges"][0]["kind"] = "unknown"
                else:
                    section["nodes"][0]["id"] = "Invalid Name"
                with self.assertRaises(ValueError):
                    validate_network(value)

    def test_collision_rows_accept_explicit_named_states_without_rewriting(self):
        for state in ("open", "water", "blocked", "inherit", "unknown-floor"):
            with self.subTest(state=state):
                value = mask()
                value["rows"][0][0]["state"] = state
                original = copy.deepcopy(value)
                validate_collision(value)
                self.assertEqual(value, original)

    def test_collision_ranges_reject_gaps_overlaps_bad_bounds_and_bad_types(self):
        invalid_rows = [
            [{"from": 2, "to": 10, "state": "open"}],
            [{"from": 1, "to": 4, "state": "open"}, {"from": 6, "to": 10, "state": "blocked"}],
            [{"from": 1, "to": 5, "state": "open"}, {"from": 5, "to": 10, "state": "blocked"}],
            [{"from": 1, "to": 11, "state": "open"}],
            [{"from": 1, "to": 0, "state": "open"}],
            [{"from": 1.5, "to": 10, "state": "open"}],
            [{"from": True, "to": 10, "state": "open"}],
            [{"from": 1, "to": float("inf"), "state": "open"}],
            [{"from": 1, "to": 10, "state": "unknown"}],
            [{"from": 1, "to": 10, "state": ["open"]}],
            [{"from": 1, "to": 10, "state": "open", "count": 10}],
            [], "9", {"from": 1, "to": 10, "state": "open"},
        ]
        for row in invalid_rows:
            with self.subTest(row=row):
                value = mask()
                value["rows"][0] = row
                with self.assertRaises(ValueError):
                    validate_collision(value)

    def test_collision_legacy_fields_and_encoded_rows_are_rejected(self):
        for key, content in (("rowsEncoding", "rle64"), ("shortRun", 21), ("longRun", 3), ("role", "overlay")):
            with self.subTest(key=key):
                value = mask()
                value[key] = content
                with self.assertRaises(ValueError):
                    validate_collision(value)
        for rows in ("9/3g4", ["9", "3g4"], {1: "9", 2: "3g4"}):
            with self.subTest(rows=rows):
                value = mask()
                value["rows"] = rows
                with self.assertRaises(ValueError):
                    validate_collision(value)

    def test_collision_dimensions_and_references_are_required(self):
        value = mask()
        value["rows"][0][0]["to"] = 9
        with self.assertRaises(ValueError):
            validate_collision(value)
        records = [{"api": "RegisterRoadNetwork", "profile": "fixture", "data": network()}]
        with self.assertRaisesRegex(ValueError, "Unknown collision mask"):
            validate_catalogue(records)
        records.append({"api": "RegisterRoadCollision", "profile": "fixture", "data": mask()})
        self.assertEqual(validate_catalogue(records), (1, 1))

    def test_base_cannot_inherit_but_local_masks_can_delegate(self):
        main, base, local = network(), mask(), mask()
        local["id"] = "example-bank-interior"
        local["rows"][0][0]["state"] = "inherit"
        main["collision"]["overlays"] = [local["id"]]
        records = [{"api": "RegisterRoadNetwork", "profile": "fixture", "data": main},
                   {"api": "RegisterRoadCollision", "profile": "fixture", "data": base},
                   {"api": "RegisterRoadCollision", "profile": "fixture", "data": local}]
        self.assertEqual(validate_catalogue(records), (1, 2))
        base["rows"][0][0]["state"] = "inherit"
        with self.assertRaisesRegex(ValueError, "base collision mask cannot inherit"):
            validate_catalogue(records)
        base["rows"][0][0]["state"] = "unknown-floor"
        self.assertEqual(validate_catalogue(records), (1, 2), "An unknown floor remains explicit even in a base mask")

    def test_plain_collision_lua_roundtrip_keeps_every_range(self):
        value = mask()
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "ground.lua"
            content = render("RegisterRoadCollision", "fixture", value, 2)
            path.write_text(content, encoding="utf-8", newline="\n")
            declaration = read_declarations([path])[0]
            self.assertEqual(declaration["data"], value)
            self.assertEqual(content, path.read_text(encoding="utf-8"))

    def test_lua_roundtrip_preserves_geometry_and_manual_additions(self):
        value = network()
        section = value["sections"][0]
        section["nodes"].append({"id": "example-valley-new-door", "x": 11, "y": 3})
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "valley.lua"
            content = render("RegisterRoadNetwork", "fixture", value, 2)
            self.assertEqual(content, render("RegisterRoadNetwork", "fixture", dict(reversed(list(value.items()))), 2),
                             "Canonical field order cannot depend on Lua/Python map iteration")
            path.write_text(content, encoding="utf-8", newline="\n")
            record = read_declarations([path])[0]
            # Empty Lua tables are ambiguous; their empty-array fields stay empty.
            self.assertEqual(record["data"]["sections"], value["sections"])
            self.assertEqual(record["revision"], 2)
            self.assertEqual(path.read_text(encoding="utf-8"), content)


class ShippedRoadContracts(unittest.TestCase):
    def test_all_discovered_declarations_use_the_native_authoring_contract(self):
        paths = sorted(DATA.glob("*/Roads/**/*.lua"))
        before = {path: path.read_bytes() for path in paths}
        records = read_declarations(paths)
        validate_catalogue(records)
        for record in records:
            self.assertEqual(record["profile"], Path(record["file"]).relative_to(DATA).parts[0])
            self.assertGreater(record["revision"], 0)
        self.assertEqual({path: path.read_bytes() for path in paths}, before)


if __name__ == "__main__":
    unittest.main()
