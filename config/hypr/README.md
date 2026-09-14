# Hyprland Keymap

## Applications

| Keybinding      | Action                                               |
| --------------- | ---------------------------------------------------- |
| `SUPER + Q`     | Open terminal (`ghostty`)                            |
| `SUPER + E`     | Open file manager (`dolphin`)                        |
| `SUPER + SPACE` | Open application launcher (`rofi` / drun mode)       |
| `SUPER + L`     | Lock screen (`hyprlock`)                             |
| `SUPER + I`     | Open logout menu (`wlogout`)                         |
| `SUPER + M`     | Open shutdown menu (`hyprshutdown`) or exit Hyprland |

---

## Window Management

| Keybinding  | Action                                         |
| ----------- | ---------------------------------------------- |
| `SUPER + C` | Close active window                            |
| `SUPER + V` | Toggle floating mode                           |
| `SUPER + P` | Toggle pseudo-tiling                           |
| `SUPER + J` | Toggle split direction (Dwindle layout)        |
| `SUPER + T` | Switch between `dwindle` and `monocle` layouts |

---

## Focus Navigation

| Keybinding          | Action                                  |
| ------------------- | --------------------------------------- |
| `ALT + TAB`         | Switch to the previously focused window |
| `SUPER + TAB`       | Cycle to the next layout element        |
| `ALT + SHIFT + TAB` | Cycle to the previous layout element    |
| `SUPER + ←`         | Move focus left                         |
| `SUPER + →`         | Move focus right                        |
| `SUPER + ↑`         | Move focus up                           |
| `SUPER + ↓`         | Move focus down                         |

---

## Workspaces

### Switching Workspaces

| Keybinding                 | Action                  |
| -------------------------- | ----------------------- |
| `SUPER + 1..9`             | Switch to workspace 1-9 |
| `SUPER + 0`                | Switch to workspace 10  |
| `SUPER + Mouse Wheel Down` | Next workspace          |
| `SUPER + Mouse Wheel Up`   | Previous workspace      |

### Moving Windows Between Workspaces

| Keybinding             | Action                              |
| ---------------------- | ----------------------------------- |
| `SUPER + SHIFT + 1..9` | Move active window to workspace 1-9 |
| `SUPER + SHIFT + 0`    | Move active window to workspace 10  |

---

## Special Workspace (Scratchpad)

| Keybinding          | Action                                          |
| ------------------- | ----------------------------------------------- |
| `SUPER + S`         | Toggle special workspace `magic`                |
| `SUPER + SHIFT + S` | Move active window to special workspace `magic` |

---

## Mouse Actions

| Keybinding                 | Action        |
| -------------------------- | ------------- |
| `SUPER + Left Mouse Drag`  | Move window   |
| `SUPER + Right Mouse Drag` | Resize window |

---

## Screenshots

| Keybinding      | Action                                               |
| --------------- | ---------------------------------------------------- |
| `PRINT`         | Save a full-screen screenshot                        |
| `SHIFT + PRINT` | Capture a selected area and copy it to the clipboard |

### Screenshot location

```text
~/Pictures/Screenshots/shot-YYYY-MM-DD_HH-MM-SS.png
```

---

## Audio Controls

| Keybinding             | Action                 |
| ---------------------- | ---------------------- |
| `XF86AudioRaiseVolume` | Increase volume by 5%  |
| `XF86AudioLowerVolume` | Decrease volume by 5%  |
| `XF86AudioMute`        | Toggle speaker mute    |
| `XF86AudioMicMute`     | Toggle microphone mute |

---

## Brightness Controls

| Keybinding              | Action                    |
| ----------------------- | ------------------------- |
| `XF86MonBrightnessUp`   | Increase brightness by 5% |
| `XF86MonBrightnessDown` | Decrease brightness by 5% |

---

## Media Controls

| Keybinding       | Action         |
| ---------------- | -------------- |
| `XF86AudioPlay`  | Play / Pause   |
| `XF86AudioPause` | Play / Pause   |
| `XF86AudioNext`  | Next track     |
| `XF86AudioPrev`  | Previous track |

---

## Configured Applications

| Function             | Application        |
| -------------------- | ------------------ |
| Terminal             | `ghostty`          |
| File Manager         | `dolphin`          |
| Application Launcher | `rofi` (drun mode) |
| Screen Lock          | `hyprlock`         |
| Logout Menu          | `wlogout`          |
| Screenshots          | `grim` + `slurp`   |
| Audio Control        | `wpctl`            |
| Media Control        | `playerctl`        |
| Brightness Control   | `brightnessctl`    |

---

## Modifier Keys

| Key     | Description                         |
| ------- | ----------------------------------- |
| `SUPER` | Windows / Super key (main modifier) |
| `SHIFT` | Shift key                           |
| `ALT`   | Alt key                             |
| `PRINT` | Print Screen key                    |
