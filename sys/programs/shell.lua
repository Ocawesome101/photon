-- Basic shell --

local computer = require("computer")
local term = require("term")

term.clear()
print("Welcome to a buggy test of Proton.")

print("Copying stdin to stdout.")

while true do
  term.write("> ")
  term.write(term.read())
  coroutine.yield()
end
