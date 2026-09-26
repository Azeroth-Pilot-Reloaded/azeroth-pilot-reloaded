local titles, requests = {}, {}
function LibStub() return { GetLocale = function() return {} end } end
function wipe(value) for key in pairs(value) do value[key] = nil end end
C_QuestLog = {
    GetTitleForQuestID = function(id) return titles[id] end,
    RequestLoadQuestByID = function(id) requests[#requests + 1] = id end,
}
APR = {}
dofile("APR-Core/utils/QuestUtils.lua")

assert(APR:GetQuestTitle(123) == nil and #requests == 1 and requests[1] == 123)
assert(APR:GetQuestTitle(123) == nil and #requests == 1, "Uncached titles request once")
assert(not APR:OnQuestTitleLoaded(999, true), "Unrequested quest data does not refresh UI")
titles[123] = "Loaded quest"
assert(APR:OnQuestTitleLoaded(123, true))
assert(APR:GetQuestTitle(123) == "Loaded quest" and #requests == 1)
APR:GetQuestTitle(456)
APR:ResetQuestTitleRequests()
assert(not APR:OnQuestTitleLoaded(456, true), "Reset clears pending title requests")
print("Quest titles: uncached requests deduplicate and loaded titles resolve")
