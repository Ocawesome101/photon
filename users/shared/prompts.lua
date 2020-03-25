-- various little prompts --

local p = {}

function p.yesno(prompt, default)
  checkArg(1, prompt, "string")
  checkArg(2, default, "string", "nil")

  local default = ((default == "y" or default == "n") and default) or "y"
  default = default:upper()

  local r = false
  repeat
    io.write(string.format("%s [%s/%s]: ", prompt, (default == "Y" and default) or "y", (default == "N" and default) or "n"))
    local yn = io.read()
  until ans == "y" or ans == "n"

  return (#ans == 2 and ans == "y") or default == "Y"
end

function p.choice(prompt, items)
  checkArg(1, prompt, "string")
  checkArg(2, items, "table")

  print(prompt .. ":")
  for n, item in pairs(items) do
    print(("%d. %s"):format(n, item))
  end

  local choice
  repeat
    local sig, e, _, id = coroutine.yield()
    if id then
      choice = tonumber(string.char(id))
    elseif e == "interrupt" then
      error("interrupted")
    end
  until items[choice]

  return items[choice]
end

return p
