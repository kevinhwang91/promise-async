local helpers = require('spec.helpers.init')
local testFulfilled = helpers.testFulfilled
local testRejected = helpers.testRejected
local deferredPromise = helpers.deferredPromise
local dummy = {dummy = 'dummy'}
local sentinel = {sentinel = 'sentinel'}
local other = {other = 'other'}
local reasons = require('spec.helpers.reasons')

describe('2.2.7: `thenCall` must return a promise: ' ..
    '`promise2 = promise1.thenCall(onFulfilled, onRejected)', function()
    it('is a promise', function()
        local p1 = deferredPromise()
        local p2 = p1:thenCall()

        assert.True(type(p2) == 'table' or type(p2) == 'function')
        assert.is.not_equal(p2, nil)
        assert.equal('function', type(p2.thenCall))
    end)

    describe('2.2.7.1: If either `onFulfilled` or `onRejected` returns a value `x`, ' ..
        'run the Promise Resolution Procedure `[[Resolve]](promise2, x)`', function()
        it('see separate 3.3 tests', function()
        end)
    end)

    describe('2.2.7.2: If either `onFulfilled` or `onRejected` throws an exception `e`, ' ..
        '`promise2` must be rejected with `e` as the reason.', function()
        local function testReason(expectedReason, stringRepresentation)
            describe('The reason is ' .. stringRepresentation, function()
                testFulfilled(it, assert, dummy, function(p1)
                    local p2 = p1:thenCall(function()
                        error(expectedReason)
                    end)
                    p2:thenCall(nil, function(actualReason)
                        assert.equal(expectedReason, actualReason)
                        done()
                    end)
                end)
                testRejected(it, assert, dummy, function(p1)
                    local p2 = p1:thenCall(nil, function()
                        error(expectedReason)
                    end)
                    p2:thenCall(nil, function(actualReason)
                        assert.equal(expectedReason, actualReason)
                        done()
                    end)
                end)
            end)
        end

        for reasonStr, reason in pairs(reasons) do
            testReason(reason(), reasonStr)
        end
    end)

    describe('2.2.7.3: If `onFulfilled` is not a function and `promise1` is fulfilled, ' ..
        '`promise2` must be fulfilled with the same value', function()
        local function testNonFunction(nonFunction, stringRepresentation)
            describe('`onFulfilled` is' .. stringRepresentation, function()
                testFulfilled(it, assert, sentinel, function(p1)
                    local p2 = p1:thenCall(nonFunction)
                    p2:thenCall(function(value)
                        assert.equal(sentinel, value)
                        done()
                    end)
                end)
            end)
        end

        testNonFunction(nil, '`nil`')
        testNonFunction(false, '`false`')
        testNonFunction(5, '`5`')
        testNonFunction(setmetatable({}, {}), 'a metatable')
        testNonFunction({function() return other end}, 'an table containing a function')
    end)

    describe('2.2.7.4: If `onRejected` is not a function and `promise1` is rejected, ' ..
        '`promise2` must be rejected with the same reason', function()
        local function testNonFunction(nonFunction, stringRepresentation)
            describe('`onRejected` is' .. stringRepresentation, function()
                testRejected(it, assert, sentinel, function(p1)
                    local p2 = p1:thenCall(nonFunction)
                    p2:thenCall(nil, function(reason)
                        assert.equal(sentinel, reason)
                        done()
                    end)
                end)
            end)
        end

        testNonFunction(nil, '`nil`')
        testNonFunction(false, '`false`')
        testNonFunction(5, '`5`')
        testNonFunction(setmetatable({}, {}), 'a metatable')
        testNonFunction({function() return other end}, 'an table containing a function')
    end)
end)
