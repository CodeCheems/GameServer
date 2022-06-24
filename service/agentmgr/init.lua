local skynet = require("skynet")
local s = require("service")

STATUS = {
    LOGIN = 2,
    GAME = 3,
    LOGOUT = 4,
}
local players = {}

function mgrPlayer()
    local m = {
        playerId = nil,
        node = nil,
        agent = nil,
        status = nil,
        gate = nil,
    }
    return m
end

s.resp.reqlogin = function(source,playerId,node,gate)
    local mplayer = players[playerId]
    if mplayer and mplayer.status == STATUS.LOGOUT then
        skynet.error("reqlogin fail,at status LOGOUT"..playerId)
        return false
    end
    if mplayer and mplayer.status == STATUS.LOGIN then
        skynet.error("reqlogin fail,at status LOGIN"..playerId)
        return false
    end
    if mplayer then
        local pnode = mplayer.node
        local pagent = mplayer.agent
        local pgate = mplayer.gate
        mplayer.status = STATUS.LOGOUT
        s.call(pnode,pagent,"kick")
        s.send(pnode,pagent,"exit")
        s.send(pnode,pgate,"send",playerId,{"kick","顶替下线"})
        s.call(pnode,pgate,"kick",playerId)
    end
    local player = mgrPlayer()
    player.playerId = playerId
    player.node = node
    player.gate = gate
    player.agent = nil
    player.status = STATUS.LOGIN
    players[playerId] = player
    local nmgr = skynet.localname(".nodemgr")
    local agent = s.call(node,nmgr,"newservice","agent","agent",playerId)
    player.agent = agent
    player.status = STATUS.GAME
    return true,agent
end

s.resp.reqkick = function(source,playerId,reason)
    local mplayer = players[playerId]
    if not mplayer then
        return false
    end
    if mplayer.status ~= STATUS.GAME then
        return false
    end
    local pnode = mplayer.node
    local pagent = mplayer.agent
    local pgate = mplayer.gate
    mplayer.status = STATUS.LOGOUT
    s.call(pnode,pagent,"kick")
    s.send(pnode,pagent,"exit")
    s.send(pnode,pgate,"kick",playerId)
    players[playerId] = nil
    return true
end

s.start(...)
