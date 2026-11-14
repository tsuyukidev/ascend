# Ascend

Executor script hub. Modular source, bundled into one loadstring-able file.

```
src/
  lib/ui.lua        custom window lib (tabs, toggles, sliders, dropdowns, textboxes, toasts)
  lib/store.lua     config persistence via writefile/readfile
  core/hub.lua      registry, feature binding, Hub tab (runner, config, unload)
  games/*.lua       per-game modules, auto-picked by the bundler
  main.lua          entry
dist/hub.lua        build output, this is what you host
loader.lua          one-line bootstrap to paste in an executor
test/               mock Roblox env + smoke probe
```

## Build

```sh
python3 build.py     # writes dist/hub.lua
sh test/run.sh       # syntax + runtime smoke under a mocked engine
```

## Load

Host `dist/hub.lua` somewhere raw (github raw, cdn), then in an executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/dist/hub.lua"))()
```

`loader.lua` is the same thing with a pcall wrapper, edit the url first.

## Add a game module

Create `src/games/<name>.lua`, rebuild, done. Bundler globs the folder.

```lua
local mod = { name = "Blox Fruits", features = {} }

mod.features = {
    { name = "Auto Farm", type = "toggle", section = "Farm", run = function(state) end },
    { name = "Range", type = "slider", section = "Farm", min = 1, max = 100, default = 20,
      run = function(value) end },
    { name = "Mode", type = "dropdown", section = "Farm", options = { "A", "B" },
      run = function(value) end },
    { name = "Hop", section = "Utility", run = function() end },
}

function mod.init(tab) end       -- optional, runs before features
function mod.build(tab) end      -- optional, custom UI
function mod.cleanup() end       -- optional, runs on unload

return mod
```

Feature keys:

| key | meaning |
|---|---|
| `name` | row label, also the config key (`Module.name`) |
| `type` | `button` (default), `toggle`, `slider`, `dropdown`, `textbox` |
| `section` | group header, defaults to `General` |
| `min` / `max` / `default` | slider bounds and initial value |
| `options` | dropdown entries |
| `run` | callback; receives state/value/text |
| `placeholder` | textbox hint |

Toggles and sliders persist to `ascend/config.json` and re-apply on load.

## Instance

`getgenv().Ascend` holds the running instance:

```lua
getgenv().Ascend:unload()
```
