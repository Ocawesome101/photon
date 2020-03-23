-- MOTD api --

local motd = {}

local shell_motds = {
  "Proton's source is available at https://github.com/ocawesome101/proton",
  "Pull requests are always welcome!",
  "Proton: Booting faster than OpenOS since... a long time. My OpenOS installation is still booting.",
  "Did you know Proton can multitask? Check out the sched API!",
  "Proton boots in exactly the same way OpenOS doesn't.",
  "Proton is the only functional OS I've written that isn't a complete Unix ripoff.",
  "Try out the package manager.... once I finish it. It doesn't work yet.",
  "Try the Proton Network Stack!"
}

function motd.random_shell()
  return shell_motds[math.random(1, #shell_motds)]
end

return motd
