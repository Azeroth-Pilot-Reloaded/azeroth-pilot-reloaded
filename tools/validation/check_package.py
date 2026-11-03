"""Validate runtime dependencies and client-specific loading in an APR release."""
from collections import Counter
from pathlib import Path, PurePosixPath
import argparse
import re
import xml.etree.ElementTree as ET


TERRAIN_INDEX = 'APR-Core/features/navigation/TerrainIndex.lua'
TERRAIN_LOADER = 'APR-Core/features/navigation/NavigationTerrain.lua'


def read_manifest(path):
    text = path.read_text(encoding='utf-8-sig')
    # WoW accepts the shared xsi schema prefix without a local declaration;
    # Embedded library manifests can rely on that convention.
    if 'xsi:' in text and 'xmlns:xsi=' not in text:
        text = re.sub(r'<Ui\b', '<Ui xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"', text, count=1)
    return ET.fromstring(text)


def validate_runtime_files(root, toc, game):
    root = root.resolve()
    visited, active = Counter(), set()

    def visit(path):
        path = path.resolve()
        assert path.is_relative_to(root), f'Runtime dependency outside APR: {path}'
        assert path.is_file(), f'Missing runtime dependency: {path.relative_to(root)}'
        visited[path] += 1
        if path.suffix != '.xml':
            return
        assert path not in active, f'Cyclic runtime manifest: {path.relative_to(root)}'
        active.add(path)
        for nested in xml_runtime_references(path, root, game):
            visit(nested)
        active.remove(path)

    for line in toc.read_text(encoding='utf-8-sig').splitlines():
        if line.strip() and not line.lstrip().startswith('#'):
            visit(root / line.strip().replace('\\', '/').replace('[Game]', game))
    return visited


def xml_runtime_references(path, root, game):
    for element in read_manifest(path).iter():
        if element.tag.rsplit('}', 1)[-1] not in ('Include', 'Script') or 'file' not in element.attrib:
            continue
        reference = element.attrib['file'].replace('\\', '/').replace('[Game]', game)
        nested = path.parent / reference
        yield nested if nested.is_file() else root / reference


def validate_runtime_only(root):
    for name in ('tools', 'tests', 'docs', 'readme', '.github', '.githooks', '.vscode', '.cache', '.venv'):
        assert not (root / name).exists(), f'Development files must not be distributed: {name}'
    for path in root.rglob('*'):
        if not path.is_file():
            continue
        relative = path.relative_to(root)
        # The packager generates the release changelog; license notices also stay.
        if str(relative) == 'CHANGELOG.md' or path.name.upper().startswith(('LICENSE', 'COPYING')):
            continue
        assert not any(part.startswith('.') for part in relative.parts), f'Repository metadata in package: {relative}'
        assert path.suffix.lower() not in ('.md', '.svg', '.json', '.py', '.cmd', '.yml', '.yaml'), \
            f'Development source in package: {relative}'
        assert not (path.suffix == '.toc' and len(relative.parts) > 1), f'Standalone library TOC in package: {relative}'


def route_entries(toc):
    return [line.strip().replace('\\', '/') for line in toc.read_text(encoding='utf-8-sig').splitlines()
            if line.strip().startswith('Routes/')]


def validate_navigation(root, toc, game):
    entries = [line.strip().replace('\\', '/') for line in toc.read_text(encoding='utf-8-sig').splitlines()]
    entry = 'APR-Core/libs/LibAPRNavigation-1.0/LibAPRNavigation.xml'
    assert entries.count(entry) == 1, f'{toc.name} must load the navigation catalogue once'
    assert not any('Farstrider' in line for line in entries if line and not line.startswith('#')), 'Legacy navigation must not be loaded'
    assert (root / entry).is_file(), 'Missing navigation catalogue'


def toc_metadata(toc):
    metadata = {}
    for line in toc.read_text(encoding='utf-8-sig').splitlines():
        if line.startswith('##') and ':' in line:
            key, _, value = line[2:].partition(':')
            metadata[key.strip().lower()] = value.strip()
    return metadata


def read_terrain_index(path):
    """Evaluate generated data with no client, filesystem or Python globals."""
    if not path.is_file():
        return None
    from lupa.lua51 import LuaRuntime, LuaError
    runtime = LuaRuntime(register_eval=False, register_builtins=False, max_memory=8 * 1024 * 1024)
    read = runtime.eval('''function(source)
        local target = {}
        local chunk, err = loadstring(source, "@TerrainIndex.lua")
        assert(chunk, err)
        setfenv(chunk, { APR = target })
        debug.sethook(function() error("Terrain index instruction limit exceeded") end, "", 100000)
        local ok, failure = pcall(chunk)
        debug.sethook()
        assert(ok, failure)
        return target.NavigationTerrainIndex
    end''')
    try:
        index = read(path.read_text(encoding='utf-8-sig'))
        assert index is not None and index['schema'] == 1, 'unsupported schema'
        return index
    except (LuaError, AssertionError) as error:
        raise AssertionError(f'Invalid terrain index: {error}') from error


def terrain_declarations(index):
    from lupa.lua51 import lua_type
    if index is None:
        return []
    profiles = index['profiles']
    assert lua_type(profiles) == 'table', 'Invalid terrain index profiles'
    result = []
    for profile, record in profiles.items():
        for world, definition in terrain_worlds(profile, record):
            packs = terrain_world_packs(world, definition)
            for pack in packs:
                result.append((profile, world, terrain_pack_item(pack)))
    return result


def terrain_worlds(profile, record):
    from lupa.lua51 import lua_type
    assert profile in ('retail', 'forever'), f'Unknown terrain profile: {profile}'
    assert lua_type(record) == 'table' and lua_type(record['worlds']) == 'table', 'Invalid terrain index worlds'
    builds = record['builds']
    assert lua_type(builds) == 'table', 'Invalid terrain builds'
    assert all(isinstance(build, str) and enabled is True for build, enabled in builds.items()), 'Invalid terrain build identity'
    return record['worlds'].items()


def terrain_world_packs(world, definition):
    from lupa.lua51 import lua_type
    assert type(world) is int and world >= 0, 'Invalid terrain world identity'
    assert lua_type(definition) == 'table' and lua_type(definition['packs']) == 'table', 'Invalid terrain packs'
    return terrain_array(definition['packs'])


def terrain_array(packs):
    keys = set(packs.keys())
    assert keys == set(range(1, len(keys) + 1)), 'Terrain packs must be a contiguous array'
    return [packs[key] for key in range(1, len(keys) + 1)]


def terrain_pack_item(pack):
    from lupa.lua51 import lua_type
    assert lua_type(pack) == 'table', 'Invalid terrain pack'
    item = {key: pack[key] for key in ('id', 'revision', 'file')}
    assert isinstance(item['id'], str) and item['id'], 'Invalid terrain pack identity'
    assert pack['addon'] is None, 'Terrain must be internal to APR, without an addon declaration'
    assert type(item['revision']) is int and item['revision'] >= 0, 'Invalid terrain revision'
    validate_terrain_chunk_path(item['file'])
    return item


def validate_terrain_chunk_path(file):
    assert isinstance(file, str) and file.endswith('.lua') and '\\' not in file, 'Invalid terrain chunk file'
    path = PurePosixPath(file)
    assert not path.is_absolute() and '..' not in path.parts and path.as_posix() == file \
        and path.parts[0] == 'NavigationData', 'Invalid terrain chunk path'


def validate_terrain(release, apr, client_files):
    declarations = terrain_declarations(read_terrain_index(apr / TERRAIN_INDEX))
    if declarations:
        assert all(files[apr / TERRAIN_INDEX] == 1 for files in client_files), 'Every client must load the terrain index once'
        assert all(files[apr / TERRAIN_LOADER] == 1 for files in client_files), 'Every client must load the terrain loader once'
    identities, chunks = set(), set()
    for profile, world, pack in declarations:
        identity = (profile, world, pack['id'])
        assert identity not in identities, f'Duplicate terrain pack identity: {identity}'
        identities.add(identity)
        chunk = apr / pack['file']
        assert chunk.is_file(), f'Missing internal terrain chunk: {pack["file"]}'
        chunks.add(chunk)
        expected = (0, 2) if profile == 'retail' else (1,)
        for client, files in enumerate(client_files):
            if client in expected:
                assert files[chunk] == 1, f'Client must load its indexed terrain chunk once: {pack["file"]}'
                order = list(files)
                assert order.index(apr / TERRAIN_LOADER) < order.index(chunk), \
                    f'Terrain loader must precede its internal chunks: {pack["file"]}'
            else:
                assert files[chunk] == 0, f'Terrain chunk loaded by the wrong client profile: {pack["file"]}'
    for path in (apr / 'NavigationData').rglob('*.lua'):
        assert path in chunks, f'Unindexed internal terrain chunk: {path.relative_to(apr)}'
    for path in release.glob('APR_NavData_*'):
        assert not path.is_dir(), f'Standalone terrain addon must not be distributed: {path.name}'
    return len(chunks)


def validate(root):
    root = root.resolve()
    root = root / 'APR' if (root / 'APR').is_dir() else root
    retail = root / 'APR_Mainline.toc'
    forever = root / 'APR_Camelot.toc'
    assert retail.is_file() and forever.is_file(), 'Both client TOCs must exist in the same package'
    for toc in (retail, forever, root / 'APR.toc'):
        assert route_entries(toc) == ['Routes/RouteList_[Game].xml'], f'{toc.name} must select routes by client'
    forever_toc = forever.read_text(encoding='utf-8-sig')
    assert '## Interface: 16001' in forever_toc
    assert '120105' not in forever_toc.splitlines()[0]
    validate_navigation(root, retail, 'Standard')
    validate_navigation(root, forever, 'Camelot')
    validate_navigation(root, root / 'APR.toc', 'Standard')
    client_files = [validate_runtime_files(root, toc, game)
                    for toc, game in ((retail, 'Standard'), (forever, 'Camelot'), (root / 'APR.toc', 'Standard'))]
    manifests = [root/'Routes/RouteList_Standard.xml', root/'Routes/RouteList_Camelot.xml']
    scripts = []
    for manifest in manifests:
        entries = [element.attrib['file'] for element in read_manifest(manifest)]
        assert all((root / entry).is_file() for entry in entries)
        assert len(entries) == len(set(entries)), f'Duplicate route in {manifest.name}'
        scripts.append(set(entries))
    assert not scripts[0] & scripts[1], 'A route file is loaded by both client families'
    validate_runtime_only(root)
    terrain = validate_terrain(root.parent, root, client_files)
    print(f'Package passed: APR with {terrain} internal terrain chunks, Retail ({len(scripts[0])} files), Forever ({len(scripts[1])} files), complete runtime dependencies, no development files')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('package', type=Path, help='Unpacked release root or its APR addon directory')
    validate(parser.parse_args().package)
