# APR UI skins

APR registers its own controls in `SkinRegistry.lua` when they are created. This
includes anonymous popup buttons, route presets and reorder arrows, scrollbars,
image-preview controls, tracked buffs and the XP overlay. Registration is
idempotent, and changes requested during combat wait for `PLAYER_REGEN_ENABLED`.
Skinning never changes click handlers or secure item attributes.

ElvUI uses its Skins module. EllesmereUI uses the public
[`RegisterSkin` API](https://github.com/EllesmereGaming/EllesmereUI/blob/main/SKINNING_API.md),
including its per-addon enable switch and live theme updates. APR's own options
require a reload when switching skins. ElvUI takes precedence if both APR skin
options are enabled. EllesmereUI versions without `RegisterSkin` are ignored.

EllesmereUI supplies panel backgrounds, borders, fonts, teal header accents and
icon styling across APR windows. Quest titles, objectives and completion retain
their semantic colors using the EllesmereUI tracker palette. APR text sizes and
layout remain configurable. Theme changes refresh existing and future text;
relayout requested during combat waits until combat ends. Image previews use a
separate background surface so the panel skinner cannot fade their images.
ElvUI retains APR's existing panel background behavior.

## Automated checks

```sh
python tools/validation/run_lua_tests.py --skins-only
python tools/validation/run_lua_tests.py --xp-overlay-only
```

These use Lua 5.1 mocks; they do not replace an in-game rendering check.

## In-game checks

Repeat with neither UI addon enabled, with ElvUI, and with EllesmereUI:

1. Open route settings. Inspect the preset buttons, search field, custom-path
   scrollbar and up/down arrows. Add several routes and reorder them; the first
   up arrow and last down arrow must remain disabled.
2. Open a route suggestion and a selection popup. Check all nested choices and
   footer buttons, including choices created after the first opening.
3. Check rollback/skip, header collapse/expand, status export, changelog scrolling
   and image-preview close. The preview image and existing layout must remain intact.
4. With a usable XP item in the bags, check the bordered overlay header, drag it,
   reload and verify its position. Click the item and verify that the reminder
   disappears with the buff. New skin changes during combat apply after combat.
   The XP header should match APR's ObjectiveTracker headers. Close the overlay
   from its header or dismiss only War Mode with its row's close button. Verify
   these choices persist, including across alternative items for the same bonus.
   Restore the overlay and individual bonuses in APR's Current Step options.
5. Disable the APR skin option and reload. With EllesmereUI, also check its own
   per-addon switch and change its theme; registered controls should follow it.
6. If both UI addons are installed, disable APR's ElvUI skin and reload to select
   EllesmereUI. A control must never receive both skins in the same session.

ElvUI coverage implements
[issue #500](https://github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded/issues/500).
