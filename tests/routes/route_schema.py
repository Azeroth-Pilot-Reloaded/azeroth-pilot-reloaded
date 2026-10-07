"""Strict declaration grammar shared by every route, independent of expansion.

Lua tables arrive as dicts (including arrays). Keep this contract in sync with
RouteManager, RouteUtils, RouteConditions, StepUtils and the action handlers.
Unknown fields are errors at every depth; adding an engine option requires an
explicit grammar rule here. This validates declarations, not quest story order.
"""

import math
import re


class InvalidRoute(ValueError):
    pass


def fail(path, message):
    raise InvalidRoute(f"{path}: {message}")


def scalar(description, predicate):
    def check(value, path):
        if not predicate(value):
            fail(path, f"expected {description}, got {value!r}")
    return check


def number(minimum=None, maximum=None, integer=False):
    return scalar("finite " + ("integer" if integer else "number") +
                  f" in [{minimum}, {maximum}]", lambda v:
                  type(v) in (int, float) and math.isfinite(v) and
                  (not integer or v == int(v)) and
                  (minimum is None or v >= minimum) and (maximum is None or v <= maximum))


ID = number(1, integer=True)
COUNT = number(0, integer=True)
NUMBER = number()
BOOL = scalar("boolean", lambda v: type(v) is bool)
TEXT = scalar("nonempty string", lambda v: isinstance(v, str) and bool(v.strip()))
SLOT = number(1, 19, integer=True)


def enum(values):
    values = tuple(values)
    return scalar("one of " + repr(values), lambda v: any(type(v) is type(x) and v == x for x in values))


def union(*rules):
    def check(value, path):
        errors = []
        for rule in rules:
            try:
                rule(value, path)
                return
            except InvalidRoute as error:
                errors.append(str(error))
        fail(path, "no supported form matched (" + "; ".join(errors) + ")")
    return check


def array(rule, minimum=0):
    def check(value, path):
        if not isinstance(value, dict) or any(type(k) is not int for k in value):
            fail(path, "expected an indexed Lua list")
        if set(value) != set(range(1, len(value) + 1)):
            fail(path, "list indexes must be contiguous starting at 1")
        if len(value) < minimum:
            fail(path, f"expected at least {minimum} entries")
        for index, item in value.items():
            rule(item, f"{path}[{index}]")
    return check


def mapping(key_rule, value_rule):
    def check(value, path):
        if not isinstance(value, dict):
            fail(path, "expected a Lua table")
        for key, item in value.items():
            key_rule(key, f"{path}.<key {key!r}>")
            value_rule(item, f"{path}[{key!r}]")
    return check


def obj(fields, required=(), choices=(), patterns=()):
    def check(value, path):
        if not isinstance(value, dict):
            fail(path, "expected a Lua object")
        for key in required:
            if key not in value:
                fail(path, f"missing required field {key}")
        for options in choices:
            if not any(key in value and value[key] is not False for key in options):
                fail(path, "requires one of " + ", ".join(options))
        for key, item in value.items():
            rule = fields.get(key)
            if rule is None and isinstance(key, str):
                rule = next((r for pattern, r in patterns if re.fullmatch(pattern, key)), None)
            if rule is None:
                fail(path, f"unknown field {key!r}")
            rule(item, f"{path}.{key}")
    return check


IDS = array(ID, 1)
OPERATOR = enum(("<", "<=", ">", ">=", "==", "~="))


class RouteSchema:
    def __init__(self, catalog):
        def constants(name):
            return enum(catalog.enums[name].values())

        level = union(number(1), enum(catalog.profiles),
                      obj({"level": ID, "xp": number(integer=True)}, required=("level", "xp")))
        reputation = obj({"factionID": ID, "level": ID, "type": constants("REPUTATION_TYPE")},
                         required=("factionID", "level"))
        item = obj({"itemID": ID, "quantity": ID}, required=("itemID",))
        class_value = enum((*catalog.enums["Classes"].values(),
                            *(key.upper().replace(" ", "") for key in catalog.enums["Classes"])))
        race = union(constants("RACES"), ID)
        equipped_stat = obj({"slot": SLOT, "stat": TEXT, "value": NUMBER,
                             "operator": OPERATOR, "precision": COUNT, "allowMissing": BOOL},
                            required=("slot", "stat", "value"))
        equipped_item = obj({"slot": SLOT, "itemID": ID, "invert": BOOL}, required=("slot",))
        self.condition_fields = {
            "Faction": enum(("Alliance", "Horde", "Neutral")),
            "Hardcore": BOOL, "AlliedRace": BOOL,
            "SkipForPrimaryProfessions": ID,
            "Race": union(race, array(race, 1)),
            "Class": union(class_value, array(class_value, 1)),
            "ClassNot": union(class_value, array(class_value, 1)),
            "ClassSpec": constants("Specs"), "Gender": enum((1, 2, 3)),
            "Event": constants("EVENTS"), "BeLvl": number(1),
            "Money": obj({"copper": COUNT, "operator": OPERATOR}, required=("copper",)),
            "VendorMoney": obj({"copper": COUNT, "operator": OPERATOR, "includeEquipped": BOOL,
                                "equippedSlots": array(SLOT, 1)}, required=("copper",)),
            "ItemCount": obj({"itemID": ID, "itemIDs": IDS, "count": COUNT,
                              "operator": OPERATOR, "includeBank": BOOL, "includeUsableToys": BOOL},
                             required=("count",), choices=(("itemID", "itemIDs"),)),
            "EquippedItemStat": union(equipped_stat, array(equipped_stat, 1)),
            "EquippedItem": union(equipped_item, array(equipped_item, 1)),
            "Collection": item,
            "Skill": obj({"skill": union(ID, TEXT), "skillID": ID, "name": TEXT,
                          "rank": COUNT, "operator": OPERATOR, "maximum": BOOL},
                         choices=(("skill", "skillID", "name"),)),
            "ReputationLevel": reputation, "SkipForReputation": reputation,
        }
        for name in "Level MinLevel MaxLevel SkipForLvl".split():
            self.condition_fields[name] = level
        for name in "Zones OnlyInZones SkipInZones".split():
            self.condition_fields[name] = IDS
        for name in ("InterfaceVersion InterfaceVersionExact HasAchievement DontHaveAchievement "
                     "HasAura DontHaveAura HasSpell IsQuestOnQuest IsQuestNotOnQuest "
                     "IsQuestCompleted IsQuestUncompleted").split():
            self.condition_fields[name] = ID
        for name in "DontHaveSpell IsQuestReadyForTurnIn".split():
            self.condition_fields[name] = union(ID, IDS)
        for name in ("IsOneOfQuestsCompleted IsOneOfQuestsUncompleted IsOneOfQuestsCompletedOnAccount "
                     "IsOneOfQuestsUncompletedOnAccount IsQuestsCompleted IsQuestsUncompleted "
                     "IsQuestsCompletedOnAccount IsQuestsUncompletedOnAccount").split():
            self.condition_fields[name] = IDS
        # Late binding makes conditions recursive without admitting step actions.
        condition = lambda value, path: self.condition(value, path)
        self.condition_fields.update(AnyOf=array(condition), AllOf=array(condition), Not=condition)
        self.condition = obj(self.condition_fields)
        route_conditions = {name: self.condition_fields[name] for name in (
            "AnyOf InterfaceVersion InterfaceVersionExact DontHaveSpell IsQuestReadyForTurnIn "
            "HasAchievement DontHaveAchievement Faction Race Class ClassNot Event AlliedRace "
            "IsQuestCompleted IsQuestUncompleted BeLvl ClassSpec Zones").split()}
        route_conditions.update(Level=number(1), MinLevel=number(1), MaxLevel=number(1))
        self.route_condition = obj(route_conditions)

        self.step_fields = dict(self.condition_fields)
        for name in ("ChromiePick DropQuest ExitTutorial GetFP GroupTask LearnProfession LeaveQuest "
                     "NpcDismount SetHS UseDalaHS UseFlightPath UseGarrisonHS UseHS WarMode Waypoint "
                     "DenyNPC MerchantNPC RaidIcon SpellTrigger Zone NodeID QuestLineSkip ExtraLine "
                     "Gossip Brewery SparringRing").split():
            self.step_fields[name] = ID
        for name in ("Bloodlust Boat DeathSkip Dontskipvid ExtraActionB InstanceQuest IsAdventureMap "
                     "IsCampaignQuest MountVehicle NoArrow NoAutoFlightMap NoAutoAccept NoAutoTurnIn "
                     "NonSkippableWaypoint ResetRoute RouteCompleted SingleWaypointDisplayDistance "
                     "SpecialETAHide UseGlider VehicleExit").split():
            self.step_fields[name] = BOOL
        for name in "Done DoneDB PickUp PickUpDB QpartDB WaypointDB LeaveQuests GossipOptionIDs".split():
            self.step_fields[name] = array(ID)
        for name in "Qpart QpartPart Fillers".split():
            self.step_fields[name] = mapping(ID, array(ID))
        for name in "Range ETA EmoteETA GossipETA".split():
            self.step_fields[name] = number(0)
        for name in "InVehicle PickedLoa".split():
            self.step_fields[name] = enum((1, 2))
        xy = obj({"x": NUMBER, "y": NUMBER}, required=("x", "y"))
        zone_aliases = {key: ID for key in ("Zone", "zone", "mapID", "MapID", "uiMapID", "UiMapID")}
        coord_entry = union(obj({"x": NUMBER, "y": NUMBER, **zone_aliases}, required=("x", "y")),
                            obj({"Coord": xy, **zone_aliases}, required=("Coord",)))
        multi_coord = union(array(coord_entry, 1), mapping(ID, coord_entry))
        objective = scalar("quest ID or quest-objective key", lambda v:
                           isinstance(v, str) and re.fullmatch(r"[1-9]\d*(?:-\d+)?", v) is not None)
        self.step_fields.update({
            "Name": TEXT, "Note": union(TEXT, array(TEXT, 1)), "PreviewImages": array(TEXT, 1),
            "_index": ID, "_comment": TEXT, "Grind": level,
            "Coord": union(xy, multi_coord), "Coords": multi_coord,
            "ZoneStepTrigger": obj({"x": NUMBER, "y": NUMBER, "Range": number(0)},
                                   required=("x", "y", "Range")),
            "Button": mapping(objective, ID), "SpellButton": mapping(objective, union(ID, TEXT)),
            "UseItem": obj({"itemID": ID, "questID": ID, "itemSpellID": ID}, required=("itemID",)),
            "UseSpell": obj({"spellID": ID, "questID": ID}, required=("spellID",)),
            "Treasure": obj({"questID": ID, "itemID": ID}, required=("questID",)),
            "Achievement": obj({"achievementID": ID, "criteriaID": ID, "criteriaIndex": ID, "questID": ID},
                               required=("achievementID",)),
            "Scenario": obj({"scenarioID": ID, "stepID": ID, "criteriaID": COUNT, "criteriaIndex": ID, "questID": ID},
                            required=("scenarioID", "stepID", "criteriaID", "criteriaIndex")),
            "Group": obj({"questID": ID, "Number": ID}, required=("questID", "Number")),
            "DroppableQuest": obj({"Qid": ID, "MobId": ID, "Text": TEXT}, required=("Qid", "MobId", "Text")),
            "Buffs": array(obj({"spellId": ID, "tooltipMessage": TEXT}, required=("spellId",)), 1),
            "LootMoney": obj({"copper": ID, "includeEquipped": BOOL, "equippedSlots": array(SLOT, 1)},
                             required=("copper",)),
            "Reputation": reputation,
            "SpellETA": obj({"spellID": ID, "itemID": ID, "seconds": number(0)},
                            required=("seconds",), choices=(("spellID", "itemID"),)),
            "Emote": obj({"emote": TEXT, "npcID": COUNT, "manual": BOOL}, required=("emote",)),
            "EquipItem": obj({"itemID": ID, "slot": SLOT}, required=("itemID", "slot")),
            "TameBeast": obj({"npcID": ID, "spellID": ID, "text": TEXT, "Text": TEXT}),
            "Repair": obj({"npcID": ID, "minDurability": number(0, 100)}, required=("npcID",)),
            "LearnSkill": obj({"spellID": ID, "spellIDs": IDS, "allAvailable": BOOL, "npcID": ID,
                               "text": TEXT, "Text": TEXT}, choices=(("spellID", "spellIDs", "allAvailable"),)),
        })
        for name in "TakePortal EnterInstance LeaveInstance EnterScenario DoScenario LeaveScenario".split():
            self.step_fields[name] = obj({"questID": ID, "mapID": ID}, required=("mapID",))
        self.step_fields["TakePortal"] = obj({"questID": ID, "mapID": ID}, choices=(("mapID", "questID"),))
        for name in "BuyMerchant LootItems".split():
            self.step_fields[name] = array(obj({"itemID": ID, "quantity": ID, "questID": ID},
                                               required=("itemID", "quantity") if name == "BuyMerchant" else ("itemID",)), 1)
        entry = union(ID, obj({"itemID": ID, "text": TEXT, "Text": TEXT}, required=("itemID",)))
        for name in "SellItems BankDeposit BankWithdraw DestroyItems".split():
            fields = {"items": array(entry, 1), "npcID": ID, "text": TEXT, "Text": TEXT}
            if name == "SellItems":
                fields["junk"] = BOOL
                fields["questID"] = ID
                fields["equippedSlots"] = array(SLOT, 1)
            self.step_fields[name] = union(array(entry, 1), obj(fields, choices=(tuple(
                ["items", "junk", "equippedSlots"] if name == "SellItems" else ["items"]),)))
        self.step = obj(self.step_fields, patterns=((r"ExtraLineText\d*", union(TEXT, array(TEXT, 1))),
                                                   (r"TrigText\d*", TEXT)))
        steps = array(self.step)
        scenario = obj({"label": TEXT, "scenarioID": ID, "index": ID, "steps": steps},
                       required=("scenarioID", "steps"))
        self.route_fields = {
            "category": constants("CATEGORIES"), "expansion": constants("EXPANSIONS"),
            "gameVersion": constants("GAME_VERSIONS"), "label": TEXT, "mapID": COUNT,
            "legacyLabels": array(TEXT, 1), "conditions": self.route_condition,
            "autoStartOnMap": BOOL, "notSkippable": BOOL, "hiddenFromSelection": BOOL, "temporary": BOOL,
            "sojournerAchievementID": ID, "delve": obj({}),
            "steps": union(steps, array(scenario, 1)), "scenarios": array(scenario),
            "parallelSteps": array(obj({"conditions": condition, "steps": array(self.step, 1)}, required=("steps",))),
            "requiredRoute": array(TEXT),
            "nextRoute": array(union(TEXT, obj({"route": TEXT, "conditions": condition}, required=("route",)))),
            "prefab": mapping(constants("PREFAB_TYPES"), union(NUMBER,
                              obj({"index": NUMBER, "conditions": condition}, required=("index",)))),
        }
        self.route = obj(self.route_fields, required=("label",), choices=(("steps", "scenarios"),))

    def validate(self, key, route):
        TEXT(key, "route key")
        self.route(route, key)
