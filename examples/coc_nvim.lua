local promise = require('promise')
local M = {}
local fn = vim.fn

function M.action(action, ...)
    local args = {...}
    return promise(function(resolve, reject)
        table.insert(args, function(err, res)
            if err ~= vim.NIL then
                reject(err)
            else
                if res == vim.NIL then
                    res = nil
                end
                resolve(res)
            end
        end)
        fn.CocActionAsync(action, unpack(args))
    end)
end

function M.runCommand(name, ...)
    return M.action('runCommand', name, ...)
end

--
-- M.action('showOutline', true)

return M
