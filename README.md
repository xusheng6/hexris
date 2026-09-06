# Hexris

A block-puzzle game for iPad, built with Flutter/Dart. Inspired by a now-deprecated iOS game that is no longer available on the App Store — this project recreates its gameplay and visual style from scratch.

The game features two board modes — a classic 10x10 square grid and a
61-cell hexagonal grid — where players drag and drop pieces to fill and clear
lines. Modern Hexris rules are enabled by default, with a compact Classic
ruleset available from Settings.

## Screenshot

<p align="center">
  <img src="screenshots/hex_mode.png" width="300" alt="Hex mode gameplay">
</p>

## Features

- **Two board modes**: Square (10x10 grid) and Hex (radius-4 hexagonal grid with 61 cells)
- **Two rulesets**: modern Hexris (default) and Classic
- **Drag-and-drop** pieces from a 3-piece tray onto the board
- **Line clearing**: complete rows/columns (square) or any of 3 hex axes to clear cells
- **Undo**: take back your last move(s)
- **Classic rules**: alternate piece catalogs, probabilities, tray refill,
  shape/color grouping, scoring, and progression
- **High score** tracking per board mode and ruleset

## Rulesets

Modern rules are enabled by default. Turn on **Classic rules** in Settings for
the alternate piece generation, tray refill, and scoring behavior. Changing
rulesets starts a fresh board so state from the two systems cannot mix.

See [docs/classic-rules.md](docs/classic-rules.md) for the mechanics, complete
probability tables, and differences from modern Hexris.

## Building

```bash
flutter run          # run on connected device
flutter run -d macos # run on macOS desktop
```

Requires Flutter SDK 3.x+.
