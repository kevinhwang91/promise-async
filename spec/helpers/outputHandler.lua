return function(options)
    local busted = require('busted')
    local handler = require('busted.outputHandlers.utfTerminal')(options)

    local promiseUnhandledError = {}

    busted.subscribe({'test', 'end'}, function(element, parent)
        while #promiseUnhandledError > 0 do
            local res = table.remove(promiseUnhandledError, 1)
            handler.successesCount = handler.successesCount - 1
            handler.failuresCount = handler.failuresCount + 1
            busted.publish({'failure', element.descriptor}, element, parent, tostring(res))
        end
    end)

    require('promise').loop.callWrapper = function(callback)
        local ok, res = pcall(callback)
        if ok then
            return
        end
        table.insert(promiseUnhandledError, tostring(res))
    end
    return handler
end
