-- Load the real reusable engine without changing an APR test's AceLocale mock.
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
setmetatable(environment, { __index = function(_, key)
    error("Unexpected engine global dependency: " .. tostring(key))
end })
loadModule("APR-Core/libs/LibAPRNavigation-1.0/Core.lua")
loadModule("APR-Core/libs/LibAPRNavigation-1.0/Search.lua")
return environment.LibStub("LibAPRNavigation-1.0")
