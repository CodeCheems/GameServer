local skynet = require("skynet")
local cluster = require("skynet.cluster")
require("skynet.manager")
local M = {
    name = "",
    id = 0,

    exit = nil,
    init = nil,

    resp = {},
}

local dispatch = function(session,address,cmd,...)
    skynet.error(M.name.." dispatch : "..cmd)
    local fun = M.resp[cmd]
    if not fun then
        skynet.ret()
        return
    end
    local traceback = function(err)
        skynet.error("[error] : "..tostring(err))
        skynet.error(debug.traceback())
    end
    local ret = table.pack(xpcall(fun,traceback,address,...))
    local isok = ret[1]
    if not isok then
        skynet.ret()
        return
    end
    skynet.retpack(table.unpack(ret,2))
end

function M.call(node,srv,...)
    local mynode = skynet.getenv("node")
    if node==mynode then
        return skynet.call(srv,"lua",...)
    else
        return cluster.call(node,srv,...)
    end
end

function M.send(node,srv,...)
    local mynode = skynet.getenv("node")
    if node==mynode then
        return skynet.send(srv,"lua",...)
    else
        return cluster.send(node,srv,...)
    end
end

function init()
    skynet.dispatch("lua",dispatch)
    if M.init then
        M.init()
    end
    --skynet.register("."..M.name..M.id)
end

function M.start(name,id,...)
    M.name = name
    M.id = tonumber(id)
    skynet.start(init)
end

return M