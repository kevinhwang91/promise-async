---@diagnostic disable: unused-local, missing-return

---@class PromiseLike
local PromiseLike = {}

---Attaches callbacks for the resolution and/or rejection of the Promise.
---@param onFulfilled? fun(value: any): any The callback to execute when the Promise is resolved.
---@param onRejected? fun(reason: any): any The callback to execute when the Promise is rejected.
---@return Promise promise A Promise for the completion of which ever callback is executed.
function PromiseLike:thenCall(onFulfilled, onRejected) end

return PromiseLike
