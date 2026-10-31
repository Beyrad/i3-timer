#!/usr/bin/env bash
set -euo pipefail

APP_NAME="i3-timer"
BIN_DIR="$HOME/.local/bin"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
DATA_DIR="$DATA_HOME/i3-timer"
CFG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-}"
if [ -z "$RUNTIME_DIR" ]; then
    if [ -d "/run/user/$(id -u)" ]; then
        RUNTIME_DIR="/run/user/$(id -u)"
    else
        RUNTIME_DIR="/tmp/i3-timer-$(id -u)"
    fi
fi
STAMP="$(date +%Y%m%d-%H%M%S)"
BEGIN_MARK="# >>> i3-timer >>>"
END_MARK="# <<< i3-timer <<<"

warn() { printf 'warning: %s\n' "$*" >&2; }

stop_applet() {
    local pidfile="$RUNTIME_DIR/i3-timer.pid"
    [ -f "$pidfile" ] || return 0
    local pid
    pid="$(cat "$pidfile" 2>/dev/null || true)"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null \
        && tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null | grep -q "i3-timer"; then
        kill "$pid" 2>/dev/null || true
        local i
        for i in 1 2 3 4 5; do
            kill -0 "$pid" 2>/dev/null || break
            sleep 0.1
        done
    fi
    rm -f "$pidfile"
}

restart_i3() {
    if [ -n "${DISPLAY:-}" ] && command -v i3-msg >/dev/null 2>&1; then
        if i3-msg restart >/dev/null 2>&1; then
            return 0
        fi
        warn "i3-msg restart failed."
    fi
    warn "Restart i3 (Mod+Shift+r) so i3status drops the timer block."
    return 1
}

stop_applet
rm -f "$BIN_DIR/$APP_NAME"
rm -rf "$DATA_DIR"

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

if restart_i3; then
    sleep 1
    rm -f "$RUNTIME_DIR/i3-timer.time" "$RUNTIME_DIR/i3-timer.time.tmp"
else
    rm -f "$RUNTIME_DIR/i3-timer.time.tmp"
    if [ -d "$RUNTIME_DIR" ]; then
        printf '00:00:00\n' > "$RUNTIME_DIR/i3-timer.time"
    fi
    echo "Left $RUNTIME_DIR/i3-timer.time in place so the current bar shows no read_file error; it is cleared on logout."
fi
rm -f "$RUNTIME_DIR/i3-timer.json" "$RUNTIME_DIR/i3-timer.json.tmp"
rm -f "$RUNTIME_DIR/i3-timer.pid"
echo "i3-timer uninstalled."
