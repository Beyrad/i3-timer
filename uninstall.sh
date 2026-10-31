#!/usr/bin/env bash
set -euo pipefail

APP_NAME="i3-timer"
BIN_DIR="$HOME/.local/bin"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
DATA_DIR="$DATA_HOME/i3-timer"
CFG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BEGIN_MARK="# >>> i3-timer >>>"
END_MARK="# <<< i3-timer <<<"

pkill -f "$BIN_DIR/$APP_NAME" 2>/dev/null || true
rm -f "$BIN_DIR/$APP_NAME"
rm -rf "$DATA_DIR"
rm -f "$RUNTIME_DIR/i3-timer.time" "$RUNTIME_DIR/i3-timer.json"

for conf in "$CFG_HOME/i3status/config" "$HOME/.i3status.conf" "$CFG_HOME/i3/config" "$HOME/.i3/config"; do
    [ -f "$conf" ] || continue
    python3 - "$conf" "$STAMP" "$BEGIN_MARK" "$END_MARK" <<'PY'
import re
import shutil
import sys

conf, stamp, begin, end = sys.argv[1:5]
with open(conf, encoding="utf-8") as handle:
    text = handle.read()
if begin not in text:
    sys.exit(0)
shutil.copy2(conf, conf + ".bak-" + stamp)
text = re.sub(r"\n?" + re.escape(begin) + r".*?" + re.escape(end) + r"\n?", "\n", text, flags=re.S)
with open(conf, "w", encoding="utf-8") as handle:
    handle.write(text)
print("Cleaned " + conf)
PY
done

if [ -n "${DISPLAY:-}" ] && command -v i3-msg >/dev/null 2>&1; then
    i3-msg reload >/dev/null 2>&1 || true
fi
echo "i3-timer uninstalled."
