local env = dofile("tests/lua/route_ui_test_env.lua")
local createFrame = CreateFrame
function CreateFrame(kind, name, parent, template)
    local frame = createFrame(kind, name, parent, template)
    if template == "ObjectiveTrackerContainerHeaderTemplate" then
        frame.Text, frame.MinimizeButton = env.widget(frame), env.widget(frame)
    end
    return frame
end
dofile("APR-Core/utils/Utils.lua")
dofile("APR-Core/features/group/Party.lua")
APR.settings.profile.receiveGroupData = true
local now, tickers, completed, sent = 0, {}, {}, {}
function GetTime() return now end
C_Timer = { NewTicker = function(_, callback)
    local ticker = { callback = callback, Cancel = function(self) self.cancelled = true end }
    tickers[#tickers + 1] = ticker
    return ticker
end }
function APR.party:UpdateGroupListing(message) completed[#completed + 1] = message end
local party = APR.party
party:HandleMessageFragment("shared|2|2|B", "one")
party:HandleMessageFragment("shared|2|2|D", "two")
party:HandleMessageFragment("shared|2|2|B", "one")
party:HandleMessageFragment("shared|1|2|A", "one")
party:HandleMessageFragment("shared|1|2|C", "two")
assert(#completed == 2 and completed[1] == "AB" and completed[2] == "CD")
assert(not next(party.incomingFragments) and not next(party.fragmentExpiry))
assert(tickers[1].cancelled and not party.fragmentCleanupTicker)
for _, malformed in ipairs({ "bad", "id|x|2|x", "id|0|2|x", "id|3|2|x", "id|1|0|x",
    "id|1|999999999999999|x", "id|1|2|" .. string.rep("x", 181) }) do
    party:HandleMessageFragment(malformed, "one")
end
assert(not next(party.incomingFragments))
party:HandleMessageFragment("expired|1|2|a", "one")
now = 11
tickers[2].callback()
assert(not next(party.incomingFragments) and tickers[2].cancelled)
party:HandleMessageFragment("conflict|1|2|a", "one")
party:HandleMessageFragment("conflict|2|3|b", "one")
assert(#completed == 2, "Conflicting totals cannot publish an incomplete snapshot")
party:HandleMessageFragment("conflict|2|2|b", "one")
assert(completed[3] == "ab")
APR.settings.profile.receiveGroupData = false
party:HandleMessageFragment("disabled|1|2|x", "one")
assert(not next(party.incomingFragments))
APR.settings.profile.receiveGroupData = true
C_ChatInfo = { SendAddonMessage = function(_, message) sent[#sent + 1] = message end }
local payload = string.rep("serialized|data", 70)
APR:SendAddonMessageSplit("APRPartyData", payload, "PARTY")
for i = #sent, 1, -1 do
    assert(#sent[i] <= 255)
    party:HandleMessageFragment(sent[i], "roundtrip")
end
assert(completed[4] == payload)
print("Party: sender isolation, out-of-order/duplicate fragments, expiry, invalid headers and wire roundtrip passed")
