#!/usr/bin/env python3
"""Install dist/<theme>/*.png into the Omarchy themes (STRICT: a theme ends up with exactly its configured scenes).

    python3 src/install_to_themes.py --dry-run
    python3 src/install_to_themes.py                      # install
    python3 src/install_to_themes.py --apply              # install, then switch to the first theme in the config

What it does per theme: renames the old theme folder if config says `renamed_from`; backs up the theme's text files;
archives every wallpaper that is not part of the new set (deduplicated by content, nothing is deleted);
installs NN-<folder>-<tag>.png in scene order; rewrites README + the colors.toml header; refreshes preview.png.
"""
import hashlib, json, os, re, shutil, subprocess, sys, time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CFG = json.load(open(f'{ROOT}/config/project.json'))
THEMES = os.environ.get('ASTRAEA_THEMES_DIR') or os.path.expanduser('~/.config/omarchy/themes')     # env override is for testing
dry = '--dry-run' in sys.argv
MODE = sys.argv[sys.argv.index('--mode')+1] if '--mode' in sys.argv else 'static'     # static = text baked in | animated = text-free base + overlay
assert MODE in ('static', 'animated'), 'mode must be static or animated'
SRC_DIR = 'dist/base' if MODE == 'animated' else 'dist'
STAMP = time.strftime('%Y%m%d-%H%M%S')
first_name = None

def sha(path):
    return hashlib.sha1(open(path, 'rb').read()).hexdigest()[:8]

for key, th in CFG['themes'].items():
    folder, name, old = th['folder'], th['name'], th.get('renamed_from')
    scenes = sorted((s for s in CFG['scenes'] if s['theme'] == key), key=lambda s: s['id'])
    if not scenes: continue
    tdir, odir = f'{THEMES}/{folder}', f'{THEMES}/{old}' if old else None
    print(f'\n{name}  ({folder})')
    template = f'{ROOT}/themes/{folder}'            # text-file template shipped in the repo (colours, terminal/bar configs)
    if not os.path.isdir(tdir):
        if odir and os.path.isdir(odir): print(f'  rename folder: {old} -> {folder}')
        elif os.path.isdir(template): print(f'  create theme from template: themes/{folder}')
        else: print('  !! theme folder missing, no old folder and no template - skipped'); continue
    first_name = first_name or name
    srcs = []
    for s in scenes:
        src = f'{ROOT}/{SRC_DIR}/{key}/scene-{s["id"]}-{s["tag"]}.png'
        if not os.path.exists(src): sys.exit(f'missing {src} - run: python3 src/build_hud.py' + (' --base' if MODE == 'animated' else ''))
        srcs.append((src, f'{len(srcs)+1:02d}-{folder}-{s["tag"]}.png'))
    cur = f'{tdir if os.path.isdir(tdir) else (odir if odir and os.path.isdir(odir) else template)}/backgrounds'
    existing = sorted(os.listdir(cur)) if os.path.isdir(cur) else []
    for _, n in srcs: print(f'  install  {n}')
    for f in existing: print(f'  archive  {f}')
    if dry: continue
    if not os.path.isdir(tdir):
        if odir and os.path.isdir(odir): os.rename(odir, tdir)
        else: shutil.copytree(template, tdir, ignore=shutil.ignore_patterns('backgrounds'))
    os.makedirs(f'{tdir}/backgrounds', exist_ok=True)
    # backup text files, archive old wallpapers (dedup by content hash)
    bk = f'{ROOT}/backups/{STAMP}/{folder}'; os.makedirs(bk, exist_ok=True)
    for f in os.listdir(tdir):
        if os.path.isfile(f'{tdir}/{f}'): shutil.copy2(f'{tdir}/{f}', bk)
    ra = f'{ROOT}/archive/retired-wallpapers/{folder}'; os.makedirs(ra, exist_ok=True)
    have = {f.split('-', 1)[0] for f in os.listdir(ra)}
    bgdir = f'{tdir}/backgrounds'
    replaced = {n for _, n in srcs}
    for f in existing:
        if f in replaced: continue            # same scene rebuilt in place: not worth archiving
        h = sha(f'{bgdir}/{f}')
        if h not in have: shutil.copy2(f'{bgdir}/{f}', f'{ra}/{h}-{f}'); have.add(h)
    shutil.rmtree(bgdir); os.makedirs(bgdir)
    for src, n in srcs: shutil.copy2(src, f'{bgdir}/{n}')
    subprocess.run(['magick', srcs[0][0], '-resize', '1280x720', f'{tdir}/preview.png'], check=True)
    # naming inside the theme
    ct = open(f'{tdir}/colors.toml').read()
    ct = re.sub(r'\A# .*\n', f'# {name.upper()} - Astraea Voss, The Last Wayfinder\n', ct)
    open(f'{tdir}/colors.toml', 'w').write(ct)
    open(f'{tdir}/README.md', 'w').write(
        f'# {name} - Omarchy Theme\n\nFeaturing **Astraea Voss**, callsign *The Last Wayfinder*.\n\n'
        f'Wallpapers ({len(srcs)}): ' + ', '.join(s['tag'] for s in scenes) + '.\n'
        f'Built by {ROOT.replace(os.path.expanduser("~"), "~")} (see WORKFLOW.md). Cycle with `omarchy theme bg next`.\n')

print(f'\nmode: {MODE}')
print('(dry run - nothing changed)' if dry else 'installed.')
if '--apply' in sys.argv and not dry and first_name:
    subprocess.run(['omarchy', 'theme', 'set', first_name], check=True)
