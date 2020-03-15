-- Basic shell --

local logger = ...

local computer = require("computer")
local term = require("term")
local shell = require("shell")
local gpu = require("drivers").loadDriver("gpu")

term.clear()
print("Welcome to", _OSVERSION)

local function printError(...)
  local oldForeground = gpu.getForeground()
  gpu.setForeground(0xFF0000)
  print(...)
  gpu.setForeground(oldForeground)
end

while true do
  term.write(shell.resolveVariables(os.getenv("PS1")))
  local cmd = term.read()
  if cmd ~= "\n" then
    local ok, err = pcall(function()return shell.execute(cmd)end)
    if not ok and err then
      printError(err)
    end
  end
  coroutine.yield()
end
