#!/usr/bin/env python3
"""Build HUD wallpapers: art/upscaled/scene-N.png  ->  build/ (intermediates)  ->  dist/ (final PNGs).

Everything configurable lives in config/project.json. Usage:
    python3 src/build_hud.py            # all scenes
    python3 src/build_hud.py 2 5        # only scenes 2 and 5
"""
import json, os, random, shutil, subprocess, sys
from html import escape

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CFG = json.load(open(f'{ROOT}/config/project.json'))
BUILD, DIST = f'{ROOT}/build', f'{ROOT}/dist'
os.makedirs(BUILD, exist_ok=True); os.makedirs(DIST, exist_ok=True)

# ---- fonts: bundled in assets/fonts so the build never depends on outside paths
FONTCONF = f'{BUILD}/fonts.conf'
open(FONTCONF, 'w').write(
    '<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd"><fontconfig>'
    '<include ignore_missing="yes">/etc/fonts/fonts.conf</include>'
    f'<dir>{ROOT}/assets/fonts</dir></fontconfig>')
ENV = {**os.environ, 'FONTCONFIG_FILE': FONTCONF}

# ---- 5x7 pixel font for the wordmark
GLYPHS = {
 'A':'01110 10001 10001 11111 10001 10001 10001', 'B':'11110 10001 10001 11110 10001 10001 11110',
 'C':'01110 10001 10000 10000 10000 10001 01110', 'D':'11110 10001 10001 10001 10001 10001 11110',
 'E':'11111 10000 10000 11110 10000 10000 11111', 'F':'11111 10000 10000 11110 10000 10000 10000',
 'G':'01111 10000 10000 10011 10001 10001 01111', 'H':'10001 10001 10001 11111 10001 10001 10001',
 'I':'01110 00100 00100 00100 00100 00100 01110', 'J':'00111 00010 00010 00010 00010 10010 01100',
 'K':'10001 10010 10100 11000 10100 10010 10001', 'L':'10000 10000 10000 10000 10000 10000 11111',
 'M':'10001 11011 10101 10101 10001 10001 10001', 'N':'10001 11001 10101 10011 10001 10001 10001',
 'O':'01110 10001 10001 10001 10001 10001 01110', 'P':'11110 10001 10001 11110 10000 10000 10000',
 'Q':'01110 10001 10001 10001 10101 10010 01101', 'R':'11110 10001 10001 11110 10100 10010 10001',
 'S':'01111 10000 10000 01110 00001 00001 11110', 'T':'11111 00100 00100 00100 00100 00100 00100',
 'U':'10001 10001 10001 10001 10001 10001 01110', 'V':'10001 10001 10001 10001 10001 01010 00100',
 'W':'10001 10001 10001 10101 10101 10101 01010', 'X':'10001 10001 01010 00100 01010 10001 10001',
 'Y':'10001 10001 01010 00100 00100 00100 00100', 'Z':'11111 00001 00010 00100 01000 10000 11111',
}

def pixels(word, x, y, c, fill, dx=0, drop=()):
    out = ''
    for i, ch in enumerate(word):
        for r, row in enumerate(GLYPHS[ch].split()):
            for k, b in enumerate(row):
                if b == '1' and (i, r, k) not in drop:
                    out += f'<rect x="{x+dx+(i*6+k)*c+1}" y="{y+r*c+1}" width="{c-2}" height="{c-2}" fill="{fill}"/>'
    return out

def star(cx, cy, s, col):   # Astraea's mark: four-point star, orbit ring, satellite
    r = 70*s
    return (f'<g stroke="{col}" fill="none" stroke-width="{2.5*s}" stroke-linecap="round">'
            f'<path d="M{cx} {cy-r}L{cx+r*.16} {cy-r*.16}L{cx+r} {cy}L{cx+r*.16} {cy+r*.16}L{cx} {cy+r}L{cx-r*.16} {cy+r*.16}L{cx-r} {cy}L{cx-r*.16} {cy-r*.16}Z" fill="{col}" fill-opacity="0.18"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r*1.22}" stroke-width="{1.5*s}" stroke-dasharray="{4*s} {9*s}" opacity="0.8"/>'
            f'<ellipse cx="{cx}" cy="{cy}" rx="{r*1.55}" ry="{r*.5}" stroke-width="{1.2*s}" opacity="0.55" transform="rotate(-24 {cx} {cy})"/>'
            f'<circle cx="{cx+r*1.35}" cy="{cy-r*.62}" r="{4*s}" fill="{col}" stroke="none"/></g>')

def caduceus(cx, cy, s, col):   # the small Hermes tribute
    p = (f'<g stroke="{col}" fill="none" stroke-width="{3*s}" stroke-linecap="round"><path d="M{cx} {cy-60*s}V{cy+70*s}"/>'
         f'<circle cx="{cx}" cy="{cy-66*s}" r="{6*s}" fill="{col}"/>')
    for g in (-1, 1):
        p += (f'<path d="M{cx} {cy-40*s}C{cx+g*30*s} {cy-70*s} {cx+g*70*s} {cy-62*s} {cx+g*86*s} {cy-80*s}'
              f'M{cx} {cy-32*s}C{cx+g*30*s} {cy-52*s} {cx+g*60*s} {cy-44*s} {cx+g*74*s} {cy-58*s}'
              f'M{cx} {cy-24*s}C{cx+g*24*s} {cy-38*s} {cx+g*48*s} {cy-30*s} {cx+g*60*s} {cy-40*s}"/>')
    return p + f'<path d="M{cx} {cy+60*s}C{cx+28*s} {cy+40*s} {cx-28*s} {cy+20*s} {cx} {cy}C{cx+28*s} {cy-20*s} {cx-28*s} {cy-35*s} {cx} {cy-45*s}"/></g>'

def corrupt(src, dst, cw, seed):
    """Digital artefacts on the wallpaper itself: tear bands + pixelated macroblocks in the left
    zone only, feathered toward the character, plus neutral additive grain (mean brightness preserved)."""
    g = CFG['glitch']; rnd = random.Random(seed*7+1)
    cmd = ['magick', '-seed', str(seed*1009+7), src]      # seeded: ImageMagick's grain is otherwise different every run
    for _ in range(g['tear_bands']):
        y = rnd.randrange(500, 1250, 2); h = rnd.choice([10, 14, 18, 22]); dx = rnd.choice([-1, 1])*rnd.randrange(30, 64); cr = rnd.randrange(4, 8)
        cmd += ['(', '+clone', '-crop', f'{cw}x{h}+0+{y}', '+repage', '-roll', f'{dx:+d}+0',
                '(', '+clone', '-channel', 'R', '-roll', f'+{cr}+0', '+channel', ')', '-compose', 'Screen', '-composite',
                '(', '-size', f'{cw}x{h}', 'xc:white', '-fx', f'i<{int(cw*.5)}?1:max(0,({cw}-i)/{int(cw*.5)})', ')',
                '-alpha', 'off', '-compose', 'CopyOpacity', '-composite', ')',
                '-geometry', f'+0+{y}', '-compose', 'Over', '-composite']
    for _ in range(g['macroblocks']):
        w = rnd.choice([64, 96, 128]); h = rnd.choice([32, 48, 64]); x = rnd.randrange(260, max(300, cw-300)); y = rnd.randrange(430, 1100)
        cmd += ['(', '+clone', '-crop', f'{w}x{h}+{x}+{y}', '+repage', '-scale', '12%', '-scale', '833%', '-modulate', '105,120,100', ')',
                '-geometry', f'+{x+rnd.choice([-24, 24])}+{y}', '-compose', 'Over', '-composite']
    # NB: reset -geometry before the grain, or the last macroblock offset shifts it (caused dark slabs once)
    cmd += ['-geometry', '+0+0', '-gravity', 'NorthWest',
            '(', '-size', '2560x1440', 'xc:gray50', '-attenuate', '0.35', '+noise', 'Gaussian', ')',
            '-compose', 'Mathematics', '-define', 'compose:args=0,0.10,1,-0.05', '-composite']
    subprocess.run(cmd + [dst], check=True)

BASE = '--base' in sys.argv          # text-free base art for the animated overlay

def build_scene(sc):
    n = sc['id']; th = CFG['themes'][sc['theme']]; ch = CFG['character']; tx = CFG['text']
    G, C, G1, G2 = th['accent'], th['secondary'], th['grad_hi'], th['grad_lo']
    # typography colour per role (config themes.<t>.type overrides these defaults)
    K = {'notice': C, 'headline': G, 'subline': '#F1ECE0', 'accent': C, 'rank': '#E8EEF4', 'location': G,
         'kit': C, 'surname': C, 'tribute': '#E8EEF4', **th.get('type', {})}
    rnd = random.Random(n*13); cw = sc['clear_width']; shade = sc['shade']
    word = ch['name'].upper(); missing = [l for l in word if l not in GLYPHS]
    if missing: sys.exit(f'wordmark has unsupported letters: {missing}')
    bg = f'{BUILD}/scene-{n}-corrupted.png'
    src = f'{ROOT}/art/' + sc.get('image', f'upscaled/scene-{n}.png')
    calm = sc.get('style') == 'calm'          # calm = same HUD, no digital artefacts
    if calm: shutil.copy(src, bg)
    else: corrupt(src, bg, min(cw, 1500), n)

    cells = 6*len(word)-1; c = max(10, min(22, round(740/cells))); W = cells*c; X, Y = 220, 1020
    on = [(i, r, k) for i, l in enumerate(word) for r, row in enumerate(GLYPHS[l].split()) for k, b in enumerate(row) if b == '1']
    prot = {i for i, l in enumerate(word) if l in CFG['glitch']['protect_letters']}     # thin-stem letters stay intact
    safe = [o for o in on if o[0] not in prot]
    drop = set() if calm else set(rnd.sample(safe, CFG['glitch']['dropped_cells']))
    stray = [] if calm else rnd.sample(safe, CFG['glitch']['stray_cells'])
    ff = 'font-family="Geist Mono"'; tf = 'font-family="Tektur" font-weight="500" font-size="60"'
    E = escape

    s = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2560 1440" width="2560" height="1440"><defs>
<linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{G1}"/><stop offset="1" stop-color="{G2}"/></linearGradient>
<linearGradient id="f" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#02060d" stop-opacity="{shade}"/><stop offset="0.6" stop-color="#02060d" stop-opacity="{shade*.55:.2f}"/><stop offset="1" stop-color="#02060d" stop-opacity="0"/></linearGradient>
<radialGradient id="b" cx="520" cy="1440" r="1100" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#02060d" stop-opacity="{min(.9, shade+.06):.2f}"/><stop offset="1" stop-color="#02060d" stop-opacity="0"/></radialGradient>
<pattern id="sc" width="4" height="4" patternUnits="userSpaceOnUse"><rect width="4" height="1" fill="#000" opacity="0.2"/></pattern>
<filter id="gl" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="3" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>'''
    bands = [] if calm else [(1050, 1060, 22), (1112, 1122, -18)]
    for i, (a, b, _) in enumerate(bands): s += f'<clipPath id="wb{i}"><rect x="60" y="{a}" width="1200" height="{b-a}"/></clipPath>'
    s += '<clipPath id="tb"><rect x="200" y="252" width="900" height="8"/></clipPath></defs>'
    s += (f'<image href="{os.path.basename(bg)}" width="2560" height="1440"/><rect width="{cw+300}" height="1440" fill="url(#f)"/>'
          f'<rect width="2560" height="1440" fill="url(#b)"/><rect width="{cw+200}" height="1440" fill="url(#sc)"/>')
    if BASE:      # art + shade + scanlines + tear artefacts only; the overlay draws every piece of text
        os.makedirs(f'{DIST}/base/{sc["theme"]}', exist_ok=True)
        out = f'{DIST}/base/{sc["theme"]}/scene-{n}-{sc["tag"]}.png'; svg = f'{BUILD}/scene-{n}-base.svg'
        open(svg, 'w').write(s + '</svg>'); subprocess.run(['rsvg-convert', svg, '-o', out], check=True, env=ENV); return out
    s += f'<g stroke="{G}" stroke-width="3" fill="none"><path d="M60 130V60H130M2500 130V60H2430M60 1310V1380H130M2500 1310V1380H2430"/></g>'
    s += f'<g stroke="{C}" fill="{C}" {ff} font-size="14"><path d="M96 150V1290" stroke-width="1.2" opacity="0.55"/>'     # ruler
    for i in range(29):
        y = 150+i*40; m = (i % 5 == 0)
        s += f'<path d="M96 {y}h{18 if m else 8}" stroke-width="{1.4 if m else 1}" opacity="{0.8 if m else 0.4}"/>' + (f'<text x="124" y="{y+5}" stroke="none" opacity="0.55">{i*40:03d}</text>' if m else '')
    s += '</g>'
    s += f'<g {ff}><text x="220" y="172" font-size="20" letter-spacing="6" fill="{K['notice']}" opacity="0.9">{E(tx["notice"])}</text><path d="M220 198H1010" stroke="{G}" stroke-width="1.5"/></g>'
    def head(fh, fs):      # headline + subline, each in its own colour
        return (f'<text x="220" y="282" letter-spacing="3" fill="{fh}">{E(tx["headline"])}</text>'
                f'<text x="220" y="342" font-size="29" letter-spacing="2" fill="{fs}">{E(tx["subline"])}</text>')
    s += (f'<g {tf} opacity="0.5" transform="translate(-4 0)">{head(C, C)}</g><g {tf} filter="url(#gl)">{head(K["headline"], K["subline"])}</g>'
          + (f'<g clip-path="url(#tb)" {tf} transform="translate(16 0)">{head(C, C)}</g>' if not calm else ''))
    s += (f'<text x="220" y="392" {ff} font-size="22" letter-spacing="3" fill="{K['accent']}" filter="url(#gl)">{E(tx["accent"])}</text>'
          f'<text x="220" y="438" {ff} font-size="20" letter-spacing="4" fill="{K['rank']}" opacity="0.9">'
          f'{E("RANK " + ch["rank"] + "  /  CALLSIGN: " + ch["callsign"] + "  /  ONLINE")}</text>')
    s += f'<g {ff} font-size="20" fill="{K['kit']}" opacity="0.95"><text x="220" y="498" fill="{K['location']}">&gt; {E(sc["location"])}</text>'
    for i, l in enumerate(sc['kit']): s += f'<text x="220" y="{534+i*30}">&gt; {E(l)}</text>'
    s += '</g>'
    loss = rnd.randrange(7, 19)
    s += (f'<g {ff} font-size="16" letter-spacing="2" fill="{C}" opacity="0.8"><text x="220" y="656">ERR 0x{rnd.randrange(4096, 65535):04X}  /  PACKET LOSS {loss}%  /  RESYNC</text>'
          f'<text x="226" y="656" fill="{G}" opacity="0.35">ERR 0x{rnd.randrange(4096, 65535):04X}  /  PACKET LOSS {loss}%  /  RESYNC</text></g>')
    bx = 220; bar = ''
    for k in range(46):
        w = rnd.choice([2, 2, 3, 5]); bar += f'<rect x="{bx}" y="686" width="{w}" height="26"/>'; bx += w+rnd.choice([2, 3, 4])
    s += f'<g fill="{C}" opacity="0.55">{bar}</g>'
    for (x, y) in [(900, 176), (1000, 700), (150, 1000)]:
        s += f'<g stroke="{G}" stroke-width="1.5" opacity="0.7"><path d="M{x-10} {y}h20M{x} {y-10}v20"/><circle cx="{x}" cy="{y}" r="5" fill="none"/></g>'
    s += f'<text x="1010" y="226" text-anchor="end" {ff} font-size="16" letter-spacing="3" fill="{G}" opacity="0.85">REC  04:{rnd.randrange(10, 59)}:{rnd.randrange(10, 59)}:{rnd.randrange(10, 29)}</text>'
    for _ in range(0 if calm else 26):   # dead pixels in the dark zone, never over the type
        x = rnd.randrange(130, cw); y = rnd.randrange(130, 1300); sz = rnd.choice([4, 4, 6, 8, 12])
        if 200 < x < 1180 and (230 < y < 720 or 1000 < y < 1260): continue
        s += f'<rect x="{x}" y="{y}" width="{sz}" height="{sz}" fill="{rnd.choice([C, G])}" opacity="{rnd.choice([.35, .5, .7])}"/>'
    for _ in range(0 if calm else 6):    # data streaks
        y = rnd.randrange(430, 1300, 2); x = rnd.randrange(100, cw-400); w = rnd.randrange(60, 260)
        s += f'<rect x="{x}" y="{y}" width="{w}" height="{rnd.choice([2, 3, 5])}" fill="{rnd.choice([C, G])}" opacity="0.4"/>'
    s += f'<g>{pixels(word, X, Y, c, C, -6)}</g><g opacity="0.45">{pixels(word, X, Y, c, G, 6)}</g><g>{pixels(word, X, Y, c, "url(#g)", 0, drop)}</g>'
    for (i, r, k) in stray:
        dx = rnd.choice([-3, -2, 2, 3])*c
        s += f'<rect x="{X+dx+(i*6+k)*c+1}" y="{Y+r*c+1}" width="{c-2}" height="{c-2}" fill="{rnd.choice([C, G])}" opacity="0.8"/>'
    for i, (a, b, dx) in enumerate(bands): s += f'<g clip-path="url(#wb{i})" opacity="0.9">{pixels(word, X, Y, c, C if dx > 0 else G, dx)}</g>'
    s += (f'<path d="M220 {Y+176}H{220+W}" stroke="{G}" stroke-width="1.5"/>'
          f'<text x="220" y="{Y+220}" {ff} font-size="22" letter-spacing="22" fill="{K['surname']}">{E(" ".join(ch["surname"].upper()))}</text>'
          f'<text x="262" y="{Y+256}" {ff} font-size="15" letter-spacing="2" fill="{K['tribute']}" opacity="0.9">{E(tx["tribute"])}</text>'
          + star(220+W+120, 1110, 0.85, G) + caduceus(234, Y+248, 0.2, G))     # tribute sits on its own line under VOSS
    svg = f'{BUILD}/scene-{n}.svg'; open(svg, 'w').write(s+'</svg>')
    os.makedirs(f'{DIST}/{sc["theme"]}', exist_ok=True)
    out = f'{DIST}/{sc["theme"]}/scene-{n}-{sc["tag"]}.png'      # dist/<theme>/scene-N-tag.png
    subprocess.run(['rsvg-convert', svg, '-o', out], check=True, env=ENV)
    return out

def write_overlay_data():
    """overlay/data.json: everything the animated overlay needs (text, colours, per-scene readouts, pixel glyph cells)."""
    word = CFG['character']['name'].upper()
    cells = [[i*6+k, r] for i, l in enumerate(word) for r, row in enumerate(GLYPHS[l].split()) for k, b in enumerate(row) if b == '1']
    themes = {}
    for key, th in CFG['themes'].items():
        G, C = th['accent'], th['secondary']
        K = {'notice': C, 'headline': G, 'subline': '#F1ECE0', 'accent': C, 'rank': '#E8EEF4', 'location': G,
             'kit': C, 'surname': C, 'tribute': '#E8EEF4', **th.get('type', {})}
        themes[key] = {'folder': th['folder'], 'accent': G, 'secondary': C, 'grad_hi': th['grad_hi'], 'grad_lo': th['grad_lo'], 'type': K}
    scenes = {f'{CFG["themes"][s["theme"]]["folder"]}-{s["tag"]}': {'theme': s['theme'], 'location': s['location'], 'kit': s['kit']} for s in CFG['scenes']}
    os.makedirs(f'{ROOT}/overlay', exist_ok=True)
    json.dump({'design': {'w': 2560, 'h': 1440}, 'character': CFG['character'], 'text': CFG['text'], 'cells': cells,
               'cellCount': 6*len(word)-1, 'themes': themes, 'scenes': scenes}, open(f'{ROOT}/overlay/data.json', 'w'), indent=1)

if __name__ == '__main__':
    want = {int(a) for a in sys.argv[1:] if a.isdigit()}
    outs = [build_scene(sc) for sc in CFG['scenes'] if not want or sc['id'] in want]
    write_overlay_data()
    if BASE: print('built', len(outs), 'base wallpapers ->', DIST + '/base'); sys.exit(0)
    sheet = f'{DIST}/contact-sheet.png'
    subprocess.run(['magick', 'montage', *outs, '-tile', '2x3' if len(outs) <= 6 else '4x',  '-geometry', '960x540+4+4', '-background', 'black', sheet], check=True)
    print('built', len(outs), 'HUD wallpapers ->', DIST); print('contact sheet:', sheet)
