local helpers       = require('spec.helpers.init')
local testFulfilled = helpers.testFulfilled
local testRejected  = helpers.testRejected
local setTimeout    = helpers.setTimeout
local dummy         = {dummy = 'dummy'}
local sentinel      = {sentinel = 'sentinel'}
local sentinel2     = {sentinel = 'sentinel2'}
local sentinel3     = {sentinel = 'sentinel3'}

describe('2.2.6: `thenCall` may be called multiple times on the same promise.', function()
    local function callbackAggregator(times, ultimateCallback)
        local soFar = 0
        return function()
            soFar = soFar + 1
            if soFar == times then
                ultimateCallback()
            end
        end
    end

    describe('2.2.6.1: If/when `promise` is fulfilled, all respective `onFulfilled` callbacks ' ..
        'must execute in the order of their originating calls to `thenCall`.', function()
        describe('multiple boring fulfillment handlers', function()
            testFulfilled(it, assert, sentinel, function(p)
                local onFulfilled1 = spy.new(function() end)
                local onFulfilled2 = spy.new(function() end)
                local onFulfilled3 = spy.new(function() end)
                local onRejected = spy.new(function() end)
                p:thenCall(onFulfilled1, onRejected)
                p:thenCall(onFulfilled2, onRejected)
                p:thenCall(onFulfilled3, onRejected)
                p:thenCall(function(value)
                    assert.equal(sentinel, value)

                    assert.spy(onFulfilled1).was_called_with(sentinel)
                    assert.spy(onFulfilled2).was_called_with(sentinel)
                    assert.spy(onFulfilled3).was_called_with(sentinel)
                    assert.spy(onRejected).was_not_called()
                    done()
                end)
            end)
        end)

        describe('multiple fulfillment handlers, one of which throws', function()
            testFulfilled(it, assert, sentinel, function(p)
                local onFulfilled1 = spy.new(function() end)
                local onFulfilled2 = spy.new(function()
                    error()
                end)
                local onFulfilled3 = spy.new(function() end)
                local onRejected = spy.new(function() end)
                p:thenCall(onFulfilled1, onRejected)
                p:thenCall(onFulfilled2, onRejected):catch(function() end)
                p:thenCall(onFulfilled3, onRejected)
                p:thenCall(function(value)
                    assert.equal(sentinel, value)
                    assert.spy(onFulfilled1).was_called_with(sentinel)
                    assert.spy(onFulfilled2).was_called_with(sentinel)
                    assert.spy(onFulfilled3).was_called_with(sentinel)
                    assert.spy(onRejected).was_not_called()
                    done()
                end)
            end)
        end)

        describe('results in multiple branching chains with their own fulfillment values', function()
            testFulfilled(it, assert, dummy, function(p)
                local semiDone = callbackAggregator(3, function()
                    done()
                end)

                p:thenCall(function()
                    return sentinel
                end):thenCall(function(value)
                    assert.equal(sentinel, value)
                    semiDone()
                end)

                p:thenCall(function()
                    error(sentinel2)
                end):thenCall(nil, function(reason)
                    assert.equal(sentinel2, reason)
                    semiDone()
                end)

                p:thenCall(function()
                    return sentinel3
                end):thenCall(function(value)
                    assert.equal(sentinel3, value)
                    semiDone()
                end)
            end)
        end)

        describe('`onFulfilled` handlers are called in the original order', function()
            local queue = {}
            local function enQueue(value)
                table.insert(queue, value)
            end

            before_each(function()
                queue = {}
            end)

            testFulfilled(it, assert, dummy, function(p)
                local function onFulfilled1()
                    enQueue(1)
                end

                local function onFulfilled2()
                    enQueue(2)
                end

                local function onFulfilled3()
                    enQueue(3)
                end

                p:thenCall(onFulfilled1)
                p:thenCall(onFulfilled2)
                p:thenCall(onFulfilled3)

                p:thenCall(function()
                    assert.same({1, 2, 3}, queue)
                    done()
                end)
            end)

            describe('even when one handler is added inside another handler', function()
                testFulfilled(it, assert, dummy, function(p)
                    local function onFulfilled1()
                        enQueue(1)
                    end

                    local function onFulfilled2()
                        enQueue(2)
                    end

                    local function onFulfilled3()
                        enQueue(3)
                    end

                    p:thenCall(function()
                        onFulfilled1()
                        p:thenCall(onFulfilled3)
                    end)
                    p:thenCall(onFulfilled2)

                    p:thenCall(function()
                        setTimeout(function()
                            assert.same({1, 2, 3}, queue)
                            done()
                        end, 10)
                    end)
                end)
            end)
        end)
    end)

    describe('2.2.6.2: If/when `promise` is rejected, all respective `onRejected` callbacks ' ..
        'must execute in the order of their originating calls to `thenCall`.', function()
        describe('multiple boring rejection handlers', function()
            testRejected(it, assert, sentinel, function(p)
                local onFulfilled = spy.new(function() end)
                local onRejected1 = spy.new(function() end)
                local onRejected2 = spy.new(function() end)
                local onRejected3 = spy.new(function() end)
                p:thenCall(onFulfilled, onRejected1)
                p:thenCall(onFulfilled, onRejected2)
                p:thenCall(onFulfilled, onRejected3)
                p:thenCall(nil, function(reason)
                    assert.equal(sentinel, reason)

                    assert.spy(onRejected1).was_called_with(sentinel)
                    assert.spy(onRejected2).was_called_with(sentinel)
                    assert.spy(onRejected3).was_called_with(sentinel)
                    assert.spy(onFulfilled).was_not_called()
                    done()
                end)
            end)
        end)

        describe('multiple rejection handlers, one of which throws', function()
            testRejected(it, assert, sentinel, function(p)
                local onFulfilled = spy.new(function() end)
                local onRejected1 = spy.new(function() end)
                local onRejected2 = spy.new(function()
                    error()
                end)
                local onRejected3 = spy.new(function() end)
                p:thenCall(onFulfilled, onRejected1)
                p:thenCall(onFulfilled, onRejected2):catch(function() end)
                p:thenCall(onFulfilled, onRejected3)
                p:thenCall(nil, function(reason)
                    assert.equal(sentinel, reason)

                    assert.spy(onRejected1).was_called_with(sentinel)
                    assert.spy(onRejected2).was_called_with(sentinel)
                    assert.spy(onRejected3).was_called_with(sentinel)
                    assert.spy(onFulfilled).was_not_called()
                    done()
                end)
            end)
        end)

        describe('results in multiple branching chains with their own rejection values', function()
            testRejected(it, assert, dummy, function(p)
                local semiDone = callbackAggregator(3, function()
                    done()
                end)

                p:thenCall(nil, function()
                    return sentinel
                end):thenCall(function(value)
                    assert.equal(sentinel, value)
                    semiDone()
                end)

                p:thenCall(nil, function()
                    error(sentinel2)
                end):thenCall(nil, function(reason)
                    assert.equal(sentinel2, reason)
                    semiDone()
                end)

                p:thenCall(nil, function()
                    return sentinel3
                end):thenCall(function(value)
                    assert.equal(sentinel3, value)
                    semiDone()
                end)
            end)
        end)

        describe('`onRejected` handlers are called in the original order', function()
            local queue = {}
            local function enQueue(value)
                table.insert(queue, value)
            end

            before_each(function()
                queue = {}
            end)

            testRejected(it, assert, dummy, function(p)
                local function onRejected1()
                    enQueue(1)
                end

                local function onRejected2()
                    enQueue(2)
                end

                local function onRejected3()
                    enQueue(3)
                end

                p:thenCall(nil, onRejected1)
                p:thenCall(nil, onRejected2)
                p:thenCall(nil, onRejected3)
                p:thenCall(nil, function()
                    assert.same({1, 2, 3}, queue)
                    done()
                end)
            end)

            describe('even when one handler is added inside another handler', function()
                testRejected(it, assert, dummy, function(p)
                    local function onRejected1()
                        enQueue(1)
                    end

                    local function onRejected2()
                        enQueue(2)
                    end

                    local function onRejected3()
                        enQueue(3)
                    end

                    p:thenCall(nil, function()
                        onRejected1()
                        p:thenCall(nil, onRejected3)
                    end)
                    p:thenCall(nil, onRejected2)
                    p:thenCall(nil, function()
                        setTimeout(function()
                            assert.same({1, 2, 3}, queue)
                            done()
                        end, 15)
                    end)
                end)
            end)
        end)
    end)
end)
