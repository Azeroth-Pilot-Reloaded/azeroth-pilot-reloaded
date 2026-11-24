"""Run and monitor the prepared local APR Retail terrain generator."""

import argparse
from collections import Counter
from concurrent.futures import FIRST_COMPLETED, ThreadPoolExecutor, wait
from contextlib import contextmanager
import ctypes
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
from time import monotonic, time, time_ns


ROOT = Path(__file__).resolve().parents[1]
if not __package__:
    sys.path.insert(0, str(ROOT))

from tools.terrain_ui.install import Installation
from tools.terrain_ui.job import PACK_CAPACITY, generate_fitting_pack, geometry_omissions
from tools.terrain_ui.native import prepare_binaries

GIB = 1024**3
STATUSES = {"complete": "complet", "partial": "partiel", "failed": "échec"}


def arguments():
    parser = argparse.ArgumentParser(description="Génère les graphes Retail avec une progression dans le terminal.")
    parser.add_argument("--wow", type=Path, default=Path(r"D:\Jeux\World of Warcraft"))
    parser.add_argument("--cache", type=Path, help="Dossier de génération préparé pour le build installé.")
    parser.add_argument("--generator", type=Path, default=ROOT.parent / "Route-generator")
    parser.add_argument("--defs", type=Path, default=ROOT.parent / "WoWDBDefs" / "definitions")
    parser.add_argument("--casc-dll", type=Path, help="Chemin vers CascLib.dll.")
    parser.add_argument("--workers", type=int, default=2, help="Nombre de mondes traités simultanément.")
    parser.add_argument("--threads", type=int, default=2, help="Nombre de threads du générateur par monde.")
    parser.add_argument("--worlds", nargs="+", type=int, metavar="ID", help="Limite la génération à ces mondes.")
    parser.add_argument("--dry-run", action="store_true", help="Vérifie les prérequis et affiche la couverture actuelle.")
    parser.add_argument("--cache-only", action="store_true", help="Conserve les packs dans le cache sans les installer.")
    args = parser.parse_args()
    if args.workers < 1 or args.threads < 1:
        parser.error("--workers et --threads doivent être positifs")
    return args


def installed_identity(wow):
    lines = (wow / ".build.info").read_text(encoding="utf-8-sig").splitlines()
    header = [column.split("!", 1)[0] for column in lines[0].split("|")]
    rows = [dict(zip(header, line.split("|"))) for line in lines[1:]]
    active = [row for row in rows if row.get("Product") == "wow" and row.get("Active") == "1"]
    if len(active) != 1:
        raise ValueError("Le fichier .build.info doit identifier un seul client Retail actif.")
    return active[0]["Version"], active[0]["Build Key"]


def load_json(path):
    try:
        return json.loads(path.read_bytes())
    except FileNotFoundError:
        return None


def prepare(args):
    args.wow, args.generator, args.defs = (path.resolve() for path in (args.wow, args.generator, args.defs))
    build, build_key = installed_identity(args.wow)
    root = (args.cache or ROOT / ".cache" / f"retail-terrain-{build.rsplit('.', 1)[-1]}").resolve()
    args.bin = root / "wide-layer-target" / "release"
    args.cells, args.retry, args.wide_heights, args.wide_layers = 128, True, True, True
    dll_pattern = "CascLib-*/bin/CascLib_dll/x64/Release/CascLib.dll"
    dll = args.casc_dll or next(iter(sorted((args.generator / ".cache/terrain-tools").glob(dll_pattern))), None)
    if not dll or not dll.is_file():
        raise ValueError("CascLib.dll est introuvable. Indique son chemin avec --casc-dll.")
    required = [root / name for name in ("generate_worlds.py", "subzone_report.py", "coverage-expected.json",
                "area-catalogue.json", "community-listfile.csv", "road-texture-listfile.csv", "file-index.sqlite")]
    if args.dry_run:
        required.append(args.bin / "apr-terrain.exe")
    required.extend((args.defs / "Map.dbd", args.generator / "tools/apr-terrain/road-textures.json"))
    missing = [str(path) for path in required if not path.is_file()]
    if missing:
        raise ValueError(f"Le cache de génération du build {build} doit être préparé. Fichiers manquants\n  " + "\n  ".join(missing))
    inventory = load_json(root / "coverage-expected.json")
    identity = inventory["identity"]
    if (identity["product"], identity["build"], identity["buildKey"].lower()) != ("wow", build, build_key.lower()):
        raise ValueError(f"Le cache appartient au build {identity['build']}. Le client Retail installé est {build}.")
    worlds = {world["id"]: world for world in inventory["worlds"].values() if world["status"] == "ready"}
    if args.worlds:
        unavailable = set(args.worlds) - worlds.keys()
        if unavailable:
            raise ValueError("Mondes sans terrain lisible dans cet inventaire\n  " + ", ".join(map(str, sorted(unavailable))))
        worlds = {world: worlds[world] for world in dict.fromkeys(args.worlds)}
    if not worlds:
        raise ValueError("L’inventaire Retail ne contient aucun monde lisible.")
    os.environ.update(APR_CASCLIB_DLL=str(dll.resolve()), APR_PYTHON=sys.executable,
                      APR_TERRAIN_FILE_INDEX=str(root / "file-index.sqlite"), PYTHONUTF8="1")
    return root, identity, worlds


@contextmanager
def generation_lock(root):
    import msvcrt

    with (root / "retail-generation.lock").open("a+b") as lock:
        lock.seek(0)
        try:
            msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
        except OSError as error:
            raise ValueError("Une génération Retail utilise déjà ce cache.") from error
        yield


def prepare_results(root, engine, worlds, executable, restore):
    results = {}
    result_dir = root / "results"
    if restore:
        result_dir.mkdir(exist_ok=True)
    for world in worlds:
        path = result_dir / f"{world}.json"
        result = load_json(path)
        pack = root / "packs" / str(world)
        relative_pack = str(pack.relative_to(root))
        manifest = pack / "PACK.json"
        checksum = engine.digest(manifest) if manifest.is_file() else None
        if result and result.get("pack") and (result["pack"] != relative_pack or not checksum
                                               or checksum != result.get("packSha256")):
            if restore:
                engine.write(root / "logs" / f"{world}-ancien-resultat.json", result)
                path.unlink()
            result = None
        # An interrupted retry may have overwritten the result while leaving its pack intact.
        if not result or not result.get("pack"):
            coverage = load_json(pack / "Coverage.json")
            if (coverage and checksum and coverage.get("id") == world
                    and coverage.get("pack") == relative_pack and checksum == coverage.get("packSha256")):
                check = subprocess.run([executable, "check", "--out", pack], capture_output=True)
                if check.returncode == 0:
                    if restore:
                        engine.write(path, coverage)
                    result = coverage
        if result:
            if result["status"] == "complete" and geometry_omissions(result.get("statistics", {})):
                result = result | {"status": "partial"}
                if restore:
                    engine.write(path, result)
            results[world] = result
    return results


def enable_recovery(args, root, engine):
    source = root / "layer-source/tools"
    if not (source / "apr-terrain/Cargo.toml").is_file():
        source = args.generator / "tools"
    args.bin, _ = prepare_binaries(print, toolchain=(source, Path(os.environ["APR_CASCLIB_DLL"])))
    original_run = engine.run

    def run(command, logfile):
        if command[1] != "generate":
            return original_run(command, logfile)

        def execute(attempt):
            start = logfile.stat().st_size if logfile.is_file() else 0
            try:
                original_run(attempt, logfile)
            except subprocess.CalledProcessError:
                with logfile.open("rb") as output:
                    output.seek(start)
                    message = output.read().decode("utf-8", errors="replace")
                error = next((line for line in message.splitlines() if PACK_CAPACITY.search(line)), None)
                if error is None:
                    raise
                raise ValueError(error) from None

        def on_retry(old, new):
            with logfile.open("a", encoding="utf-8") as output:
                output.write(f"Limite du graphe à {old} cellules · nouvel essai à {new} cellules sur toutes les tuiles\n")

        generate_fitting_pack(command, execute, on_retry)

    engine.run = run


def session_stage(root, world, started, status):
    if not status or status["stage"] == "extraction":
        written = 0
        for directory in (root / "work").glob(f"world-{world['id']}-*"):
            for extracted in directory.glob(f"tiles-*/{world['id']}"):
                try:
                    if extracted.stat().st_mtime_ns >= started:
                        written = max(written, sum(1 for _ in extracted.glob("*.json")))
                except FileNotFoundError:
                    pass
        expected = len(world.get("tiles", ())) or "?"
        return f"Extraction · {written}/{expected} tuiles écrites"
    rasterized = 0
    for scratch in (root / "packs").glob(".apr-*"):
        timestamp = scratch.name.rsplit("-", 1)[-1]
        if not timestamp.isdecimal() or int(timestamp) < started:
            continue
        grid = scratch / "grid"
        for tiles in (grid / ".apr-grid-staging/tiles", grid / "tiles"):
            rasterized = max(rasterized, sum(1 for _ in (tiles / str(world["id"])).glob("*.nav.gz")))
    readable = status["readableTiles"]
    phase = "Assemblage du graphe" if rasterized >= readable else "Rasterisation"
    return f"{phase} · {rasterized}/{readable} tuiles rasterisées"


def bar(done, total):
    width = 24
    filled = width if not total else width * done // total
    return f"[{'#' * filled}{'-' * (width - filled)}] {done}/{total}"


class Progress:
    def __init__(self, identity, target_count, session_count):
        self.interactive = sys.stdout.isatty()
        self.header = f"Graphes Retail {identity['build']}"
        self.started = monotonic()
        self.target_count = target_count
        self.session_count = session_count
        self.line_count = 0
        self.last_print = None
        self.last_done = None

    def show(self, results, done, active, last, stopping=False):
        elapsed = monotonic() - self.started
        if not self.interactive and self.last_done == done and elapsed - self.last_print < 30 and not stopping:
            return
        counts = Counter(result["status"] for result in results.values())
        seconds = int(elapsed)
        clock = f"{seconds // 3600:02}:{seconds // 60 % 60:02}:{seconds % 60:02}"
        lines = [
            f"{self.header} · {clock}",
            f"Couverture  {bar(counts['complete'], self.target_count)} mondes complets",
            f"Session     {bar(done, self.session_count)} mondes traités" if self.session_count
            else "Session     Aucun monde à reprendre",
            f"Partiels {counts['partial']} · Échecs {counts['failed']} · "
            f"{sum(row.get('packedTiles', 0) for row in results.values()):,} tuiles empaquetées".replace(",", " "),
        ]
        lines.extend(active)
        if last:
            lines.append(f"Dernier résultat  {last}")
        if stopping:
            lines.append("Arrêt demandé · fermeture des tâches en cours")
        if self.interactive:
            if self.line_count:
                sys.stdout.write(f"\x1b[{self.line_count}F\x1b[J")
            width = shutil.get_terminal_size().columns
            lines = [line[:max(1, width - 1)] for line in lines]
            self.line_count = len(lines)
        print("\n".join(lines), flush=True)
        self.last_print, self.last_done = elapsed, done


def generate(args, root, identity, worlds, engine, results):
    todo = [world for world in worlds.values() if results.get(world["id"], {}).get("status") != "complete"]
    if not args.worlds:
        # Start the largest world early while smaller worlds fill the other slots.
        todo.sort(key=lambda world: len(world.get("tiles", ())))
        if todo:
            todo.insert(0, todo.pop())
    progress = Progress(identity, len(worlds), len(todo))
    done, last, stopping = 0, None, False
    stages = {}
    original_write = engine.write

    def publish(path, document):
        original_write(path, document)
        if path.parent == root / "active":
            stages[document["id"]] = document

    def request_stop(_signum, _frame):
        nonlocal stopping
        stopping = True

    previous_signal = signal.signal(signal.SIGINT, request_stop)
    engine.write = publish
    try:
        source_hash = engine.digest(root / "community-listfile.csv") if todo else None
        allowlist = args.generator / "tools/apr-terrain/road-textures.json"
        roads = root / "road-texture-listfile.csv"
        queue = iter(todo)
        active = {}
        with ThreadPoolExecutor(max_workers=args.workers) as pool:
            while True:
                while not stopping and len(active) < args.workers and (world := next(queue, None)) is not None:
                    started = time_ns()
                    future = pool.submit(engine.build_world, world, args, root, identity, source_hash, allowlist, roads)
                    active[future] = (world, started)
                active_lines = []
                for world, started in active.values():
                    stage = session_stage(root, world, started, stages.get(world["id"]))
                    active_lines.append(f"  [{world['id']}] {stage} · {world['name']}")
                progress.show(results, done, active_lines, last, stopping)
                if not active:
                    break
                finished, _ = wait(active, timeout=2, return_when=FIRST_COMPLETED)
                for future in finished:
                    world, _ = active.pop(future)
                    result = future.result()
                    if result["status"] == "complete" and geometry_omissions(result.get("statistics", {})):
                        result = result | {"status": "partial"}
                        engine.write(root / "results" / f"{world['id']}.json", result)
                    results[world["id"]] = result
                    done += 1
                    last = f"{world['name']} ({world['id']}) · {STATUSES[result['status']]}"
    finally:
        engine.write = original_write
        signal.signal(signal.SIGINT, previous_signal)
    return 130 if stopping else (0 if all(results.get(world, {}).get("status") == "complete" for world in worlds) else 2)


def install_packs(root, identity, executable, results, installation):
    def check(pack):
        verified = subprocess.run([executable, "check", "--out", pack], capture_output=True)
        if verified.returncode:
            raise ValueError((verified.stderr or verified.stdout).decode("utf-8", errors="replace").strip())

    installed, failures = 0, 0
    for world, result in sorted(results.items()):
        if result["status"] not in {"complete", "partial"} or not result.get("pack"):
            continue
        pack = root / "packs" / str(world)
        try:
            if result.get("build") != identity["build"]:
                raise ValueError("Le résultat provient d’un autre build.")
            if geometry_omissions(result.get("statistics", {})):
                raise ValueError("Le pack contient des altitudes ou des transitions non encodées.")
            installation.publish(pack, world, set(), check, lambda: None)
            installed += 1
        except (OSError, ValueError, KeyError) as error:
            failures += 1
            print(f"Installation de la carte {world} · {error}", file=sys.stderr, flush=True)
    print(f"Installation · {installed} packs vérifiés, {failures} échecs · {installation.root}", flush=True)
    return failures


def main():
    for stream in (sys.stdout, sys.stderr):
        if isinstance(stream, io.TextIOWrapper):
            stream.reconfigure(encoding="utf-8", errors="replace")
    args = arguments()
    try:
        root, identity, worlds = prepare(args)
        spec = importlib.util.spec_from_file_location("apr_retail_engine", root / "generate_worlds.py")
        engine = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(engine)
        executable = args.bin / "apr-terrain.exe"
        if args.dry_run:
            results = prepare_results(root, engine, worlds, executable, restore=False)
            pending = len(worlds) - sum(result["status"] == "complete" for result in results.values())
            Progress(identity, len(worlds), pending).show(results, 0, [], None)
            print(f"Cache prêt · {root}")
            return 0
        if os.name != "nt":
            raise ValueError("Ce générateur de terrain local utilise CascLib et les exécutables Windows.")
        with generation_lock(root):
            enable_recovery(args, root, engine)
            executable = args.bin / "apr-terrain.exe"
            for name in ("work", "logs", "active", "packs"):
                (root / name).mkdir(exist_ok=True)
            # Windows rebooted between some resumptions. These markers cannot belong to a live worker.
            uptime = ctypes.windll.kernel32.GetTickCount64
            uptime.restype = ctypes.c_uint64
            boot_time = time() - uptime() / 1000
            for marker in (root / "active").glob("*.json"):
                if marker.resolve().parent == root / "active" and marker.stat().st_mtime < boot_time:
                    marker.unlink(missing_ok=True)
            results = prepare_results(root, engine, worlds, executable, restore=True)
            if (any(results.get(world, {}).get("status") != "complete" for world in worlds)
                    and shutil.disk_usage(root).free < 35 * GIB):
                raise ValueError("Le générateur a besoin d’au moins 35 Gio libres pour ses fichiers temporaires.")
            status = generate(args, root, identity, worlds, engine, results)
            print("\nActualisation du rapport des zones et sous-zones…", flush=True)
            report = subprocess.run([sys.executable, "-B", root / "subzone_report.py", "--all-worlds"], capture_output=True)
            if report.returncode:
                print(report.stderr.decode("utf-8", errors="replace"), file=sys.stderr)
                return report.returncode
            print(f"Rapport  {root / 'coverage-retail-full.json'}\nPacks    {root / 'packs'}\nJournaux {root / 'logs'}")
            if status != 130 and not args.cache_only:
                print("Installation des graphes dans la bibliothèque…", flush=True)
                if install_packs(root, identity, executable, results, Installation(identity)):
                    return 2
            return status
    except (OSError, ValueError, KeyError, IndexError) as error:
        print(f"Génération Retail · {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
