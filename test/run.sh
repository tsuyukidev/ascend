#!/bin/sh
set -e
cd "$(dirname "$0")/.."
python3 build.py > /dev/null
sed 's/^return __req("main")$/__H = __req("main")/' dist/hub.lua > /tmp/ascend-bundle.lua
cat test/mock.lua /tmp/ascend-bundle.lua test/probe.lua > /tmp/ascend-smoke.lua
luau /tmp/ascend-smoke.lua
