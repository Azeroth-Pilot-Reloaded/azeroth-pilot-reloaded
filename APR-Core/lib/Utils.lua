--[[
Return a string with surrounding stars

TextWithStars("hello")          -- "\*\* hello \*\*"

TextWithStars("hello", 3)       -- "\*\*\* hello \*\*\*"

TextWithStars("hello", 4, true) -- "\*\*\*\* hello"

TextWithStars("hello", 0)       -- "hello"
]]
function TextWithStars(text, count, onlyLeft)
    count = count or 2;

    if count < 1 then
        return text;
    end

    onlyLeft = onlyLeft or false;

    local stars = string.rep("*", count);

    if onlyLeft then
        return stars .. " " .. text;
    end

    return stars .. " " .. text .. " " .. stars;
end
