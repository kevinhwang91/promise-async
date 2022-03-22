local helpers = require('spec.helpers.init')
local setTimeout = helpers.setTimeout
local deferredPromise = helpers.deferredPromise
local promise = require('promise')
local other = {other = 'other'}

local Thenables = {
    fulfilled = {
        ['a synchronously-fulfilled custom thenable'] = function(value)
            return {
                thenCall = function(self, resolvePromise)
                    local _ = self
                    resolvePromise(value)
                end
            }
        end,
        ['an asynchronously-fulfilled custom thenable'] = function(value)
            return {
                thenCall = function(self, resolvePromise)
                    local _ = self
                    setTimeout(function()
                        resolvePromise(value)
                    end, 0)
                end
            }
        end,
        ['a synchronously-fulfilled one-time thenable'] = function(value)
            local numberOfTimesThenRetrieved = 0;
            return setmetatable({}, {
                __index = function(_, k)
                    if numberOfTimesThenRetrieved == 0 and k == 'thenCall' then
                        numberOfTimesThenRetrieved = numberOfTimesThenRetrieved + 1
                        return function(self, resolvePromise)
                            local _ = self
                            resolvePromise(value)
                        end
                    end
                    return nil
                end
            })
        end,
        ['a thenable that tries to fulfill twice'] = function(value)
            return {
                thenCall = function(self, resolvePromise)
                    local _ = self
                    resolvePromise(value)
                    resolvePromise(other)
                end
            }
        end,
        ['a thenable that fulfills but then throws'] = function(value)
            return {
                thenCall = function(self, resolvePromise)
                    local _ = self
                    resolvePromise(value)
                    error(other)
                end
            }
        end,
        ['an already-fulfilled promise'] = function(value)
            return promise.resolve(value)
        end,
        ['an eventually-fulfilled promise'] = function(value)
            local p, resolve = deferredPromise()
            setTimeout(function()
                resolve(value)
            end, 10)
            return p
        end
    },
    rejected = {
        ['a synchronously-rejected custom thenable'] = function(reason)
            return {
                thenCall = function(self, resolvePromise, rejectPromise)
                    local _, _ = self, resolvePromise
                    rejectPromise(reason)
                end
            }
        end,
        ['an asynchronously-rejected custom thenable'] = function(reason)
            return {
                thenCall = function(self, resolvePromise, rejectPromise)
                    local _, _ = self, resolvePromise
                    setTimeout(function()
                        rejectPromise(reason)
                    end, 0)
                end
            }
        end,
        ['a synchronously-rejected one-time thenable'] = function(reason)
            local numberOfTimesThenRetrieved = 0;
            return setmetatable({}, {
                __index = function(_, k)
                    if numberOfTimesThenRetrieved == 0 and k == 'thenCall' then
                        numberOfTimesThenRetrieved = numberOfTimesThenRetrieved + 1
                        return function(self, resolvePromise, rejectPromise)
                            local _, _ = self, resolvePromise
                            rejectPromise(reason)
                        end
                    end
                    return nil
                end
            })
        end,
        ['a thenable that immediately throws in `thenCall`'] = function(reason)
            return {
                thenCall = function()
                    error(reason)
                end
            }
        end,
        ['an table with a throwing `thenCall` metatable'] = function(reason)
            return setmetatable({}, {
                __index = function(_, k)
                    if k == 'thenCall' then
                        return function()
                            error(reason)
                        end
                    end
                    return nil
                end
            })
        end,
        ['an already-rejected promise'] = function(reason)
            return promise.reject(reason)
        end,
        ['an eventually-rejected promise'] = function(reason)
            local p, _, reject = deferredPromise()
            setTimeout(function()
                reject(reason)
            end, 10)
            return p
        end
    }
}

return Thenables
