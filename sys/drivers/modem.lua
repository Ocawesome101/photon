-- modem driver. It's probably better to use the network stack I've implemented. --

local component = ...

local modem_component = component.list("modem")()

if not modem_component then
  return nil
end

local raw = component.proxy(modem_component)

local modem = {}
setmetatable(modem, {__index = function(tbl, k) error("Attempt to index modem." .. k .. " (a nil value)") end})

if raw.isWireless() then
  raw.setStrength(512)
end

function modem.maxPacketSize()
  return raw.maxPacketSize()
end

function modem.isWireless()
  return raw.isWireless()
end

function modem.open(port)
  checkArg(1, port, "number", "nil")
  local port = port or 80
  return raw.open(port)
end

function modem.close(port)
  checkArg(1, port, "number", "nil")
  local port = port or 80
  return raw.close(port)
end

function modem.isOpen(port)
  checkArg(1, port, "number", "nil")
  local port = port or 80
  return raw.isOpen(port)
end

function modem.send(addr, port, ...)
  checkArg(1, addr, "string", "nil")
  checkArg(2, port, "number", "nil")
  local port = port or 80
  modem.open(port)
  local args = {...}
  if args == {} then
    return nil, "Message data required"
  end
  if addr then
    return raw.send(addr, port, ...)
  else
    return raw.broadcast(port, ...)
  end
end

function modem.getStrength()
  return raw.getStrength()
end

function modem.setStrength(s)
  checkArg(1, s, "number", "nil")
  local s = s or 512
  return raw.setStrength(s)
end

function modem.getWakeMessage()
  return raw.getWakeMessage()
end

function modem.setWakeMessage(message, fuzzy)
  checkArg(1, message, "string", "nil")
  checkArg(2, fuzzy, "boolean", "nil")
  local message = message or ""
  return raw.setWakeMessage(message, fuzzy)
end

return modem
