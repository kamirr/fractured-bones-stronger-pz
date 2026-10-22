# Fractured Bones Stronger

A Project Zomboid mod that gives a healed body part a configurable chance to prevent future fractures.

## Layout

The game mod package is in `Contents/mods/FracturedBonesStronger`. After a body part's first fracture heals, each later fracture attempt on that same part gets one prevention roll. The chance defaults to 50% and can be set from 0% to 100% in sandbox settings. The chance does not increase when the part fractures and heals again.

## Local development

Project Zomboid mods do not need a separate build step. To try the package in game, copy or link `Contents/mods/FracturedBonesStronger` into the local Project Zomboid `mods` directory, enable it from the Mods menu, set the prevention chance in sandbox options, and check the game log for load errors.

## Continuous integration

GitHub Actions runs package metadata checks and Lua 5.1 behavior and syntax checks on pull requests and pushes to `main`. A separate dedicated-server smoke workflow installs the Project Zomboid server through SteamCMD, enables this mod, and checks that the server starts and reports the mod in its console. The server job is resource-intensive and can also be started manually from the Actions tab.
