--[[
Return a string with surrounding stars

textWithStars("hello")          -- "** hello **"
textWithStars("hello", 3)       -- "*** hello ***"
textWithStars("hello", 4, true) -- "**** hello"
textWithStars("hello", 0)       -- "hello"
]]
function textWithStars(text, count, onlyLeft)
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
