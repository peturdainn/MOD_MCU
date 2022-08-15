-- Always-On telnet server based on code by T. Ellison (June 2019)

local module = {}

local m_skt = nil
local stdout = nil


-- this funtion gets node output and either throws away or forwards to telnet client
local function node_output(opipe)
    -- always read the node output!
    local rec = opipe:read(1400)
    if m_skt ~= nil then
        stdout = opipe
        if rec and #rec > 0 then m_skt:send(rec) end
    end
    return false -- don't repost as the on:sent will do this
end

local function telnet_session(socket)

  local function onsent_CB(skt)     -- upval: stdout
    local rec = stdout:read(1400)
    if rec and #rec > 0 then skt:send(rec) end
  end

  local function disconnect_CB(skt) -- upval: socket, stdout
    m_skt = nil
    socket, stdout = nil, nil -- set upvals to nl to allow GC
  end

  socket:on("receive", function(_,rec) node.input(rec) end)
  socket:on("sent", onsent_CB)
  socket:on("disconnection", disconnect_CB)
  m_skt = socket
end

function module.init(port)
    module.svr = net.createServer(net.TCP, 180)
    module.svr:listen(port or 23, telnet_session)
    node.output(module.node_output, 0)
end

return module