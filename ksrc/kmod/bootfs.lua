-- Boot filesystem proxy, for loading drivers. --
local addr = computer.getBootAddress()
local bootfs = component.proxy(addr)
