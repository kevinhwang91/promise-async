---@diagnostic disable: unused-local
local uv = require('luv')
local async = require('async')
local promise = require('promise')

math.randomseed(math.ceil(uv.uptime()))

local function setTimeout(callback, ms)
    local timer = uv.new_timer()
    timer:start(ms, 0, function()
        timer:close()
        callback()
    end)
    return timer
end

local function defuse(ms)
    return promise:new(function(resolve, reject)
        setTimeout(function()
            resolve(ms)
        end, ms)
    end)
end

local function bomb(ms)
    -- getmetatable(promise).__call = promise.new
    return promise(function(resolve, reject)
        setTimeout(function()
            reject(ms)
        end, ms)
    end)
end

local function race()
    return async(function()
        return promise.race({
            defuse(math.random(500, 1000)),
            bomb(math.random(800, 1000))
        })
    end)
end

local notify = vim and vim.notify or print

local function play()
    return async(function()
        -- We are not in the next tick until first `await` is called.
        notify('Game start!')
        local cnt = 0
        xpcall(function()
            while true do
                local ms = await(race())
                cnt = cnt + ms
                notify(('Defuse after %dms~'):format(ms))
            end
        end, function(msErr)
            cnt = cnt + msErr
            notify(('Bomb after %dms~'):format(msErr))
        end)

        notify(('Game end after %dms!'):format(cnt))

        await {
            thenCall = function(self, resolve, reject)
                setTimeout(function()
                    reject(self.message)
                end, 1000)
            end,
            message = 'try to throw an error :)'
        }
    end)
end

promise.resolve():thenCall(function(value)
    notify('In next tick')
end)

notify('In main')

play():finally(function()
    print('Before throwing UnhandledPromiseRejection on finally!')
end)

-- uv.run will be called automatically under Neovim main loop
if not vim then
    uv.run()
end
