local skynet = require "skynet"
local runconfig = require ("runconfig")

skynet.start(function()
    skynet.error("[start main]")
    skynet.error("runconfig.agentmgr.node:"..runconfig.agentmgr.node)
    skynet.newservice("gateway","gateway",1)
    skynet.exit()
end)