-- mostly OpenOS-compatible term API. --

local tty = require("tty")

local term = {}

local w, h = tty.maxResolution()

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
  tty.__update_cursor()
end

local function scroll()
  tty.scroll()
end

local function newline()
  local old = tty.getCursorBlink()
  tty.setCursorBlink(true)
  cursor_update()
  tty.setCursorBlink(old)
  cursor_update()
  local x, y = tty.getCursor()
  if y == h then
    tty.scroll()
    tty.setCursor(1, y)
  else
    tty.setCursor(1, y + 1)
  end
end

function term.setCursor(nx, ny)
  checkArg(1, nx, "number")
  checkArg(2, ny, "number")
  return tty.setCursor(nx, ny)
end

function term.getCursor()
  return tty.getCursor()
end

function term.setCursorBlink(bool)
  checkArg(1, bool, "boolean")
  tty.setCursorBlink(bool)
end

function term.getCursorBlink()
  return tty.getCursorBlink()
end

function term.setCursorChar(char)
  checkArg(1, char, "string")
  return tty.setCursorChar(char)
end

function term.getCursorChar()
  return tty.getCursorChar()
end

function term.clear()
  tty.clear()
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
    local x, y = tty.getCursor()
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
        tty.set(x, y, char)
        x = x + 1
      end
      tty.setCursor(x, y)
    end
  end
  cursor = old
  cursor_update()
end

local bksp = string.char(8)
local rtn = string.char(13)
local ctrlc = string.char(237)
local max = 127
local min = 32

function term.read() -- it is ALWAYS advisable to use this function over io.read, as io.read returns characters and does not support deletion.
  local buffer = ""
  local startX, startY = term.getCursor()
  local startTTY = tty.getTTY()
  local function redraw(bk)
    term.setCursor(startX, startY)
    term.write(buffer)
    if bk then
      tty.setCursorBlink(false)
      local _x, _y = term.getCursor()
      term.write(" ")
      tty.setCursorBlink(true)
      term.setCursor(_x, _y)
    end
  end
  repeat
    coroutine.yield()
    if tty.getTTY() == startTTY then
      redraw()
      local char = (io.read(1) or string.char(1))
      local byte = (string.byte(char) or 1)
      if byte >= min and byte <= max then
        buffer = buffer .. char
      elseif char == bksp then
        buffer = buffer:sub(1, -2)
        redraw(true)
      end
    end
  until char == rtn
  buffer = buffer .. "\n"
  redraw()
  return buffer
end

function term.getViewport()
  return tty.maxResolution()
end

function term.isAvailable()
  return tty.isAvailable()
end

return term
