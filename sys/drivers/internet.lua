-- Internet card driver --

local component = ...
local computer = require("computer")

local internet_component = component.list("internet")()

if not internet_component then
  return
end

local raw = component.proxy(internet_component)

local internet = {}

setmetatable(internet, {__index = function(tbl, k) error("Attempt to index internet." .. k .. " (a nil value)") end})

function internet.get(url, headers, post)
  checkArg(1, url, "string")
  checkArg(2, headers, "table", "nil")
  checkArg(3, post, "string", "nil")
  local handle, err = raw.request(url, post, headers)
  if not handle then
    return nil, err
  end
  handle.finishConnect()
  local rtn = {}
  local code, message, headers = handle.response()
  function rtn.read(a)
    checkArg(1, a, "number", "nil")
    return handle.read(a)
  end
  function rtn.headers()
    return headers
  end
  function rtn.code()
    return code
  end
  function rtn.message()
    return message
  end
  function rtn.close()
    rtn = nil
    return handle.close()
  end
  return rtn
end

function internet.socket(addr, port)
  checkArg(1, addr, "string")
  checkArg(2, port, "number", "nil")
  local socket, err = raw.connect(addr, port)
  if not socket then
    return nil, err
  end
  socket.finishConnect()
  local rtn = {}
  function rtn.read(a)
    checkArg(1, a, "number", "nil")
    return socket.read(a)
  end
  function rtn.write(s)
    checkArg(1, s, "string")
    return socket.write(s)
  end
  function rtn.id()
    return socket.id()
  end
  function rtn.close()
    rtn = nil
    return socket.close()
  end
end

return internet
