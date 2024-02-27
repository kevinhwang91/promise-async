---@diagnostic disable: unused-local, missing-return

---@alias PromiseExecutor fun(resolve: fun(value: any), reject: fun(reason?: any))

---@class Promise
---@field loop PromiseAsyncEventLoop
---@overload fun(executor: PromiseExecutor): Promise
local Promise = {}

---Creates a new Promise.
---@param executor PromiseExecutor A callback used to initialize the promise. This callback is passed two arguments:
---a resolve callback used to resolve the promise with a value or the result of another promise,
---and a reject callback used to reject the promise with a provided reason or error.
---@return Promise promise A new Promise.
function Promise:new(executor) end

---Attaches callbacks for the resolution and/or rejection of the Promise.
---@param onFulfilled? fun(value: any): any The callback to execute when the Promise is resolved.
---@param onRejected? fun(reason: any): any The callback to execute when the Promise is rejected.
---@return Promise promise A Promise for the completion of which ever callback is executed.
function Promise:thenCall(onFulfilled, onRejected) end

---Attaches a callback for only the rejection of the Promise.
---@param onRejected? fun(reason: any): any The callback to execute when the Promise is rejected.
---@return Promise promise A Promise for the completion of the callback.
function Promise:catch(onRejected) end

---Attaches a callback that is invoked when the Promise is settled (fulfilled or rejected).
---The resolved value cannot be modified from the callback.
---@param onFinally? fun() The callback to execute when the Promise is settled (fulfilled or rejected).
---@return Promise promise A new Promise.
function Promise:finally(onFinally) end

---Creates a new resolved promise for the provided value.
---@param value? any A value, or the promise passed as value
---@return Promise promise A resolved promise.
function Promise.resolve(value) end

---Creates a new rejected promise for the provided reason.
---@param reason? any The reason the Promise was rejected.
---@return Promise promise A new rejected Promise.
function Promise.reject(reason) end

---Creates a Promise that is resolved with a table of results when all of the provided
---Promises resolve, or rejected when any Promise is rejected.
---@param values table<any, Promise> A table of Promises.
---@return Promise promise A new Promise.
function Promise.all(values) end

---Creates a Promise that is resolved with a table of results when all of the provided
---Promises resolve or reject.
---@param values table<any, Promise> A table of Promises.
---@return Promise promise A new Promise.
function Promise.allSettled(values) end

---The any function returns a Promise that is fulfilled by the first given Promise to be fulfilled,
---or rejected with an AggregateError containing an table of rejection reasons if all of the
---given Promises are rejected. It resolves all elements of the passed table to Promises as it runs this algorithm.
---@param values table<any, Promise>
---@return Promise promise A new Promise
function Promise.any(values) end

---Creates a Promise that is resolved or rejected when any of the provided Promises are resolved
---or rejected.
---@param values table<any, Promise> A table of Promises.
---@return Promise promise A new Promise.
function Promise.race(values) end

return Promise
