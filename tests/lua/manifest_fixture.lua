-- Offline client-aware XML loading; data filters keep engine inputs synthetic.
local function read(path)
    local file = assert(io.open(path))
    local text = file:read("*a")
    file:close()
    return text
end

return function(path, options)
    options = options or {}
    local visited, load = {}, options.load or dofile
    local function visit(current)
        if visited[current] or (options.skip and options.skip(current)) then return end
        if not options.terrainData and current:find("/Data/forever/Terrain/", 1, true) then return end
        visited[current] = true
        if current:sub(-4) ~= ".xml" then load(current); return end
        local xml = (options.read or read)(current):gsub("<!%-%-.-%-%->", "")
        local directory = current:match("^(.*[/])") or ""
        for tag, reference in xml:gmatch('<(%w+)%s+[^>]-file%s*=%s*"([^"]+)"[^>]*>') do
            if tag == "Script" or tag == "Include" then
                reference = reference:gsub("\\", "/"):gsub("%[Game%]", options.game or "Standard")
                visit(directory .. reference)
            end
        end
    end
    visit(path)
    return visited
end
