local fixture = dofile("tests/lua/navigation_fixture.lua")
local data = fixture:Load({ config = { Holidays = { festival = { [123] = true } } } })
local adapter, env = APR.NavigationAdapter, APR.NavigationAdapter.environment
local today = { year = 2030, month = 1, monthDay = 5, hour = 10, minute = 0 }
local function time(hour, minute) return { year = 2030, month = 1, monthDay = 5, hour = hour, minute = minute or 0 } end
local holiday = { startTime = time(10), endTime = time(11) }
local event = { calendarType = "HOLIDAY", iconTexture = 123 }
C_DateAndTime = { GetCurrentCalendarTime = function() return today end }
C_Calendar = {
    GetMonthInfo = function() return { year = 2029, month = 12 } end,
    GetNumDayEvents = function(offset, day)
        assert(offset == 1 and day == 5)
        return 1
    end,
    GetDayEvent = function(offset, day, index)
        assert(offset == 1 and day == 5 and index == 1)
        return event
    end,
    GetHolidayInfo = function(offset, day, index)
        assert(offset == 1 and day == 5 and index == 1)
        return holiday
    end,
}
assert(env.isHolidayActive("festival") == nil)
adapter.frame.OnEvent(adapter.frame, "CALENDAR_UPDATE_EVENT_LIST")
today.minute = -1
assert(
    env.isHolidayActive("festival") == false,
    "A start-day entry does not authorize travel before the actual opening"
)
today.minute = 0
assert(env.isHolidayActive("festival") == true)
today.hour = 11
assert(env.isHolidayActive("festival") == false, "The end boundary is exclusive")
today.hour = 10
holiday = nil
assert(env.isHolidayActive("festival") == nil)
holiday = { startTime = time(10), endTime = time(11) }
event.calendarType = "PLAYER"
assert(env.isHolidayActive("festival") == false, "A player-created event cannot impersonate a holiday")
event.calendarType = "HOLIDAY"
C_Calendar.GetDayEvent = function() error("restricted") end
assert(env.isHolidayActive("festival") == nil)

local current, selected = nil, "house-one"
local info = { isLoaded = true, initiativeID = 7, currentCycleID = 3, neighborhoodGUID = "hood-one", duration = 100 }
adapter.houses = {
    { houseGUID = "house-one", neighborhoodGUID = "hood-one", plotID = 1 },
    { houseGUID = "house-two", neighborhoodGUID = "hood-two", plotID = 2 },
}
C_Housing = {
    GetTrackedHouseGuid = function() return selected end,
    GetCurrentNeighborhoodGUID = function() return current end,
    GetUIMapIDForNeighborhood = function(id) return id == "hood-one" and 101 or 102 end,
}
C_NeighborhoodInitiative = { GetNeighborhoodInitiativeInfo = function() return info end }
assert(env.getHousingInitiative(101).initiativeID == 7)
assert(env.getHousingInitiative(102) == nil, "An endeavor cannot leak into a different departure map")
selected = "house-two"
assert(
    env.getHousingInitiative(102) == nil,
    "Data from the previously selected house is not evidence for the new neighborhood"
)
info.neighborhoodGUID = "hood-two"
assert(env.getHousingInitiative(102).initiativeID == 7)
current = "hood-one"
assert(
    env.getHousingInitiative(101) == nil,
    "The neighborhood actually being visited takes precedence over the dashboard selection"
)
info.neighborhoodGUID = "hood-one"
assert(env.getHousingInitiative(101).neighborhoodGUID == "hood-one")
info.isLoaded = false
assert(env.getHousingInitiative(101) == nil)
info.isLoaded, info.duration = true, 0
assert(env.getHousingInitiative(101) == nil, "Expired initiative data must not authorize a stale portal")
local refreshes = 0
APR.ActiveRoute = "synthetic-route"
APR.navigation = { ForceRefresh = function() refreshes = refreshes + 1 end }
for _, name in ipairs({ "ZONE_CHANGED_NEW_AREA", "CALENDAR_UPDATE_EVENT_LIST", "NEIGHBORHOOD_INITIATIVE_UPDATED" }) do
    assert(adapter.frame.events[name])
    adapter.frame.OnEvent(adapter.frame, name)
end
assert(refreshes == 3)
print(
    "Conditional adapter: server calendar bounds, viewed-month offset, unavailable data and neighborhood-scoped initiatives passed"
)

-- A known boundary gets one deadline; missing data gets a scoped fallback.
local pendingTimers = {}
C_Timer = { NewTimer = function(delay, callback)
    local value = { delay = delay, callback = callback, Cancel = function(self) self.cancelled = true end }
    pendingTimers[#pendingTimers + 1] = value
    return value
end }
APR.settings = { profile = { enableAddon = true } }
today.hour, today.minute = 10, 0
C_Calendar.GetDayEvent = function() return event end
adapter.calendarReady = true
adapter.holidayBoundary = nil
assert(env.isHolidayActive("festival") == true)
adapter:RefreshActivity()
local boundary = pendingTimers[#pendingTimers]
assert(boundary and boundary.delay == 3600, "Known opening/closing boundaries do not need minute polling")
for _ = 1, 100 do adapter:RefreshActivity() end
assert(#pendingTimers == 1)
holiday = nil
env.isHolidayActive("festival")
adapter:RefreshActivity()
local fallback = pendingTimers[#pendingTimers]
assert(boundary.cancelled and fallback.delay == 60, "Unavailable data uses one demand-scoped fallback")
APR.ActiveRoute = nil
adapter:RefreshActivity()
assert(fallback.cancelled)
local refreshBefore = refreshes
fallback.callback()
assert(refreshes == refreshBefore, "Cancelled calendar callbacks cannot refresh an abandoned route")
