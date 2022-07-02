local skynet = require("skynet")
local socketdriver = require("skynet.socketdriver")
local netpack = require("skynet.netpack")
local cjson = require("cjson")
local pb = require("protobuf")
local mysql = require("skynet.db.mysql")
local db=nil
local queue

function json_pack(cmd,msg)
    msg._cmd = cmd
    local body = cjson.encode(msg)
    local namelen = string.len(cmd)
    local bodylen = string.len(body)
    local len = namelen + bodylen + 2
    local format = string.format("> i2 i2 c%d c%d",namelen,bodylen)
    local buff = string.pack(format,len,namelen,cmd,body)
    return buff
end

function json_unpack(buff)
    local len = string.len(buff)
    local namelen_format = string.format("> i2 c%d",len-2)
    local namelen,other = string.unpack(namelen_format,buff)
    local bodylen = len-2-namelen
    local format = string.format("> c%d c%d",namelen,bodylen)
    local cmd,bodybuff = string.unpack(format,other)
    local isok,msg = pcall(cjson.decode,bodybuff)
    if not isok or not msg or not msg._cmd or not cmd == msg._cmd then
        print("error")
        return
    end
    return cmd,msg
end

function socket_unpack(msg,sz)
    return netpack.filter(queue,msg,sz)
end

function process_connect(fd,addr)
    skynet.error("new conn fd : "..fd.." addr : "..addr)
    socketdriver.start(fd)
end

function process_close(fd)
    skynet.error("close fd : "..fd)
end

function process_error(fd,error)
    skynet.error("error fd : "..fd.." error : "..error)
end

function process_warning(fd,size)
    skynet.error("warning fd : "..fd.." size : "..size)
end

function process_msg(fd,msg,sz)
    local str = netpack.tostring(msg,sz)
    skynet.error("recv from fd : "..fd.." str : "..str)
    skynet.sleep(100)
    skynet.error("finish fd : "..fd.." "..str)
end

function process_more()
    for fd,msg,sz in netpack.pop,queue do
        skynet.fork(process_msg,fd,msg,sz)
    end
end

function socket_dispatch(_,_,q,type,...)
    skynet.error("socket_dispatch type:"..(type or "nil"))
    queue = q
    if type=="open" then
        process_connect(...)
    elseif type=="data" then
        process_msg(...)
    elseif type=="more" then
        process_more(...)
    elseif type=="close" then
        process_close(...)
    elseif type=="error" then
        process_error(...)
    elseif type=="warning" then
        process_warning(...)
    end
end

skynet.start(function()
    --[[skynet.register_protocol({
        name = "socket",
        id = skynet.PTYPE_SOCKET,
        unpack = socket_unpack,
        dispatch = socket_dispatch,
    })
    local listenfd = socketdriver.listen("0.0.0.0",8888)
    socketdriver.start(listenfd)]]
    --[[local msg = {
        _cmd = "balllist",
        coin = 100,
        balls = {
            [1] = {id=102},
            [2] = {id=103},
        }
    }
    local buff_with_len = json_pack("balllist",msg)
    print("len : "..string.len(buff_with_len))
    print(buff_with_len)
    local format = string.format(">i2 c%d",string.len(buff_with_len)-2)
    local _,buff = string.unpack(format,buff_with_len)
    local cmd,umsg = json_unpack(buff)
    print("cmd:"..cmd)
    print("coin:"..umsg.coin)
    print("balls[1]:"..umsg.balls[1].id)]]
    --[[pb.register_file("./proto/login.pb")
    local msg = {
        id = 101,
        pw = "123456",
    }
    local buff = pb.encode("login.Login",msg)
    print("len : "..string.len(buff))
    local umsg = pb.decode("login.Login",buff)
    if umsg then
        print("id : "..umsg.id)
        print("pw : "..umsg.pw)
    else
        print("error")
    end]]

    db = mysql.connect({
        host = "192.168.1.8",
        port = 3306,
        database = "game",
        user = "root",
        password = "root",
        max_packet_size = 1024*1024,
        on_connect = nil,
    })
    skynet.error("[Pmain] db connect")
    --[[pb.register_file("./storage/playerdata.pb")
    local playerdata = {
        playerid = 108,
        coin = 97,
        name = "hjm",
        level = 4,
        last_login_time = os.time(),
    }
    local data = pb.encode("playerdata.BaseInfo",playerdata)
    print("len : "..string.len(data))
    local sql = string.format("insert into skynet (playerid,data) values (%d,%s)",108,mysql.quote_sql_str(data))
    local res = db:query(sql)
    if res.err then
        print("error : "..res.err)
    else
        print("ok")
    end]]
    pb.register_file("./storage/playerdata.pb")
    local sql = string.format("select * from skynet where playerid = 108")
    local res = db:query(sql)
    local data = res[1].data
    print("len : "..string.len(data))
    local udata = pb.decode("playerdata.BaseInfo",data)
    if not data then
        print("error")
        return
    end
    print("coin: "..udata.coin)
    print("name: "..udata.name)
    print("last_login_time: "..udata.last_login_time)
end)