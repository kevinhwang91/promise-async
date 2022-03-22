local uv = require('luv')
local uva = require('uva')
local async = require('async')

local function readFile(path)
    return async(function()
        local fd = await(uva.open(path, 'r', 438))
        local stat = await(uva.fstat(fd))
        local data = await(uva.read(fd, stat.size, 0))
        await(uva.close(fd))
        return data
    end)
end

local currentPath = debug.getinfo(1, 'S').source:sub(2)
print('Reading ' .. currentPath .. '......\n')
readFile(currentPath):thenCall(function(value)
    print(value)
end)

if not vim then
    uv.run()
end
