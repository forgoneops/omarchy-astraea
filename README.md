# Astraea: HUD wallpapers and themes for Omarchy

A small toolchain that turns your own scene art into HUD wallpapers (System-window and Ghost-in-the-Shell style) and bundles them into four [Omarchy](https://omarchy.org) themes. The HUD can be baked into the pictures, or drawn as a live animated overlay with typewriter text, a ticking timecode and glitch bursts.

The demo character is Astraea Voss, callsign "The Last Wayfinder". The small caduceus and the line "Hermes protocol // messenger of the digital gods" nod to Hermes, the guide of travelers.

![rooftop](docs/preview/rooftop.jpg)

| | | |
|---|---|---|
| ![salt basin](docs/preview/salt-basin.jpg) | ![subway](docs/preview/subway.jpg) | ![garage](docs/preview/garage.jpg) |
| ![snow highway](docs/preview/snow-highway.jpg) | ![flooded skiff](docs/preview/flooded-skiff.jpg) | ![night rain](docs/preview/night-rain.jpg) |

The previews show the finished static wallpapers. The art is AI-generated and not included in the repo (see [art/README.md](art/README.md)). Bring your own: the builder works with any 16:9 image.

## What you get
- Per-scene HUD: headline, subline, motto line, rank and callsign, a scene readout (location plus three kit lines), a pixel-font wordmark, edge ruler, corner brackets and scanlines.
- Digital artefacts: feathered tear bands, pixelated macroblocks, an RGB-split wordmark with dropped and stray cells, a title slice, dead pixels and grain. Builds are reproducible because the randomness is seeded.
- Typography colour per role and per theme (neon headline, white subline, themed motto line), all in one JSON file.
- Four themes (Astraea Section 9, Gold, Shadow and Post Apo), two wallpapers each, created from the templates in `themes/`.
- Two HUD modes you can switch between at any time:

  | | `static` | `animated` |
  |---|---|---|
  | Text | baked into the wallpaper | drawn live by a click-through Quickshell layer |
  | Cost | none | about 1.5% of one core and 200 MB RAM |

  ```
  astraea-hud static | animated | toggle | status
  ```

## Requirements
Linux with [Omarchy](https://omarchy.org) (Hyprland and Quickshell), Python 3, ImageMagick (`magick`) and librsvg (`rsvg-convert`). Only the installer and the animated overlay need Omarchy; `src/build_hud.py` runs anywhere with Python, ImageMagick and librsvg. The fonts (Tektur and Geist Mono, SIL OFL) are bundled.

## Quick start
```bash
git clone https://github.com/forgoneops/omarchy-astraea.git ~/astraea-voss && cd ~/astraea-voss

# 1. your art: 2560x1440 images -> art/upscaled/scene-1.png ... scene-6.png   (see art/README.md)
magick my-image.png -filter Lanczos -resize 2560x1440! art/upscaled/scene-1.png

# 2. build the HUD wallpapers (about 40 s)   -> dist/<theme>/scene-N-tag.png and a contact sheet
python3 src/build_hud.py

# 3. check dist/contact-sheet.png, then install into Omarchy (creates the themes from themes/ if missing)
python3 src/install_to_themes.py --dry-run
python3 src/install_to_themes.py --apply          # installs, then switches to "Astraea Section 9"

# 4. optional: animated mode and a short command
ln -sf "$PWD/src/hud-mode.sh" ~/.local/bin/astraea-hud
astraea-hud animated
```
Cycle wallpapers with `omarchy theme bg next`. To start the overlay at login, add
`o.launch_on_start("/path/to/astraea-voss/src/overlay.sh start")` to `~/.config/hypr/autostart.lua`. It only starts when the saved mode is `animated`.

## Make it yours
Everything lives in `config/project.json`: the name, callsign and rank, every line of text (motto, tribute), per-theme and typography colours, glitch amounts, and each scene (`theme`, `tag`, `location`, `kit`, `clear_width`, `shade`, optional `image`).
After changing a word, run `python3 src/build_hud.py` and then `python3 src/install_to_themes.py`. To rename a theme, change its `folder` and `name`, and set `renamed_from` to migrate an existing one. The full pipeline, gotchas and rollback notes are in [WORKFLOW.md](WORKFLOW.md).

## Layout
```
config/    project.json (all wording, scenes, colours), bible.txt (character prompt for image generation)
src/       build_hud.py, install_to_themes.py, hud-mode.sh, overlay.sh
overlay/   Quickshell QML for the animated mode (shell.qml, Hud.qml, TypeLine.qml)
themes/    text-file templates for the four Omarchy themes
assets/    bundled fonts (OFL)
docs/      design philosophy and previews
```

## Notes
- The styling is inspired by Solo Leveling's System window, Ghost in the Shell and Hermes imagery. This project is not affiliated with or endorsed by any of them.
- The installer only touches the Astraea theme folders. Anything it removes is archived, never deleted, and theme text files are backed up before each install.
- The animated overlay is a normal Quickshell config. Stop it any time with `astraea-hud static` or `src/overlay.sh stop`.

## License
Code: MIT (see `LICENSE`). Bundled fonts: SIL OFL 1.1.
