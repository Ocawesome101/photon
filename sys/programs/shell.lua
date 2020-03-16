-- Basic shell --

local logger = ...

local computer = require("computer")
local term = require("term")
local shell = require("shell")
local gpu = require("drivers").loadDriver("gpu")

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

while true do
  term.write(shell.prompt(os.getenv("PS1")))
  local cmd = term.read()
  if cmd ~= "\n" then
    local ok, err = pcall(function()return shell.execute(cmd)end)
    if not ok and err then
      printError(err)
    end
  end
  coroutine.yield()
end
