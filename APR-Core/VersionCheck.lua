local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.versionCheck = APR:NewModule("VersionCheck")

-- Session-scoped flag: only show the peer-outdated notification once per session
local peerOutdatedShown = false

---------------------------------------------------------------------------------------
---------------------------------- Version Parsing ------------------------------------
---------------------------------------------------------------------------------------

-- Parse a version string like "v1.2.3" or "1.2.3" into a comparable integer.
-- Returns nil if the string cannot be parsed or is a dev placeholder.
local function ParseVersion(versionStr)
    if not versionStr or versionStr == "" or versionStr:find("@") then
        return nil
    end
    local str = versionStr:match("^[vV](.+)$") or versionStr
    local major, minor, patch = str:match("^(%d+)%.(%d+)%.(%d+)$")
    if major then
        return tonumber(major) * 1000000 + tonumber(minor) * 1000 + tonumber(patch)
    end
    local m, n = str:match("^(%d+)%.(%d+)$")
    if m then
        return tonumber(m) * 1000000 + tonumber(n) * 1000
    end
    local rev = str:match("^(%d+)$")
    if rev then
        return tonumber(rev)
    end
    return nil
end

-- Returns true if v1 is strictly newer than v2.
local function IsNewerVersion(v1, v2)
    local n1 = ParseVersion(v1)
    local n2 = ParseVersion(v2)
    if not n1 or not n2 then return false end
    return n1 > n2
end

---------------------------------------------------------------------------------------
------------------------------ Version Check Functions --------------------------------
---------------------------------------------------------------------------------------

local function GetReleasesUrl()
    return "https://www.curseforge.com/wow/addons/azeroth-pilot-reloaded/files/all"
end

-- Check if the live game interface version has advanced beyond what this addon declared.
-- This catches the case where WoW patched forward and the addon hasn't been updated yet.
function APR.versionCheck:CheckInterfaceVersion()
    if not APR.settings.profile.checkForUpdate then return end
    local addonTOC = APR.tocVersion
    local gameTOC = APR.interfaceVersion
    if not addonTOC or not gameTOC then return end
    if gameTOC > addonTOC then
        APR.questionDialog:CreateMessagePopup(string.format(L["OUTDATED_TOC_ALERT"], GetReleasesUrl()), OKAY)
    end
end

-- Called when a version broadcast is received from a group member.
-- Shows a one-per-session notification if the sender is running a newer release.
function APR.versionCheck:HandleVersionMessage(senderVersion)
    if peerOutdatedShown then return end
    if not APR.settings.profile.checkForUpdate then return end
    if IsNewerVersion(senderVersion, APR.version) then
        peerOutdatedShown = true
        APR.questionDialog:CreateMessagePopup(string.format(L["OUTDATED_PEER_ALERT"],
            APR:WrapTextWithAppearanceColor(senderVersion, "general", "warning"),
            GetReleasesUrl()
        ), OKAY)
    end
end

-- Broadcast our version to the group so peers can compare against it.
function APR.versionCheck:BroadcastVersion()
    if not IsInGroup() then return end
    if not APR.version or APR.version:find("@") then return end
    local channel
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        channel = "INSTANCE_CHAT"
    elseif IsInRaid() then
        channel = "RAID"
    else
        channel = "PARTY"
    end
    C_ChatInfo.SendAddonMessage("APRVersionCheck", APR.version, channel)
end

function APR.versionCheck:OnInit()
    self:CheckInterfaceVersion()
end
