"""Generate packager-compatible TOCs with the route manifest for each WoW client."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RETAIL_ROUTE_MANIFEST = "Routes/RouteList.xml"
FOREVER_ROUTE_MANIFEST = "Routes/Forever/RouteList.xml"


def build_toc(lines, route_manifest, interface):
    body = [
        line
        for line in lines
        if line.strip() not in {RETAIL_ROUTE_MANIFEST, FOREVER_ROUTE_MANIFEST}
        and not line.startswith("## Interface")
        and not line.startswith("## X-Interface")
    ]
    content = "\n".join([f"## Interface: {interface}", *body])
    return content.rstrip() + "\n\n" + route_manifest + "\n"


def main():
    source = ROOT / "APR.toc"
    lines = source.read_text(encoding="utf-8-sig").splitlines()
    if RETAIL_ROUTE_MANIFEST not in lines:
        raise ValueError(f"{source} must load {RETAIL_ROUTE_MANIFEST}")

    (ROOT / "APR_Mainline.toc").write_text(
        build_toc(lines, RETAIL_ROUTE_MANIFEST, "110207, 120000, 120001, 120005, 120007, 120100, 120105"),
        encoding="utf-8",
    )
    (ROOT / "APR_Camelot.toc").write_text(
        build_toc(lines, FOREVER_ROUTE_MANIFEST, "16001"),
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
