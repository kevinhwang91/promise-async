local promise = require('promise')
local utils = require('promise-async.utils')
local compat = require('promise-async.compat')
local errFactory = require('promise-async.error')
local shortSrc = debug.getinfo(1, 'S').short_src

---@class Async
---@overload fun(executor: fun()): Promise
local Async = setmetatable({}, {
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

local function isPacked(o)
    return type(o) == 'table' and o._id == packedId
end

local function wrapFenv()
    local function result(ok, ...)
        if ok then
            return true, ...
        end
        local err = select(1, ...)
        return false, errFactory.isInstance(err) and err:peek() or err
    end

    return {
        await = Async.wait,
        pcall = function(f, ...)
            return result(compat.pcall(f, ...))
        end,
        xpcall = function(f, msgh, ...)
            return compat.xpcall(f, function(err)
                return msgh(errFactory.isInstance(err) and err:peek() or err)
            end, ...)
        end
    }
end

local function getNewFenv(call)
    return setmetatable(wrapFenv(), {
        __index = compat.getfenv(call)
    })
end

local function buildError(thread, level, err)
    if not errFactory.isInstance(err) then
        err = errFactory.new(err)
        level = level + 1
    end
    local ok, value
    repeat
        ok, value = errFactory.format(thread, level, shortSrc)
        level = level + 1
        err:push(value)
    until not ok
    return err
end

---Export wait function to someone needs
---@param executor fun()
---@return Promise
function Async.sync(executor)
    local typ = type(executor)
    local isCallable, call = utils.getCallable(executor, typ)
    assert(isCallable, 'a callable table or function expected, got ' .. typ)
    compat.setfenv(call, getNewFenv(call))
    return promise.new(function(resolve, reject)
        local co = coroutine.create(typ == 'function' and executor or function()
            return executor()
        end)

        local function afterResume(status, ...)
            if not status then
                local reason = select(1, ...)
                reject(reason)
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

---Export wait function to someone needs, wait function actually have been injected as `async`
---into the executor of async function
---@param p Promise|table
---@return ...
function Async.wait(p)
    p = promise.resolve(p)
    local err, res = coroutine.yield(p)
    if err then
        error(buildError(coroutine.running(), 2, res))
    elseif isPacked(res) then
        return compat.unpack(res)
    else
        return res
    end
end

return Async
