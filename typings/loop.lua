---@diagnostic disable: unused-local, missing-return

---Singleton table, can't be as metatable. Two ways to extend the event loop.
---1. Create a new table and implement all methods, assign the new one to `Promise.loop` .
---2. Assign the targeted method to the `Promise.loop` field to override method.
---@class PromiseAsyncEventLoop
local EventLoop = {}

---Sets a timer which executes a function once the timer expires.
---@param callback fun() A callback function, to be executed after the timer expires.
---@param delay number The time, in milliseconds that the timer should wait.
---@return userdata timer The timer handle created by EventLoop.
function EventLoop.setTimeout(callback, delay) end

---The callback function will be executed in the next tick to continue the event loop.
---@param callback fun() A callback function, will be wrapped by EventLoop.callWrapper.
function EventLoop.nextTick(callback) end

---The callback function will be executed after all next tick events are handled.
---@param callback fun() A callback function, will be wrapped by EventLoop.callWrapper.
function EventLoop.nextIdle(callback) end

---Wrap the callback function from `setTimeout`, `nextTick` and `nextIdle`.
---@param callback fun() A callback function, executed by asynchronous methods.
function EventLoop.callWrapper(callback) end

return EventLoop
