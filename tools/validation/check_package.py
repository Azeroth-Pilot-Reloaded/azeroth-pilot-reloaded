"""Validate client-specific route loading in one unpacked APR release."""
from pathlib import Path
import argparse
import xml.etree.ElementTree as ET


def route_entries(toc):
    return [line.strip().replace('\\', '/') for line in toc.read_text(encoding='utf-8-sig').splitlines()
            if line.strip().startswith('Routes/')]


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
    manifests = [root/'Routes/RouteList.xml', root/'Routes/Forever/RouteList.xml']
    scripts = []
    for manifest in manifests:
        entries = [element.attrib['file'] for element in ET.parse(manifest).getroot()]
        assert all((root / entry).is_file() for entry in entries)
        assert len(entries) == len(set(entries)), f'Duplicate route in {manifest.name}'
        scripts.append(set(entries))
    assert not scripts[0] & scripts[1], 'A route file is loaded by both client families'
    assert not (root/'tools').exists(), 'Local tooling must not be distributed'
    print(f'Package passed: one addon, Retail ({len(scripts[0])} files), Forever ({len(scripts[1])} files), no local tools')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('package', type=Path, help='Unpacked addon directory, normally .release/APR')
    validate(parser.parse_args().package)
