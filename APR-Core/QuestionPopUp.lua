local _G = _G
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

-- Initialize module
APR.questionDialog = APR:NewModule("QuestionDialog")

---------------------------------------------------------------------------------------
------------------------- Question Dialog for skippable quest -------------------------
---------------------------------------------------------------------------------------
function APR.questionDialog:CreateQuestionPopup(text, onAcceptFunction, OnCancelFunction)
    local dialogName = "QUESTION_DIALOG"
    StaticPopupDialogs[dialogName] = {
        text = text,
        button1 = ACCEPT,
        button2 = CANCEL,
        OnAccept = onAcceptFunction,
        OnCancel = OnCancelFunction,
        timeout = 0,
        whileDead = true,
        hideOnEscape = false,
    }

    StaticPopup_Show(dialogName)
end
