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

    # Export the existing APR artwork without DXT compression of its small mip levels.
    # Filtering a 128px image keeps the 61px portrait crisp at ordinary UI scales.
    logo = Image.open(ASSETS / "APR_logo.blp").convert("RGBA")
    logo.resize((128, 128), Image.Resampling.LANCZOS).save(destination / "logo.tga", compression=None)


if __name__ == "__main__":
    main()
