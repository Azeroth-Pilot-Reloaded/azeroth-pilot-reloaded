"""Check reload call sites without requiring Lua subprocess support."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]


class ReloadConfirmationSourceTests(unittest.TestCase):
    def test_reload_calls_use_confirmation_service(self):
        core = ROOT / "APR-Core"
        paths = sorted(core.rglob("*.lua"))
        self.assertTrue(paths, "No addon Lua files found")
        for path in paths:
            relative = path.relative_to(core)
            if (relative.as_posix() == "ui/foundations/ReloadConfirmation.lua"
                    or {"libs", "locales"}.intersection(relative.parts[:-1])):
                continue
            with self.subTest(file=path.relative_to(ROOT).as_posix()):
                self.assertNotRegex(
                    path.read_text(encoding="utf-8-sig"),
                    r"ReloadUI\s*\(|C_UI\.Reload\s*\(",
                    "Reload bypasses the shared confirmation",
                )
