"""APR-owned instance catalogue contracts and authoring helpers."""

import copy
import io
from pathlib import Path
import tempfile
import unittest
from contextlib import redirect_stdout

from tools.navigation.instance_connections import (
    ROOT, connection_id, load_catalogue, main, render_catalogue, slug, validate_catalogue,
)


def catalogue():
    return {
        "connections": [{
            "id": "apr-forever-portal-invented-hall-from-invented-valley",
            "kind": "portal", "bidirectional": True,
            "from": {"space": "world", "instanceID": 4, "x": 10, "y": 20},
            "to": {"space": "world", "instanceID": 8, "x": 30, "y": 40, "z": -5},
            "seconds": 15,
        }],
        "entrances": [{
            "id": "apr-forever-entrance-invented-hall-from-invented-valley",
            "kind": "dungeon", "reviewStatus": "confirmed", "instanceID": 8,
            "exterior": {"space": "world", "instanceID": 4, "x": 10, "y": 20},
            "interiorMapIDs": {},
        }],
        "config": {"NavigationSpaces": [{
            "id": "apr-forever-instance-invented-hall", "kind": "instance", "worldID": 8,
            "mapIDs": {}, "requiresExit": True, "groundOnly": True,
            "bounds": {"minX": 0, "maxX": 100, "minY": 0, "maxY": 100, "minZ": -10, "maxZ": 10},
        }]},
    }


def plain_array(value):
    return [value[key] for key in range(1, len(value) + 1)] if isinstance(value, dict) else value


class InstanceCatalogueTests(unittest.TestCase):
    def test_readable_names_and_coordinates_produce_stable_distinct_ids(self):
        self.assertEqual(slug("An Invented Hall's Gate"), "an-invented-halls-gate")
        first = {"x": -12.5, "y": 30, "z": 4}
        target = {"x": 5, "y": -8, "z": -2}
        identifier = connection_id("portal", "Invented Hall", "Invented Valley", first, destination=target)
        self.assertEqual(identifier,
                         "apr-forever-portal-invented-hall-from-invented-valley-at-south-12p5-west-30-height-above-4-to-north-5-east-8-height-below-2")
        self.assertEqual(identifier, connection_id("portal", "Invented Hall", "Invented Valley",
                         dict(reversed(list(first.items()))), destination=target))
        self.assertNotEqual(identifier, connection_id("portal", "Invented Hall", "Invented Valley", first,
                            destination=dict(target, z=3)))
        self.assertNotEqual(identifier, connection_id("portal", "Invented Hall", "Invented Valley", first,
                            destination=dict(target, x=5.0001)))
        with self.assertRaisesRegex(ValueError, "readable place"):
            slug("---")
        with self.assertRaisesRegex(ValueError, "Finite"):
            connection_id("entrance", "Hall", point={"x": float("nan"), "y": 1})

    def test_every_record_uses_a_unique_readable_apr_identity(self):
        data = catalogue()
        self.assertEqual(validate_catalogue(data), {"connections": 1, "entrances": 1, "spaces": 1})
        data["entrances"][0]["id"] = data["connections"][0]["id"]
        with self.assertRaisesRegex(ValueError, "Duplicate APR identity"):
            validate_catalogue(data)
        data["entrances"][0]["id"] = "anonymous"
        with self.assertRaisesRegex(ValueError, "readable APR"):
            validate_catalogue(data)

    def test_directions_native_worlds_and_known_heights_are_preserved(self):
        data = catalogue()
        data["connections"][0]["bidirectional"] = False
        original = copy.deepcopy(data)
        validate_catalogue(data)
        self.assertEqual(data, original)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "connections.lua"
            path.write_text(render_catalogue(data), encoding="utf-8")
            profile, loaded, revision = load_catalogue(path)
        self.assertEqual(profile, "forever")
        self.assertEqual(revision, 1)
        connection = loaded["connections"][1]
        self.assertIs(connection["bidirectional"], False)
        self.assertEqual(connection["from"], original["connections"][0]["from"])
        self.assertEqual(connection["to"], original["connections"][0]["to"])
        self.assertNotIn("z", loaded["entrances"][1]["exterior"])
        self.assertEqual(loaded["entrances"][1]["interiorMapIDs"], {})

    def test_invalid_positions_bounds_and_durations_fail_without_repair(self):
        for change in (
            lambda data: data["connections"][0]["from"].update(instanceID="unknown"),
            lambda data: data["connections"][0]["to"].update(z=float("inf")),
            lambda data: data["connections"][0].update(seconds=-1),
            lambda data: data["connections"][0].update(bidirectional="yes"),
            lambda data: data["config"]["NavigationSpaces"][0]["bounds"].update(maxZ=-10),
            lambda data: data["entrances"][0].update(reviewStatus="assumed"),
        ):
            data = catalogue()
            change(data)
            original = copy.deepcopy(data)
            with self.assertRaises(ValueError):
                validate_catalogue(data)
            self.assertEqual(data, original)

    def test_check_only_validates_and_explicit_format_is_idempotent(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "connections.lua"
            path.write_text(render_catalogue(catalogue()).replace("seconds = 15", "seconds    =    15"), encoding="utf-8")
            original = path.read_bytes()
            with redirect_stdout(io.StringIO()):
                self.assertEqual(main([str(path), "--check"]), 0)
                self.assertEqual(path.read_bytes(), original)
                self.assertEqual(main([str(path), "--format"]), 0)
                formatted = path.read_bytes()
                self.assertEqual(main([str(path), "--format"]), 0)
                self.assertEqual(path.read_bytes(), formatted)
            path.write_text("-- a declaration is missing", encoding="utf-8")
            invalid = path.read_bytes()
            with self.assertRaises(ValueError):
                load_catalogue(path)
            self.assertEqual(path.read_bytes(), invalid)


class MaintainedInstanceCatalogueTests(unittest.TestCase):
    def test_every_discovered_instance_catalogue_uses_the_same_contract(self):
        for path in (ROOT / "APR-Core/libs/LibAPRNavigation-1.0/Data").glob("*/InstanceConnections.lua"):
            with self.subTest(catalogue=path):
                profile, data, revision = load_catalogue(path)
                self.assertEqual(profile, path.parent.name)
                self.assertGreater(revision, 0)
                validate_catalogue(data)
                for entrance in plain_array(data.get("entrances", {})):
                    self.assertNotIn("interior", entrance, "Exterior metadata cannot invent an arrival inside")
                for connection in plain_array(data.get("connections", {})):
                    self.assertNotIn("durationSource", connection, "Travel duration belongs to the maintained record")


if __name__ == "__main__":
    unittest.main()
