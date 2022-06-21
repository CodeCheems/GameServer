local skynet = require("skynet")
local s = require("service")
local harbor = require("skynet.harbor")
s.client = {}
s.resp.client = function(source,fd,cmd,msg)
    if s.client[cmd] then
        local ret_msg = s.client[cmd](fd,msg,source)
        skynet.send(source,"lua","send_by_fd",fd,ret_msg)
    else
        skynet.error("s.resp.client fail",cmd)
    end
end

s.client.login = function(fd,msg,source)
    skynet.error(s.name..s.id.." recv ",table.unpack(msg))
    local playerId = tonumber(msg[2])
    local pw = tonumber(msg[3])
    local gate = source
    local node = skynet.getenv("node")
    if pw~=123 then
        return {"login",1,"密码错误"}
    end
    local amgr = harbor.queryname("agentmgr")
    local isok,agent = skynet.call(amgr,"lua","reqlogin",playerId,node,gate)
    skynet.error("请求agentmgr")
    if not isok then
        return {"login",2,"请求agentmgr失败"}
    end
    isok = skynet.call(gate,"lua","sure_agent",fd,playerId,agent)
    skynet.error("注册gate")
    if not isok then
        return {"login",3,"gate注册失败"}
    end
    skynet.error{"login succ "..playerId}
    return {"login",0,"登录成功"}
end

s.start(...)