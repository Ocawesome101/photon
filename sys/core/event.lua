-- event API. Largely for compatibility, not really used by anything --

local event = {}

local computer = require("computer")
local pull = computer.pullSignal

local listeners = {}
local timed = {}

function event.listen(evt, call)
  checkArg(1, evt, "string")
  checkArg(2, call, "function")
  for k,v in pairs(listeners) do
    if v.event == evt and v.callback == call then
      return false
    end
  end
  listeners[#listeners + 1] = {event = evt, callback = call}
  return #listeners
end

function event.ignore(evt, call)
  checkArg(1, evt, "string")
  checkArg(2, call, "function")
  for k,v in pairs(listeners) do
    if v.event == evt and v.callback == call then
      listeners[v] = nil
      return true
    end
  end
  return false
end

function event.timer(interval, callback, times)
  checkArg(1, interval, "number")
  checkArg(2, callback, "function")
  checkArg(3, times, "number", "nil")
  local times = times or 1
  timed[#timed + 1] = {interval = interval, callback = callback, called = 0, max = times, last = computer.uptime()}
  return #timed
end

function event.cancel(id)
  checkArg(1, id, "number")
  if not timed[id] then
    return false
  end
  timed[id] = nil
  return true
end

function event.pull(timeout, ...)
  checkArg(1, timeout, "number", "nil")
  local filters = {...}
  local max = (timeout and computer.uptime() + timeout) or math.huge
  repeat
    local data = {pull()}
    if data[2] == "interrupt" then
      error("interrupted")
    end
    for k, v in pairs(listeners) do
      if v.event == data[2] then
        local ok, returned = pcall(v.callback, table.unpack(data, 2))
        if not ok then
          io.stderr:write("Evemt handler for '" .. v.event .. "' crashed: " .. returned .. "\n")
          listeners[k] = nil
        end
        if returned == false then
          listeners[k] = nil
        end
      end
    end
    for k, v in pairs(timed) do
      if computer.uptime() >= v.last + v.interval then
        local ok, returned = pcall(v.callback)
        if not ok then
          io.stderr:write("Timer " .. k .. " crashed: " .. returned .. "\n")
          timed[k] = nil
        end
        v.last = computer.uptime()
        v.called = v.called + 1
        if v.called >= v.max then
          timed[k] = nil
        end
      end
    end
    local send = true
    for i, f in pairs(data) do
      if data[i] ~= filters[i] and filters[i] ~= nil then
        send = false
      end
    end
    if send then
      return table.unpack(data, 2)
    end
  until computer.uptime() >= max
  return nil
end

computer.pullSignal = event.pull

event.push = computer.pushSignal

package.loaded.event = event
