-- FarstriderLib~Init.lua
local _, FarstriderLib = ...

local VERSION = 10402

if FarstriderLib_API and (FarstriderLib_API.VERSION or 0) >= VERSION then return end

FarstriderLib.VERSION = VERSION
FarstriderLib.Internal = {}

-- ── Auto-detect the Interface path to this library folder ────────────
-- debugstack() returns "path/to/file.lua:line: ..." when the chunk loads.
-- We strip the filename to get the directory, which lets media references
-- work regardless of which addon embeds FL.
do
    local stack = debugstack(1, 1, 0) or ""
    local dir = stack:match("^(.+[/\\])FarstriderLib~Init%.lua") or ""
    -- Normalise to backslash (WoW media paths use backslashes)
    dir = dir:gsub("/", "\\")
    -- Strip everything before "Interface\" — PlaySoundFile / SetFont
    -- require paths rooted at "Interface\\" not the full disk path.
    dir = dir:gsub("^.*(Interface\\)", "%1")
    --- Base Interface path to this FarstriderLib folder (trailing backslash).
    --- Example: "Interface\\AddOns\\MountRoutePlanner\\Libs\\FarstriderLib\\"
    ---@type string
    FarstriderLib.media_path = dir
end
