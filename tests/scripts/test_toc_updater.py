#!/usr/bin/env python3
"""Regression tests for the TOC updater."""

from __future__ import annotations

import importlib.util
import io
import tempfile
import unittest
from pathlib import Path
from unittest import mock


SCRIPT = Path(__file__).resolve().parents[2] / ".github/scripts/toc-updater.py"
SPEC = importlib.util.spec_from_file_location("toc_updater", SCRIPT)
assert SPEC and SPEC.loader
toc_updater = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(toc_updater)


class Response(io.BytesIO):
    def __enter__(self) -> Response:
        return self

    def __exit__(self, *_args: object) -> None:
        self.close()


class TocUpdaterTests(unittest.TestCase):
    def test_reads_a_valid_build_from_blizzard_feed(self) -> None:
        payload = (
            "Region!STRING:0|BuildConfig!HEX:16|CDNConfig!HEX:16|"
            "KeyRing!HEX:16|BuildId!DEC:4|VersionsName!STRING:0|ProductConfig!HEX:16\n"
            "eu|a|b|c|69587|12.1.0.69587|d\n"
            "us|a|b|c|69587|12.1.0.69587|d\n"
        ).encode()
        with mock.patch.object(
            toc_updater.urllib.request, "urlopen", return_value=Response(payload)
        ):
            self.assertEqual(
                "12.1.0.69587", toc_updater.get_product_build("wow", "us")
            )

    def test_rejects_an_invalid_feed_instead_of_returning_zero(self) -> None:
        with mock.patch.object(
            toc_updater.urllib.request,
            "urlopen",
            return_value=Response(b"us|a|b|c|0|not-a-build|d\n"),
        ):
            with self.assertRaisesRegex(RuntimeError, "No valid build"):
                toc_updater.get_product_build("wow")

    def test_converts_retail_and_classic_builds(self) -> None:
        self.assertEqual(120100, toc_updater.build_to_interface("12.1.0.69587"))
        self.assertEqual(11508, toc_updater.build_to_interface("1.15.8.12345"))

    def test_preserves_existing_versions_and_adds_new_ones(self) -> None:
        original = (
            "## Interface: 110207, 120000, 120001\r\n"
            "## X-Interface: 120001\r\n\r\n"
            "## Title: APR\r\n"
        )
        expected = (
            "## Interface: 110207, 120000, 120001, 120005, 120100\r\n"
            "## X-Interface: 120100\r\n\r\n"
            "## Title: APR\r\n"
        )
        self.assertEqual(
            expected, toc_updater.update_toc_content(original, {120005, 120100})
        )

    def test_an_older_ptr_never_downgrades_x_interface(self) -> None:
        original = "## Interface: 120007, 120100\n## X-Interface: 120100\n"
        self.assertEqual(
            original, toc_updater.update_toc_content(original, {120007})
        )

    def test_rejects_zero_interfaces(self) -> None:
        original = "## Interface: 120100\n## X-Interface: 120100\n"
        with self.assertRaisesRegex(ValueError, "Invalid TOC Interface"):
            toc_updater.update_toc_content(original, {0})

    def test_rejects_discovered_non_retail_interface(self) -> None:
        original = ("## Interface: 16001, 120100\n## Interface-Retail: 120100\n"
                    "## Interface-Camelot: 16001\n## X-Interface: 120100\n")
        with self.assertRaisesRegex(ValueError, "non-Retail"):
            toc_updater.update_toc_content(original, {16001})

    def test_mixed_interface_is_unchanged_without_new_retail_versions(self) -> None:
        original = (
            "## Interface: 16001, 110207, 120100, 120105\r\n"
            "## Interface-Retail: 110207, 120100, 120105\r\n"
            "## X-Interface: 120105\r\n"
            "## Interface-Camelot: 16001\r\n\r\n"
            "## Title: APR\r\n"
        )
        self.assertEqual(
            original, toc_updater.update_toc_content(original, {120100, 120105})
        )

    def test_updates_retail_metadata_and_preserves_other_clients(self) -> None:
        # General Interface and Retail metadata have different preservation rules.
        cases = (
            ("retail fallback", "120100", "120100", "Camelot", 16001, "120100, 120105"),
            ("mixed fallback", "16001, 120100", "120100", "Camelot", 16001, "16001, 120100, 120105"),
            ("mixed retail", "120100, 16001", "120100, 16001", "Camelot", 16001, "16001, 120100, 120105"),
            ("higher non-retail version", "120100, 990001", "120100", "Custom", 990001, "120100, 120105, 990001"),
        )
        for name, general, retail, client, version, expected_general in cases:
            for newline in ("\n", "\r\n"):
                with self.subTest(case=name, newline=repr(newline)):
                    original = newline.join((
                        f"## Interface: {general}", f"## Interface-Retail: {retail}",
                        "## X-Interface: 120100", f"## Interface-{client}: {version}", "",
                    ))
                    expected = newline.join((
                        f"## Interface: {expected_general}", "## Interface-Retail: 120100, 120105",
                        "## X-Interface: 120105", f"## Interface-{client}: {version}", "",
                    ))
                    updated = toc_updater.update_toc_content(original, {120105})
                    self.assertEqual(expected, updated)
                    self.assertEqual(updated, toc_updater.update_toc_content(updated, {120105}))

    def test_failed_product_lookup_does_not_touch_the_toc(self) -> None:
        original = "## Interface: 120100\n## X-Interface: 120100\n"
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "APR.toc"
            path.write_text(original, encoding="utf-8")
            with mock.patch.object(
                toc_updater,
                "get_product_build",
                side_effect=["12.1.0.69587", RuntimeError("PTR unavailable")],
            ):
                with self.assertRaisesRegex(RuntimeError, "PTR unavailable"):
                    toc_updater.update_toc(path, ("wow", "wowt"))
            self.assertEqual(original, path.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
