"""Validate runtime dependencies and client-specific loading in an APR release."""
from pathlib import Path
import argparse
import base64
import re
import struct
import xml.etree.ElementTree as ET
import zlib


def read_manifest(path):
    text = path.read_text(encoding='utf-8-sig')
    # WoW accepts the shared xsi schema prefix without a local declaration;
    # Embedded library manifests can rely on that convention.
    if 'xsi:' in text and 'xmlns:xsi=' not in text:
        text = re.sub(r'<Ui\b', '<Ui xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"', text, count=1)
    return ET.fromstring(text)


def validate_runtime_files(root, toc, game):
    root = root.resolve()
    visited = set()

    def resolve_dependency(path):
        path = path.resolve()
        if not path.is_relative_to(root):
            raise AssertionError(f'Runtime dependency outside package root: {path}')
        return path

    def visit(path):
        assert path.is_file(), f'Missing runtime dependency: {path.relative_to(root)}'
        if path in visited:
            return
        visited.add(path)
        if path.suffix != '.xml':
            return
        for reference in manifest_references(path, game):
            nested = resolve_dependency(path.parent / reference)
            visit(nested if nested.is_file() else resolve_dependency(root / reference))

    for line in resolve_dependency(toc).read_text(encoding='utf-8-sig').splitlines():
        if line.strip() and not line.lstrip().startswith('#'):
            reference = line.strip().replace('\\', '/').replace('[Game]', game)
            visit(resolve_dependency(root / reference))
    return visited


def manifest_references(path, game):
    for element in read_manifest(path).iter():
        if element.tag.rsplit('}', 1)[-1] in ('Include', 'Script') and 'file' in element.attrib:
            yield element.attrib['file'].replace('\\', '/').replace('[Game]', game)


def validate_terrain_loading(root, files, game):
    library = (root / 'APR-Core/libs/LibAPRNavigation-1.0').resolve()
    retail_terrain = library / 'Data/retail/Terrain'
    if game == 'Standard':
        has_retail_terrain = retail_terrain / 'Terrain.xml' in files
        for path in files:
            if not path.is_relative_to(library):
                continue
            relative = path.relative_to(library)
            if has_retail_terrain and (relative == Path('Terrain.lua') or relative.parts[0] == 'Terrain'
                                       or path.is_relative_to(retail_terrain)):
                continue
            assert relative.name != 'Terrain.lua' and 'Terrain' not in relative.parts, \
                f'Retail must not load Forever terrain: {relative}'
        if has_retail_terrain:
            assert library / 'Terrain.lua' in files, 'Retail must load its terrain provider'
    elif (library / 'Terrain_Camelot.xml').is_file():
        assert library / 'Terrain.lua' in files, 'Forever must load its terrain provider'
        assert not any(path.is_relative_to(retail_terrain) for path in files), 'Forever must not load Retail terrain'
        indices = {path for path in files if path.parent == library / 'Data/forever/Terrain'
                   and re.fullmatch(r'Index-\d+\.lua', path.name)}
        if indices:
            validate_terrain_companions(root, indices)


def validate_terrain_companions(root, indices):
    expected = set()
    for index in indices:
        source = index.read_text(encoding='utf-8')
        identity = re.search(r'L:RegisterTerrainPartitionIndex\("forever",(\d+),(\d+),D,I\)', source)
        pages = re.search(r'^I\.pages=\{([^{}]+)\}$', source, re.M)
        assert identity and pages, f'Invalid terrain index: {index.name}'
        world, revision = identity.groups()
        assert index.name == f'Index-{world}.lua'
        chunks = re.findall(r'"([^"]+)"', pages[1])
        records = b''.join(zlib.decompress(base64.b64decode(block, validate=True)) for block in chunks)
        assert records and len(records) % 16 == 0, f'Invalid terrain pages: {index.name}'
        groups = {group for _, group, _, _, _ in struct.iter_unpack('<IIIHH', records)}
        for group in groups:
            name = f'APR_NavData_Forever_{world}_{group}'
            companion = root.parent / name
            toc = companion / f'{name}_Camelot.toc'
            assert toc.is_file(), f'Missing terrain companion: {name}'
            assert list(companion.glob('*.toc')) == [toc], f'Unexpected client TOC: {name}'
            lines = [line.strip() for line in toc.read_text(encoding='utf-8-sig').splitlines()]
            assert '## LoadOnDemand: 1' in lines and '## Dependencies: APR' in lines, f'Invalid terrain TOC: {name}'
            scripts = [line for line in lines if line and not line.startswith('#')]
            filename = f'World-{world}-Group-{group}.lua'
            assert scripts == [filename] and (companion / filename).is_file(), f'Missing terrain group script: {name}'
            with (companion / filename).open('rb') as stream:
                stream.seek(max(0, (companion / filename).stat().st_size - 160))
                tail = stream.read().rstrip()
            assert tail.endswith(f'L:RegisterTerrainPartitionPages("forever",{world},{revision},{group},D)'.encode()), \
                f'Mismatched terrain companion revision or identity: {name}'
            expected.add(name)
    found = {p.name for p in root.parent.glob('APR_NavData_Forever_*') if p.is_dir()}
    assert found == expected, 'Unreferenced or absent terrain companions'


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


def validate(root):
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
    for toc, game in ((retail, 'Standard'), (forever, 'Camelot'), (root / 'APR.toc', 'Standard')):
        files = validate_runtime_files(root, toc, game)
        validate_terrain_loading(root, files, game)
    manifests = [root/'Routes/RouteList_Standard.xml', root/'Routes/RouteList_Camelot.xml']
    scripts = []
    for manifest in manifests:
        entries = [element.attrib['file'] for element in read_manifest(manifest)]
        assert all((root / entry).is_file() for entry in entries)
        assert len(entries) == len(set(entries)), f'Duplicate route in {manifest.name}'
        scripts.append(set(entries))
    assert not scripts[0] & scripts[1], 'A route file is loaded by both client families'
    validate_runtime_only(root)
    print(f'Package passed: Retail ({len(scripts[0])} route files), Forever ({len(scripts[1])} route files), complete runtime dependencies, no development files')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('package', type=Path, help='Unpacked addon directory, normally .release/APR')
    validate(parser.parse_args().package)
