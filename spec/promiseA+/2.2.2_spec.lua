local helpers         = require('spec.helpers.init')
local testFulfilled   = helpers.testFulfilled
local setTimeout      = helpers.setTimeout
local deferredPromise = helpers.deferredPromise
local promise         = require('promise')
local dummy           = {dummy = 'dummy'}
local sentinel        = {sentinel = 'sentinel'}

describe('2.2.2: If `onFulfilled` is a function,', function()
    describe('2.2.2.1: it must be called after `promise` is fulfilled, ' ..
        'with `promise`’s fulfillment value as its first argument.', function()
        testFulfilled(it, assert, sentinel, function(p)
            p:thenCall(function(value)
                assert.equal(sentinel, value)
                done()
            end)
        end)
    end)

    describe('2.2.2.2: it must not be called before `promise` is fulfilled', function()
        it('fulfilled after a delay', function()
            local onFulfilled = spy.new(done)
            local p, resolve = deferredPromise()
            p:thenCall(onFulfilled)

            setTimeout(function()
                resolve(dummy)
            end, 10)
            assert.True(wait())
            assert.spy(onFulfilled).was_called(1)
        end)

        it('never fulfilled', function()
            local onFulfilled = spy.new(done)
            local p = deferredPromise()
            p:thenCall(onFulfilled)
            assert.False(wait(30))
            assert.spy(onFulfilled).was_not_called()
        end)
    end)

    describe('2.2.2.3: it must not be called more than once.', function()
        it('already-fulfilled', function()
            local onFulfilled = spy.new(done)
            promise.resolve(dummy):thenCall(onFulfilled)
            assert.spy(onFulfilled).was_not_called()
            assert.True(wait())
            assert.spy(onFulfilled).was_called(1)
        end)

        it('trying to fulfill a pending promise more than once, immediately', function()
            local onFulfilled = spy.new(done)
            local p, resolve = deferredPromise()
            p:thenCall(onFulfilled)
            resolve(dummy)
            resolve(dummy)
            assert.True(wait())
            assert.spy(onFulfilled).was_called(1)
        end)

        it('trying to fulfill a pending promise more than once, delayed', function()
            local onFulfilled = spy.new(done)
            local p, resolve = deferredPromise()
            p:thenCall(onFulfilled)
            setTimeout(function()
                resolve(dummy)
                resolve(dummy)
            end, 10)
            assert.True(wait())
            assert.spy(onFulfilled).was_called(1)
        end)

        it('trying to fulfill a pending promise more than once, immediately then delayed', function()
            local onFulfilled = spy.new(done)
            local p, resolve = deferredPromise()
            p:thenCall(onFulfilled)
            resolve(dummy)
            setTimeout(function()
                resolve(dummy)
            end, 10)
            assert.True(wait())
            assert.spy(onFulfilled).was_called(1)
        end)

        it('when multiple `thenCall` calls are made, spaced apart in time', function()
            local onFulfilled1 = spy.new(function() end)
            local onFulfilled2 = spy.new(function() end)
            local onFulfilled3 = spy.new(function() end)
            local p, resolve = deferredPromise()
            p:thenCall(onFulfilled1)
            setTimeout(function()
                p:thenCall(onFulfilled2)
            end, 10)
            setTimeout(function()
                p:thenCall(onFulfilled3)
            end, 20)
            setTimeout(function()
                resolve(dummy)
                done()
            end, 30)
            assert.True(wait())
            assert.spy(onFulfilled1).was_called(1)
            assert.spy(onFulfilled2).was_called(1)
            assert.spy(onFulfilled3).was_called(1)
        end)

        it('when `thenCall` is interleaved with fulfillment', function()
            local onFulfilled1 = spy.new(function() end)
            local onFulfilled2 = spy.new(function() end)
            local p, resolve = deferredPromise()
            p:thenCall(onFulfilled1)
            resolve(dummy)
            setTimeout(function()
                p:thenCall(onFulfilled2)
                done()
            end, 10)
            assert.True(wait())
            assert.spy(onFulfilled1).was_called(1)
            assert.spy(onFulfilled2).was_called(1)
        end)
    end)
end)
