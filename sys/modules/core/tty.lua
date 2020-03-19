-- TTYs. This API is behind-the-scenes of the term API.  --

local gpu = require("drivers").loadDriver("gpu")
local computer = require("computer")

local tty = {}

local tty_enabled = computer.totalMemory() >= 512*1024 -- buffers take a lot of memory, especially 4 8000-character buffers.

local current = 0

local x, y, w, h = 1, 1, gpu.maxResolution()
gpu.setResolution(w, h)

local newTTYProgram = "/sys/programs/shell.lua"

local cursor_default = require("unicode").char(0x258f)

-- for when buffers are disabled
local cursor = true
local cx, cy = 1, 1

local buffers

if tty_enabled then -- no point in wasting memory
  buffers = {
    [0] = {
      cursorX = 1,
      cursorY = 1,
      cursorChar = cursor_default,
      cursor = true,
      running = "/sys/programs/shell.lua",
      buffer = {}
    },
    [1] = {
      cursorX = 1,
      cursorY = 1,
      cursorChar = cursor_default,
      cursor = true,
      running = "",
      buffer = {}
    },
    [2] = {
      cursorX = 1,
      cursorY = 1,
      cursorChar = cursor_default,
      cursor = true,
      running = "",
      buffer = {}
    },
    [3] = {
      cursorX = 1,
      cursorY = 1,
      cursorChar = cursor_default,
      cursor = true,
      running = "",
      buffer = {}
    }
  }

  -- Initialize buffers
  for b=0, 3, 1 do
    for l=1, h, 1 do
      buffers[b].buffer[l] = ""
    end
  end
end

-- This function is probably REALLY slow. 50 GPU calls, even on a T3 GPU, isn't fast.
function tty.__update()
  if tty_enabled then
    local b = buffers[current].buffer
    for i=1, #b, 1 do
      gpu.set(1, i, b[i])
    end
  else
    return
  end
end

function tty.__update_cursor()
  if tty_enabled then
    local b = buffers[current]
    gpu.set(b.cursorX, b.cursorY, (b.cursor and b.cursorChar) or " ")
  else
    gpu.set(cx, cy, (cursor and default_cursor) or " ")
  end
end

function tty.setTTY(num)
  checkArg(1, num, "number")
  if not tty_enabled then
    return false, "TTYs are not enabled."
  end
  if num > 3 then
    num = 0
  elseif num < 0 then
    num = 3
  end
  current = num
  gpu.fill(1, 1, w, h, " ")
  if buffers[current].running == "" then
    local ok, err = loadfile(newTTYProgram)
    if ok then
      require("sched").spawn(ok, newTTYProgram)
    end
  end
  tty.__update()
end

function tty.getTTY()
  return current
end

function tty.setCursorBlink(bool)
  checkArg(1, bool, "boolean")
  if tty_enabled then
    buffers[current].cursor = bool
  else
    cursor = bool
  end
end

function tty.getCursorBlink()
  if tty_enabled then
    return buffers[current].cursor
  else
    return cursor
  end
end

function tty.setCursor(nx, ny)
  checkArg(1, nx, "number")
  checkArg(2, ny, "number")
  if nx <= w and ny <= h then
    if tty_enabled then
      buffers[current].cursorX = nx
      buffers[current].cursorY = ny
    else
      cx, cy = nx, ny
    end
    return true
  else
    return false, "index out of bounds"
  end
end

function tty.setCursorX(nx)
  checkArg(1, nx, "number")
  if nx <= w then
    if tty_enabled then
      buffers[current].cursorX = nx
    else
      cx = nx
    end
    return true
  else
    return false, "index out of bounds"
  end
end

function tty.setCursorY(ny)
  checkArg(1, ny, "number")
  if ny <= h then
    if tty_enabed then
      buffers[current].cursorY = ny
    else
      cy = ny
    end
    return true
  else
    return false, "index out of bounds"
  end
end

function tty.getCursor()
  if tty_enabled then
    return buffers[current].cursorX, buffers[current].cursorY
  else
    return cx, cy
  end
end

function tty.set(_x, _y, _s) -- wrapper around gpu.set that interfaces with the buffer
  checkArg(1, _x, "number")
  checkArg(2, _y, "number")
  checkArg(3, _s, "string")
  if _x > w or _y > h then
    return false, "index out of bounds"
  end
  if tty_enabled then
    local tmp = buffers[current].buffer[_y]
    buffers[current].buffer[_y] = tmp:sub(1, _x) .. _s .. tmp:sub(_x + #_s)
  end
  gpu.set(_x, _y, _s)
  return true
end

function tty.clear()
  if tty_enabled then
    for l=1, h, 1 do
      buffers[current].buffer[l] = ""
    end
  end
  gpu.fill(1, 1, w, h, " ")
end

function tty.setCursorChar(c)
  checkArg(1, c, "string")
  if tty_enabled then
    buffers[current].cursorChar = c:sub(1,1)
  else
    cursor_defaule = c:sub(1,1)
  end
end

function tty.getCursorChar()
  if tty_enabled then
    return buffers[current].cursorChar
  else
    return default_char
  end
end

function tty.scroll()
  gpu.copy(1, 1, w, h, 0, -1)
  gpu.fill(1, w, h, 1, " ")
  if tty_enabled then
    for l=2, h, 1 do
      buffers[current].buffer[l - 1] = buffers[current].buffer[l]
    end
    buffers[current].buffer[h] = ""
  end
end

function tty.maxResolution()
  return gpu.maxResolution()
end

function tty.isAvailable()
  return (gpu and gpu.getScreen() and true) or false
end

return tty
