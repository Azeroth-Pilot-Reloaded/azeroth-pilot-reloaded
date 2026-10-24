local grouped, raid, instance, now, client
local sent, popups, timers, tickers
local function loadVersion(version, saved, notifications)
    grouped, raid, instance, now, client = false, false, false, 100, "retail"
    sent, popups, timers, tickers = {}, {}, {}, {}
    APRData = saved or {}
    APR = {
        version = version, tocVersion = 120105, interfaceVersion = 120105,
        settings = { profile = { checkForUpdate = notifications ~= false, enableAddon = true } },
        NewModule = function() return {} end,
        GAME_VERSIONS = { Classic = "classic", Retail = "retail", Forever = "forever" },
        GetGameVersion = function() return client end,
        WrapTextWithAppearanceColor = function(_, value) return value end,
        questionDialog = { CreateMessagePopup = function(_, text) popups[#popups + 1] = text end },
    }
    function LibStub()
        return { GetLocale = function() return {
            OUTDATED_VERSION_ALERT = "version=%s url=%s", OUTDATED_TOC_ALERT = "toc=%s",
        } end }
    end
    function GetTime() return now end
    function CreateFrame()
        return {
            events = {}, scripts = {},
            RegisterEvent = function(self, event) self.events[event] = true end,
            UnregisterEvent = function(self, event) self.events[event] = nil end,
            UnregisterAllEvents = function(self) self.events = {} end,
            SetScript = function(self, name, callback) self.scripts[name] = callback end,
        }
    end
    LE_PARTY_CATEGORY_INSTANCE, OKAY = 2, "Okay"
    function IsInGroup(category) return grouped and (category ~= 2 or instance) end
    function IsInRaid() return raid end
    C_ChatInfo = { SendAddonMessage = function(prefix, message, channel)
        sent[#sent + 1] = { prefix = prefix, message = message, channel = channel }
    end }
    C_Timer = {
        NewTimer = function(delay, callback)
            local timer = { delay = delay, callback = callback, Cancel = function(self) self.cancelled = true end }
            timers[#timers + 1] = timer
            return timer
        end,
        NewTicker = function(delay, callback)
            error("Version checks must not start a periodic ticker")
        end,
    }
    dofile("APR-Core/core/VersionCheck.lua")
    APR.versionCheck:OnInit()
    return APR.versionCheck
end

-- Public message handling exercises parsing and ordering, including real
-- BigWigs git-describe versions that the old parser silently discarded.
for _, row in ipairs({
    { "v7.2.1", "v7.2.2", true }, { "7.9.0", "V7.10.0", true },
    { "7.2", "7.2.0", false }, { "7.2.1", "7.2.1", false },
    { "7.2.1", "7.1.99", false }, { "7.2.1", "7.2.1-12-gabcdef0", true },
    { "7.2.1-9-gabcdef0", "7.2.1-10-g123abcd", true },
    { "7.2.1-10-gabcdef0", "7.2.1-9-g123abcd", false },
    { "7.2.1-10-gabcdef0", "7.2.1-10-g123abcd", false },
    { "7.2.1-10-gabcdef0", "7.2.2", true },
    { "7.3.0-alpha.9", "7.3.0-alpha.10", true },
    { "7.3.0-alpha.10", "7.3.0-beta.1", true },
    { "7.3.0-beta.2", "7.3.0-rc.1", true },
    { "7.3.0-rc.1", "7.3.0", true }, { "7.3.0", "7.3.0-beta.2", false },
    { "7.3.0-alpha", "7.3.0-alpha.1", true },
    { "7.3.0-alpha.1", "7.3.0-alpha", false },
    { "7.3.0-1", "7.3.0-alpha", true },
    { "7.3.0-1e3", "7.3.0-999", false }, -- only digit identifiers are numeric
    { "7.2.1+abc", "7.2.1+def", false },
    { "7.2.1", "7.2.2+build.12", true },
    { "7.2.1001", "7.3.0", true }, -- no arithmetic component collisions
    { "r123", "r124", true }, { "123", "124", true },
    { "r123", "7.2.1", false }, { "7.2.1", "12345678", false },
}) do
    local check = loadVersion(row[1])
    check:HandleVersionMessage(row[2])
    assert((#popups == 1) == row[3], row[1] .. " compared to " .. row[2])
end
for _, invalid in ipairs({ false, 123, {}, "", "@project-version@", "dev", "7.2.2junk",
    "7.2.2|Hitem:1", "7.2.2\n", "7.2.2-alpha..1", "7.2.2-", string.rep("9", 65) }) do
    local check = loadVersion("7.2.1")
    check:HandleVersionMessage(invalid)
    assert(#popups == 0 and APRData.versionCheck.retail == "7.2.1")
end
local check = loadVersion("@project-version@")
grouped = true
check:HandleVersionMessage("7.2.2")
check:BroadcastVersion()
assert(#popups == 0 and #sent == 0, "Unpackaged checkouts cannot be ordered or announced")

-- Save across reloads, characters and downgrades, independently of a profile.
check = loadVersion("7.2.2")
local saved = APRData
check = loadVersion("7.2.1", saved)
assert(#popups == 1 and popups[1]:find("7.2.2", 1, true), "Solo downgrade detected at initialization")
check:CheckKnownVersion()
check:HandleVersionMessage("7.3.0")
assert(#popups == 1 and APRData.versionCheck.retail == "7.3.0", "Keep learning after the session alert")
check = loadVersion("7.3.0", saved)
assert(#popups == 0, "Updating to the known release removes the warning")
client = "forever"
APR.version = "7.2.1"
check:RememberVersion(APR.version)
check:CheckKnownVersion()
assert(#popups == 0 and saved.versionCheck.forever == "7.2.1", "Client catalogs stay separate")
check = loadVersion("7.2.1", { versionCheck = 123 })
assert(#popups == 0 and APRData.versionCheck.retail == "7.2.1", "Repair invalid saved state")
check = loadVersion("@project-version@", { versionCheck = 123 })
assert(#popups == 0, "Invalid saved state must also be harmless in a development checkout")

-- Reply to downgraded peers even after warning locally or opting out of popups.
check = loadVersion("7.2.2", nil, false)
grouped = true
check:HandleVersionMessage("7.2.1")
assert(#sent == 1 and sent[1].prefix == "APRVersionCheck" and sent[1].message == "7.2.2")
check:HandleVersionMessage("7.2.1")
assert(#sent == 1, "Responses are throttled")
check:HandleVersionMessage("7.3.0")
assert(#popups == 0 and APRData.versionCheck.retail == "7.3.0", "Opt-out only disables alerts")
APR.settings.profile.checkForUpdate = true
check:CheckKnownVersion()
assert(#popups == 1, "Known versions remain available when notifications are enabled again")
now = now + 5
check:HandleVersionMessage("7.2.1")
assert(#sent == 2, "Showing an alert must not prevent replying to older peers")
check:HandleVersionMessage("7.2.2")
assert(#sent == 2, "Equal versions never create reply loops")

-- Login/reload and roster events use a bounded exchange with no idle polling.
check = loadVersion("7.2.1")
grouped = true
for _ = 1, 10 do check:ScheduleBroadcast() end
assert(#timers == 1 and timers[1].delay == 2)
timers[1].callback()
assert(#sent == 1 and sent[1].channel == "PARTY")
assert(#timers == 2 and timers[2].delay == 5, "Only one finite retry covers loading races")
for _ = 1, 10 do check:ScheduleBroadcast() end
assert(#timers == 2, "Roster bursts cannot multiply the pending exchange")
now = now + 5
timers[2].callback()
assert(#sent == 2 and #timers == 2 and #tickers == 0)
assert(not check.broadcastTimer and not check.broadcastRetryTimer, "No timer survives the exchange")
now = now + 600
assert(#sent == 2 and #timers == 2, "Idle time does not trigger more version requests")
raid = true
check:BroadcastVersion()
assert(sent[#sent].channel == "RAID", "Channel changes bypass the old channel's throttle")
instance = true
check:BroadcastVersion()
assert(sent[#sent].channel == "INSTANCE_CHAT")
check:ScheduleBroadcast()
grouped = false
check:ScheduleBroadcast()
assert(timers[3].cancelled and not check.broadcastTimer and not check.broadcastRetryTimer)
grouped = true
check:ScheduleBroadcast()
timers[4].callback()
check:OnDisable()
assert(timers[5].cancelled and not check.broadcastRetryTimer, "Module shutdown cancels the finite retry")
check:ScheduleBroadcast()
grouped = false
timers[6].callback()
assert(#timers == 6 and not check.broadcastTimer and not check.broadcastRetryTimer,
    "Leaving while loading cannot create a retry")

check = loadVersion("7.2.1")
grouped = true
APR.settings.profile.enableAddon = false
check:BroadcastVersion()
assert(#sent == 0, "Disabled addons do not keep announcing from an existing timer")

check = loadVersion("7.2.1")
APR.interfaceVersion = 120107
check:CheckInterfaceVersion()
check:CheckInterfaceVersion()
assert(#popups == 1 and popups[1]:find("toc=", 1, true))
check = loadVersion("7.2.1", { versionCheck = { retail = "7.2.2" } })
APR.interfaceVersion = 120107
check:CheckInterfaceVersion()
assert(#popups == 1, "The TOC popup must not replace the more precise version warning")
print("Version check: packaged builds, persisted downgrades, peer replies, throttling and group lifecycle passed")
