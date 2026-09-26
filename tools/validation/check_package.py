"""Validate client-specific route loading in one unpacked APR release."""
from pathlib import Path
import argparse
import xml.etree.ElementTree as ET


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
    expected = ['FarstriderLibData.xml', f'FarstriderLibData/Areas/{flavor}/FarstriderLibData_Areas.xml']
    expected.append(f'FarstriderLibData/Waypoints/{flavor}/FarstriderLibData_Waypoints.xml')
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
    assert route_entries(retail) == ['Routes/RouteList.xml']
    assert route_entries(forever) == ['Routes/Forever/RouteList.xml']
    assert route_entries(root / 'APR.toc') == ['Routes/RouteList.xml']
    forever_toc = forever.read_text(encoding='utf-8-sig')
    assert '## Interface: 16001' in forever_toc
    assert '120105' not in forever_toc.splitlines()[0]
    validate_farstrider(root, retail, 'Standard')
    validate_farstrider(root, forever, 'Camelot')
    validate_farstrider(root, root / 'APR.toc', 'Standard')
    manifests = [root/'Routes/RouteList.xml', root/'Routes/Forever/RouteList.xml']
    scripts = []
    for manifest in manifests:
        entries = [element.attrib['file'] for element in ET.parse(manifest).getroot()]
        assert all((root / entry).is_file() for entry in entries)
        assert len(entries) == len(set(entries)), f'Duplicate route in {manifest.name}'
        scripts.append(set(entries))
    assert not scripts[0] & scripts[1], 'A route file is loaded by both client families'
    assert not (root/'tools').exists(), 'Local tooling must not be distributed'
    print(f'Package passed: one addon, Retail ({len(scripts[0])} files), Forever ({len(scripts[1])} files), client-specific Farstrider data, no local tools')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('package', type=Path, help='Unpacked addon directory, normally .release/APR')
    validate(parser.parse_args().package)
