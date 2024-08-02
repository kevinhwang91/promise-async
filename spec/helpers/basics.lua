local Basic = {}

local co = coroutine.create(function() end)
coroutine.resume(co)

Basic['`nil`'] = function()
    return nil
end

Basic['`false`'] = function()
    return false
end

Basic['`0`'] = function()
    return 0
end

Basic['`string`'] = function()
    return 'string'
end

Basic['a metatable'] = function()
    return setmetatable({}, {
        __tostring = function()
            return '{}'
        end
    })
end

Basic['a thread'] = function()
    return co
end

return Basic
