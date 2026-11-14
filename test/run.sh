#!/bin/sh
set -e
cd "$(dirname "$0")/.."
python3 build.py
luau-compile --binary dist/hub.lua > /dev/null
echo "bundle compiles"

ORION=src/vendor/orion.lua
for api in "MakeWindow" "MakeTab" "AddSection" "AddButton" "AddToggle" "AddSlider" "AddDropdown" "AddTextbox" "AddParagraph" "AddLabel" "MakeNotification" "Destroy"; do
	grep -q "function .*:$api(" "$ORION" || grep -q "function .*\.$api(" "$ORION" || { echo "missing orion api: $api"; exit 1; }
done
echo "orion api present"

grep -q "rayfield-collect\|loadstring(fetchResult" "$ORION" && { echo "telemetry still vendored"; exit 1; }
echo "no remote reporter"
