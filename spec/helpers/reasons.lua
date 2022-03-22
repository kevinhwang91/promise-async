local promise = require('promise')
local Reasons = {}
local dummy = {dummy = 'dummy'}

Reasons['`nil`'] = function()
    return nil
end

Reasons['`false`'] = function()
    return false
end

-- Lua before 5.3 versions will transfer number to string after pcall.
-- Pure string will carry some extra information after pcall, no need to test
-- Reasons['`0`'] = function()
--     return 0
-- end

Reasons['a metatable'] = function()
    return setmetatable({}, {})
end

Reasons['an always-pending thenable'] = function()
    return {
        thenCall = function() end
    }
end

Reasons['a fulfilled promise'] = function()
    return promise.resolve(dummy)
end

Reasons['a rejected promise'] = function()
    return promise.reject(dummy)
end

return Reasons
