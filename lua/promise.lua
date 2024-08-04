local utils = require('promise-async.utils')
local promiseId = {'promise-async'}
local errFactory = require('promise-async.error')
local shortSrc = debug.getinfo(1, 'S').short_src

---@alias PromiseState
---| 1 #PENDING
---| 2 #FULFILLED
---| 3 #REJECTED
local PENDING = 1
local FULFILLED = 2
local REJECTED = 3

--
---@class Promise
---@field state PromiseState
---@field result any
---@field queue table
---@field needHandleRejection? boolean
---@field err? PromiseAsyncError
local Promise = setmetatable({_id = promiseId}, {
    __call = function(self, executor)
        return self:new(executor)
    end
})
Promise.__index = Promise

local function loadEventLoop()
    local success, res = pcall(require, 'promise-async.loop')
    assert(success, 'Promise need an EventLoop, ' ..
        'luv module or a customized EventLoop module is expected.')
    return res
end

if vim then
    -- `require` in Neovim is hacked by its get_runtime API, may throw an error while calling
    -- `require` in libuv, require at once as a workaround.
    Promise.loop = require('promise-async.loop')
else
    Promise.loop = setmetatable({}, {
        __index = function(_, key)
            local loop = loadEventLoop()
            rawset(Promise, 'loop', loop)
            return loop[key]
        end,
        __newindex = function(_, key, value)
            local loop = loadEventLoop()
            rawset(Promise, 'loop', loop)
            Promise.loop[key] = value
        end
    })
end


function Promise:__tostring()
    local state = self.state
    if state == PENDING then
        return 'Promise { <pending> }'
    elseif state == REJECTED then
        return ('Promise { <rejected> %s }'):format(tostring(self.result))
    else
        return ('Promise { <fulfilled> %s }'):format(tostring(self.result))
    end
end

local function noop() end

---@param o any
---@param typ? string
---@return boolean
function Promise.isInstance(o, typ)
    return (typ or type(o)) == 'table' and o._id == promiseId
end

---must get `thenCall` field from `o` at one time, can't call repeatedly.
---@param o any
---@param typ? type
---@return function?
local function getThenable(o, typ)
    local thenCall
    if (typ or type(o)) == 'table' then
        thenCall = o.thenCall
        if type(thenCall) ~= 'function' then
            thenCall = nil
        end
    end
    return thenCall
end

local resolvePromise, rejectPromise

---@param promise Promise
local function handleQueue(promise)
    local queue = promise.queue
    if #queue == 0 then
        return
    end
    if promise.needHandleRejection and #queue > 0 then
        promise.needHandleRejection = nil
    end
    promise.queue = {}

    Promise.loop.nextTick(function()
        local state, result = promise.state, promise.result
        for _, q in ipairs(queue) do
            local newPromise, onFulfilled, onRejected = q[1], q[2], q[3]
            local func
            if state == FULFILLED then
                if utils.getCallable(onFulfilled) then
                    func = onFulfilled
                else
                    resolvePromise(newPromise, result)
                end
            elseif state == REJECTED then
                if utils.getCallable(onRejected) then
                    func = onRejected
                else
                    rejectPromise(newPromise, result)
                end
            end
            if func then
                local ok, res = xpcall(function()
                    return func(result)
                end, function(errmsg)
                    if type(errmsg) == 'string' then
                        -- pop xpcall stack
                        newPromise.err = errFactory:new(errmsg)
                            :buildStack(3, shortSrc, true)
                        return tostring(newPromise.err)
                    end
                    return errmsg
                end)
                if ok then
                    resolvePromise(newPromise, res)
                else
                    rejectPromise(newPromise, res)
                end
            end
        end
    end)
end

---@param promise Promise
---@param result any
---@param state PromiseState
local function transition(promise, result, state)
    if promise.state ~= PENDING then
        return
    end
    promise.result = result
    promise.state = state
    handleQueue(promise)
end

---@param promise Promise
---@param executor PromiseExecutor
---@param self? table
local function wrapExecutor(promise, executor, self)
    local called = false
    local resolve = function(value)
        if called then
            return
        end
        resolvePromise(promise, value)
        called = true
    end
    local reject = function(reason)
        if called then
            return
        end
        rejectPromise(promise, reason)
        called = true
    end

    local ok, res = xpcall(function()
        if self then
            ---@diagnostic disable-next-line: redundant-parameter, param-type-mismatch
            return executor(self, resolve, reject)
        else
            return executor(resolve, reject)
        end
    end, function(errmsg)
        if type(errmsg) == 'string' then
            -- pop xpcall stack
            promise.err = errFactory:new(errmsg)
                :buildStack(3, shortSrc, true)
            return tostring(promise.err)
        end
        return errmsg
    end)
    if not ok and not called then
        reject(res)
    end
end

---@param promise Promise
local function handleRejection(promise)
    promise.needHandleRejection = true

    Promise.loop.nextIdle(function()
        if promise.needHandleRejection then
            promise.needHandleRejection = nil
            local err = promise.err
            if not err then
                err = errFactory:new(promise.result)
            end
            err:unshift('UnhandledPromiseRejection with the reason:')
            error(err)
        end
    end)
end

---@param promise Promise
---@param reason any
rejectPromise = function(promise, reason)
    handleRejection(promise)
    transition(promise, reason, REJECTED)
end

---@param promise Promise
---@param value any
resolvePromise = function(promise, value)
    if promise == value then
        local reason = debug.traceback('TypeError: Chaining cycle detected for promise')
        rejectPromise(promise, reason)
        return
    end

    local valueType = type(value)
    if Promise.isInstance(value, valueType) then
        value:thenCall(function(val)
            resolvePromise(promise, val)
        end, function(reason)
            rejectPromise(promise, reason)
        end)
    else
        local thenCall = getThenable(value, valueType)
        if thenCall then
            wrapExecutor(promise, thenCall, value)
        else
            transition(promise, value, FULFILLED)
        end
    end
end

function Promise:new(executor)
    utils.assertType(executor, 'function')
    local o = self == Promise and setmetatable({}, self) or self
    o.state = PENDING
    o.result = nil
    o.queue = {}
    o.needHandleRejection = nil

    if executor ~= noop then
        wrapExecutor(o, executor)
    end
    return o
end

function Promise:thenCall(onFulfilled, onRejected)
    local o = self.new(Promise, noop)
    table.insert(self.queue, {o, onFulfilled, onRejected})
    if self.state ~= PENDING then
        handleQueue(self)
    end
    return o
end

function Promise:catch(onRejected)
    return self:thenCall(nil, onRejected)
end

function Promise:finally(onFinally)
    local function wrapFinally()
        if utils.getCallable(onFinally) then
            ---@diagnostic disable-next-line: need-check-nil
            onFinally()
        end
    end

    return self:thenCall(function(value)
        wrapFinally()
        return value
    end, function(reason)
        wrapFinally()
        return Promise.reject(reason)
    end)
end

function Promise.resolve(value)
    local typ = type(value)
    if Promise.isInstance(value, typ) then
        return value
    else
        local o = Promise:new(noop)
        local thenCall = getThenable(value, typ)
        if thenCall then
            wrapExecutor(o, thenCall, value)
        else
            o.state = FULFILLED
            o.result = value
        end
        return o
    end
end

function Promise.reject(reason)
    local o = Promise:new(noop)
    o.state = REJECTED
    o.result = reason
    handleRejection(o)
    return o
end

function Promise.all(values)
    utils.assertType(values, 'table')
    return Promise:new(function(resolve, reject)
        local res = {}
        local cnt = 0
        for k, v in pairs(values) do
            cnt = cnt + 1
            Promise.resolve(v):thenCall(function(value)
                res[k] = value
                cnt = cnt - 1
                if cnt == 0 then
                    resolve(res)
                end
            end, function(reason)
                reject(reason)
            end)
        end
        if cnt == 0 then
            resolve(res)
        end
    end)
end

function Promise.allSettled(values)
    utils.assertType(values, 'table')
    return Promise:new(function(resolve, reject)
        local res = {}
        local cnt = 0
        local _ = reject
        for k, v in pairs(values) do
            cnt = cnt + 1
            Promise.resolve(v):thenCall(function(value)
                res[k] = {status = 'fulfilled', value = value}
            end, function(reason)
                res[k] = {status = 'rejected', reason = reason}
            end):finally(function()
                cnt = cnt - 1
                if cnt == 0 then
                    resolve(res)
                end
            end)
        end
        if cnt == 0 then
            resolve(res)
        end
    end)
end

function Promise.any(values)
    utils.assertType(values, 'table')
    return Promise:new(function(resolve, reject)
        local cnt = 0
        local function rejectAggregateError()
            if cnt == 0 then
                reject('AggregateError: All promises were rejected')
            end
        end

        for _, p in pairs(values) do
            cnt = cnt + 1
            Promise.resolve(p):thenCall(function(value)
                resolve(value)
            end, function()
            end):finally(function()
                cnt = cnt - 1
                rejectAggregateError()
            end)
        end
        rejectAggregateError()
    end)
end

function Promise.race(values)
    utils.assertType(values, 'table')
    return Promise:new(function(resolve, reject)
        for _, p in pairs(values) do
            Promise.resolve(p):thenCall(function(value)
                resolve(value)
            end, function(reason)
                reject(reason)
            end)
        end
    end)
end

return Promise
