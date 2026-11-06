-- Renames preserve keys, explicit variants, future paths and historical completion receipts.
local env = dofile("tests/lua/route_prefab_test_env.lua")
local E = APR.EXPANSIONS
local first = env.route("a-variant", "Invented zone - I", {Race = "Tauren", MinLevel = 50})
local second = env.route("z-variant", "Invented zone - II", {Race = "Orc", MinLevel = 50})
first.legacyLabels, second.legacyLabels = {"Invented zone (11-19)"}, {"Invented zone (11-19)"}
local nextRoute = env.route("next", "Invented second chapter", {MinLevel = 60})
nextRoute.legacyLabels = {"Invented zone (20-25)"}
local unused = env.route("unused", "Unused renamed chapter", {MinLevel = 45})
unused.legacyLabels = {"Unused old chapter"}
local player = { ["a-variant"] = 17, ["z-variant"] = 7, next = 3,
    ["a-variant-SkippedStep"] = 2, ["a-variant-ParallelStepsState"] = {groups = {}},
    RouteSignatures = {["a-variant"] = "retained-signature"},
    TemporaryRouteState = {previousRouteKey = "a-variant"},
}
APRData.player = player
APR.settings = {profile = {routeFavorites = {["a-variant"] = true, next = true}}}
APRCustomPath.player = {"Invented zone (11-19)", "Invented zone (20-25)", "Deleted chapter"}
APRZoneCompleted.player = { ["Invented zone (11-19)"] = true, ["Invented zone (20-25)"] = true }
APR.Level, APR.ActiveRoute = 1, "a-variant"
local path, completed = APRCustomPath.player, APRZoneCompleted.player
APR:NormalizeSavedRouteLabels()
assert(path[1] == second.label and path[2] == nextRoute.label and path[3] == "Deleted chapter",
    "A legacy path without a choice keeps the resolver's recommended variant, future order and unknown entries")
assert(player.RouteChoices[second.label] == "z-variant" and player.RouteChoices[nextRoute.label] == "next")
assert(completed[first.label] and completed[second.label] and completed[nextRoute.label],
    "Previously shared completion must survive distinct new variant names and future level gates")
assert(completed["Invented zone (11-19)"] and completed["Invented zone (20-25)"], "Keep old receipts for recovery")
assert(player["a-variant"] == 17 and player["z-variant"] == 7 and player.next == 3)
assert(player["a-variant-SkippedStep"] == 2 and player["a-variant-ParallelStepsState"].groups)
assert(player.RouteSignatures["a-variant"] == "retained-signature" and player.TemporaryRouteState.previousRouteKey == "a-variant")
assert(APR.ActiveRoute == "a-variant" and APR.settings.profile.routeFavorites["a-variant"] and APR.settings.profile.routeFavorites.next)
-- Explicit entry into a nonrecommended variant, including a choice not currently queued.
path[1] = "Invented zone (11-19)"
player.RouteChoices = {[path[1]] = "a-variant", ["Unused old chapter"] = "unused"}
APR:NormalizeSavedRouteLabels()
assert(path[1] == first.label and player.RouteChoices[first.label] == "a-variant")
assert(player.RouteChoices[unused.label] == "unused" and player.RouteChoices["Unused old chapter"] == "unused")
assert(APR:GetRouteKeyFromDisplayName("Invented zone (11-19)") == "a-variant")
-- Normalizing again cannot reapply a stale alias over a later canonical choice.
local shared = env.route("shared", "Unused renamed chapter", {Race = "Orc"})
player.RouteChoices[unused.label] = "shared"
APR:NormalizeSavedRouteLabels()
assert(player.RouteChoices[unused.label] == "shared")
assert(APRCustomPath.player == path and APRZoneCompleted.player == completed and path[1] == first.label)
assert(player.RouteCompletionMigrations["Invented zone (11-19)"])
completed[first.label] = nil
APR:NormalizeSavedRouteLabels()
assert(completed[first.label] == nil and completed[second.label], "An old receipt cannot resurrect a route reset on a later login")
-- A live canonical name takes precedence over an unrelated route's alias.
local collision = env.route("collision", "Live canonical", nil)
collision.legacyLabels = {"Still canonical"}
env.route("canonical", "Still canonical", nil)
APRCustomPath.player = {"Still canonical"}
APRZoneCompleted.player["Still canonical"] = true
APR:NormalizeSavedRouteLabels()
assert(APRCustomPath.player[1] == "Still canonical" and not APRZoneCompleted.player[collision.label])
-- Foreign-client declarations and absent optional saved tables remain harmless.
local foreign = env.route("foreign", "Retail renamed", nil)
foreign.expansion, foreign.gameVersion, foreign.legacyLabels = E.TheWarWithin, APR.GAME_VERSIONS.Retail, {"Retail old"}
APRCustomPath.player, APRData.player, APRZoneCompleted.player = {"Retail old"}, nil, nil
APR:NormalizeSavedRouteLabels()
assert(APRCustomPath.player[1] == "Retail old")
print("Route label migration: ambiguous aliases, explicit/unselected choices, future paths, completions, progress, favorites and idempotent recovery passed")
