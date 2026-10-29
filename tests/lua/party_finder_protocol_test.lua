-- Discovery contracts use invented characters and definitions, never a maintained route.
APR = {}
LibStub = nil
dofile("APR-Core/features/group/PartyFinderProtocol.lua")
local P = APR.PartyFinderProtocol

assert(P.LanguageFromLocale("enGB") == "en" and P.LanguageFromLocale("enUS") == "en")
assert(P.LanguageFromLocale("esMX") == "es" and P.LanguageFromLocale("zh-Hant") == "zhTW")
assert(P.LanguageFromLocale("arbitrary") == nil and P.LanguageFromLocale({}) == nil)
assert(P.LanguageAtlas("fr") == "Lang-Regions-frFR" and P.LanguageAtlas("|Tbad") == nil)
LocaleUtil = {GetLocaleDisplayName = function(locale) return "Native " .. locale end}
assert(P.GetLanguageValues().fr == "Native frFR", "Language names come from Blizzard's locale provider")
LocaleUtil = nil
LFG_LIST_LANGUAGE_FRFR = "Global label"
assert(P.GetLanguageValues().fr == "Global label")
LFG_LIST_LANGUAGE_FRFR = nil
assert(P.GetLanguageValues().fr == "fr", "Missing native labels fall back to a neutral language code")
local normalized = P.NormalizeLanguages("fr", { en = true, fr = true, de = false, "enGB", "frFR" })
assert(table.concat(normalized, ",") == "en,fr")
assert(P.LanguageMask({ "fr", "en", "zhTW" }) == 515)
assert(table.concat(P.LanguagesFromMask(515), ",") == "en,fr,zhTW")
for _, value in ipairs({ -1, 1024, 1.5, math.huge, "3", {} }) do assert(not P.LanguagesFromMask(value)) end
assert(not P.LanguagesFromMask(0 / 0))
assert(P.AcceptLanguages({ "fr", "en" }, { fr = true }, { en = true }), "An allowed spoken language admits a bilingual player")
assert(not P.AcceptLanguages({ "en" }, { fr = true }, { en = true }))
assert(P.AcceptLanguages({ "fr" }, {}, {}))
assert(not P.AcceptLanguages({ "fr" }, {}, { fr = true }))
assert(P.AcceptLanguages({}, {}, {}) and not P.AcceptLanguages({}, { fr = true }, {}))
assert(not P.AcceptLanguages({}, {}, { en = true }), "Unknown languages are only admitted without restrictions")
assert(P.AcceptLanguages({ "en" }, { fr = false }, { en = false }))

assert(P.Hash("") == "00001505" and P.Hash("a") == "0002b606" and P.Hash("abc") == "0b885c8b")
assert(P.Hash("abc") ~= P.Hash("acb") and P.Hash({}) == nil)

local function fingerprint(definition, budget)
    local job = P.NewFingerprintJob(definition)
    local done, hash, calls = false, nil, 0
    while not done do
        done, hash = job:Step(budget or 7)
        calls = calls + 1
        assert(job.lastWork <= (budget or 7), "Fingerprint traversal honors the work budget")
        assert(calls < 100000)
    end
    return hash, job, calls
end
local first = { label = "Old title", author = "Someone", steps = {
    { PickUp = { 101 }, Coord = { x = 5, y = 8 } }, { Qpart = { [101] = { "1" } } },
}, parallelSteps = { { steps = { { Done = { 102 } } }, trigger = { level = 7 } } } }
local reordered = { parallelSteps = { { trigger = { level = 7 }, steps = { { Done = { 102 } } } } },
    steps = { { Coord = { y = 8, x = 5 }, PickUp = { 101 } }, { Qpart = { [101] = { "1" } } } },
    label = "Renamed", authors = { "Other" }, description = "Editorial", community = true, source = "Community" }
local signature = fingerprint(first)
assert(signature and signature == fingerprint(reordered), "Dictionary order and editorial attribution do not affect compatibility")
reordered.steps[1].PickUp[1] = 103
assert(signature ~= fingerprint(reordered), "Quest changes affect compatibility even when step counts match")
reordered.steps[1].PickUp[1] = 101
reordered.steps[1], reordered.steps[2] = reordered.steps[2], reordered.steps[1]
assert(signature ~= fingerprint(reordered), "Array order affects compatibility")
assert(fingerprint({ steps = { 1, 2 } }) ~= fingerprint({ steps = { 2, 1 } }), "Numeric keys cannot cancel swapped values")
assert(fingerprint({ a = 1, b = 2 }) ~= fingerprint({ a = 2, b = 1 }), "Value/key association is preserved")
assert(fingerprint({ a = "1" }) ~= fingerprint({ a = 1 }), "Scalar types participate in the hash")

-- Localized prose is presentation, including already formatted strings. Only
-- known schema positions may discard it: arbitrary dictionary keys still hash.
local function localizedDefinition(text)
    return { label = text, legacyLabels = { text }, steps = {
        { Waypoint = 7001, Note = { text }, Name = text, PreviewImages = { text },
            ExtraLineText = text, ExtraLineText42 = { text }, _comment = text,
            DroppableQuest = { Qid = 7002, MobId = 8001, Text = text },
            LearnSkill = { spellID = 9001, text = text }, TameBeast = { npcID = 8002, Text = text },
            KillNPC = { npcID = 8003, name = text }, Buffs = { { spellId = 9002, tooltipMessage = text } },
            SellItems = { items = { { itemID = 6001, Text = text } }, text = text },
            BankDeposit = { { itemID = 6002, text = text } },
            BankWithdraw = { items = { { itemID = 6003, text = text } }, Text = text },
            DestroyItems = { { itemID = 6004, Text = text } },
            Skill = { name = "stable profession name", rank = 25 }, TrigText1 = "2/3",
            SpellButton = { ["7001-1"] = "stable spell name" },
        },
    }, scenarios = { { label = text, scenarioID = 71, steps = { { PickUp = { 7003 }, Note = text } } } },
        parallelSteps = { { conditions = { MinLevel = 15 }, steps = { { Done = { 7004 }, Note = text } } } } }
end
local english = localizedDefinition("Travel to the river")
local french = localizedDefinition("Rejoignez la riviere")
local localeSignature = fingerprint(english)
assert(localeSignature == fingerprint(french), "Identical gameplay remains compatible across localized presentation")
french.steps[1].Note = nil
french.steps[1].ExtraLineText = nil
assert(localeSignature == fingerprint(french), "Removing optional display prose does not change compatibility")
french.steps[1].DroppableQuest.Qid = 7005
assert(localeSignature ~= fingerprint(french), "Ignoring an action label must preserve its quest contract")
french = localizedDefinition("Rejoignez la riviere"); french.steps[1].Skill.name = "another profession"
assert(localeSignature ~= fingerprint(french), "A Skill name is a condition, not a display label")
french = localizedDefinition("Rejoignez la riviere"); french.steps[1].TrigText1 = "3/3"
assert(localeSignature ~= fingerprint(french), "Completion trigger text remains mechanical")
french = localizedDefinition("Rejoignez la riviere"); french.steps[1].SpellButton["7001-1"] = "another spell"
assert(localeSignature ~= fingerprint(french), "Spell names consumed by an action remain mechanical")
for _, key in ipairs({ "label", "Note", "text", "name", "source", "ExtraLineText1" }) do
    assert(fingerprint({ extension = { [key] = "first" } }) ~= fingerprint({ extension = { [key] = "second" } }),
        "Display-looking dictionary keys outside the schema remain meaningful: " .. key)
end
assert(fingerprint({ { Waypoint = 7001, Note = "First" } }) == fingerprint({ { Waypoint = 7001, Note = "Second" } }),
    "Legacy flat routes share the same display-field exclusions")
assert(fingerprint({ steps = { { label = "First", scenarioID = 71, steps = { { Waypoint = 7001, Note = "First" } } } } })
    == fingerprint({ steps = { { label = "Second", scenarioID = 71, steps = { { Waypoint = 7001, Note = "Second" } } } } }),
    "Scenario blocks stored in steps retain localized prose independence")
local _, shortNoteJob = fingerprint({ steps = { { Waypoint = 7001, Note = "short" } } }, 1)
local _, longNoteJob = fingerprint({ steps = { { Waypoint = 7001, Note = string.rep("long note", 2000) } } }, 1)
assert(shortNoteJob.visited == longNoteJob.visited, "Discarded display strings consume no byte-hashing work")
local many = { steps = {} }
for index = 1, 600 do many.steps[index] = { Qpart = { [index + 1000] = { "1" } }, text = string.rep("x", 180) } end
local denseHash, denseJob, denseCalls = fingerprint(many, 3)
assert(denseCalls > 600 and denseJob.visited > 600 and denseHash)
assert(denseHash == fingerprint(many, 97), "Slice size cannot change the fingerprint")
local _, _, stringCalls = fingerprint({ text = string.rep("long value", 2000) }, 1)
assert(stringCalls > 300, "Long scalar strings must be hashed across multiple slices")
local cyclic = {}; cyclic.self = cyclic
local invalidHash, invalidJob = fingerprint(cyclic)
assert(not invalidHash and invalidJob.error == "definition_cycle")
local unsupportedHash, unsupportedJob = fingerprint({ callback = function() end })
assert(not unsupportedHash and unsupportedJob.error == "definition_type")
local afterDone = denseJob.visited
assert(denseJob:Step(1) and denseJob.visited == afterDone and denseJob.lastWork == 0)

local own = { route = "12345678", revision = "abcdef12", progressId = "main:3", step = 3, total = 12 }
local peer = { route = "12345678", revision = "abcdef12", progressId = "main:5", step = 5, total = 12 }
local status, gap = P.CompareProgress(own, peer)
assert(status == "ahead" and gap == 2)
status, gap = P.CompareProgress(peer, own)
assert(status == "behind" and gap == -2)
assert(P.CompareProgress(own, own) == "same")
peer.progressId = "parallel:1:2"
status, gap = P.CompareProgress(own, peer)
assert(status == "different" and gap == nil)
peer.progressId, peer.step = "parallel:1:1", 3
assert(P.CompareProgress(peer, peer) == "same")
peer.revision = "ffffffff"; assert(P.CompareProgress(own, peer) == "unknown")
peer.route = "87654321"; assert(P.CompareProgress(own, peer) == "other")
assert(P.CompareProgress(nil, peer) == "unknown")
local malformed = { route = "12345678", revision = "abcdef12", progressId = "main:3" }
assert(P.CompareProgress(malformed, malformed) == "unknown", "Missing positions cannot claim exact progress")

local query = { id = "q-1", context = "11111111", route = "12345678", revision = "abcdef12",
    progressId = "main:3", step = 3, total = 12, mode = "nearby", range = 5,
    minLevel = 0, maxLevel = 0, primary = "fr", languages = 3 }
local wire = assert(P.Encode("Q", query))
assert(wire == "1|Q|q-1|11111111|12345678|abcdef12|main:3|3|12|nearby|5|0|0|fr|3")
local decoded = assert(P.Decode(wire))
assert(decoded.kind == "Q" and decoded.range == 5 and decoded.languages == 3 and decoded.total == 12)
local worldQuery = {id = "world-query", context = "11111111", route = "00000000", revision = "00000000",
    progressId = "unknown", step = 0, total = 0, mode = "world", range = 5,
    minLevel = 10, maxLevel = 30, primary = "fr", languages = 3}
local worldWire = assert(P.Encode("Q", worldQuery))
local worldDecoded = assert(P.Decode(worldWire))
assert(worldDecoded.mode == "world" and worldDecoded.route == "00000000"
    and worldDecoded.minLevel == 10 and worldDecoded.maxLevel == 30)
worldQuery.mode = "unsupported-scope"
assert(not P.Encode("Q", worldQuery), "The new scope does not allow arbitrary modes")
assert(P.Encode("W", {}) == "1|W" and P.Decode("1|W").kind == "W")
assert(P.Encode("D", { id = "done-7" }) == "1|D|done-7")
assert(P.Encode("R", { id = "i-1", status = "declined" }) == "1|R|i-1|declined")
assert(P.Decode("1|R|i-1|accepted").status == "accepted")
local presence = { id = "q-1", context = "11111111", route = "12345678", revision = "abcdef12",
    progressId = "parallel:1:2", step = 3, total = 12, map = 9, level = 20, class = 8,
    primary = "fr", languages = 3, groupSize = 1, leader = true, recruiting = false,
    afk = false, dnd = false, warMode = true }
local presenceWire = assert(P.Encode("P", presence))
assert(presenceWire == "1|P|q-1|11111111|12345678|abcdef12|parallel:1:2|3|12|9|20|8|fr|3|1|1|0|0|0|1|auto")
local result = assert(P.Decode(presenceWire))
assert(result.leader == true and result.recruiting == false and result.warMode == true and result.languageSource == "auto")
presence.languageSource = "player"
assert(P.Decode(assert(P.Encode("P", presence))).languageSource == "player")
local invite = { id = "i-1", route = "00000000", revision = "00000000", progressId = "unknown", step = 0, total = 0 }
assert(P.Encode("I", invite) == "1|I|i-1|00000000|00000000|unknown|0|0")
invite.route, invite.revision, invite.progressId, invite.step, invite.total = "12345678", "abcdef12", "end", 13, 12
assert(P.Decode(assert(P.Encode("I", invite))).progressId == "end")
invite.id, invite.step, invite.total = string.rep("n", 32), 1000001, 1000000
assert(P.Decode(assert(P.Encode("I", invite))).step == 1000001, "The end position after the maximum authored step is valid")
invite.id = string.rep("n", 33); assert(not P.Encode("I", invite))
local noLanguages = {}; for key, value in pairs(query) do noLanguages[key] = value end
noLanguages.primary, noLanguages.languages = "", 0
assert(P.Decode(assert(P.Encode("Q", noLanguages))).languages == 0)
for _, bad in ipairs({
    "", "2|W", "1|Z", "1|W|extra", "1|D|", "1|D|x|extra", "1|D|name space", "1|D|é", "1|R|i-1|cancelled",
    wire .. "|surplus", wire:gsub("main:3", "main:0"), wire:gsub("main:3", "main:4"),
    wire:gsub("nearby", "anything"), wire:gsub("|fr|3$", "|fr|1"), wire:gsub("|fr|3$", "|fr|1024"),
    wire:gsub("abcdef12", "badvalue"), presenceWire:gsub("|20|8|", "|0|8|"),
    presenceWire:gsub("|20|8|", "|20|21|"), presenceWire:gsub("|1|auto$", "|true|auto"),
    "1|D|" .. string.rep("x", 241), "1|D|x\n", "1|D|x\0",
}) do assert(not P.Decode(bad), "Reject malformed discovery payload: " .. bad) end
for _, change in ipairs({ { "step", -1 }, { "step", 0 / 0 }, { "total", math.huge },
    { "range", 101 }, { "languages", 1024 }, { "primary", "fake" }, { "id", "|Hbad" },
    { "minLevel", "1" }, { "context", {} } }) do
    local copy = {}; for key, value in pairs(query) do copy[key] = value end
    copy[change[1]] = change[2]
    assert(not P.Encode("Q", copy), "Local payload validation: " .. change[1])
end
local bounds = {}; for key, value in pairs(query) do bounds[key] = value end
bounds.minLevel, bounds.maxLevel = 30, 20
assert(not P.Encode("Q", bounds))
presence.recruiting = 1; assert(not P.Encode("P", presence))
assert(not P.Encode("unknown", {}) and not P.Decode({}))
print("Companion protocol: strict bounded packets, language policies, stable progress and incremental fingerprints passed")
