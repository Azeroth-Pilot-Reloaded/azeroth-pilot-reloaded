"""Build APR reputation milestones from reviewed Forever activities.

Explicit authoring tool; never called by tests or addon startup. No third-party
quest IDs or scripts are executed. Source targets are cross-checked against the
local guide data before any output is written. Activity prose is authored in
Route-generator/tools/localization/forever-reputation-translations.json, preserving route titles.
"""

import argparse
import json
import os
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[2]
LOCALIZATION_ROOT = Path(os.environ.get('APR_ROUTEGEN_ROOT', ROOT.parent / 'Route-generator')) / 'tools/localization'
STANDINGS = {"Hated": 1, "Hostile": 2, "Unfriendly": 3, "Neutral": 4,
             "Friendly": 5, "Honored": 6, "Revered": 7, "Exalted": 8}


CATALOG = [
    ("argent-dawn", 529, "Argent Dawn", "Aube d'argent", None, 50, 1422,
     [(5, "argent_low"), (6, "argent_low"), (7, "argent_high"), (8, "argent_high")]),
    ("bloodsail-buccaneers", 87, "Bloodsail Buccaneers", "Voile sanglante", None, 55, 1434,
     [(4, "bloodsail"), (5, "bloodsail")]),
    ("brood-of-nozdormu", 910, "Brood of Nozdormu", "ProgÃ©niture de Nozdormu", None, 60, 1451,
     [(4, "brood_low"), (5, "brood_low"), (6, "brood_high"), (7, "brood_high"), (8, "brood_high")]),
    ("cenarion-circle", 609, "Cenarion Circle", "Cercle cÃ©narien", None, 60, 1451,
     [(6, "cenarion_low"), (7, "cenarion_high"), (8, "cenarion_high")]),
    ("centaur-clans", 92, "Gelkis Clan Centaur", "Centaures du clan Gelkis", None, 30, 1443,
     [(6, "centaur"), (7, "centaur"), (8, "centaur")]),
    ("centaur-clans", 93, "Magram Clan Centaur", "Centaures du clan Magram", None, 30, 1443,
     [(6, "centaur"), (7, "centaur"), (8, "centaur")]),
    ("hydraxian-waterlords", 749, "Hydraxian Waterlords", "Seigneurs des eaux hydraxiens", None, 60, 1447,
     [(6, "hydraxian_low"), (7, "hydraxian_mid"), (8, "hydraxian_high")]),
    ("kirin-tor", 2740, "Kirin Tor", "Kirin Tor", "Alliance", 30, 1416,
     [(5, "kirin")]),
    ("merchants-favor", 2586, "Azeroth Commerce Authority", "AutoritÃ© commerciale d'Azeroth", "Alliance", 10, 1433,
     [(5, "merchant"), (6, "merchant"), (7, "merchant"), (8, "merchant")]),
    ("merchants-favor", 2587, "Durotar Supply and Logistics", "Approvisionnement et logistique de Durotar", "Horde", 10, 1413,
     [(5, "merchant"), (6, "merchant"), (7, "merchant"), (8, "merchant")]),
    ("nightclaw-druids", 2758, "Nightclaw Druids", "Druides Nightclaw", None, 10, 2521,
     [(6, "nightclaw"), (7, "nightclaw"), (8, "nightclaw")]),
    ("ravenholdt", 349, "Ravenholdt", "Ravenholdt", None, 24, 1416,
     [(5, "raven_low"), (6, "raven_low"), (8, "raven_high")]),
    ("thorium-brotherhood", 59, "Thorium Brotherhood", "ConfrÃ©rie du thorium", None, 48, 1427,
     [(5, "thorium_low"), (6, "thorium_mid"), (7, "thorium_high"), (8, "thorium_high")]),
    ("timbermaw-hold", 576, "Timbermaw Hold", "Grumegueules", None, 48, 1448,
     [(3, "timber_low"), (4, "timber_low"), (5, "timber_low"), (6, "timber_low"), (7, "timber_high"), (8, "timber_high")]),
    ("wintersaber-trainers", 589, "Wintersaber Trainers", "Ã‰leveurs de sabres-d'hiver", "Alliance", 58, 1452,
     [(5, "winter_low"), (6, "winter_low"), (8, "winter_high")]),
    ("zandalar-tribe", 270, "Zandalar Tribe", "Tribu Zandalar", None, 60, 1434,
     [(5, "zandalar"), (6, "zandalar"), (7, "zandalar"), (8, "zandalar")]),
]

for slug, fid, en, fr, faction, map_id in [
    ("darnassus", 69, "Darnassus", "Darnassus", "Alliance", 1457),
    ("gnomeregan-exiles", 54, "Gnomeregan Exiles", "ExilÃ©s de Gnomeregan", "Alliance", 1455),
    ("ironforge", 47, "Ironforge", "Forgefer", "Alliance", 1455),
    ("stormwind", 72, "Stormwind", "Hurlevent", "Alliance", 1453),
    ("darkspear-trolls", 530, "Darkspear Trolls", "Trolls Sombrelance", "Horde", 1454),
    ("orgrimmar", 76, "Orgrimmar", "Orgrimmar", "Horde", 1454),
    ("thunder-bluff", 81, "Thunder Bluff", "Les Pitons-du-Tonnerre", "Horde", 1456),
    ("undercity", 68, "Undercity", "Fossoyeuse", "Horde", 1458),
]:
    CATALOG.append((slug, fid, en, fr, faction, 12, map_id, [(6, "city"), (7, "city"), (8, "city")]))

for slug, fid, en, fr, faction, level, map_id, act in [
    ("alterac-valley", 730, "Stormpike Guard", "Garde Foudrepique", "Alliance", 51, 1416, "av"),
    ("alterac-valley", 729, "Frostwolf Clan", "Clan Loup-de-givre", "Horde", 51, 1416, "av"),
    ("arathi-basin", 509, "The League of Arathor", "La Ligue d'Arathor", "Alliance", 20, 1417, "ab"),
    ("arathi-basin", 510, "The Defilers", "Les Profanateurs", "Horde", 20, 1417, "ab"),
    ("warsong-gulch", 890, "Silverwing Sentinels", "Sentinelles d'Aile-argent", "Alliance", 10, 1440, "wsg"),
    ("warsong-gulch", 889, "Warsong Outriders", "Voltigeurs Chanteguerre", "Horde", 10, 1413, "wsg"),
    ("darkspear-islands", 2798, "Darkspear Raiders", "Raiders Darkspear", "Horde", 30, 1413, "islands"),
    ("darkspear-islands", 2799, "Theramore Expeditionary Force", "Corps expÃ©ditionnaire de Theramore", "Alliance", 30, 1413, "islands"),
]:
    CATALOG.append((slug, fid, en, fr, faction, level, map_id, [(n, act) for n in range(5, 9)]))

for fid, en, fr in [(470, "Ratchet", "Cabestan"), (21, "Booty Bay", "Baie-du-Butin"),
                    (369, "Gadgetzan", "Gadgetzan"), (577, "Everlook", "Long-guet")]:
    CATALOG.append(("steamwheedle-cartel", fid, en, fr, None, 50, 1444,
                    [(n, "cartel") for n in range(5, 9)]))


# Established localized faction names; custom names retain their server spelling.
FACTION_NAMES = {
    "deDE": {
        "529": "Argentumdämmerung",
        "87": "Blutsegelbukaniere",
        "910": "Brut Nozdormus",
        "609": "Zirkel des Cenarius",
        "92": "Gelkisklan",
        "93": "Magramklan",
        "749": "Hydraxianer",
        "2740": "Kirin Tor",
        "349": "Rabenholdt",
        "59": "Thoriumbruderschaft",
        "576": "Holzschlundfeste",
        "589": "Wintersäblerausbilder",
        "270": "Stamm der Zandalari",
        "69": "Darnassus",
        "54": "Gnomeregangnome",
        "47": "Eisenschmiede",
        "72": "Sturmwind",
        "530": "Dunkelspeertrolle",
        "76": "Orgrimmar",
        "81": "Donnerfels",
        "68": "Unterstadt",
        "730": "Sturmlanzengarde",
        "729": "Frostwolfklan",
        "509": "Der Bund von Arathor",
        "510": "Die Entweihten",
        "890": "Silberschwingen",
        "889": "Kriegshymnenklan",
        "470": "Ratschet",
        "21": "Beutebucht",
        "369": "Gadgetzan",
        "577": "Ewige Warte"
    },
    "koKR": {
        "529": "은빛 여명회",
        "87": "붉은 해적단",
        "910": "노즈도르무 혈족",
        "609": "세나리온 의회",
        "92": "켄타우로스 - 겔키스 일족",
        "93": "켄타우로스 - 마그람 일족",
        "749": "히드락시안 물의 군주",
        "2740": "키린 토",
        "349": "라벤홀트 암살단",
        "59": "토륨 대장조합",
        "576": "나무구렁 요새",
        "589": "눈호랑이 조련사",
        "270": "잔달라 부족",
        "69": "다르나서스",
        "54": "놈리건",
        "47": "아이언포지",
        "72": "스톰윈드",
        "530": "검은창 트롤",
        "76": "오그리마",
        "81": "썬더 블러프",
        "68": "언더시티",
        "730": "스톰파이크 경비대",
        "729": "서리늑대 부족",
        "509": "아라소르 연맹",
        "510": "포세이큰 파멸단",
        "890": "은빛날개 파수대",
        "889": "전쟁노래 정찰대",
        "470": "톱니항",
        "21": "무법항",
        "369": "가젯잔",
        "577": "눈망루 마을"
    },
    "esES": {
        "529": "El Alba Argenta",
        "87": "Bucaneros Velasangre",
        "910": "Linaje de Nozdormu",
        "609": "Círculo Cenarion",
        "92": "Centauros del clan Gelkis",
        "93": "Centauros del clan Magram",
        "749": "Srs. del Agua de Hydraxis",
        "2740": "Kirin Tor",
        "349": "Ravenholdt",
        "59": "Hermandad del Torio",
        "576": "Bastión Fauces de Madera",
        "589": "Instructores de sableinvernales",
        "270": "Tribu Zandalar",
        "69": "Darnassus",
        "54": "Exiliados de Gnomeregan",
        "47": "Forjaz",
        "72": "Ventormenta",
        "530": "Trols Lanza Negra",
        "76": "Orgrimmar",
        "81": "Cima del Trueno",
        "68": "Entrañas",
        "730": "Guardia Pico Tormenta",
        "729": "Clan Lobo Gélido",
        "509": "Liga de Arathor",
        "510": "Los Rapiñadores",
        "890": "Centinelas Ala de Plata",
        "889": "Escoltas Grito de Guerra",
        "470": "Trinquete",
        "21": "Bahía del Botín",
        "369": "Gadgetzan",
        "577": "Vista Eterna"
    },
    "esMX": {
        "529": "El Alba Argenta",
        "87": "Bucaneros Velasangre",
        "910": "Linaje de Nozdormu",
        "609": "Círculo Cenarion",
        "92": "Centauros del clan Gelkis",
        "93": "Centauros del clan Magram",
        "749": "Srs. del Agua de Hydraxis",
        "2740": "Kirin Tor",
        "349": "Ravenholdt",
        "59": "Hermandad del Torio",
        "576": "Bastión Fauces de Madera",
        "589": "Instructores de sableinvernales",
        "270": "Tribu Zandalar",
        "69": "Darnassus",
        "54": "Exiliados de Gnomeregan",
        "47": "Forjaz",
        "72": "Ventormenta",
        "530": "Trols Lanza Negra",
        "76": "Orgrimmar",
        "81": "Cima del Trueno",
        "68": "Entrañas",
        "730": "Guardia Pico Tormenta",
        "729": "Clan Lobo Gélido",
        "509": "Liga de Arathor",
        "510": "Los Rapiñadores",
        "890": "Centinelas Ala de Plata",
        "889": "Escoltas Grito de Guerra",
        "470": "Trinquete",
        "21": "Bahía del Botín",
        "369": "Gadgetzan",
        "577": "Vista Eterna"
    },
    "ptBR": {
        "529": "Aurora Argêntea",
        "87": "Bucaneiros da Vela Sangrenta",
        "910": "Prole de Nozdormu",
        "609": "Círculo Cenariano",
        "92": "Clã dos Centauros Gelkis",
        "93": "Clã dos Centauros Magram",
        "749": "Senhores das Águas Hidraxianos",
        "2740": "Kirin Tor",
        "349": "Corvoforte",
        "59": "Irmandade do Tório",
        "576": "Domínio dos Presamatos",
        "589": "Treinadores de Sabres-do-inverno",
        "270": "Tribo Zandalar",
        "69": "Darnassus",
        "54": "Gnomeregan",
        "47": "Altaforja",
        "72": "Ventobravo",
        "530": "Trolls Lançanegra",
        "76": "Orgrimmar",
        "81": "Penhasco do Trovão",
        "68": "Cidade Baixa",
        "730": "Guarda de Lançatroz",
        "729": "Clã Lobo do Gelo",
        "509": "A Liga de Arathor",
        "510": "Os Profanadores",
        "890": "Sentinelas da Asa de Prata",
        "889": "Pioneiros do Brado Guerreiro",
        "470": "Vila Catraca",
        "21": "Angra do Butim",
        "369": "Geringontzan",
        "577": "Visteterna"
    },
    "itIT": {
        "529": "Alba d'Argento",
        "87": "Bucanieri Velerosse",
        "910": "Stirpe di Nozdormu",
        "609": "Circolo Cenariano",
        "92": "Centauri del Clan Gelkis",
        "93": "Centauri del Clan Magram",
        "749": "Seguaci di Idraxis",
        "2740": "Kirin Tor",
        "349": "Corvolesto",
        "59": "Fratellanza del Torio",
        "576": "Rifugio dei Mordilegno",
        "589": "Addestratori delle Fiere Glaciali",
        "270": "Tribù Zandalari",
        "69": "Darnassus",
        "54": "Esiliati di Gnomeregan",
        "47": "Forgiardente",
        "72": "Roccavento",
        "530": "Troll Lanciascura",
        "76": "Orgrimmar",
        "81": "Picco del Tuono",
        "68": "Sepulcra",
        "730": "Guardia dei Piccatonante",
        "729": "Clan Lupi Bianchi",
        "509": "Lega di Arathor",
        "510": "Profanatori",
        "890": "Sentinelle Alargentea",
        "889": "Predoni Cantaguerra",
        "470": "Porto Paranco",
        "21": "Baia del Bottino",
        "369": "Meccania",
        "577": "Lungavista"
    },
    "ruRU": {
        "529": "Серебряный Рассвет",
        "87": "Пираты Кровавого Паруса",
        "910": "Род Ноздорму",
        "609": "Круг Кенария",
        "92": "Кентавры из племени Гелкис",
        "93": "Кентавры из племени Маграм",
        "749": "Гидраксианские Повелители Вод",
        "2740": "Кирин-Тор",
        "349": "Черный Ворон",
        "59": "Братство Тория",
        "576": "Древобрюхи",
        "589": "Укротители ледопардов",
        "270": "Племя Зандалари",
        "69": "Дарнас",
        "54": "Изгнанники Гномрегана",
        "47": "Стальгорн",
        "72": "Штормград",
        "530": "Племя Черного Копья",
        "76": "Оргриммар",
        "81": "Громовой Утес",
        "68": "Подгород",
        "730": "Стража Грозовой Вершины",
        "729": "Азеротский клан Северного Волка",
        "509": "Лига Аратора",
        "510": "Осквернители",
        "890": "Среброкрылые Часовые",
        "889": "Всадники Песни Войны",
        "470": "Кабестан",
        "21": "Пиратская Бухта",
        "369": "Прибамбасск",
        "577": "Круговзор"
    },
    "zhCN": {
        "529": "银色黎明",
        "87": "血帆海盗",
        "910": "诺兹多姆的子嗣",
        "609": "塞纳里奥议会",
        "92": "吉尔吉斯半人马",
        "93": "玛格拉姆半人马",
        "749": "海达希亚水元素",
        "2740": "肯瑞托",
        "349": "拉文霍德",
        "59": "瑟银兄弟会",
        "576": "木喉要塞",
        "589": "冬刃豹训练师",
        "270": "赞达拉部族",
        "69": "达纳苏斯",
        "54": "诺莫瑞根流亡者",
        "47": "铁炉堡",
        "72": "暴风城",
        "530": "暗矛巨魔",
        "76": "奥格瑞玛",
        "81": "雷霆崖",
        "68": "幽暗城",
        "730": "雷矛卫队",
        "729": "霜狼氏族",
        "509": "阿拉索联军",
        "510": "污染者",
        "890": "银翼要塞",
        "889": "战歌氏族",
        "470": "棘齿城",
        "21": "藏宝海湾",
        "369": "加基森",
        "577": "永望镇"
    },
    "zhTW": {
        "529": "銀色黎明",
        "87": "血帆海盜",
        "910": "諾茲多姆的子嗣",
        "609": "塞納里奧議會",
        "92": "吉爾吉斯半人馬",
        "93": "瑪格拉姆半人馬",
        "749": "海達希亞水元素",
        "2740": "祈倫托",
        "349": "拉文霍德",
        "59": "瑟銀兄弟會",
        "576": "木喉要塞",
        "589": "冬刃豹訓練師",
        "270": "贊達拉部族",
        "69": "達納蘇斯",
        "54": "諾姆瑞根流亡者",
        "47": "鐵爐堡",
        "72": "暴風城",
        "530": "暗矛食人妖",
        "76": "奧格瑪",
        "81": "雷霆崖",
        "68": "幽暗城",
        "730": "雷矛衛隊",
        "729": "霜狼氏族",
        "509": "阿拉索聯軍",
        "510": "污染者",
        "890": "銀翼哨兵",
        "889": "戰歌先遣騎",
        "470": "棘齒城",
        "21": "藏寶海灣",
        "369": "加基森",
        "577": "永望鎮"
    }
}


# Compact translations retain the actionable method, prerequisite and cap. The
# longer English/French explanations are editorial variants of the same method.
def translation_catalog():
    """The reviewed export is also the authoring source; do not duplicate prose."""
    return json.loads((LOCALIZATION_ROOT / 'forever-reputation-translations.json').read_text(encoding='utf-8'))


def all_activities():
    prefix = 'FOREVER_REPUTATION_ACTIVITY_'
    catalog = translation_catalog()
    return {key[len(prefix):].lower(): {locale: values[key] for locale, values in catalog.items()}
            for key in catalog['enUS'] if key.startswith(prefix)}


CUSTOM_FACTION_NAMES = {
    'deDE': ['Handelsbehörde von Azeroth', 'Versorgung und Logistik von Durotar', 'Nachtklauendruiden', 'Dunkelspeerräuber', 'Expeditionsstreitmacht von Theramore'],
    'esES': ['Autoridad de Comercio de Azeroth', 'Suministros y Logística de Durotar', 'Druidas Garra Nocturna', 'Asaltantes Lanza Negra', 'Fuerza Expedicionaria de Theramore'],
    'itIT': ['Autorità Commerciale di Azeroth', 'Rifornimenti e Logistica di Durotar', 'Druidi Artiglio Notturno', 'Predoni Lanciascura', 'Corpo di Spedizione di Theramore'],
    'ptBR': ['Autoridade Comercial de Azeroth', 'Suprimentos e Logística de Durotar', 'Druidas Garra da Noite', 'Saqueadores Lançanegra', 'Força Expedicionária de Theramore'],
    'ruRU': ['Торговое управление Азерота', 'Снабжение и логистика Дуротара', 'Друиды Ночного Когтя', 'Налетчики Черного Копья', 'Тераморский экспедиционный корпус'],
    'koKR': ['아제로스 상업 협회', '듀로타 보급 및 병참', '밤발톱 드루이드', '검은창 약탈자', '테라모어 원정군'],
    'zhCN': ['艾泽拉斯贸易局', '杜隆塔尔后勤补给局', '夜爪德鲁伊', '暗矛掠夺者', '塞拉摩远征军'],
    'zhTW': ['艾澤拉斯貿易局', '杜洛塔後勤補給局', '夜爪德魯伊', '暗矛掠奪者', '塞拉摩遠征軍'],
}


def localized_name(locale, fid, en, fr):
    if locale == 'frFR':
        return fr
    locale = 'esES' if locale == 'esMX' else locale
    custom_ids = (2586, 2587, 2758, 2798, 2799)
    if fid in custom_ids and locale in CUSTOM_FACTION_NAMES:
        return CUSTOM_FACTION_NAMES[locale][custom_ids.index(fid)]
    return FACTION_NAMES.get(locale, {}).get(str(fid), en)


TITLE_PREFIXES = {
    'enUS': 'Reputation', 'frFR': 'Réputation', 'deDE': 'Ruf',
    'esES': 'Reputación', 'esMX': 'Reputación', 'itIT': 'Reputazione',
    'ptBR': 'Reputação', 'ruRU': 'Репутация', 'koKR': '평판',
    'zhCN': '声望', 'zhTW': '聲望',
}


def title_key(english_name):
    return f'Forever - Reputation - {english_name}'


def legacy_labels(entry):
    _, fid, en, fr, *_ = entry
    return list(dict.fromkeys('Forever - ' + localized_name(locale, fid, en, fr)
                             for locale in TITLE_PREFIXES))


def read_targets(text):
    """Read only documented reputation declarations, never embedded scripts."""
    return {(int(fid), STANDINGS[standing]) for fid, standing in re.findall(
        r"^\s*rep\s+(\d+)\s+(Hated|Hostile|Unfriendly|Neutral|Friendly|Honored|Revered|Exalted)\b",
        text, re.MULTILINE)}


class MapPoint(tuple):
    """A source map point, converted by APR at route declaration time."""


class WorldPoint(tuple):
    """An existing world point with its navigation map retained separately."""


def point(map_id, x, y):
    return MapPoint((map_id, x, y))


def lua(value):
    if isinstance(value, MapPoint):
        return 'APR.worldCoordinateConverter:ConvertMapCoordinate(' + ', '.join(map(str, value)) + ')'
    if isinstance(value, WorldPoint):
        return lua({'x': value[1], 'y': value[2]})
    if value is True:
        return 'true'
    if value is False:
        return 'false'
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, (list, tuple)):
        return '{ ' + ', '.join(lua(item) for item in value) + ' }'
    if isinstance(value, dict):
        return '{ ' + ', '.join((key if isinstance(key, str) and key.isidentifier() else '[' + lua(key) + ']')
                               + ' = ' + lua(item) for key, item in value.items()) + ' }'
    raise TypeError(f'Unsupported authored value: {value!r}')


def located(step, destination):
    if destination:
        step.update(Coord=destination, Zone=destination[0])
    return step


def quest(qid, giver, objectives=(), receiver=None, filters=None, prerequisite=None,
          npc=None, receiver_npc=None, starter=None, repeatable=False):
    """One native quest traversal, never an invented automatic repeat loop.

    Repeatable quests deliberately have no permanent completion predicates.
    Objective tuples contain the actual quest objective indexes and destinations.
    """
    filters = dict(filters or {})
    pickup = dict(filters, PickUp=[qid], IsQuestNotOnQuest=qid)
    if not repeatable:
        pickup['IsQuestUncompleted'] = qid
    if prerequisite:
        pickup['IsQuestCompleted'] = prerequisite
    if starter:
        pickup.update(Button={str(qid): starter},
                      ItemCount={'itemID': starter, 'count': 1, 'includeBank': False})
    elif giver:
        pickup['Range'] = 5
    if npc:
        pickup['RaidIcon'] = [{'npcID': npc, 'questID': qid}]
    result = [located(pickup, giver)]
    for parts, destination, options in objectives:
        step = dict(filters, Qpart={qid: list(parts)}, IsQuestOnQuest=qid,
                    Not={'IsQuestReadyForTurnIn': qid})
        step.update(options)
        result.append(located(step, destination))
    done = dict(filters, Done=[qid], IsQuestOnQuest=qid)
    if receiver_npc or (npc and not receiver):
        done['RaidIcon'] = [{'npcID': receiver_npc or npc, 'questID': qid}]
    result.append(located(done, receiver or giver))
    return result


def objective(parts, destination, **options):
    return (parts, destination, options)


CITY_POINTS = {
    69: point(1457, 64.02, 23), 54: point(1455, 74.09, 48.22),
    47: point(1455, 43.22, 31.57), 72: point(1453, 53.93, 81.67),
    530: point(1454, 37.7, 87.9), 76: point(1454, 63.6, 51.23),
    81: point(1456, 43.05, 42.72), 68: point(1458, 71.66, 29.23),
}

ACTIVITY_POINTS = {
    'argent_low': point(1422, 36.97, 57.26),
    'argent_high': point(1423, 26.5, 10.4),
    'bloodsail': point(1434, 29, 75.6),
    'brood_low': point(1451, 29, 92.8), 'brood_high': point(1451, 29, 92.8),
    'cenarion_low': point(1451, 39, 44), 'cenarion_high': point(1451, 48.57, 37.78),
    'hydraxian_low': point(1451, 19.84, 22.23),
    'hydraxian_mid': point(1427, 32.1, 94.7), 'hydraxian_high': point(1427, 32.1, 94.7),
    'kirin': point(1416, 8.5, 59.3),
    'nightclaw': point(2521, 63.8, 36.03),
    'raven_low': point(1417, 27.1, 30.6), 'raven_high': point(1416, 84.45, 80.32),
    'cartel': point(1444, 44.81, 43.423),
    'thorium_low': point(1427, 38.77, 28.5), 'thorium_mid': point(1427, 38.77, 28.5),
    # The precise location inside the dungeon is not established here. Point at
    # its entrance rather than fabricate a map pin for the bar.
    'thorium_high': point(1427, 32.1, 94.7),
    'timber_low': point(1448, 63.08, 8.82), 'timber_high': point(1452, 27.74, 34.5),
    'winter_low': point(1452, 49.94, 9.84), 'winter_high': point(1452, 49.94, 9.84),
    'zandalar': WorldPoint((1434, 1295.6, -11840.9)),
}


def native_plan(fid):
    """Reviewed one-time unlocks and initial repeatable traversals by milestone.

    Keys are target standings; 0 runs at entry, 9 after the final milestone.
    No current repeatable turn-in is ever used as a permanent prerequisite.
    """
    plan = {0: []}
    add = lambda steps, before=0: plan.setdefault(before, []).extend(steps)
    if fid == 529:
        alternatives = [5401, 5405, 5503]
        for faction, qid, giver, npc in [
            ('Alliance', 5401, point(1422, 42.97, 83.55), 10840),
            ('Horde', 5405, point(1420, 83.19, 68.45), 10839),
        ]:
            steps = quest(qid, giver, filters={'Faction': faction}, npc=npc)
            steps[0]['Not'] = {'AnyOf': [
                {'IsOneOfQuestsCompleted': alternatives},
                {'ItemCount': {'itemIDs': [12846, 13209, 19812], 'count': 1, 'includeBank': True}},
            ]}
            add(steps)
        for item_id in (19812, 13209, 12846):
            add([{'EquipItem': {'itemID': item_id, 'slot': 13},
                  'ItemCount': {'itemID': item_id, 'count': 1, 'includeBank': False},
                  'Not': {'AnyOf': [{'EquippedItem': {'slot': slot, 'itemID': item}}
                                   for slot in (13, 14) for item in (12846, 13209, 19812)]},
                  'Note': ['EQUIP_ARGENT_DAWN_COMMISSION_COLLECT_SCOURGESTONES']}])
    elif fid == 609:
        add(quest(8318, point(1451, 48.57, 37.78),
                  [objective([1], point(1451, 39, 44))], npc=15306))
    elif fid == 59:
        add(quest(7722, point(1427, 38.77, 28.5),
                  [objective([1], point(1427, 40.39, 35.73))], npc=14624))
    elif fid == 749:
        duke = point(1447, 79.28, 73.69)
        add(quest(6804, duke, [objective([1], point(1423, 44, 41), Button={'6804-1': 17310})], npc=13278))
        add(quest(6805, duke, [objective([1, 2], point(1451, 19.84, 22.23))], npc=13278))
        # Raid continuation comes after the attainable outdoor Honored stage;
        # it must not prevent players from using the outdoor reputation path.
        steps = quest(6821, duke,
                      [objective([1], point(1428, 26.4, 24.5), GroupTask=6821)], npc=13278)
        steps[0]['IsQuestsCompleted'] = [6804, 6805]
        add(steps, 7)
        add(quest(6822, duke, [objective([1, 2, 3, 4], point(1427, 32.1, 94.7), GroupTask=6822)],
                  prerequisite=6821, npc=13278), 7)
        add(quest(6823, duke, prerequisite=6822, npc=13278), 7)
        add(quest(6824, duke, [objective([1, 2, 3, 4], point(1427, 32.1, 94.7), GroupTask=6824)],
                  prerequisite=6823, npc=13278), 7)
    elif fid == 576:
        grazle, nafien, salfa = point(1448, 50.93, 85.01), point(1448, 64.77, 8.13), point(1452, 27.74, 34.5)
        add(quest(8460, grazle, [objective([1, 2, 3], point(1448, 48.32, 92.99))], npc=11554))
        add(quest(8462, grazle, receiver=nafien, prerequisite=8460, npc=11554, receiver_npc=15395))
        add(quest(8461, nafien, [objective([1, 2, 3], point(1448, 63.08, 8.82))], prerequisite=8462, npc=15395))
        # The hostile tunnel is crossed only after the first attainable standing.
        add(quest(8465, nafien, receiver=salfa, prerequisite=8461, npc=15395, receiver_npc=11556), 4)
        add(quest(8464, salfa, [objective([1, 2, 3], point(1452, 67.03, 35.57))], prerequisite=8465, npc=11556), 4)
    elif fid == 589:
        rivern = point(1452, 49.94, 9.84)
        add(quest(4970, rivern, [objective([1, 2], point(1452, 58, 19))], npc=10618, repeatable=True), 5)
        add(quest(5201, rivern, [objective([1, 2], point(1452, 67.03, 35.57))], npc=10618, repeatable=True), 6)
        add(quest(5981, rivern, [objective([1, 2], point(1452, 62.19, 68.75), GroupTask=5981)],
                  npc=10618, repeatable=True), 8)
    elif fid == 349:
        # The letter is optional and Rogue-only; all classes retain the grind.
        add(quest(6681, None, [objective([1], point(1424, 78.62, 17.96))],
                  receiver=point(1416, 84.45, 80.32), filters={'Class': 'ROGUE'},
                  receiver_npc=6707, starter=17126))
    elif fid == 270:
        steps = quest(8240, ACTIVITY_POINTS['zandalar'],
                      [objective([1], None, NoArrow=True,
                                 ExtraLineText=['FOREVER_REPUTATION_DESTROY_BIJOU'])], npc=15070)
        bijous = list(range(19707, 19716))
        progress = steps[1]
        fallback = dict(progress, Not={'AnyOf': [
            progress['Not'], {'ItemCount': {'itemIDs': bijous, 'count': 1, 'includeBank': False}}]})
        steps[1:2] = [dict(progress, Button={'8240-1': item_id},
                           ItemCount={'itemID': item_id, 'count': 1, 'includeBank': False})
                      for item_id in bijous] + [fallback]
        add(steps)
    elif fid in (92, 93):
        for faction, totem_quest, buying_quest, giver, npc in [
            ('Alliance', 93224, 93227 if fid == 92 else 93226, point(1443, 66.7, 10.9), 5396),
            ('Horde', 93225, 94873 if fid == 92 else 94872, point(1443, 56.3, 59.7), 5412),
        ]:
            add(quest(totem_quest, giver, [objective([1], point(1443, 69.5, 44))],
                      filters={'Faction': faction}, npc=npc))
            add(quest(buying_quest, giver,
                      receiver=point(1443, 35.6, 92) if fid == 92 else point(1443, 75, 68.2),
                      filters={'Faction': faction}, prerequisite=totem_quest, npc=npc,
                      receiver_npc=253139 if fid == 93 else None))
    elif fid in (470, 21, 369, 577):
        zorbin = point(1444, 44.81, 43.423)
        add(quest(7003, zorbin, [objective([1], point(1444, 37.8, 22), Button={'7003-1': 18904})], npc=14637))
        add(quest(7721, zorbin, [objective([1], point(1444, 34.4, 35.6))], npc=14637))
    elif fid == 2740:
        modera = point(1421, 68.6, 45.2)
        add(quest(92432, point(1424, 48.3, 60.1), receiver=modera, npc=247264, receiver_npc=269127))
        add(quest(92458, modera, [objective([1], point(1416, 8.5, 59.3), GroupTask=92458)],
                  prerequisite=92432, npc=269127))
        add(quest(92457, modera, [objective([1, 2, 3], point(1416, 8.5, 59.3), GroupTask=92457)],
                  prerequisite=92432, npc=269127))
    elif fid == 2758:
        lotheluum, elegael, vayn = point(2521, 63.973, 75.095), point(2521, 61.76, 39.14), point(2521, 63.8, 36.03)
        steps = quest(94484, lotheluum, receiver=elegael, npc=252359, receiver_npc=257944)
        steps[0]['IsQuestUncompleted'] = 94484
        steps[0]['Not'] = {'AnyOf': [{'IsQuestCompleted': 94493}, {'IsQuestOnQuest': 94493}]}
        add(steps)
        ear_steps = quest(93165, vayn, [objective([1], point(2521, 63.835, 37.435))], npc=254151)
        add(ear_steps[:1])
        for qid, destination in [(94485, point(2521, 58.27, 38.33)),
                                 (94486, point(2521, 58.27, 38.33)),
                                 (94487, point(2521, 63.835, 37.435))]:
            steps = quest(qid, elegael, [objective([1], destination)], npc=257944)
            steps[0]['AnyOf'] = [{'IsQuestCompleted': 94484}, {'IsQuestCompleted': 94493}]
            add(steps)
        steps = quest(94488, elegael, [objective([1], point(2521, 65.54, 36.3))], npc=257944)
        steps[0]['IsQuestsCompleted'] = [94485, 94486, 94487]
        add(steps)
        steps = quest(94489, elegael, [objective([2], point(2521, 64.49, 34.74), GossipOptionIDs=[137859])], npc=257944)
        steps[0]['IsQuestsCompleted'] = [94485, 94486, 94487]
        rescues = []
        for count, destination in [(2, point(2521, 64.25, 31.93)),
                                    (4, point(2521, 65.93, 33.55)),
                                    (7, point(2521, 64.745, 34.925))]:
            rescues.append(located({'QpartPart': {94489: [1]}, 'TrigText': f'{count}/',
                                    'IsQuestOnQuest': 94489, 'Not': {'IsQuestReadyForTurnIn': 94489},
                                    'Note': ['NOT_MOVE_DURING_INTERACTION']}, destination))
        steps[1:1] = rescues
        add(steps)
        add([located({'LootItems': [{'itemID': 265476, 'quantity': 1, 'includeBank': False}],
                      'IsQuestUncompleted': 94490, 'IsQuestNotOnQuest': 94490}, point(2521, 65.54, 36.3))])
        add(quest(94490, None, receiver=elegael, starter=265476, receiver_npc=257944))
        add(ear_steps[1:])
        steps = quest(94491, elegael, receiver=lotheluum, npc=257944, receiver_npc=252359)
        steps[0]['IsQuestsCompleted'] = [94488, 94489, 94490]
        add(steps)
    elif fid == 87:
        firallon = point(1434, 30.6, 90.6)
        add(quest(9272, firallon, npc=2546), 5)
        add(quest(1036, point(1434, 27.6, 69.6), receiver=firallon, npc=2545, receiver_npc=2546), 9)
        add(quest(4621, firallon, [objective([1, 2], point(1434, 27.2, 76.9), GroupTask=4621)],
                  prerequisite=1036, npc=2546), 9)
    return plan


def validate_native_quests(entry, source_text):
    declared = {int(match) for match in re.findall(r'^\s*(?:accept|turnin)\s+(\d+)\b', source_text, re.MULTILINE)}
    referenced = set()
    for group in native_plan(entry[1]).values():
        for step in group:
            for action in ('PickUp', 'Done'):
                referenced.update(step.get(action, []))
            referenced.update(step.get('Qpart', {}))
            referenced.update(step.get('QpartPart', {}))
    if referenced - declared:
        raise ValueError(f'Undocumented native quests in {entry[0]}: {sorted(referenced - declared)}')


def normalize_step(value):
    """Preserve existing notes, merge extra instructions, discard old comments."""
    if isinstance(value, (MapPoint, WorldPoint)):
        return value
    if isinstance(value, dict):
        result = {key: normalize_step(item) for key, item in value.items() if key != '_comment'}
        extra = result.pop('ExtraLineText', None)
        if extra is not None:
            def note_list(notes):
                return [notes] if isinstance(notes, str) else list(notes)
            result['Note'] = note_list(result.get('Note', [])) + note_list(extra)
        return result
    if isinstance(value, (list, tuple)):
        return [normalize_step(item) for item in value]
    return value


def milestone_steps(fid, standing, act, faction=None):
    """Keep repeat instructions scoped to the character and current activity."""
    step = {'Reputation': {'factionID': fid, 'level': standing, 'type': 'standard'},
            'Note': [f'FOREVER_REPUTATION_ACTIVITY_{act.upper()}']}
    if faction:
        step['Faction'] = faction
    destination = CITY_POINTS.get(fid) if act == 'city' else ACTIVITY_POINTS.get(act)
    if act == 'centaur':
        destination = point(1443, 35.6, 92) if fid == 92 else point(1443, 75, 68.2)
    located(step, destination)
    if act.startswith('argent_'):
        result = []
        for side in ('Alliance', 'Horde'):
            variant = dict(step, Faction=side, Note=step['Note'] + [f'FOREVER_REPUTATION_ARGENT_RETURN_{side.upper()}'],
                           Button={str(fid): 12844})
            result.append(variant)
        return result
    if act == 'raven_high':
        return [dict(step, Class='ROGUE', Note=['FOREVER_REPUTATION_RAVEN_PICKPOCKET'],
                     SpellButton={str(fid): 921}),
                dict(step, ClassNot='ROGUE')]
    if act == 'merchant' and standing == 5:
        quest_id = 98247 if faction == 'Alliance' else 98248
        return [dict(step, IsQuestUncompleted=quest_id,
                     Note=[f'FOREVER_REPUTATION_DELIVERY_{faction.upper()}'] + step['Note']),
                dict(step, IsQuestCompleted=quest_id)]
    if act == 'cartel':
        step['Button'] = {str(fid): 18904}
    elif act == 'zandalar':
        step['Button'] = {str(fid): 19858}
    return [step]


def render_route(entry):
    slug, fid, en, fr, faction, level, map_id, stages = entry
    key = title_key(en)
    route_id = "Forever-Reputation-" + re.sub(r"[^A-Za-z0-9]+", "-", en).strip("-")
    lines = ['local L = LibStub("AceLocale-3.0"):GetLocale("APR")', '',
             '-- Generated by tools/conversion/forever_reputation.py; edit the reviewed catalog there.',
             f'APR.RouteQuestStepList["{route_id}"] = {{',
             '    expansion = APR.EXPANSIONS.Forever,',
             '    gameVersion = APR.GAME_VERSIONS.Forever,',
             '    category = APR.CATEGORIES.Reputation,',
             f'    label = L["{key}"],',
             f'    legacyLabels = {lua(legacy_labels(entry))},',
             '    autoStartOnMap = false,',
             f'    mapID = {map_id},',
             f'    levelRange = {{ min = {level}, max = 60 }},',
             f'    conditions = {{ MinLevel = {level}' + (f', Faction = "{faction}"' if faction else '') + ' },',
             '    steps = {']
    index = 0
    plan = native_plan(fid)

    def append_native(steps, standing=None):
        nonlocal index
        for authored in steps:
            step = normalize_step(authored)
            if standing:
                step['SkipForReputation'] = {'factionID': fid, 'level': standing, 'type': 'standard'}
            index += 1
            step['_index'] = index
            lines.append('        ' + lua(step) + ',')

    append_native(plan.get(0, []), stages[-1][0])
    for standing, act in stages:
        append_native(plan.get(standing, []), standing)
        for step in milestone_steps(fid, standing, act, faction):
            index += 1
            step['_index'] = index
            lines.append('        {')
            for field, value in step.items():
                rendered = lua(value)
                if field == 'Reputation':
                    rendered = rendered.replace('"standard"', 'APR.REPUTATION_TYPE.Standard')
                lines.append(f'            {field} = {rendered},')
            lines.append('        },')
    append_native(plan.get(9, []))
    lines.extend([f'        {{ RouteCompleted = true, _index = {index + 1} }},', '    },', '}', ''])
    return '\n'.join(lines)


def build(source_dir, output_dir, translations_path, migration_path=None):
    """Validate the entire input before writing only explicitly named outputs."""
    activities = all_activities()
    catalog = translation_catalog()
    exports = {locale: {} for locale in next(iter(activities.values()))}
    outputs = []
    covered = set()
    seen_ids = set()
    migration = {}
    for entry in CATALOG:
        slug, fid, en, fr, faction, level, map_id, stages = entry
        if fid in seen_ids:
            raise ValueError(f"Duplicate faction ID {fid}")
        seen_ids.add(fid)
        source = source_dir / (slug + '.guide')
        source_text = source.read_text(encoding='utf-8-sig')
        targets = read_targets(source_text)
        validate_native_quests(entry, source_text)
        for standing, act in stages:
            if (fid, standing) not in targets:
                raise ValueError(f"Undocumented target {fid}/{standing} in {source}")
            for locale in exports:
                exports[locale][f"FOREVER_REPUTATION_ACTIVITY_{act.upper()}"] = activities[act][locale]
        for locale in exports:
            name = localized_name(locale, fid, en, fr)
            exports[locale][title_key(en)] = catalog.get(locale, {}).get(title_key(en), f"{TITLE_PREFIXES[locale]} - {name}")
        migration[f'FOREVER_REPUTATION_TITLE_{fid}'] = title_key(en)
        rendered = render_route(entry)
        for key in set(re.findall(r'"(FOREVER_REPUTATION_[A-Z_]+)"', rendered)):
            if key.startswith('FOREVER_REPUTATION_ACTIVITY_'):
                continue
            for locale in exports:
                exports[locale][key] = catalog[locale][key]
        outputs.append(rendered)
        covered.add(slug)
    discovered = {p.stem for p in source_dir.glob('*.guide')}
    if discovered != covered:
        raise ValueError(f"Source coverage changed: missing={discovered-covered}, absent={covered-discovered}")
    output_dir.mkdir(parents=True, exist_ok=True)
    translations_path.parent.mkdir(parents=True, exist_ok=True)
    (output_dir / 'Forever_Reputations.lua').write_text('\n'.join(outputs), encoding='utf-8')
    translations_path.write_text(json.dumps(exports, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    if migration_path is not None:
        migration_path.parent.mkdir(parents=True, exist_ok=True)
        migration_path.write_text(json.dumps(migration, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return len(outputs)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True, help='Directory containing the reviewed .guide data')
    parser.add_argument('--output', type=Path, default=ROOT / 'Routes/Forever/Reputation')
    parser.add_argument('--translations', type=Path,
                        default=LOCALIZATION_ROOT / 'forever-reputation-translations.json')
    parser.add_argument('--key-migration', type=Path, default=ROOT / '.cache/reputation-key-migration.json')
    args = parser.parse_args()
    count = build(args.source, args.output, args.translations, args.key_migration)
    print(f"Wrote {count} reputation routes; shared manifests and addon locales were not modified.")


if __name__ == '__main__':
    main()
