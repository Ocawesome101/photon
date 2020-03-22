-- Basic shell --

local logger = ...

local computer = require("computer")
local term = require("term")
local shell = require("shell")
local gpu = require("drivers").loadDriver("gpu")
local motd = require("motd")
--local tty = require("tty")
--local running_tty = tty.getTTY()

local logo =
[[Welcome to....        __            
    ____  _________  / /_____  ____ 
   / __ \/ ___/ __ \/ __/ __ \/ __ \
  / /_/ / /  / /_/ / /_/ /_/ / / / /
 / .___/_/   \____/\__/\____/_/ /_/ 
/_/
]]

term.clear()
print(logo)
print(motd.random_shell())

shell.setErrorHandler(function(e,l)io.stderr:write(debug.traceback(e,l) .. "\n")end)

local history = {}
while true do
  if #history == 16 then
    table.remove(history, 1)
  end
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  io.write(shell.prompt(os.getenv("PS1")))
  local cmd = term.read(history)
  if cmd ~= "\n" then
    cmd = cmd:gsub("\n", "")
    table.insert(history, cmd)
    local ok, err = pcall(function()return shell.execute(cmd)end)
    if not ok and err then
      io.stderr:write(debug.traceback(err) .. "\n")
    end
  end
  coroutine.yield()
end
