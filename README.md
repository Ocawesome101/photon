# Photon

Photon is a modular, lightweight hybrid kernel for the OpenComputers Minecraft mod.

## Building

While a precompiled kernel does ship with Photon, you may want to build it yourself. To do so, you will need [Luacomp](https://github.com/Adorable-Catgirl/Luacomp) and Lua 5.3.

Download Luacomp to somewhere in your `$PATH`, then execute the following commands:
```bash
cd /path/to/your/local/copy/ksrc
make
```
Copy the resulting script to `/boot` in your OpenComputers filesystem.

## Background Services

Photon supports background services through the use of the `rc` shell command. By default, though Photon ships with a few background services available, none are enabled. Default services are:

  * `combod`: Listens for keyboard shortcuts and queues signals appropriately
  * `mountd`: Automatically (un)mounts filesystems when they are added or removed
  * `cursorblink`: Blinks the cursor

Available `rc` commands are `start`, `stop`, `restart`, `disable`, and `enable`.

## Progress

- [ ] Photon
  - [X] Kernel
    - [X] Component Proxies
    - [X] Logging
    - [X] Cooperative Scheduler + IPC
    - [X] Userspace Sandbox
  - [ ] Userspace
    - [X] Init
    - [ ] Drivers
      - [ ] Filesystems
        - [X] Managed
        - [ ] Unmanaged
          - [ ] OpenFS
          - [ ] OpenUPT
      - [X] Graphics Card
      - [X] Networking
        - [X] Internet Card
        - [X] Network Card
      - [X] Redstone Card
      - [ ] Data Card
      - [ ] EEPROM
      - [ ] 3D Printer
      - [ ] Robot
      - [ ] Computronics
        - [ ] Tape Drive
        - [ ] Speaker
        - [X] Beep Card
        - [X] Sound Card
        - [X] Noise Card
    - [ ] Some kind of network stack
    - [ ] Libraries
      - [X] Lua Standard
        - [X] io
        - [X] package
        - [X] os
      - [ ] Custom
        - [X] text
        - [X] term
        - [X] shell
        - [X] sched
        - [X] drivers
        - [ ] utils
          - [X] splitter
          - [X] serialization
          - [ ] notes
        - [ ] tui
    - [ ] Interfaces
      - [ ] Photon Shell
        - [ ] Commands
          - [X] ls
          - [X] cp
          - [X] mv
          - [X] cd
          - [X] cat
          - [X] pwd
          - [X] mkdir
          - [x] echo
          - [ ] lshw
          - [X] rm
          - [ ] alias
          - [X] clear
          - [X] free
          - [X] ps
          - [X] kill
          - [X] lua
          - [X] power
          - [X] components
          - [X] set
          - [X] unset
          - [X] wc
          - [X] mount
          - [ ] umount
        - [ ] Aliases
        - [X] Variables (ish)
        - [ ] ? TTYs
           Note: There was an attempt at TTYs. It failed.
      - [ ] Modularity Desktop Environment
        - [ ] Base
          - [ ] Windows
            - [ ] Closable
            - [ ] Movable
            - [ ] ? Resizable
          - [ ] Menus
            - [ ] Right-click
            - [ ] Left-click
        - [ ] Buffering?
          - [ ] HW buffering (T3 only), 80x25
          - [ ] SW buffering (RAM heavy), up to 160x50
    - [ ] Photon Package Manager
      - [ ] Repo lists
      - [ ] Package lists
      - [ ] Packages
        - [ ] Install
        - [ ] Remove
        - [ ] Search
