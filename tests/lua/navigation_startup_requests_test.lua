local fixture = dofile("tests/lua/navigation_fixture.lua")

for _, case in ipairs({
    { profile = "forever", initiativeEnabled = true, calendar = 0, initiative = 0 },
    { profile = "unsupported", interface = 11508, initiativeEnabled = true, calendar = 0, initiative = 0 },
    { profile = "retail", initiativeEnabled = true, calendar = 0, initiative = 1 },
    { profile = "retail", holidays = true, initiativeEnabled = true, calendar = 1, initiative = 1 },
    { profile = "retail", holidays = true, initiativeEnabled = false, calendar = 1, initiative = 0 },
    { profile = "retail", holidays = true, calendar = 1, initiative = 0 },
}) do
    fixture.profile, fixture.interface = case.profile, case.interface
    local calendarRequests, initiativeRequests, tickers = 0, 0, {}
    C_Housing = nil
    C_Calendar = { OpenCalendar = function() calendarRequests = calendarRequests + 1 end }
    C_NeighborhoodInitiative = {
        RequestNeighborhoodInitiativeInfo = function() initiativeRequests = initiativeRequests + 1 end,
    }
    if case.initiativeEnabled ~= nil then
        C_NeighborhoodInitiative.IsInitiativeEnabled = function() return case.initiativeEnabled end
    end
    C_Timer = {
        NewTicker = function(seconds, callback)
            assert(seconds == 60)
            tickers[#tickers + 1] = callback
            return { Cancel = function() end }
        end,
    }
    fixture:Load({ config = { Holidays = case.holidays and { festival = { [123] = true } } or nil } })
    local frame = APR.NavigationAdapter.frame
    assert(calendarRequests == 0 and initiativeRequests == 0, "Loading the adapter must not issue requests")
    for attempt = 1, 2 do
        frame.OnEvent(frame, "PLAYER_ENTERING_WORLD")
        assert(calendarRequests == case.calendar * attempt,
            "Login and reload must not request a calendar unused by the navigation catalogue")
        assert(initiativeRequests == case.initiative * attempt,
            "Exposed APIs do not authorize housing initiative requests on other clients or disabled services")
    end
    for _, event in ipairs({ "TRACKED_HOUSE_CHANGED", "PLAYER_HOUSE_LIST_UPDATED" }) do
        local before = initiativeRequests
        frame.OnEvent(frame, event)
        assert(initiativeRequests == before + case.initiative,
            "House events must retain the same client and feature checks as login")
    end
    assert(#tickers == case.calendar, "Only a catalogue that uses holidays needs periodic refreshes")
    for _, tick in ipairs(tickers) do tick() end
    assert(calendarRequests == case.calendar * 3, "Required holidays must still refresh after login")
end

print("Navigation startup requests: unused calendar, cross-client APIs and disabled initiative service passed")
