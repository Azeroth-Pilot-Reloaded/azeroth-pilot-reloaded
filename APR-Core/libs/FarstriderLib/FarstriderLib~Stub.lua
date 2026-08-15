-- FarstriderLib~Stub.lua
-- No-op stubs for modules that only exist in debug builds.
-- The debug files (Logger, Debug) override these when loaded.
-- In production builds REMOVE_LINE strips those files, so
-- these stubs prevent nil-function errors.
local _, FarstriderLib = ...

if not FarstriderLib.Internal then return end

--- Delegates to _setWaypointImpl if registered (by Debug.lua), otherwise no-op.
---@param waypoint Location
---@param texture string
---@param options? table
function FarstriderLib.PlaceFlare(waypoint, texture, options)
    if FarstriderLib._setWaypointImpl then
        FarstriderLib._setWaypointImpl(waypoint, texture, options)
    end
end

--- Delegates to _clearWaypointsImpl if registered (by Debug.lua), otherwise no-op.
function FarstriderLib.ClearFlares()
    if FarstriderLib._clearWaypointsImpl then
        FarstriderLib._clearWaypointsImpl()
    end
end

FarstriderLib.Logger = FarstriderLib.Logger or {}

---@type Logger
local Logger = FarstriderLib.Logger

---@param ... any
function Logger:Log(...) end

---@param ... any
function Logger:Info(...) end

---@param ... any
function Logger:InfoGreen(...) end

---@param ... any
function Logger:Warning(...) end

---@param ... any
function Logger:Error(...) end
