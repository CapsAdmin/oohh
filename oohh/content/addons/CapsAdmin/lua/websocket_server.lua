local socket = luasocket.Server("tcp")

luasocket.debug = true

socket:Host("localhost", 1246)
socket.OnReceive = print