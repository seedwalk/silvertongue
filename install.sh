#!/bin/sh
# Copies the addon over the installed copy. Plain files, no symlink:
# the game gets its own copy, and this overwrites it every time.
set -e

SRC="$(cd "$(dirname "$0")" && pwd)/Silvertongue"
DEST="${WOW_ADDONS:-/home/fede/.local/share/Steam/steamapps/compatdata/4146968419/pfx/drive_c/Program Files (x86)/World of Warcraft/_anniversary_/Interface/AddOns}"

[ -d "$SRC" ] || { echo "Source not found: $SRC"; exit 1; }

# Never ship a red run. Skip with SKIP_TESTS=1 when there is a reason to.
if [ -z "$SKIP_TESTS" ] && [ -x "$(dirname "$0")/tests/run.sh" ]; then
    if ! "$(dirname "$0")/tests/run.sh" >/dev/null 2>&1; then
        echo "Tests are failing. Not installing."
        echo "Run tests/run.sh to see why, or set SKIP_TESTS=1 to install anyway."
        exit 1
    fi
fi
[ -d "$DEST" ] || { echo "AddOns folder not found: $DEST"; exit 1; }

# The addon was called Shamanolo before. Leaving it installed would load both
# copies, and they fight over the same global frame names.
if [ -d "$DEST/Shamanolo" ]; then
    echo "Removing the old Shamanolo install."
    rm -rf "$DEST/Shamanolo"
fi

# Replace the old copy outright so deleted files do not linger.
rm -rf "$DEST/Silvertongue"
cp -r "$SRC" "$DEST/Silvertongue"

echo "Installed to: $DEST/Silvertongue"
echo "$(find "$DEST/Silvertongue" -type f | wc -l) files"
echo "Use /reload in game (or restart the client if it was not running)."
