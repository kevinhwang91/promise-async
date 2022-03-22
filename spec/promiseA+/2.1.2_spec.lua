local helpers         = require('spec.helpers.init')
local setTimeout      = helpers.setTimeout
local testFulfilled   = helpers.testFulfilled
local deferredPromise = helpers.deferredPromise
local dummy           = {dummy = 'dummy'}

describe('2.1.2.1: When fulfilled, a promise: must not transition to any other state.', function()
    local onFulfilled, onRejected = spy.new(function() end), spy.new(function() end)

    before_each(function()
        onFulfilled:clear()
        onRejected:clear()
    end)

    testFulfilled(it, assert, dummy, function(p)
        local onFulfilledCalled = false
        p:thenCall(function()
            onFulfilledCalled = true
        end, function()
            assert.False(onFulfilledCalled)
            done()
        end)

        setTimeout(function()
            done()
        end, 50)
    end)

    it('trying to fulfill then immediately reject', function()
        local p, resolve, reject = deferredPromise()
        p:thenCall(onFulfilled, onRejected)
        resolve(dummy)
        reject(dummy)

        setTimeout(function()
            done()
        end, 50)
        assert.True(wait())
        assert.spy(onFulfilled).was_called()
        assert.spy(onRejected).was_not_called()
    end)

    it('trying to fulfill then reject, delayed', function()
        local p, resolve, reject = deferredPromise()
        p:thenCall(onFulfilled, onRejected)
        resolve(dummy)

        setTimeout(function()
            reject(dummy)
            done()
        end, 50)
        assert.True(wait())
        assert.spy(onFulfilled).was_called()
        assert.spy(onRejected).was_not_called()
    end)

    it('trying to fulfill immediately then reject, delayed', function()
        local p, resolve, reject = deferredPromise()
        p:thenCall(onFulfilled, onRejected)

        setTimeout(function()
            resolve(dummy)
            reject(dummy)
            done()
        end, 50)
        assert.True(wait())
        assert.spy(onFulfilled).was_called()
        assert.spy(onRejected).was_not_called()
    end)
end)
