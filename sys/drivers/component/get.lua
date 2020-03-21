-- you really, really shouldn't be using the component API, so NO proxy will be provided. use drivers instead. --

local component = ...

local function get(addr)
  checkArg(1, addr, "string")
  local full = ""

  for fullAddr, ctype in component.list() do
    if fullAddr:sub(1, #addr) == addr then
      full = addr
    end
  end

  if full == "" then
    return nil, "no such component"
  end

  return full
end

return get 
