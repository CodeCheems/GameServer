local skynet = require("skynet")
local s = require("service")
local socket = require("skynet.socket")
local runconfig = require("runconfig")

local conns = {}  --[fd] = conn
local players = {}  --[playerId] = gatePlayer

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

local process_msg = function(fd,msgstr)
    --skynet.error("fd: "..fd,"msg: "..msgstr)
    local cmd,msg = str_unpack(msgstr)
    skynet.error("recv "..fd.." ["..cmd.."] {"..table.concat(msg,",").."}")
    local cn = conns[fd]
    local playerId = cn.playerId
    if not playerId then
        local node = skynet.getenv("node")
        local nodecfg = runconfig[node]
        local loginId = math.random(1,#nodecfg.login)
        local login = "login"..loginId
        skynet.send(login,"lua","client",fd,cmd,msg)
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
    skynet.error("listen socket :","0.0.0.0",port)
    socket.start(listenfd,connect)
end

s.start(...)