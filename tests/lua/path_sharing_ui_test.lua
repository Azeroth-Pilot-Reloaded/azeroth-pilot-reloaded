-- Real APR controls retain catalogue shortcuts and independent header actions.
local env = dofile("tests/lua/route_browser_test_env.lua")
GROUP = "Synthetic group"
local shared, route, recipient
local grouped = false
APR.PathSharing = { peers = { Peer = true } }
function APR.PathSharing:IsAvailable() return grouped end
function APR.PathSharing:Roster() return { Peer = "Peer", Old = "Older peer" } end
function APR.PathSharing:SharePath(target) shared, recipient = true, target end
function APR.PathSharing:ShareRoute(key, target) route, recipient = key, target end
local units = { party1 = "Peer", party2 = "Old" }
APR.PartyProtocol = { PlayerKey = function(value) return value end, UnitName = function(unit) return units[unit] end }
local nativeMenu = dofile("tests/lua/native_member_menu_test_env.lua")
PartyScreenPanel = CreateFrame("Frame", nil, UIParent)
PartyScreenPanel:SetWidth(250)
PartyFrameHeader = CreateFrame("Frame", nil, PartyScreenPanel)
PartyFrameHeader.MinimizeButton = CreateFrame("Button", nil, PartyFrameHeader)
PartyFrameHeader.Text = PartyFrameHeader:CreateFontString()
local drags = 0
PartyFrameHeader:SetScript("OnMouseDown", function() drags = drags + 1 end)
dofile("APR-Core/features/group/PathSharingUI.lua")
local headerButton = assert(PartyFrameHeader.SharePathButton)
assert(PartyFrameHeader:GetWidth() == 250 and headerButton:GetWidth() == 22)
assert(not headerButton:IsEnabled(), "The header share button starts disabled when solo")
grouped = true
APR.PathSharing:RefreshShareControls()
assert(headerButton:IsEnabled())
headerButton.scripts.OnClick()
assert(shared and recipient == nil)
PartyFrameHeader.scripts.OnMouseDown()
assert(drags == 1, "The new button must not replace the header drag handler")

local browser = APR.RouteBrowser
browser:Show()
browser:Refresh(true)
browser.selectedKey = "first"
browser:RefreshShareButton()
assert(not browser.shareRoute:IsEnabled(), "Official routes are not sent as Recorder definitions")
APRData.CustomRoute = { recorded = { label = "Recorded", steps = { { Note = "recorded action" } } } }
browser.selectedKey = "recorded"
browser:RefreshShareButton()
assert(browser.shareRoute:IsEnabled())
grouped = false
APR.PathSharing:RefreshShareControls()
assert(not browser.shareRoute:IsEnabled() and not headerButton:IsEnabled(), "Leaving a group disables both controls")
grouped = true
APR.PathSharing:RefreshShareControls()
assert(browser.shareRoute:IsEnabled() and headerButton:IsEnabled(), "Joining a group restores the selected custom route action")
browser.shareRoute.scripts.OnClick()
local dialog = assert(APR.UI.selectionDialog)
local peer, old
for _, option in ipairs(dialog.options) do
    if option.value == "Peer" then peer = option end
    if option.value == "Old" then old = option end
end
assert(peer and peer.enabled and old and old.enabled == false)
dialog:Choose(peer)
assert(route == "recorded" and recipient == "Peer")

-- Pooled catalogue rows retain their right-click add/remove contract.
local row = browser.list.active[1]
local actions = {}
function APR.RouteCatalog:ChangePath(record, action) actions[#actions + 1] = action end
row.scripts.OnClick(row, "RightButton")
assert(actions[1] == "add")
browser.selectedKey = "first"
browser:RefreshShareButton()
assert(not browser.shareRoute:IsEnabled())
-- Native party actions stay owned by Blizzard; APR only appends sharing.
APR.PathSharing:ShowMemberMenu("Peer")
assert(nativeMenu.which == "PARTY" and nativeMenu.context.unit == "party1")
assert(#nativeMenu.root.nativeActions == 3 and #nativeMenu.root.additions == 1)
assert(nativeMenu.root.divider and nativeMenu.root.additions[1].enabled)
recipient = nil
nativeMenu.root.additions[1].callback()
assert(recipient == "Peer")
APR.PathSharing:ShowMemberMenu("Old")
assert(nativeMenu.context.unit == "party2" and not nativeMenu.root.additions[1].enabled)
recipient = nil
nativeMenu.root.additions[1].callback()
assert(recipient == nil, "An incompatible peer cannot receive a shared path")

local vanillaMenu = UnitPopup_OpenMenu("PARTY", { unit = "party1" })
assert(#vanillaMenu.additions == 0, "Ordinary WoW party menus are not changed")
units.party1, units.party2 = "Old", "Peer"
APR.PathSharing:ShowMemberMenu("Peer")
assert(nativeMenu.context.unit == "party2", "Resolve the unit again after a roster reorder")
local pendingShare = nativeMenu.root.additions[1].callback
grouped = false
pendingShare()
assert(recipient == nil, "A stale menu cannot share after leaving the group")
grouped = true
local opened = nativeMenu.opened
units.party2 = "Peer-OtherRealm"
APR.PathSharing:ShowMemberMenu("Peer")
assert(nativeMenu.opened == opened, "Do not open a namesake's menu from a stale APR row")
units.party2 = "Peer"

local nativeOpen, nativeAPI = UnitPopup_OpenMenu, Menu
Menu, APR.PathSharing.memberMenuHooked = nil, nil
APR.PathSharing:ShowMemberMenu("Peer")
assert(nativeMenu.opened == opened, "Missing optional menu APIs remain a quiet no-op")
Menu = nativeAPI
UnitPopup_OpenMenu = nil
APR.PathSharing:ShowMemberMenu("Peer")
assert(nativeMenu.opened == opened)
UnitPopup_OpenMenu = nativeOpen

env.setCombat(true)
APR.PathSharing:ShowMemberMenu("Peer")
assert(not dialog:IsShown(), "Combat does not open a new share dialog")
assert(nativeMenu.opened == opened, "Combat does not open a native member menu")
print("Sharing UI: real header button, preserved drag, selected custom routes, compatible targets and existing shortcuts passed")
