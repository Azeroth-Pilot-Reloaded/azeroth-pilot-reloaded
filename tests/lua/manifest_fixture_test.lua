local loadManifest = dofile("tests/lua/manifest_fixture.lua")
local documents = {
    ["fixture/Root.xml"] = '<Ui><Script file="base.lua"/><Include file="Client_[Game].xml"/></Ui>',
    ["fixture/Client_Standard.xml"] = '<Ui/>',
    ["fixture/Client_Camelot.xml"] = '<Ui><Include file="nested/Child.xml"/></Ui>',
    ["fixture/nested/Child.xml"] = '<Ui><Script file="module.lua"/><Include file="../Data/catalog.xml"/></Ui>',
    ["fixture/nested/../Data/catalog.xml"] = '<Ui><Script file="record.lua"/></Ui>',
}
local loaded = {}
local function run(game, skip)
    loaded = {}
    loadManifest("fixture/Root.xml", {
        game = game, read = function(path) return assert(documents[path], path) end,
        load = function(path) loaded[#loaded + 1] = path end, skip = skip,
    })
end
run("Standard")
assert(#loaded == 1 and loaded[1] == "fixture/base.lua")
run("Camelot")
assert(#loaded == 3 and loaded[2] == "fixture/nested/module.lua"
    and loaded[3] == "fixture/nested/../Data/record.lua")
run("Camelot", function(path) return path:find("/Data/", 1, true) ~= nil end)
assert(#loaded == 2 and loaded[2] == "fixture/nested/module.lua")
print("Manifest fixture: client selection, ordered nested includes and synthetic-data filters passed")
