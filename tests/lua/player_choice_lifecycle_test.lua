-- Real PLAYER_CHOICE_UPDATE dispatch and PickedLoa rendering/progression.
-- Native option/response IDs are invented. The two Loa quest IDs are the
-- renderer's intrinsic client mapping, not assertions about any shipped guide.
local env = dofile("tests/lua/addon_journey_quest_env.lua")
APR.RouteQuestStepList = {}
APRCustomPath.player = {}
local choice, sent, onResponse = nil, {}, nil
C_PlayerChoice = {
    GetCurrentPlayerChoiceInfo = function() return choice end,
    SendPlayerChoiceResponse = function(id)
        sent[#sent + 1] = id
        if onResponse then onResponse(id) end
    end,
}

local serial, failures, passed = 0, {}, 0
local function start(step)
    APR.routeValidationPending, APR.routeValidationFailed = nil, nil
    serial = serial + 1
    local route = "choice-contract-" .. serial
    step.Note = step.Note or "Synthetic choice instruction"
    APR.RouteQuestStepList[route] = { label = "Synthetic choice", mapID = 10,
        steps = { step, { Note = "Choice completed" } } }
    APRData.player[route] = 1
    APRCustomPath.player[#APRCustomPath.player + 1] = route
    assert(APR:ActivateRoute(route, "choice_test"))
    APR:UpdateQuestAndStep()
    H.settle()
    return route
end
local function update()
    H.emit("PLAYER_CHOICE_UPDATE")
    H.settle()
end
local function progress(route, expected, message)
    assert(APRData.player[route] == expected, message)
end
local function offered(id, buttonID)
    return { id = id, disabledOption = false, buttons = { { id = buttonID, disabled = false } } }
end
local function run(name, test)
    choice, sent, onResponse = nil, {}, nil
    APR.routeValidationPending, APR.routeValidationFailed = nil, nil
    H.errors = {}
    local ok, err = pcall(test)
    if ok then passed = passed + 1 else failures[#failures + 1] = name .. ": " .. tostring(err) end
    -- Continue independent cases so one rejected boundary does not hide the
    -- behavior of the other choice type or the native Loa mapping.
    onResponse = nil
    APR.routeValidationPending, APR.routeValidationFailed = nil, nil
    H.errors = {}
end

for _, action in ipairs({ "Brewery", "SparringRing" }) do
    run(action .. " native response and repeat", function()
        local route = start({ [action] = 31 })
        update()
        progress(route, 1, "A closed/unavailable player choice must not progress")
        assert(#sent == 0, "No native choice means no response")
        choice = { options = {} }
        update()
        progress(route, 1, "An empty option list must not progress")
        choice = { options = { offered(32, 3201) } }
        update()
        progress(route, 1, "An unrelated option must not progress")
        assert(#sent == 0, "Unrelated native options must not receive a response")
        choice = { options = { offered(32, 3201), offered(31, 3101), offered(33, 3301) } }
        choice.options[2].buttons[2] = { id = 3102, disabled = false }
        update()
        assert(#sent == 1 and sent[1] == 3101, "Send the matching option's first native response ID only")
        progress(route, 2, "A valid native response must complete the current choice")
        update()
        assert(#sent == 1, "A repeated update on the following instruction must not resubmit the choice")
        progress(route, 2, "A repeated native choice update must not skip the next instruction")
    end)
end

run("validation gates", function()
    local route = start({ Brewery = 41 })
    choice = { options = { offered(41, 4101) } }
    APR.routeValidationPending = {}
    update()
    progress(route, 1, "Fingerprint validation must block native choice effects")
    assert(#sent == 0, "Pending validation must not send a response")
    APR.routeValidationPending, APR.routeValidationFailed = nil, true
    update()
    progress(route, 1, "Failed validation must retain progress")
    assert(#sent == 0, "Failed validation must not send a response")
    APR.routeValidationFailed = nil
    update()
    assert(#sent == 1 and sent[1] == 4101, "Validation recovery must allow the current response")
    progress(route, 2, "Recovery must complete the matching choice once")
end)

run("late data after route change", function()
    local previous = start({ Brewery = 51 })
    update()
    local current = start({ SparringRing = 52 })
    choice = { options = { offered(51, 5101) } }
    update()
    assert(#sent == 0, "Late options for an old route must not be selected")
    progress(previous, 1, "Late data must not change the inactive route")
    progress(current, 1, "Late data must not complete a different current choice")
    choice = { options = { offered(52, 5201) } }
    update()
    assert(#sent == 1 and sent[1] == 5201, "The replacement route must select its own native response")
    progress(current, 2, "The replacement route must remain completable")
end)

-- Disabled choices and empty button arrays are native data states. Neither a
-- response attempt nor the presence of a matching option proves availability.
for _, boundary in ipairs({ "disabled option", "disabled button", "empty buttons" }) do
    run(boundary, function()
        local route = start({ Brewery = 61 })
        local option = offered(61, 6101)
        if boundary == "disabled option" then option.disabledOption = true
        elseif boundary == "disabled button" then option.buttons[1].disabled = true
        else option.buttons = {} end
        choice = { options = { option } }
        update()
        assert(#sent == 0, "An unavailable native response must not be sent")
        progress(route, 1, "An unavailable native response must not complete a choice")
        choice = { options = { offered(61, 6101) } }
        update()
        assert(#sent == 1 and sent[1] == 6101, "A later available response must recover without losing the step")
        progress(route, 2, "A previously unavailable choice must complete when available")
    end)
end

-- PLAYER_CHOICE_CLOSE is synchronous in the native contract. A listener may
-- change route while SendPlayerChoiceResponse closes that UI; the response
-- still belongs to the captured old step, never the replacement route.
run("synchronous native close changes context", function()
    local previous = start({ SparringRing = 71 })
    local replacement = "choice-replacement-during-close"
    APR.RouteQuestStepList[replacement] = { label = "Synthetic replacement", mapID = 10,
        steps = { { Note = "Keep this instruction" }, { Note = "Replacement finish" } } }
    APRData.player[replacement] = 1
    APRCustomPath.player[#APRCustomPath.player + 1] = replacement
    choice = { options = { offered(71, 7101) } }
    onResponse = function()
        assert(APR:ActivateRoute(replacement, "synthetic_choice_close_listener"))
        APR:UpdateStep()
    end
    update()
    assert(#sent == 1 and sent[1] == 7101, "The original context must send its matching response once")
    progress(previous, 1, "Changing context during a native response must not mutate inactive progress")
    progress(replacement, 1, "A native response must never complete a replacement route's instruction")
end)

local function clearProof()
    H.quests, H.order, H.rewarded, APR.ActiveQuests = {}, {}, {}, {}
end
for _, mapping in ipairs({ { loa = 1, quest = 47439, opposite = 47440 },
    { loa = 2, quest = 47440, opposite = 47439 } }) do
    run("PickedLoa " .. mapping.loa .. " accepted", function()
        clearProof()
        local route = start({ PickedLoa = mapping.loa })
        progress(route, 1, "Absent native Loa proof must preserve the instruction")
        H.quest(mapping.opposite)
        APR:UpdateQuestAndStep()
        progress(route, 1, "The other Loa's accepted quest must not complete this variant")
        H.quest(mapping.quest)
        APR:UpdateQuestAndStep()
        assert(APR.ActiveQuests[mapping.quest], "The accepted proof must come through the real native quest cache")
        progress(route, 2, "The matching accepted native quest must complete this Loa variant")
        APR:UpdateQuestAndStep()
        progress(route, 2, "Re-rendering accepted Loa proof must not skip the following instruction")
    end)
    run("PickedLoa " .. mapping.loa .. " completed", function()
        clearProof()
        H.rewarded[mapping.opposite] = true
        local route = start({ PickedLoa = mapping.loa })
        progress(route, 1, "The other Loa's completed native quest must not complete this variant")
        H.rewarded[mapping.quest] = true
        APR:UpdateStep()
        assert(not APR.ActiveQuests[mapping.quest], "Completed proof must work without an accepted quest in the cache")
        progress(route, 2, "The matching native completion flag must complete this Loa variant")
        APR:UpdateStep()
        progress(route, 2, "Repeated completed Loa proof must advance only once")
    end)
end

assert(#failures == 0, table.concat(failures, "\n"))
assert(passed == 12, "Every independent native player-choice lifecycle must execute")
