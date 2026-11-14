#!/usr/bin/env python3
import pathlib
import re
import sys
from datetime import datetime, timezone

ROOT = pathlib.Path(__file__).resolve().parent
SRC = ROOT / "src"
OUT = ROOT / "dist" / "hub.lua"

PRELUDE = """local __mods = {}
local __loaded = {}
local function __req(name)
\tlocal cached = __loaded[name]
\tif cached ~= nil then
\t\treturn cached
\tend
\tlocal factory = __mods[name]
\tif not factory then
\t\terror("module missing: " .. tostring(name))
\tend
\tlocal built = factory()
\t__loaded[name] = built
\treturn built
end
local require = __req
"""


def modules():
    names = ["vendor.orion", "lib.store", "core.hub"]
    games = sorted(p.stem for p in (SRC / "games").glob("*.lua"))
    names += [f"games.{g}" for g in games]
    names.append("main")
    return names


def version():
    text = (SRC / "core" / "hub.lua").read_text()
    found = re.search(r'version\s*=\s*"([^"]+)"', text)
    return found.group(1) if found else "0.0.0"


def main():
    parts = []
    for name in modules():
        path = SRC / (name.replace(".", "/") + ".lua")
        if not path.exists():
            sys.exit(f"missing module: {path}")
        parts.append((name, path.read_text().rstrip() + "\n"))

    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    head = f"-- ascend hub v{version()} | built {stamp} | do not edit, edit src/\n"
    body = [head, PRELUDE]

    for name, src in parts:
        body.append(f'\n__mods["{name}"] = function()\n')
        body.append(src)
        body.append("\nend\n")

    body.append('\nreturn __req("main")\n')

    OUT.parent.mkdir(exist_ok=True)
    OUT.write_text("".join(body))
    size = OUT.stat().st_size
    print(f"built {OUT.relative_to(ROOT)} ({size} bytes, {len(parts)} modules)")


if __name__ == "__main__":
    main()
