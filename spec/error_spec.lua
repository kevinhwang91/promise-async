local e = require('promise-async.error')
local basics = require('spec.helpers.basics')

describe('Error for Promise and Async.', function()
    describe('Basic operations about error,', function()
        local msg = 'message test'
        it('create a error', function()
            local err = e:new(msg)
            assert.equal(msg, tostring(err))
        end)

        it('append messages to a error', function()
            local err = e:new(msg)
            err:push('foo')
            err:push('bar')
            assert.equal('message test\nstack traceback:\nfoo\nbar', tostring(err))
        end)

        it('do unshift for a error', function()
            local err = e:new(msg)
            err:push('foo')
            err:push('bar')
            err:unshift('UnhandledPromiseRejection baz:')
            assert.equal('UnhandledPromiseRejection baz:\nmessage test\nstack traceback:\nfoo\nbar', tostring(err))
        end)
    end)

    describe('Build stacks.', function()
        describe('Build basic values for top of stack.', function()
            -- keep stack always from tail calls
            local function level3(v)
                local s = e:new(v):buildStack(2)
                return tostring(s)
            end
            local function level2(v)
                local o = level3(v)
                return o
            end
            local function level1(v)
                local o = level2(v)
                return o
            end
            local src = debug.getinfo(1).short_src
            local level1Line = debug.getinfo(level1, 'S').linedefined
            local level2Line = debug.getinfo(level2, 'S').linedefined
            local level3Line = debug.getinfo(level3, 'S').linedefined
            local stackStr = ([[stack traceback:
	%s:%d: in function 'level3'
	%s:%d: in function 'level2'
	%s:%d: in function 'level1']]):format(src, level3Line + 1, src, level2Line + 1, src, level1Line + 1)
            local function testBasicTopStack(expectedValue, stringRepresentation)
                it('The value is ' .. stringRepresentation .. '.', function()
                    local s = level1(expectedValue)
                    assert.truthy(s:find(tostring(expectedValue) .. '\n' .. stackStr, 1, true))
                end)
            end

            for valueStr, basicFn in pairs(basics) do
                testBasicTopStack(basicFn(), valueStr)
            end
        end)
    end)
end)
