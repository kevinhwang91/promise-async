local promise = require('promise')
local utils = require('promise-async.utils')
local compat = require('promise-async.compat')

local asyncId = {'promise-async'}

---@class Async
local Async = setmetatable({_id = asyncId}, {
    __call = function(self, executor)
        return self.sync(executor)
    end
})

local packedId = {}

local Packed = {_id = packedId}
Packed.__index = Packed

local function wrapPacked(packed)
    return setmetatable(packed, Packed)
end

local function hasPacked(o)
    return type(o) == 'table' and o._id == packedId
end

local function injectENV(fn)
    compat.setfenv(fn, setmetatable({
        await = Async.wait,
        pcall = compat.pcall,
        xpcall = compat.xpcall
    }, {
        __index = compat.getfenv(fn)
    }))
end

function Async.sync(executor)
    local typ = type(executor)
    local isCallable, fn = utils.getCallable(executor, typ)
    assert(isCallable, 'a callable table or function expected, got ' .. typ)
    injectENV(fn)
    return promise:new(function(resolve, reject)
        local co = coroutine.create(typ == 'function' and executor or function()
            return executor()
        end)

        local function afterResume(status, ...)
            if not status then
                local reason = select(1, ...)
                reject(debug.traceback(co, reason))
                return
            elseif coroutine.status(co) == 'dead' then
                local value
                local n = select('#', ...)
                if n == 1 then
                    value = select(1, ...)
                elseif n > 1 then
                    value = wrapPacked({...})
                end
                resolve(value)
                return
            end
            local p = select(1, ...)
            return p
        end

        local function next(err, res)
            local p = afterResume(coroutine.resume(co, err, res))
            if p then
                p:thenCall(function(value)
                    next(false, value)
                end, function(reason)
                    next(true, reason)
                end)
            end
        end

        next()
    end)
end

---Export wait function to someone needs, wait function actually have injected as `await` into
---the executor of async function
---@param p Promise|any
---@return ...
function Async.wait(p)
    p = promise.resolve(p)
    local err, res = coroutine.yield(p)
    if err then
        error(res, 0)
    elseif hasPacked(res) then
        return compat.unpack(res)
    else
        return res
    end
end

return Async
