local skynet = require "skynet"
local runconfig = require ("runconfig")
local skynet_manager = require("skynet.manager")
local cluster = require("skynet.cluster")

--test ip : (ip addr)172.30.133.226
skynet.start(function()
    skynet.error("[start main]")
    --skynet.error("runconfig.agentmgr.node:"..runconfig.agentmgr.node)
    local mynode = skynet.getenv("node")
    local nodecfg = runconfig[mynode]
    local nodemgr = skynet.newservice("nodemgr","nodemgr",0)
    skynet.name(".nodemgr",nodemgr)
    cluster.reload(runconfig.cluster)
    cluster.open(mynode)
    for i, v in pairs(nodecfg.gateway or {}) do
        local srv = skynet.newservice("gateway","gateway",i)
        skynet.name(".gateway"..i,srv)
    end
    for i, v in pairs(nodecfg.login or {}) do
        local srv = skynet.newservice("login","login",i)
        skynet.name(".login"..i,srv)
    end
    local anode = runconfig.agentmgr.node
    if mynode==anode then
        local srv = skynet.newservice("agentmgr","agentmgr",0)
        skynet.name("agentmgr",srv)
    else
        local proxy =cluster.proxy(anode,"agentmgr")
        skynet.name("agentmgr",proxy)
    end
    for i, sid in pairs(runconfig.scene[mynode] or {}) do
        local srv = skynet.newservice("scene","scene",sid)
        skynet.name(".scene"..sid,srv)
    end
    skynet.newservice("admin","admin",0)
    --skynet.newservice("debug_console",8000)
    skynet.exit()
end)