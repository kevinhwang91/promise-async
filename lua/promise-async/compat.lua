---Functions are compatible with LuaJIT's.
---@class PromiseAsyncCompat
local M = {}

---@return boolean
function M.is51()
    return _G._VERSION:sub(-3) == '5.1' and not jit
end

if table.pack then
    M.pack = table.pack
else
    M.pack = function(...)
        return {n = select('#', ...), ...}
    end
end

if table.unpack then
    M.unpack = table.unpack
else
    M.unpack = unpack
end
---@diagnostic enable: deprecated

if M.is51() then
    local _pcall, _xpcall = pcall, xpcall
    local utils = require('promise-async.utils')

    local function yieldInCoroutine(thread, co, success, ...)
        if coroutine.status(co) == 'suspended' then
            return yieldInCoroutine(thread, co, coroutine.resume(co, coroutine.yield(...)))
        end
        return success, ...
    end

    local function doPcall(thread, f, ...)
        local typ = type(f)
        local ok, fn = utils.getCallable(f, typ)
        if not ok then
            return false, ('attempt to call a %s value'):format(typ)
        end
        local co = coroutine.create(function(...)
            return fn(...)
        end)
        return yieldInCoroutine(thread, co, coroutine.resume(co, ...))
    end

    M.pcall = function(f, ...)
        local thread = coroutine.running()
        if not thread then
            return _pcall(f, ...)
        end
        return doPcall(thread, f, ...)
    end

    local function xpcallCatch(msgh, success, ...)
        if success then
            return true, ...
        end
        local ok, result = _pcall(msgh, ...)
        return false, ok and result or 'error in error handling'
    end

    M.xpcall = function(f, msgh, ...)
        local thread = coroutine.running()
        if not thread then
            return _xpcall(f, msgh, ...)
        end
        return xpcallCatch(msgh, doPcall(thread, f, ...))
    end
else
    M.pcall = pcall
    M.xpcall = xpcall
end

if setfenv then
    M.setfenv = setfenv
    M.getfenv = getfenv
else
    local function findENV(f)
        local name = ''
        local value
        local up = 1
        while name do
            name, value = debug.getupvalue(f, up)
            if name == '_ENV' then
                return up, value
            end
            up = up + 1;
        end
        return 0
    end

    local function envHelper(f, name)
        if type(f) == 'number' then
            if f < 0 then
                error(([[bad argument #1 to '%s' (level must be non-negative)]]):format(name), 3)
            end
            local ok, dInfo = pcall(debug.getinfo, f + 2, 'f')
            if not ok or not dInfo then
                error(([[bad argument #1 to '%s' (invalid level)]]):format(name), 3)
            end
            f = dInfo.func
        elseif type(f) ~= 'function' then
            error(([[bad argument #1 to '%s' (number expected, got %s)]]):format(name, type(f)), 3)
        end
        return f
    end

    function M.setfenv(f, table)
        f = envHelper(f, 'setfenv')
        local up = findENV(f)
        if up > 0 then
            debug.upvaluejoin(f, up, function()
                return table
            end, 1)
        end
        return f
    end

    function M.getfenv(f)
        if f == 0 or f == nil then
            return _G
        end
        f = envHelper(f, 'getfenv')
        local up, value = findENV(f)
        return up > 0 and value or _G
    end
end

return M
