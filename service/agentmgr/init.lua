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
