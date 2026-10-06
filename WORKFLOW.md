# Astraea Voss: wallpaper, HUD and theme workflow

Astraea Voss, callsign The Last Wayfinder, is the star-maiden and the last guide. A small caduceus and the line "HERMES PROTOCOL // MESSENGER OF THE DIGITAL GODS" on every HUD pay tribute to Hermes, messenger and guide of travelers.
Look: Hermes gold, a Solo Leveling System window, Ghost in the Shell, a post-apocalyptic survivor.

## 1. Folder map

Folders marked *local* are git-ignored: they are created by the build or hold your own files.

```
astraea-voss/                      project root (this guide assumes ~/astraea-voss)
├── WORKFLOW.md                   this file
├── config/
│   ├── project.json              all wording, scenes, theme names and colours, glitch amounts (edit here)
│   └── bible.txt                 character description for every image prompt
├── assets/fonts/                 Tektur and Geist Mono (SIL OFL), bundled
├── themes/                       text-file templates for the four Omarchy themes
├── overlay/                      Quickshell QML for the animated mode
├── art/                          local
│   ├── raw/scenes/               scene-1..6.png, generator output (1672x941 here)
│   ├── raw/concept/              concept image
│   ├── upscaled/                 scene-1..6.png at 2560x1440; the builder reads these
│   └── legacy/upscaled/          extra images referenced by a scene's `image` field
├── src/
│   ├── build_hud.py              art + config -> dist/<theme>/scene-N-tag.png (build/ holds scratch files)
│   ├── install_to_themes.py      dist -> Omarchy themes (strict, archives what it replaces)
│   ├── hud-mode.sh               static / animated switch (also the `astraea-hud` command)
│   └── overlay.sh                start/stop the overlay
├── dist/<theme>/                 local; final wallpapers grouped by theme, plus dist/contact-sheet.png. Rebuildable.
├── build/                        local; scratch, safe to delete
├── backups/<timestamp>/<theme>/  local; theme text files saved before each install
├── archive/                      local; wallpapers the installer replaced
└── docs/                         design philosophy and previews
```
Installed themes live in `~/.config/omarchy/themes/astraea-*`.

## 2. Themes and scenes

One image becomes one HUD wallpaper, in exactly one theme.

| Theme (menu name) | Folder | Scenes | HUD accent / secondary |
|---|---|---|---|
| Astraea Section 9 | `astraea-section-9` | 1 rooftop, 4 garage | gold / ice-cyan |
| Astraea Gold | `astraea-gold` | 2 salt-basin, 7 overwatch | gold / coral |
| Astraea Shadow | `astraea-shadow` | 3 subway, 5 snow-highway | violet / ice-blue |
| Astraea Post Apo | `astraea-post-apo` | 6 flooded-skiff, 8 night-rain | amber / steel-blue |

Wallpaper files inside a theme are named `NN-<folder>-<tag>.png`, in scene order. Cycle with `omarchy theme bg next`, pick with `omarchy theme bg-switcher`, switch theme with `omarchy theme set "Astraea Gold"`.

## 3. Pipeline

| # | Step | Command or action |
|---|---|---|
| 1 | Generate art (Codex, `image_generation` on) | Prompt = `config/bible.txt` plus a scene description; save to `art/raw/scenes/scene-N.png`. Example: `cd ~/astraea-voss && codex exec --skip-git-repo-check "<prompt>"`. The flags were not verified on Codex 0.159.3, so test one image first. |
| 2 | Upscale | `magick art/raw/scenes/scene-N.png -filter Lanczos -resize 2560x1440! -unsharp 0x1 art/upscaled/scene-N.png` |
| 3 | Describe the scene | In `config/project.json`, under `scenes[]`: `id`, `tag`, `theme`, `clear_width` (x where the character starts), `shade` (left darkening, 0 to 1), `location`, `kit[3]`, optional `image` and `style:"calm"` |
| 4 | Build | `python3 src/build_hud.py` (all scenes, about 40 s) or `python3 src/build_hud.py 2 5` |
| 5 | Review | Open `dist/contact-sheet.png`: legibility, overlaps, character untouched |
| 6 | Dry-run | `python3 src/install_to_themes.py --dry-run` |
| 7 | Install | `python3 src/install_to_themes.py` (add `--apply` to switch to the first theme) |
| 8 | Verify | Look at it with real windows and Waybar on top |

To change wording (motto, callsign, tribute, name, theme names), edit `config/project.json` and run steps 4, 6 and 7. To add a scene, drop the art in, add a `scenes[]` entry and run 4, 6 and 7. To rename a theme, change `folder` and `name`, set `renamed_from` to the old folder, and run step 7.

The installer is strict: a theme ends up with exactly its configured scenes. Anything else found in a theme's `backgrounds/` is copied to `archive/retired-wallpapers/<folder>/` (de-duplicated by content hash) before removal. Nothing is deleted.

## 4. What the HUD contains
The HUD is one left column on a single axis (x=220): notice label, headline, subline, accent line, rank and callsign, scene readout (location plus three kit lines), a corrupted packet line and barcode, the pixel wordmark ASTRAEA with a star emblem, "V O S S", and the caduceus with the tribute line. An edge ruler, corner brackets and scanlines frame it.

Artefacts (amounts live under `glitch`): tear bands with a red-channel shift, feathered away from the character; pixelated macroblocks; an RGB-split wordmark with dropped and stray cells and sliced bands; a title slice; dead pixels; data streaks; neutral grain. Letters listed in `protect_letters` (default `T`) are never damaged.

Typography colour is set per role and per theme in `config/project.json`, under `themes.<t>.type` (`notice`, `headline`, `subline`, `accent`, `rank`, `location`, `kit`, `surname`, `tribute`). A role left out falls back to a default. The hierarchy: headline in the theme accent with a glow, subline in warm white, motto line in the secondary hue, rank and readouts in soft neutrals.

Current motto: BELIEVE IN YOURSELF / THE ONLY THING THAT LIMITS YOU IS YOUR IMAGINATION / DON'T WORRY // TOGETHER WE CAN BUILD EVERYTHING.

## 4b. HUD mode: static or animated
One command switches everything: `astraea-hud static | animated | toggle | status` (the same as `src/hud-mode.sh ...`).

| | static | animated |
|---|---|---|
| Wallpapers installed | text baked in (`dist/<theme>/`) | text-free base art (`dist/base/<theme>/`) |
| Extra process | none | Quickshell overlay (`overlay/`), a click-through layer between wallpaper and windows |
| Cost | none | about 1.5% of one core, 200 MB RAM |
| Extras | none | typewriter intro, cursor, ticking REC and packet line, wordmark sweep, glitch bursts every 7 to 16 s; follows the active wallpaper |

A switch saves the mode in `config/mode`, builds anything missing, installs the matching wallpapers, stops or starts the overlay, and re-applies your current Astraea theme. Omarchy copies a theme into its state directory when it is applied, so new files only show after `theme set`. `status` shows the saved mode, what is actually installed, and whether the overlay is running.

Autostart: a line in `~/.config/hypr/autostart.lua` runs `src/overlay.sh start` at login. The script only starts the overlay when the saved mode is `animated`, so static mode never gets a duplicate. Keep a copy of your own autostart file before editing it.

If the wallpapers are the text-free kind and the overlay is not running, you see art with no text. Run `astraea-hud status`.

Overlay files: `shell.qml` (windows and the wallpaper watcher), `Hud.qml` (layout and animation; timings are the `t0` and `cps` values), `TypeLine.qml`, and `data.json` (generated by the builder).

Building by hand: `python3 src/build_hud.py` (static), `python3 src/build_hud.py --base` (animated base plus data.json), `python3 src/install_to_themes.py --mode static|animated`.

## 5. Gotchas
Each of these cost time once.

- Omarchy's wallpaper layer is a still Qt `Image`, so it cannot play GIF or video. Animation needs the separate overlay.
- `rsvg-convert` silently renders black for images in a parent folder (`../x.png`). The builder keeps the background next to the SVG.
- ImageMagick's `-geometry` persists between composites. Reset it to `+0+0` before the grain layer, or the layer lands off-position and leaves dark slabs.
- Grain must be neutral: an additive `Mathematics` blend on a gray50 canvas. Overlay or SoftLight with image-derived noise changed brightness by about 1.8 times. Compare mean brightness before and after.
- Builds are reproducible because the grain is seeded per scene (`magick -seed`). Without the seed every run differs, and "installed versus dist" hash checks fail for no real reason.
- Hue-rotating the art turns skin and gold sickly. Use a light `-colorize` wash if you need a tint.
- Keep wording in JSON, not in Python strings. An apostrophe in `DON'T` once broke a script.
- Don't patch scripts with a blind `str.replace` on text that also appears elsewhere in the file.
- QML: property names cannot start with an uppercase letter, and `baseline` is a reserved Item property.
- QML: never name a property `data` on an Item. It is the built-in children list, so every child silently stops rendering. The HUD was invisible until the property was renamed to `cfg`.
- To debug a blank overlay, check `hyprctl layers`, log state with `console.log`, then bisect with coloured test boxes at different depths. Avoid screenshotting a live desktop, since it can capture private windows.
- Bright scenes (sunset, snow, water) need a higher `shade`; dark ones need a lower one.

## 6. Verify an install
Compare `sha1sum` of each `dist/<theme>/scene-*.png` with the matching file in `~/.config/omarchy/themes/astraea-*/backgrounds/`. They match after every install.

## 7. Rollback
- Theme text files: `backups/<timestamp>/<theme>/`. Replaced wallpapers: `archive/retired-wallpapers/<folder>/`.
- Switch back to any earlier theme with `omarchy theme set "<theme name>"`.
- Start clean: `rm -rf build dist`, then run step 4.
