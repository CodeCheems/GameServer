local skynet = require("skynet")
local s = require("service")

s.client = {}
s.gate = nil
--根据传入时间，计算当天零点的时间戳
--os.time()可以得到当前时间距离1970.1.1.08：00 的秒数
function get_day(timestamp)
    local day = (timestamp+3600*8)/(3600*24)
    return math.ceil(day)
end
--1970年01月01日是星期四，此处以周四20：40点为界
function get_week_by_thu2040(timestamp)
    local week = (timestamp+3600*8-3600*20-40*60)/(3600*24*7)
    return math.ceil(week)
end
--开启服务器从数据库读取
--关闭服务器保存
local last_check_time = 1582935650
function timer()
    local last = get_week_by_thu2040(last_check_time)
    local now = get_week_by_thu2040(os.time())
    last_check_time = os.time()
    if now>last then
        skynet.error("开启活动")
    end
end

s.client.work = function(msg)
    s.data.coin = s.data.coin + 1
    return {"work",s.data.coin}
end

s.resp.client = function(source,cmd,msg)
    s.gate = source
    if s.client[cmd] then
        local ret_msg = s.client[cmd](msg,source)
        if ret_msg then
            skynet.send(source,"lua","send",s.id,ret_msg)
        end
    else
        skynet.error("s.resp.client fail",cmd)
    end
end

s.init = function()
    skynet.sleep(200)
    s.data = {
        coin = 100,
        hp = 200,
        last_login_time = 1582725978,
    }
    local last_day = get_day(s.data.last_login_time)
    local day = get_day(os.time())
    if day>last_day then
        --first_login_day()  每天第一次登录执行
        skynet.error("每天第一次登录执行")
    end
end

s.resp.kick = function(source)
    s.leave_scene()
    skynet.error("be kick",s.name,s.id)
    skynet.sleep(200)
end

s.resp.exit = function(source)
    skynet.exit()
end

s.resp.send = function(source,msg)
    skynet.send(s.gate,"lua","send",s.id,msg)
end

s.start(...)
require("scene")