local M = {}
local promise = require('promise')
local reject = promise.reject

promise.reject = function (reason)
    local p = reject(reason)
    p.needHandleRejection = nil
    return p
end

M.setTimeout = promise.loop.setTimeout

function M.deferredPromise()
    local resolve, reject
    local p = promise(function(resolve0, reject0)
        resolve, reject = resolve0, reject0
    end)
    return p, resolve, reject
end

function M.testFulfilled(it, assert, value, test)
    it('already-fulfilled', function()
        test(promise.resolve(value))
        assert.True(wait())
    end)

    it('immediately-fulfilled', function()
        local p, resolve = M.deferredPromise()
        test(p)
        resolve(value)
        assert.True(wait())
    end)

    it('eventually-fulfilled', function()
        local p, resolve = M.deferredPromise()
        test(p)
        wait(10)
        resolve(value)
        assert.True(wait())
    end)
end

function M.testRejected(it, assert, reason, test)
    it('already-rejected', function()
        test(promise.reject(reason))
        assert.True(wait())
    end)

    it('immediately-rejected', function()
        local p, _, reject = M.deferredPromise()
        test(p)
        reject(reason)
        assert.True(wait())
    end)

    it('eventually-fulfilled', function()
        local p, _, reject = M.deferredPromise()
        test(p)
        wait(10)
        reject(reason)
        assert.True(wait())
    end)
end

return M
