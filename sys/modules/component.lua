-- compatibility --

local c = {}
local drivers = require("drivers")

setmetatable(c, {__index = function(tbl, k) local attempt = drivers.loadDriver(k) if attempt then return attempt; else attempt = drivers.loadDriver("component/" .. k) if attempt then return attempt else error("component." .. k .. " is not implemented") end end end})

function c.isAvailable(c)
  local d = drivers.loadDriver(c)
  if d and d ~= {} then
    return true
  else
    return false
  end
end

return c
