# Azeroth Pilot Reloaded - AI Coding Agent Instructions

## Project Overview
APR is a World of Warcraft addon that provides automated leveling guidance through a quest routing system. It's a continuation of the legacy Azeroth Auto Pilot addon, built on the Ace3 framework with Lua.

## Architecture

### Core Components
- **APR-Core/Core.lua**: Main initialization using Ace3's `AceAddon-3.0`. Sets up the `APR` global table with character data, settings, and route lists
- **APR-Core/Event.lua**: Event-driven system using WoW's event registration (`QUEST_ACCEPTED`, `QUEST_COMPLETE`, etc.)
- **APR-Core/QuestHandler.lua**: Route progression logic that reads `APR.RouteQuestStepList` and updates `APRData[APR.PlayerID][APR.ActiveRoute]`
- **Routes/**: Expansion-specific leveling routes organized by faction and zone

### Data Flow
1. Routes are loaded from `Routes/*.lua` files into `APR.RouteQuestStepList[routeName]`
2. Current step tracked via `APRData[APR.PlayerID][APR.ActiveRoute]` (numeric index)
3. `APR:UpdateStep()` processes the current step and checks completion conditions
4. Arrow, UI frames, and map markers updated via `APR:SendMessage("APR_MAP_UPDATE")`

### Key Global Tables
- `APRData[playerID]`: Per-character persistent data (current step, completed zones, custom paths)
- `APRSettings`: Addon configuration via AceDB
- `APR.RouteQuestStepList[routeName]`: Array of step tables with action definitions

## Step System

Routes are arrays of step tables. Each step can contain:
- **Quest actions**: `PickUp`, `Done` (turn in), `Qpart` (objectives), `DropQuest`
- **Movement**: `Coord` (coordinates), `Waypoint` (intermediate point), `Range` (completion radius)
- **World interactions**: `GetFP` (flight path), `SetHS` (hearthstone), `UseFlightPath`
- **Items/Spells**: `UseItem`, `UseSpell`, `Button` (quest item keybind)
- **NPCs**: `GossipOptionIDs`, `DenyNPC`, `Emote`
- **Special**: `Scenario`, `Treasure`, `LootItem`, `BuyMerchant`, `Group`

Example step structure:
```lua
{
    PickUp = { 28713 },  -- Quest ID(s) to accept
    Coord = { x = 830.4, y = 10313.2 },  -- Map coordinates
    _index = 1,  -- Step number
}
```

## Development Patterns

### Module System
All features use `APR:NewModule("Name")` pattern from Ace3:
```lua
APR.moduleName = APR:NewModule("ModuleName")
function APR.moduleName:FunctionName() end
```

### Settings Access
Settings via `APR.settings.profile.settingName`. Never modify `SettingsDB` directly.

### Event Registration
Events registered in `APR-Core/Event.lua` using the `events` table. Callbacks defined in `APR.event.functions[tag]`.

### Debug Output
Use `APR:Debug("message", data)` for debug logging (controlled by `APR.settings.profile.debug`).

### WoW API Compatibility
Check for both retail and classic APIs:
```lua
local IsSpellKnown = C_SpellBook.IsSpellKnown or _G.IsSpellKnown
```

### Localization
All user-facing text through `LibStub("AceLocale-3.0"):GetLocale("APR")`:
```lua
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
print(L["COMMAND_LIST"])
```

## File Structure

### Loading Order (APR.toc)
1. Libraries (`APR-Core/libs/embeds.xml`)
2. Locales (`APR-Core/locales/locales.xml`)
3. Core initialization (`APR-Core/Core.lua`)
4. Utilities and data models
5. Feature modules (Config, QuestHandler, Arrow, etc.)
6. Routes (`Routes/RouteList.xml`)

### Adding New Routes
1. Create file in appropriate `Routes/{Expansion}/` directory
2. Define route as `APR.RouteQuestStepList["routeName"] = { ... }`
3. Add `<Script file="Routes/..."/>` to `Routes/RouteList.xml`
4. Register in `APR-Core/data/routes/{Faction}Routes.lua`

### Adding New Settings
1. Add default value in `APR-Core/Config.lua` `settingsDBDefaults.profile`
2. Create UI options in `createBlizzOptions()` function
3. Access via `APR.settings.profile.newSetting`

## Common Tasks

### Testing Changes
- Use `/apr debug` to enable debug logging
- Use `/apr status` to check addon state
- `/apr reset` resets current route progress
- `/apr forcereset` wipes all character data (requires `/reload`)

### Route Development
- Coordinates are in-game world coordinates (not 0-100 ranges)
- `_index` field required for step ordering
- Test with both `autoAccept` enabled/disabled
- Use `Range` for area objectives, omit for exact points

### UI Frames
- All frames support lock/unlock, scale, and position saving
- Frame anchors stored in `APR.settings.profile.{frameName}Frame`
- Use `APR.Color` table for consistent theming

### Party Sync
- Uses WoW's C_ChatInfo addon channels (`APRPartyRequest`, `APRPartyData`, `APRPartyDelete`)
- Messages serialized with AceSerializer, split for size limits
- See `APR-Core/Party.lua` for protocol

## Critical Conventions

1. **Never use `_G` variables without checking WoW version compatibility**
2. **Always validate step existence before accessing**: `if step and step.Property then`
3. **Quest IDs must be numbers, not strings**
4. **Coordinates use `{x = number, y = number}` format**
5. **Route names use format**: `"{level}-{zoneName}{Faction}"` (e.g., `"57-ShadowglenNightElf"`)
6. **Player identification**: `APR.PlayerID` = `"PlayerName-GUIDHash"`

## Build & Distribution
- Version managed via `## Version: @project-version@` in `.toc` (replaced during packaging)
- Supports multiple WoW interface versions (see `## Interface` in `.toc`)
- No build step required - Lua files loaded directly by WoW client
- Test by symlinking to `World of Warcraft/_retail_/Interface/AddOns/APR/`

## Useful Commands
```bash
# Search for quest ID usage in routes
grep -r "PickUp = { 28713 }" Routes/

# Find all step types in a route file
grep -E "PickUp|Done|Qpart|GetFP|SetHS" Routes/Vanilla/Kalimdor_Alliance.lua

# Check locale key existence
grep "COMMAND_LIST" APR-Core/locales/*.lua
```
