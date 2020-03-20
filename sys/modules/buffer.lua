-- screen buffers, both hardware and software --

local buffer = {}

local gpu = require("drivers").loadDriver("gpu")
local computer = require("computer")

local w, h = gpu.maxResolution()
local bufferMode = "software"

function buffer.hardwareRequirementsMet()
  return (w >= 80 and h >= 25 and (computer.totalMemory() >= 512*1024 or w >= 160 and h >= 50))
end

function buffer.setMode()
  if w >= 160 and h >= 50 then
    bufferMode = "hardware"
    gpu.setViewport(1, 1, 80, 25)
  else
    bufferMode = "software"
  end
end

local used = {}

function buffer.bufferFromUnusedHardwareSpace()
  local b1 = {x = 81, y = 1}
  local b2 = {x = 1, y = 26}
  local b3 = {x = 81, y = 26}
  if not used.topRight then
    used.topRight = true
    return b1
  elseif not used.bottomLeft then
    used.bottomLeft = true
    return b2
  elseif not used.bottomRight then
    used.bottomRight = true
    return b3
  else
    return {x=0,y=0}
  end
end

function buffer.new(width, height)
  local new = {}
  if width == 80 and height == 25 and bufferMode == "hardware" and usedBuffers < 3 then -- for simplicity, only 3 full-screen buffers are supported in hardware
    new = buffer.bufferFromUnusedHardwareSpace()
    function new:set(x, y, s, f, b)
      checkArg(1, x, "number")
      checkArg(2, y, "number")
      checkArg(3, s, "string")
      checkArg(4, f, "number", "nil")
      checkArg(5, b, "number", "nil")
      if f then
        gpu.setForeground(f)
      end
      if b then
        gpu.setBackground(b)
      end
      gpu.set(self.x + x, self.y + y, s)
    end
    function new:draw()
      gpu.copy(self.x, self.y, 80, 25, 0 - self.x - 80, 0 - self.y - 25)
    end
    function new:fill(x, y, w, h, c, f, b)
      checkArg(1, x, "number")
      checkArg(2, y, "number")
      checkArg(3, w, "number")
      checkArg(4, h, "number")
      checkArg(5, c, "string")
      checkArg(6, f, "number", "nil")
      checkArg(7, b, "number", "nil")
      if f then
        gpu.setForeground(f)
      end
      if b then
        gpu.setBackground(b)
      end
      gpu.fill(self.x + x, self.y + y, w, h, c)
    end
  else
    new.buf = {}
    new.w = width
    new.h = height
    for h=1, height, 1 do
      new.buf[h] = {}
      for w=1, width, 1 do
        new.buf[h][w] = {" ", 0xFFFFFF, 0x000000}
      end
    end
    local function setChar(x, y, c, f, b)
      if not new.buf[y] or not new.buf[y][x] then
        return false, "index " .. x .. "*" .. y .. "out of bounds"
      end
      new.buf[y][x][1] = c
      if f then
        new.buf[y][x][2] = f
      end
      if b then
        new.buf[y][x][3] = b
      end
      return true
    end
    local function getChar(x, y)
      if not new.buf[y] or not new.buf[y][x] then
        return false, "index " .. x .. "*" .. y .. " out of bounds"
      end
      return new.buf[y][x]
    end
    function new:set(_x, _y, s, f, b)
      checkArg(1, _x, "number")
      checkArg(2, _y, "number")
      checkArg(3, s, "string")
      checkArg(4, f, "number", "nil")
      checkArg(5, b, "number", "nil")
      if _x > self.w or _y > self.h then
        return false, "index out of bounds"
      end
      local cx = _x
      for char in s:gmatch(".") do
        setChar(cx, _y, char, f, b)
        cx = cx + 1
      end
      return true
    end
    function new:fill(x, y, _w, _h, c, f, b)
      checkArg(1, x, "number")
      checkArg(2, y, "number")
      checkArg(3, _w, "number")
      checkArg(4, _h, "number")
      checkArg(5, c, "string")
      checkArg(6, f, "number", "nil")
      checkArg(7, b, "number", "nil")
      for _x=x, x+_w, 1 do
        for _y=y, y+_h, 1 do
          setChar(_x, _y, _c, f, b)
        end
      end
      return true
    end
    function new:drawToBuffer(buf, x, y)
      checkArg(1, buf, "table")
      checkArg(2, x, "number")
      checkArg(3, y, "number")
      for _y=1, self.h, 1 do
        for _x=1, self.w, 1 do
          local char = getChar(_x, _y)
          buf:set(x + _x, y + _y, char[1], char[2], char[3])
        end
      end
      return true
    end
    function new:draw()
      for _y=1, self.h, 1 do
        for _x=1, self.w, 1 do
          local char, err = getChar(_x, _y)
          if char then
            gpu.setForeground(char[2])
            gpu.setBackground(char[3])
            gpu.set(_x, _y, (char[1] or " "))
          else
            print(err)
          end
        end
      end
    end
    function new:width()
      return self.w
    end
  end
  return new
end

return buffer
