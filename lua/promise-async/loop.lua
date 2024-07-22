local uv = require('luv')

---@class PromiseAsyncLoop
---@field tick userdata
---@field tickCallbacks function[]
---@field tickStarted boolean
---@field idle userdata
---@field idleCallbacks function[]
---@field idleStarted boolean
local EventLoop = {
    tick = uv.new_timer(),
    tickCallbacks = {},
    tickStarted = false,
    idle = uv.new_idle(),
    idleCallbacks = {},
    idleStarted = false
}

function EventLoop.setTimeout(callback, ms)
    local timer = uv.new_timer()
    timer:start(ms, 0, function()
        timer:close()
        EventLoop.callWrapper(callback)
    end)
    return timer
end

local function runTick()
    EventLoop.tickStarted = true
    local callbacks = EventLoop.tickCallbacks
    EventLoop.tickCallbacks = {}
    for _, cb in ipairs(callbacks) do
        EventLoop.callWrapper(cb)
    end
    if #EventLoop.tickCallbacks > 0 then
        EventLoop.tick:start(0, 0, runTick)
    else
        EventLoop.tickStarted = false
    end
    -- luv loop has invoked close method if the timer has finished
    -- EventLoop.tick:close()
end

function EventLoop.nextTick(callback)
    table.insert(EventLoop.tickCallbacks, callback)
    if not EventLoop.tickStarted then
        EventLoop.tick:start(0, 0, runTick)
    end
end

local function runIdle()
    EventLoop.idleStarted = true
    local callbacks = EventLoop.idleCallbacks
    EventLoop.idleCallbacks = {}
    for _, cb in ipairs(callbacks) do
        EventLoop.callWrapper(cb)
    end
    if #EventLoop.idleCallbacks == 0 then
        EventLoop.idleStarted = false
        EventLoop.idle:stop()
    end
end

function EventLoop.nextIdle(callback)
    EventLoop.nextTick(function()
        table.insert(EventLoop.idleCallbacks, callback)
        if not EventLoop.idleStarted then
            EventLoop.idle:start(runIdle)
        end
    end)
end

if vim and type(vim.schedule) == 'function' then
    EventLoop.callWrapper = vim.schedule
else
    -- https://github.com/luvit/luv/pull/665 can throw the non-string error since 1.46 version
    function EventLoop.callWrapper(fn) fn() end
end

return EventLoop
