---@class UvFS
local M = {}

local uv = require('luv')
local promise = require('promise')
local compat = require('promise-async.compat')

local function wrap(name, argc)
    return function(...)
        local argv = {...}
        return promise(function(resolve, reject)
            argv[argc] = function(err, data)
                if err then
                    reject(err)
                else
                    resolve(data)
                end
            end
            uv[name](compat.unpack(argv))
        end)
    end
end

M.close = wrap('fs_close', 2)
M.open = wrap('fs_open', 4)
M.read = wrap('fs_read', 4)
M.unlink = wrap('fs_unlink', 2)
M.write = wrap('fs_write', 4)
M.mkdir = wrap('fs_mkdir', 3)
M.mkdtemp = wrap('fs_mkdtemp', 2)
M.mkstemp = wrap('fs_mkstemp', 2)
M.rmdir = wrap('fs_rmdir', 2)
M.scandir = wrap('fs_scandir', 2)
M.stat = wrap('fs_stat', 2)
M.fstat = wrap('fs_fstat', 2)
M.lstat = wrap('fs_lstat', 2)
M.rename = wrap('fs_rename', 3)
M.fsync = wrap('fs_fsync', 2)
M.fdatasync = wrap('fs_fdatasync', 2)
M.ftruncate = wrap('fs_ftruncate', 3)
M.sendfile = wrap('fs_sendfile', 5)
M.access = wrap('fs_access', 3)
M.chmod = wrap('fs_chmod', 3)
M.fchmod = wrap('fs_fchmod', 3)
M.utime = wrap('fs_utime', 4)
M.futime = wrap('fs_futime', 4)
M.lutime = wrap('fs_lutime', 4)
M.link = wrap('fs_link', 3)
M.symlink = wrap('fs_symlink', 4)
M.readlink = wrap('fs_readlink', 2)
M.realpath = wrap('fs_realpath', 2)
M.chown = wrap('fs_chown', 4)
M.fchown = wrap('fs_fchown', 4)
M.lchown = wrap('fs_lchown', 4)
M.copyfile = wrap('fs_copyfile', 4)

-- TODO
M.opendir = function(path, entries)
    return promise(function(resolve, reject)
        uv.fs_opendir(path, function(err, data)
            if err then
                reject(err)
            else
                resolve(data)
            end
        end, entries)
    end)
end

M.readdir = wrap('fs_readdir', 2)
M.closedir = wrap('fs_closedir', 2)
M.statfs = wrap('fs_statfs', 2)

return M
