local env = dofile("tests/lua/route_ui_test_env.lua")
local L = dofile("tests/lua/localization_test_env.lua")
local timers, loggedIn, petBattle = {}, true, false
C_Timer = {After = function(_, callback) timers[#timers + 1] = callback end}
local function flush()
    local current = timers; timers = {}
    for _, callback in ipairs(current) do callback() end
end
function IsLoggedIn() return loggedIn end
function APR:IsPetBattleActive() return petBattle end
function APR:RegisterSupportedEvent(frame, event) frame:RegisterEvent(event) end
function env.methods:UnregisterAllEvents() self.unregistered = true end
function env.methods:SetClampRectInsets(...) self.clampInsets = {...} end
function env.methods:CreateMaskTexture() return env.widget(self) end
function env.methods:AddMaskTexture(mask) self.mask = mask end
function env.methods:SetTexCoord(...) self.texCoords = {...} end
UIParent:SetSize(1280, 900)
local hide = env.methods.Hide
function env.methods:Hide()
    local shown = self:IsShown(); hide(self)
    if shown and self.scripts.OnHide then self.scripts.OnHide(self) end
end
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
local positions = {}
local windowLib = {
    RegisterConfig = function(frame, storage) positions[frame] = storage end,
    SavePosition = function(frame)
        local storage = positions[frame]
        storage.point, storage.x, storage.y = frame.point[1], frame.point[4] or 0, frame.point[5] or 0
    end,
    RestorePosition = function(frame)
        local storage = positions[frame]
        frame:ClearAllPoints()
        frame:SetPoint(storage.point, UIParent, storage.point, storage.x, storage.y)
    end,
}
function LibStub(name, ...)
    if name == "LibWindow-1.1" then return windowLib end
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
function env.methods:SetTexture(path) self.texture = path end
local panel = APR.ReleaseNotesPanel:Create(UIParent)
assert(not panel.banner and panel.preferences.point[1] == "TOPRIGHT",
    "Release notes in Options start with preferences and leave the image out")
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

-- Startup must open a standalone, themed reader without opening AceConfig or the workspace.
dofile("APR-Core/ui/panels/ReleaseNotesWindow.lua")
local window = APR.ReleaseNotesWindow
local visits, resumed = 0, 0
APR.Workspace = {Show = function(_, page, section) assert(page == "options" and section == "changelog"); visits = visits + 1 end}
APR.LayoutEditor = {firstUsePending = true, QueueOnboarding = function() resumed = resumed + 1 end}
UIParent:SetSize(2048, 1152)
APR.version, APR.settings.profile.lastRecordedVersion, APR.settings.profile.showChangeLog = "7.0.0", "6.9.0", true
loggedIn = false
APR.changelog:OnInit()
flush()
assert(window.pending and not window.frame and APR.settings.profile.lastReleaseNotesVersion == "",
    "Loading the addon cannot consume a version before the player can see its notes")
APR.settings.profile.lastRecordedVersion = APR.version
loggedIn = true; UIParent:Hide()
window.watcher.scripts.OnEvent(); flush()
assert(window.pending and not window.frame, "The startup window waits for UIParent to become visible")
UIParent:Show()
window.watcher.scripts.OnEvent(); window.watcher.scripts.OnEvent(); flush()
assert(window.frame:IsShown() and visits == 0 and opens == 2 and window.frame:GetFrameStrata() == "DIALOG",
    "A version change shows a dedicated window even on first use, without opening Options")
assert(math.abs(window.frame:GetWidth() - 655.36) < 0.001 and math.abs(window.frame:GetHeight() - 806.4) < 0.001
    and window.frame.point[1] == "CENTER" and window.frame.point[4] == 0
    and math.abs(window.frame.point[5] - 74.88) < 0.001,
    "Default size and upper-centered placement match the reference proportions at any UI scale")
local position = APR.settings.profile.uiWindows.APRReleaseNotesWindow
assert(position.width == window.frame:GetWidth() and position.height == window.frame:GetHeight()
    and position.y == window.frame.point[5], "The initial geometry is saved even if the UI reloads before closing the reader")
assert(APR.settings.profile.lastReleaseNotesVersion == APR.version and not window.pending,
    "The notes are acknowledged only after they are displayed, regardless of route version writes")
assert(window.banner.image.texture == "Interface\\AddOns\\APR\\APR-Core\\assets\\header.blp")
assert(window.banner == window.frame.header and not window.frame.logo and not window.banner.Text:IsShown(),
    "Artwork replaces the entire title bar without a separate title or medallion")
assert(window.banner:GetParent() == window.frame and window.banner.point[1] == "TOPRIGHT"
    and window.banner.point[2] == window.frame and window.banner.point[4] == 0
    and window.banner.point[5] == window.frame:GetWidth() * 18 / 1024 + 7,
    "The artwork reaches both outer window edges while retaining the medallion overhang")
assert(not window.frame.close:IsShown() and window.frame.close.enabled == false and window.close:IsShown(),
    "The header cross is hidden and disabled; the bottom Close button remains available")
assert(window.reader.notes.title:GetText() == "UI_RELEASE_WINDOW_TITLE",
    "The release title belongs to the notes beneath the illustrated header")
window.frame:SetWidth(834); window.frame.scripts.OnSizeChanged(window.frame)
assert(window.banner:GetHeight() == 208.5, "The full-width header retains the artwork's 4:1 aspect ratio on resize")
assert(window.banner.point[5] == 21.66015625 and window.frame.clampInsets[3] == 22.66015625,
    "Resizing scales the circle overhang and includes it in screen clamping")
local art = window.banner.artwork
assert(art.left:GetWidth() == 8 and art.left:GetHeight() == 8 and art.right:GetWidth() == 8
    and art.right.mask.texture:find("rounded%-fill%-top%-right%.tga$")
    and not art.right.mask.texCoords and art.left.mask.texture:find("rounded%-fill%.tga$"),
    "The upper corners use correctly oriented eight-unit masks without reversing MaskTexture UVs")
assert(not art.below.mask and not art.above.mask and art.below.texCoords[4] == 1
    and art.above.texCoords[3] == 0, "The lower corners and protruding medallion remain uncut")
window.frame:SetWidth(1100); window.frame.scripts.OnSizeChanged(window.frame)
assert(art.left:GetWidth() == 8 and art.right:GetWidth() == 8 and art.below:GetWidth() == 1100,
    "Resizing preserves the exact radius and covers the complete banner width")
assert(art.above.texCoords[4] == art.center.texCoords[3] and art.center.texCoords[4] == art.below.texCoords[3],
    "The original artwork remains continuous across every tile")
local count, fonts = env.frames(), env.fonts()
APR.changelog:OnInit()
assert(env.frames() == count and env.fonts() == fonts, "Repeated initialization cannot duplicate the version prompt")
local row = window.reader.rows[1]
L["New Changelog"] = "v7.0.1\n# Fixes\n- Another fix"
APR.changelog:SetChangeLog()
assert(window.reader.rows[1] == row and row:GetText() == "v7.0.1", "The standalone reader reuses and refreshes the shared formatter")
window.frame:ClearAllPoints()
window.frame:SetPoint("CENTER", UIParent, "CENTER", 45, 30)
window.options.scripts.OnClick()
assert(not window.frame:IsShown() and visits == 1 and resumed > 0, "Revisit is an explicit action into Options")
APR.settings.profile.lastRecordedVersion = APR.version
APR.changelog.startupVersion = nil
APR.changelog:OnInit()
assert(not window.frame:IsShown(), "Unchanged versions do not open release notes")
APR.settings.profile.lastRecordedVersion, APR.settings.profile.showChangeLog = "old", false
APR.version = "7.0.1"
APR.changelog:OnInit(); flush()
assert(not window.frame:IsShown() and not window.pending and APR.settings.profile.lastReleaseNotesVersion == "7.0.0",
    "The existing show-patch-notes preference remains authoritative even after an upgrade")
APR.settings.profile.showChangeLog = true
APR.version = "7.1.0"
env.setCombat(true); APR.changelog:OnInit(); flush()
assert(window.pending and not window.frame:IsShown(), "Startup during combat defers the standalone window")
APR.settings.profile.lastRecordedVersion = APR.version
env.setCombat(false); window.watcher.scripts.OnEvent(); flush()
assert(window.frame:IsShown() and not window.pending and visits == 1,
    "Combat deferral survives the normal saved-version update and never opens Options")
print("Startup release notes: standalone reader, options without masthead, version gating, reuse, combat and explicit revisit passed")

-- An upgrade not displayed before disconnect must survive the route version update.
window:Hide()
APR.version = "7.2.0"; loggedIn = false
APR.changelog:OnInit(); flush()
APR.settings.profile.lastRecordedVersion = APR.version
assert(window.pending and APR.settings.profile.lastReleaseNotesVersion == "7.1.0")
window:Hide() -- Tear down the old session while retaining the saved profile.
APR.changelog.startupVersion = nil
dofile("APR-Core/ui/panels/ReleaseNotesWindow.lua")
window = APR.ReleaseNotesWindow
APR.changelog:OnInit(); petBattle, loggedIn = true, true; flush()
assert(window.pending and not window.frame and window:IsBlockingOnboarding(),
    "Unread notes survive reconnecting and defer through pet battles")
petBattle = false
window.watcher.scripts.OnEvent(); flush()
assert(window.frame:IsShown() and APR.settings.profile.lastReleaseNotesVersion == "7.2.0" and visits == 1)
assert(window.frame:GetWidth() == 1100 and window.frame.point[4] == 45 and window.frame.point[5] == 30,
    "Custom resizing and placement survive reconnecting instead of being replaced by the defaults")
window.close.scripts.OnClick()
assert(not window.frame:IsShown(), "The bottom Close button still dismisses the release reader")
window:Hide(); APR.changelog.startupVersion = nil
APR.changelog:OnInit(); flush()
assert(not window.frame:IsShown() and not window.pending, "Read notes stay closed on subsequent reloads")

window:Hide()
APR.settings.profile.lastReleaseNotesVersion = nil
APR.settings.profile.lastRecordedVersion = APR.version
APR.changelog.startupVersion = nil
APR.changelog:OnInit(); flush()
assert(window.frame:IsShown(), "Legacy route version writes cannot suppress the first dedicated release window")
window:Hide(); APR.changelog.startupVersion = nil
APR.changelog:OnInit(); flush()
assert(not window.frame:IsShown(), "Migration displays the current release only once")
print("Startup release notes: login/UI readiness, unread version persistence, reconnect, pet battle and appearance priority passed")
