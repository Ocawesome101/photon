-- The base of the Modularity desktop environment. --

local config = require("config")
local buffer = require("buffer")
local unicode = require("unicode")
local sched = require("sched")

print("Loading Modularity configuration")
local cfg = {
  background = 0x6699FF
}

cfg = config.loadWithDefaults("/sys/config/modularity.cfg", cfg)

local ok, err = buffer.hardwareRequirementsMet() 
if not ok then
  error("Hardware requirements not met: " .. err)
end

buffer.setMode()

local logotop = " _  _  _|   | _  _.|_  "
local logomid = "|||(_)(_||_||(_|| ||_\\/"
local logobot = "                     / "
local slogan  = "Loading..."

local root = buffer.new(80, 25)

root:fill(1, 1, 80, 25, " ", nil, cfg.background)
root:fill(25, 5, 30, 10, " ", nil, 0xCCCCCC)
root:set(29, 6, logotop, 0x000000, 0xCCCCCC)
root:set(29, 7, logomid, 0x000000, 0xCCCCCC)
root:set(29, 8, logobot, 0x000000, 0xCCCCCC)
root:set(35, 11, slogan, 0x000000, 0xCCCCCC)
root:draw()

local windowBuffers = {}

local modwm = {} -- the WM api

function modwm.createWindow(topLeftX, topLeftY, width, height, title)
  checkArg(1, topLeftX, "number")
  checkArg(2, topLeftY, "number")
  checkArg(3, width, "number")
  checkArg(4, height, "number")
  checkArg(5, title, "string")
  local new = buffer.new(width, height)
  new:fill(1, 1, width, height, " ", 0xFFFFFF)
  for _,d in ipairs(windowBuffers) do
    d.layer = d.layer + 1
  end
  windowBuffers[#windowBuffers + 1] = {canvas = new, x = topLeftX, y = topLeftY, title, layer = 1}
  return new, #windowBuffers
end

function modwm.removeWindow(id)
  checkArg(1, id, "number")
  if not windowBuffers[id] then
    return false, "no such window"
  end
  local old = windowBuffers[id].layer
  for _,d in ipairs(windowBuffers) do
    if d.layer == old then
      d = nil
    elseif d.layer > old then
      d.layer = d.layer - 1
    end
  end
  return true
end

function modwm.windows()
  local windows = {}
  for _, data in ipairs(windowBuffers) do
    windows[data.layer] = data.title
  end
  return windows
end

function modwm.raise(id)
  checkArg(1, id, "number")
  if not windowBuffers[id] then
    return false, "no such window"
  end
  for _,d in ipairs(windowBuffers) do -- shift all windows back a layer
    d.layer = d.layer + 1
  end
  windowBuffers[id].layer = 1
  return true
end

local function makeTitlebar(width, title)
  return string,format("%s%sX", title, (" "):rep(width - #title - 1))
end

function modwm.redraw()
  root:fill(1, 1, 80, 25, " ", nil, cfg.background)
  local windows = {}
  for _, d in ipairs(windowBuffers) do -- organize windows so we can draw them in the correct order
    windows[d.layer] = {x = d.x, y = d.y, w = d.canvas:width(), title = d.title, canvas = d.canvas}
  end
  for i=#windows, 1, -1 do -- iterate backwards through the windows
    local x, y = windows[i].x, windows[i].y + 1
    root:set(x, y - 1, makeTitlebar(windows[i].w, windows[i].title))
    windows[i].canvas:drawToBuffer(root, x, y)
  end
  root:draw()
end

package.loaded.modwm = modwm

local ok, err = loadfile("/sys/programs/modularity/modwm.lua")
if not ok then
  error("Failed to load click_listener: " .. err)
end

local ok = sched.spawn(ok, "modwm")
