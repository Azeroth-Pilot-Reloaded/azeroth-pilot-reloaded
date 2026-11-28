-- SPDX-License-Identifier: GPL-3.0-or-later
local lib = LibStub("LibAPRNavigation-1.0")
local runtime = lib._TerrainNamespace
if not lib:BeginModule("TerrainPartitions", 1) then return end

local partitions = setmetatable({}, { __mode = "k" })
local floor = math.floor
local importing = false
local lastImportFrame
local frameToken
local blockSize = 16384
local importStartWindowMs = 0.6

function lib.Instance:HasDeferredTerrainImports(world)
    return self.profile == "forever" and GetTime ~= nil and debugprofilestop ~= nil
        and partitions[runtime.Data(world)] ~= nil
end

-- One native import cannot be interrupted. Drivers share the first callback's
-- start time and stop dispatching work when a worker has to wait for a frame.
function lib.Instance:BeginTerrainFrame()
    if self.profile ~= "forever" or not GetTime or not debugprofilestop then return end
    local frame = GetTime()
    if not frameToken or frameToken.time ~= frame then
        frameToken = { time = frame, started = debugprofilestop() }
    end
    return frameToken
end

local function unsigned(value)
    return type(value) == "number" and value >= 0 and value < math.huge and value == floor(value)
end

local function uint32(bytes, pos)
    local a, b, c, d = bytes:byte(pos, pos + 3)
    return a + 256 * b + 65536 * c + 16777216 * d
end

local function decodeBlock(encoded)
    local block = C_EncodingUtil.DecompressString(C_EncodingUtil.DecodeBase64(encoded), Enum.CompressionMethod.Zlib)
    assert(type(block) == "string" and #block <= blockSize)
    return block
end

local function decodePages(index, data)
    local groupWidth = index.width
    assert(unsigned(data.nx) and data.nx > 0 and unsigned(data.ny) and data.ny > 0)
    local columns
    if index.schema == 1 then
        assert(unsigned(groupWidth) and groupWidth >= 1 and groupWidth <= 16)
        columns = math.ceil(data.ny / groupWidth)
    else
        assert(unsigned(index.groupCount) and index.groupCount > 0 and index.groupCount <= data.nx * data.ny)
        assert(unsigned(index.maxGroupBytes) and index.maxGroupBytes > 0)
    end
    local rows = {}
    for i, encoded in ipairs(index.pages) do rows[i] = decodeBlock(encoded) end
    local bytes = table.concat(rows)
    assert(#bytes > 0 and #bytes % 16 == 0)
    local state = { pageGroup = {}, fields = {}, groups = {}, prefix = index.groupAddOnPrefix }
    if type(index.components) == "table" and type(index.dag) == "table" then
        state.portals = { base = {}, count = {}, total = 0, rawComponents = lib.Copy(index.components),
            rawDag = lib.Copy(index.dag), blocks = {}, ancestors = {}, recent = {} }
    end
    local counts = {}
    assert(#index.fields > 0 and #index.fields <= 16)
    for i, name in ipairs(index.fields) do
        assert((name == "labels" or data.packed[name]) and not state.fields[name])
        state.fields[name] = 2 ^ (i - 1)
        counts[name] = 0
    end
    local groupsSeen = 0
    for p = 1, #bytes, 16 do
        local key, group = uint32(bytes, p), uint32(bytes, p + 4)
        local low, high = bytes:byte(p + 14, p + 15)
        local mask = low + 256 * high
        assert(key >= 1 and key <= data.nx * data.ny and not state.pageGroup[key])
        if state.portals then
            local portals = state.portals
            local base = uint32(bytes, p + 8)
            local n, m = bytes:byte(p + 12, p + 13)
            local count = n + 256 * m
            assert(base == portals.total)
            portals.base[key], portals.count[key], portals.total = base, count, base + count
        end
        if columns then
            assert(group == floor(floor((key - 1) / data.ny) / groupWidth) * columns
                + floor(((key - 1) % data.ny) / groupWidth) + 1)
        else
            assert(group >= 1 and group <= index.groupCount)
        end
        assert(mask < 2 ^ #index.fields)
        local pages = state.groups[group]
        if not pages then
            pages = {}
            state.groups[group] = pages
            groupsSeen = groupsSeen + 1
        end
        pages[key] = mask
        state.pageGroup[key] = group
        for name, bit in pairs(state.fields) do
            if floor(mask / bit) % 2 == 1 then
                counts[name] = counts[name] + 1
            else
                assert(name ~= "grid" and name ~= "graph" and name ~= "height")
            end
        end
    end
    assert(index.schema == 1 or groupsSeen == index.groupCount)
    assert(counts.grid and counts.grid > 0 and counts.graph == counts.grid and counts.height == counts.grid)
    for name, count in pairs(data.counts) do assert((counts[name] or 0) == count) end
    for name, count in pairs(counts) do assert(name == "labels" or data.counts[name] == count) end
    return state
end

local function componentAt(portals, page, index)
    local count = portals.count[page]
    if not count or not unsigned(index) or index == 0 or index > count then return end
    local offset = (portals.base[page] + index - 1) * 4
    local n = floor(offset / blockSize) + 1
    local block = portals.blocks[n]
    if not block then
        local ok, bytes = pcall(decodeBlock, portals.rawComponents[n])
        if not ok or #bytes ~= math.min(blockSize, portals.total * 4 - (n - 1) * blockSize) then return end
        block, portals.blocks[n] = bytes, bytes
    end
    local component = uint32(block, offset % blockSize + 1)
    if component < portals.total then return component end
end

local function incomingComponents(portals)
    if portals.incoming ~= nil then return portals.incoming end
    local incoming = {}
    for _, encoded in ipairs(portals.rawDag) do
        local ok, block = pcall(decodeBlock, encoded)
        if not ok or #block % 8 ~= 0 then portals.incoming = false; return end
        for p = 1, #block, 8 do
            runtime.Work()
            local from, to = uint32(block, p), uint32(block, p + 4)
            if from >= portals.total or to >= portals.total then portals.incoming = false; return end
            local row = incoming[to] or {}
            row[#row + 1] = from
            incoming[to] = row
        end
    end
    portals.incoming = portals.incoming or incoming
    return portals.incoming
end

function runtime.PartitionPortalReachable(data, fromPage, fromIndex, toPage, toIndex)
    local state = partitions[data]
    local portals = state and state.portals
    if not portals or not runtime.active then return end
    local from = componentAt(portals, fromPage, fromIndex)
    local to = componentAt(portals, toPage, toIndex)
    if not from or not to then return end
    if from == to then return true end
    local incoming = incomingComponents(portals)
    if not incoming then return end
    if not incoming[to] then return false end
    local seen = portals.ancestors[to]
    if not seen then
        -- Build privately across yields. Canceled jobs cannot publish a
        -- partial ancestor set as evidence of disconnection.
        seen = { [to] = true }
        local queue, nextNode = { to }, 1
        while nextNode <= #queue do
            local row = incoming[queue[nextNode]]
            nextNode = nextNode + 1
            for i = 1, row and #row or 0 do
                runtime.Work()
                local parent = row[i]
                if not seen[parent] then
                    seen[parent] = true
                    queue[#queue + 1] = parent
                end
            end
        end
        if not portals.ancestors[to] then
            if #portals.recent == 8 then portals.ancestors[table.remove(portals.recent, 1)] = nil end
            portals.ancestors[to] = seen
            portals.recent[#portals.recent + 1] = to
        end
    end
    return seen[from] == true
end

function lib:RegisterTerrainPartitionIndex(profile, world, revision, data, index)
    if profile ~= "forever" or not unsigned(world) or not unsigned(revision)
        or type(index) ~= "table" or (index.schema ~= 1 and index.schema ~= 2) or type(data) ~= "table"
        or index.groupAddOnPrefix ~= "APR_NavData_Forever_" .. world .. "_" then return false end
    local old = runtime.Data(world)
    if old and old.partitionRevision == revision and partitions[old] then return true end
    local ok, state = pcall(decodePages, index, data)
    if not ok then return false end
    local header = {}
    for key, value in pairs(data) do header[key] = value end
    header.partitionSchema, header.partitionRevision = index.schema, revision
    header.componentLabels = header.componentLabels or {}
    self:RegisterTerrainData(profile, world, header, revision)
    local current = runtime.Data(world)
    if not current or current == old or current.partitionRevision ~= revision then return false end
    partitions[current] = state
    return true
end

local function checkGroup(data, state, group, declaration)
    local remaining = {}
    for key, mask in pairs(group) do remaining[key] = mask end
    local function checkField(name, records)
        local bit = state.fields[name]
        for key, blocks in pairs(records) do
            local mask = remaining[key]
            assert(bit and mask and floor(mask / bit) % 2 == 1 and type(blocks) == "table")
            if name ~= "labels" then
                assert(#blocks > 0)
                for i = 1, #blocks do assert(type(blocks[i]) == "string") end
            end
            remaining[key] = mask - bit
        end
    end
    for name, records in pairs(declaration.packed) do
        assert(data.packed[name] and name ~= "labels")
        checkField(name, records)
    end
    checkField("labels", declaration.componentLabels)
    for _, mask in pairs(remaining) do assert(mask == 0) end
    return lib.Copy(declaration)
end

function lib:RegisterTerrainPartitionPages(profile, world, revision, id, declaration)
    if profile ~= "forever" or not unsigned(world) or not unsigned(id) then return false end
    local data = runtime.Data(world)
    local state = data and partitions[data]
    if not state or data.partitionRevision ~= revision then return false end
    local group = state.groups[id]
    if group == true then return true end
    if not group or type(declaration) ~= "table" then return false end
    local ok, pages = pcall(checkGroup, data, state, group, declaration)
    if not ok then return false end
    for name, records in pairs(pages.packed) do
        for key, value in pairs(records) do data.packed[name][key] = value end
    end
    for key, value in pairs(pages.componentLabels) do data.componentLabels[key] = value end
    state.groups[id] = true
    return true
end

function runtime.ValidPartition(data)
    return partitions[data] ~= nil
end

function runtime.EnsureTerrainPage(data, key)
    local state = assert(partitions[data], "missing terrain partition")
    local group = state.pageGroup[key]
    if not group or state.groups[group] == true then return true end
    local job = runtime.active
    if not job or importing then return false end
    -- One synchronous client import can exceed the entire slice. Check the
    -- clock before entering the client, where the worker cannot suspend.
    local frame = GetTime and GetTime()
    local waited = false
    while true do
        local token = frameToken and frameToken.time == frame and frameToken
        -- After a frame boundary the pending request gets a turn even if
        -- preparing this callback again consumed the early import window.
        local late = token and not waited and debugprofilestop() - token.started > importStartWindowMs
        if not job.partitionImportedThisStep and job.clock() < job.deadline
            and not (frame and frame == lastImportFrame) and not (token and token.deferred) and not late then break end
        if token then token.deferred = true end
        job.workLastStep = job.limit
        coroutine.yield()
        if state.groups[group] == true then return true end
        local previous = frame
        frame = GetTime and GetTime()
        waited = waited or previous ~= frame
    end
    assert(C_AddOns and C_AddOns.LoadAddOn, "terrain companion unavailable")
    job.partitionImportedThisStep = true
    lastImportFrame = frame
    importing, runtime.active = true, nil
    local ok, loaded = pcall(C_AddOns.LoadAddOn, state.prefix .. group)
    importing, runtime.active = false, job
    assert(ok and loaded and state.groups[group] == true, "incomplete terrain companion")
    return true
end
