-- A bounded diagnostic must also bound work before discarding a large payload.
local D = APRInstrumentation
assert(D.Value("line\nnext\t|color\r") == "line next ||color ")
assert(D.Value(false) == "false" and D.Value(nil) == "nil")

local plain = string.rep("x", 2000000)
local escaped = string.rep("|\n\t\r", 500000)
local originalGsub, scanned = string.gsub, 0
string.gsub = function(subject, ...)
    assert(#subject <= 240, "Diagnostic sanitization must never scan an entire large string")
    scanned = scanned + #subject
    return originalGsub(subject, ...)
end
local plainResult = D.Value(plain)
local escapedResult = D.Value(escaped)
local nested = D.Value({payload = plain})
string.gsub = originalGsub
assert(plainResult == string.rep("x", 240))
assert(escapedResult == string.rep("||   ", 48), "Truncation preserves whitespace and pipe escaping")
assert(nested == "{payload=" .. string.rep("x", 240) .. "}")
assert(scanned <= 1000, "Multiple megabyte inputs require only bounded prefix scans")

-- Prefixes near the output boundary must preserve the existing byte contract.
assert(D.Value(string.rep("a", 238) .. "|suffix") == string.rep("a", 238) .. "||")
assert(D.Value(string.rep("a", 239) .. "\nrest") == string.rep("a", 239) .. " ")
print("Diagnostic values: bounded input scans, large nested payloads, whitespace, pipes and truncation passed")
