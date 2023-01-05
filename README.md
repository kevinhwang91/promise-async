# promise-async

![GitHub Test](https://github.com/kevinhwang91/promise-async/workflows/Test/badge.svg)
![GitHub Lint](https://github.com/kevinhwang91/promise-async/workflows/Lint/badge.svg)

The goal of promise-async is to port [Promise][promise] & [Async][async] from JavaScript to Lua.

> A value returned by async function in JavaScript is actually a Promise Object. It's incomplete and
> inflexible for using an async function wrapped by bare coroutine without Promise in almost Lua
> implementation.

- [Features](#features)
- [Demonstration](#demonstration)
  - [Script](#script)
    - [demo.lua](#demo.lua)
    - [demo.js](#demo.js)
- [Quickstart](#quickstart)
  - [Requirements](#requirements)
  - [Installation](#installation)
    - [As a plugin for Neovim platform](#as-a-plugin-for-neovim-platform)
    - [As a library from Luarocks](#as-a-library-from-luarocks)
- [Documentation](#documentation)
  - [Summary](#summary)
  - [async](#async)
- [Development](#development)
  - [Neovim tips](#neovim-tips)
  - [Run tests](#run-tests)
  - [Improve completion experience](#improve-completion-experience)
  - [Customize EventLoop](#customize-eventloop)
- [Credit](#credit)
- [Feedback](#feedback)
- [License](#license)

## Features

- API is similar to JavaScript's
- Customize EventLoop in any platforms
- Support Lua 5.1-5.4 and LuaJIT with an EventLoop module
- Support Neovim platform

## Demonstration

<https://user-images.githubusercontent.com/17562139/169118448-9468909b-dbde-4dde-9308-ffe71abb24cd.mp4>

### Script

#### demo.lua

<https://github.com/kevinhwang91/promise-async/blob/3f6dcb2f0f546e8be7e170785f07f71ef6afab34/examples/demo.lua#L17-L82>

#### demo.js

<https://github.com/kevinhwang91/promise-async/blob/3f6dcb2f0f546e8be7e170785f07f71ef6afab34/examples/demo.js#L1-L58>

## Quickstart

### Requirements

- Lua 5.1 or latter
- [Luv](https://github.com/luvit/luv)

> Luv is a default EventLoop for promise-async. It doesn't mean promise-async must require it. In
> fact, promise-async require a general EventLoop module which Luv like.

### Installation

#### As a plugin for Neovim platform

Install with [Packer.nvim](https://github.com/wbthomason/packer.nvim):

- As a normal plugin

```lua
use {'kevinhwang91/promise-async'}
```

or

- As a Luarocks plugin

```lua
use_rocks {'promise-async'}
```

#### As a library from Luarocks

1. `luarocks install promise-async`
2. `luarocks install luv` or implement an EventLoop
   [interface](https://github.com/kevinhwang91/promise-async/blob/main/typings/loop.lua) to adapt
   your platform

## Documentation

promise-async's API is based on [MDN-Promise][promise]. [typings/promise.lua](typings/promise.lua)
is the typings with documentation of Promise class.

### Summary

Summary up the API different from JavaScript.

<!-- markdownlint-disable MD013 -->

| JavaScript                                          | Lua                                             |
| --------------------------------------------------- | ----------------------------------------------- |
| `new Promise`                                       | `Promise:new`/`Promise`                         |
| `Promise.then`                                      | `Promise:thenCall`, `then` is language keyword  |
| `Promise.catch`                                     | `Promise:catch`                                 |
| `Promise.finally`                                   | `Promise:finally`                               |
| `Promise.resolve`                                   | `Promise.resolve`                               |
| `Promise.reject`                                    | `Promise.reject`                                |
| `Promise.all`: `Symbol.iterator` as iterator        | `Promise.all`: `pairs` as iterator              |
| `Promise.allSettled`: `Symbol.iterator` as iterator | `Promise.allSettled`: `pairs` as iterator       |
| `Promise.any`: `Symbol.iterator` as iterator        | `Promise.any`: `pairs` as iterator              |
| `Promise.race`: `Symbol.iterator` as iterator       | `Promise.race`: `pairs` as iterator             |
| `async`: as keyword at the start of a function      | `Async`/`Async.sync`: as a surrounding function |
| `await`: as keyword                                 | `await`/`Async.wait` as a function              |

<!-- markdownlint-enable MD013 -->

### async

The environment in `Async.sync` function have been injected some new functions for compatibility or
enhancement:

1. `await`: A reference of `Async.wait` function;
2. `pcall`: Be compatible with LuaJIT;
3. `xpcall`: Be compatible with LuaJIT;

`async` in JavaScript return Promise object only with single result, but may carry multiple results
in Lua. The resolved result of Promise object return by `async` function will be packed into a table
via `{...}`. However, the result handled by `await` will be unpacked and return multiple values.

```lua
local async = require('async')

local function f()
    return 1, 2, 3
end

-- multiple results are packed into resolved result in Promise
async(f):thenCall(function(v)
    print(v[1], v[2], v[3]) -- output: 1 2 3
end)

-- results returned by `await`
async(function()
    local v1, v2, v3 = await(async(f))
    print(v1, v2, v3) -- output: 1 2 3
end)

uv.run()
```

## Development

### Neovim tips

- `Promise.resolve():thenCall(cb)` is almost equivalent to `vim.schedule(cb)`.

### Run tests

`make test`

### Improve completion experience

Following [typings/README.md](./typings/README.md)

### Customize EventLoop

TODO, refer to [loop.lua](./lua/promise-async/loop.lua)

## Credit

- [Promise][promise]
- [Async][async]
- [promises-tests](https://github.com/promises-aplus/promises-tests)
- [then/promise](https://github.com/then/promise)
- [promisejs.org](https://www.promisejs.org)
- [event-loop-timers-and-nexttick](https://nodejs.org/en/docs/guides/event-loop-timers-and-nexttick)

[promise]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise
[async]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/async_function

## Feedback

- If you get an issue or come up with an awesome idea, don't hesitate to open an issue in github.
- If you think this plugin is useful or cool, consider rewarding it a star.

## License

The project is licensed under a BSD-3-clause license. See [LICENSE](./LICENSE) file for details.
