-- mostly OpenOS-compatible term API. --

local gpu, err = require("drivers").loadDriver("gpu")
if not gpu then
  error(err)
end

local term = {}

local x, y = 1, 1
local w, h = gpu.maxResolution()

local cursor = true
local cursorChar = require("unicode").char(0x258f)

local function cursor_update()
--[[  local cx = x
  local char = gpu.get(cx, y)
  local f, b = gpu.getForeground(), gpu.getBackground()
  if cursor then
    gpu.setForeground(b)
    gpu.setBackground(f)
  end
  gpu.set(cx, y, char)
  gpu.setForeground(f)
  gpu.setBackground(b)]]
  if cursor then
    gpu.set(x, y, cursorChar)
  else
    gpu.set(x, y, " ")
  end
end

local function scroll()
  gpu.copy(1, 1, w, h, 0, -1)
  gpu.fill(1, h, w, 1, " ")
end

local function newline()
  local old = cursor
  cursor = false
  cursor_update()
  cursor = old
  if y == h then
    scroll()
  else
    y = y + 1
  end
  x = 1
end

function term.setCursor(nx, ny)
  checkArg(1, nx, "number")
  checkArg(2, ny, "number")
  if nx <= w and ny <= h then
    x, y = nx, ny
    cursor_update()
    return true
  end
  return false
end

function term.getCursor()
  return x, y
end

function term.setCursorBlink(bool)
  checkArg(1, bool, "boolean")
  cursor = bool
end

function term.getCursorBlink()
  return cursor
end

function term.setCursorChar(char)
  checkArg(1, char, "string")
  char = char:sub(1,1)
  if #char == 1 then
    cursorChar = char
  end
end

function term.getCursorChar()
  return cursorChar
end

function term.clear()
  gpu.fill(1, 1, w, h, " ")
  term.setCursor(1, 1)
end

function term.write(str, wrap)
  checkArg(1, str, "string")
  checkArg(2, wrap, "boolean", "nil")
  local old = cursor
  cursor = false
  cursor_update()
  str = str:gsub("\t", "    ")
  local wrap = wrap or true
  local words = {}
  local word = ""
  for char in str:gmatch(".") do
    word = word .. char
    if char == " " or char == "\n" then
      table.insert(words, word)
      word = ""
    end
  end
  if word ~= "" then
    table.insert(words, word)
  end
  for i=1, #words, 1 do
    local word = words[i]
    if x + #word + 1 > w then
      newline()
    end
    for char in word:gmatch(".") do
      if char == "\n" then
        newline()
      else
        if x + 1 > w then
          newline()
        end
        gpu.set(x, y, char)
        x = x + 1
      end
    end
  end
  cursor = old
  cursor_update()
end

local bksp = string.char(8)
local rtn = string.char(13)
local max = 127
local min = 32

function term.read() -- it is ALWAYS advisable to use this function over io.read, as io.read returns characters and does not support deletion.
  local buffer = ""
  local startX, startY = term.getCursor()
  local function redraw(bk)
    term.setCursor(startX, startY)
    term.write(buffer)
    if bk then
      cursor = false
      local _x, _y = term.getCursor()
      term.write(" ")
      cursor = true
      term.setCursor(_x, _y)
    end
  end
  repeat
    redraw()
    coroutine.yield()
    local char = (io.read(1) or string.char(1))
    local byte = (string.byte(char) or 1)
    if byte >= min and byte <= max then
      buffer = buffer .. char
    elseif char == bksp then
      buffer = buffer:sub(1, -2)
      redraw(true)
    end
  until char == rtn
  buffer = buffer .. "\n"
  redraw()
  return buffer
end

function term.getViewport()
  return gpu.getViewport()
end

function term.isAvailable()
  return gpu.isAvailable()
end

return term
