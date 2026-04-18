<div align="center">

<img src="App/Assets.xcassets/AppIcon.appiconset/icon_256.png" width="180" height="180" />

# Cat Monitor

### A tiny pixel cat lives in your macOS menu bar, purrsonally watched over by yours truly

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)](https://www.apple.com/macos/)
[![Swift 5.10](https://img.shields.io/badge/Swift-5.10-orange)](https://swift.org/)


[Get Started](#build) · [Features](#features) · [How It Works](#how-it-works)

</div>


## Download

Grab the latest DMG from [Releases](https://github.com/kornvik/Cat-Monitor/releases). Open it, drag to Applications, meow.

On first launch, right-click > Open to bypass Gatekeeper (the app is not notarized yet, nya). It will also ask for Accessibility permission so the cat can watch you type.

## What is this?

Type and the cat types too. Stop and the cat chills. Meow. Next to the cat you'll see CPU, Memory, GPU, and Disk usage at a glance. Click it and a popover shows up with gauge rings, temperatures, GPU memory, and network speeds. Everything a cat needs to keep an eye on, meow.

## Features

- Animated pixel cat that reacts to your typing, nya
- CPU, Memory, GPU, Disk percentages in the menu bar
- Popover with gauge rings, CPU/GPU temps, GPU memory, network speeds
- Reads Apple Silicon SMC temps directly, meow
- Super lightweight, sits around 0.5% CPU when idle. Cats are efficient like that

## Build

```bash
brew install xcodegen
xcodegen generate
xcodebuild -project CatMonitor.xcodeproj -scheme CatMonitorApp -configuration Release build
```

Copy the built app from `DerivedData/` to `/Applications` and add it to your Login Items to keep it running. The cat doesn't like being left behind, nya.

## How it works

The cat lives in an `NSStatusItem`. Stats refresh every 2 seconds. Temperatures and GPU memory only update when the popover is open to save resources. Gotta conserve energy for naps, nya.

Keyboard monitoring uses `NSEvent.addGlobalMonitorForEvents` which needs Accessibility permission. The app will ask for it on first launch, meow.

Temperatures come from direct SMC access via `IOConnectCallStructMethod`, which means this app runs outside the sandbox and can't go on the Mac App Store. Same story as iStat Menus and other serious system monitors, nya.

## Project structure

```
App/Sources/         Main menu bar app
Shared/Sources/      System stats, colors
project.yml          XcodeGen config
```

## License

MIT. Free as a cat should be, meow.
