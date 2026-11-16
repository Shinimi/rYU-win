<h1 align="center">rYu-win</h1>
<p align="center">crimson, tiling, quiet. my Windows 10 setup.</p>

<p align="center">
  <img src="screenshots/desktop.png" width="90%">
</p>

Started this because I wanted Hyprland on Windows and kept getting most of the way there.
It's GlazeWM for tiling, YASB on top, red animated borders, no taskbar, and everything
recolored dark red / near black. Built and used daily on **Windows 10 IoT Enterprise LTSC 2021**,
should be fine on regular Windows 10 22H2. Windows 11 works for most of it but isn't what I use.

## What's in it

| | |
|---|---|
| **Tiling** | [GlazeWM](https://github.com/glzr-io/glazewm), 9 workspaces on the main screen, 1 on the side screen |
| **Bar** | [YASB](https://github.com/amnweb/yasb), based on [Akira_YASB](https://github.com/MrDLingters/Akira_YASB) by MrDLingters, recolored |
| **Borders** | [tacky-borders](https://github.com/lukeyou05/tacky-borders), spinning crimson gradient + glow on the focused window |
| **Taskbar** | hidden with [thide](https://github.com/amnweb/thide) |
| **Launcher** | [Flow Launcher](https://github.com/Flow-Launcher/Flow.Launcher) on Win+Space, crimson theme |
| **Explorer** | wine-red glass ([ExplorerBlurMica](https://github.com/Maplespe/ExplorerBlurMica)) + my own crimson glass icon set |
| **Accent** | #DC143C everywhere, [AccentColorizer](https://github.com/krlvm/AccentColorizer) for the stubborn blue bits |
| **Cursor** | [Bibata Modern](https://github.com/ful1e5/Bibata_Cursor) rebuilt in crimson |
| **Start menu** | [Open-Shell](https://github.com/Open-Shell/Open-Shell-Menu), Win7 layout, dark |
| **Right click** | [Nilesoft Shell](https://nilesoft.org) with a crimson theme |
| **Terminal** | Windows Terminal (portable build, works on LTSC) + [fastfetch](https://github.com/fastfetch-cli/fastfetch) + small prompt |
| **Workspace animation** | `rYuSwitch`, a tiny helper I wrote that slides/fades the old workspace out |
| **Apps** | themes for Discord (Vencord/Vesktop), Spotify (Spicetify), Steam (Millennium), Telegram, Waterfox, Helium, Vivaldi |

## Screenshots

<p align="center">
  <img src="screenshots/explorer.png" width="48%">
  <img src="screenshots/terminal.png" width="48%">
</p>
<p align="center">
  <img src="screenshots/rightclick.png" width="30%">
  <img src="screenshots/startmenu.png" width="30%">
</p>

## Install

1. Download the repo (Code > Download ZIP) and unzip it somewhere it can stay, like `Documents\rYu-win`.
2. Double click `install.cmd`, say yes to the admin prompt.
3. Pick what you want. Enter installs the recommended set, `all` installs everything,
   or type numbers like `1 3 4`.
4. Sign out and back in once.

Everything is split into modules, so you can also do `install.cmd core icons` from a terminal.
Apps are downloaded from their official GitHub releases while installing, nothing prebuilt is shipped here.

Your old GlazeWM / YASB / tacky-borders configs get backed up next to the new ones as `*.before-rYu`.

**Wallpapers:** drop your own into `wallpapers/` before installing (they end up in `Pictures\Wallpapers`,
which is where the YASB wallpaper picker looks). Lock screen uses whatever your desktop wallpaper is.

## Undo

`uninstall.cmd` - same menu, every module has an undo. It doesn't uninstall the apps themselves
(GlazeWM, YASB etc.), it just stops them, takes them out of autostart and puts your configs back.

## Keybinds

| keys | what |
|---|---|
| `Win + 1..9` | go to workspace |
| `Win + Shift + 1..9` | send window to workspace |
| `Win + Shift + 0` | send window to the side screen |
| `Win + Arrows` | focus left / right / up / down |
| `Win + Shift + Arrows` | move window |
| `Win + Space` | Flow Launcher |
| `Alt + Space` | YASB search |
| `Win + Enter` | terminal |
| `Win + Q` | close window |
| `Win + V` | float / tile |
| `Win + F` | fullscreen |
| `Win + T` | flip split direction |
| `Alt + Shift + R` | reload GlazeWM, bar and borders |
| `Alt + Shift + E` | quit GlazeWM |

## Notes

- Set up for two monitors: workspaces 1-9 on monitor 0, workspace 10 on monitor 1. One monitor works too,
  edit `bind_to_monitor` in `config/glazewm/config.yaml` if things land in the wrong place.
- If you re-run `core` after `wsanim`, run `wsanim` again (core puts the default GlazeWM keybinds back).
- `rYuSwitch` takes a screenshot of the current workspace, puts it on top, switches underneath and slides it
  away. It's a trick, so video on the old workspace freezes for ~0.2s. Speed is `DurationMs` / `SlidePct`
  at the top of `modules/wsanim/rYuSwitch.cs`. Don't like it? `uninstall.cmd wsanim`.
- Glass too dark or too see-through: change `a=` in `modules/glass/config.ini` (higher = more solid) and run the glass module again.
- Steam and Telegram need a couple of clicks by hand, see the README in their module folders.
- Logs end up in `%TEMP%\rYu-win\`.

## Layout

```
config/      GlazeWM, YASB, tacky-borders, Flow Launcher
modules/     one folder per part, each with apply.ps1 / undo.ps1
scripts/     installer + shared helpers
wallpapers/  put yours here
```

## Credits

See [CREDITS.md](CREDITS.md). Huge thanks to everyone there, this is mostly their work glued together and painted red.

## License

MIT for my own stuff (scripts, configs, icons, rYuSwitch). The bundled cursor files are GPL-3.0 like Bibata itself,
and everything that gets downloaded keeps its own license.
