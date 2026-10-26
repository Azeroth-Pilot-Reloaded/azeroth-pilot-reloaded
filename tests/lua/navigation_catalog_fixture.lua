-- Load the library and synthetic actions without changing mocked client globals.
local environment = {
    assert = assert, error = error, ipairs = ipairs, pairs = pairs, next = next,
    type = type, tonumber = tonumber, tostring = tostring, select = select,
    pcall = pcall, xpcall = xpcall, unpack = unpack, rawget = rawget, rawset = rawset,
    setmetatable = setmetatable, getmetatable = getmetatable,
    math = math, string = string, table = table, strmatch = string.match,
}
environment._G = environment
local function loadModule(path)
    local chunk = assert(loadfile(path))
    setfenv(chunk, environment)
    return chunk()
end
loadModule("APR-Core/libs/HereBeDragons/LibStub/LibStub.lua")
local root = "APR-Core/libs/LibAPRNavigation-1.0/"
local manifest = assert(io.open(root .. "LibAPRNavigation.xml"))
local xml = manifest:read("*a")
manifest:close()
for path in xml:gmatch('file="([^"]+)"') do
    if not path:match("^Data/") then loadModule(root .. path) end
end
local Lib = environment.LibStub("LibAPRNavigation-1.0")
for profile, catalog in pairs(dofile("tests/lua/navigation_travel_action_test_catalog.lua")) do
    Lib:RegisterData(profile, "fixture", catalog)
end
return Lib
