-- A native roster arrives asynchronously only while its display channel remains selected.
local Fixture = dofile("tests/lua/party_finder_test_env.lua")

local function New()
    local env = Fixture.New()
    env.population, env.selection, env.requested, env.loaded = 0, 2, 0, false
    function GetSelectedDisplayChannel() return env.selection end
    function SetSelectedDisplayChannel(index)
        env.selection = index
        if index == 3 then
            env.requested = env.requested + 1
            C_Timer.NewTimer(1, function()
                if env.selection ~= 3 then return end
                env.loaded, env.population = true, 4
                env:Event("CHANNEL_COUNT_UPDATE", 3, 4)
                env:Event("CHANNEL_ROSTER_UPDATE", 3, 4)
            end)
        end
    end
    local names = { "Local-Home", "First-Home", "Second-Home", "Third-Home" }
    C_ChatInfo.GetChannelRosterInfo = function(index, row)
        assert(index == 3)
        return env.loaded and names[row] or nil
    end
    local finder, channel = env.finder, APR.CommunicationChannel
    channel.addonTransport = "blocked"
    assert(finder:Search())
    return env, finder
end

local env, finder = New()
env:Advance(0.5)
assert(finder.sweep.loading and env.selection == 3 and env.requested == 1)
assert(#env:Messages("Q", "WHISPER") == 0)
env:Advance(0.9)
assert(env.loaded and finder.sweep.total == 3 and not finder.sweep.loading)
assert(env.selection == 2, "Restore the original selection after the first cold roster arrives")
assert(#env:Messages("Q", "WHISPER") == 1)

env, finder = New()
finder:StopAPRSweep()
assert(env.selection == 2 and not finder.rosterSelection and not finder.rosterLoading)
env:Advance(12)
assert(not env.loaded and not finder.sweep and #env:Messages("Q", "WHISPER") == 0)

env, finder = New()
SetSelectedDisplayChannel(1) -- user chooses another native channel while the request is pending
env:Advance(11)
assert(env.selection == 1 and not finder.rosterSelection, "Timeout cannot overwrite a later user selection")
assert(finder.status == "roster_unavailable")

env, finder = New()
env:Event("PLAYER_CAMPING")
assert(env.selection == 2 and not finder.rosterSelection and not finder.rosterLoading)
env:Event("LOGOUT_CANCEL")
env:Advance(12)
assert(not finder.sweep and #env:Messages("Q", "WHISPER") == 0)

env, finder = New()
finder:SetOption("enabled", false)
assert(env.selection == 2 and not finder.rosterSelection)

env, finder = New()
ChannelFrame = { IsShown = function() return true end } -- the user opens native chat during loading
env:Advance(1.4)
assert(env.selection == 3, "An opened native channel window owns its current selection")
ChannelFrame = nil

print("Cold APR roster: delayed native delivery, selection lease, Stop, timeout, logout and user interaction passed")

-- The native selected APR index survives reload, but its count/cache are empty.
-- Re-selecting the same index does nothing; the server count can arrive in the
-- event while GetChannelDisplayInfo still returns nil.
local function retainedSelection()
    local env = Fixture.New()
    local finder = env.finder
    env.selection, env.population, env.loaded = 3, nil, false
    local selections, original = {}, GetChannelDisplayInfo
    function GetSelectedDisplayChannel() return env.selection end
    function GetChannelDisplayInfo(index)
        if index == 3 and env.channels.APR then
            return "APR", false, false, env.channels.APR, nil, true
        end
        return original(index)
    end
    function SetSelectedDisplayChannel(index)
        selections[#selections + 1] = index
        if index == env.selection then return end
        env.selection = index
        if index == 3 then
            C_Timer.NewTimer(1, function()
                env.loaded = true
                env:Event("CHANNEL_ROSTER_UPDATE", 3, 3)
            end)
        end
    end
    C_ChatInfo.GetChannelRosterInfo = function(index, row)
        assert(index == 3)
        if env.loaded then return ({ "Local-Home", "One-Home", "Two-Home" })[row] end
    end
    APR.CommunicationChannel.addonTransport = "blocked"
    assert(finder:Search())
    return env, finder, selections
end

env, finder, selections = retainedSelection()
assert(selections[1] == 2 and selections[2] == 3 and env.selection == 3)
env:Advance(1.4)
assert(finder.sweep.total == 2 and not finder.sweep.loading)
assert(finder.worldPopulation == 3 and env.selection == 3)
assert(#env:Messages("Q", "WHISPER") == 1)
-- An unrelated channel's count must not replace APR's event-backed count.
env:Event("CHANNEL_COUNT_UPDATE", 2, 9000)
assert(finder:RefreshWorldPopulation() == 3)
-- A renumbered/replaced channel cannot reuse a previously cached event count.
env.channels.APR, env.channelID = 9, 9
APR.CommunicationChannel:Refresh()
assert(finder:RefreshWorldPopulation() == nil)
print(
    "Retained APR selection: real selection transition, event-only population, unrelated events and renumbering passed"
)

-- Discovery invalidates the old display order as soon as selection is changed.
-- APR keeps its local channel number but moves to a different display index.
env = Fixture.New()
finder = env.finder
local shifted, loaded, selected = false, false, 3
local calls = {}
function GetNumDisplayChannels() return shifted and 4 or 3 end
function GetSelectedDisplayChannel() return selected end
function GetChannelDisplayInfo(index)
    if index == 1 then return "Fixture header", true end
    if index == 2 then return "Fixture general", false, false, 1, 1, true end
    if shifted and index == 3 then return "New native header", true end
    if index == (shifted and 4 or 3) then return "APR", false, false, env.channelID, nil, true end
end
function SetSelectedDisplayChannel(index)
    calls[#calls + 1] = index
    if index == 2 and not shifted then
        shifted, selected = true, 2
        env:Event("CHANNEL_UI_UPDATE")
    elseif shifted and index == 3 then
        selected = 2 -- the obsolete index is now a header; native code selects a default
    elseif shifted and index == 4 then
        selected = 4
        C_Timer.NewTimer(0.5, function()
            loaded = true
            env:Event("CHANNEL_ROSTER_UPDATE", 4, 3)
        end)
    else
        selected = index
    end
end
C_ChatInfo.GetChannelRosterInfo = function(index, row)
    if loaded and index == 4 then return ({ "Local-Home", "Three-Home", "Four-Home" })[row] end
end
APR.CommunicationChannel.addonTransport = "blocked"
assert(finder:Search())
env:Advance(1.1)
assert(shifted and selected == 4 and finder.worldDisplayIndex == 4)
assert(not finder.sweep.loading and finder.sweep.total == 2)
assert(calls[1] == 2 and calls[2] == 3 and calls[3] == 4)
print("APR roster refresh: display index re-resolved after native order changes, without opening the channel window")
