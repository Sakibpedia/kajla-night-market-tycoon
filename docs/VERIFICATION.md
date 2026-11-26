# Verification — Kajla Night Market Tycoon

Godot 4.3 stable, Windows. All commands exited 0.

| Suite | Result |
|---|---|
| `CityTest.tscn` | `[CITY2D] PASS` — 1,500 buildings (600 rendered), 341 roads, 30 shops, 16 plaza stalls, 15 gates |
| `EconomyTest.tscn` | `[ECON] PASS` — 15 nights, stock, pricing, staff, upgrades, save/reload |
| `run_all.ps1` | `[DAY] ALL 15 NIGHTS PASS` — every night built 46 stalls, spawned actors, served customers, hit profit/customer targets and completed successfully |

## Iteration log

- **Cycle 1:** transformed the 2.5D stealth project into a market sim (new autoload, market loop, HUD, menu, tests, art). Fixed GDScript typing issues found on the first run.
- **Cycle 2:** added striped stall awnings, HUD scrims, target bar and a real market plaza with 16 stalls in rows.
- **Cycle 3:** fixed repeated renderer OOM on the integrated GPU by drawing a 600-building subset (all 1,500 still collide), simplifying awnings and reducing customer count; spawned the player inside the plaza so the game opens on the market.

Four real gameplay frames (menu, market, stall management, night summary) were captured from the running game with `tools/test/ScreenshotTest.tscn`.

The Windows export was built and launched successfully. GitHub Actions runs the three suites and exports on every push, and attaches the `.exe` to tagged releases (`contents: write` is granted explicitly).

Credit: S M Nazmuz Sakib. Map data © OpenStreetMap contributors (ODbL).
