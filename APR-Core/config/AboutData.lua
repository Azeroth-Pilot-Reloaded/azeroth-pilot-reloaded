-- Verified project credits (README and route metadata), shared by the workspace and Blizzard settings.
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
APR.AboutData = {}
local Data = APR.AboutData
Data.credits = {
    {key = "author", label = "AUTHOR", names = "Neoldric (Neogeekmo)"},
    {key = "dev", label = "DEV", names = "Neoldric, Kamian"},
    {key = "route_designer", label = "ROUTE_DESIGNER", names = "Pahonix, Ola, Clara, Jumbonero"},
    {key = "graphic", label = "ABOUT_GRAPHIC", names = "Rycia, Neoldric"},
    {key = "support", label = "ABOUT_SUPPORT", names = "NightofStarrs, Pahonix"},
    {key = "Translator", label = "ABOUT_TRANSLATOR", names = function()
        return table.concat({FRFR .. ": Neogeekmo, Jmsche, Mania", DEDE .. ": Kamian, Movion",
            ESMX .. ": Jean", RURU .. ": ZamestoTV"}, "\n")
    end},
}

function Data:GetCredits()
    local rows = {}
    for _, credit in ipairs(self.credits) do
        rows[#rows + 1] = {key = credit.key,
            title = string.format(L[credit.label], ""):gsub("%s*：%s*$", ""):gsub("%s*:%s*$", ""),
            text = type(credit.names) == "function" and credit.names() or credit.names}
    end
    rows[#rows + 1] = {title = L["LEGACY"], text = L["WELCOME_ZYRR"] .. "\n" ..
        "Deathmessenger, DesMephisto, BrutallStatic, TeddyRuxpins"}
    return rows
end

function Data:GetCreditLine(key)
    for _, entry in ipairs(self:GetCredits()) do
        if entry.key == key then return entry.title .. ": " .. entry.text end
    end
end

-- Count loaded definitions, never generate quest steps or a filtered catalog to display these facts.
function Data:GetRouteSummary()
    local count, expansions, authors = 0, {}, {}
    for key, route in pairs(APR.RouteQuestStepList or {}) do
        if type(route) == "table" and type(route.steps) == "table" then
            count = count + 1
            if route.expansion then expansions[route.expansion] = true end
            local author = APR:GetRouteAttribution(key)
            if author ~= "APR" then authors[author] = true end
        end
    end
    local expansionCount, names = 0, {}
    for _ in pairs(expansions) do expansionCount = expansionCount + 1 end
    for author in pairs(authors) do names[#names + 1] = author end
    table.sort(names)
    return count, expansionCount, table.concat(names, ", ")
end
