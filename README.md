
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
3. Run the NecroLua.exe executable to launch the game with mods.
4. Enjoy!
5. If you have a question, feature request or bug report, please [open an issue][issues].

  [releases]: https://github.com/ManuelBlanc/NecroLua/releases
  [issues]: https://github.com/ManuelBlanc/NecroLua/issues

## Making mods
Check the [wiki documentation][wiki] for more information on the modding API.

  [wiki]: https://github.com/ManuelBlanc/NecroLua/wiki

## Building from source
To build NecroLua from source, run `nmake all`. You need the following software packages:

+ Microsoft command line build tools (MSVC v142 - VS 2019 C++ x64/86 build tools)
+ LuaJIT 2.1.0-beta3 (the libraries and the executable are both required)
+ Microsoft Research Detours Package (https://github.com/microsoft/Detours)
+ DbgHelp.dll – Windows Image Helper (included with Windows)
+ ImageMagick (_Optional_, used to make the app icon)

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
