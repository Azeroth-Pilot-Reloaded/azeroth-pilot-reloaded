"""Summarize observed Retail zone and subzone coverage for the batch generator."""

from collections import Counter, defaultdict
from datetime import datetime, timezone
import re

from .retail_worker import digest, read, write


MAP_TYPES = {3, 4, 5, 6}
PAGE = re.compile(rb'^D\.packed\.grid\[(\d+)\]=')
GEOMETRY = re.compile(rb'\["(cx0|cy0|nx|ny)"\]=(-?\d+)')
INTERIORS = re.compile(rb'\["areaParents"\]=\{([^}]*)\}')
INTERIOR = re.compile(rb'\[(\d+)\]=(\d+)')


def packed_observation(root, result):
    world = result['id']
    pack = root / result['pack']
    checksum = result['packSha256']
    if digest(pack / 'PACK.json') != checksum:
        raise ValueError(f'World {world} manifest changed during report')
    cache = root / 'area-pack-index' / f'{world}.json'
    if cache.is_file():
        cached = read(cache)
        if cached['packSha256'] == checksum:
            return cached
    manifest = read(pack / 'PACK.json')
    with (pack / f'Nav/Nav{world}.lua').open('rb') as source:
        declaration = next((line for line in source if b'["areaParents"]=' in line), None)
    if declaration is None:
        raise ValueError(f'World {world} has no terrain metadata')
    geometry = {key.decode(): int(value) for key, value in GEOMETRY.findall(declaration)}
    interior = {int(key): int(value) for key, value in INTERIOR.findall(INTERIORS.search(declaration)[1])}
    tiles = set()
    for path in manifest['loadOrder']:
        if path == f'Nav/Nav{world}.lua':
            continue
        with (pack / path).open('rb') as source:
            for line in source:
                match = PAGE.match(line)
                if match:
                    north, west = divmod(int(match[1]) - 1, geometry['ny'])
                    tiles.add(f'{31 - west - geometry["cy0"]}_{31 - north - geometry["cx0"]}')
    if len(tiles) != result['packedTiles']:
        raise ValueError(f'World {world} page count differs from the verified pack')
    observation = {'packSha256': checksum, 'tiles': sorted(tiles), 'interiors': interior}
    cache.parent.mkdir(exist_ok=True)
    write(cache, observation)
    return observation


def status_counts(values):
    return Counter(row['status'] for row in values)


def report(root, all_worlds):
    catalogue = read(root / 'area-catalogue.json')
    inventory = read(root / 'coverage-expected.json')
    if catalogue['identity'] != inventory['identity']:
        raise ValueError('World and area catalogues differ in build identity')
    worlds = {int(key): row for key, row in inventory['worlds'].items()}
    targets = {key for key, row in worlds.items() if any(item['type'] in MAP_TYPES for item in row['uiMaps'])}
    targets.update(row['ContinentID'] for row in catalogue['areas'].values() if row['AreaName_lang'] and row['ContinentID'] in worlds)
    terrain = defaultdict(lambda: defaultdict(set))
    scan_errors = {}
    for path in (root / 'area-tiles').glob('*.json'):
        scanned = read(path)
        world = scanned['id']
        if scanned['errors']:
            scan_errors[world] = scanned['errors']
        for tile, areas in scanned['tiles'].items():
            for area in areas:
                terrain[area][world].add(tile)
            if areas:
                targets.add(world)
    associated_worlds = set(targets)
    if all_worlds:
        targets.update(worlds)

    packed = {}
    interiors = defaultdict(set)
    world_report = {}
    for world in sorted(targets):
        world_data = worlds[world]
        result_path = root / 'results' / f'{world}.json'
        result = read(result_path) if result_path.is_file() else {}
        phase = 'running' if (root / 'active' / f'{world}.json').is_file() else result.get('status', 'pending')
        if world_data['status'] != 'ready':
            phase = world_data['status']
        packed_tiles = 0
        if result.get('pack'):
            try:
                observed = packed_observation(root, result)
                packed[world] = set(observed['tiles'])
                packed_tiles = len(packed[world])
                for area in observed['interiors']:
                    interiors[int(area)].add(world)
            except (OSError, ValueError) as error:
                if phase != 'running':
                    phase = 'verificationFailed'
                world_report[world] = {'verificationError': str(error)}
        world_report.setdefault(world, {}).update(status=phase, name=world_data['name'], packedTiles=packed_tiles,
                                                   zoneOrAreaReference=world in associated_worlds,
                                                   tileErrors=result.get('errors', {}), sourceError=world_data.get('error'))

    area_report = {}
    all_area_ids = {int(key) for key in catalogue['areas']} | terrain.keys()
    interiors_by_parent = defaultdict(set)
    for key, worlds_with_interior in interiors.items():
        record = catalogue['wmos'].get(str(key))
        if record:
            interiors_by_parent[record['AreaTableID']].update(worlds_with_interior)
    for area in sorted(all_area_ids):
        occurrences = terrain.get(area, {})
        missing = {world: sorted(tiles - packed.get(world, set())) for world, tiles in occurrences.items()}
        missing = {world: tiles for world, tiles in missing.items() if tiles}
        status = 'allObservedTilesPacked' if occurrences and not missing else 'missingObservedTiles'
        if not occurrences:
            status = 'interiorObserved' if area in interiors_by_parent else 'noObservedSurface'
        record = catalogue['areas'].get(str(area), {})
        area_report[area] = {'status': status, 'name': record.get('AreaName_lang'), 'parent': record.get('ParentAreaID'),
                             'declaredWorld': record.get('ContinentID'),
                             'observations': {world: len(tiles) for world, tiles in occurrences.items()},
                             'missingTiles': missing, 'packedInteriorWorlds': sorted(interiors_by_parent.get(area, ())) }

    map_report = {}
    for key, row in catalogue['uiMaps'].items():
        if row['type'] not in MAP_TYPES:
            continue
        assignments = []
        for world, area in row['assignments']:
            assigned_tiles = terrain.get(area, {}).get(world, set())
            missing = sorted(assigned_tiles - packed.get(world, set()))
            status = world_report.get(world, {}).get('status', 'noTerrainAssignment')
            if assigned_tiles:
                status = 'missingObservedTiles' if missing else 'allObservedTilesPacked'
            assignments.append({'world': world, 'area': area, 'status': status, 'observedTiles': len(assigned_tiles),
                                'missingTiles': missing})
        status = 'noTerrainAssignment'
        cases = {item['status'] for item in assignments if item['world'] >= 0}
        if cases and cases <= {'complete', 'allObservedTilesPacked'}:
            status = 'allAssignmentsPacked'
        elif cases - {'noTerrainAssignment'}:
            status = 'partialOrPending'
        map_report[key] = {**row, 'status': status, 'assignments': assignments}

    interior_report = {}
    for key, row in catalogue['wmos'].items():
        observed = sorted(interiors.get(int(key), ()))
        if observed or row['AreaName_lang'] and row['AreaName_lang'].casefold() != 'default':
            interior_report[key] = {'name': row['AreaName_lang'], 'parent': row['AreaTableID'],
                                    'status': 'observedInPack' if observed else 'noObservedSurface', 'worlds': observed}

    return {'updatedAt': datetime.now(timezone.utc).isoformat(), 'identity': catalogue['identity'],
            'sources': catalogue['sources'], 'worldCounts': status_counts(world_report.values()),
            'uiMapCounts': status_counts(map_report.values()), 'areaCounts': status_counts(area_report.values()),
            'interiorCounts': status_counts(interior_report.values()),
            'packedTiles': sum(item['packedTiles'] for item in world_report.values()),
            'worlds': world_report, 'uiMaps': map_report, 'areas': area_report,
            'interiors': interior_report, 'areaScanErrors': scan_errors}
