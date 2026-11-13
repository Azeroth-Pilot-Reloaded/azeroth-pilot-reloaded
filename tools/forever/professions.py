"""Explicit profession conversion; never edits manifests/locales.

Run from the repository root: python tools/forever/professions.py --source SOURCE
Uses the compiled source catalog for Forever recipe data and trainer coordinates,
and the authored locale tables plus localized name chunks for readable APR text.
"""
from pathlib import Path
import argparse
import hashlib
import json
import re
from urllib.parse import unquote

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[2]

def lua(value):
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, bool):
        return str(value).lower()
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, (list, tuple)):
        return "{ " + ", ".join(lua(v) for v in value) + " }"
    return "{ " + ", ".join((k if isinstance(k, str) and re.fullmatch(r"[A-Za-z_]\w*", k) else "[" + lua(k) + "]") + " = " + lua(v) for k, v in value.items()) + " }"


def plain(value):
    if hasattr(value, "items"):
        values = {k: plain(v) for k, v in value.items()}
        return [values[i] for i in range(1, len(values) + 1)] if values and set(values) == set(range(1, len(values) + 1)) else values
    return value

DEST = ROOT / "Routes/Forever/Professions"
# Native rank spell identities, shared with Classic; recipes below come from
# Forever, never from an Era recipe itinerary.
RANKS = {
    171: (2259, 3101, 3464, 11611), 164: (2018, 3100, 3538, 9785),
    185: (2550, 3102, 3413, 18260), 333: (7411, 7412, 7413, 13920),
    202: (4036, 4037, 4038, 12656), 129: (3273, 3274, 7924, 10846),
    356: (7620, 7731, 7732, 18248), 182: (2366, 2368, 3570, 11993),
    165: (2108, 3104, 3811, 10662), 186: (2575, 2576, 3564, 10248),
    393: (8613, 8617, 8618, 10768), 197: (3908, 3909, 3910, 12180),
}
LOCALES = ("enUS", "deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW")
SPECIALIZATIONS = {
    "blacksmithing": "200 / 40\n{npc:5164} / {npc:11177}: {item:7937} ×4 + {item:7936} ×2 + {item:7935} ×1\n{npc:11146} / {npc:11178}: {item:3853} ×4 + {item:3855} ×4 + {item:7941} ×2 + {item:7945} ×2",
    "engineering": "200 / 30\n{npc:7944} / {npc:7406}: {item:10559} ×6 + {item:4407} ×1 + {item:4392} ×2\n{npc:8126}: {item:4394} ×20 + {item:10507} ×20 + {item:4384} ×5",
    "leatherworking": "225 / 40\n{npc:7866} / {npc:7867}: {item:8203} ×2 + {item:8204} ×2 + {item:8165} ×10\n{npc:7868} / {npc:7869}: {item:7077} ×2 + {item:7079} ×2 + {item:7075} ×2 + {item:7081} ×2\n235: {npc:7852} / {npc:7854} → {npc:7870} / {npc:7871}: {item:8211} ×1 + {item:8214} ×1\n{item:279941}",
}
SPECIALIZATION_TEXT = dict(zip(LOCALES, (
    "Optional: choose one specialization; none is required for skill 300. Requirements below: profession skill / character level, then trainers and items. Complete the prerequisite quests and learn any required recipes yourself.",
    "Optional: Wählt eine Spezialisierung; für Fertigkeit 300 ist keine erforderlich. Unten: Berufsfertigkeit / Charakterstufe, dann Lehrer und Gegenstände. Erledigt die vorausgesetzten Quests und lernt benötigte Rezepte selbst.",
    "Opcional: elige una especialización; ninguna es necesaria para llegar a 300. Abajo: habilidad de profesión / nivel del personaje, instructores y objetos. Completa las misiones previas y aprende las recetas necesarias.",
    "Opcional: elige una especialización; ninguna es necesaria para llegar a 300. Abajo: habilidad de profesión / nivel del personaje, instructores y objetos. Completa las misiones previas y aprende las recetas necesarias.",
    "Facultatif : choisissez une seule spécialisation ; aucune n'est requise pour atteindre 300. Ci-dessous : compétence / niveau du personnage, puis maîtres et composants. Terminez les quêtes préalables et apprenez les recettes nécessaires.",
    "Facoltativo: scegli una sola specializzazione; nessuna è necessaria per arrivare a 300. Sotto: abilità professionale / livello del personaggio, poi istruttori e oggetti. Completa le missioni preliminari e impara le ricette necessarie.",
    "선택 사항: 전문화는 하나만 선택하며, 숙련도 300에는 필요하지 않습니다. 아래는 전문 기술 숙련도 / 캐릭터 레벨, 상급자와 재료입니다. 선행 퀘스트를 완료하고 필요한 제조법을 직접 배우세요.",
    "Opcional: escolha uma especialização; nenhuma é necessária para chegar a 300. Abaixo: perícia da profissão / nível do personagem, instrutores e itens. Complete as missões prévias e aprenda as receitas necessárias.",
    "Необязательно: выберите одну специализацию; для навыка 300 она не нужна. Ниже: навык профессии / уровень персонажа, затем учителя и предметы. Выполните предварительные задания и изучите нужные рецепты.",
    "可选：只能选择一个专精，达到技能300无需专精。下列内容为专业技能/角色等级，以及训练师和所需物品。请先完成前置任务并自行学习所需配方。",
    "可選：只能選擇一個專精，達到技能300無需專精。下列內容為專業技能/角色等級，以及訓練師和所需物品。請先完成前置任務並自行學習所需配方。",
)))


def read_guides(source):
    runtime = LuaRuntime(register_eval=False, register_builtins=False)
    runtime.execute("SourceRegistry = { RegisterGuide = function(g) captured = g end }")
    catalogs = list((source / "addon").glob("*/Guides.lua"))
    content = next(p.read_text(encoding="utf-8-sig") for p in catalogs if '-- Source: forever/professions/' in p.read_text(encoding="utf-8-sig"))
    guides = {}
    for path in sorted((source / "guides/forever/professions").glob("*.guide")):
        marker = "-- Source: forever/professions/" + path.name + "\n"
        block = content.split(marker, 1)[1].split("\n-- Source:", 1)[0]
        block = re.sub(r'\b\w+\.RegisterGuide\(', 'SourceRegistry.RegisterGuide(', block)
        runtime.execute(block)
        guide = plain(runtime.globals().captured)
        assert guide["id"] == "forever/professions/" + path.stem
        assert len(re.findall(r"(?m)^step ", path.read_text(encoding="utf-8"))) == len(guide["steps"])
        guides[path.stem] = guide
    return guides


def read_names(path):
    names = {}
    if path.exists():
        for kind, chunk in re.findall(r'R\("(\w+)", \d+, \d+, \[\[(.*?)\]\]\)', path.read_text(encoding="utf-8"), re.S):
            for line in chunk.strip().splitlines():
                ident, value = line.split("\t", 1)
                names[kind + ":" + ident] = unquote(value)
    return names


class Texts:
    def __init__(self, source, guides):
        self.source = source
        self.output = {loc: {} for loc in LOCALES}
        self.names = {loc: read_names(next((source / "addon").glob(f"*_{loc}/Names.lua"), source / "missing")) for loc in LOCALES}
        self.names["itIT"].update({"skill:" + str(ident): name for ident, name in zip(RANKS, (
            "Alchimia", "Forgiatura", "Cucina", "Incantamento", "Ingegneria", "Primo Soccorso", "Pesca", "Erbalismo", "Conciatura", "Estrazione", "Scuoiatura", "Sartoria"))})
        self.translations = {}
        self.note_values = set()
        export = ROOT / "tools/localization/forever-professions-translations.json"
        self.reviewed = json.loads(export.read_text(encoding="utf-8")) if export.exists() else {}
        runtime = LuaRuntime(register_eval=False, register_builtins=False)
        for slug in guides:
            for step in guides[slug]["steps"]:
                if step.get("note"):
                    self.note_values.add((slug, step["note"]))
            for loc in LOCALES:
                path = source / f"guides/locales/{loc}/forever/professions/{slug}.lua"
                self.translations[slug, loc] = plain(runtime.execute(path.read_text(encoding="utf-8"))) if path.exists() else {}
        # Reuse current CurseForge keys when their complete English text matches.
        self.existing = {}
        for path in [*sorted((ROOT / ".cache").glob("localization-*/verified/enUS.lua")), ROOT / "APR-Core/locales/enUS.lua"]:
            self.existing.update({json.loads(value): key for key, value in re.findall(r'L\["([^"]+)"\]\s*=\s*("(?:[^"\\]|\\.)*")', path.read_text(encoding="utf-8"))})

    def render(self, value, names, locale):
        def token(match):
            ident = match[1]
            if ident in self.names[locale]:
                return self.names[locale][ident]
            if locale == "enUS" and ident in names:
                return names[ident]
            kind, number = ident.split(":")
            if kind in ("item", "spell", "quest"):
                return f"|H{kind}:{number}|h[#{number}]|h"
            return "#" + number
        return re.sub(r"\{([a-z]+:\d+)\}", token, value)

    def key(self, slug, value, names):
        english = self.render(value, names, "enUS")
        key = "FOREVER_PROF_" + hashlib.sha256(value.encode()).hexdigest()[:16].upper()
        # Once this feature's reviewed key is imported into the local preview,
        # it must remain in its export on the next explicit conversion.
        if english in self.existing and key not in self.reviewed.get("enUS", {}):
            return self.existing[english]
        for loc in LOCALES:
            # The export is the reviewed translation source. Never replace a
            # complete instruction with an objective name or a numeric summary.
            reviewed = self.reviewed.get(loc, {}).get(key)
            translated = self.translations[slug, loc].get(value)
            if reviewed is not None and (not isinstance(reviewed, str) or not reviewed.strip()):
                raise ValueError(f"Invalid reviewed translation: {loc} {key}")
            if reviewed:
                rendered = reviewed
            elif loc == "enUS":
                rendered = self.render(value, names, loc)
            elif translated:
                rendered = self.render(translated, names, loc)
            elif (slug, value) in self.note_values:
                raise ValueError(f"Missing complete translation: {loc} {key}")
            else:
                rendered = self.render(value, names, loc)
            if not isinstance(rendered, str) or not rendered.strip():
                raise ValueError(f"Empty translation: {loc} {key}")
            previous = self.output[loc].get(key)
            assert previous is None or previous == rendered, (key, previous, rendered)
            self.output[loc][key] = rendered
        return key


def restrictions(*entries):
    result = {}
    for entry in entries:
        if not entry:
            continue
        for key, values in entry.items():
            if key == "factions":
                assert len(values) == 1
                result["Faction"] = values[0]
            elif key == "races":
                values = ["Scourge" if value == "Undead" else value for value in values]
                result["Race"] = values[0] if len(values) == 1 else values
            else:
                raise ValueError(f"Unsupported source condition {key}")
    return result


def location(goal):
    if all(k in goal for k in ("map", "x", "y")):
        return {"Zone": goal["map"], "Coord": (goal["map"], goal["x"], goal["y"])}
    return {}


def choices(goal, inherited):
    if goal.get("t") == "train" and goal.get("rank") == 1:
        return [(None, inherited)]  # Existing initial-profession service routing.
    candidates = goal.get("candidates")
    if not candidates:
        return [(None, inherited)]
    result = []
    for faction, code, capital in (("Alliance", "A", 1453), ("Horde", "H", 1454)):
        if inherited.get("Faction", faction) != faction:
            continue
        races = inherited.get("Race", [])
        races = [races] if isinstance(races, str) else races
        faction_races = {"Human", "Dwarf", "Gnome", "NightElf", "Skyborne"} if faction == "Alliance" else {"Orc", "Troll", "Tauren", "Undead", "Scourge"}
        if races and not faction_races.intersection(races):
            continue
        eligible = [c for c in candidates if code in c.get("faction", "AH")]
        if not eligible:
            raise ValueError(f"No {faction} trainer/vendor: {goal}")
        # Fixed explicit destination, not the unfinished nearest-service contract.
        target = min(enumerate(eligible), key=lambda pair: (pair[1]["map"] != capital, pair[0]))[1]
        result.append((target, {**inherited, "Faction": faction}))
    return result


def convert_guide(slug, guide, texts):
    steps = []
    names = dict(guide.get("names", {}))
    skill = next(g["skillLine"] for st in guide["steps"] for g in st.get("goals", []) if g["t"] == "train")
    def key(value):
        return texts.key(slug, value, names)
    for source_index, authored in enumerate(guide["steps"], 1):
        base = restrictions(authored.get("only"))
        note = key(authored.get("note") or authored["title"])
        for goal in authored.get("goals", []):
            kind = goal["t"]
            inherited = restrictions(authored.get("only"), goal.get("only"))
            if kind == "skill" and any(g["t"] == "craft" and g.get("untilSkill") == goal["level"] for g in authored["goals"]):
                continue
            if kind == "goto" and any(g["t"] == "skill" for g in authored["goals"]):
                continue  # Put the gathering location on the rank objective itself.
            for candidate, conditions in choices(goal, inherited):
                s = {**conditions, **location(candidate or goal), "ExtraLineText": [note], "_comment": f"Source step {source_index}: {kind}"}
                if candidate:
                    s["RaidIcon"] = candidate["npc"]
                elif goal.get("npc"):
                    s["RaidIcon"] = goal["npc"]
                if kind == "train":
                    if "skillLine" in goal:
                        s["LearnProfession"] = RANKS[goal["skillLine"]][goal["rank"] - 1]
                        book = re.search(r'\{item:(\d+)\}', goal.get("text", ""))
                        if book:
                            rank_spell = s["LearnProfession"]
                            steps.append({**conditions, **location(candidate or goal), "BuyMerchant": [{"itemID": int(book[1]), "quantity": 1}], "DontHaveSpell": rank_spell, "ExtraLineText": [note]})
                            steps.append({**conditions, "UseItem": {"itemID": int(book[1])}, "DontHaveSpell": rank_spell, "ExtraLineText": [note]})
                    else:
                        # Source NPC-only rank instruction (dungeon master).
                        s["LearnProfession"] = RANKS[skill][3]
                        if goal["npc"] == 11073:
                            steps.append({**conditions, "Zone": 1418, "Coord": (1418, 65.05, 43.45), "Waypoint": 900000001, "Range": 10, "ExtraLineText": [note]})
                        else:
                            raise ValueError(f"Unresolved rank trainer: {goal}")
                elif kind == "learn":
                    s["LearnSkill"] = {"spellID": goal["spell"]}
                    if candidate or goal.get("npc"):
                        s["LearnSkill"]["npcID"] = (candidate or goal)["npc"]
                    if goal.get("item"):
                        steps.append({**conditions, "UseItem": {"itemID": goal["item"]}, "DontHaveSpell": goal["spell"], "ExtraLineText": [note]})
                elif kind in ("buy", "collect"):
                    field = "BuyMerchant" if kind == "buy" else "LootItems"
                    item = {"itemID": goal["item"], "quantity": goal.get("count", 1)}
                    if goal.get("quest"):
                        item["questID"] = goal["quest"]
                    if kind == "collect":
                        item["includeBank"] = False
                    s[field] = [item]
                elif kind == "craft":
                    # No automatic crafting. Exact-count intermediate components
                    # use a manual note; rank crafts finish only on native skill.
                    summary = "{spell:" + str(goal["spell"]) + "}"
                    names["spell:" + str(goal["spell"])] = goal["spellName"]
                    if goal.get("count"):
                        summary += " ×" + str(goal["count"])
                    if goal.get("reagents"):
                        summary += " ← " + ", ".join("{item:" + str(r["item"]) + "} ×" + str(r["count"]) for r in goal["reagents"])
                        for reagent in goal["reagents"]:
                            names["item:" + str(reagent["item"])] = reagent["itemName"]
                    s["ExtraLineText"].insert(0, key(summary))
                    if goal.get("untilSkill"):
                        s["SkillGoal"] = {"skillID": goal["skillLine"], "rank": goal["untilSkill"]}
                    else:
                        s["Note"] = [key(summary)]
                    if "Specialisation (optional)" in authored.get("note", ""):
                        s["ExtraLineText"].extend(["FOREVER_PROF_SPECIALIZATION_DETAILS", key(SPECIALIZATIONS[slug])])
                elif kind == "skill":
                    s["SkillGoal"] = {"skillID": goal["skillLine"], "rank": goal["level"]}
                    waypoint = next((g for g in authored["goals"] if g["t"] == "goto"), None)
                    if waypoint:
                        s.update(location(waypoint))
                elif kind == "level":
                    s["Grind"] = goal["level"]
                elif kind == "accept":
                    s["PickUp"] = [goal["quest"]]
                    s["Range"] = 5
                elif kind == "turnin":
                    s["Done"] = [goal["quest"]]
                    s["Range"] = 5
                elif kind == "complete":
                    s["Qpart"] = {goal["quest"]: list(range(1, len(goal.get("objs", [])) + 1))}
                    if goal.get("startItem"):
                        s["Button"] = {str(goal["quest"]) + "-1": goal["startItem"]}
                elif kind == "use":
                    s["UseItem"] = {"itemID": goal["item"]}
                elif kind == "goto":
                    s["Waypoint"] = 900000001
                    s["Range"] = goal.get("r", 10)
                else:
                    raise ValueError(f"Unsupported goal {goal}")
                if goal.get("closedBy"):
                    s["Not"] = {"IsQuestCompleted": goal["closedBy"][0]}
                steps.append(s)
    steps.append({"RouteCompleted": True})
    label = key(guide["title"])
    lines = ['local L = LibStub("AceLocale-3.0"):GetLocale("APR")', '',
             f'-- Profession progression: {slug}.',
             '-- Generated explicitly with tools/forever/professions.py. Manual crafting only.',
             f'APR.RouteQuestStepList["Forever-Profession-{slug}"] = {{',
             f'    label = L[{lua(label)}],', '    expansion = APR.EXPANSIONS.Forever,',
             '    gameVersion = APR.GAME_VERSIONS.Forever,', '    category = APR.CATEGORIES.Professions,',
             '    mapID = 947,', '    autoStartOnMap = false,', '    steps = {']
    for index, step in enumerate(steps, 1):
        lines.append('        {')
        for field, value in step.items():
            encoded = lua(value)
            if field == "Coord":
                encoded = f'APR.worldCoordinateConverter:ConvertMapCoordinate({value[0]}, {value[1]}, {value[2]})'
            lines.append(f'            {field} = {encoded},')
        lines.extend((f'            _index = {index},', '        },'))
    lines.extend(('    },', '}', ''))
    return "\n".join(lines), skill, len(steps)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    args = parser.parse_args()
    guides = read_guides(args.source)
    texts = Texts(args.source, guides)
    DEST.mkdir(parents=True, exist_ok=True)
    for slug, guide in guides.items():
        result, skill, count = convert_guide(slug, guide, texts)
        (DEST / ("Forever_Profession_" + slug.replace("-", "_") + ".lua")).write_text(result, encoding="utf-8")
        print(f"{slug}: skill {skill}, {count} steps")
    export = ROOT / "tools/localization/forever-professions-translations.json"
    for loc in LOCALES:
        texts.output[loc]["FOREVER_PROF_SPECIALIZATION_DETAILS"] = SPECIALIZATION_TEXT[loc]
    export.write_text(json.dumps(texts.output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Translations: {len(texts.output['enUS'])} keys; reviewed export entries preserved")


if __name__ == "__main__":
    main()
