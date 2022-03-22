local uv = require('luv')
local uva = require('uva')
local async = require('async')

local function writeFile(path, data)
    return async(function()
        local path_ = path .. '_'
        local fd = await(uva.open(path_, 'w', 438))
        await(uva.write(fd, data, -1))
        await(uva.close(fd))
        pcall(await, uva.rename(path_, path))
    end)
end

local path = debug.getinfo(1, 'S').source:sub(2) .. '__'
print('Writing ' .. path .. '......\n')
writeFile(path, 'write some texts :)\n')

if not vim then
    uv.run()
end
