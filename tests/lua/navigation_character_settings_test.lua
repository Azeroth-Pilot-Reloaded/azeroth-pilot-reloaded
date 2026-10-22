local fixture = dofile("tests/lua/navigation_fixture.lua")
APRNavigationCharacterSettings = nil
local data = fixture:Load()
assert(APRNavigationCharacterSettings == nil, "Manifest loading must not initialize SavedVariables")
local settings = data:GetCharacterSettings()
assert(type(settings) == "table")
settings.housingExitLocation = { mapId = 0, pos = { x = 10, y = 20, z = 30 }, isUI = false }
assert(data:GetCharacterSettings() == settings, "Character settings must remain stable")
assert(data:GetCharacterSettings().housingExitLocation.pos.x == 10)
print("Navigation character settings: delayed initialization and persistence passed")
