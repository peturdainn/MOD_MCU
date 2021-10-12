local module = {}  

-- SETTINGS
TELNET_PORT = 23

local function telnet_listener(socket) 
    local queueLine = (require "fifosock").wrap(socket)

    local function receiveLine(s, line)
        node.input(line)
    end

    local function disconnect(s)
        socket:on("disconnection", nil)
        socket:on("reconnection", nil)
        socket:on("connection", nil)
        socket:on("receive", nil)
        socket:on("sent", nil)
        node.output(nil)
    end

    socket:on("receive",receiveLine)
    socket:on("disconnection",disconnect)
    node.output(queueLine, 0)
    print(("Welcome to NodeMCU world (%d mem free, %s)"):format(node.heap(), wifi.sta.getip()))
end


function module.init()
    net.createServer(net.TCP, 180):listen(TELNET_PORT, telnet_listener)
    print("Telnet server started...")
end

return module