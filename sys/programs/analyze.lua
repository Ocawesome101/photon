-- analyze: print boot times --

local kernel = os.kernelStartupTime()
local init = os.initStartupTime()
local total = kernel + init

print(("Startup finished in %02fs (kernel) + %02fs (userspace) = %02fs"):format(kernel, init, total))
