#!/usr/bin/env python3
import argparse
import os
import re
import socket
from enum import Enum
from typing import Dict, List, Set, Literal

# Type aliases for clarity
TestProd = Literal['wowt', 'wowxptr', 'wow_classic_ptr', 'wow_classic_era_ptr']
BetaProd = Literal['wow_beta', 'wow_classic_beta']
FullProd = Literal['wow', 'wow_classic', 'wow_classic_era']
Product = TestProd | BetaProd | FullProd
VersionDict = Dict[Product, str]

# ANSI color codes for terminal output
RESET = "\033[0m"
BOLD = "\033[1m"
LIGHT_BLUE = "\033[94m"
GREEN = "\033[32m"
YELLOW = "\033[33m"

# Default line ending (can be adapted later)
LINE_END = "\n"

class GameFlavor(Enum):
    WOW = 'wow'
    WOW_CLASSIC = 'wow_classic'
    WOW_CLASSIC_ERA = 'wow_classic_era'

def parse_game_flavor(value: str) -> GameFlavor:
    """Parse and validate game flavor input."""
    mapping = {
        'retail': GameFlavor.WOW,
        'mainline': GameFlavor.WOW,
        'classic': GameFlavor.WOW_CLASSIC,
        'cata': GameFlavor.WOW_CLASSIC,
        'classic_era': GameFlavor.WOW_CLASSIC_ERA,
        'vanilla': GameFlavor.WOW_CLASSIC_ERA
    }
    lower = value.lower()
    if lower not in mapping:
        raise argparse.ArgumentTypeError(
            f"Invalid flavor: {value}. Allowed values are: {', '.join(mapping.keys())}"
        )
    return mapping[lower]

def get_product_version(prod: Product, cache: VersionDict) -> str:
    """
    Retrieve version string for a given product from battle.net or return cached value.
    The version is formatted as major + zero-padded minor and patch (e.g. 102030).
    """
    if prod in cache:
        return cache[prod]

    host = 'us.version.battle.net'
    port = 1119
    request_line = f"v1/products/{prod}/versions\n"
    try:
        with socket.create_connection((host, port), timeout=10) as sock:
            sock.sendall(request_line.encode())
            data_chunks = []
            while True:
                data = sock.recv(4096)
                if not data:
                    break
                data_chunks.append(data.decode())
            response = ''.join(data_chunks)
    except (socket.timeout, socket.error) as err:
        print(f"Error communicating with server: {err}")
        return ""

    version_str = ""
    for line in response.splitlines():
        if line.startswith('us'):
            parts = line.split('|')
            if len(parts) > 5:
                version_str = parts[5]
            break

    # Remove revision and split version parts
    version_str = version_str.rsplit('.', 1)[0]
    try:
        major, minor, patch = version_str.split('.')
    except ValueError:
        major, minor, patch = "0", "0", "0"
    # Ensure minor and patch are two digits
    version_formatted = f"{major}{minor.zfill(2)}{patch.zfill(2)}"
    cache[prod] = version_formatted
    return version_formatted

def is_library_toc(file_path: str) -> bool:
    """
    Determine if the .toc file is part of a library (e.g. resides in 'lib', 'libs', 'library', 'libraries').
    """
    parts = os.path.normpath(file_path).split(os.sep)
    return any(part.lower() in ['lib', 'libs', 'library', 'libraries'] for part in parts)

def merge_versions(existing: str, new_set: Set[str]) -> str:
    """
    Merge versions from the existing line with the new set.
    If the new interfaces indicate a higher version group, then older versions are removed.
    Returns a comma-separated sorted string.
    """
    current = {v.strip() for v in existing.split(',')} if existing else set()
    combined = current.union(new_set)
    # Cleaning mechanism: keep only versions matching the new highest interface group.
    if new_set:
        max_new = max(new_set, key=lambda v: int(v))
        prefix = max_new[:3]
        combined = {v for v in combined if v.startswith(prefix)}
    sorted_versions = sorted(combined, key=lambda v: int(v))
    return ', '.join(sorted_versions)

def update_interface_line(content: str, line_prefix: str, new_versions: Set[str]) -> (str, bool):
    """
    Update a line starting with the given prefix by merging its version numbers
    with new_versions. Returns updated content and a flag if a substitution was made.
    """
    pattern = re.compile(rf'^({re.escape(line_prefix)}):\s*(.*)$', re.MULTILINE)
    updated = False

    def replacer(match):
        nonlocal updated
        prefix = match.group(1)
        current_versions = match.group(2)
        merged = merge_versions(current_versions, new_versions)
        updated = True
        return f"{prefix}: {merged}"

    new_content, count = pattern.subn(replacer, content)
    return new_content, updated if count > 0 else False

def update_toc_file(file_path: str, prod: FullProd, multi: bool,
                    include_beta: bool, include_test: bool,
                    cache: VersionDict, files_updated: List[str]) -> None:
    """
    Update the interface version lines in a .toc file based on the product.
    The function reads the file, calculates new interface versions (merging with any existing ones)
    and writes back only if there is an actual change.
    """
    print(f"{LIGHT_BLUE}Processing {BOLD}{file_path}{RESET}{LIGHT_BLUE} for product {prod}{RESET}", end=' ')

    try:
        with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
            original = f.read()
    except Exception as ex:
        print(f"Error reading file: {ex}")
        return

    # Normalize line breaks for processing
    content = original.replace('\r\n', '\n').replace('\r', '\n')
    new_versions: Set[str] = set()

    base_ver = get_product_version(prod, cache)
    if base_ver:
        new_versions.add(base_ver)

    # Append beta version if required and available
    if include_beta:
        if prod == 'wow':
            beta_ver = get_product_version('wow_beta', cache)
            if beta_ver and beta_ver > base_ver:
                new_versions.add(beta_ver)
        elif prod == 'wow_classic':
            beta_ver = get_product_version('wow_classic_beta', cache)
            if beta_ver and beta_ver > base_ver:
                new_versions.add(beta_ver)

    # Append test (PTR) version if required and available
    if include_test:
        if prod == 'wow':
            for test_prod in ['wowt', 'wowxptr']:
                test_ver = get_product_version(test_prod, cache)
                if test_ver and test_ver > base_ver:
                    new_versions.add(test_ver)
        elif prod == 'wow_classic':
            test_ver = get_product_version('wow_classic_ptr', cache)
            if test_ver and test_ver > base_ver:
                new_versions.add(test_ver)
        elif prod == 'wow_classic_era':
            test_ver = get_product_version('wow_classic_era_ptr', cache)
            if test_ver and test_ver > base_ver:
                new_versions.add(test_ver)

    updated_content = content
    changed = False

    # Choose which interface line(s) to update based on multi flag and product type
    if not multi:
        updated_content, sub_changed = update_interface_line(updated_content, "## Interface", new_versions)
        changed = changed or sub_changed
    else:
        if prod == 'wow_classic':
            for prefix in ["## Interface-Cata", "## Interface-Classic"]:
                updated_content, sub_changed = update_interface_line(updated_content, prefix, new_versions)
                changed = changed or sub_changed
        elif prod == 'wow_classic_era':
            updated_content, sub_changed = update_interface_line(updated_content, "## Interface-Vanilla", new_versions)
            changed = changed or sub_changed
        else:
            # For 'wow' in multi mode, update generic interface
            updated_content, sub_changed = update_interface_line(updated_content, "## Interface", new_versions)
            changed = changed or sub_changed

    # Write the file only if changes were made
    if changed and updated_content != content:
        final_le = "\n" if "\r\n" not in original else "\r\n"
        with open(file_path, 'w', encoding='utf-8', newline='') as f:
            f.write(updated_content.replace("\n", final_le))
        files_updated.append(file_path)
        print(f"{GREEN}Updated{RESET}")
    else:
        print(f"{YELLOW}No change{RESET}")

def main():
    parser = argparse.ArgumentParser(description="Update WoW Interface Versions in .toc files")
    parser.add_argument('-b', '--beta', action='store_true', help="Include beta versions")
    parser.add_argument('-p', '--ptr', action='store_true', help="Include test (PTR) versions")
    parser.add_argument('-f', '--flavor', type=parse_game_flavor, default=GameFlavor.WOW,
                        help="Game flavor (retail, mainline, classic, cata, classic_era, vanilla)")
    args = parser.parse_args()

    include_beta = args.beta
    include_test = args.ptr
    flavor = args.flavor.value

    cached_versions: VersionDict = {}
    files_modified: List[str] = []

    # Pattern to detect TOC files with specific naming convention (e.g. Mainline, Classic, etc.)
    naming_pattern = re.compile(r'[-_](Mainline|Classic|Cata|Vanilla)\.toc$')

    # Walk recursively through the directory
    for root, _, files in os.walk('.'):
        for fname in files:
            if fname.endswith('.toc'):
                full_path = os.path.join(root, fname)
                # Skip files in library folders
                if is_library_toc(full_path):
                    continue

                # Determine update strategy based on file naming
                if not naming_pattern.search(full_path):
                    update_toc_file(full_path, flavor, False, include_beta, include_test, cached_versions, files_modified)
                    update_toc_file(full_path, 'wow_classic', True, include_beta, include_test, cached_versions, files_modified)
                    update_toc_file(full_path, 'wow_classic_era', True, include_beta, include_test, cached_versions, files_modified)
                else:
                    if 'Mainline' in full_path:
                        update_toc_file(full_path, 'wow', False, include_beta, include_test, cached_versions, files_modified)
                    elif 'Classic' in full_path or 'Cata' in full_path:
                        update_toc_file(full_path, 'wow_classic', False, include_beta, include_test, cached_versions, files_modified)
                    elif 'Vanilla' in full_path:
                        update_toc_file(full_path, 'wow_classic_era', False, include_beta, include_test, cached_versions, files_modified)

    if files_modified:
        print(f"\n{GREEN}Modified files:")
        for f in files_modified:
            print(f"{GREEN}{f}{RESET}")
    else:
        print(f"\n{YELLOW}No files were modified.{RESET}")

if __name__ == '__main__':
    main()
