package = 'promise-async'
version = '1.0-0'
source = {
    url = 'git+https://github.com/kevinhwang91/promise-async.git',
    tag = 'v1.0.0'
}
description = {
    summary = 'Promise & Async in Lua',
    detailed = 'The goal of promise-async is to port Promise & Async from JavaScript to Lua.',
    homepage = 'https://github.com/kevinhwang91/promise-async',
    license = ' BSD-3-Clause'
}

dependencies = {
    'lua >= 5.1, <= 5.4'
}

build = {
    type = 'builtin',
    modules = {
        async = 'lua/async.lua',
        promise = 'lua/promise.lua',
        ['promise-async.compat'] = 'lua/promise-async/compat.lua',
        ['promise-async.error'] = 'lua/promise-async/error.lua',
        ['promise-async.loop'] = 'lua/promise-async/loop.lua',
        ['promise-async.utils'] = 'lua/promise-async/utils.lua'
    },
    copy_directories = {
       'typings'
    }
}
