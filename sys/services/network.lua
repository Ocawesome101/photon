-- in-game networking --

local sched = require("sched")
local modem = require("drivers").loadDriver("modem")
local computer = require("computer")
local cget = require("drivers").loadDriver("component/get")
local fs = require("drivers").loadDriver("filesystem")
local config = require("config")

sched.detach()
sched.register("modem_message")
sched.unregister("interrupt")

local netcfg = config.loadWithDefaults("/sys/config/network.cfg", {hostname = os.getenv("HOSTNAME") or computer.address():sub(1, 8), timeout = 5})

local hostname = netcfg.hostname
local timeout = netcfg.timeout

modem.open(80)

local net = {}

local buffer = {}

local function getMessage(addr, port)
  checkArg(1, addr, "string", "nil")
  checkArg(2, port, "number", "nil")
  local port = port or 80
  local max = computer.uptime() + timeout
  repeat
    local data = {computer.pullSignal()}
    if data[2] == "modem_message" then
      buffer[#buffer + 1] = {message = {table.unpack(data, 7)}, port = data[5], sender = data[4]}
    end
    for i=1, #buffer, 1 do
      if (buffer[i].sender == addr or addr == nil) and (buffer[i].port == port or port == nil) then
        local tmp = buffer[i]
        table.remove(buffer, i)
        return tmp
      end
    end
  until computer.uptime() >= max
  return nil, "Timed out"
end

function net.enableWakeOnLAN()
  modem.setWakeMessage("WoLBeacon")
end

function net.connect(hostname, port)
  checkArg(1, hostname, "string")
  checkArg(2, port, "number", "nil")
  local port = port or 80
  local timeout = timeout or 5
  modem.send(nil, port, "request_connection", hostname)
  local con = {}
  local max = computer.uptime() + timeout
  while true do
    local m, err = getMessage(nil, port)
    if not m then
      return nil, err
    end
    if m.message == {"accept_connection", hostname} and m.port == port then
      con.addr = m.addr
      con.port = port
      break
    elseif computer.uptime() >= max then
      return nil, "connection timed out"
    end
  end
  function con.request(file, dest)
    checkArg(1, file, "string")
    checkArg(2, dest, "string")
    modem.send(con.addr, con.port, "request_file", file, dest)
  end

  function con.send(file, dest)
    checkArg(1, file, "string")
    checkArg(2, dest, "string")
    if not fs.exists(file) then
      return nil, "File does not exist"
    end
    local handle = io.open(file)
    local data = {}
    repeat
      local read = handle:read(4096) -- files should be sent in 4096-byte chunks
      if read then
        data[#data + 1] = read
      end
    until not read
    modem.send(con.addr, con.port, "send_file", dest)
    for i=1, #data, 1 do
      modem.send(con.addr, con.port, "file_data", data[i])
    end
    return modem.send(con.addr, con.port, "end_of_file", dest)
  end

  function con.ping()
    modem.send(con.addr, con.port, "ping")
    local max = computer.uptime() + timeout
    repeat
      local msg, err = getMessage(con.addr, con.port)
      if not msg then
        return nil, err
      end
      if msg.message[1] == "pong" then
        return max - timeout - computer.uptime()
      end
    until computer.uptime() >= max
    return nil, "Timed out"
  end

  return con
end

package.loaded.net = net

while true do
  local msg, err = getMessage()
  if msg then
    if msg.message[1] == "send_file" then
      local s = ""
      local file = msg.messsage[2]
      local addr = msg.sender
      local port = msg.port
      local max = computer.uptime() + timeout
      repeat
        local msg, err = getMessage(addr, port)
        if not msg then
          return nil, err
        end
        if msg.message[1] == "file_data" and msg.message[2] == file then
          s = s .. msg.message[3]
        end
      until (msg.message[1] == "end_of_file" and msg.message[2] == file) or computer.uptime() >= max
      local handle = io.open(msg.message[2], "w")
      handle:write(s)
      handle:close()
    elseif msg.message[1] == "ping" then
      modem.send(msg.sender, msg.port, "pong")
    elseif msg.message[1] == "request_connection" then
      if msg.message[2] == hostname then
        modem.send(msg.sender, msg.port, "accept_connection", hostname)
      end
    end
  end
end
