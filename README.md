# i3-timer

A tiny, clickable stopwatch for the i3 status bar.

It puts a clock icon in the i3bar system tray (next to other indicators such as
`nm-applet`), with a small menu to **Start/Pause**, **Stop**, and **Reset**. The
elapsed time is shown as a separate block at the end of the i3bar.

```
[ ... i3status modules ... ] [ ⏱ 00:12:34 ] [ tray: ⏰ ]
```

<p align="center">
  <img src="pics/sample.png" width="300" alt="Sample">
</p>

## Features

- System-tray icon with a click menu (Start/Pause, Stop, Reset).
- Elapsed time rendered by `i3status` at the end of the bar.
- Counts up, keeps its value when stopped, survives applet restarts.
- No daemons or services: a single small Python process.

## Requirements

- i3 with i3bar and i3status
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

## Install

```sh
git clone https://github.com/<your-username>/i3-timer.git
cd i3-timer
./install.sh
```

The installer:

1. copies `i3-timer` to `~/.local/bin/` and the icon to `~/.local/share/i3-timer/`,
2. adds a marked `read_file` block to your `i3status` config and sets
   `interval = 1`,
3. adds a marked `exec` line to your i3 config,
4. starts the applet and reloads i3.

Backups are written next to every config as `config.bak-<timestamp>`. Running
the installer twice is safe.

If your i3/i3status configs live somewhere unusual, the installer prints the
lines to add manually instead.

## Usage

Click the clock icon in the tray:

- **Start / Pause** — begin or pause counting.
- **Stop** — freeze the current value.
- **Reset** — set the timer back to `00:00:00`.

The elapsed time appears at the end of the i3bar and updates every second.

## Customize

- **Color**: edit the `color_good` value in the generated `read_file i3timer`
  block (defaults to cyan `#61e9f2`).
- **Icon**: replace `~/.local/share/i3-timer/icons/timer.png` with your own PNG.

## Uninstall

```sh
./uninstall.sh
```

This stops the applet, removes the installed files, and strips the marked blocks
from your configs (with backups). If you installed manually, remove the
`i3-timer` lines from your configs yourself.

## How it works

`i3-timer` is a small GTK/AppIndicator process. Every second it writes the
formatted elapsed time to `$XDG_RUNTIME_DIR/i3-timer.time`. An `i3status`
`read_file` module displays that file at the end of the bar. Timer state is kept
in `$XDG_RUNTIME_DIR/i3-timer.json`.

## Credits

Built with **DeepSeek V4.1 Flash Free**.

## License

MIT. See [LICENSE](LICENSE).
