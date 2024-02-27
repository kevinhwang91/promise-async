local errorId = {}

---@class PromiseAsyncError
---@field err any
---@field queue string[]
---@field index number
local Error = {_id = errorId}
Error.__index = Error

local function dump(o, limit)
    local s
    if type(o) ~= 'table' then
        s = tostring(o)
    else
        local meta = getmetatable(o)
        if meta and meta.__tostring then
            s = tostring(o)
        else
            if limit > 0 then
                local fmt = '%s [%s] = %s,'
                s = '{'
                for k, v in pairs(o) do
                    if type(k) ~= 'number' then
                        k = '"' .. k .. '"'
                    end
                    s = fmt:format(s, k, dump(v, limit - 1))
                end
                s = s:sub(1, #s - 1) .. ' }'
            else
                s = '{...}'
            end
        end
    end
    return s
end

function Error.isInstance(o)
    return type(o) == 'table' and o._id == errorId
end

---@param thread? thread
---@param level number
---@param skipShortSrc? string
---@return string?
function Error.format(thread, level, skipShortSrc)
    local res
    local dInfo = thread and debug.getinfo(thread, level, 'nSl') or debug.getinfo(level, 'nSl')
    if dInfo then
        local name, shortSrc, currentline = dInfo.name, dInfo.short_src, dInfo.currentline
        if skipShortSrc == shortSrc then
            return
        end
        local detail
        if not name or name == '' then
            detail = ('in function <Anonymous:%d>'):format(dInfo.linedefined)
        else
            detail = ([[in function '%s']]):format(name)
        end
        res = ('        %s:%d: %s'):format(shortSrc, currentline, detail)
    end
    return res
end

---@param err any
---@return PromiseAsyncError
function Error.new(err)
    local o = setmetatable({}, Error)
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

---@return any
function Error:peek()
    return self.err
end

return Error
