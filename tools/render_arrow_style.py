"""Pack APR's original arrow artwork into the existing navigation atlas layout.

The PNG is the unmodified imagegen output. This build step only rotates, resamples
and packs it: 108 counterclockwise headings, projected to the same 4:3 cells as
Arrow.blp. The doubled resolution keeps its existing normalized UV coordinates.
Requires Pillow; no image generator or network is needed to rebuild the atlas.
"""
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools/artwork/Arrow-APR.png"
DESTINATION = ROOT / "APR-Core/assets/Arrow-APR.tga"


def build():
    source = Image.open(SOURCE).convert("RGBA")
    if source.width != source.height or source.getextrema()[3][0] != 0:
        raise ValueError("The source must be square with a transparent background")
    source = source.resize((448, 448), Image.Resampling.LANCZOS)
    atlas = Image.new("RGBA", (1024, 1024))
    for heading in range(108):
        # Cell 0 points up; cell 27 left, 54 down and 81 right, matching Arrow.blp.
        cell = source.rotate(heading * 360 / 108, Image.Resampling.BICUBIC)
        cell = cell.resize((112, 84), Image.Resampling.LANCZOS)
        bounds = cell.getchannel("A").point(lambda alpha: 255 if alpha > 8 else 0).getbbox()
        if not bounds or bounds[0] < 1 or bounds[1] < 1 or bounds[2] > 111 or bounds[3] > 83:
            raise ValueError(f"Arrow clips at heading {heading}")
        atlas.paste(cell, ((heading % 9) * 112, (heading // 9) * 84))
    # Uncompressed 32-bit TGA is supported directly by the game client.
    atlas.save(DESTINATION, compression=None)
    print(DESTINATION)


if __name__ == "__main__":
    build()
