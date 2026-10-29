"""Bundled audio is published to the shared library before its APR consumers."""

from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


ROOT = Path(__file__).resolve().parents[2]
MODULE = "APR-Core/utils/SharedMedia.lua"


class SharedMediaTests(unittest.TestCase):
    def test_packaged_sounds_share_the_real_library_index(self):
        runtime = LuaRuntime(unpack_returned_tuples=True)
        runtime.execute("""
            APR = {}
            function GetLocale() return "enUS" end
            strmatch = string.match
            function securecallfunction(callback, ...) return callback(...) end
            bit = {band = function(left, right)
                local result, bitValue = 0, 1
                while left > 0 and right > 0 do
                    if left % 2 == 1 and right % 2 == 1 then result = result + bitValue end
                    left, right, bitValue = math.floor(left / 2), math.floor(right / 2), bitValue * 2
                end
                return result
            end}
            C_UIFileAsset = {IsKnownFile = function() return true end}
            function geterrorhandler() return error end
            function PlaySoundFile() error("Media registration cannot play a sound") end
        """)
        for path in (
            "APR-Core/libs/HereBeDragons/LibStub/LibStub.lua",
            "APR-Core/libs/HereBeDragons/CallbackHandler-1.0/CallbackHandler-1.0.lua",
            "APR-Core/libs/LibSharedMedia-3.0/LibSharedMedia-3.0.lua",
        ):
            runtime.execute((ROOT / path).read_text(encoding="utf-8-sig"))
        runtime.execute("""
            media = LibStub("LibSharedMedia-3.0")
            media:Register("sound", "Synthetic external media", "Interface\\\\AddOns\\\\Synthetic\\\\alert.ogg")
            existingIndex = media:List("sound")
            registrations, notifications = {}, 0
            local original = media.Register
            function media:Register(kind, name, file)
                registrations[#registrations + 1] = {kind = kind, name = name, file = file}
                return original(self, kind, name, file)
            end
            local observer = {}
            media.RegisterCallback(observer, "LibSharedMedia_Registered", function(_, kind)
                if kind == "sound" then notifications = notifications + 1 end
            end)
        """)
        source = (ROOT / MODULE).read_text(encoding="utf-8-sig")
        runtime.execute(source)
        declarations = list(runtime.globals().registrations.values())
        self.assertTrue(declarations, "APR must publish its packaged audio")
        published = set()
        registered_files = set()
        names = set()
        prefix = "Interface\\AddOns\\APR\\"
        for declaration in declarations:
            with self.subTest(name=declaration["name"]):
                self.assertEqual(declaration["kind"], "sound")
                self.assertTrue(declaration["name"].startswith("APR - "))
                self.assertNotIn(declaration["name"], names)
                names.add(declaration["name"])
                self.assertTrue(declaration["file"].startswith(prefix))
                relative = declaration["file"][len(prefix):].replace("\\", "/")
                self.assertTrue((ROOT / relative).is_file(), relative)
                published.add(relative)
                registered_files.add(declaration["file"])
        bundled = {
            path.relative_to(ROOT).as_posix()
            for path in (ROOT / "APR-Core/assets").rglob("*")
            if path.is_file() and path.suffix.lower() in {".mp3", ".ogg", ".wav"}
        }
        self.assertEqual(published, bundled)
        self.assert_companion_mapping(runtime, registered_files)
        runtime.execute("""
            assert(media:List("sound") == existingIndex, "Other addons keep the same live shared-media index")
            local present = {}
            for _, name in ipairs(existingIndex) do present[name] = true end
            for _, declaration in ipairs(registrations) do
                assert(present[declaration.name])
                assert(media:Fetch("sound", declaration.name, true) == declaration.file)
            end
            assert(media:Fetch("sound", "Synthetic external media", true))
        """)
        notifications = runtime.globals().notifications
        self.assertEqual(notifications, len(declarations))
        runtime.execute(source)
        self.assertEqual(runtime.globals().notifications, notifications,
                         "Repeated module evaluation cannot duplicate media or replace existing registrations")

    def test_registration_precedes_all_toc_shared_media_consumers(self):
        entries = [line.strip().replace("\\", "/")
                   for line in (ROOT / "APR.toc").read_text(encoding="utf-8-sig").splitlines()
                   if line.strip() and not line.startswith("#")]
        self.assertEqual(entries.count(MODULE), 1)
        self.assertLess(entries.index("APR-Core/libs/embeds.xml"), entries.index(MODULE))
        self.assertLess(entries.index("APR-Core/core/Core.lua"), entries.index(MODULE),
                        "The addon object must exist before its bundled sound mapping is declared")
        for entry in entries:
            path = ROOT / entry
            if entry != MODULE and path.suffix == ".lua" and "LibSharedMedia-3.0" in path.read_text(encoding="utf-8-sig"):
                with self.subTest(consumer=entry):
                    self.assertLess(entries.index(MODULE), entries.index(entry))

    def test_unavailable_optional_library_is_safe(self):
        source = (ROOT / MODULE).read_text(encoding="utf-8-sig")
        for setup in ("", "function LibStub() return nil end", "function LibStub() return {} end"):
            with self.subTest(setup=setup):
                runtime = LuaRuntime()
                runtime.execute("APR = {}; " + setup)
                runtime.execute(source)
                self.assert_companion_mapping(runtime)

    def assert_companion_mapping(self, runtime, registered_files=None):
        mapping = runtime.globals().APR.CompanionSoundFiles
        self.assertIsNotNone(mapping, "Bundled default sounds must not depend on optional library availability")
        declared = dict(mapping.items())
        self.assertTrue(declared)
        self.assertEqual(len(set(declared.values())), len(declared), "Each event has a distinct default sound")
        # Discover supported events from their owner rather than freezing a palette
        # inventory in this test. Native labels are only evaluated when options open.
        runtime.execute("""
            local previous = LibStub
            function LibStub(name, ...)
                if name == "AceLocale-3.0" then
                    return {GetLocale = function() return {} end}
                end
                return previous and previous(name, ...)
            end
        """)
        runtime.execute((ROOT / "APR-Core/config/Config_GroupFinder.lua").read_text(encoding="utf-8-sig"))
        events = set(runtime.globals().APR.GroupFinderDefaults.sounds.keys())
        self.assertEqual(set(declared), events, "Every supported sound event has a bundled default")
        prefix = "Interface\\AddOns\\APR\\"
        for event, file in declared.items():
            with self.subTest(event=event):
                self.assertIsInstance(event, str)
                self.assertIsInstance(file, str)
                self.assertTrue(file.startswith(prefix))
                relative = Path(file[len(prefix):].replace("\\", "/"))
                self.assertFalse(relative.is_absolute())
                self.assertNotIn("..", relative.parts)
                self.assertEqual(relative.suffix.lower(), ".ogg")
                self.assertTrue((ROOT / relative).is_file())
                if registered_files is not None:
                    self.assertIn(file, registered_files, "Defaults must also be available in the shared-media picker")

    def test_bundled_ogg_files_are_complete_vorbis_streams(self):
        # Check the codec as well as the extension: Ogg can also carry codecs that
        # the game does not play. These assertions describe the file contract,
        # without freezing filenames, durations, musical notes or binary hashes.
        for path in (ROOT / "APR-Core/assets").rglob("*"):
            if not path.is_file() or path.suffix.lower() != ".ogg":
                continue
            with self.subTest(file=path.relative_to(ROOT).as_posix()):
                data = path.read_bytes()
                offset, first, last_flags = 0, True, 0
                while offset < len(data):
                    self.assertGreaterEqual(len(data) - offset, 27, "Truncated Ogg page header")
                    self.assertEqual(data[offset:offset + 4], b"OggS")
                    self.assertEqual(data[offset + 4], 0, "Unsupported Ogg version")
                    last_flags = data[offset + 5]
                    segments = data[offset + 26]
                    body_start = offset + 27 + segments
                    self.assertLessEqual(body_start, len(data), "Truncated Ogg lacing table")
                    body_size = sum(data[offset + 27:body_start])
                    next_offset = body_start + body_size
                    self.assertLessEqual(next_offset, len(data), "Truncated Ogg page body")
                    if first:
                        self.assertTrue(last_flags & 2, "Missing beginning-of-stream page")
                        self.assertEqual(data[body_start:body_start + 7], b"\x01vorbis")
                        self.assertGreaterEqual(body_size, 30, "Truncated Vorbis identification header")
                        self.assertGreater(data[body_start + 11], 0, "Vorbis audio requires channels")
                        self.assertGreater(int.from_bytes(data[body_start + 12:body_start + 16], "little"), 0)
                        first = False
                    offset = next_offset
                self.assertFalse(first, "An Ogg file must contain audio pages")
                self.assertTrue(last_flags & 4, "Missing end-of-stream page")
