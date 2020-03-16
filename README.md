# Proton

Proton is a modular, lightweight hybrid kernel for the OpenComputers Minecraft mod.

## Building

While a precompiled kernel does ship with this Git repository, you may want to build it yourself. To do so, you will need [Luacomp](https://github.com/Adorable-Catgirl/Luacomp) and Lua 5.3.

Download Luacomp to somewhere in your `$PATH`, then execute the following commands:
```bash
cd /path/to/your/local/copy/ksrc
make
```
Copy the resulting script to `/boot` in your OpenComputers filesystem.
