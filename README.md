# Adderall

A tiny macOS menu bar toggle for `caffeinate`.

- **Left click** the pills icon: toggle keep-awake on/off (filled = on, dimmed = off)
- **Right click**: menu with Quit and a **Keep Display Awake** checkbox

While on, it runs `caffeinate -di -w <app pid>`, so the display and system stay awake, and caffeinate exits by itself if the app quits or crashes. Unchecking Keep Display Awake drops `-d`, so the system stays awake but the screen can still turn off. The setting is remembered across launches.

## Build

```sh
./build.sh           # builds build/Adderall.app
./build.sh install   # also copies it to /Applications
```

Needs the Xcode command line tools (`swiftc`). No Xcode project, no dependencies.
