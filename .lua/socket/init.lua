-- lapisbean luasocket shim
local socket = {}

socket.sleep = Sleep
socket.gettime = GetTime

return socket
