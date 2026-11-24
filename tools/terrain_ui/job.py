"""Run one resumable generation selection with per-tile progress and pause checkpoints."""

from collections import Counter, deque
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import sys
from threading import RLock, Thread
from time import monotonic, sleep
from uuid import uuid4

from .catalog import LOCALES, area_path, client_reader, open_client, read_area_tiles, select, tiles_in_bounds
from .install import Installation, coverage
from .native import DEFINITIONS, GENERATOR, RETAIL, WORKSPACE, prepare_binaries, read_json, write_json


CPU_COUNT = os.cpu_count() or 1
DEFAULTS = {"cells": 128, "threads": min(2, CPU_COUNT), "minRegion": 1, "stretch": 2, "roadThreshold": 128,
            "roadWeak": 32, "wideHeights": True, "wideLayers": True, "keepPartial": True}
LIMITS = {"cells": (64, 128, 256), "threads": range(1, CPU_COUNT + 1),
          "minRegion": range(1, 100001), "stretch": range(6), "roadThreshold": range(1, 256),
          "roadWeak": range(1, 256)}
TEMPORARY_READ = re.compile(r"\[(?:Errno|WinError) (?:32|33|995|1237)\]|temporarily unavailable", re.IGNORECASE)
MODEL_CAUSE = re.compile(r"(?:model FileDataID \d+|unsupported M2 layout|unsupported model format).*$")
PACK_CAPACITY = re.compile(r"(?:graph fields: .*local portal index \d+ exceeds 4094|"
                           r"(?:surface|graph) fields: .*wire integer \d+ exceeds \d+ digits|"
                           r"nav(?: v\d+)? tile \(\d+, \d+\) column .*; link capacity \d+)")


def options(values):
    if not isinstance(values, dict) or not values.keys() <= DEFAULTS.keys():
        raise ValueError("Invalid terrain settings.")
    settings = DEFAULTS | values
    for key, default in DEFAULTS.items():
        value = settings[key]
        if type(value) is not type(default) or (key in LIMITS and value not in LIMITS[key]):
            raise ValueError(f"Invalid value for {key}.")
    if settings["roadWeak"] > settings["roadThreshold"]:
        raise ValueError("The weak road threshold must be lower than or equal to the main threshold.")
    return settings


def generate_fitting_pack(command, execute, on_retry):
    cell_argument = command.index("--cells") + 1
    requested = int(command[cell_argument])
    if requested not in LIMITS["cells"]:
        raise ValueError(f"Unsupported tile resolution {requested}")
    resolutions = [value for value in reversed(LIMITS["cells"]) if value <= requested]
    for index, cells in enumerate(resolutions):
        attempt = list(command)
        attempt[cell_argument] = str(cells)
        try:
            execute(attempt)
            return cells
        except ValueError as error:
            if index + 1 == len(resolutions) or not PACK_CAPACITY.search(str(error)):
                raise
            on_retry(cells, resolutions[index + 1])


def geometry_omissions(stats):
    return {key: stats[key] for key in ("unrepresentableFloors", "unrepresentableDirectedEdges") if stats.get(key)}


def geometry_issue(path):
    with path.open("rb") as stream:
        stream.seek(-min(path.stat().st_size, 65536), os.SEEK_END)
        trailer = stream.read()
    marker = b'],"complete":'
    index = trailer.rfind(marker)
    data = json.loads(b'{"complete":' + trailer[index + len(marker):]) if index >= 0 else read_json(path)
    return data["errors"] or ([] if data["complete"] else ["Incomplete terrain tile"])


def bytes_in(path):
    total = 0
    for directory, _, names in os.walk(path):
        for name in names:
            try:
                total += (Path(directory) / name).stat().st_size
            except FileNotFoundError:
                pass
    return total


def last_tile(paths):
    count, name, latest = 0, None, 0
    for path in paths:
        try:
            modified = path.stat().st_mtime_ns
        except FileNotFoundError:
            continue
        count += 1
        if modified >= latest:
            latest, name = modified, path.name.split(".")[0]
    return count, name


class Generation:
    def __init__(self, client, data, scope, settings, only_worlds=None):
        ids, trail, roots, zone = select(data, scope)
        self.client, self.data, self.scope, self.settings = client, data, scope, settings
        self.installation = Installation(client)
        self.protected = {}
        self.ids = ids if only_worlds is None else [world for world in ids if world in only_worlds]
        self.trail, self.roots, self.zone = trail, roots, zone
        identity = json.dumps([scope, settings], sort_keys=True).encode()
        self.folder = WORKSPACE / "clients" / client["id"] / "jobs" / hashlib.sha256(identity).hexdigest()[:16]
        self.runtime = uuid4().hex
        self.marker = self.folder / f"{self.runtime}.pause"
        self.acknowledgement = self.marker.with_suffix(".ack")
        self.lock = RLock()
        self.started = monotonic()
        self.paused_since = None
        self.paused_for = 0
        self.state, self.phase = "running", "planning"
        self.world, self.unit, self.tile_areas = None, None, {}
        self.geometry, self.active_tile = None, None
        self.regions = {}
        for continent in data["tree"]:
            if scope.get("continent") and scope["continent"] != continent["id"]:
                continue
            for zone in continent["zones"]:
                for world in zone["worlds"]:
                    self.regions.setdefault(world, []).append((continent, zone))
        self.tasks, self.results = [], []
        self.lines = deque(maxlen=350)
        self.process = None
        self.stopping = False
        self.expected = 0
        self.error = None
        self.tile_errors = {}
        self.finished = None
        self.disk = (0, 0, 0)
        self.folder.mkdir(parents=True, exist_ok=True)

    def start(self):
        Thread(target=self.run, daemon=True, name="terrain-generation").start()

    def log(self, message):
        self.write_log(str(message).rstrip())
        with self.lock:
            self.lines.append(str(message).rstrip()[:900])

    def write_log(self, message):
        with (self.folder / "generation.log").open("a", encoding="utf-8") as stream:
            stream.write(message + "\n")

    def retry_worlds(self):
        if self.finished is None or self.state not in {"partial", "failed"}:
            return set()
        if self.phase == "finished":
            return {item["world"] for item in self.results if item["status"] != "complete"}
        return set(self.ids) - {item["world"] for item in self.results if item["status"] == "complete"}

    def pause(self):
        with self.lock:
            if self.state != "running":
                raise ValueError("There is no running generation to pause.")
            self.acknowledgement.unlink(missing_ok=True)
            self.marker.touch()
            self.state = "pausing"

    def resume(self):
        with self.lock:
            if self.state not in {"pausing", "paused"}:
                raise ValueError("There is no paused generation to resume.")
            self.marker.unlink(missing_ok=True)
            if self.paused_since is not None:
                self.paused_for += monotonic() - self.paused_since
            self.paused_since = None
            self.state = "running"

    def stop(self):
        with self.lock:
            self.stopping = True
            self.marker.unlink(missing_ok=True)
            if self.process and self.process.poll() is None:
                self.process.terminate()

    def checkpoint(self):
        while not self.stopping and self.marker.is_file():
            self.acknowledgement.touch()
            sleep(0.15)
        if self.stopping:
            raise InterruptedError("Generation closed")

    def command(self, args, env):
        self.checkpoint()
        with self.lock:
            if self.stopping:
                raise InterruptedError("Generation closed")
            process = self.process = subprocess.Popen([str(arg) for arg in args], env=env,
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace",
                creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
        with process.stdout:
            last = ""
            for line in process.stdout:
                last = line.strip()
                if last.startswith("APR_TILE "):
                    with self.lock:
                        self.active_tile = last.removeprefix("APR_TILE ")
                elif last.startswith("APR_AREAS "):
                    _, tile, areas = last.split(maxsplit=2)
                    with self.lock:
                        self.tile_areas.setdefault(tile, json.loads(areas))
                        self.active_tile = tile
                elif last.startswith('{"') and len(last) > 800:
                    self.log("Pack manifest written.")
                elif last:
                    self.log(last)
        status = process.wait()
        with self.lock:
            self.process = None
        if status:
            raise ValueError(last or f"{Path(args[0]).name} exited with status {status}")

    def plan(self):
        reader = store = None
        area_ids = {int(key) for key in self.data["areas"] if self.roots and any(
            area["id"] in self.roots for area in area_path(self.data["areas"], key))}
        try:
            for world_id in self.ids:
                self.checkpoint()
                world = self.data["worlds"][str(world_id)]
                selected = None
                observed = {}
                shared_continent = self.scope.get("continent", "").startswith("ui:") if self.scope.get("continent") else False
                if shared_continent and not self.zone:
                    shared_continent = any(group["id"].startswith("ui:") and group["id"] != self.scope["continent"]
                        and any(world_id in zone["worlds"] for zone in group["zones"]) for group in self.data["tree"])
                if world["tiles"] is not None and (self.zone is not None or shared_continent):
                    zones = [self.zone] if self.zone else [zone["id"] for _, zone in self.regions.get(world_id, [])]
                    candidates = [row for zone in zones for row in self.data["assignments"].get(zone, [])]
                    ranges = [box for key, _, box in candidates if key == world_id and box]
                    selected = set()
                    scan_ids = area_ids
                    if not self.zone:
                        roots = {root for _, zone in self.regions.get(world_id, []) for root in zone["roots"]}
                        scan_ids = {int(key) for key in self.data["areas"] if any(
                            area["id"] in roots for area in area_path(self.data["areas"], key))}
                    if scan_ids:
                        if not store:
                            reader, dll = client_reader()
                            for mask in LOCALES.values():
                                try:
                                    store = open_client(self.client, reader, dll, mask)
                                    break
                                except OSError:
                                    continue
                            if not store:
                                raise ValueError("The selected client's terrain archive could not be opened.")
                        result = read_area_tiles(store, world, self.checkpoint, self.folder.parents[1])
                        observed = result["tiles"]
                        selected.update(tile for tile, areas in observed.items() if scan_ids.intersection(areas))
                    if self.scope.get("area") is None and ranges:
                        selected.update(tiles_in_bounds(world["tiles"], ranges))
                    if not selected:
                        self.log(f"World {world_id}: no client tiles match the selected area.")
                        continue
                    selected = sorted(selected)
                elif world["tiles"] is None and self.scope.get("area") is not None:
                    self.log(f"World {world_id}: the installed data has no tile-level subdivision for this world model.")
                    continue
                else:
                    area_pathname = self.folder.parents[1] / "area-tiles" / f"{world_id}.json"
                    if self.client["product"] == "wow" and self.client["build"] == "12.1.5.70961" and not area_pathname.is_file():
                        area_pathname = RETAIL / "area-tiles" / f"{world_id}.json"
                    if area_pathname.is_file():
                        observed = read_json(area_pathname)["tiles"]
                protected = self.installation.protected_tiles(world_id, world["tiles"])
                self.protected[world_id] = protected
                if selected and protected:
                    selected = sorted(set(selected) | protected)
                    self.log(f"Map {world_id} · preserving {len(protected)} installed tiles")
                expected = len(selected or world["tiles"] or ())
                self.tasks.append((world, selected, observed, expected))
        finally:
            if store:
                store.close()
        if not self.tasks:
            raise ValueError("No terrain tiles match this selection in the installed client.")

    def run(self):
        try:
            self.log(f"Generation {self.runtime} · {self.client['product']} · {self.client['build']} · {len(self.ids)} maps")
            self.plan()
            self.phase = "preparing"
            binaries, dll = prepare_binaries(self.log, self.command)
            env = os.environ | {"APR_CASCLIB_DLL": str(dll), "APR_PYTHON": sys.executable, "PYTHONUTF8": "1",
                                "APR_TERRAIN_PAUSE_FILE": str(self.marker),
                                "APR_TERRAIN_FILE_INDEX": str(RETAIL / "file-index.sqlite")}
            if not (RETAIL / "file-index.sqlite").is_file():
                env.pop("APR_TERRAIN_FILE_INDEX")
            for world, selected, observed, expected in self.tasks:
                self.checkpoint()
                with self.lock:
                    self.world, self.tile_areas, self.expected = world, observed, expected
                    self.geometry, self.active_tile = None, None
                    self.tile_errors = {}
                    self.phase = "extraction"
                    self.unit = self.folder / "worlds" / str(world["id"])
                result = {}
                try:
                    result = self.build_world(binaries, env, selected)
                    self.phase = "installation"
                    self.log(f"Installing map {world['id']} in LibAPRNavigation")
                    pack = self.unit / "pack"
                    installed = self.installation.publish(pack, world["id"], self.protected[world["id"]],
                        lambda path: self.command([binaries / "apr-terrain.exe", "check", "--out", path], env),
                        self.checkpoint)
                    result = result | {"installed": str(installed)}
                except (OSError, ValueError, KeyError) as error:
                    self.log(f"Map {world['id']} · {self.phase} · {error}")
                    result = {"world": world["id"], "expected": expected, "tiles": 0} | result | {
                        "status": "failed", "errorPhase": self.phase, "error": str(error), "errors": self.tile_errors}
                with self.lock:
                    self.results.append(result)
                self.log(f"World {world['id']} · {result['status']} · {result['tiles']}/{result['expected']}")
            with self.lock:
                states = {result["status"] for result in self.results}
                self.state = "complete" if states == {"complete"} else "failed" if states == {"failed"} else "partial"
                if self.state == "failed":
                    self.error = self.results[-1]["error"]
                self.phase = "finished"
                self.disk = (0, 0, 0)
        except (OSError, ValueError, KeyError, struct.error) as error:
            with self.lock:
                self.error = str(error)
                self.state = "failed"
                self.disk = (0, 0, 0)
            self.log(error)
        finally:
            self.marker.unlink(missing_ok=True)
            self.acknowledgement.unlink(missing_ok=True)
            try:
                write_json(self.folder / "report.json", {"client": self.client["product"], "build": self.client["build"],
                    "scope": self.scope, "settings": self.settings, "state": self.state, "phase": self.phase,
                    "error": self.error, "destination": str(self.installation.root), "results": self.results})
            finally:
                with self.lock:
                    self.finished = monotonic()

    def inspect_extraction(self, directory, requested):
        index = read_json(directory / "index.json")
        if (index["product"], index["build"]) != (self.client["product"], self.client["build"]):
            raise ValueError("Extracted geometry does not match the selected client build.")
        if read_json(directory / index["metadata"])["buildKey"] != self.client["buildKey"]:
            raise ValueError("The client files changed during extraction.")
        if len(index["maps"]) != 1 or index["maps"][0]["id"] != self.world["id"]:
            raise ValueError("Extracted geometry does not match the requested map.")
        accepted, errors, seen = {}, {}, set()
        for tile in index["maps"][0]["tiles"]:
            self.checkpoint()
            key = f"{tile['x']}_{tile['y']}"
            if key in seen or (requested and key not in requested):
                raise ValueError(f"Unexpected geometry tile {key}.")
            seen.add(key)
            try:
                issue = geometry_issue(directory / tile["file"])
            except (OSError, ValueError) as error:
                issue = [str(error)]
            if issue:
                errors[key] = issue
            else:
                accepted[key] = tile
        errors.update({key: ["No geometry emitted for the requested tile"] for key in sorted(requested - seen)})
        return index, accepted, errors

    def report_tile_errors(self, errors, attempt):
        if not errors:
            return
        world = self.world["id"]
        causes = Counter()
        details = []
        for tile, issues in errors.items():
            grouped = {match[0] if (match := MODEL_CAUSE.search(issue)) else issue for issue in issues}
            causes.update(grouped)
            details.extend(f"Map {world} · {attempt} · Tile {tile} · {issue}" for issue in issues)
        self.write_log("\n".join(details))
        for cause, count in causes.most_common(3):
            self.log(f"Map {world} · {attempt} · {count}/{len(errors)} affected tiles · {cause}")

    def recover_extraction(self, reader, env, geometry, accepted, errors):
        # Global WMO maps can expose empty placeholder pages in a filtered retry.
        if self.world["tiles"] is None:
            return
        retry = {tile for tile, issues in errors.items() if all(TEMPORARY_READ.search(issue) for issue in issues)}
        if not retry:
            return
        self.phase = "recovery"
        self.log(f"Map {self.world['id']} · retrying {len(retry)} tiles after temporary read errors")
        directory = geometry / "retry"
        directory.mkdir()
        try:
            self.command([*reader, "--out", directory, "--tile", ",".join(sorted(retry))], env)
            _, recovered, remaining = self.inspect_extraction(directory, retry)
        except (OSError, ValueError, KeyError) as error:
            if self.stopping:
                raise
            self.log(f"Targeted retry failed · {error}")
            return
        for key, tile in recovered.items():
            accepted[key] = tile | {"file": f"retry/{tile['file']}"}
            del errors[key]
        errors.update(remaining)
        self.report_tile_errors(remaining, "retry")
        self.log(f"Map {self.world['id']} · {len(recovered)}/{len(retry)} tiles recovered")

    def generate_pack(self, command, env):
        return generate_fitting_pack([*command, "--cells", str(self.settings["cells"])],
            lambda attempt: self.command(attempt, env),
            lambda old, new: self.log(f"Map {self.world['id']} · {old} cells exceed pack capacity · "
                                     f"retrying all tiles with {new} cells"))

    def build_world(self, binaries, env, selected):
        world_id = self.world["id"]
        pack = self.unit / "pack"
        record = self.unit / "result.json"
        executable = binaries / "apr-terrain.exe"
        if record.is_file() and (pack / "PACK.json").is_file():
            result = read_json(record)
            if result["status"] == "complete":
                self.phase = "verification"
                try:
                    self.command([executable, "check", "--out", pack], env)
                    manifest = read_json(pack / "PACK.json")
                    needed = set(selected or self.world["tiles"] or ())
                    if needed <= coverage(pack, world_id, manifest) and not geometry_omissions(manifest["maps"][str(world_id)]):
                        return result | {"cells": manifest["cells"]}
                except ValueError:
                    self.log(f"Pack verification failed for map {world_id}; rebuilding.")
        self.unit.mkdir(parents=True, exist_ok=True)
        geometry = self.unit / f"geometry-{self.runtime}"
        geometry.mkdir(exist_ok=True)
        common = ["--product", self.client["product"], "--continents", str(world_id)]
        reader = [binaries / "apr-terrain-reader.exe", "--wow", self.client["root"], "--defs", DEFINITIONS, *common]
        command = [*reader, "--out", geometry, *(("--tile", ",".join(selected)) if selected else ())]
        with self.lock:
            self.phase, self.geometry = "extraction", geometry
        try:
            self.log(f"Geometry extraction · map {world_id} · {self.expected or 'WMO'}")
            self.command(command, env)
            requested = set(selected or self.world["tiles"] or ())
            index, accepted, errors = self.inspect_extraction(geometry, requested)
            self.tile_errors = errors
            self.report_tile_errors(errors, "extraction")
            self.recover_extraction(reader, env, geometry, accepted, errors)
            expected = self.expected or len(accepted) + len(errors)
            ok = list(accepted.values())
            if not ok or (errors and not self.settings["keepPartial"]):
                raise ValueError(f"Only {len(ok)}/{expected} tiles could be read.")
            if errors or ok != index["maps"][0]["tiles"]:
                if errors:
                    index["selection"] = "tiles"
                index["maps"][0]["tiles"] = sorted(ok, key=lambda tile: (tile["y"], tile["x"]))
                write_json(geometry / "index.json", index)
            roads = RETAIL / "road-texture-listfile.csv"
            allowlist = GENERATOR / "tools/apr-terrain/road-textures.json"
            if not allowlist.is_file():
                allowlist = RETAIL / "layer-source/tools/apr-terrain/road-textures.json"
            command = [executable, "generate", "--geometry", geometry, *common, "--build", self.client["build"],
                       "--out", pack, "--listfile", roads, "--allowlist", allowlist]
            for flag, key in (("threads", "threads"), ("min-region", "minRegion"),
                              ("graph-stretch-percent", "stretch"), ("road-threshold", "roadThreshold"),
                              ("road-weak-threshold", "roadWeak")):
                command.extend((f"--{flag}", str(self.settings[key])))
            for flag, key in (("wide-heights", "wideHeights"), ("wide-layers", "wideLayers")):
                if self.settings[key]:
                    command.append(f"--{flag}")
            self.phase, self.expected = "raster", len(ok)
            self.log(f"Graph generation · map {world_id} · {len(ok)}")
            cells = self.generate_pack(command, env)
            self.phase = "verification"
            self.command([executable, "check", "--out", pack], env)
            manifest = read_json(pack / "PACK.json")
            stats = manifest["maps"][str(world_id)]
            tiles = stats["clusters"]
            if tiles != len(ok):
                raise ValueError("The output tile count differs from the extracted geometry.")
            omitted = geometry_omissions(stats)
            if omitted:
                message = (f"Map {world_id} pack omits {omitted.get('unrepresentableFloors', 0)} floors and "
                           f"{omitted.get('unrepresentableDirectedEdges', 0)} directed transitions")
                self.log(message)
                if not self.settings["keepPartial"]:
                    raise ValueError(message)
            result = {"world": world_id, "status": "complete" if tiles == expected and not omitted else "partial",
                      "expected": expected, "tiles": tiles, "cells": cells, "errors": errors}
            result.update(omitted)
            write_json(record, result)
            return result
        finally:
            if geometry.resolve().parent == self.unit.resolve():
                shutil.rmtree(geometry)

    def snapshot(self, logs):
        with self.lock:
            return self._snapshot(logs)

    def active_trail(self, tile):
        if self.scope.get("area") is not None:
            return self.trail
        paths = [area_path(self.data["areas"], str(key)) for key in self.tile_areas.get(tile, ())]
        matches = []
        for continent, zone in self.regions.get(self.world["id"], ()):
            if self.zone is not None and self.zone != zone["id"]:
                continue
            for path in paths:
                for index, area in enumerate(path):
                    if area["id"] in zone["roots"]:
                        matches.append((index, len(path), continent["name"], zone["name"],
                                        [item["name"] for item in path[index + 1:] if item["name"]]))
        if matches:
            _, _, continent, zone, areas = max(matches, key=lambda entry: entry[:2])
            return [continent, zone, *areas]
        return self.trail or [self.world["name"]]

    def _snapshot(self, logs):
        now = self.finished or monotonic()
        if self.state == "pausing" and self.acknowledgement.is_file():
            self.paused_since = now
            self.state = "paused"
        elapsed = (self.paused_since or now) - self.started - self.paused_for
        timestamp, work_bytes, pack_bytes = self.disk
        if monotonic() - timestamp > 2.5:
            packs = self.folder.glob("worlds/*/pack")
            pack_bytes = sum(bytes_in(pack) for pack in packs)
            work_bytes = max(0, bytes_in(self.folder) - pack_bytes)
            if self.state in {"complete", "partial", "failed"}:
                pack_bytes = sum(bytes_in(Path(result["installed"])) for result in self.results if "installed" in result)
            self.disk = monotonic(), work_bytes, pack_bytes
        current = None
        fraction = 0
        phase = self.phase
        if self.world and self.unit and self.state in {"running", "pausing", "paused"}:
            world_id = str(self.world["id"])
            if phase == "extraction":
                count, tile = last_tile(self.geometry.glob(f"tiles-*/{world_id}/*.json")) if self.geometry else (0, None)
                tile = self.active_tile or tile
                fraction = 0.32 * min(1, count / (self.expected or max(count + 1, 1)))
            elif phase == "recovery":
                count, tile, fraction = self.expected - len(self.tile_errors), self.active_tile, 0.32
            elif phase == "raster":
                count, tile = last_tile(self.unit.glob(f".apr-*/grid/.apr-grid-staging/tiles/{world_id}/*.nav.gz"))
                if not count:
                    count, tile = last_tile(self.unit.glob(f".apr-*/grid/tiles/{world_id}/*.nav.gz"))
                fraction = 0.32 + 0.60 * min(1, count / max(self.expected, 1))
                if count >= self.expected:
                    phase = "packing"
            else:
                count, tile, fraction = self.expected, self.active_tile, 0.97
            tile = tile or self.active_tile
            trail = self.active_trail(tile)
            current = {"world": self.world["id"], "trail": trail, "tile": tile, "files": count, "expected": self.expected}
        estimate = sum(max(4, item[3]) for item in self.tasks)
        finished = sum(max(4, item[3]) for item in self.tasks[:len(self.results)])
        active_weight = max(4, self.tasks[len(self.results)][3]) if len(self.results) < len(self.tasks) else 0
        progress = min(1, (finished + fraction * active_weight) / estimate) if estimate else 0
        eta = round(elapsed * (1 - progress) / progress) if 0.005 < progress < 1 and elapsed >= 3 else None
        return {"state": self.state, "phase": phase, "scope": self.trail, "current": current, "elapsed": round(elapsed),
                "client": self.client["id"], "retryMaps": len(self.retry_worlds()),
                "logReady": (self.folder / "generation.log").is_file(),
                "reportReady": self.finished is not None and (self.folder / "report.json").is_file(),
                "eta": eta, "progress": progress, "total": len(self.tasks), "done": len(self.results),
                "failed": sum(item["status"] == "failed" for item in self.results),
                "partial": sum(item["status"] == "partial" for item in self.results),
                "excludedTiles": sum(len(item.get("errors", {})) for item in self.results),
                "tiles": sum(item["tiles"] for item in self.results), "workBytes": work_bytes, "packBytes": pack_bytes,
                "freeBytes": shutil.disk_usage(WORKSPACE).free, "output": str(self.installation.root), "error": self.error,
                "logs": list(self.lines) if logs else None}
