-- Basic shell --

local logger = ...

local computer = require("computer")
local term = require("term")
local shell = require("shell")
local gpu = require("drivers").loadDriver("gpu")
local tty = require("tty")
local running_tty = tty.getTTY()

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

local function printError(err, lvl)
  local oldForeground = gpu.getForeground()
  gpu.setForeground(0xFF0000)
  print(debug.traceback(err, lvl))
  gpu.setForeground(oldForeground)
end

shell.setErrorHandler(printError)

local history = {}
while true do
  if #history == 16 then
    table.remove(history, 1)
  end
  term.write(shell.prompt(os.getenv("PS1")))
  local cmd = term.read(history)
  if cmd ~= "\n" then
    table.insert(history, cmd)
    local ok, err = pcall(function()return shell.execute(cmd)end)
    if not ok and err then
      printError(err)
    end
  end
  coroutine.yield()
end
