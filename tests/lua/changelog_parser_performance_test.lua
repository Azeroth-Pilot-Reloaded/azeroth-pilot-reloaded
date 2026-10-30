-- The changelog is editable prose, not a maintained release fixture. Exercise
-- supported Markdown and malformed synthetic text without freezing real notes.
APR = {}
function APR:NewModule() return {} end
function APR:WrapTextWithAppearanceColor(text, _, role) return "<" .. role .. ">" .. text .. "</>" end
function LibStub() return { GetLocale = function() return {} end } end
dofile("APR-Core/ui/panels/ChangeLog.lua")
local log = APR.changelog
assert(log:ParseFormatting("Voir [les nouveautés](https://exemple.test/été?q=50%) et [l'aide](guide).")
    == "Voir les nouveautés (https://exemple.test/été?q=50%) et l'aide (guide).")
assert(log:ParseFormatting("[a[b](c)") == "a[b (c)", "Nested opening brackets retain the existing label contract")
assert(log:ParseFormatting("[][texte](url)") == "[]texte (url)")
assert(log:ParseFormatting("[vide]() et [URL](https://exemple.test)") == "[vide]() et URL (https://exemple.test)")
assert(log:ParseFormatting("[nom] puis [suite](url)") == "[nom] puis suite (url)")
assert(log:ParseFormatting("[nom](sans fin [autre]") == "[nom](sans fin [autre]")
assert(log:ParseFormatting("\\[lien\\](url) et `[code](url)`") == "[lien](url) et <accent>[code](url)</>")
assert(log:ParseFormatting("**fort** _normal_ et ~~ancien~~ | marque")
    == "<accent>fort</> _normal_ et <muted>ancien</> || marque")
local heading = log:ParseBlocks("## Titre français  \t###")[1]
assert(heading.kind == "heading" and heading.text == "Titre français" and heading.indent == 8)
assert(log:ParseBlocks("# Titre###")[1].text == "Titre###")
assert(log:ParseBlocks("# Titre ###  ")[1].text == "Titre ###  ", "Closing hashes followed by whitespace remain literal")
assert(log:ParseBlocks("# ###")[1].text == "###")
assert(log:ParseBlocks("# Titre\v\f###")[1].text == "Titre", "Closing headings accept all Lua whitespace characters")
local blocks = log:ParseBlocks("v1.2.3\n\n- [Aide](url)\n> **Attention**\n```lua\n[x](url) | code\n```")
assert(#blocks == 4 and blocks[1].kind == "version" and blocks[2].kind == "list"
    and blocks[2].text == "–  Aide (url)" and blocks[3].kind == "quote"
    and blocks[3].text == "<accent>Attention</>" and blocks[4].kind == "code"
    and blocks[4].text == "[x](url) || code")

local find, gsub, match, gmatch, sub = string.find, string.gsub, string.match, string.gmatch, string.sub
local scanned = 0
string.find = function(subject, pattern, initial, plain)
    local first, last = find(subject, pattern, initial, plain)
    scanned = scanned + (plain and ((first or #subject + 1) - (initial or 1) + #pattern) or #subject)
    return first, last
end
string.gsub = function(subject, pattern, ...)
    assert(pattern ~= "%[([^%]]+)%]%(([^%)]+)%)" and pattern ~= "%s+#+$",
        "Malformed Markdown cannot use the old unanchored repeated-suffix searches")
    scanned = scanned + #subject
    return gsub(subject, pattern, ...)
end
string.match = function(subject, ...)
    scanned = scanned + #subject
    return match(subject, ...)
end
string.gmatch = function(subject, ...)
    scanned = scanned + #subject
    return gmatch(subject, ...)
end
string.sub = function(subject, first, last)
    local result = sub(subject, first, last)
    scanned = scanned + #result
    return result
end
local previousLinks, previousHeading = 0, 0
for _, count in ipairs({ 1000, 2000, 4000, 8000 }) do
    local brackets = string.rep("[", count)
    scanned = 0
    assert(log:ParseFormatting(brackets) == brackets)
    local linkWork = scanned
    assert(linkWork < count * 30, "An unmatched bracket run needs only a fixed number of scans")
    if previousLinks > 0 then assert(linkWork < previousLinks * 2.1, "Doubling malformed brackets cannot quadruple parser work") end
    previousLinks = linkWork

    local text = "Titre " .. string.rep(" ", count) .. "suffix"
    scanned = 0
    assert(log:ParseBlocks("## " .. text)[1].text == text)
    local headingWork = scanned
    assert(headingWork < count * 50, "A long heading's internal spaces cannot trigger repeated suffix searches")
    if previousHeading > 0 then assert(headingWork < previousHeading * 2.1, "Doubling internal heading whitespace stays linear") end
    previousHeading = headingWork
end
local missingURL = string.rep("[nom](", 2000)
scanned = 0
assert(log:ParseFormatting(missingURL) == missingURL)
assert(scanned < #missingURL * 30, "An absent URL close must not rescan every nested link opener")
local invalidLabels = string.rep("[[[[nom] puis ", 1000)
scanned = 0
assert(log:ParseFormatting(invalidLabels) == invalidLabels)
assert(scanned < #invalidLabels * 30, "Invalid URLs share one label-close scan for their opening brackets")
local valid = string.rep("[étiquette](url) ", 1000)
scanned = 0
assert(log:ParseFormatting(valid) == string.rep("étiquette (url) ", 1000))
assert(scanned < #valid * 30, "Complete links also preserve linear scanning/copying work")
string.find, string.gsub, string.match, string.gmatch, string.sub = find, gsub, match, gmatch, sub
print("Changelog parser: French Markdown/URLs/code, incomplete brackets/URLs and long heading spaces preserve output with linear scan work")
