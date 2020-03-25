-- MOTD api --

local motd = {}

local shell_motds = {
  "Photon's source is available at https://github.com/ocawesome101/photon",
  "Pull requests are always welcome!",
  "Photon: Booting faster than OpenOS since... a long time. My OpenOS installation is still booting.",
  "Did you know Photon can multitask? Check out the sched API!",
  "Photon boots in exactly the same way OpenOS doesn't.",
  "Photon is the only functional OS I've written that isn't a complete Unix ripoff.",
  "Try out the package manager.... once I finish it. It doesn't work yet.",
  "Try the Photon Network Stack!"
}

function motd.random_shell()
  return shell_motds[math.random(1, #shell_motds)]
end

return motd
