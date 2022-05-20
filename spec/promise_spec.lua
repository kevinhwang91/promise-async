local promise    = require('promise')
local helpers    = require('spec.helpers.init')
local basics     = require('spec.helpers.basics')
local reasons    = require('spec.helpers.reasons')
local setTimeout = helpers.setTimeout
local dummy      = {dummy = 'dummy'}
local sentinel   = {sentinel = 'sentinel'}
local sentinel2  = {sentinel = 'sentinel2'}
local sentinel3  = {sentinel = 'sentinel3'}
local other      = {other = 'other'}

describe('Extend Promise A+.', function()
    describe('Promise.resolve', function()
        describe('Resolving basic values.', function()
            local function testBasicResolve(expectedValue, stringRepresentation)
                it('The value is ' .. stringRepresentation ..
                    ', and the state of Promise become fulfilled at once.', function()
                    local p = promise.resolve(expectedValue)
                    assert.truthy(tostring(p):match('<fulfilled>'))
                    p:thenCall(function(value)
                        assert.equal(expectedValue, value)
                        done()
                    end)
                    assert.True(wait())
                end)
            end

            for valueStr, basicFn in pairs(basics) do
                testBasicResolve(basicFn(), valueStr)
            end
        end)

        it('resolve another resolved Promise', function()
            local p1 = promise.resolve(dummy)
            local p2 = promise.resolve(p1)
            p2:thenCall(function(value)
                assert.equal(dummy, value)
                done()
            end)
            assert.True(wait())
            assert.equal(p1, p2)
        end)

        it('resolve another rejected Promise', function()
            local p1 = promise.reject(dummy)
            local p2 = promise.resolve(p1)
            p2:thenCall(nil, function(reason)
                assert.equal(dummy, reason)
                done()
            end)
            assert.True(wait())
            assert.equal(p1, p2)
        end)

        it('resolve thenables and throwing Errors', function()
            local p1 = promise.resolve({
                thenCall = function(self, resolvePromise)
                    local _ = self
                    resolvePromise(dummy)
                end
            })
            assert.True(promise.isInstance(p1))

            local onFulfilled1 = spy.new(function(value)
                assert.equal(dummy, value)
            end)
            p1:thenCall(onFulfilled1)

            local thenable = {
                thenCall = function(self, resolvePromise)
                    local _ = self
                    error(dummy)
                    resolvePromise(other)
                end
            }
            local onRejected = spy.new(function(reason)
                assert.equal(dummy, reason)
            end)
            local p2 = promise.resolve(thenable)
            p2:thenCall(nil, onRejected)

            thenable = {
                thenCall = function(self, resolvePromise)
                    local _ = self
                    resolvePromise(dummy)
                    error(other)
                end
            }
            local onFulfilled2 = spy.new(function(value)
                assert.equal(dummy, value)
            end)
            local p3 = promise.resolve(thenable)
            p3:thenCall(onFulfilled2)

            assert.False(wait(30))
            assert.spy(onFulfilled1).was_called()
            assert.spy(onRejected).was_called()
            assert.spy(onFulfilled2).was_called()
        end)
    end)

    describe('Promise.rejected.', function()
        describe('Rejecting reasons', function()
            local function testBasicReject(expectedReason, stringRepresentation)
                it('The reason is ' .. stringRepresentation ..
                    ', and the state of Promise become rejected at once.', function()
                    local p = promise.reject(expectedReason)
                    assert.truthy(tostring(p):match('<rejected>'))
                    p:thenCall(nil, function(value)
                        assert.equal(expectedReason, value)
                        done()
                    end)
                    assert.True(wait())
                end)
            end

            for reasonStr, reason in pairs(reasons) do
                testBasicReject(reason(), reasonStr)
            end
        end)
    end)

    describe('Promise.catch method.', function()
        it('throw errors', function()
            local onRejected1 = spy.new(function(reason)
                assert.equal(dummy, reason)
            end)
            promise(function()
                error(dummy)
            end):catch(onRejected1)

            local onRejected2 = spy.new(function() end)
            promise(function(resolve)
                resolve()
                error(dummy)
            end):catch(onRejected2)

            assert.False(wait(30))
            assert.spy(onRejected1).was_called()
            assert.spy(onRejected2).was_not_called()
        end)

        it('is resolved', function()
            local onRejected1 = spy.new(function() end)
            local onFulfilled = spy.new(function() end)
            local onRejected2 = spy.new(function() end)
            promise.resolve(dummy)
                :catch(onRejected1)
                :thenCall(onFulfilled)
                :catch(onRejected2)

            assert.False(wait(30))
            assert.spy(onRejected1).was_not_called()
            assert.spy(onFulfilled).was_called()
            assert.spy(onRejected2).was_not_called()
        end)
    end)

    describe('Promise.finally method.', function()
        local onFinally = spy.new(done)
        before_each(function()
            onFinally:clear()
        end)

        it('always return itself, different from JavaScript', function()
            local p1 = promise(function() end)
            local p2 = p1:finally(onFinally)
            assert.equal(p1, p2)
        end)

        it('is pending', function()
            promise(function() end):finally(onFinally)
            assert.False(wait(30))
            assert.spy(onFinally).was_not_called()
        end)

        it('is fulfilled', function()
            promise.resolve(dummy):finally(onFinally)
            assert.True(wait())
            assert.spy(onFinally).was_called()
        end)

        it('is rejected', function()
            promise.reject(dummy):catch(function() end):finally(onFinally)
            assert.True(wait())
            assert.spy(onFinally).was_called()
        end)

        it('should throw first error', function()
            local queue = {}
            local p = promise.new(function(resolve)
                setTimeout(function()
                    resolve()
                end, 30)
            end)
            p:finally(function()
                table.insert(queue, sentinel)
            end)
            p:finally(function()
                error(dummy)
            end)
            p:finally(function()
                table.insert(queue, sentinel2)
            end)
            p:finally(function()
                error(other)
            end)
            p:finally(function()
                table.insert(queue, sentinel3)
            end)
            local err
            local rawCallWrapper = promise.loop.callWrapper
            promise.loop.callWrapper = function(fn)
                local ok, res = pcall(fn)
                if not ok then
                    err = res
                end
            end
            assert.False(wait(30))
            promise.loop.callWrapper = rawCallWrapper
            assert.same({sentinel, sentinel2, sentinel3}, queue)
            assert.truthy(tostring(err):match('dummy'))
        end)
    end)

    describe('Promise.all method.', function()
        it('should be fulfilled immediately if element is empty', function()
            promise.all({}):thenCall(function(value)
                assert.same({}, value)
                done()
            end)
            assert.True(wait())
        end)

        describe('wait for fulfillments,', function()
            it('use index table as elements', function()
                local p1 = promise.resolve(sentinel)
                local p2 = sentinel2
                local p3 = promise(function(resolve)
                    setTimeout(function()
                        resolve(sentinel3)
                    end, 10)
                end)

                promise.all({p1, p2, p3}):thenCall(function(value)
                    assert.same({sentinel, sentinel2, sentinel3}, value)
                    done()
                end)
                assert.True(wait())
            end)

            it('use key-value table as elements, different from JavaScript', function()
                local p1 = promise.resolve(sentinel)
                local p2 = sentinel2
                local p3 = promise(function(resolve)
                    setTimeout(function()
                        resolve(sentinel3)
                    end, 10)
                end)

                promise.all({p1 = p1, p2 = p2, p3 = p3}):thenCall(function(value)
                    assert.same({p1 = sentinel, p2 = sentinel2, p3 = sentinel3}, value)
                    done()
                end)
                assert.True(wait())
            end)
        end)

        it('is rejected if any of the elements are rejected', function()
            local p1 = promise.resolve(sentinel)
            local p2 = sentinel2
            local p3 = promise(function(_, reject)
                setTimeout(function()
                    reject(sentinel3)
                end, 10)
            end)
            promise.all({p1, p2, p3}):thenCall(nil, function(reason)
                assert.equal(sentinel3, reason)
                done()
            end)
            assert.True(wait())
        end)
    end)

    describe('Promise.allSettled method.', function()
        it('should be fulfilled immediately if element is empty', function()
            promise.allSettled({}):thenCall(function(value)
                assert.same({}, value)
                done()
            end)
            assert.True(wait())
        end)

        describe('wait for fulfillments,', function()
            it('use index table as elements', function()
                local p1 = promise.resolve(sentinel)
                local p2 = sentinel2
                local p3 = promise(function(resolve)
                    setTimeout(function()
                        resolve(sentinel3)
                    end, 10)
                end)

                promise.allSettled({p1, p2, p3}):thenCall(function(value)
                    assert.same({
                        {status = 'fulfilled', value = sentinel},
                        {status = 'fulfilled', value = sentinel2},
                        {status = 'fulfilled', value = sentinel3}
                    }, value)
                    done()
                end)
                assert.True(wait())
            end)

            it('use key-value table as elements, different from JavaScript', function()
                local p1 = promise.resolve(sentinel)
                local p2 = sentinel2
                local p3 = promise(function(resolve)
                    setTimeout(function()
                        resolve(sentinel3)
                    end, 10)
                end)

                promise.allSettled({p1 = p1, p2 = p2, p3 = p3}):thenCall(function(value)
                    assert.same({
                        p1 = {status = 'fulfilled', value = sentinel},
                        p2 = {status = 'fulfilled', value = sentinel2},
                        p3 = {status = 'fulfilled', value = sentinel3}
                    }, value)
                    done()
                end)
                assert.True(wait())
            end)
        end)


        it('is always resolved even if any of the elements are rejected', function()
            local p1 = promise.resolve(sentinel)
            local p2 = sentinel2
            local p3 = promise(function(_, reject)
                setTimeout(function()
                    reject(sentinel3)
                end, 10)
            end)
            promise.allSettled({p1, p2, p3}):thenCall(function(value)
                assert.same({
                    {status = 'fulfilled', value = sentinel},
                    {status = 'fulfilled', value = sentinel2},
                    {status = 'rejected', reason = sentinel3}
                }, value)
                done()
            end)
            assert.True(wait())
        end)
    end)

    describe('Promise.any method.', function()
        it('should be rejected immediately if element is empty', function()
            promise.any({}):thenCall(nil, function(reason)
                assert.truthy(reason:match('^AggregateError'))
                done()
            end)
            assert.True(wait())
        end)

        it('resolve with the first promise to fulfill, even if a promise rejects first', function()
            local p1 = promise.reject(sentinel)
            local p2 = promise(function(resolve)
                setTimeout(function()
                    resolve(sentinel2)
                end, 30)
            end)
            local p3 = promise(function(resolve)
                setTimeout(function()
                    resolve(sentinel3)
                end, 10)
            end)
            promise.any({p1, p2, p3}):thenCall(function(value)
                assert.equal(sentinel3, value)
                done()
            end)
            assert.True(wait())
        end)

        it('reject with `AggregateError` if no promise fulfills', function()
            promise.any({promise.reject(dummy)}):thenCall(nil, function(reason)
                assert.not_equal(dummy, reason)
                assert.truthy(reason:match('^AggregateError'))
                done()
            end)
            assert.True(wait())
        end)
    end)

    describe('Promise.race method.', function()
        it('should be pending forever if element is empty', function()
            local onFinally = spy.new(done)
            promise.race({}):finally(onFinally)
            assert.spy(onFinally).was_not_called()
            assert.False(wait(30))
            assert.spy(onFinally).was_not_called()
        end)

        describe('resolves or rejects with the first promise to settle,', function()
            it('resolve Promise is earlier than reject', function()
                local p1 = promise(function(resolve)
                    setTimeout(function()
                        resolve(sentinel)
                    end, 10)
                end)
                local p2 = promise(function(_, reject)
                    setTimeout(function()
                        reject(sentinel2)
                    end, 20)
                end)
                promise.race({p1, p2}):thenCall(function(value)
                    assert.equal(sentinel, value)
                    done()
                end)
                assert.True(wait())
            end)

            it('reject Promise is earlier than resolve', function()
                local p1 = promise(function(_, reject)
                    setTimeout(function()
                        reject(sentinel)
                    end, 10)
                end)
                local p2 = promise(function(resolve)
                    setTimeout(function()
                        resolve(sentinel2)
                    end, 20)
                end)
                promise.race({p1, p2}):thenCall(nil, function(reason)
                    assert.equal(sentinel, reason)
                    done()
                end)
                assert.True(wait())
            end)
        end)
    end)
end)
