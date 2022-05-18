# promise-async

![GitHub Test](https://github.com/kevinhwang91/promise-async/workflows/Test/badge.svg)
![GitHub Lint](https://github.com/kevinhwang91/promise-async/workflows/Lint/badge.svg)

The goal of promise-async is to port [Promise][promise] & [Async][async] from JavaScript to Lua.

> A value returned by async function in JavaScript is actually a Promise Object. It's incomplete and
> inflexible for using an async function wrapped by bare coroutine without Promise.

## Features

- API is similar to JavaScript's
- Customize EventLoop in any platforms
- Support Lua 5.1-5.4 and LuaJIT with an EventLoop module
- Support Neovim platform

## Demonstrating

<https://user-images.githubusercontent.com/17562139/169118448-9468909b-dbde-4dde-9308-ffe71abb24cd.mp4>

### Script

#### demo.lua

<https://github.com/kevinhwang91/promise-async/blob/8177d6e6ab8dae4ca5f26caf3bdc23f632595d40/examples/demo.lua#L17-L82>

#### demo.js

<https://github.com/kevinhwang91/promise-async/blob/8177d6e6ab8dae4ca5f26caf3bdc23f632595d40/examples/demo.js#L1-L58>

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

promise-async's API is based on [MDN-Promise][promise].
[typings/promise.lua](typings/promise.lua) is the typings with documentation of Promise class.

Summary up the API different from JavaScript.

<!-- markdownlint-disable MD013 -->

| JavaScript                                          | Lua                                             |
| --------------------------------------------------- | ----------------------------------------------- |
| `new Promise`                                       | `Promise.new`/`Promise`                         |
| `Promise.then`                                      | `Promise:thenCall`, `then` is language keyword  |
| `Promise.catch`                                     | `Promise:catch`                                 |
| `Promise.finally`: return a new Promise             | `Promise:finally`: return itself                |
| `Promise.resolve`                                   | `Promise.resolve`                               |
| `Promise.reject`                                    | `Promise.reject`                                |
| `Promise.all`: `Symbol.iterator` as iterator        | `Promise.all`: `pairs` as iterator              |
| `Promise.allSettled`: `Symbol.iterator` as iterator | `Promise.allSettled`: `pairs` as iterator       |
| `Promise.any`: `Symbol.iterator` as iterator        | `Promise.any`: `pairs` as iterator              |
| `Promise.race`: `Symbol.iterator` as iterator       | `Promise.race`: `pairs` as iterator             |
| `async`: as keyword at the start of a function      | `Async`/`Async.sync`: as a surrounding function |
| `await`: as keyword                                 | `async`/`Async.wait` as a function              |

<!-- markdownlint-enable MD013 -->

The environment in `Async.sync` function have been injected some new functions for compatibility or
enhancement:

1. `await`: A reference of `Async.wait` function;
2. `pcall`: Be compatible with LuaJIT;
3. `xpcall`: Be compatible with LuaJIT;

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
