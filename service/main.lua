local skynet = require "skynet"
local runconfig = require ("runconfig")

--test ip : (ip addr)172.30.133.226
skynet.start(function()
    skynet.error("[start main]")
    skynet.error("runconfig.agentmgr.node:"..runconfig.agentmgr.node)
    local gateway = skynet.newservice("gateway","gateway",1)
    local login = skynet.newservice("login","login",1)
    skynet.error("gateway1 addr: "..skynet.address(gateway))
    skynet.error("login1 addr: "..skynet.address(login))

    skynet.send(gateway,"lua","saveLogin",login,1)
    --skynet.newservice("debug_console",8000)
    skynet.exit()
end)