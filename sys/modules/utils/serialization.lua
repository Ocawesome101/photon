-- serialization --

local s = {}

function s.unserialize(str)
  checkArg(1, str, "string")
  local ok, err = load("return " .. str, "=" .. str, "t", {})
  if not ok then
    return nil, err
  end

  return ok()
end

local function serialize(tbl, indent)
  local ident = (" "):rep(indent)
  local rtn = "{\n"

  for k,v in pairs(tbl) do
    local key, val
    if type(k) == "string" then
      key = "\"" .. k .. "\""
    else
      key = k
    end
    if type(v) == "string" then
      val = "\"" .. v .. "\""
    elseif type(v) == "number" then
      val = v
    elseif type(v) == "table" then
      val = serialize(v, indent + 2)
    else
      val = tostring(v)
    end
    rtn = rtn .. ident .. "[" .. key .. "] = " .. val .. ",\n"
  end

  rtn = rtn .. ident:sub(1, -3) .. "}"
  return rtn
end

function s.serialize(tbl)
  checkArg(1, tbl, "table")
  
  return serialize(tbl, 2)
end

return s
