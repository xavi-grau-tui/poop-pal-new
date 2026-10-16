#!/bin/zsh
# QA screenshots (development only): backs up the testing save, runs tools/qa/capture.tscn
# windowed with the given args, restores the save. Usage: tools/qa/shoot.sh game=1 levels=1,10 out=/tmp/x
# (HEADLESS=1 runs it without a window: no pictures, but every script error shows up)
UD="$HOME/Library/Application Support/Godot/app_userdata/HaraTomo"
BK="$(mktemp -d)"
cp "${UD:?}"/*.json "${BK:?}"/ 2>/dev/null
if [[ -n "$HEADLESS" ]]; then MODE=(--headless); else MODE=(--windowed --resolution 540x960); fi
/Applications/Godot.app/Contents/MacOS/Godot --path "$(dirname $0)/../.." --audio-driver Dummy $MODE res://tools/qa/capture.tscn -- "$@" 2>&1 | grep -E "QA |SCRIPT ERROR|Parse Error|ERROR: .*res://|at: res://|Invalid" | head -40
cp "${BK:?}"/*.json "${UD:?}"/ 2>/dev/null
rm -rf "${BK:?}"
