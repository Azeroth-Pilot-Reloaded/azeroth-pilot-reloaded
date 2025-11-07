#!/usr/bin/env bash
# scripts/package.sh - create a zip suitable for Interface/AddOns/APR
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OUT_DIR="$ROOT_DIR/dist"
mkdir -p "$OUT_DIR"

PKG_NAME="APR-$(date +%Y%m%d%H%M%S).zip"
PKG_PATH="$OUT_DIR/$PKG_NAME"

# Files/dirs to exclude from package
EXCLUDES=( --exclude ".git/*" --exclude ".github/*" --exclude "dist/*" --exclude "node_modules/*" )

echo "Creating package $PKG_PATH"
cd "$ROOT_DIR"
zip -r "$PKG_PATH" . "${EXCLUDES[@]}"

echo "Package created: $PKG_PATH"
