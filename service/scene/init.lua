local skynet = require("skynet")
local s = require("service")

local balls = {}  --[playerId] = ball
local foods = {}
local food_maxid = 0
local food_count = 0


function ball()
    local m={
        playerId = nil,
        node = nil,
        agent = nil,
        x = math.random(0,100),
        y = math.random(0,100),
        size = 2,
        speedx = 0,
        speedy = 0,
    }
    return m
end

local function ballListMsg()
    local msg = {"ballList"}
    for i, v in pairs(balls) do
        table.insert(msg,v.playerId)
        table.insert(msg,v.x)
        table.insert(msg,v.y)
        table.insert(msg,v.size)
    end
    return msg
end

function food()
    local m={
        id=nil,
        x = math.random(0,100),
        y = math.random(0,100),
    }
    return m
end

local function foodListMsg()
    local msg = {"foodList"}
    for i, v in pairs(foods) do
        table.insert(msg,v.id)
        table.insert(msg,v.x)
        table.insert(msg,v.y)
    end
    return msg
end

function broadcast(msg)
    for i, v in pairs(balls) do
        s.send(v.node,v.agent,"send",msg)
    end
end

s.resp.enter = function(source,playerId,node,agent)
    if balls[playerId] then
        return false
    end
    local b = ball()
    b.playerId = playerId
    b.node = node
    b.agent = agent
    local enterMsg = {"enter",playerId,b.x,b.y,b.size}
    broadcast(enterMsg)
    balls[playerId] = b
    local ret_msg = {"enter",0,"进入游戏成功"}
    s.send(b.node,b.agent,"send",ret_msg)
    s.send(b.node,b.agent,"send",ballListMsg())
    s.send(b.node,b.agent,"send",foodListMsg())
    return true
end

s.resp.leave = function(source,playerId)
    if not balls[playerId] then
        return false
    end
    balls[playerId] = nil
    local leavemsg = {"leave",playerId}
    broadcast(leavemsg)
end

s.resp.shift = function(source,playerId,x,y)
    local b = balls[playerId]
    if not b then
        return false
    end
    b.speedx = x
    b.speedy = y
end

function move_update()
    for i, v in pairs(balls) do
        v.x = v.x + v.speedx * 0.2
        v.y = v.y + v.speedy * 0.2
        if v.speedx ~= 0 or v.speedy~=0 then
            local msg = {"move",v.playerId,v.x,v.y}
            broadcast(msg)
        end
    end
end

function update(frame)
    food_update()
    move_update()
    eat_update()
end

s.init = function()
    skynet.fork(function()
        local stime = skynet.now()
        local frame = 0
        while true do
            frame = frame+1
            local isok,err = pcall(update,frame)
            if not isok then
                skynet.error(err)
            end
            local etime = skynet.now()
            local waittime = frame*20 - (etime - stime)
            if waittime<=0 then
                waittime = 2
            end
            skynet.sleep(waittime)
        end
    end)
end

s.start(...)