package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;examples/?.lua"
local socket = require("client.socket")

local fd = socket.connect("127.0.0.1",8888)
socket.usleep(1*1000000)

local bytes = string.pack(">Hc13Hc4Hc2",13,"login,101,134",4,"work",4,"wo")
socket.send(fd,bytes)

socket.usleep(1*1000000)
bytes = string.pack(">c2","rk")
socket.send(fd,bytes)
socket.close(fd)