
<p align="center">
  <a href="#necrolua">
    <img alt="NecroLua" src="https://repository-images.githubusercontent.com/197468562/e41a8000-abd0-11e9-9e7f-a23cbd23823f" width="749">
  </a>
</p>

# NecroLua
**NecroLua** adds modding capabilities to [Crypt of the NecroDancer][cotnd] via LuaJIT.

  [cotnd]: https://braceyourselfgames.com/crypt-of-the-necrodancer/

## Installation and usage
1. Download the [latest release][releases] (or [build](#building-from-source) it from the source).
2. Extract the zip in the same directory as the NecroDancer.exe executable. E.g.,
  ```
  C:\Program Files (x86)\Steam\steamapps\common\Crypt of the NecroDancer
  ```
3. Create a [test mod](#example-mod)
4. Run the NecroLua.exe executable to launch the game with mods.
5. Enjoy!
6. If you have a question, feature request or bug report, please [open an issue][issues].

  [releases]: https://github.com/ManuelBlanc/NecroLua/releases
  [issues]: https://github.com/ManuelBlanc/NecroLua/issues

## Making mods
Check the [wiki documentation][wiki] for more information on the modding API.

  [wiki]: https://github.com/ManuelBlanc/NecroLua/wiki

## Building from source
1. First, install the following software packages:

+ Microsoft command line build tools (MSVC v142 - VS 2019 C++ x64/86 build tools)
  + Make sure to use the x86 (32-bit) tools since NecroDancer.exe is a 32-bit executable
+ [LuaJIT 2.1.0-beta3][luajit]
  + Use luajit's included `src/msvcbuild.bat` instead of running the makefile
+ [Microsoft Research Detours Package][detours]
+ DbgHelp.dll – Windows Image Helper (included with Windows)
+ ImageMagick (_Optional_, used to make the app icon)

2. After installing the above packages, go to your NecroLua directory and create an `include` subdirectory and a `lib` subdirectory, and copy in the required headers and library files; the following files should be present:

```bash
$ ls lib/ include/
include/:
detours.h  lauxlib.h  lua.h  luaconf.h  luajit.h  lualib.h

lib/:
detours.lib  lua51.dll  lua51.lib
```

3. `nmake all`

4. Copy the following files to the same directory as the NecroDancer.exe executable:
+ `NecroLua.exe `
+ `NecroLuaAPI.dll`
+ `lua51.dll`
+ `steam_appid.txt`

  [luajit]: [https://luajit.org/install.html]
  [detours]: [https://github.com/microsoft/Detours]

5. Continue following the [install instructions](#installation-and-usage)

## Example mod

Set up the following directory structure:
```
Crypt of the NecroDancer
|-- NecroDancer.exe
|-- ...
|-- <other files and directories>
|-- ...
`-- mods
    `-- example-mod
        `-- lua
            `-- init.lua
```

`init.lua` should have the following contents:
```lua
print ""
print "loading lua mod"
print ""

necrolua.hook("c_Player::p_GetElectricStrength", function(func, self)
  return 1 - func(self)
end)
```

This mod will make invert your character's electricity; e.g. you will do arcing electric attacks when you're _not_ on the zone 5 wire.

## Authors
+ [ManuelBlanc](https://github.com/ManuelBlanc)

Special thanks to IamLupo and Adikso.

## License
Copyright (C) 2019 ManuelBlanc

This is free software, and you are welcome to redistribute it under certain conditions.
See Copyright Notice in [LICENSE.txt](./LICENSE.txt) for details.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
