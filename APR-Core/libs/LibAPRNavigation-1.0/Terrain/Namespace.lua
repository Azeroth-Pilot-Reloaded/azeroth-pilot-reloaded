-- GPL-3.0-or-later. Private loading bridge; Terrain.lua removes it after loading.
local Lib = LibStub("LibAPRNavigation-1.0")
local runtime = {}
Lib._TerrainNamespace = runtime

-- One charged operation contains at most 64 primitive loop checkpoints. This
-- keeps a cell decoder inside the deadline without equating every byte with a
-- planner operation (which would spread a single cold tile over minutes).
-- Every potentially growing loop in the terrain reader and search checkpoints here.
-- No timer or event owns this worker: only the consumer's Job:Step resumes it.
function runtime.Work()
    local job = runtime.active
    if not job then return end
    if job.quantum > 0 then job.quantum = job.quantum - 1; return end
    while job.workLastStep >= job.limit or job.clock() >= job.deadline do
        coroutine.yield()
        job = runtime.active
    end
    job.workLastStep = job.workLastStep + 1
    job.quantum = 63
end
