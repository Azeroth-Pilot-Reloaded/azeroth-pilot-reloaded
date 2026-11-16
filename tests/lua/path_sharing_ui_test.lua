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
APR.PartyProtocol = { PlayerKey = function(value) return value end }
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
env.setCombat(true)
APR.PathSharing:ShowMemberMenu("Peer")
assert(not dialog:IsShown(), "Combat does not open a new share dialog")
print("Sharing UI: real header button, preserved drag, selected custom routes, compatible targets and existing shortcuts passed")
