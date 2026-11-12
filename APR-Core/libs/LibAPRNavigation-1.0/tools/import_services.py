"""Compile service facts, never addon code. Run explicitly; tests use temporary inputs.

python APR-Core/libs/LibAPRNavigation-1.0/tools/import_services.py --zygor ../zygor --rxp ../RXPGuides \
    --polestar ../polestar --installed-forever "D:/Jeux/World of Warcraft/_forever_/Interface/AddOns"
"""
import argparse
from collections import Counter
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
PROFESSIONS = {"Alchemy": 171, "Blacksmithing": 164, "Cooking": 185,
               "Enchanting": 333, "Engineering": 202, "First Aid": 129,
               "Fishing": 356, "Herbalism": 182, "Leatherworking": 165,
               "Mining": 186, "Skinning": 393, "Tailoring": 197,
               "Inscription": 773, "Jewelcrafting": 755, "Archaeology": 794}
ROLES = {"Repair": "repair", "Auctioneer": "auction", "Banker": "bank",
         "Stable Master": "stable", "Vendor": "vendor"}
REGIONS = {"Eastern Kingdoms": 0, "Kalimdor": 0, "Outland": 1, "Northrend": 2,
           "Cataclysm": 3, "Pandaria": 4, "Draenor": 5, "Broken Isles": 6,
           "Kul Tiras": 7, "Zandalar": 7, "Shadowlands": 8, "Dragonflight": 9,
           "Dragon Isles": 9, "TWW": 10, "The War Within": 10, "Midnight": 11}


class Compiler:
    def __init__(self):
        self.records = {"forever": {}, "retail": {}}
        self.rejected = Counter()
        self.map_names, self.npc_names = {}, {}

    def read(self, path, identity):
        content = path.read_bytes()
        return content.decode("utf-8-sig")

    def add(self, profile, record, source):
        if not (record.get("mapID", 0) > 0 and 0 <= record["x"] <= 100 and 0 <= record["y"] <= 100):
            self.rejected["invalid_coordinate"] += 1
            return
        if record.get("id") == 0:
            self.rejected["non_service_placeholder"] += 1
            return
        if profile == "retail" and record["service"] in ("class", "weapon", "vendor", "stable"):
            return
        # Same service/identity on the same map at the same observed position.
        # Preserve separate spawns and different factions/restrictions.
        key = (record["service"], record.get("id", 0), record["mapID"],
               round(record["x"], 2), round(record["y"], 2), record.get("faction", "B"),
               record.get("skill", 0), record.get("class", ""), record.get("expansion", -1))
        existing = self.records[profile].setdefault(key, dict(record))
        if not existing.get("name") and record.get("name"):
            existing["name"] = record["name"]
        if record.get("z") is not None:
            existing["z"] = record["z"]

    def zygor(self, root, profile):
        edition = "Forever" if profile == "forever" else "Retail"
        base = root / ("ZygorGuidesViewerForever" if profile == "forever" else "ZygorGuidesViewer")
        identity = f"zygor/{profile}/NPCData.lua"
        text = self.read(base / f"Data-{edition}/NPCData.lua", identity)
        names_path = base / f"Localization-{edition}/NPCs_enUS.lua"
        if names_path.exists():
            names_text = names_path.read_text(encoding="utf-8-sig")
            self.npc_names[profile] = dict((int(npc), name) for npc, name in re.findall(r'\[(\d+)\]\s*=\s*"([^"\n]+)"', names_text))
        category, expansion = None, None
        for raw in text.splitlines():
            match = re.match(r'\s*\["([^"\n]+)"\]\s*=\s*\[\[', raw)
            if match:
                category, expansion = match[1], None
            heading = re.match(r"\s*--\s*([\w ]+?)\s*--\s*$", raw)
            if heading and heading[1].casefold() in {key.casefold(): value for key, value in REGIONS.items()}:
                expansion = {key.casefold(): value for key, value in REGIONS.items()}[heading[1].casefold()]
            service, skill, klass = ROLES.get(category), None, None
            if category and category.startswith("Trainer"):
                skill = PROFESSIONS.get(category[7:])
                service = "trainer" if skill else None
            elif category and category.startswith("Class") and " " not in category:
                service, klass = "class", category[5:].upper()
            line, _, comment = raw.partition("--")
            if not service:
                continue
            match = re.match(r"\s*(\d+)\s*=\s*(.+)", line)
            if not match:
                continue
            parts = match[2].strip().split("|")
            fields = {p[0]: p[1:].strip() for p in parts if p}
            if fields.get("c"):
                self.rejected["zygor_condition_requires_review"] += 1
                continue
            if not all(k in fields for k in ("m", "x", "y")):
                self.rejected["zygor_incomplete"] += 1
                continue
            try:
                record = dict(service=service, id=int(match[1]), mapID=int(fields["m"]),
                              x=float(fields["x"]), y=float(fields["y"]), faction=fields.get("s", "B"))
            except ValueError:
                self.rejected["zygor_unparsed_coordinate"] += 1
                continue
            name = re.search(r"\(([^()]+)\)\s*$", comment)
            if name:
                record["name"] = name[1]
            elif "," in comment:
                candidate_name = comment.rsplit(",", 1)[-1].strip()
                if candidate_name and not re.search(r"\d|/", candidate_name):
                    record["name"] = candidate_name
            if skill:
                record["skill"] = skill
                if profile == "retail":
                    if expansion is None:
                        self.rejected["trainer_extension_requires_review"] += 1
                        continue
                    record["expansion"] = 3 if skill == 794 else expansion
            if klass:
                record["class"] = klass
            self.add(profile, record, identity)
        mailbox = re.search(r"ZGV\._MailboxData\s*=\s*\[\[(.*?)\]\]", text, re.S)
        for line in (mailbox[1].splitlines() if mailbox else []):
            fields = dict(re.findall(r"(?:^|\|)\s*([smxy])([^|\s]+)", line.partition("--")[0]))
            if all(k in fields for k in ("m", "x", "y")):
                self.add(profile, dict(service="mailbox", mapID=int(fields["m"]),
                                       x=float(fields["x"]), y=float(fields["y"]),
                                       faction=fields.get("s", "B")), identity)
        rover = base / f"Libs-{edition}/LibRover-1.0"
        maps = self.read(rover / "data.lua", f"zygor/{profile}/maps")
        map_ids = dict((name, int(mid)) for name, mid in re.findall(r'\["([^"]+)"\]\s*=\s*\{\s*\[0\]\s*=\s*(\d+)', maps))
        self.map_names[profile] = {}
        for name, body in re.findall(r'\["([^"]+)"\]\s*=\s*\{([^}]+)\}', maps):
            for mid in re.findall(r"\[\d+\]\s*=\s*(\d+)", body):
                self.map_names[profile][int(mid)] = name
        identity = f"zygor/{profile}/inns"
        inns = self.read(rover / "data_inns.lua", identity)
        current = None
        for line in inns.splitlines():
            header = re.match(r'''\s*\[['"](.+?)['"]\]\s*=\s*\{''', line)
            if header:
                current = map_ids.get(header[1])
            fields = dict(re.findall(r'(\w+)\s*=\s*("[^"\n]*"|\d+(?:\.\d+)?)', line.partition("--")[0]))
            if current and all(k in fields for k in ("npcid", "x", "y")):
                if "condition" in line or "cond=" in line or "phase=" in line:
                    self.rejected["inn_condition_requires_review"] += 1
                    continue
                self.add(profile, dict(service="inn", id=int(fields["npcid"]), mapID=current,
                                       x=float(fields["x"]), y=float(fields["y"]),
                                       name=fields.get("npc", '""').strip('"'),
                                       faction=fields.get("faction", '"B"').strip('"')), identity)

    def polestar(self, root, installed):
        identity = "polestar/weapon_masters"
        text = self.read(root / "addon/Polestar/Nav/Nearby.lua", identity)
        weapons = {}
        block = text.split("local WEAPON_MASTERS = {", 1)[1].split("\n}", 1)[0]
        for npc, side, numbers in re.findall(r'\[(\d+)\]\s*=\s*\{\s*"([AH])",([^}]+)', block):
            weapons[int(npc)] = (side, [int(v) for v in re.findall(r"\d+", numbers)])
        codex = installed / "Polestar_Codex"
        for path in sorted(codex.glob("*.lua")):
            if not re.match(r"(?:Npcs|Objects)\d+\.lua$", path.name):
                continue
            identity = f"polestar/codex/{path.name}"
            content = self.read(path, identity)
            names = {}
            for kind, quoted_names, quoted_facts in re.findall(r'C.Register\("(npc|object)",\s*("(?:[^"\\]|\\.)*"),\s*("(?:[^"\\]|\\.)*")', content):
                quoted = json.dumps(json.loads(quoted_names) + json.loads(quoted_facts))
                # Decode the string literal as data; no Lua execution.
                for line in json.loads(quoted).splitlines():
                    parts = line.split("\t")
                    if len(parts) < 2 or not parts[0].isdigit():
                        continue
                    npc = int(parts[0])
                    if len(parts) >= 3 and not parts[1]:
                        names[npc] = parts[2]
                        self.npc_names.setdefault("forever", {})[npc] = parts[2]
                    fields, name = parts[1].split(";"), names.get(npc, "")
                    if not parts[1]:
                        continue
                    if kind == "npc":
                        if len(fields) < 8 or fields[4]:  # instanced NPCs
                            continue
                        side, roles, spawns = fields[2] or "B", fields[5].split(","), fields[7:]
                    else:
                        if fields[-1] not in ("m", "mA", "mH", "mAH"):
                            continue
                        side, roles, spawns = fields[-1][1:] or "B", ["mailbox"], fields[2:-1]
                    services = []
                    for role in roles:
                        service = {"banker": "bank", "auctioneer": "auction", "innkeeper": "inn",
                                   "repair": "repair", "vendor": "vendor", "stablemaster": "stable",
                                   "mailbox": "mailbox"}.get(role)
                        if service:
                            services.append(dict(service=service))
                        elif role.startswith("class:"):
                            services.append(dict(service="class", **{"class": role[6:]}))
                        elif role.startswith("trainer:") and role[8:].isdigit():
                            skill = int(role[8:])
                            if skill in PROFESSIONS.values():
                                services.append(dict(service="trainer", skill=skill))
                    if npc in weapons and kind == "npc":
                        services.extend(dict(service="weapon", skill=skill) for skill in weapons[npc][1])
                    heights = []
                    for spawn in spawns:
                        if spawn.startswith("z"):
                            heights = spawn[1:].split(",")
                    point_index = 0
                    for spawn in spawns:
                        values = spawn.split(",")
                        if len(values) < 4 or not values[0].isdigit():
                            continue
                        # Frame e is the current Forever map frame; unknown historic frames need review.
                        if values[1] not in ("", "e"):
                            self.rejected["polestar_map_frame_requires_review"] += 1
                            continue
                        for i in range(2, len(values) - 1, 2):
                            height = heights[point_index] if point_index < len(heights) else ""
                            point_index += 1
                            for service in services:
                                self.add("forever", dict(service, id=npc, object=kind == "object", name=name,
                                                         faction=side, mapID=int(values[0]),
                                                         x=int(values[i]) / 10, y=int(values[i + 1]) / 10,
                                                         **({"z": float(height)} if height else {})), identity)

    def rxp(self, root):
        # RXP's flight DB is deliberately not imported: LibTaxiData owns flights.
        # Inspect guide service declarations for independent coordinate corroboration.
        observed = {}
        for path in sorted(root.rglob("*.lua")):
            if "Guides" not in path.parts:
                continue
            text = path.read_text(encoding="utf-8-sig")
            for block in re.split(r"\n\s*step\b", text):
                ids = re.findall(r"\.(?:vendor|trainer)\s+(\d+)", block)
                goto = re.search(r"\.goto\s+(\d+),(\d+(?:\.\d+)?),(\d+(?:\.\d+)?)", block)
                if goto:
                    for npc in ids:
                        observed[(int(npc), int(goto[1]))] = (float(goto[2]), float(goto[3]), path)
        for profile in self.records.values():
            for record in profile.values():
                found = observed.get((record.get("id"), record["mapID"]))
                if found and abs(record["x"] - found[0]) < 1 and abs(record["y"] - found[1]) < 1:
                    identity = "rxp/" + found[2].relative_to(root).as_posix()
                    self.read(found[2], identity)
                    self.rejected["rxp_corroborated"] += 1

    def write(self, output, corrections):
        for profile, rows in corrections.get("records", {}).items():
            for record in rows:
                self.add(profile, record, "reviewed-corrections")
        counts = {}
        expansions = ["Classic", "The Burning Crusade", "Wrath of the Lich King", "Cataclysm",
                      "Mists of Pandaria", "Warlords of Draenor", "Legion", "Battle for Azeroth",
                      "Shadowlands", "Dragonflight", "The War Within", "Midnight"]
        weapons = {43: "Swords", 55: "Two-Handed Swords", 44: "Axes", 172: "Two-Handed Axes",
                   54: "Maces", 160: "Two-Handed Maces", 229: "Polearms", 136: "Staves", 173: "Daggers",
                   473: "Fist Weapons", 45: "Bows", 226: "Crossbows", 46: "Guns", 176: "Thrown"}
        professions = {v: k for k, v in PROFESSIONS.items()}
        for profile, rows in self.records.items():
            records = sorted(rows.values(), key=lambda r: (r["service"], r.get("skill", 0), r.get("id", 0), r["mapID"], r["x"], r["y"]))
            destination = output / profile / "Services.lua"
            destination.parent.mkdir(parents=True, exist_ok=True)
            lines = ["-- Service locations. Coordinates are percentages on the named map.",
                     'LibStub("LibAPRNavigation-1.0"):RegisterServiceLocations("' + profile + '", {']
            for record in records:
                if not record.get("name"):
                    record["name"] = self.npc_names.get(profile, {}).get(record.get("id"), self.npc_names.get("forever", {}).get(record.get("id"), ""))
                if not record["name"]:
                    record["name"] = "Mailbox" if record["service"] == "mailbox" else record["service"].title()
                record["mapName"] = self.map_names.get(profile, {}).get(record["mapID"], "Unknown map")
                if record.get("skill"):
                    record["skillName"] = (weapons if record["service"] == "weapon" else professions)[record["skill"]]
                if "expansion" in record:
                    record["expansionName"] = expansions[record["expansion"]]
                if "id" in record:
                    record["objectID" if record.pop("object", False) else "npcID"] = record.pop("id")
                fields = []
                for key, value in record.items():
                    literal = json.dumps(value, ensure_ascii=False)
                    if isinstance(value, bool):
                        literal = "true" if value else "false"
                    fields.append(f'{key}={literal}' if key != "class" else f'["class"]={literal}')
                lines.append("    {" + ", ".join(fields) + "},")
            destination.write_text("\n".join(lines + ["}, 1)", ""]), encoding="utf-8")
            counts[profile] = dict(Counter(r["service"] for r in records))
        print(json.dumps({"counts": counts, "review": dict(self.rejected)}, indent=2))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--zygor", type=Path, required=True)
    parser.add_argument("--rxp", type=Path, required=True)
    parser.add_argument("--polestar", type=Path, required=True)
    parser.add_argument("--installed-forever", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=ROOT / "Data")
    args = parser.parse_args()
    compiler = Compiler()
    for profile in ("forever", "retail"):
        compiler.zygor(args.zygor, profile)
    compiler.polestar(args.polestar, args.installed_forever)
    compiler.rxp(args.rxp)
    corrections = json.loads((Path(__file__).with_name("corrections.json")).read_text(encoding="utf-8"))
    compiler.write(args.output, corrections)


if __name__ == "__main__":
    main()
