local loop = require('promise').loop

local function testAsynchronousFunction(name)
    it(name .. 'is asynchronous', function()
        local called = spy.new(function() end)
        loop[name](function()
            called()
            done()
        end, 0)
        assert.spy(called).was_not_called()
        assert.True(wait())
        assert.spy(called).was_called()
    end)
end

describe('EventLoop for Promise.', function()
    testAsynchronousFunction('setTimeout')
    testAsynchronousFunction('nextTick')
    testAsynchronousFunction('nextIdle')

    describe('fire `nextIdle` is later than `nextTick`,', function()
        it('call `nextTick` first', function()
            local queue = {}
            local tick = {'tick'}
            local idle = {'idle'}
            loop.nextTick(function()
                table.insert(queue, tick)
            end)
            loop.nextIdle(function()
                table.insert(queue, idle)
            end)
            loop.setTimeout(done, 50)
            assert.True(wait())
            assert.same(tick, queue[1])
            assert.same(idle, queue[2])
        end)

        it('call `nextIdle` first', function()
            local queue = {}
            local tick = {'tick'}
            local idle = {'idle'}
            loop.nextIdle(function()
                table.insert(queue, idle)
            end)
            loop.nextTick(function()
                table.insert(queue, tick)
            end)
            loop.setTimeout(done, 50)
            assert.True(wait())
            assert.same(tick, queue[1])
            assert.same(idle, queue[2])
        end)
    end)

    it('call `nextTick` in `nextTick` event', function()
        local onTick = spy.new(function() end)
        local onNextTick = spy.new(function() end)
        loop.nextTick(function()
            onTick()
            loop.nextTick(function()
                onNextTick()
                assert.spy(onNextTick).was_called()
                done()
            end)
            assert.spy(onTick).was_called()
            assert.spy(onNextTick).was_not_called()
        end)

        assert.True(wait())
    end)

    it('call `nextIdle` in `nextIdle` event', function()
        local onIdle = spy.new(function() end)
        local onNextIdle = spy.new(function() end)
        loop.nextIdle(function()
            onIdle()
            loop.nextIdle(function()
                onNextIdle()
                assert.spy(onNextIdle).was_called()
                done()
            end)
            assert.spy(onIdle).was_called()
            assert.spy(onNextIdle).was_not_called()
        end)

        assert.True(wait())
    end)

    it('override callWrapper method', function()
        local rawCallWrapper = loop.callWrapper
        local callback = function() end
        loop.callWrapper = function(fn)
            loop.callWrapper = rawCallWrapper
            assert.same(callback, fn)
            done()
        end
        loop.nextTick(callback)
        assert.True(wait())
        loop.callWrapper = rawCallWrapper
    end)
end)
