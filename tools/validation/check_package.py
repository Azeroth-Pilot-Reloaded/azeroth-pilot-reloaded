"""Validate runtime dependencies and client-specific loading in an APR release."""
from pathlib import Path
import argparse
import xml.etree.ElementTree as ET


def validate_runtime_files(root, toc, game):
    visited = set()

    def visit(path):
        assert path.is_file(), f'Missing runtime dependency: {path.relative_to(root)}'
        if path in visited or path.suffix != '.xml':
            return
        visited.add(path)
        for element in ET.parse(path).iter():
            if element.tag.rsplit('}', 1)[-1] not in ('Include', 'Script') or 'file' not in element.attrib:
                continue
            reference = element.attrib['file'].replace('\\', '/').replace('[Game]', game)
            nested = path.parent / reference
            visit(nested if nested.is_file() else root / reference)

    for line in toc.read_text(encoding='utf-8-sig').splitlines():
        if line.strip() and not line.lstrip().startswith('#'):
            visit(root / line.strip().replace('\\', '/').replace('[Game]', game))


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


def validate_farstrider(root, toc, game):
    entry = 'APR-Core/libs/FarstriderLibData_[Game].xml'
    entries = [line.strip().replace('\\', '/') for line in toc.read_text(encoding='utf-8-sig').splitlines()]
    assert entries.count(entry) == 1, f'{toc.name} must select Farstrider data by client'
    manifest = root / entry.replace('[Game]', game)
    includes = [element.attrib['file'].replace('\\', '/') for element in ET.parse(manifest).getroot()]
    flavor = 'Vanilla' if game == 'Camelot' else 'Standard'
    expected = ['FarstriderLibData.xml', f'libs/FarstriderLibData/Areas/{flavor}/FarstriderLibData_Areas.xml']
    expected.append(f'libs/FarstriderLibData/Waypoints/{flavor}/FarstriderLibData_Waypoints.xml')
    expected.append('FarstriderLibData_Finalizer.xml')
    assert includes == expected, f'Wrong Farstrider data or load order for {game}'
    for include in includes:
        nested = manifest.parent / include
        assert nested.is_file(), f'Missing Farstrider manifest: {nested}'
        for element in ET.parse(nested).getroot():
            reference = element.attrib['file'].replace('\\', '/')
            assert (nested.parent / reference).is_file(), f'Missing Farstrider dependency: {reference}'


def validate(root):
    retail = root / 'APR_Mainline.toc'
    forever = root / 'APR_Camelot.toc'
    assert retail.is_file() and forever.is_file(), 'Both client TOCs must exist in the same package'
    for toc in (retail, forever, root / 'APR.toc'):
        assert route_entries(toc) == ['Routes/RouteList_[Game].xml'], f'{toc.name} must select routes by client'
    forever_toc = forever.read_text(encoding='utf-8-sig')
    assert '## Interface: 16001' in forever_toc
    assert '120105' not in forever_toc.splitlines()[0]
    validate_farstrider(root, retail, 'Standard')
    validate_farstrider(root, forever, 'Camelot')
    validate_farstrider(root, root / 'APR.toc', 'Standard')
    for toc, game in ((retail, 'Standard'), (forever, 'Camelot'), (root / 'APR.toc', 'Standard')):
        validate_runtime_files(root, toc, game)
    manifests = [root/'Routes/RouteList_Standard.xml', root/'Routes/RouteList_Camelot.xml']
    scripts = []
    for manifest in manifests:
        entries = [element.attrib['file'] for element in ET.parse(manifest).getroot()]
        assert all((root / entry).is_file() for entry in entries)
        assert len(entries) == len(set(entries)), f'Duplicate route in {manifest.name}'
        scripts.append(set(entries))
    assert not scripts[0] & scripts[1], 'A route file is loaded by both client families'
    validate_runtime_only(root)
    print(f'Package passed: one addon, Retail ({len(scripts[0])} files), Forever ({len(scripts[1])} files), complete runtime dependencies, no development files')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('package', type=Path, help='Unpacked addon directory, normally .release/APR')
    validate(parser.parse_args().package)
