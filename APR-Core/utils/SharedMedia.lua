-- Publish bundled media when APR loads, independently of its settings windows.
-- Stable names keep saved choices and other addons' shared-media lists compatible.
local soundRoot = "Interface\\AddOns\\APR\\APR-Core\\assets\\sound\\"
-- Defaults resolve directly even if the optional shared-media library is unavailable.
APR.CompanionSoundFiles = {
    match = soundRoot .. "companion-match.ogg",
    received = soundRoot .. "companion-received.ogg",
    joined = soundRoot .. "companion-joined.ogg",
    declined = soundRoot .. "companion-declined.ogg",
    expired = soundRoot .. "companion-expired.ogg",
    error = soundRoot .. "companion-error.ogg",
}
APR.CompanionSoundNames = {
    match = "APR - Companion Match", received = "APR - Companion Received",
    joined = "APR - Companion Joined", declined = "APR - Companion Declined",
    expired = "APR - Companion Expired", error = "APR - Companion Error",
}
local media = LibStub and LibStub("LibSharedMedia-3.0", true)
if not media or not media.Register then return end

local sounds = {
    ["APR - 42"] = "42.mp3",
}
for name, file in pairs(sounds) do
    media:Register("sound", name, soundRoot .. file)
end
for event, file in pairs(APR.CompanionSoundFiles) do
    media:Register("sound", APR.CompanionSoundNames[event], file)
end
