-- FarstriderLibData~Init.lua
local _, FarstriderLibData = ...

local VERSION = 1784851200

if FarstriderLibData_API and (FarstriderLibData_API.VERSION or 0) >= VERSION then return end

FarstriderLibData.VERSION = VERSION
FarstriderLibData.Internal = {}
