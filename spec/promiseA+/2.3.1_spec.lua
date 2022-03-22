local promise = require('promise')
local dummy = {dummy = 'dummy'}

describe('2.3.1: If `promise` and `x` refer to the same object, reject `promise` with a ' ..
    '`TypeError` as the reason.', function()
    it('via return from a fulfilled promise', function()
        local p
        p = promise.resolve(dummy):thenCall(function()
            return p
        end)

        p:thenCall(nil, function(reason)
            assert.truthy(reason:match('^TypeError'))
            done()
        end)
        assert.True(wait())
    end)

    it('via return from a rejected promise', function()
        local p
        p = promise.reject(dummy):thenCall(nil, function()
            return p
        end)

        p:thenCall(nil, function(reason)
            assert.truthy(reason:match('^TypeError'))
            done()
        end)
        assert.True(wait())
    end)
end)
