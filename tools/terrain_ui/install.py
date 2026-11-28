"""Publish verified Lua packs to stable paths in LibAPRNavigation."""

from contextlib import contextmanager
from hashlib import sha256
import json
import os
from pathlib import Path
import re
import shutil
from tempfile import TemporaryDirectory
from threading import Lock
from xml.etree import ElementTree
from xml.sax.saxutils import quoteattr

from .native import BUILD, PRODUCT, ROOT, read_json, write_json


LIBRARY = ROOT / "APR-Core/libs/LibAPRNavigation-1.0"
XMLNS = "http://www.blizzard.com/wow/ui/"
RETAIL = {"wow", "wowt", "wowxptr", "wow_beta"}
PACK_NAME = re.compile(r"Nav/Nav(\d+)(?:_\d+)?\.lua\Z")
REGISTER = re.compile(rb'^L:RegisterTerrainData\("[a-z0-9_]+",(\d+),D,(\d+)\)$', re.MULTILINE)
PAGE = re.compile(rb'^D\.packed\.grid\[(\d+)\]=', re.MULTILINE)
LOCK = Lock()


def xml_file(path, entries):
    content = [f'<Ui xmlns="{XMLNS}">', *(f'  <{tag} file={quoteattr(entry)}/>' for tag, entry in entries), '</Ui>']
    pending = path.with_suffix(".next")
    try:
        pending.write_bytes(("\n".join(content) + "\n").encode("utf-8"))
        pending.replace(path)
    finally:
        pending.unlink(missing_ok=True)


def coverage(pack, world, manifest=None):
    """Recover absolute tile coordinates from the pack's own Lua page keys."""
    manifest = manifest or read_json(pack / "PACK.json")
    if str(world) not in manifest["maps"]:
        return set()
    header = (pack / "Nav" / f"Nav{world}.lua").read_bytes()
    bounds = [re.search(rb'\["' + key + rb'"\]=(-?\d+)', header) for key in (b"cx0", b"cy0", b"ny")]
    if not all(bounds) or int(bounds[2][1]) <= 0:
        raise ValueError(f"Invalid pack grid for map {world}.")
    x, y, height = (int(value[1]) for value in bounds)
    positions = set()
    for path in manifest["files"]:
        if path.startswith(f"Nav/Nav{world}_"):
            for key in PAGE.finditer((pack / path).read_bytes()):
                row, col = divmod(int(key[1]) - 1, height)
                positions.add(f"{31 - y - col}_{31 - x - row}")
    if len(positions) != manifest["maps"][str(world)]["clusters"]:
        raise ValueError(f"Pack page count disagrees with geometry for map {world}.")
    return positions


@contextmanager
def publishing_lock(folder):
    with LOCK:
        folder.mkdir(parents=True, exist_ok=True)
        with (folder / "lock").open("ab+") as handle:
            if os.name == "nt":
                import msvcrt
                handle.seek(0)
                msvcrt.locking(handle.fileno(), msvcrt.LK_LOCK, 1)
            try:
                yield
            finally:
                if os.name == "nt":
                    handle.seek(0)
                    msvcrt.locking(handle.fileno(), msvcrt.LK_UNLCK, 1)


class Installation:
    def __init__(self, client, library=LIBRARY):
        self.product, self.build = client["product"], client["build"]
        if not PRODUCT.fullmatch(self.product) or not BUILD.fullmatch(self.build):
            raise ValueError("Invalid terrain client identity.")
        self.profile = "retail" if self.product in RETAIL else "forever" if self.product == "wowf" else self.product
        self.root = library / "Data" / self.profile / "Terrain"
        self.index = self.root / "Terrain.xml"
        self.prefix = (self.product, self.build)
        self.default_product = {"retail": "wow", "forever": "wowf"}.get(self.profile, self.product)
        self.work = self.root / ".install"

    def catalogue(self):
        if not self.index.is_file():
            return [], {}
        scripts, maps = [], {}
        try:
            document = ElementTree.parse(self.index).getroot()
        except ElementTree.ParseError as error:
            raise ValueError("Invalid generated terrain XML index.") from error
        for entry in document:
            tag = entry.tag.rsplit("}", 1)[-1]
            relative = entry.attrib["file"]
            if tag == "Script" and self.profile == "forever":
                scripts.append((tag, relative))
                continue
            parts = relative.split("/")
            product = parts[0] if len(parts) == 3 else self.default_product
            if (tag != "Include" or len(parts) not in (2, 3) or parts[-1] != "Terrain.xml"
                    or not re.fullmatch(r"0|[1-9][0-9]*", parts[-2])
                    or (len(parts) == 3 and (self.profile != "retail" or product not in RETAIL - {"wow"}))):
                raise ValueError("Invalid terrain index entry.")
            key = product, int(parts[-2])
            if key in maps:
                raise ValueError("Duplicate terrain index entry.")
            maps[key] = self.root.joinpath(*parts[:-1])
        return scripts, maps

    def paths(self, world):
        if type(world) is not int or world < 0:
            raise ValueError("Invalid terrain map ID.")
        parent = self.root if self.product == self.default_product else self.root / self.product
        return parent / str(world), self.work / f"{self.product}-{world}.previous"

    def installed_tiles(self, path):
        if path.is_dir():
            metadata = read_json(path / "Generation.json")
            if (metadata["product"], metadata["clientBuild"]) == self.prefix:
                return set(read_json(path / "Tiles.json"))
        return set()

    def protected_tiles(self, world, current_tiles):
        target, backup = self.paths(world)
        with publishing_lock(self.work):
            installed = self.installed_tiles(target if target.is_dir() else backup)
        if self.profile == "forever" and current_tiles is not None and (self.root / f"Nav/Nav{world}.lua").is_file():
            installed |= coverage(self.root, world) & current_tiles.keys()
        return installed

    def publish(self, source, world, required, check, checkpoint):
        manifest_bytes = (source / "PACK.json").read_bytes()
        manifest = json.loads(manifest_bytes)
        provenance = read_json(source / "Generation.json")
        source_hash = sha256(manifest_bytes).hexdigest()
        if (manifest["grid"]["product"], manifest["grid"]["build"]) != self.prefix or set(manifest["maps"]) != {str(world)}:
            raise ValueError("The pack does not match the selected client build and map.")
        if (provenance["product"], provenance["clientBuild"]) != self.prefix or provenance["maps"] != [world]:
            raise ValueError("The generation metadata does not match the selected client build and map.")
        if provenance["packManifestSha256"] != source_hash:
            raise ValueError("The generation metadata does not match the pack checksum.")
        tiles = coverage(source, world, manifest)
        key = self.product, world
        target, backup = self.paths(world)
        if not required <= tiles:
            raise ValueError("Some previously installed tiles could not be rebuilt. The existing graph is retained.")

        with publishing_lock(self.work):
            scripts, entries = self.catalogue()
            if backup.exists() and not target.exists():
                backup.rename(target)
            if not self.installed_tiles(target) <= tiles:
                raise ValueError("Another generation installed more tiles. Restart to include them.")
            for product in RETAIL - {self.product} if self.profile == "retail" else ():
                other = entries.get((product, world))
                if other and read_json(other / "Generation.json")["clientBuild"] == self.build:
                    raise ValueError("Another product already supplies this map for the same game build.")
            previous = read_json(target / "Generation.json") if target.is_dir() else {}
            if key in entries and previous.get("sourcePackManifestSha256") == source_hash:
                checkpoint()
                try:
                    check(target)
                except (OSError, ValueError):
                    pass
                else:
                    return target

            entries[key] = target
            includes = [("Include", (path / "Terrain.xml").relative_to(self.root).as_posix())
                        for _, path in sorted(entries.items())]
            provenance["sourcePackManifestSha256"] = source_hash
            with TemporaryDirectory(dir=self.work) as temporary:
                stage = Path(temporary) / "pack"
                self.copy_pack(source, manifest, provenance, world, tiles, stage, checkpoint)
                check(stage)
                checkpoint()
                if backup.exists():
                    shutil.rmtree(backup)
                target.parent.mkdir(parents=True, exist_ok=True)
                if target.exists():
                    target.rename(backup)
                try:
                    stage.rename(target)
                    xml_file(self.index, scripts + includes)
                except BaseException:
                    if target.exists():
                        target.rename(stage)
                    if backup.exists():
                        backup.rename(target)
                    raise
            if backup.exists():
                shutil.rmtree(backup, ignore_errors=True)
            return target

    def copy_pack(self, source, manifest, provenance, world, tiles, stage, checkpoint):
        (stage / "Nav").mkdir(parents=True)
        order = manifest["loadOrder"]
        guard = (
            'local terrain=LibStub("LibAPRNavigation-1.0")\n'
            f'if not terrain:MatchesGeneratedTerrain({json.dumps(self.profile)},{json.dumps(self.build)}) then return end\n'
        ).encode("ascii") if self.profile in {"retail", "forever"} else b""
        registrations = 0
        for relative in order:
            checkpoint()
            match = PACK_NAME.fullmatch(relative)
            if not match or int(match[1]) != world:
                raise ValueError(f"Unexpected Lua source for map {world}: {relative}")
            data = (source / relative).read_bytes()
            if sha256(data).hexdigest() != manifest["files"][relative]:
                raise ValueError(f"Pack changed during installation: {relative}")
            if guard:
                declaration = f'L:RegisterTerrainData("{self.profile}",{world},'.encode("ascii")
                data, count = REGISTER.subn(lambda match: declaration + b"D," + match[2] + b",true)", data)
                registrations += count
                data = guard + data
            (stage / relative).write_bytes(data)
            manifest["files"][relative] = sha256(data).hexdigest()
        if guard and registrations != 1:
            raise ValueError("Expected exactly one terrain registration for the map.")
        manifest["profile"] = self.profile
        xml_file(stage / "Terrain.xml", [("Script", relative) for relative in order])
        write_json(stage / "Tiles.json", sorted(tiles))
        write_json(stage / "PACK.json", manifest)
        provenance["packManifestSha256"] = sha256((stage / "PACK.json").read_bytes()).hexdigest()
        write_json(stage / "Generation.json", provenance)
