-- FarstriderLib~Finalizer.lua
local _, FarstriderLib = ...

if not FarstriderLib.Internal then return end

FarstriderLib.Internal = nil

---@type FarstriderLibAPI
FarstriderLib_API = {
    VERSION = FarstriderLib.VERSION,
    DATA = FarstriderLib.Data,
    Rebuild = FarstriderLib.Pathfinding.Rebuild,
    FindTrail = FarstriderLib.FindTrail,
    FindTrailTo = FarstriderLib.FindTrailTo,
}

-- legacy support for direct access, will be removed in a future update
_G.FarstriderLib = FarstriderLib
