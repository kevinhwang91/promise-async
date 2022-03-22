local helpers = require('spec.helpers.init')
local deferredPromise = helpers.deferredPromise
local promise = require('promise')
local setTimeout = helpers.setTimeout
local reasons = require('spec.helpers.reasons')
local dummy = {dummy = 'dummy'}
local sentinel = {sentinel = 'sentinel'}
local other = {other = 'other'}
local thenables = require('spec.helpers.thenables')

local function testPromiseResolution(xFactory, test)
    it('via return from a fulfilled promise', function()
        local p = promise.resolve(dummy):thenCall(function()
            return xFactory()
        end)
        test(p)
        assert.True(wait())
    end)

    it('via return from a rejected promise', function()
        local p = promise.reject(dummy):thenCall(nil, function()
            return xFactory()
        end)
        test(p)
        assert.True(wait())
    end)
end

describe('2.3.3: Otherwise, if `x` is a table or function,', function()
    describe('2.3.3.1: Let `thenCall` be `x.thenCall`', function()
        describe('`x` is a table', function()
            local thenCallRetrieved = spy.new(function() end)

            before_each(function()
                thenCallRetrieved:clear()
            end)

            testPromiseResolution(function()
                local x = {}
                setmetatable(x, {
                    __index = function(_, k)
                        if k == 'thenCall' then
                            thenCallRetrieved()
                            return function(_, resolvePromise)
                                resolvePromise()
                            end
                        end
                    end
                })
                return x
            end, function(p)
                p:thenCall(function()
                    assert.spy(thenCallRetrieved).was_called(1)
                    done()
                end)
            end)
        end)

        describe('2.3.3.2: If retrieving the property `x.thenCall` results in a thrown exception ' ..
            '`e`, reject `promise` with `e` as the reason.', function()
            local function testRejectionViaThrowingGetter(e, stringRepresentation)
                describe('`e` is ' .. stringRepresentation, function()
                    testPromiseResolution(function()
                        return {
                            thenCall = function()
                                error(e)
                            end
                        }
                    end, function(p)
                        p:thenCall(nil, function(reason)
                            assert.equal(e, reason)
                            done()
                        end)
                    end)
                end)
            end

            for reasonStr, reason in pairs(reasons) do
                testRejectionViaThrowingGetter(reason(), reasonStr)
            end
        end)

        describe('2.3.3.3: If `thenCall` is a function, call it with `x` as `self`, first ' ..
            'argument `resolvePromise`, and second argument `rejectPromise`', function()
            testPromiseResolution(function()
                local x
                x = {
                    thenCall = function(self, resolvePromise, rejectPromise)
                        assert.equal(x, self)
                        assert.True(type(resolvePromise) == 'function')
                        assert.True(type(rejectPromise) == 'function')
                        resolvePromise()
                    end
                }
                return x
            end, function(p)
                p:thenCall(function()
                    done()
                end)
            end)
        end)

        describe('2.3.3.3.1: If/when `resolvePromise` is called with value `y`, ' ..
            'run `[[Resolve]](promise, y)`', function()
            local function testCallingResolvePromise(yFactory, stringRepresentation, test)
                describe('`y` is ' .. stringRepresentation, function()
                    describe('`thenCall` calls `resolvePromise` synchronously', function()
                        testPromiseResolution(function()
                            return {
                                thenCall = function(self, resolvePromise)
                                    local _ = self
                                    resolvePromise(yFactory())
                                end
                            }
                        end, test)
                    end)

                    describe('`thenCall` calls `resolvePromise` asynchronously', function()
                        testPromiseResolution(function()
                            return {
                                thenCall = function(self, resolvePromise)
                                    local _ = self
                                    setTimeout(function()
                                        resolvePromise(yFactory())
                                    end, 0)
                                end
                            }
                        end, test)
                    end)
                end)
            end

            local function testCallingResolvePromiseFulfillsWith(yFactory, stringRepresentation,
                                                                 fulfillmentValue)
                testCallingResolvePromise(yFactory, stringRepresentation, function(p)
                    p:thenCall(function(value)
                        assert.equal(fulfillmentValue, value)
                        done()
                    end)
                end)
            end

            local function testCallingResolvePromiseRejectsWith(yFactory, stringRepresentation,
                                                                rejectionReason)
                testCallingResolvePromise(yFactory, stringRepresentation, function(p)
                    p:thenCall(nil, function(reason)
                        assert.equal(rejectionReason, reason)
                        done()
                    end)
                end)
            end

            describe('`y` is not a thenable', function()
                testCallingResolvePromiseFulfillsWith(function()
                    return nil
                end, '`null`', nil)
                testCallingResolvePromiseFulfillsWith(function()
                    return false
                end, '`false`', false)
                testCallingResolvePromiseFulfillsWith(function()
                    return 5
                end, '`5`', 5)
                testCallingResolvePromiseFulfillsWith(function()
                    return sentinel
                end, '`an table`', sentinel)
            end)

            describe('`y` is a thenable', function()
                for stringRepresentation, factory in pairs(thenables.fulfilled) do
                    testCallingResolvePromiseFulfillsWith(function()
                        return factory(sentinel)
                    end, stringRepresentation, sentinel)
                end
                for stringRepresentation, factory in pairs(thenables.rejected) do
                    testCallingResolvePromiseRejectsWith(function()
                        return factory(sentinel)
                    end, stringRepresentation, sentinel)
                end
            end)

            describe('`y` is a thenable for a thenable', function()
                for outerString, outerFactory in pairs(thenables.fulfilled) do
                    for innerString, factory in pairs(thenables.fulfilled) do
                        local stringRepresentation = outerString .. ' for ' .. innerString
                        testCallingResolvePromiseFulfillsWith(function()
                            return outerFactory(factory(sentinel))
                        end, stringRepresentation, sentinel)
                    end
                    for innerString, factory in pairs(thenables.rejected) do
                        local stringRepresentation = outerString .. ' for ' .. innerString
                        testCallingResolvePromiseRejectsWith(function()
                            return outerFactory(factory(sentinel))
                        end, stringRepresentation, sentinel)
                    end
                end
            end)
        end)
    end)

    describe('2.3.3.3.2: If/when `rejectPromise` is called with reason `r`, reject `promise` with `r`', function()
        local function testCallingRejectPromise(r, stringRepresentation, test)
            describe('`r` is ' .. stringRepresentation, function()
                describe('`thenCall` calls `rejectPromise` synchronously', function()
                    testPromiseResolution(function()
                        return {
                            thenCall = function(self, resolvePromise, rejectPromise)
                                local _, _ = self, resolvePromise
                                rejectPromise(r)
                            end
                        }
                    end, test)
                end)

                describe('`thenCall` calls `rejectPromise` asynchronously', function()
                    testPromiseResolution(function()
                        return {
                            thenCall = function(self, resolvePromise, rejectPromise)
                                local _, _ = self, resolvePromise
                                setTimeout(function()
                                    rejectPromise(r)
                                end, 0)
                            end
                        }
                    end, test)
                end)
            end)
        end

        local function testCallingRejectPromiseRejectsWith(rejectionReason, stringRepresentation)
            testCallingRejectPromise(rejectionReason, stringRepresentation, function(p)
                p:thenCall(nil, function(reason)
                    assert.equal(rejectionReason, reason)
                    done()
                end)
            end)
        end

        for reasonStr, reason in pairs(reasons) do
            testCallingRejectPromiseRejectsWith(reason(), reasonStr)
        end
    end)

    describe('2.3.3.3.3: If both `resolvePromise` and `rejectPromise` are called, or multiple ' ..
        'calls to the same argument are made, the first call takes precedence, and any further ' ..
        'calls are ignored.', function()
        describe('calling `resolvePromise` then `rejectPromise`, both synchronously', function()
            testPromiseResolution(function()
                return {
                    thenCall = function(self, resolvePromise, rejectPromise)
                        local _ = self
                        resolvePromise(sentinel)
                        rejectPromise(other)
                    end
                }
            end, function(p)
                p:thenCall(function(value)
                    assert.equal(sentinel, value)
                    done()
                end)
            end)
        end)

        describe('calling `resolvePromise` synchronously then `rejectPromise` asynchronously', function()
            testPromiseResolution(function()
                return {
                    thenCall = function(self, resolvePromise, rejectPromise)
                        local _ = self
                        resolvePromise(sentinel)
                        setTimeout(function()
                            rejectPromise(other)
                        end, 0)
                    end
                }
            end, function(p)
                p:thenCall(function(value)
                    assert.equal(sentinel, value)
                    done()
                end)
            end)
        end)

        describe('calling `resolvePromise` then `rejectPromise`, both asynchronously', function()
            testPromiseResolution(function()
                return {
                    thenCall = function(self, resolvePromise, rejectPromise)
                        local _ = self
                        setTimeout(function()
                            resolvePromise(sentinel)
                        end, 0)
                        setTimeout(function()
                            rejectPromise(other)
                        end, 0)
                    end
                }
            end, function(p)
                p:thenCall(function(value)
                    assert.equal(sentinel, value)
                    done()
                end)
            end)
        end)

        describe('calling `resolvePromise` with an asynchronously-fulfilled promise, then calling ' ..
            '`rejectPromise`, both synchronously', function()
            testPromiseResolution(function()
                local p, resolve = deferredPromise()
                setTimeout(function()
                    resolve(sentinel)
                end, 10)
                return {
                    thenCall = function(self, resolvePromise, rejectPromise)
                        local _ = self
                        resolvePromise(p)
                        rejectPromise(other)
                    end
                }
            end, function(p)
                p:thenCall(function(value)
                    assert.equal(sentinel, value)
                    done()
                end)
            end)
        end)

        describe('calling `resolvePromise` with an asynchronously-rejected promise, then calling ' ..
            '`rejectPromise`, both synchronously', function()
            testPromiseResolution(function()
                local p, _, reject = deferredPromise()
                setTimeout(function()
                    reject(sentinel)
                end, 10)
                return {
                    thenCall = function(self, resolvePromise, rejectPromise)
                        local _ = self
                        resolvePromise(p)
                        rejectPromise(other)
                    end
                }
            end, function(p)
                p:thenCall(nil, function(reason)
                    assert.equal(sentinel, reason)
                    done()
                end)
            end)
        end)

        describe('calling `rejectPromise` then `resolvePromise`, both synchronously', function()
            testPromiseResolution(function()
                local p, resolve = deferredPromise()
                setTimeout(function()
                    resolve(sentinel)
                end, 10)
                return {
                    thenCall = function(self, resolvePromise, rejectPromise)
                        local _ = self
                        resolvePromise(p)
                        rejectPromise(other)
                    end
                }
            end, function(p)
                p:thenCall(function(value)
                    assert.equal(sentinel, value)
                    done()
                end)
            end)
        end)

        describe('calling `rejectPromise` synchronously then `resolvePromise` asynchronously', function()
            testPromiseResolution(function()
                return {
                    thenCall = function(self, resolvePromise, rejectPromise)
                        local _, _ = self, resolvePromise
                        rejectPromise(sentinel)
                        setTimeout(function()
                            resolvePromise(other)
                        end, 0)
                    end
                }
            end, function(p)
                p:thenCall(nil, function(reason)
                    assert.equal(sentinel, reason)
                    done()
                end)
            end)
        end)

        describe('calling `rejectPromise` then `resolvePromise`, both asynchronously', function()
            testPromiseResolution(function()
                return {
                    thenCall = function(self, resolvePromise, rejectPromise)
                        local _, _ = self, resolvePromise
                        setTimeout(function()
                            rejectPromise(sentinel)
                        end, 0)
                        setTimeout(function()
                            resolvePromise(other)
                        end, 0)
                    end
                }
            end, function(p)
                p:thenCall(nil, function(reason)
                    assert.equal(sentinel, reason)
                    done()
                end)
            end)
        end)

        describe('calling `resolvePromise` twice synchronously', function()
            testPromiseResolution(function()
                return {
                    thenCall = function(self, resolvePromise)
                        local _ = self
                        resolvePromise(sentinel)
                        resolvePromise(other)
                    end
                }
            end, function(p)
                p:thenCall(function(value)
                    assert.equal(sentinel, value)
                    done()
                end)
            end)
        end)

        describe('calling `resolvePromise` twice, first synchronously then asynchronously', function()
            testPromiseResolution(function()
                return {
                    thenCall = function(self, resolvePromise)
                        local _ = self
                        resolvePromise(sentinel)
                        setTimeout(function()
                            resolvePromise(other)
                        end, 0)
                    end
                }
            end, function(p)
                p:thenCall(function(value)
                    assert.equal(sentinel, value)
                    done()
                end)
            end)
        end)

        describe('calling `resolvePromise` twice, both times asynchronously', function()
            testPromiseResolution(function()
                return {
                    thenCall = function(self, resolvePromise)
                        local _ = self
                        setTimeout(function()
                            resolvePromise(sentinel)
                        end, 0)
                        setTimeout(function()
                            resolvePromise(other)
                        end, 0)
                    end
                }
            end, function(p)
                p:thenCall(function(value)
                    assert.equal(sentinel, value)
                    done()
                end)
            end)
        end)

        describe('calling `resolvePromise` with an asynchronously-fulfilled promise, ' ..
            'then calling it again, both times synchronously', function()
            testPromiseResolution(function()
                local p, resolve = deferredPromise()
                setTimeout(function()
                    resolve(sentinel)
                end, 10)
                return {
                    thenCall = function(self, resolvePromise)
                        local _ = self
                        resolvePromise(p)
                        resolvePromise(other)
                    end
                }
            end, function(p)
                p:thenCall(function(value)
                    assert.equal(sentinel, value)
                    done()
                end)
            end)
        end)

        describe('calling `resolvePromise` with an asynchronously-rejected promise, ' ..
            'then calling it again, both times synchronously', function()
            testPromiseResolution(function()
                local p, _, reject = deferredPromise()
                setTimeout(function()
                    reject(sentinel)
                end, 10)
                return {
                    thenCall = function(self, resolvePromise)
                        local _ = self
                        resolvePromise(p)
                        resolvePromise(other)
                    end
                }
            end, function(p)
                p:thenCall(nil, function(reason)
                    assert.equal(sentinel, reason)
                    done()
                end)
            end)
        end)

        describe('calling `rejectPromise` twice synchronously', function()
            testPromiseResolution(function()
                return {
                    thenCall = function(self, resolvePromise, rejectPromise)
                        local _, _ = self, resolvePromise
                        rejectPromise(sentinel)
                        rejectPromise(other)
                    end
                }
            end, function(p)
                p:thenCall(nil, function(reason)
                    assert.equal(sentinel, reason)
                    done()
                end)
            end)
        end)

        describe('calling `resolvePromise` twice, first synchronously then asynchronously', function()
            testPromiseResolution(function()
                return {
                    thenCall = function(self, resolvePromise, rejectPromise)
                        local _, _ = self, resolvePromise
                        rejectPromise(sentinel)
                        setTimeout(function()
                            rejectPromise(other)
                        end, 0)
                    end
                }
            end, function(p)
                p:thenCall(nil, function(reason)
                    assert.equal(sentinel, reason)
                    done()
                end)
            end)
        end)

        describe('calling `rejectPromise` twice, both times asynchronously', function()
            testPromiseResolution(function()
                return {
                    thenCall = function(self, resolvePromise, rejectPromise)
                        local _, _ = self, resolvePromise
                        setTimeout(function()
                            rejectPromise(sentinel)
                        end, 0)
                        setTimeout(function()
                            rejectPromise(other)
                        end, 0)
                    end
                }
            end, function(p)
                p:thenCall(nil, function(reason)
                    assert.equal(sentinel, reason)
                    done()
                end)
            end)
        end)

        describe('saving and abusing `resolvePromise` and `rejectPromise`', function()
            local savedResolvePromise, savedRejectPromise

            before_each(function()
                savedResolvePromise, savedRejectPromise = nil, nil
            end)

            testPromiseResolution(function()
                return {
                    thenCall = function(self, resolvePromise, rejectPromise)
                        local _ = self
                        savedResolvePromise, savedRejectPromise = resolvePromise, rejectPromise
                    end
                }
            end, function(p)
                local onFulfilled, onRejected = spy.new(function() end), spy.new(function() end)
                p:thenCall(onFulfilled, onRejected)
                if savedResolvePromise and savedRejectPromise then
                    savedResolvePromise(dummy)
                    savedResolvePromise(dummy)
                    savedRejectPromise(dummy)
                    savedRejectPromise(dummy)
                end

                setTimeout(function()
                    savedResolvePromise(dummy)
                    savedResolvePromise(dummy)
                    savedRejectPromise(dummy)
                    savedRejectPromise(dummy)
                end, 10)

                setTimeout(function()
                    assert.spy(onFulfilled).was_called(1)
                    assert.spy(onRejected).was_not_called()
                    done()
                end, 50)
            end)
        end)

        describe('2.3.3.3.4: If calling `thenCall` throws an exception `e`,', function()
            describe('2.3.3.3.4.1: If `resolvePromise` or `rejectPromise` have been called, ignore it.', function()
                describe('`resolvePromise` was called with a non-thenable', function()
                    testPromiseResolution(function()
                        return {
                            thenCall = function(self, resolvePromise)
                                local _ = self
                                resolvePromise(sentinel)
                                error(other)
                            end
                        }
                    end, function(p)
                        p:thenCall(function(value)
                            assert.equal(sentinel, value)
                            done()
                        end)
                    end)
                end)

                describe('`resolvePromise` was called with an asynchronously-fulfilled promise', function()
                    testPromiseResolution(function()
                        local p, resolve = deferredPromise()
                        setTimeout(function()
                            resolve(sentinel)
                        end, 10)
                        return {
                            thenCall = function(self, resolvePromise)
                                local _ = self
                                resolvePromise(p)
                                error(other)
                            end
                        }
                    end, function(p)
                        p:thenCall(function(value)
                            assert.equal(sentinel, value)
                            done()
                        end)
                    end)
                end)

                describe('`resolvePromise` was called with an asynchronously-rejected promise', function()
                    testPromiseResolution(function()
                        local p, _, reject = deferredPromise()
                        setTimeout(function()
                            reject(sentinel)
                        end, 10)
                        return {
                            thenCall = function(self, resolvePromise)
                                local _ = self
                                resolvePromise(p)
                                error(other)
                            end
                        }
                    end, function(p)
                        p:thenCall(nil, function(reason)
                            assert.equal(sentinel, reason)
                            done()
                        end)
                    end)
                end)

                describe('`rejectPromise` was called', function()
                    testPromiseResolution(function()
                        return {
                            thenCall = function(self, resolvePromise, rejectPromise)
                                local _, _ = self, resolvePromise
                                rejectPromise(sentinel)
                                error(other)
                            end
                        }
                    end, function(p)
                        p:thenCall(nil, function(reason)
                            assert.equal(sentinel, reason)
                            done()
                        end)
                    end)
                end)

                describe('`resolvePromise` then `rejectPromise` were called', function()
                    testPromiseResolution(function()
                        return {
                            thenCall = function(self, resolvePromise, rejectPromise)
                                local _ = self
                                resolvePromise(sentinel)
                                rejectPromise(other)
                            end
                        }
                    end, function(p)
                        p:thenCall(function(value)
                            assert.equal(sentinel, value)
                            done()
                        end)
                    end)
                end)

                describe('`rejectPromise` then `resolvePromise` were called', function()
                    testPromiseResolution(function()
                        return {
                            thenCall = function(self, resolvePromise, rejectPromise)
                                local _ = self
                                rejectPromise(sentinel)
                                resolvePromise(other)
                            end
                        }
                    end, function(p)
                        p:thenCall(nil, function(reason)
                            assert.equal(sentinel, reason)
                            done()
                        end)
                    end)
                end)
            end)

            describe('2.3.3.3.4.2: Otherwise, reject `promise` with `e` as the reason.', function()
                describe('straightforward case', function()
                    testPromiseResolution(function()
                        return {
                            thenCall = function()
                                error(sentinel)
                            end
                        }
                    end, function(p)
                        p:thenCall(nil, function(reason)
                            assert.equal(sentinel, reason)
                            done()
                        end)
                    end)
                end)
            end)

            describe('`resolvePromise` is called asynchronously before the `throw`', function()
                testPromiseResolution(function()
                    return {
                        thenCall = function(self, resolvePromise)
                            local _ = self
                            setTimeout(function()
                                resolvePromise(other)
                            end, 0)
                            error(sentinel)
                        end
                    }
                end, function(p)
                    p:thenCall(nil, function(reason)
                        assert.equal(sentinel, reason)
                        done()
                    end)
                end)
            end)

            describe('`rejectPromise` is called asynchronously before the `throw`', function()
                testPromiseResolution(function()
                    return {
                        thenCall = function(self, resolvePromise, rejectPromise)
                            local _, _ = self, resolvePromise
                            setTimeout(function()
                                rejectPromise(other)
                            end, 0)
                            error(sentinel)
                        end
                    }
                end, function(p)
                    p:thenCall(nil, function(reason)
                        assert.equal(sentinel, reason)
                        done()
                    end)
                end)
            end)
        end)
    end)

    describe('2.3.3.4: If `thenCall` is not a function, fulfill promise with `x`', function()
        local function testFulfillViaNonFunction(thenCall, stringRepresentation)
            local x = nil

            before_each(function()
                x = {thenCall = thenCall}
            end)

            describe('thenCall is ' .. stringRepresentation, function()
                testPromiseResolution(function()
                    return x
                end, function(p)
                    p:thenCall(function(value)
                        assert.equal(x, value)
                        done()
                    end)
                end)
            end)
        end

        testFulfillViaNonFunction(5, '`5`')
        testFulfillViaNonFunction({}, 'a table')
        testFulfillViaNonFunction({function() end}, 'a table containing a function')
        testFulfillViaNonFunction(setmetatable({}, {}), 'a metatable')
    end)
end)
