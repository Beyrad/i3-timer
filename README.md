# i3-timer

A tiny, clickable stopwatch for the i3 status bar.

It puts a clock icon in the i3bar system tray (next to other indicators such as
`nm-applet`), with a small menu to **Start/Pause** and **Reset** the timer. The
elapsed time is shown as a separate block at the end of the i3bar.

```
[ ... i3status modules ... ] [ ⏱ 00:12:34 ] [ tray: ⏰ ]
```

<p align="center">
  <img src="pics/sample.png" alt="i3-timer in the i3bar">
</p>

## Features

- System-tray icon with a click menu: Start/Pause and Reset.
- Elapsed time rendered by `i3status` at the end of the bar.
- Counts up and keeps its accumulated time across applet restarts (downtime is
  not counted).
- A single small Python process; no daemons or services.

## Requirements

- i3 with i3bar and i3status (for the `read_file` module)
- Python 3 with PyGObject (`python3-gi`)
- AppIndicator bindings (Ayatana preferred, classic fallback)

Install the dependencies:

```sh
# Ubuntu / Debian
sudo apt install i3 i3status python3-gi gir1.2-ayatanaappindicator3-0.1

# Arch Linux
sudo pacman -S i3-wm i3status python-gobject libayatana-appindicator

# Fedora
sudo dnf install i3 i3status python3-gobject libayatana-appindicator-gtk3
```

i3bar must have its tray enabled (`tray_output primary` is the default). This
project targets `i3status`; i3blocks and polybar need a different setup.

## Install

```sh
git clone https://github.com/Beyrad/i3-timer.git
cd i3-timer
./install.sh
```

The installer:

1. copies `i3-timer` to `~/.local/bin/` and the icon to
   `$XDG_DATA_HOME/i3-timer/icons/` (default `~/.local/share/i3-timer/icons/`),
2. adds a marked `read_file` block to your `i3status` config and sets
   `interval = 1`,
3. adds a marked `exec_always` line to your i3 config,
4. starts the applet and restarts i3 so the bar block appears.

A restart is required because `i3status` reads its configuration only when it
starts; `i3-msg reload` does not restart the running status process. If no
display is available, the installer asks you to restart i3 (`Mod+Shift+r`).

Backups are written next to every config as `config.bak-<timestamp>`. Running
the installer twice is safe.

If your i3/i3status configs live somewhere unusual, the installer prints the
lines to add manually instead.

Note: `interval = 1` makes every i3status module refresh each second, which is
needed for a smooth stopwatch. Colors require `colors = true` in the i3status
`general` block (the default).

## Usage

Click the clock icon in the tray:

- **Start / Pause** — begin or pause counting.
- **Reset** — set the timer back to `00:00:00`.

The elapsed time appears at the end of the i3bar and updates every second.

## Customize

- **Color**: edit the `color_good` value in the generated `read_file i3timer`
  block (defaults to cyan `#61e9f2`).
- **Icon**: replace `$XDG_DATA_HOME/i3-timer/icons/timer.png` (default
  `~/.local/share/i3-timer/icons/timer.png`).

## Troubleshooting

- **No tray icon**: make sure i3bar's tray is enabled (`tray_output primary`, or
  remove `tray_output none`) and that no other tray host is taking over.
- **`read_file ... No such file or directory`**: the applet is not running.
  Start it with `~/.local/bin/i3-timer &`, then restart i3 (`Mod+Shift+r`).
- **`i3timer - 2: No such file or directory` after uninstalling**: the running
  `i3status` still has the old config in memory. Run `i3-msg restart` (or
  `Mod+Shift+r`); the uninstaller does this automatically when a display is
  available.
- **Two icons**: only one instance is allowed; stop stray processes with
  `pkill -f 'bin/i3-timer$'` and restart i3 (`Mod+Shift+r`).
- **No time block**: the installer targets `i3status`; i3blocks/polybar setups
  are not supported out of the box.

## Uninstall

```sh
./uninstall.sh
```

This stops the applet, removes the installed files, and strips the marked blocks
from your configs (with backups), then restarts i3 so `i3status` drops the block.
Without a display it leaves the runtime time file in place (cleared on logout)
and asks you to restart, so the bar shows no `read_file` error in the meantime.
If you installed manually, remove the `i3-timer` lines from your configs
yourself.

## How it works

`i3-timer` is a small GTK/AppIndicator process. Every second it writes the
formatted elapsed time to `$XDG_RUNTIME_DIR/i3-timer.time`. An `i3status`
`read_file` module displays that file at the end of the bar. Timer state is kept
in `$XDG_RUNTIME_DIR/i3-timer.json`, and a lock file (`i3-timer.pid`) guarantees
a single running instance.

## Credits

Built with **DeepSeek V4.1 Flash Free**.

## License

MIT. See [LICENSE](LICENSE).
