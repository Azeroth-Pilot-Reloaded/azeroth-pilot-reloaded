"""Load route declarations without WoW APIs or access to OS/Python facilities."""

from dataclasses import dataclass
from pathlib import Path

from lupa.lua51 import LuaRuntime, lua_type


ROOT = Path(__file__).resolve().parents[2]


def plain(value, depth=0):
    if depth > 40:
        raise ValueError("Route data is cyclic or nested too deeply")
    if lua_type(value) == "table":
        return {plain(k, depth + 1): plain(v, depth + 1) for k, v in value.items()}
    if lua_type(value) is not None:
        raise ValueError(f"Route data cannot contain a Lua {lua_type(value)}")
    return value


@dataclass
class RouteCatalog:
    routes: dict
    sources: dict
    enums: dict
    profiles: set


def load_routes(paths=None):
    runtime = LuaRuntime(unpack_returned_tuples=True, register_eval=False, register_builtins=False)
    runtime.execute('''
        local locale = setmetatable({}, {__index = function(_, key) return key end})
        function LibStub() return {GetLocale = function() return locale end} end
        APR = {}
    ''')
    for name in ("APR-Core/data/models/Enums.lua", "APR-Core/data/models/Classes.lua",
                 "APR-Core/config/LevelProfiles.lua"):
        runtime.execute((ROOT / name).read_text(encoding="utf-8"), name="@" + name)
    enum_names = ("CATEGORIES", "EXPANSIONS", "PREFAB_TYPES", "GAME_VERSIONS", "RACES",
                  "Classes", "Specs", "EVENTS", "REPUTATION_TYPE", "REPUTATION_STANDING")
    enums = {name: plain(runtime.globals().APR[name]) for name in enum_names}
    profiles = set(runtime.globals().APR.LevelRequirementProfiles.keys())
    environment, registry, execute = runtime.execute('''
        local registry = {}
        local function unknown(_, key) error("Unknown route constant/API: " .. tostring(key), 2) end
        local apr = {DelveRouteRegistry = {}, worldCoordinateConverter = {}}
        for _, name in ipairs({"CATEGORIES", "EXPANSIONS", "PREFAB_TYPES", "GAME_VERSIONS",
            "RACES", "Classes", "Specs", "EVENTS", "REPUTATION_TYPE", "REPUTATION_STANDING"}) do
            apr[name] = setmetatable(APR[name], {__index = unknown})
        end
        function apr.worldCoordinateConverter:ConvertMapCoordinate(map, x, y)
            assert(type(map) == "number" and map > 0 and map % 1 == 0, "Invalid source map ID")
            assert(type(x) == "number" and x >= 0 and x <= 100, "Invalid source map x")
            assert(type(y) == "number" and y >= 0 and y <= 100, "Invalid source map y")
            return {x = x, y = y}
        end
        apr.RouteQuestStepList = setmetatable({}, {
            __index = registry,
            __newindex = function(_, key, value)
                assert(registry[key] == nil, "Duplicate route key: " .. tostring(key))
                registry[key] = value
            end
        })
        setmetatable(apr, {__index = unknown})
        local env = setmetatable({APR = apr, LibStub = LibStub, ipairs = ipairs, pairs = pairs,
            type = type, tostring = tostring, tonumber = tonumber, table = {insert = table.insert},
            math = {min = math.min, max = math.max}, string = {format = string.format}},
            {__index = unknown, __newindex = unknown})
        local function execute(source, name)
            local chunk, err = loadstring(source, name)
            if not chunk then error(err) end
            setfenv(chunk, env)
            debug.sethook(function() error("Route declaration instruction limit exceeded") end, "", 10000000)
            local ok, result = pcall(chunk)
            debug.sethook()
            if not ok then error(result) end
        end
        return env, registry, execute
    ''')
    sources = {}
    for path in sorted(paths if paths is not None else (ROOT / "Routes").rglob("*.lua")):
        name = path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else str(path)
        execute(path.read_text(encoding="utf-8-sig"), "@" + name)
        for key in registry.keys():
            sources.setdefault(key, name)
    return RouteCatalog(plain(registry), sources, enums, profiles)
