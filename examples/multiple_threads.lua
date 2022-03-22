---@diagnostic disable: redefined-local
local uv      = require('luv')
local promise = require('promise')
local mpack   = require('mpack')

local asyncHandle
local thread
promise(function(resolve, reject)
    asyncHandle = uv.new_async(function(err, data)
        asyncHandle:close()
        if err then
            reject((mpack.unpack or mpack.decode)(err))
        else
            resolve((mpack.unpack or mpack.decode)(data))
        end
    end)
end):thenCall(function(value)
    print(('Getting resolved value: %s from %s'):format(value[1], thread))
end, function(reason)
    print(('Getting rejected reason: %s from %s'):format(reason[1], thread))
end)

thread = uv.new_thread(function(delay, asyn)
    local uv      = require('luv')
    local mpack   = require('mpack')
    local promise = require('promise')
    math.randomseed(math.ceil(uv.uptime()))
    promise(function(resolve, reject)
        print(tostring(uv.thread_self()) .. ' is running.')
        promise.loop.setTimeout(function()
            if math.random(1, 2) == 1 then
                resolve({'succeeded'})
            else
                reject({'failed'})
            end
        end, delay)
    end):thenCall(function(value)
        uv.async_send(asyn, nil, (mpack.pack or mpack.encode)(value))
    end):catch(function(reason)
        uv.async_send(asyn, (mpack.pack or mpack.encode)(reason))
    end)
    uv.run()
end, 1000, asyncHandle)

if not vim then
    uv.run()
end
