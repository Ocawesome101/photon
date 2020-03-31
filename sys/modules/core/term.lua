-- mostly OpenOS-compatible term API. --

local sched = require("sched")
local gpu, err = require("drivers").loadDriver("gpu")
if not gpu then
  error(err)
end
local event

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

function term.write(str, wrapmode)
  checkArg(1, str, "string")
  checkArg(2, wrapmode, "string", "nil")
  local old = cursor
  cursor = false
  cursor_update()
  str = str:gsub("\t", "    ")
  local wrap = (wrapmode == "precise" and wrapmode) or "word"
  local words = {}
  local word = ""
  local printed = 0
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
    if x + #word + 1 > w and wrap == "word" then
      newline()
      printed = printed + 1
    end
    for char in word:gmatch(".") do
      if char == "\n" then
        newline()
        printed = printed + 1
      else
        if x + 1 > w then
           newline()
           printed = printed + 1
        end
        gpu.set(x, y, char)
        x = x + 1
      end
    end
  end
  cursor = old
  cursor_update()
  return printed
end

local bksp = string.char(8)
local rtn = string.char(13)
local up = string.char(200)
local down = string.char(208)
local max = 127
local min = 32

function term.read(hist, rep)
  checkArg(1, hist, "table", "nil")
  checkArg(2, rep, "string", "nil")
  event = event or require("event")
  local buffer = ""
  local startX, startY = term.getCursor()
  sched.register("key_down")
  local hist = hist or {}
  local hpos = 0
  local function redraw(bk)
    term.setCursor(startX, startY)
    local printed = term.write((rep and rep:sub(1,1):rep(#buffer)) or buffer, "precise")
    if startY + printed > h then
      startY = h - printed
    end
    if bk then
      cursor = false
      local _x, _y = term.getCursor()
      term.write(" ")
      cursor = true
      term.setCursor(_x, _y)
    end
  end
  local reason = "enter"
  repeat
    redraw()
    local event, _, char, code = event.pull()
    if event == "key_down" then
      char = string.char(char)
      local byte = (string.byte(char) or 1)
      if byte >= min and byte <= max then
        buffer = buffer .. char
      elseif char == bksp then
        buffer = buffer:sub(1, -2)
        redraw(true)
      elseif code == 200 then -- up
        if hpos < #hist then
          hpos = hpos + 1
        end
        buffer = (" "):rep(#buffer + 1)
        local old = cursor
        cursor = false
        redraw(true)
        cursor = old
        buffer = (hist[hpos] or "")
      elseif code == 208 then -- down
        if hpos > 0 then
          hpos = hpos - 1
        end
        buffer = (" "):rep(#buffer + 1)
        local old = cursor
        cursor = false
        redraw(true)
        cursor = old
        buffer = (hist[hpos] or "")
      end
    elseif event == "interrupt" then
      print("^C")
      error("interrupted")
    elseif event == "exit" then
      reason = "exit"
    elseif event == "clipboard" then
      buffer = buffer .. char
    end
  until char == rtn or event == "exit"
  buffer = buffer .. "\n"
  redraw()
  return buffer, reason
end

function term.getViewport()
  return gpu.getViewport()
end

function term.isAvailable()
  return gpu.isAvailable()
end

return term
