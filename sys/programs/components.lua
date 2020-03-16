-- components: List installed components --

local text = require("text")
local component_list = require("drivers").loadDriver("component/list")

print(string.format("%s%s", text.padRight("Address", 38), "Type"))

for addr, ctype in component_list() do
  print(string.format("%s%s", text.padRight(addr, 38), ctype))
end
