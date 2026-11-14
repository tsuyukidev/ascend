# Ascend

Executor script hub built on Orion. Modular source, bundled into one loadstring-able file.

```
src/
  vendor/orion.lua  Orion UI library, vendored and audited
  lib/store.lua     config persistence via writefile/readfile
  core/hub.lua      registry, feature binding, Hub tab (runner, config, unload)
  games/*.lua       per-game modules, auto-picked by the bundler
  main.lua          entry
dist/hub.lua        build output, this is what you host
loader.lua          one-line bootstrap to paste in an executor
test/run.sh         build + compile + orion api + telemetry check
```

## Orion note

`shlexware/Orion` is deleted. The surviving mirror (`jensonhirst/Orion`) ships two things
the upstream lib did not: a `loadstring` of
`raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/.../reporter.lua` with a baked analytics
token, and a "UI Library Upgrade" ad notification on every window. Both are stripped in
`src/vendor/orion.lua`, and the gui parenting is hardened (`gethui` optional, `syn` optional,
fallback to PlayerGui). Vendoring also means no runtime fetch of a lib someone else controls.

Only remaining remote call is the Feather icon list JSON (data, pcall guarded, no code exec).

## Build

```sh
sh test/run.sh       # builds dist/hub.lua, compiles it, checks api + telemetry strip
python3 build.py     # build only
```

## Load

Host `dist/hub.lua` somewhere raw (github raw, cdn), then in an executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/tsuyukidev/ascend/master/dist/hub.lua"))()
```

`loader.lua` is the same thing with a pcall wrapper, edit the url first.

## Add a game module

Create `src/games/<name>.lua`, rebuild, done. Bundler globs the folder.

```lua
local mod = { name = "Blox Fruits", icon = "", features = {} }

mod.features = {
    { name = "Auto Farm", type = "toggle", section = "Farm", run = function(state) end },
    { name = "Range", type = "slider", section = "Farm", min = 1, max = 100, default = 20,
      run = function(value) end },
    { name = "Mode", type = "dropdown", section = "Farm", options = { "A", "B" },
      run = function(value) end },
    { name = "Hop", section = "Utility", run = function() end },
}

function mod.init(tab) end       -- optional, runs before features
function mod.build(tab) end      -- optional, custom ui via orion api
function mod.cleanup() end       -- optional, runs on unload

return mod
```

Feature keys:

| key | meaning |
|---|---|
| `name` | row label, also the config key (`Module.name`) |
| `type` | `button` (default), `toggle`, `slider`, `dropdown`, `textbox` |
| `section` | group header, defaults to `General` |
| `min` / `max` / `default` / `step` / `unit` | slider bounds, initial value, increment, suffix |
| `options` | dropdown entries |
| `color` | per element accent, defaults to the hub purple |
| `run` | callback; receives state/value/text |
| `icon` | module tab icon, feather icon name, empty for none |

Toggles, sliders, dropdowns and textboxes persist to `ascend/config.json` and re-apply on load.
Orion fires each callback once during construction, so saved values take effect immediately.

## Instance

`getgenv().Ascend` holds the running instance:

```lua
getgenv().Ascend:unload()
```

Reinjecting also kills the previous instance and destroys the old gui.
