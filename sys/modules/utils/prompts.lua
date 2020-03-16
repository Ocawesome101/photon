-- various little prompts --

local term = require("term")

local p = {}

function p.yesno(prompt, default)
  checkArg(1, prompt, "string")
  checkArg(2, default, "string", "nil")

  local default = (default == "y" or default == "n" and default) or "y"
  default = default:upper()

  local r = false
  repeat
    term.write(string.format("%s [%s/%s]: ", (default == "Y" and default) or "y", (default == "N" and default) or "n"))
    local yn = term.read()
  until ans = "y\n" or ans == "n\n" or ans == "\n"

  return (#ans == 2 and ans == "y") or default == "Y"
end

return p
