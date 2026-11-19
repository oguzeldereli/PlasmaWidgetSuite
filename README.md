# Lattice — a Plasma 6 widget suite

A small set of desktop widgets that look like the readout panel of a quiet,
well-made scientific instrument. No heavy cards — everything floats on the
wallpaper as **hairline rules, tick marks, monospace numerals and sparklines**,
sharing one design language so they read as a single system.

Built for an ML/AI + .NET/React + low-level dev workflow, plus music.

## The widgets

| id | name | what it shows |
|----|------|---------------|
| `org.lattice.core`  | **Core**  | ML-forward system vitals — GPU utilisation, **VRAM** (the metric that bottlenecks ML), GPU temp, CPU and memory, with hairline sparklines. VRAM/mem fill turns amber→red as it fills. |
| `org.lattice.flux`  | **Flux**  | Minimalist now-playing (MPRIS): track, hairline seek bar, album art (thumbnail or faint backdrop), a quiet spectrum, and transport controls. |
| `org.lattice.epoch` | **Epoch** | Dev-time: clock, ISO week, **day-of-year (172/365)**, a year-progress hairline, a live **Unix epoch counter** and uptime. |
| `org.lattice.probe` | **Probe** | Network throughput as twin down/up sparklines with live rates and session peaks. |
| `org.lattice.stack` | **Stack** | A glance at pinned git repos — project-type tag (NET/NODE/PY/RS/GO/CPP), branch, **dirty count**, ahead/behind. Click a repo to open it (configurable command). |
| `org.lattice.rail`  | **Rail**  | A creative launcher toolbar: hairline command cells that show a glyph at rest and **slide their label open on hover**, with a leading `›` prompt. Runs inline in a panel or on the desktop. |
| `org.lattice.deck`  | **Deck**  | A creative task manager — a **window "tape"**: app icons on hairline ticks; the active window lights its segment in accent and slides its title open, hover reveals any title, demands-attention pulses. Click activates / toggles minimise, middle-click closes, **right-click → Pin to deck** (pinned apps stay as a dock even when closed; pin state persists). **Drag a cell to reorder** (pinned order persists). Hover labels open rightward without shifting the tape. Optional mono icons that pop to colour on focus. |

## How it stays "in place" on any wallpaper

- **Every colour derives from your active Plasma colour scheme**, so the suite
  is automatically correct on light *and* dark wallpapers.
- The **accent** defaults to your scheme's highlight colour (so it matches the
  rest of your desktop); override it per-widget in the config.
- An optional **adaptive scrim** (Appearance → Backing scrim) adds a subtle,
  scheme-tinted frosted plate behind the content for busy wallpapers. It's at
  0% by default for the fully-floating look.

## Type

Data/numerals use **CaskaydiaCove Nerd Font Mono** (so glyph icons render
inline); captions use **Inter**.

## Install

```sh
./build.sh            # assemble shared lib into each widget + install/upgrade all
./build.sh core       # build + install a single widget (core|flux|epoch|probe)
./build.sh assemble   # only copy the shared library in (no install)
./build.sh restart    # restart plasmashell
```

Then right-click the desktop → **Add Widgets…** → search **"Lattice"**.

### Top bar (global menu)

A slim top panel laid out as:

```
[ ◉ Launcher ] [ Global Menu ] ····· [ Deck task tape ] ····· [ Rail ] [ Epoch clock ]
```

A full-screen app launcher (kickerdash) on the far left, real application menus,
the window tape centered, launchers + clock on the right. It's additive — your
existing panels are untouched.

**Super/Meta key:** apply binds Super to that launcher (full-screen, so it always
opens centered) and disables the orphaned generic *"activate application launcher"*
shortcut that was popping up in the top-left corner. Because the shortcut registry
is owned by `kglobalacceld` (which rewrites the file from memory), the script
edits `kglobalshortcutsrc` while both `plasmashell` and `kglobalacceld` are
stopped, then restarts them — so the change sticks. `remove` restores the default.

```sh
./panel/setup-top-bar.sh          # apply (idempotent — safe to re-run)
./panel/setup-top-bar.sh remove   # remove it
```

### Deck traversal shortcuts

Global keyboard shortcuts to walk the windows along the Deck (stable creation
order, wrapping around). Landing on a window **un-minimises and activates** it.

```sh
./panel/setup-shortcuts.sh          # Meta+]  next window,  Meta+[  previous
./panel/setup-shortcuts.sh remove   # remove them
```

Rebind in **System Settings → Shortcuts → KWin → "Lattice Deck …"**.

Implemented as a **KWin script** (`panel/kwin-deck/`) so it works on **Wayland
and X11** — it registers its own shortcuts, keeps its own stable window order
(KWin's live list reorders on focus), and activates + un-minimises the target.
To also maximise the window you land on, set `FORCE_MAXIMIZE = true` at the top
of `panel/kwin-deck/contents/code/main.js` and re-run `setup-shortcuts.sh`.

The Global Menu shows each focused app's real menus (KWin's appmenu export).
A true *custom*-styled global menu isn't possible in pure QML here — the menu
model lives inside the compiled `org.kde.plasma.appmenu` applet — so the suite
uses that applet and styles the panel around it.

After upgrading an already-placed widget you may need to log out/in or run
`./build.sh restart` for plasmashell to pick up the new QML.

## Project layout

```
shared/ui/            design system — copied into each widget at build time
  Theme.qml           tokens: type, metrics, motion, colour helpers (singleton)
  Caption / MonoText  letter-spaced caps label + tabular mono numerals
  Hairline / Ticks    the recurring 1px rule + tick-strip motif
  Sparkline / Meter   crisp sparkline + ticked bar gauge
  Scrim               adaptive legibility backing
widgets/org.lattice.*/  one Plasma applet package each (core/flux/epoch/probe/stack/rail)
panel/                top-bar.js + setup-top-bar.sh — the global-menu top panel
build.sh              assembles shared/ into each package and (re)installs
```

The shared components are kept DRY in `shared/ui/` and copied into each
package's `contents/ui/lattice/` by `build.sh`, which also generates the
`qmldir` (declaring `Theme` as a singleton). Widgets import them with
`import "lattice" as Lattice`.

## Requirements

- Plasma 6, Qt 6.7+ (tested on Plasma 6.7 / Qt 6.11).
- `core` reads `nvidia-smi` for GPU/VRAM/temp; without it the GPU section shows
  "not detected" and CPU/memory still work.
- `flux` uses `org.kde.plasma.private.mpris`.

## License

MIT.
