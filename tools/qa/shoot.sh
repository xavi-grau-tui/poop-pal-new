#!/bin/zsh
# QA screenshots (development only): backs up the testing save, runs tools/qa/capture.tscn
# windowed with the given args, restores the save. Usage: tools/qa/shoot.sh game=1 levels=1,10 out=/tmp/x
# (HEADLESS=1 runs it without a window: no pictures, but every script error shows up; LINES_OUT=n shows
# n lines of its output instead of 40)
UD="$HOME/Library/Application Support/Godot/app_userdata/HaraTomo"
BK="$(mktemp -d)"
cp "${UD:?}"/*.json "${BK:?}"/ 2>/dev/null
if [[ -n "$HEADLESS" ]]; then MODE=(--headless); else MODE=(--windowed --resolution 540x960); fi
# (FAST=1 with HEADLESS=1: a fixed 60 fps step, run as fast as the computer goes: autopilot checks)
if [[ -n "$FAST" ]]; then MODE+=(--fixed-fps 60); fi
/Applications/Godot.app/Contents/MacOS/Godot --path "$(dirname $0)/../.." --audio-driver Dummy $MODE res://tools/qa/capture.tscn -- "$@" 2>&1 | grep -E "QA |SCRIPT ERROR|Parse Error|ERROR: .*res://|at: res://|Invalid" | head -${LINES_OUT:-40}
cp "${BK:?}"/*.json "${UD:?}"/ 2>/dev/null
rm -rf "${BK:?}"
