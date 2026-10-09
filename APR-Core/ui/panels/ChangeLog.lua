-- Release notes use one formatter for startup and the Options page; no separate legacy window.
local L = LibStub("AceLocale-3.0"):GetLocale("APR")
APR.changelog = APR:NewModule("ChangeLog")

function APR.changelog:OnInit()
    if APR.LayoutEditor and APR.LayoutEditor.firstUsePending then return end
    if APR.version ~= APR.settings.profile.lastRecordedVersion and APR.settings.profile.showChangeLog then
        self:ShowChangeLog()
    end
end

function APR.changelog:ShowChangeLog()
    APR.Workspace:Show("options", "changelog")
end

function APR.changelog:GetText()
    return self:ParseChangelogText((L["New Changelog"] or "") .. "\n" .. (L["Prev Changelog"] or ""))
end

function APR.changelog:GetBlocks()
    return self:ParseBlocks((L["New Changelog"] or "") .. "\n\n" .. (L["Prev Changelog"] or ""))
end

function APR.changelog:SetChangeLog()
    local options = APR.OptionsPanel
    if options and options.frame and options.frame:IsShown() and options.selected == "changelog" then
        -- AceConfig does not track externally supplied containers in its NotifyChange refresh list.
        options:Select("changelog")
    end
end

function APR.changelog:ParseFormatting(text)
    -- Protect literal code/escaped punctuation before interpreting emphasis.
    local literals = {}
    local function literal(value)
        literals[#literals + 1] = value
        return "\001" .. #literals .. "\002"
    end
    local function color(value, role) return APR:WrapTextWithAppearanceColor(value, "general", role) end
    text = text:gsub("|", "||"):gsub("\\([%p])", literal)
    text = text:gsub("``(.-)``", function(value) return literal(color(value, "accent")) end)
    text = text:gsub("`([^`]+)`", function(value) return literal(color(value, "accent")) end)
    text = text:gsub("%[([^%]]+)%]%(([^%)]+)%)", function(label, url) return label .. " (" .. url .. ")" end)
    for _, pattern in ipairs({"%*%*%*(.-)%*%*%*", "%*%*(.-)%*%*", "__(.-)__", "%*([^*]+)%*"}) do
        text = text:gsub(pattern, function(value) return color(value, "accent") end)
    end
    text = text:gsub("~~(.-)~~", function(value) return color(value, "muted") end)
    return (text:gsub("\001(%d+)\002", function(index) return literals[tonumber(index)] end))
end

function APR.changelog:ParseBlocks(text)
    local blocks, code, fence, gap = {}, nil, nil, 0
    local function append(kind, value, indent, size, role)
        blocks[#blocks + 1] = {kind = kind, text = value, indent = indent or 0,
            size = size or 12, role = role or "base", gap = gap}
        gap = 0
    end
    for line in (text:gsub("\r\n", "\n") .. "\n"):gmatch("([^\n]*)\n") do
        local marker = line:match("^%s*(```+)") or line:match("^%s*(~~~+)")
        if code then
            if marker and marker:sub(1, 1) == fence:sub(1, 1) and #marker >= #fence then
                append("code", table.concat(code, "\n"), 12)
                code, fence = nil, nil
            else code[#code + 1] = line:gsub("|", "||") end
        elseif marker then
            code, fence = {}, marker
        elseif not line:find("%S") or line:match("^%s*%-%-%-+%s*$") then
            gap = 10
        else
            local heading, title = line:match("^%s*(#+)%s+(.+)")
            local plain = title or line
            if plain:match("^v?%d+%.%d+%.%d+") then
                gap = #blocks > 0 and 18 or 0
                append("version", self:ParseFormatting(plain), 0, 18, "accent")
            elseif heading then
                gap = math.max(gap, 10)
                append("heading", self:ParseFormatting(title:gsub("%s+#+$", "")), (#heading - 1) * 8, 14, "accent")
            else
                local indent, bullet, body = line:match("^(%s*)([%-%*+])%s+(.+)")
                if not bullet then indent, bullet, body = line:match("^(%s*)(%d+%.)%s+(.+)") end
                if bullet then
                    append("list", (bullet:match("%d") and bullet or "–") .. "  " .. self:ParseFormatting(body), #indent * 6 + 4)
                elseif line:match("^%s*>") then
                    append("quote", self:ParseFormatting(line:gsub("^%s*>%s?", "")), 12, 12, "muted")
                else append("paragraph", self:ParseFormatting(line)) end
            end
        end
    end
    if code then append("code", table.concat(code, "\n"), 12) end
    return blocks
end

function APR.changelog:ParseChangelogText(text)
    local lines = {}
    for _, block in ipairs(self:ParseBlocks(text)) do
        if block.gap > 0 then lines[#lines + 1] = "" end
        lines[#lines + 1] = string.rep(" ", math.floor(block.indent / 6)) .. block.text
    end
    return table.concat(lines, "\n")
end
