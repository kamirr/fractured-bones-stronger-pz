# Fractured Bones Stronger

A Project Zomboid mod that gives a healed body part a configurable chance to prevent future fractures.

## Layout

The game mod package is in `Contents/mods/FracturedBonesStronger`. After a body part's first fracture heals, each later fracture attempt on that same part gets one prevention roll. The chance defaults to 50% and can be set from 0% to 100% in sandbox settings. The chance does not increase when the part fractures and heals again.

## Manual fracture testing

In Sandbox Options, set **Enable fracture test commands** to `true`. This option defaults to `false`; on a multiplayer server, only admins can use these commands. Set **Fracture prevention chance** to `100` for a deterministic prevention test, then enter commands in chat:

```text
/fbs test ForeArm_L
```

`test` resets that body part's history, creates its first fracture, clears it to record healing, then attempts a second fracture through the normal prevention logic. The command reports whether prevention occurred. To step through the lifecycle manually, use:

```text
/fbs reset ForeArm_L
/fbs fracture ForeArm_L
/fbs heal ForeArm_L
/fbs fracture ForeArm_L
/fbs status ForeArm_L
```

Supported test parts are `ForeArm_L`, `ForeArm_R`, `Shin_L`/`LowerLeg_L`, `Shin_R`/`LowerLeg_R`, `Thigh_L`/`UpperLeg_L`, and `Thigh_R`/`UpperLeg_R`. The part defaults to `ForeArm_L`; `/fbs help` lists the available actions.

## Local development

Project Zomboid mods do not need a separate build step. To try the package in game, copy or link `Contents/mods/FracturedBonesStronger` into the local Project Zomboid `mods` directory, enable it from the Mods menu, set the prevention chance in sandbox options, and check the game log for load errors.

## Continuous integration

GitHub Actions runs package metadata checks and Lua 5.1 behavior and syntax checks on pull requests and pushes to `main`. A separate dedicated-server smoke workflow installs the Project Zomboid server through SteamCMD, enables this mod, and checks that the server starts and reports the mod in its console. The server job is resource-intensive and can also be started manually from the Actions tab.
