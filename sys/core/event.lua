-- event API. Largely for compatibility, not really used by anything --

local event = {}

local computer = require("computer")
local sched = require("sched")
sched.register("key_down")
sched.register("key_up")
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

function event.pull(timeout, filter)
  checkArg(1, timeout, "number", "nil")
  checkArg(2, filter, "string", "nil")
  local filters = {filter}
  local max = (timeout and computer.uptime() + timeout) or math.huge
  repeat
--    print("pulling")
    local data = {coroutine.yield()}
    table.remove(data, 1)
    if data[1] == "interrupt" then
      error("interrupted")
    end
--    print("listeners")
    for k, v in pairs(listeners) do
      if v.event == data[1] then
        local ok, returned = pcall(v.callback, table.unpack(data, 1))
        if not ok then
          io.stderr:write("Evemt handler for '" .. v.event .. "' crashed: " .. returned .. "\n")
          listeners[k] = nil
        end
        if returned == false then
          listeners[k] = nil
        end
      end
    end
--    print("timed")
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
--    print(data[1], filter)
    if data[1] == filter or filter == nil then
      return table.unpack(data, 1)
    end
  until computer.uptime() >= max
  return nil
end

computer.pullSignal = event.pull

event.push = computer.pushSignal

package.loaded.event = event
