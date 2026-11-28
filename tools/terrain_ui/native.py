"""Locate the existing terrain toolchain and build a reader for installed Battle.net products."""

import hashlib
import importlib.util
import inspect
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from threading import Lock
from urllib.request import urlopen


ROOT = Path(__file__).resolve().parents[2]
WORKSPACE = ROOT / ".cache" / "terrain-ui"
REPORTS = ROOT / "tools" / "terrain_ui" / "reports"
RETAIL = ROOT / ".cache" / "retail-terrain-70961"
GENERATOR = ROOT.parent / "Route-generator"
DEFINITIONS = WORKSPACE / "definitions"
DBD_REVISION = "3a7954cfb8ee4f1132c83cd1859753294ee8964b"
DBD_TABLES = ("Map", "AreaTable", "UiMap", "UiMapAssignment", "WMOAreaTable", "LiquidType", "LiquidMaterial")
PRODUCT = re.compile(r"wow[a-z0-9_]*\Z")
BUILD = re.compile(r"\d+(?:\.\d+){2,}\Z")
BUILD_LOCK = Lock()
PAUSE = '''
fn wait_if_paused() {
    if let Some(marker) = std::env::var_os("APR_TERRAIN_PAUSE_FILE") {
        let marker = std::path::Path::new(&marker);
        while marker.is_file() {
            let _ = std::fs::write(marker.with_extension("ack"), b"");
            std::thread::sleep(std::time::Duration::from_millis(150));
        }
    }
}
'''

def installed_identity(root, product):
    lines = (root / ".build.info").read_text(encoding="utf-8-sig").splitlines()
    header = [column.split("!", 1)[0] for column in lines[0].split("|")]
    rows = (dict(zip(header, line.split("|"))) for line in lines[1:])
    active = [row for row in rows if row.get("Product") == product and row.get("Active") == "1"]
    if len(active) != 1:
        raise ValueError(f"No unique installed build for {product}")
    row = active[0]
    return {"product": product, "build": row["Version"], "buildKey": row["Build Key"]}


def wdt_id(store, row):
    import ctypes as c

    if row.get("WdtFileDataID"):
        return row["WdtFileDataID"]
    directory = row.get("Directory")
    if not directory or not re.fullmatch(r"[A-Za-z0-9 _-]+", directory):
        return 0

    class FileInfo(c.Structure):
        _fields_ = [("keysAndName", c.c_char * 48), ("wide", c.c_uint64 * 6),
                    ("segment", c.c_uint32), ("spans", c.c_uint32), ("id", c.c_uint32),
                    ("locale", c.c_uint32), ("content", c.c_uint32)]

    name = c.c_char_p(f"world\\maps\\{directory}\\{directory}.wdt".encode("ascii"))
    handle = c.c_void_p()
    if not store.dll.CascOpenFile(store.handle, c.cast(name, c.c_void_p), 0xffffffff, 16, c.byref(handle)):
        return 0
    try:
        info = FileInfo()
        query = store.dll.CascGetFileInfo
        query.argtypes = [c.c_void_p, c.c_int, c.c_void_p, c.c_size_t, c.POINTER(c.c_size_t)]
        query.restype = c.c_bool
        return info.id if query(handle, 2, c.byref(info), c.sizeof(info), None) and info.id != 0xffffffff else 0
    finally:
        store.dll.CascCloseFile(handle)


def prepare_definitions():
    local = ROOT.parent / "WoWDBDefs" / "definitions"
    DEFINITIONS.mkdir(parents=True, exist_ok=True)
    for table in DBD_TABLES:
        filename = f"{table}.dbd"
        destination = DEFINITIONS / filename
        if destination.is_file():
            continue
        url = f"https://raw.githubusercontent.com/wowdev/WoWDBDefs/{DBD_REVISION}/definitions/{filename}"
        try:
            with urlopen(url, timeout=8) as response:
                data = response.read(1_000_000)
            if not data.startswith(b"COLUMNS\n"):
                raise ValueError(f"Invalid WoWDBDefs definition for {table}.")
        except OSError:
            if not (local / filename).is_file():
                raise
            data = (local / filename).read_bytes()
        pending = destination.with_suffix(".tmp")
        pending.write_bytes(data)
        pending.replace(destination)


def replace_source(source, anchor, replacement):
    if source.count(anchor) != 1:
        raise ValueError("The APR terrain sources have changed. Review the local reader adapter.")
    return source.replace(anchor, replacement)


def decoder_source(path):
    decoder = path.read_text(encoding="utf-8")
    decoder = replace_source(decoder, '    selected = {field:fields.index(field) for field in FIELDS[name]}',
        '    selected = {field:fields.index(field) for field in FIELDS[name] if field in fields}')
    decoder = replace_source(decoder, "        if kind==2:\n            return common[i].get(key, default)",
        '''        if fields[i] == "Region" and kind == 0 and width in (32,192) and off + 192 <= h[2]*8:
            return [(bits >> (off + j*32)) & 0xffffffff for j in range(6)]
        if kind==2:
            return common[i].get(key, default)''')
    decoder = replace_source(decoder, "        copy_at=ids_at+ids",
        '''        copy_at=ids_at+ids
        if name == "UiMap" and relations and "ParentUiMapID" not in selected:
            relation_at = copy_at + 8*copies
            relation_count, _, _ = struct.unpack_from("<3I", data, relation_at)
            if 12 + 8*relation_count != relations:
                raise ValueError("Invalid UiMap relation table")
            for parent, record in struct.iter_unpack("<2I", data[relation_at+12:]):
                if record >= count:
                    raise ValueError("Invalid UiMap parent record index")
                key = struct.unpack_from("<I", data, ids_at+4*record)[0] if ids else field(
                    int.from_bytes(data[record*h[2]:(record+1)*h[2]], "little"), h[10], None)
                rows[key]["ParentUiMapID"] = parent''')
    return decoder + '''
FILE_IDS.update(UiMap=1957206, UiMapAssignment=1957219, LiquidType=1371380, LiquidMaterial=1132538)
FIELDS.update(Map=("MapName_lang","Directory","WdtFileDataID"), UiMap=("Name_lang","Type","ParentUiMapID"),
              UiMapAssignment=("MapID","UiMapID","AreaID","Region"), LiquidType=("SoundBank","MaterialID"),
              LiquidMaterial=("LVF",))
STRINGS.update(("Name_lang","Directory"))
'''


def load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def installations(explicit):
    candidates = [Path(r"D:\Jeux\World of Warcraft"), Path(r"C:\Program Files (x86)\World of Warcraft"), *explicit]
    if os.name == "nt":
        import winreg

        for hive in (winreg.HKEY_LOCAL_MACHINE, winreg.HKEY_CURRENT_USER):
            for view in (winreg.KEY_WOW64_32KEY, winreg.KEY_WOW64_64KEY):
                try:
                    with winreg.OpenKey(hive, r"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
                                        0, winreg.KEY_READ | view) as entries:
                        for index in range(winreg.QueryInfoKey(entries)[0]):
                            name = winreg.EnumKey(entries, index)
                            try:
                                with winreg.OpenKey(entries, name) as entry:
                                    label, _ = winreg.QueryValueEx(entry, "DisplayName")
                                    if label.startswith("World of Warcraft"):
                                        location, _ = winreg.QueryValueEx(entry, "InstallLocation")
                                        if location:
                                            path = Path(location)
                                            candidates.extend((path, path.parent))
                            except OSError:
                                continue
                except OSError:
                    continue
    if os.environ.get("APR_WOW_ROOT"):
        candidates.append(Path(os.environ["APR_WOW_ROOT"]))
    roots = dict.fromkeys(path.resolve() for path in candidates if (path / ".build.info").is_file())
    clients = []
    for root in roots:
        lines = (root / ".build.info").read_text(encoding="utf-8-sig").splitlines()
        columns = [column.split("!", 1)[0] for column in lines[0].split("|")]
        rows = (dict(zip(columns, line.split("|"))) for line in lines[1:])
        products = sorted({row["Product"] for row in rows if PRODUCT.fullmatch(row.get("Product", ""))})
        for product in products:
            try:
                identity = installed_identity(root, product)
            except ValueError:
                continue
            if not BUILD.fullmatch(identity["build"]) or not re.fullmatch(r"[0-9a-fA-F]{32}", identity["buildKey"]):
                continue
            client_id = hashlib.sha256(f"{root}:{product}:{identity['buildKey']}".encode()).hexdigest()[:16]
            clients.append({"id": client_id, "root": str(root), **identity})
    return sorted(clients, key=lambda client: (client["product"] != "wow", client["product"]))


def resources():
    preferred = RETAIL / "layer-source" / "tools"
    source = preferred if (preferred / "apr-terrain/src/pack.rs").is_file() else GENERATOR / "tools"
    dll = next((GENERATOR / ".cache/terrain-tools").glob("CascLib-*/bin/CascLib_dll/x64/Release/CascLib.dll"), None)
    if not dll or not (source / "apr-terrain/Cargo.toml").is_file():
        raise ValueError("The APR terrain sources, CascLib and WoWDBDefs are required.")
    return source, dll


def storage_source(path):
    source = path.read_text(encoding="utf-8")
    anchor = '        self.identity = read_identity(root, {"wow": "retail", "wowf": "forever"}[product])'
    adapter = "\n" + inspect.getsource(installed_identity) + "\n" + inspect.getsource(wdt_id)
    source = replace_source(source, "\nclass Local(LocalStorage):", adapter + "\n\nclass Local(LocalStorage):")
    source = replace_source(source, anchor, "        self.identity = installed_identity(root, product)")
    source = replace_source(source, '                        catalog={r["ID"]:r["WdtFileDataID"] for r in map_table[0]}',
        '                        catalog={r["ID"]:wdt_id(local,r) for r in map_table[0]}')
    source = replace_source(source, '            metadata = liquid_catalog(read,args.tables,args.product,build)',
        '''            if local and args.defs:
                types, _ = local.table(Path(args.defs), "LiquidType")
                materials, _ = local.table(Path(args.defs), "LiquidMaterial")
                layouts = {r["ID"]: r["LVF"] for r in materials}
                metadata = {
                    "categories": {r["ID"]: r["SoundBank"]+1 for r in types if r["SoundBank"] in (0,1,2,3)},
                    "layouts": {r["ID"]: layouts[r["MaterialID"]] for r in types if r["MaterialID"] in layouts},
                }
            else:
                metadata = liquid_catalog(read,args.tables,args.product,build)''')
    source = replace_source(source, 'for n in FILE_IDS if n!="Map"', 'for n in ("AreaTable", "WMOAreaTable")')
    source = replace_source(source, '                except OSError as error:\n                    tables[name]',
        '                except (OSError, ValueError, KeyError, struct.error) as error:\n                    tables[name]')
    index_reader = Path(__file__).with_name("casc_root.py").read_text(encoding="utf-8")
    source = replace_source(source, "\nclass Local(LocalStorage):", "\n" + index_reader + "\n\nclass Local(LocalStorage):")
    return replace_source(source, '        for line in sys.stdin.buffer:\n            try:\n                key = json.loads(line)',
        '''        root_ids = None
        for line in sys.stdin.buffer:
            try:
                key = json.loads(line)
                if isinstance(key, dict):
                    file_id = key.get("modelRegistration")
                    if not local or type(file_id) is not int or not 0 < file_id <= 0xffffffff:
                        raise ValueError("Model registration requires the local CASC root index")
                    if root_ids is None:
                        root_ids = RootFileIds(read("ROOT"))
                    stream.write(struct.pack("<iB", 1, file_id in root_ids))
                    stream.flush()
                    continue''')


def model_bridge_source(path):
    source = replace_source(path.read_text(encoding="utf-8"), '    files: HashMap<u32, Arc<Vec<u8>>>,',
        '    files: HashMap<u32, Arc<Vec<u8>>>,\n    unregistered_models: std::collections::HashSet<u32>,')
    source = replace_source(source, '            files: HashMap::new(),',
        '            files: HashMap::new(),\n            unregistered_models: Default::default(),')
    return replace_source(source, '    pub fn named(&mut self, name: &str) -> Result<Arc<Vec<u8>>> {',
        '''    pub fn placement_model(&mut self, id: u32) -> Result<Option<Arc<Vec<u8>>>> {
        if self.unregistered_models.contains(&id) {
            return Ok(None);
        }
        match self.read(id) {
            Ok(model) => Ok(Some(model)),
            Err(error) if id != 0 => match self.request(&format!(r#"{{"modelRegistration":{id}}}"#)) {
                Ok(registered) if registered.as_slice() == [0] => {
                    self.unregistered_models.insert(id);
                    eprintln!("Ignoring orphaned model placement: FileDataID {id} absent from this build's CASC root");
                    Ok(None)
                }
                Ok(_) => Err(error),
                Err(index_error) => Err(error.context(format!("cannot verify model registration: {index_error:#}"))),
            },
            Err(error) => Err(error),
        }
    }
    pub fn named(&mut self, name: &str) -> Result<Arc<Vec<u8>>> {''')


def model_diagnostics_source(path):
    source = replace_source(path.read_text(encoding="utf-8"), 'fn m2(mut data: &[u8]) -> Result<Vec<Face>> {',
        '''include!("m3_collision.rs");
include!("m2_physics.rs");

fn m2(mut data: &[u8], mut read: impl FnMut(u32) -> Result<std::sync::Arc<Vec<u8>>>) -> Result<Vec<Face>> {
    if data.starts_with(b"M3DT") {
        return m3_collision(data).context("M3DT collision");
    }
    let mut physics = None;''')
    source = replace_source(source,
        '''        data.len() >= 304 && &data[..4] == b"MD20" && matches!(u32at(data, 4)?, 264 | 272 | 274),
        "unsupported M2 layout"''',
        '''        data.len() >= 304 && &data[..4] == b"MD20",
        "unsupported M2 layout (signature {:?}, {} bytes)",
        String::from_utf8_lossy(&data[..data.len().min(4)]), data.len()
    );
    let version = u32at(data, 4)?;
    ensure!(
        matches!(version, 264 | 272 | 274),
        "unsupported M2 layout (MD20 version {version})"''')
    source = replace_source(source, '    let mut out = m2(&source.read(id)?)?;',
        '''    let Some(data) = source.placement_model(id).with_context(|| format!("model FileDataID {id}"))? else {
        return Ok(Vec::new());
    };
    let mut out = m2(&data, |key| source.read(key)).with_context(|| format!("model FileDataID {id}"))?;''')
    source = replace_source(source, '            let file = if u16at(rec, 34)? & 64 != 0 {\n                source.read(id)?',
        '''            let file = if u16at(rec, 34)? & 64 != 0 {
                let Some(data) = source.placement_model(id)? else { return Ok(()); };
                data''')
    source = replace_source(source, '            append(tile, m2(&file)?, &p, "m2", None, None);',
        '''            let collision = m2(&file, |key| source.read(key))
                .with_context(|| format!("model FileDataID {id}"))?;
            append(tile, collision, &p, "m2", None, None);''')
    source = replace_source(source, 'tile.issue(format!("M2 {id}: {e}"))',
        'tile.issue(format!("M2 {id}: {e:#}"))')
    source = replace_source(source, '                ensure!(u32at(blob, 0)? == 0, "external M2 physics unavailable")',
        '''                ensure!(blob.len() == 4, "invalid PFID length");
                ensure!(physics.replace(u32at(blob, 0)?).is_none(), "duplicate PFID");''')
    source = replace_source(source, '    faces(\n        model_array(data, 224, 12)?,',
        '''    if let Some(id) = physics.filter(|id| *id != 0) {
        let bones = u32at(data, 44)? as usize;
        read(id).and_then(|bytes| verify_m2_physics(&bytes, bones))
            .with_context(|| format!("external M2 physics (PFID {id})"))?;
    }
    faces(
        model_array(data, 224, 12)?,''')
    return replace_source(source, 'tile.issue(format!("WMO doodad {idx}: {e}"))',
        'tile.issue(format!("WMO {key} doodad {idx}: {e:#}"))')


def texture_source(path):
    source = replace_source(path.read_text(encoding="utf-8"),
        'pub fn textures(data: &[u8], tile: &mut Tile, big: bool) -> Result<()> {\n    let file = Chunks::parse(data)?;',
        '''pub fn textures(data: &[u8], tile: &mut Tile, big: bool) -> Result<usize> {
    let file = Chunks::parse(data)?;
    let mut empty_base_layers = 0;''')
    source = replace_source(source, '            ensure!(tex != 0, "missing diffuse FileDataID");\n            let flags = u32at(r, 4)?;',
        '''            let flags = u32at(r, 4)?;
            if tex == 0 {
                // A zero in the modern MDID table can represent an untextured base.
                // Keep its place in MCLY so subsequent layers retain their alpha maps.
                ensure!(index == 0 && flags == 0 && file.get(b"MTEX").is_none(), "missing diffuse FileDataID");
                empty_base_layers += 1;
            }''')
    return replace_source(source, '"incomplete texture cell directory"\n    );\n    Ok(())',
        '"incomplete texture cell directory"\n    );\n    Ok(empty_base_layers)')


def pack_grid_source(source):
    source = replace_source(source, 'fn process_map(dir: &Path, out: &Path, map: &Map, workers: usize, capacity: usize) -> Result<Value> {',
        'fn process_map(dir: &Path, out: &Path, map: &Map, workers: usize, capacity: usize, query_graph: bool) -> Result<Value> {')
    source = replace_source(source, '                if offset % 16 == 0 || run_edge(-1) || run_edge(1) {',
        '                if query_graph && (offset % 16 == 0 || run_edge(-1) || run_edge(1)) {')
    source = replace_source(source, '''    ensure!(workers > 0, "threads must be positive");''', '''    build_grid_variant(geometry, out, workers, capacity, true)
}

pub fn build_grid_for_pack(geometry: &Path, out: &Path, workers: usize, capacity: usize) -> Result<Value> {
    build_grid_variant(geometry, out, workers, capacity, false)
}

fn build_grid_variant(geometry: &Path, out: &Path, workers: usize, capacity: usize, query_graph: bool) -> Result<Value> {
    ensure!(workers > 0, "threads must be positive");''')
    return replace_source(source, 'process_map(&dir, &stage, m, workers, capacity)?',
        'process_map(&dir, &stage, m, workers, capacity, query_graph)?')


def cargo_build(manifest, target, options, log, execute):
    env = os.environ.copy()
    portable = RETAIL / "toolchain"
    cargo = shutil.which("cargo")
    if not cargo and (portable / "cargo/bin/cargo.exe").is_file():
        cargo = str(portable / "cargo/bin/cargo.exe")
        env.update(CARGO_HOME=str(portable / "cargo"), RUSTUP_HOME=str(portable / "rustup"))
    if not cargo:
        raise ValueError("Rust Cargo is required to compile the local terrain generator.")
    env["CARGO_TARGET_DIR"] = str(target)
    command = [cargo, "build", "--release", "--offline", "--locked", "--jobs", "2",
               "--manifest-path", manifest, *options]
    log("Cargo build · APR terrain")
    if execute:
        execute(command, env)
    else:
        result = subprocess.run(command, env=env, capture_output=True)
        if result.returncode:
            raise ValueError(result.stderr.decode("utf-8", errors="replace"))


def prepare_forever_packer(log, execute=None):
    with BUILD_LOCK:
        target = WORKSPACE / "native-target-forever"
        manifest = GENERATOR / "tools/apr-terrain/Cargo.toml"
        cargo_build(manifest, target, ["--bin", "apr-terrain"], log, execute)
        return target / "release/apr-terrain.exe"


def prepare_binaries(log, execute=None, toolchain=None):
    with BUILD_LOCK:
        source, dll = resources() if toolchain is None else toolchain
        crate = source / "apr-terrain"
        target = WORKSPACE / "native-target"
        executables = target / "release"
        code = WORKSPACE / "native-source/tools"
        model_readers = [Path(__file__).with_name(name) for name in ("m2_physics.rs", "m3_collision.rs")]
        texture_tests = Path(__file__).with_name("adt_texture_tests.rs")
        files = [*model_readers, texture_tests, Path(__file__).with_name("casc_root.py"), crate / "Cargo.lock",
                 *sorted(crate.glob("**/*.rs")), *sorted(crate.glob("**/*.toml")),
                 crate / "client/src/storage.py", crate / "client/src/db2.py",
                 source / "navigation_terrain/client.py", source / "navigation_v2/liquid_metadata.py"]
        fingerprint = hashlib.sha256(Path(__file__).read_bytes())
        for file in files:
            fingerprint.update(file.read_bytes())
        stamp = target / "apr-ui-build.txt"
        signature = fingerprint.hexdigest()
        if stamp.is_file() and stamp.read_text() == signature and all(
            (executables / name).is_file() for name in ("apr-terrain.exe", "apr-terrain-reader.exe")
        ):
            return executables, dll
        native = code / "apr-terrain"
        shutil.copytree(crate, native, dirs_exist_ok=True, ignore=shutil.ignore_patterns("target", "__pycache__"))
        for rel in ("navigation_terrain/client.py", "navigation_v2/liquid_metadata.py"):
            destination = code / rel
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source / rel, destination)
        adapter = native / "client/src/storage.py"
        adapter.write_text(storage_source(adapter), encoding="utf-8")
        decoder = native / "client/src/db2.py"
        decoder.write_text(decoder_source(decoder), encoding="utf-8")
        reader = native / "client/src/main.rs"
        reader_code = replace_source(reader.read_text(encoding="utf-8"),
            'matches!(product, "wow" | "wowf")',
            "product.starts_with(\"wow\") && product.bytes().all(|b| b.is_ascii_lowercase() || b.is_ascii_digit() || b == b'_')"
        )
        reader_code = replace_source(reader_code, '        let rel = format!("{generation}/{id}/{x}_{y}.json");',
            '''        wait_if_paused();
        let areas: BTreeSet<u32> = tile.triangles.iter().filter_map(|triangle| triangle.area).collect();
        println!("APR_AREAS {x}_{y} {}", serde_json::to_string(&areas)?);
        let rel = format!("{generation}/{id}/{x}_{y}.json");''')
        reader_code = replace_source(reader_code, "                } else {\n                    emit(",
            '''                } else {
                    wait_if_paused();
                    println!("APR_TILE {x}_{y}");
                    emit(''')
        reader_code = replace_source(reader_code, '''        if let Err(e) = source
            .read(ids[3])
            .and_then(|d| adt::textures(&d, &mut tile, flags & 0x84 != 0))
        {
            tile.issue(format!("textures {}: {e}", ids[3]))
        }''', '''        match source.read(ids[3]).and_then(|d| adt::textures(&d, &mut tile, flags & 0x84 != 0)) {
            Ok(0) => (),
            Ok(count) => eprintln!("Texture FileDataID {}: {count} untextured base layers; other layers retained", ids[3]),
            Err(error) => tile.issue(format!("textures {}: {error}", ids[3])),
        }''')
        reader.write_text(reader_code + PAUSE, encoding="utf-8")
        adt = native / "client/src/adt.rs"
        adt.write_text(texture_source(adt) + '\ninclude!("adt_texture_tests.rs");\n', encoding="utf-8")
        shutil.copyfile(texture_tests, adt.with_name(texture_tests.name))
        models = native / "client/src/models.rs"
        models.write_text(model_diagnostics_source(models), encoding="utf-8")
        for path in model_readers:
            shutil.copyfile(path, models.with_name(path.name))
        bridge = native / "client/src/bridge.rs"
        bridge.write_text(model_bridge_source(bridge), encoding="utf-8")
        pack = native / "src/pack.rs"
        pack.write_text(pack.read_text(encoding="utf-8").replace(
            'Some("wowf" | "synthetic") => "forever",',
            'Some("wowf" | "synthetic") => "forever",\n        Some(product) if product.starts_with("wow") => product,'
        ).replace("    fn load(&self, pos: nav::Pos) -> Result<page::Page> {",
                  "    fn load(&self, pos: nav::Pos) -> Result<page::Page> {\n        wait_if_paused();") + PAUSE,
                        encoding="utf-8")
        metadata = native / "src/source.rs"
        metadata_code = replace_source(metadata.read_text(encoding="utf-8"),
            '        let v = apr_terrain_grid::build_grid_with_layer_capacity(', '''        // The Lua packer uses the raster links and regions and computes its own portal paths.
        let raster = if cmd == "grid" {
            apr_terrain_grid::build_grid_with_layer_capacity
        } else {
            apr_terrain_grid::build_grid_for_pack
        };
        let v = raster(''')
        metadata.write_text(metadata_code.replace(
            'let profile = if index["product"] == "wow" {\n        "retail"\n    } else {\n        "forever"\n    };',
            'let profile = match index["product"].as_str() {\n        Some("wow") => "retail",\n        Some("wowf" | "synthetic") => "forever",\n        Some(product) => product,\n        None => bail!("unknown product"),\n    };',
        ).replace('        for rec in arr(&map["tiles"])? {',
                  '        for rec in arr(&map["tiles"])? {\n            wait_if_paused();') + PAUSE,
                            encoding="utf-8")
        grid = native / "grid/src/disk.rs"
        grid.write_text(pack_grid_source(grid.read_text(encoding="utf-8")).replace('    let p = dir.join(&r.file).canonicalize()?;',
                  '    wait_if_paused();\n    let p = dir.join(&r.file).canonicalize()?;') + PAUSE, encoding="utf-8")
        grid_lib = native / "grid/src/lib.rs"
        grid_lib.write_text(grid_lib.read_text(encoding="utf-8") + '\npub use disk::build_grid_for_pack;\n', encoding="utf-8")
        grid_test = native / "grid/tests/disk.rs"
        grid_test.write_text(replace_source(grid_test.read_text(encoding="utf-8"), '    assert_eq!(word(&b, 20), 0);',
            '''    assert_eq!(word(&b, 20), 0);
    let pack = root.join("pack-grid");
    let pack_index = apr_terrain_grid::build_grid_for_pack(&root, &pack, 2, apr_terrain_grid::LINK_LAYERS).unwrap();
    assert_eq!(pack_index["continents"]["9"]["tiles"], index["continents"]["9"]["tiles"]);
    for field in ["regions", "components"] {
        assert_eq!(pack_index["continents"]["9"][field], index["continents"]["9"][field]);
    }
    for tile in ["32_32", "33_32"] {
        for suffix in ["nav", "area"] {
            let file = format!("tiles/9/{tile}.{suffix}.gz");
            assert_eq!(read(&pack.join(&file)), read(&out.join(&file)));
        }
    }
    let regions_only = read(&pack.join("graph/9.bin.gz"));
    assert_eq!(word(&regions_only, 16), 0);
    assert_eq!(word(&regions_only, 20), comp_count);
    assert_eq!(word(&regions_only, 28), region_count);
    let region_table = 32 + 40;
    let full_region_table = off - 4 * (comp_count + region_count);
    assert_eq!(&regions_only[region_table..region_table + 4 * (comp_count + region_count)],
               &graph[full_region_table..off]);'''), encoding="utf-8")
        command_test = native / "tests/command.rs"
        command_code = replace_source(command_test.read_text(encoding="utf-8"),
            '"complete":true,"errors":[],"triangles":', '"complete":true,"errors":[],"textureCells":[],"triangles":')
        command_test.write_text(replace_source(command_code, '    assert_eq!(packed["profile"], "retail");',
            '''    assert_eq!(packed["profile"], "retail");
    let direct_out = root.join("direct");
    let listfile = root.join("textures.csv");
    let allowlist = root.join("roads.json");
    fs::write(&listfile, "101;tileset/fixture.blp\\n").unwrap();
    fs::write(&allowlist, r#"["tileset/fixture.blp"]"#).unwrap();
    let direct = call(&["generate", "--geometry", geom.to_str().unwrap(), "--continents", "91",
        "--cells", "128", "--listfile", listfile.to_str().unwrap(), "--allowlist", allowlist.to_str().unwrap(),
        "--out", direct_out.to_str().unwrap()]);
    assert_eq!(direct["files"], packed["files"]);
    assert_eq!(call(&["check", "--out", direct_out.to_str().unwrap()])["state"], "ok");'''), encoding="utf-8")
        cargo_build(native / "Cargo.toml", target, ["--workspace"], log, execute)
        stamp.write_text(signature, encoding="utf-8")
        return executables, dll


def read_json(path):
    return json.loads(path.read_bytes())


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(".next")
    temp.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    temp.replace(path)
