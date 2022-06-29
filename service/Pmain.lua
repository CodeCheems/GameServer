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

function json_unpack()

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
        balls = {
            [1] = {id=102,x=10,y=20,size=1},
            [2] = {id=103,x=10,y=20,size=2},
        }
    }
    local buff = cjson.encode(msg)
    print(buff)

    buff = [[{"_cmd":"balllist","balls":[{"size":1,"x":10,"y":20,"id":102},{"size":2,"x":10,"y":20,"id":103}]}]]
    local isok,ms = pcall(cjson.decode,buff)
    if isok then
        print(ms._cmd)
        print(ms.balls[1].id)
    else
        print("error")
    end
end)