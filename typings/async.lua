---@diagnostic disable: unused-local, missing-return

---An async function is a function like the async keyword in JavaScript
---@class Async
---@overload fun(executor: table|fun(): ...): Promise
local Async = {}

---Await expressions make promise returning functions behave as though they're synchronous by
---suspending execution until the returned promise is fulfilled or rejected.
---@param promise PromiseLike|Promise|any
---@return ... result The resolved value of the promise.
function _G.await(promise) end

return Async
