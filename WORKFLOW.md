# Astraea Voss — wallpaper, HUD & theme workflow

**Astraea Voss**, callsign **The Last Wayfinder** — the star-maiden, the last guide. A small caduceus + "HERMES PROTOCOL // MESSENGER OF THE DIGITAL GODS"
on every HUD is the tribute to Hermes (messenger and guide of travelers).
Look: Hermes gold × Solo Leveling System window × Ghost in the Shell, post-apocalyptic survivor.

## 1. Folder map

```
astraea-voss/                      (project root = ~/astraea-voss)
├── WORKFLOW.md                   this file
├── config/
│   ├── project.json              ALL wording, scenes, theme names/colours, glitch amounts  ← edit here
│   └── bible.txt                 character description for every image prompt
├── assets/fonts/                 Tektur + Geist Mono (SIL OFL), bundled
├── art/
│   ├── raw/scenes/               scene-1..6.png   Codex output, 1672x941
│   ├── raw/concept/              astraea-voss-concept.png
│   ├── upscaled/                 scene-1..6.png   2560x1440 — what the builder reads
│   └── legacy/
│       ├── raw/                  first-batch-v1..6.png   (earlier look)
│       └── upscaled/             v1_/v3_ × gold|shadow|postapo.png (2560x1440 + palette washes; builder reads via `image`)
├── src/
│   ├── build_hud.py              art + config → dist/<theme>/scene-N-tag.png   (+ build/ scratch)
│   └── install_to_themes.py      dist → Omarchy themes (strict, archives what it replaces)
├── dist/<theme>/                 FINAL wallpapers, grouped by theme (+ dist/contact-sheet.png). Rebuildable.
├── build/                        scratch (created on demand, safe to delete)
├── backups/<timestamp>/<theme>/  theme text files saved before each install
├── docs/PHILOSOPHY.md            "Signal Discipline" design philosophy
└── archive/                      history only — see archive/README.md
```
Installed themes live in `~/.config/omarchy/themes/astraea-*`.

## 2. Themes and scenes (one image = one HUD wallpaper, in exactly one theme)

| Theme (menu name) | Folder | Scenes | HUD accent / secondary |
|---|---|---|---|
| Astraea Section 9 | `astraea-section-9` | 1 rooftop · 4 garage | gold / ice-cyan |
| Astraea Gold | `astraea-gold` | 2 salt-basin · 7 overwatch | gold / coral |
| Astraea Shadow | `astraea-shadow` | 3 subway · 5 snow-highway | violet / ice-blue |
| Astraea Post Apo | `astraea-post-apo` | 6 flooded-skiff · 8 night-rain | amber / steel-blue |

Wallpaper files inside a theme: `NN-<folder>-<tag>.png`, in scene order. Cycle: `omarchy theme bg next`; pick: `omarchy theme bg-switcher`; switch theme: `omarchy theme set "Astraea Gold"`.

## 3. Pipeline

| # | Step | Command / action |
|---|---|---|
| 1 | Generate art (Codex, `image_generation` on) | prompt = `config/bible.txt` + scene; save `art/raw/scenes/scene-N.png`. `cd ~/astraea-voss && codex exec --skip-git-repo-check "<prompt>"` (flags unverified on 0.159.3 — test one) |
| 2 | Upscale | `magick art/raw/scenes/scene-N.png -filter Lanczos -resize 2560x1440! -unsharp 0x1 art/upscaled/scene-N.png` |
| 3 | Describe the scene | `config/project.json → scenes[]`: `id, tag, theme, clear_width` (x where the character starts), `shade` (left darkening 0–1), `location`, `kit[3]`, optional `image`, `style:"calm"` |
| 4 | Build | `python3 src/build_hud.py` (all, ~40 s) or `python3 src/build_hud.py 2 5` |
| 5 | Review | `dist/contact-sheet.png` — legibility, overlaps, character untouched |
| 6 | Dry-run | `python3 src/install_to_themes.py --dry-run` |
| 7 | Install | `python3 src/install_to_themes.py` (add `--apply` to switch to the first theme) |
| 8 | Verify | look at it with real windows + Waybar over it |

Change wording (motto, callsign, tribute, name, theme names) → edit `config/project.json` → steps 4, 6, 7.
Add a scene → drop art in, add a `scenes[]` entry → 4, 6, 7. Rename a theme → change `folder`/`name` and set `renamed_from` to the old folder → 7.

The installer is **strict**: a theme ends with exactly its configured scenes. Anything else found in a theme's `backgrounds/` is copied to
`archive/retired-wallpapers/<folder>/` (de-duplicated by content hash) before removal. Nothing is ever deleted.

## 4. What the HUD contains
Left column on one axis (x=220): notice label → headline → subline → accent line → rank/callsign → scene readout (location + 3 kit lines)
→ corrupted packet line + barcode → pixel wordmark **ASTRAEA** + star emblem → **V O S S** → caduceus + tribute. Edge ruler, corner brackets, scanlines.
Artefacts (amounts in `glitch`): tear bands with red-channel shift (feathered away from the character), pixelated macroblocks, RGB-split wordmark with
dropped/stray cells and sliced bands, title slice, dead pixels, data streaks, neutral grain. `protect_letters` (default `T`) are never damaged.
Typography colour is set per role and per theme in `config/project.json → themes.<t>.type` (`notice, headline, subline, accent, rank, location, kit, surname, tribute`);
any role left out falls back to a default. Hierarchy: headline = theme accent (glow), subline = warm white, motto line = secondary hue, rank/readouts = soft neutrals.
Motto now: **BELIEVE IN YOURSELF** / THE ONLY THING THAT LIMITS YOU IS YOUR IMAGINATION / DON'T WORRY // TOGETHER WE CAN BUILD ANYTHING.

## 4b. HUD mode: static or animated (switchable)
**One command switches everything:** `astraea-hud static | animated | toggle | status`  (same as `src/hud-mode.sh …`).

| | static | animated |
|---|---|---|
| Wallpapers installed | text baked in (`dist/<theme>/`) | text-free base art (`dist/base/<theme>/`) |
| Extra process | none | Quickshell overlay (`overlay/`), click-through layer between wallpaper and windows |
| Cost | zero | ≈1.5 % of one core, ≈200 MB RAM |
| Extras | — | typewriter intro, cursor, ticking REC/packet line, wordmark sweep, glitch bursts every 7–16 s; follows the active wallpaper |

What a switch does: saves the mode in `config/mode`, builds anything missing, installs the matching wallpapers, stops/starts the overlay,
and re-applies your current Astraea theme (Omarchy copies a theme into its state dir when applied, so new files only show after `theme set`).
`status` shows the saved mode, what is actually installed, and whether the overlay runs.
Autostart: the last line of `~/.config/hypr/autostart.lua` runs `src/overlay.sh start` at login; it only starts the overlay when the saved mode is
`animated`, so static mode never gets a duplicate. (Original autostart file: `backups/autostart.lua.before-overlay`.)
If the overlay isn't running while wallpapers are the text-free kind, you see art with no text — run `astraea-hud status`.
Overlay files: `shell.qml` (windows, wallpaper watcher), `Hud.qml` (layout + animation, timings are `t0`/`cps` values), `TypeLine.qml`, `data.json` (generated by the builder).
Building by hand: `python3 src/build_hud.py` (static) · `python3 src/build_hud.py --base` (animated base + data.json) · `python3 src/install_to_themes.py --mode static|animated`.

## 5. Gotchas (each cost us time once)
- Omarchy's wallpaper layer is a still Qt `Image`: no GIF/video. Animation would need an extra daemon/layer (not installed, not pursued).
- `rsvg-convert` silently renders black for images in a parent folder (`../x.png`) — the builder keeps the background beside the SVG.
- ImageMagick `-geometry` persists between composites; reset to `+0+0` before the grain layer or it lands off-position (dark slabs).
- Grain must be neutral: additive `Mathematics` blend on a gray50 canvas. Overlay/SoftLight with image-derived noise changed brightness ~1.8×. Check mean brightness before/after.
- Builds are reproducible: the grain is seeded per scene (`magick -seed`). Without it every run differs and "installed vs dist" hash checks fail for no real reason.
- Hue-rotating the art turns skin/gold sickly; use a light `-colorize` wash if a tint is ever needed.
- Keep wording in JSON, not in Python strings (an apostrophe in `DON'T` broke a script). QML gotchas: property names can't start uppercase, `baseline` is a reserved Item property, and **never name a property `data` on an Item** — it is the built-in children list, so every child silently stops rendering (the HUD was invisible until renamed to `cfg`). Debug a blank overlay by checking `hyprctl layers`, then logging state with `console.log`, then bisecting with coloured test boxes at different depths; never screenshot the live desktop. Don't patch scripts with blind `str.replace` on text that also appears elsewhere.
- Bright scenes (sunset, snow, water) need a higher `shade`; dark ones a lower one.

## 6. Verify an install
`for f in dist/<theme>/scene-*.png` vs the file in `~/.config/omarchy/themes/astraea-*/backgrounds/` — `sha1sum` must match (it does after every install).

## 7. Rollback
- Theme text files: `backups/<timestamp>/<theme>/`. Old wallpapers: `archive/retired-wallpapers/<folder>/`.
- Previous theme was **Nous Research**: `omarchy theme set "Nous Research"`.
- Start clean: `rm -rf build dist`, then step 4.

## 8. Open / optional
- Everything is named Astraea now (themes, project root). The `archive/` scripts still contain the old `~/hermes-art` paths and will not run — they are history.
- Animated text overlay, and a Telegram client (nchat), are separate topics that were discussed but not built.
