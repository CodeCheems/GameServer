local skynet = require("skynet")
local socketdriver = require("skynet.socketdriver")
local netpack = require("skynet.netpack")
local cjson = require("cjson")
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
    local msg = {
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
    print("balls[1]:"..umsg.balls[1].id)

end)