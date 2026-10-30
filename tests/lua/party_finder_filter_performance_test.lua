-- Compiled policies preserve multilingual/unknown-language behavior without
-- sorting preferences again for every cached discovery result.
local Fixture = dofile("tests/lua/party_finder_test_env.lua")
local env = Fixture.New({ settings = { matchMode = "zone" } })
local finder, P = env.finder, env.protocol
local unrestricted = P.CompileLanguagePolicy({}, {})
local french = P.CompileLanguagePolicy({ fr = true }, { en = true })
local blockedFrench = P.CompileLanguagePolicy({}, { fr = true })
local asian = P.CompileLanguagePolicy({ "zhCN", "zhTW" }, { zhCN = true })
assert(P.AcceptLanguageMask(0, unrestricted) and P.AcceptLanguageMask(1023, unrestricted))
assert(not P.AcceptLanguageMask(0, french) and not P.AcceptLanguageMask(1, french))
assert(P.AcceptLanguageMask(2, french) and P.AcceptLanguageMask(3, french),
    "An allowed language admits bilingual peers despite their blocked second language")
assert(not P.AcceptLanguageMask(0, blockedFrench) and not P.AcceptLanguageMask(2, blockedFrench))
assert(P.AcceptLanguageMask(3, blockedFrench) and P.AcceptLanguageMask(512, blockedFrench))
assert(not P.AcceptLanguageMask(256, asian) and P.AcceptLanguageMask(512, asian)
    and P.AcceptLanguageMask(768, asian), "High language bits retain their independent policies")
for _, bad in ipairs({ -1, 1024, 1.5, math.huge, "3", {} }) do
    assert(not P.AcceptLanguageMask(bad, unrestricted))
end
assert(not P.AcceptLanguageMask(0 / 0, unrestricted))

-- Populate the actual capped cache through its public wire protocol and fresh
-- queries. Four equal populations have independently chosen language masks.
local masks, primaries = { 1, 2, 3, 512 }, { "en", "fr", "en", "zhTW" }
for batch = 1, 7 do
    -- Isolate full-cache filtering from the discovery rate limiter.
    if batch > 1 then env:Advance(1); finder.lastSearch = nil end
    assert(finder:Search())
    for index = 1, 30 do
        local number = (batch - 1) * 30 + index
        local language = (number - 1) % 4 + 1
        env:Receive("P", env:Presence({ languages = masks[language], primary = primaries[language] }),
            "Candidate" .. number .. "-Home", "WHISPER")
    end
end
assert(finder:GetCount() == 200)
local settings = finder:GetSettings()
settings.languages, settings.blockedLanguages = { fr = true }, { en = true }
finder.candidatesDirty = true
finder:GetLocalState() -- Isolate list filtering from separate local-state work.

local normalize, sort = P.NormalizeLanguages, table.sort
local normalizations, sorts = 0, 0
P.NormalizeLanguages = function(...)
    normalizations = normalizations + 1
    return normalize(...)
end
table.sort = function(...)
    sorts = sorts + 1
    return sort(...)
end
local list = finder:GetCandidates()
assert(#list == 100, "Fifty French and fifty bilingual peers match; English and Chinese peers do not")
assert(normalizations == 2 and sorts == 3,
    "200 candidates normalize two policy lists and sort once, instead of 600 normalizations/601 sorts")
local previousNormalizations, previousSorts = normalizations, sorts
assert(finder:GetCandidates() == list and finder:GetCount() == 100)
assert(normalizations == previousNormalizations and sorts == previousSorts,
    "Unchanged badge/list reads keep their allocation-free cached path")
P.NormalizeLanguages, table.sort = normalize, sort

finder:SetLanguageOption("languages", "fr", false)
finder:SetLanguageOption("languages", "zhTW", true)
assert(finder:GetCount() == 50, "Changing preferences immediately rebuilds the compiled policy")
env:Advance(121)
assert(finder:GetCount() == 0, "Compiled policies do not extend the candidate expiration boundary")
print("Companion filters: 200 peers use two normalizations/three sorts instead of 600/601; bilingual, unknown, settings and expiry passed")
