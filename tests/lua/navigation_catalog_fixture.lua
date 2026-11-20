-- Load the library and synthetic actions without changing mocked client globals.
local environment = {
    assert = assert,
    error = error,
    ipairs = ipairs,
    pairs = pairs,
    next = next,
    type = type,
    tonumber = tonumber,
    tostring = tostring,
    select = select,
    pcall = pcall,
    xpcall = xpcall,
    unpack = unpack,
    rawget = rawget,
    rawset = rawset,
    setmetatable = setmetatable,
    getmetatable = getmetatable,
    math = math,
    string = string,
    table = table,
    strmatch = string.match,
}
environment._G = environment
local function loadModule(path)
    local chunk = assert(loadfile(path))
    setfenv(chunk, environment)
    return chunk()
end
loadModule("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
local root = "APR-Core/libs/LibAPRNavigation-1.0/"
dofile("tests/lua/manifest_fixture.lua")(root .. "LibAPRNavigation.xml", {
    load = loadModule,
    skip = function(path) return path:find("/Data/", 1, true) ~= nil end,
})
local Lib = environment.LibStub("LibAPRNavigation-1.0")
for profile, catalog in pairs(dofile("tests/lua/navigation_travel_action_test_catalog.lua")) do
    Lib:RegisterData(profile, "fixture", catalog)
end
return Lib
