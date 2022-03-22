local helpers       = require('spec.helpers.init')
local testFulfilled = helpers.testFulfilled
local testRejected  = helpers.testRejected
local dummy         = {dummy = 'dummy'}

describe('2.3.4: If `x` is not an object or function, fulfill `promise` with `x`', function()
    local function testValue(expectedValue, stringRepresentation)
        describe('The value is ' .. stringRepresentation, function()
            testFulfilled(it, assert, dummy, function(p1)
                local p2 = p1:thenCall(function()
                    return expectedValue
                end)
                p2:thenCall(function(actualValue)
                    assert.equal(expectedValue, actualValue)
                    done()
                end)
            end)

            testRejected(it, assert, dummy, function(p1)
                local p2 = p1:thenCall(nil, function()
                    return expectedValue
                end)
                p2:thenCall(function(actualValue)
                    assert.equal(expectedValue, actualValue)
                    done()
                end)
            end)
        end)
    end

    testValue(nil, '`nil`')
    testValue(false, '`false`')
    testValue(true, '`true`')
    testValue(0, '`0`')
end)
