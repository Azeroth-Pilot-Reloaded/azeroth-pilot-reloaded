"""Export the route browser's textures for WoW, without network access.

Requires Pillow and resvg-py. MDI sources and their license are vendored beside
the textures, as in APR-Route-Recorder; no SVG renderer is needed in game.
"""
from io import BytesIO
import json
from pathlib import Path

from PIL import Image
from resvg_py import svg_to_bytes

ASSETS = Path(__file__).resolve().parents[1] / "APR-Core" / "assets"


def export_chrome(destination):
    """Vector corners and Blizzard's eight-strip edge atlas; no stretching of corner radii.

    Backdrop.lua samples the inner 7/8 of each tile (four pixels of padding here).
    Horizontal edges use rotated vertical strips. Stroke width stays one UI unit
    for each exported radius, rather than growing when a window gets larger.
    """
    def export(name, elements, width, height):
        svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}">{elements}</svg>'
        png = svg_to_bytes(svg_string=svg, width=width * 4, height=height * 4)
        Image.open(BytesIO(png)).convert("RGBA").resize((width, height), Image.Resampling.LANCZOS).save(
            destination / name, compression=None)

    export("rounded-fill.tga", '<path fill="white" d="M64 0 A64 64 0 0 0 0 64 H64 Z"/>', 64, 64)
    for radius in (4, 6, 8):
        scale = 56 / radius
        parts = []
        # Left, right, top, bottom. WoW rotates the last two strips through their UVs.
        for index, x in enumerate((0.5, radius - 0.5, 0.5, radius - 0.5)):
            parts.append(f'<g transform="translate({index * 64 + 4},0) scale({scale})">'
                         f'<path d="M{x} 0 V{64 / scale}" stroke="white" fill="none"/></g>')
        r = radius - 0.5
        paths = (
            f'M0.5 {radius} A{r} {r} 0 0 1 {radius} 0.5',
            f'M0 0.5 A{r} {r} 0 0 1 {r} {radius}',
            f'M{radius} {r} A{r} {r} 0 0 1 0.5 0',
            f'M{r} 0 A{r} {r} 0 0 1 0 {r}',
        )
        for index, path in enumerate(paths, 4):
            parts.append(f'<g transform="translate({index * 64 + 4},4) scale({scale})">'
                         f'<path d="{path}" stroke="white" fill="none"/></g>')
        export(f"rounded-border-{radius}.tga", ''.join(parts), 512, 64)


def main():
    destination = ASSETS / "ui"
    manifest = json.loads((destination / "mdi" / "manifest.json").read_text(encoding="utf-8"))
    for name, source in manifest["icons"].items():
        svg = (destination / "mdi" / (source + ".svg")).read_text(encoding="utf-8")
        png = svg_to_bytes(svg_string=svg, width=256, height=256,
                           style_sheet="path { fill: #ffffff; }")
        icon = Image.open(BytesIO(png)).convert("RGBA").resize((64, 64), Image.Resampling.LANCZOS)
        icon.save(destination / (name + ".tga"), compression=None)
        print(f"{name}.tga <- {source}.svg")

    # The supplied master includes the entire metal ring and its transparent margin.
    # Keep the original in tools (excluded from packages), and load only this small RGBA export in WoW.
    logo = Image.open(ASSETS.parents[1] / "tools" / "artwork" / "APR-logo.png").convert("RGBA")
    logo.resize((256, 256), Image.Resampling.LANCZOS).save(destination / "logo.tga", compression=None)
    export_chrome(destination)


if __name__ == "__main__":
    main()
