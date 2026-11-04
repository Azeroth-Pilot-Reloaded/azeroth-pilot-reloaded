local state = { profile = "retail", ordinary = true, advanced = false, indoors = false }
function GetTime() return 0 end
function IsFlyableArea() return state.ordinary end
function IsAdvancedFlyableArea() return state.advanced end
function IsIndoors() return state.indoors end
function IsFlying() return state.flying == true end
function GetUnitSpeed() return 0, 7, 30, 4.7 end
function CreateFrame() return { RegisterEvent = function() end, SetScript = function() end } end
function LibStub() return { GetLocale = function() return {} end } end
APR = { GAME_VERSIONS = { Forever = "forever" }, NewModule = function() return {} end }
function APR:GetGameVersion() return state.profile end
function APR:GetNavigationPlayerPosition() return {x=0,y=0,z=0,instanceID=0} end
function APR:CheckFlySkill() return state.learned ~= false end
C_PlayerInfo = { GetGlidingInfo = function() return state.gliding == true, true, 0 end }
C_MountJournal = {
    GetMountIDs = function() return {1} end,
    GetCollectedDragonridingMounts = function() return state.groundMountOnly and {} or {1} end,
    GetMountUsabilityByID = function() return true end,
    GetMountInfoByID = function() return "mount", 0, 0, false, true, 0, 0, 0, 0, 0, not state.groundMountOnly end,
}
dofile("APR-Core/features/navigation/Navigation.lua")
local nav = APR.navigation
assert(nav:GetThreshold() == 2000, "Ordinary flight permission must not imply skyriding permission")
local profile = nav:GetMovementProfile()
assert(profile.currentCanSteady and not profile.currentCanSkyriding, "A steady-only zone retains its own locally permitted movement mode")
state.groundMountOnly = true
nav._flyingMountID = nil
assert(not nav:GetMovementProfile().canSteady, "Riding skill plus a ground mount cannot prove a usable flying mount")
state.groundMountOnly = false
state.advanced, state.ordinary = true, false
profile = nav:GetMovementProfile()
assert(profile.currentCanSkyriding and not profile.currentCanSteady, "A skyriding zone need not also permit steady flight locally")
state.indoors = true
profile = nav:GetMovementProfile()
assert(not profile.currentCanSteady and not profile.currentCanSkyriding, "Indoor restrictions apply locally even when area flags permit flight")
assert(nav:GetMovementSpeed(10000) == 7,
    "An explicitly supplied flight threshold cannot transfer flying speed into an indoor observation")
local nativeIndoor = IsIndoors
IsIndoors = function() return {} end
assert(nav:GetMovementSpeed(10000) == 7, "An unreadable indoor observation cannot prove flying speed")
IsIndoors = function() error("indoor observation unavailable") end
assert(nav:GetMovementSpeed(10000) == 7, "A temporarily unavailable indoor API remains conservative")
IsIndoors = nativeIndoor
state.indoors,state.advanced,state.ordinary=false,false,false
assert(nav:GetMovementSpeed(10000)==7,
    "A stale explicit flight threshold cannot override a currently forbidden flight area")
state.indoors, state.profile = false, "forever"
profile = nav:GetMovementProfile()
assert(not profile.canSteady and not profile.canSkyriding, "Forever remains grounded regardless of Retail API observations")
state.profile, state.ordinary, state.advanced = "retail", true, true
APR.NavigationData = { GetWalkingSpeed = function(_, point, fast, ground) return point.groundOnly and ground or fast end }
profile = nav:GetMovementProfile()
assert(not profile.canFlyAt({groundOnly=true}, "skyriding") and profile.canFlyAt({movementMode="skyriding"}, "skyriding")
    and not profile.canFlyAt({},"skyriding"),
    "A declared aerial corridor proves future permission while a restricted or unknown coordinate remains grounded")
state.flying, state.gliding = true, true
assert(nav:GetMovementProfile().currentMode == "skyriding", "An airborne departure must attach to an aerial corridor")
state.learned = false
assert(not nav:GetMovementProfile().canSteady, "Skyriding alone does not prove ordinary flight training")
state.learned = true
state.gliding = false
assert(nav:GetMovementProfile().currentMode == "steady", "Steady flight uses its own graph state at the same XYZ")
APR.NavigationData.HasTerrainData = function() return true end
assert(not nav:CanSkipFlyingWaypoint(), "An unknown bypass corridor cannot skip an authored checkpoint")
APR.NavigationData.HasTerrainData = function() return false end
assert(nav:CanSkipFlyingWaypoint(), "A legacy world retains its existing flight skip policy")
print("Terrain movement: steady, skyriding, indoor, Forever and destination restrictions")
