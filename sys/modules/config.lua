-- load config files --

local serialization = require("utils/serialization")

local config = {}

function config.load(file)
  checkArg(1, file, "string")
  local handle = io.open(file, "r")
  if handle then
    local data = handle:read("a")
    handle:close()
    local cfg = load("return " .. data, "=" .. file, "t", {})
    if cfg then
      return cfg()
    end
  end
  return nil
end

function config.loadWithDefaults(file, default)
  checkArg(1, file, "string")
  checkArg(2, default, "table")
  local loaded = config.load(file)
  if not loaded then return default end

  for k,v in pairs(default) do
    if not loaded[k] then
      loaded[k] = v
    end
  end

  return loaded
end

function config.save(file, saveMe)
  checkArg(1, file, "string")
  checkArg(2, saveMe, "table")
  local serialized = serialization.serialize(saveMe, true)

  local handle = io.open(file, "w")
  handle:write(serialized)
  handle:close()
  return true
end

return config
