#!/usr/bin/env bash
set -euo pipefail

APP_NAME="i3-timer"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
DATA_DIR="$DATA_HOME/i3-timer"
ICON_DIR="$DATA_DIR/icons"
CFG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-}"
if [ -z "$RUNTIME_DIR" ]; then
    if [ -d "/run/user/$(id -u)" ]; then
        RUNTIME_DIR="/run/user/$(id -u)"
    else
        RUNTIME_DIR="/tmp/i3-timer-$(id -u)"
    fi
fi
TIME_FILE="$RUNTIME_DIR/i3-timer.time"
APP_PATH="$BIN_DIR/$APP_NAME"
STAMP="$(date +%Y%m%d-%H%M%S)"
BEGIN_MARK="# >>> i3-timer >>>"
END_MARK="# <<< i3-timer <<<"

say() { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

[ -f "$REPO_DIR/$APP_NAME" ] || die "run install.sh from the repository directory"
command -v python3 >/dev/null 2>&1 || die "python3 is required"
python3 - <<'PY' >/dev/null 2>&1 || die "GTK/AppIndicator bindings missing. Install python3-gi and gir1.2-ayatanaappindicator3-0.1 (or gir1.2-appindicator3-0.1)."
import gi
gi.require_version("Gtk", "3.0")
try:
    gi.require_version("AyatanaAppIndicator3", "0.1")
except ValueError:
    gi.require_version("AppIndicator3", "0.1")
PY

say "Installing files..."
install -d "$BIN_DIR" "$ICON_DIR"
mkdir -p "$RUNTIME_DIR"
install -m 755 "$REPO_DIR/$APP_NAME" "$APP_PATH"
install -m 644 "$REPO_DIR/icons/timer.png" "$ICON_DIR/timer.png"
[ -f "$TIME_FILE" ] || printf '00:00:00\n' > "$TIME_FILE"

I3STATUS_CONF=""
for candidate in "$CFG_HOME/i3status/config" "$HOME/.i3status.conf"; do
    if [ -f "$candidate" ]; then
        I3STATUS_CONF="$candidate"
        break
    fi
done
if [ -z "$I3STATUS_CONF" ]; then
    I3STATUS_CONF="$CFG_HOME/i3status/config"
    install -d "$(dirname "$I3STATUS_CONF")"
    if [ -f /etc/i3status.conf ]; then
        cp /etc/i3status.conf "$I3STATUS_CONF"
    else
        printf 'general {\n        colors = true\n}\n' > "$I3STATUS_CONF"
    fi
    say "Created $I3STATUS_CONF"
fi

python3 - "$I3STATUS_CONF" "$TIME_FILE" "$STAMP" "$BEGIN_MARK" "$END_MARK" <<'PY'
import re
import shutil
import sys

conf, time_file, stamp, begin, end = sys.argv[1:6]
with open(conf, encoding="utf-8") as handle:
    text = handle.read()

shutil.copy2(conf, conf + ".bak-" + stamp)
text = re.sub(r"\n?" + re.escape(begin) + r".*?" + re.escape(end) + r"\n?", "\n", text, flags=re.S)

if re.search(r"^\s*interval\s*=\s*\d+", text, re.M):
    text = re.sub(r"^(\s*interval\s*=\s*)\d+", r"\g<1>1", text, count=1, flags=re.M)
elif re.search(r"general\s*\{", text):
    match = re.search(r"general\s*\{", text)
    index = text.index("{", match.start()) + 1
    text = text[:index] + "\n        interval = 1" + text[index:]
else:
    text = "general {\n        interval = 1\n}\n\n" + text

block = (
    "\n" + begin + "\n"
    'order += "read_file i3timer"\n'
    "read_file i3timer {\n"
    '    path = "%s"\n'
    '    format = "\u23f1 %%content"\n'
    '    color_good = "#000080"\n'
    "}\n" + end + "\n"
) % time_file

with open(conf, "w", encoding="utf-8") as handle:
    handle.write(text.rstrip() + "\n" + block)
print("Updated " + conf)
PY

I3_CONF=""
for candidate in "$CFG_HOME/i3/config" "$HOME/.i3/config"; do
    if [ -f "$candidate" ]; then
        I3_CONF="$candidate"
        break
    fi
done

if [ -n "$I3_CONF" ]; then
    python3 - "$I3_CONF" "$APP_PATH" "$TIME_FILE" "$STAMP" "$BEGIN_MARK" "$END_MARK" <<'PY'
import re
import shutil
import sys

conf, app_path, time_file, stamp, begin, end = sys.argv[1:7]
with open(conf, encoding="utf-8") as handle:
    text = handle.read()

shutil.copy2(conf, conf + ".bak-" + stamp)
text = re.sub(r"\n?" + re.escape(begin) + r".*?" + re.escape(end) + r"\n?", "\n", text, flags=re.S)

command = "test -f %s || echo 00:00:00 > %s; exec %s" % (time_file, time_file, app_path)
block = "\n" + begin + "\n" + "exec --no-startup-id sh -c '%s'\n" % command + end + "\n"

with open(conf, "w", encoding="utf-8") as handle:
    handle.write(text.rstrip() + "\n" + block)
print("Updated " + conf)
PY
else
    warn "No i3 config found. Add this line manually:"
    say "exec --no-startup-id sh -c 'test -f \"$TIME_FILE\" || echo 00:00:00 > \"$TIME_FILE\"; exec \"$APP_PATH\"'"
fi

pkill -f "$APP_PATH" 2>/dev/null || true
setsid "$APP_PATH" >/dev/null 2>&1 &
if [ -n "${DISPLAY:-}" ] && command -v i3-msg >/dev/null 2>&1; then
    i3-msg reload >/dev/null 2>&1 || true
    say "Started i3-timer and reloaded i3."
else
    say "Started i3-timer. Reload i3 to update the bar."
fi

say ""
say "Done. Click the clock icon in the tray: Start/Pause, Stop, Reset."
say "Elapsed time appears at the end of the i3bar."
