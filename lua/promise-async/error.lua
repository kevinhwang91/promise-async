local errorId = {}

---@class PromiseAsyncError
---@field err any
---@field queue string[]
---@field index number
local Error = {_id = errorId}
Error.__index = Error

local function dump(o, limit)
    local typ = type(o)
    if typ == 'string' then
        return o
    elseif typ ~= 'table' then
        return tostring(o)
    end
    local meta = getmetatable(o)
    if meta and meta.__tostring then
        return tostring(o)
    end
    if limit > 0 then
        local fmt = '%s [%s] = %s,'
        local s = '{'
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = fmt:format(s, k, dump(v, limit - 1))
        end
        return #s == 1 and '{}' or s:sub(1, #s - 1) .. ' }'
    else
        return '{...}'
    end
end

function Error.isInstance(o)
    return type(o) == 'table' and o._id == errorId
end

local what = _G._VERSION:sub(-3) == '5.1' and 'Snl' or 'Slnt'

local function outputLevelInfo(dInfo)
    local seg = {('\t%s:'):format(dInfo.short_src)}
    if dInfo.currentline > 0 then
        table.insert(seg, ('%d:'):format(dInfo.currentline))
    end
    -- TODO
    -- lua 5.3 and 5.4 will look up global function and module function before checking 'namewhat'.
    -- And insert "in namewhat name" if not found
    if dInfo.namewhat ~= '' then
        table.insert(seg, (" in function '%s'"):format(dInfo.name))
    else
        if dInfo.what == 'm' then
            table.insert(seg, ' in main chunk')
        elseif dInfo.what ~= 'C' then
            table.insert(seg, (' in function <%s:%d>'):format(dInfo.short_src, dInfo.linedefined))
        else
            table.insert(seg, '?')
        end
    end
    if dInfo.istailcall then
        table.insert(seg, '\n\t(...tail calls...)')
    end
    return table.concat(seg, '')
end

---@param startLevel? number
---@param skipShortSrc? string
---@param doPop? boolean
---@return PromiseAsyncError
function Error:buildStack(startLevel, skipShortSrc, doPop)
    local level = startLevel or 1
    local value
    local thread = coroutine.running()
    while true do
        local dInfo = thread and debug.getinfo(thread, level, what) or debug.getinfo(level, what)
        if not dInfo or skipShortSrc == dInfo.short_src then
            break
        end
        value = outputLevelInfo(dInfo)
        level = level + 1
        self:push(value)
    end
    if doPop then
        self:pop()
    end
    return self
end

---@param err any
---@return PromiseAsyncError
function Error:new(err)
    local o = setmetatable({}, self)
    o.err = err
    o.queue = {}
    o.index = 0
    return o
end

function Error:__tostring()
    local errMsg = dump(self.err, 1)
    if #self.queue == 0 then
        return errMsg
    end
    local t = {}
    for i = 1, self.index do
        table.insert(t, self.queue[i])
    end
    table.insert(t, errMsg)
    if self.index < #self.queue then
        table.insert(t, 'stack traceback:')
    end
    for i = self.index + 1, #self.queue do
        table.insert(t, self.queue[i])
    end
    return table.concat(t, '\n')
end

---@param value string
function Error:unshift(value)
    if value then
        self.index = self.index + 1
        table.insert(self.queue, 1, value)
    end
    return #self.queue
end

---@param value? string
function Error:push(value)
    if value then
        table.insert(self.queue, value)
    end
    return #self.queue
end

---@return string
function Error:pop()
    return table.remove(self.queue)
end

---@return any
function Error:peek()
    return self.err
end

return Error
