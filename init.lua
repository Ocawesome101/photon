-- init. You've all seen this by now, go away --
local a,p,i=computer.getBootAddress(),computer.pullSignal,component.invoke;local h,e=i(a,"open","/sys/core/okern.lua");if not h then error(e)end;local d=""repeat local c=i(a,"read",h,math.huge)d=d..(c or"")until not c;i(a,"close",h);local o,e=load(d,"=/sys/core/okern.lua","t",_G);if not o then error(e)end;ok()while true do p()end
