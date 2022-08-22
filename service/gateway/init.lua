local skynet = require("skynet")
local s = require("service")
local socket = require("skynet.socket")
local runconfig = require("runconfig")
local harbor = require("skynet.harbor")
local conns = {}  --[fd] = conn
local players = {}  --[playerId] = gatePlayer
local closing = false

local function conn()
    local m = {
        fd = nil,
        pllayerId = nil,
    }
    return m
end

local function gatePlayer()
    local m = {
        playerId = nil,
        agent = nil,
        conn = nil,
        key = math.random(1,99999999),
        last_conn_time = nil,
        msgcache = {}, --未发送的消息缓存
    }
    return m
end

local str_unpack = function(msgstr)
    local msg = {}
    while true do
        local arg,rest = string.match(msgstr,"(.-),(.*)")
        if arg then
            msgstr = rest
            table.insert(msg,arg)
        else
            table.insert(msg,msgstr)
            break
        end
    end
    return msg[1],msg
end

local str_pack = function(cmd,msg)
    return table.concat(msg,",").."\r\n"
end

local process_reconnect = function(fd,msg)
    local playerId = tonumber(msg[2])
    local key = tonumber(msg[3])
    local cn = conns[fd]
    if not cn then
        skynet.error("reconnect fail,conn not exist")
        return
    end
    local gplayer = players[playerId]
    if not gplayer then
        skynet.error("reconnect fail,player not exist")
        return
    end
    if gplayer.conn then
        skynet.error("reconnect fail,conn not break")
        return
    end
    if gplayer.key ~=key then
        skynet.error("reconnect fail,key error")
        return
    end
    gplayer.conn = cn
    cn.playerId = playerId
    s.resp.send_by_fd(nil,fd,{"reconnect",0})
    for i, cmsg in ipairs(gplayer.msgcache) do
        s.resp.send_by_fd(nil,fd,cmsg)
    end
    gplayer.msgcache = {}
end

local process_msg = function(fd,msgstr)
    --skynet.error("fd: "..fd,"msg: "..msgstr)
    local cmd,msg = str_unpack(msgstr)
    skynet.error("recv "..fd.." ["..cmd.."] {"..table.concat(msg,",").."}")
    local cn = conns[fd]
    local playerId = cn.playerId
    if cmd == "reconnect" then
        process_reconnect(fd,msg)
        return
    end
    if not playerId then
        local node = skynet.getenv("node")
        local nodecfg = runconfig[node]
        local loginId = math.random(1,#nodecfg.login)
        ---todo
        local addr = skynet.localname(".login"..loginId)
        skynet.error("gateway target : "..skynet.address(addr))
        skynet.send(addr,"lua","client",fd,cmd,msg)
    else
        local gplayer = players[playerId]
        local agent = gplayer.agent
        skynet.send(agent,"lua","client",cmd,msg)
    end
end

local process_buff = function(fd,readBuff)
    while true do
        local msgstr,rest = string.match(readBuff,"(.-)\r\n(.*)")
        if msgstr then
            readBuff = rest
            process_msg(fd,msgstr)
        else
            return readBuff
        end
    end
end

local disconnect = function(fd)
    local c = conns[fd]
    if not c then
        return
    end

    local playerId = c.playerId
    if not playerId then
        return
    else
        local gplayer = players[playerId]
        gplayer.conn = nil
        skynet.timeout(300*100,function()
            if gplayer.conn~=nil then
                return
            end
            local reason = "断线超时"
            local amgr = harbor.queryname("agentmgr")
            skynet.call(amgr,"lua","reqkick",playerId,reason)
        end)
    end
end

local recv_loop = function(fd)
    socket.start(fd)
    skynet.error("socket connected "..fd)
    local readBuff = ""
    while true do
        local recvstr = socket.read(fd)
        if recvstr then
            readBuff = readBuff..recvstr
            readBuff = process_buff(fd,readBuff)
        else
            skynet.error("socket close "..fd)
            disconnect(fd)
            socket.close(fd)
            return
        end
    end
end

local connect = function(fd,addr)
    if closing then
        return
    end
    print("connect from :"..addr.." "..fd)
    local c = conn()
    conns[fd] = c
    c.fd = fd
    skynet.fork(recv_loop,fd)
end

function s.init()
    local node = skynet.getenv("node")
    local nodecfg = runconfig[node]
    local port = nodecfg.gateway[s.id].port

    local listenfd = socket.listen("0.0.0.0",port)
    skynet.error("listen socket :","0.0.0.0",port,s.id,s.name)
    socket.start(listenfd,connect)
end

s.resp.send_by_fd = function(source,fd,msg)
    if not conns[fd] then
        return
    end

    local buff = str_pack(msg[1],msg)
    skynet.error("send "..fd.." ["..msg[1].."] {"..table.concat(msg,",").."}")
    socket.write(fd,buff)
end

s.resp.send=function(source,playerId,msg)
    local gplayer = players[playerId]
    if gplayer==nil then
        return
    end
    local c = gplayer.conn
    if c==nil then
        table.insert(gplayer.msgcache,msg)
        local len = #gplayer.msgcache
        if len>500 then
            local amgr = harbor.queryname("agentmgr")
            skynet.call(amgr,"lua","reqkick",playerId,"gate消息缓存过多")
        end
        return
    end
    s.resp.send_by_fd(nil,c.fd,msg)
end

s.resp.sure_agent=function(source,fd,playerId,agent)
    local cn = conns[fd]
    if not cn then
        local amgr = harbor.queryname("agentmgr")
        skynet.call(amgr,"lua","reqkick",playerId,"未完成登录即下线")
        return false
    end
    cn.playerId = playerId
    local gplayer = gatePlayer()
    gplayer.playerId = playerId
    gplayer.agent = agent
    gplayer.conn = cn
    players[playerId] = gplayer
    return true
end

s.resp.kick=function(source,playerId)
    local gplayer = players[playerId]
    if not gplayer then
        return
    end
    local c = gplayer.conn
    players[playerId] = nil
    if not c then
        return
    end
    conns[c.fd] = nil
    disconnect(c.fd)
    socket.close(c.fd)
end

s.resp.shutdown = function()
    closing = true
end

s.start(...)