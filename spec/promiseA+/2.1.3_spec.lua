local helpers         = require('spec.helpers.init')
local testRejected    = helpers.testRejected
local deferredPromise = helpers.deferredPromise
local setTimeout      = helpers.setTimeout
local dummy           = {dummy = 'dummy'}

describe('2.1.3.1: When rejected, a promise: must not transition to any other state.', function()
    local onFulfilled, onRejected = spy.new(function() end), spy.new(function() end)

    before_each(function()
        onFulfilled:clear()
        onRejected:clear()
    end)

    testRejected(it, assert, dummy, function(p)
        local onRejectedCalled = false
        p:thenCall(function()
            assert.False(onRejectedCalled)
            done()
        end, function()
            onRejectedCalled = true
        end)

        setTimeout(function()
            done()
        end, 50)
    end)

    it('trying to reject then immediately fulfill', function()
        local p, resolve, reject = deferredPromise()
        p:thenCall(onFulfilled, onRejected)
        reject(dummy)
        resolve(dummy)

        setTimeout(function()
            done()
        end, 50)
        assert.True(wait())
        assert.spy(onFulfilled).was_not_called()
        assert.spy(onRejected).was_called()
    end)

    it('trying to reject then fulfill, delayed', function()
        local p, resolve, reject = deferredPromise()
        p:thenCall(onFulfilled, onRejected)
        reject(dummy)

        setTimeout(function()
            resolve(dummy)
            done()
        end, 50)
        assert.True(wait())
        assert.spy(onFulfilled).was_not_called()
        assert.spy(onRejected).was_called()
    end)

    it('trying to reject immediately then fulfill, delayed', function()
        local p, resolve, reject = deferredPromise()
        p:thenCall(onFulfilled, onRejected)

        setTimeout(function()
            reject(dummy)
            resolve(dummy)
            done()
        end, 50)
        assert.True(wait())
        assert.spy(onFulfilled).was_not_called()
        assert.spy(onRejected).was_called()
    end)
end)
