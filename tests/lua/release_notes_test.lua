local env = dofile("tests/lua/route_ui_test_env.lua")
local L = dofile("tests/lua/localization_test_env.lua")
dofile("APR-Core/integrations/SkinRegistry.lua")
dofile("APR-Core/ui/foundations/Themes.lua")
dofile("APR-Core/ui/foundations/Widgets.lua")
dofile("APR-Core/ui/panels/ChangeLog.lua")
function APR:WrapTextWithAppearanceColor(text, _, role) return "<" .. role .. ">" .. text .. "</" .. role .. ">" end
local text = [=[v6.8.0 (2026-10-08)

# Features
- **Visible emphasis** and `Repair`.
  - Nested __item__ with ``**literal code**``.
- [Release](https://example.com/release)

## Details
> *Useful* information
\*literal stars\* and ~~old~~
```lua
local value = "**literal** |cffffff"
```
v6.8.1
]=]
local blocks = APR.changelog:ParseBlocks(text)
assert(blocks[1].kind == "version" and blocks[1].text == "v6.8.0 (2026-10-08)")
assert(blocks[2].kind == "heading" and blocks[2].text == "Features")
assert(blocks[3].text == "–  <accent>Visible emphasis</accent> and <accent>Repair</accent>.")
assert(blocks[4].indent > blocks[3].indent and blocks[4].text:find("<accent>**literal code**</accent>", 1, true))
assert(blocks[5].text:find("Release (https://example.com/release)", 1, true))
assert(blocks[6].kind == "heading" and blocks[6].indent > blocks[2].indent)
assert(blocks[7].kind == "quote")
assert(blocks[8].text == "*literal stars* and <muted>old</muted>")
assert(blocks[9].kind == "code" and blocks[9].text == 'local value = "**literal** ||cffffff"')
assert(blocks[10].kind == "version" and blocks[10].text == "v6.8.1", "A version without a date must not disappear")
assert(APR.changelog:ParseBlocks("```\nunclosed")[1].text == "unclosed")
assert(APR.changelog:ParseChangelogText(text):find("v6.8.1", 1, true))

-- Exercise panel lifecycle, selection and resizing without replacing the persisted setting callbacks.
local opens, released = 0, 0
local oldLib = LibStub
function LibStub(name, ...)
    if name == "AceConfigDialog-3.0" then return {Open = function(_, app, host)
        assert(app == "Notes"); opens = opens + 1; host.app = app
    end} end
    return oldLib(name, ...)
end
function APR.UI:SettingsHost(parent)
    return {frame = CreateFrame("Frame", nil, parent),
        ReleaseChildren = function() released = released + 1 end,
        SetUserData = function(self, key, value) self[key] = value end}
end
APR.github = "https://github.com/example/apr/"
L["New Changelog"], L["Prev Changelog"] = text, "v6.7.0\n# Fixes\n- Earlier release"
dofile("APR-Core/ui/panels/ReleaseNotesPanel.lua")
local panel = APR.ReleaseNotesPanel:Create(UIParent)
panel:Show("Notes")
assert(opens == 1 and #panel.rows > #blocks, "Both current and previous releases are shown")
assert(panel.link:GetText() == "https://github.com/example/apr/releases")
assert(panel.link:HasFocus() and panel.link.highlighted, "The release URL is selected immediately on opening")
panel.copy.scripts.OnClick()
assert(panel.link:HasFocus() and panel.link.highlighted, "Copy action selects the complete URL for Ctrl+C")
panel.link:SetText("Accidental edit")
panel.link.scripts.OnTextChanged(panel.link, true)
assert(panel.link:GetText() == panel.url, "Typing cannot change the canonical release URL")
panel.scroll:SetWidth(500); panel:Layout()
assert(panel.rows[4].point[4] > panel.rows[3].point[4], "Nested bullets remain indented after resize")
local firstRow = panel.rows[1]
panel:Hide()
assert(not panel.frame:IsShown() and released == 1 and not panel.link:HasFocus())
L["New Changelog"], L["Prev Changelog"] = "v7.0.0", ""
panel:Show("Notes")
assert(panel.rows[1] == firstRow and not panel.rows[2]:IsShown(), "Rows are reused and obsolete notes are hidden")
assert(panel.link:HasFocus() and panel.link.highlighted, "Reopening the page selects the link again")
assert(opens == 2)
print("Release notes: Markdown structure, literal code, both releases, URL selection and panel lifecycle passed")
