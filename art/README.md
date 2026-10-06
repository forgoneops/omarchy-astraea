# art/

Put your scene images here. They are not included in the repo.

- `art/raw/scenes/scene-N.png`: generated art as it came out (16:9, any size)
- `art/upscaled/scene-N.png`: 2560x1440, which is what `src/build_hud.py` reads
- `art/legacy/upscaled/*.png`: optional extra images, referenced by a scene's `image` field in `config/project.json`

Upscale one image:
```
magick art/raw/scenes/scene-1.png -filter Lanczos -resize 2560x1440! -unsharp 0x1 art/upscaled/scene-1.png
```
Composition tip: keep the left half of the picture calm and dark. The HUD text sits in a single left column, and the character belongs in the right third.
