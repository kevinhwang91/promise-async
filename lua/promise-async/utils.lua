---@class PromiseAsyncUtils
local M = {}

---@param o any
---@param expectedType string
function M.assertType(o, expectedType)
    local gotType = type(o)
    local fmt = '%s expected, got %s'
    return assert(gotType == expectedType, fmt:format(expectedType, gotType))
end

---@param o any
---@param typ? string
---@return boolean, function|table|any
function M.getCallable(o, typ)
    local ok
    local f
    local t = typ or type(o)
    if t == 'function' then
        ok, f = true, o
    elseif t ~= 'table' then
        ok, f = false, o
    else
        local meta = getmetatable(o)
        ok = meta and type(meta.__call) == 'function'
        if ok then
            f = meta.__call
        end
    end
    return ok, f
end

return M
