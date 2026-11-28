"""Read and pack one Retail map for the batch generator."""

import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
from threading import get_ident
from time import sleep


def read(path):
    return json.loads(path.read_bytes())


def write(path, document):
    pending = path.with_suffix(f'.{os.getpid()}.{get_ident()}.tmp')
    pending.write_text(json.dumps(document, ensure_ascii=False, indent=2), encoding='utf-8')
    pending.replace(path)


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def run(args, logfile):
    with logfile.open('ab') as stream:
        subprocess.run([str(arg) for arg in args], stdout=stream, stderr=subprocess.STDOUT, check=True)


def tile_errors(path):
    with path.open('rb') as stream:
        stream.seek(-min(path.stat().st_size, 65536), os.SEEK_END)
        trailer = stream.read()
    separator = b'],"complete":'
    offset = trailer.rfind(separator)
    if offset == -1:
        status = read(path)
    else:
        status = json.loads(b'{"complete":' + trailer[offset + len(separator):])
    if status['complete'] and not status['errors']:
        return []
    return status['errors'] or ['Incomplete tile geometry']


def extract(args, world_id, destination, logfile, extra=()):
    command = [args.bin / 'apr-terrain-reader.exe', '--wow', args.wow, '--defs', args.defs,
               '--product', 'wow', '--continents', world_id, '--out', destination, *extra]
    for attempt in range(4):
        try:
            run(command, logfile)
            return
        except subprocess.CalledProcessError:
            with logfile.open('rb') as log:
                log.seek(-min(logfile.stat().st_size, 8192), os.SEEK_END)
                can_retry = b'cannot open local product' in log.read()
            if attempt == 3 or not can_retry or any(destination.iterdir()):
                raise
            sleep(2 ** (attempt + 1) + (int(world_id) % 10) / 10)


def extract_without_textures(world_id, candidates, geometry, args, logfile, identity):
    destination = geometry / 'geometry-only'
    destination.mkdir()
    verified = {}
    for start in range(0, len(candidates), 200):
        requested = candidates[start:start + 200]
        output = destination / str(start)
        output.mkdir()
        extract(args, world_id, output, logfile, ('--geometry-only', '--tile', ','.join(requested)))
        index = read(output / 'index.json')
        if (index['product'], index['build']) != (identity['product'], identity['build']):
            raise ValueError('Installed client build changed during tile retry')
        for tile in index['maps'][0]['tiles']:
            key = f'{tile["x"]}_{tile["y"]}'
            path = output / tile['file']
            if key in requested and not tile_errors(path):
                verified[key] = {**tile, 'file': (path.relative_to(geometry)).as_posix()}
    return verified


def generate_pack(command, logfile, tiles, index, index_path, errors, world_id, previous):
    while tiles:
        start = logfile.stat().st_size if logfile.is_file() else 0
        try:
            run(command, logfile)
            return
        except subprocess.CalledProcessError:
            with logfile.open(encoding='utf-8', errors='replace') as output:
                output.seek(start)
                status = output.read()
            match = re.search(rf'apr-terrain: map {world_id} tile \((\d+), (\d+)\): ((?:surface|graph) fields: .+)', status)
            if not match:
                match = re.search(r'apr-terrain: nav(?: v\d+)? tile \((\d+), (\d+)\) (column .+link capacity \d+)', status)
            if not match:
                raise
            column, row = map(int, match.group(1, 2))
            remaining = [tile for tile in tiles if (tile['x'], tile['y']) != (column, row)]
            if len(remaining) == len(tiles) or not remaining:
                raise
            tile_id = f'{column}_{row}'
            if previous and tile_id not in previous['errors']:
                raise ValueError(f'Retry would drop previously packed tile {tile_id}')
            errors[tile_id] = [f'generation: {match[3]}']
            tiles[:] = remaining
            index['selection'] = 'tiles'
            write(index_path, index)


def build_world(world, args, root, identity, source_hash, allowlist, roads):
    world_id = str(world['id'])
    result_path = root / 'results' / f'{world_id}.json'
    previous = None
    if result_path.is_file():
        previous = read(result_path)
        if not args.retry or previous['status'] == 'complete':
            return previous
        if not previous.get('pack'):
            previous = None
    logfile = args.logs / f'{world_id}.log'
    pack = root / 'packs' / world_id
    result = {'id': world['id'], 'name': world['name'], 'kind': world['kind'],
              'status': 'failed', 'build': identity['build'], 'errors': {}}
    write(root / 'active' / f'{world_id}.json', {'id': world['id'], 'name': world['name'], 'stage': 'extraction'})
    try:
        if shutil.disk_usage(root).free < 35 * 1024**3:
            raise ValueError('Less than 35 GiB available for temporary geometry')
        with tempfile.TemporaryDirectory(prefix=f'world-{world_id}-', dir=root / 'work') as temporary:
            geometry = Path(temporary)
            if geometry.resolve().parent != (root / 'work').resolve():
                raise ValueError('Temporary directory outside generation workspace')
            extract(args, world_id, geometry, logfile)
            index_path = geometry / 'index.json'
            index = read(index_path)
            metadata = read(geometry / index['metadata'])
            if (index['product'], index['build'], metadata['buildKey']) != (identity['product'], identity['build'], identity['buildKey']):
                raise ValueError('Installed client build changed')
            tiles = index['maps'][0]['tiles']
            expected = set(world.get('tiles', ())) if world['kind'] == 'ADT' else None
            expected = expected if expected is not None else {f'{tile["x"]}_{tile["y"]}' for tile in tiles}
            result['expectedTiles'] = len(expected)
            observed = set()
            complete = []
            for tile in tiles:
                key = f'{tile["x"]}_{tile["y"]}'
                observed.add(key)
                errors = tile_errors(geometry / tile['file'])
                if errors:
                    result['errors'][key] = errors
                else:
                    complete.append(tile)
            if observed != expected:
                raise ValueError(f'Reader inventory disagrees with WDT: missing={sorted(expected-observed)}, extra={sorted(observed-expected)}')
            texture_failures = [key for key, errors in result['errors'].items()
                                if all(error.startswith('textures ') for error in errors)]
            if texture_failures:
                recovered = extract_without_textures(world_id, texture_failures, geometry, args, logfile, identity)
                if recovered:
                    result['tilesWithoutRoadTextures'] = {key: result['errors'].pop(key) for key in recovered}
                    complete.extend(recovered.values())
            result['readableTiles'] = len(complete)
            if not complete:
                raise ValueError('No tile with complete geometry')
            if previous and (len(complete) < previous['packedTiles'] or result['errors'].keys() - previous['errors'].keys()):
                raise ValueError('Retry would drop previously packed terrain')
            index['maps'][0]['tiles'] = complete
            if len(complete) != len(tiles):
                index['selection'] = 'tiles'
            if result['errors'] or result.get('tilesWithoutRoadTextures'):
                complete.sort(key=lambda tile: (tile['y'], tile['x']))
                write(index_path, index)
            write(root / 'active' / f'{world_id}.json', {'id': world['id'], 'name': world['name'],
                  'stage': 'generation', 'expectedTiles': len(expected), 'readableTiles': len(complete)})
            generate_pack([args.bin / 'apr-terrain.exe', 'generate', '--geometry', geometry, '--product', 'wow',
                 '--build', identity['build'], '--continents', world_id, '--listfile', roads, '--allowlist', allowlist,
                 '--threads', args.threads, '--cells', args.cells, '--min-region', 1, '--graph-stretch-percent', 2,
                 *(['--wide-heights'] if args.wide_heights else []),
                 *(['--wide-layers'] if args.wide_layers else []),
                 '--revision', 20261123, '--date', '2026-11-23', '--out', pack], logfile, complete, index,
                 index_path, result['errors'], world_id, previous)
            run([args.bin / 'apr-terrain.exe', 'check', '--out', pack], logfile)
            manifest = read(pack / 'PACK.json')
            if (manifest['profile'], manifest['grid']['build'], set(manifest['maps'])) != ('retail', identity['build'], {world_id}):
                raise ValueError('Pack identity differs from expected world and build')
            stats = manifest['maps'][world_id]
            if stats['clusters'] != len(complete):
                raise ValueError('Pack tile count differs from the geometry inventory')
            result.update(status='complete' if len(expected) == len(complete) else 'partial',
                          packedTiles=len(complete), pack=str(pack.relative_to(root)),
                          packSha256=digest(pack / 'PACK.json'), geometryIndexSha256=digest(index_path),
                          listfileSha256=source_hash, cells=manifest['cells'],
                          heightDigits=manifest.get('heightDigits', 2), gridVersion=manifest['grid']['version'],
                          statistics=stats)
            write(pack / 'Coverage.json', result)
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        result['failure'] = str(error)
    finally:
        (root / 'active' / f'{world_id}.json').unlink(missing_ok=True)
    manifest_path = pack / 'PACK.json'
    if (result['status'] == 'failed' and previous and manifest_path.is_file()
            and digest(manifest_path) == previous['packSha256']):
        write(root / 'logs' / f'{world_id}-last-retry.json', result)
        return previous
    write(result_path, result)
    return result
