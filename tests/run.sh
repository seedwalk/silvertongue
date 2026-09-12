#!/bin/sh
# Runs both harnesses against the addon source. Needs any Lua 5.1 interpreter.
# The harnesses stub the WoW API; they check logic, not layout.
LUA="${LUA:-lua5.1}"
command -v "$LUA" >/dev/null 2>&1 || { echo "Set LUA=/path/to/lua (5.1)"; exit 1; }
cd "$(dirname "$0")" || exit 1
"$LUA" test_engine.lua && "$LUA" test_ui.lua
