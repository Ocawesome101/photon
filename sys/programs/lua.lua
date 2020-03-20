-- A Lua interpreter. Pretty basic. --

local shell = require("shell")
local gpu = require("drivers").loadDriver("gpu")
local term = require("term")
local serialization = require("utils/serialization")

local args, options = shell.parse(...)

local LUA_ENV = setmetatable({}, {__index=_G})

LUA_ENV.os = setmetatable({}, {__index=_G.os})

print(_VERSION, "Copyright (C) 1994-2017 Lua.org, PUC-Rio")
gpu.setForeground(0xFFFF00)
print("Enter a statement and press [enter] to evaluate it.")
print("Prefix an expression with '=' to show its value.")
print("Type 'os.exit()' to exit the interpreter.")

local running = true

function LUA_ENV.os.exit()
  running = false
end

while running do
  gpu.setForeground(0x00FF00)
  io.write("lua> ")
  gpu.setForeground(0xFFFFFF)
  local inp = io.read()
  if #history > 16 then
    history:remove(1)
  end
  local exec, reason
  if inp:sub(1,1) == "=" then
    exec, reason = load("return " .. inp:sub(2), "=stdin", "t", LUA_ENV)
  else
    exec, reason = load("return " .. inp, "=stdin", "t", LUA_ENV)
    if not exec then
      exec, reason = load(inp, "=stdin", "t", LUA_ENV)
    end
  end
  if exec then
    local result = {pcall(exec)}
    if not result[1] and result[2] then
      print(debug.traceback(result[2]))
    elseif not result[1] then
      print("nil")
    else
      local status, returned = pcall(function() for i = 2, #result, 1 do print(type(result[i]) == "table" and serialization.serialize(result[i]) or result[i]) end end)
      if not status then
        print("error serializing result: " .. tostring(returned))
      end
    end
  else
    print(tostring(reason))
  end
end
