"""Builds the store graphics from store/raw/*.png with headless Chrome.

    python3 store/make.py            # ink theme (default)
    python3 store/make.py paper      # light theme

Writes store/out/{appstore,play}/NN_name.png, the Play feature graphic, the
512 px Play icon and store/overview.png.

Every slide uses the same grid: headline on top, an upright iPhone below that
runs off the bottom edge, and at most one real card lifted out of the screen
at exactly the place it sits in the app.
"""

import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(ROOT, 'raw')
OUT = os.path.join(ROOT, 'out')
TMP = os.path.join(ROOT, 'build')
APP = os.path.dirname(ROOT)
FONTS = os.path.join(APP, 'assets', 'fonts')
ICON = os.path.join(APP, 'ios/Runner/Assets.xcassets/AppIcon.appiconset/1024.png')
CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'

INK = '#15142B'
LIME = '#D6F84C'
RAW_W, RAW_H = 1206, 2622

THEMES = {
    'ink': dict(top='#23214A', bottom='#0C0B1C', text='#FFFFFF', accent=LIME,
                marker=False, halo='rgba(112,100,255,0.24)', grain=0.55,
                muted='#A7A5C6', lift='rgba(5,4,18,0.50)'),
    'paper': dict(top='#FBF9F3', bottom='#E9E5D9', text=INK, accent=INK,
                  marker=True, halo='rgba(214,248,76,0.28)', grain=0.35,
                  muted='#6B6980', lift='rgba(21,20,43,0.30)'),
}

# W, H, headline px, headline top, phone width (share of W), phone top
SIZES = {
    'appstore': (1290, 2796, 124, 236, 0.82, 720),
    # iPhone 6.1"/6.3" slot (medium display), same layout scaled down.
    'appstore-6.3': (1206, 2622, 116, 221, 0.82, 673),
    'play': (1080, 1920, 96, 150, 0.74, 470),
}

# Cards lifted out of the screenshots, in raw pixels. Boxes sit 8 px inside
# the card edge, so clipping with CARD_R (card radius 78 - 8) never shows the
# screen background in the corners.
CARD_R = 70
CARDS = {
    'today_next': ('01_today', (73, 492, 1133, 1296)),
    'protein': ('04_protein', (73, 410, 1133, 1279)),
    'progress': ('06_progress', (73, 652, 1133, 1762)),
    'feeling': ('07_checkin', (73, 740, 1133, 1299)),
    'sites': ('03_sites', (73, 1640, 1133, 2220)),
    'report': ('08_report', (60, 395, 1146, 1010)),
}

# dy moves a lifted card, in screenshot pixels (so App Store and Play match).
SLIDES = [
    dict(name='hero', raw='01_today', brand=True,
         title='Your <em>calm</em><br>GLP-1 companion', card='today_next', dy=60, edge=True),
    dict(name='meds', chips=True, title='Works with<br><em>any GLP-1</em>'),
    dict(name='sites', raw='03_sites', title='Never guess your<br><em>injection spot</em>',
         card='sites', dy=-60),
    dict(name='protein', raw='04_protein', title='Protect<br>your <em>muscle</em>',
         card='protein', dy=30),
    dict(name='progress', raw='06_progress', title='See what each<br><em>dose</em> does',
         card='progress', k=1.2, dy=30),
    dict(name='remind', raw='05_doses', title='Reminders that<br><em>feel kind</em>',
         banner=True),
    dict(name='checkin', raw='07_checkin', title='Track how you<br><em>really feel</em>',
         card='feeling'),
    dict(name='report', raw='08_report', title='A <em>clean report</em><br>for your doctor',
         card='report', radius=14, k=1.24, dy=40),
]

MEDS = ['Mounjaro', 'Zepbound', 'Ozempic', 'Wegovy', 'Rybelsus', 'Saxenda',
        'Trulicity']


# ------------------------------------------------------------------- page

def css(W, t):
    s = W / 1290
    em = (f"""background:linear-gradient(180deg,transparent 50%,{LIME} 50%,{LIME} 86%,
          transparent 86%);padding:0 .08em;margin:0 -.04em;border-radius:.08em;"""
          if t['marker'] else f'color:{t["accent"]};')
    return f"""
@font-face {{ font-family:Brico; font-weight:800;
  src:url('file://{FONTS}/BricolageGrotesque-ExtraBold.ttf'); }}
@font-face {{ font-family:Fig; font-weight:600; src:url('file://{FONTS}/Figtree-SemiBold.ttf'); }}
@font-face {{ font-family:Fig; font-weight:700; src:url('file://{FONTS}/Figtree-Bold.ttf'); }}
@font-face {{ font-family:Fig; font-weight:800; src:url('file://{FONTS}/Figtree-ExtraBold.ttf'); }}
* {{ margin:0; padding:0; box-sizing:border-box; }}
html, body {{ overflow:hidden; }}
body {{ position:relative; font-family:Fig; -webkit-font-smoothing:antialiased; }}
.abs {{ position:absolute; }}
h1 {{ position:absolute; left:4%; right:4%; text-align:center; font-family:Brico;
  font-weight:800; line-height:1.0; letter-spacing:-.028em; color:{t['text']}; z-index:5; }}
h1 em {{ font-style:normal; {em} }}
.device {{ position:absolute; z-index:2;
  background:linear-gradient(135deg,#9A989F 0%,#45444B 9%,#232227 32%,#1A191E 55%,
    #2B2A30 80%,#77757C 100%);
  box-shadow:0 {50*s:.0f}px {110*s:.0f}px rgba(0,0,0,.42), 0 {14*s:.0f}px {30*s:.0f}px rgba(0,0,0,.30),
    inset 0 0 0 {1.2*s:.1f}px rgba(255,255,255,.28); }}
.bezel {{ width:100%; height:100%; background:#030305;
  box-shadow:inset 0 0 0 {1.5*s:.1f}px rgba(0,0,0,.9); }}
.screen {{ width:100%; height:100%; overflow:hidden; background:#F6F5F1; }}
.screen img {{ display:block; width:100%; }}
.btn {{ position:absolute; border-radius:{3*s:.1f}px;
  background:linear-gradient(90deg,#2A292E,#6C6B71 45%,#2A292E); }}
.lift {{ position:absolute; z-index:4; background-repeat:no-repeat;
  box-shadow:0 {6*s:.0f}px {14*s:.0f}px rgba(0,0,0,.10), 0 {38*s:.0f}px {80*s:.0f}px {t['lift']}; }}
sup {{ font-size:.5em; vertical-align:.85em; margin-left:.06em; font-weight:700; }}
"""


def background(W, H, t, halo_y):
    noise = (f'<svg class="abs" style="left:0;top:0;z-index:1;opacity:{t["grain"]};'
             f'mix-blend-mode:soft-light" width="{W}" height="{H}">'
             f'<filter id="n"><feTurbulence type="fractalNoise" baseFrequency="0.9" '
             f'numOctaves="3" stitchTiles="stitch"/><feColorMatrix type="saturate" values="0"/>'
             f'</filter><rect width="100%" height="100%" filter="url(#n)"/></svg>')
    return (f'<div class="abs" style="left:0;top:0;width:{W}px;height:{H}px;z-index:0;'
            f'background:radial-gradient(ellipse {W*0.95:.0f}px {H*0.42:.0f}px at 50% {halo_y:.0f}px,'
            f'{t["halo"]},transparent 70%),linear-gradient(180deg,{t["top"]},{t["bottom"]})"></div>'
            + noise)


def device(raw, x, top, w):
    """Upright iPhone 17 Pro. Returns html and where the screen is drawn."""
    rim = w * 0.012
    bez = w * 0.020
    b = rim + bez
    sw = w - 2 * b
    sh = sw * RAW_H / RAW_W
    h = sh + 2 * b
    rs = sw * 0.137
    rb = rs + bez
    ro = rb + rim
    bw = max(3.0, w * 0.0065)

    def btn(side, at, length):
        pos = f'left:{-bw + 1:.1f}px' if side == 'l' else f'right:{-bw + 1:.1f}px'
        return (f'<div class="btn" style="{pos};top:{at * h:.0f}px;width:{bw:.1f}px;'
                f'height:{length * h:.0f}px"></div>')

    html = (f'<div class="device" style="left:{x:.0f}px;top:{top:.0f}px;width:{w:.0f}px;'
            f'height:{h:.0f}px;border-radius:{ro:.0f}px;padding:{rim:.1f}px">'
            + btn('l', .170, .030) + btn('l', .228, .060) + btn('l', .300, .060)
            + btn('r', .250, .092)
            + f'<div class="bezel" style="border-radius:{rb:.0f}px;padding:{bez:.1f}px">'
            f'<div class="screen" style="border-radius:{rs:.0f}px">'
            f'<img src="file://{RAW}/{raw}.png"></div></div></div>')
    return html, dict(x=x + b, y=top + b, w=sw, scale=sw / RAW_W, h=h)


def lift(card, scr, k=1.26, dy=0.0, radius=CARD_R, edge=False):
    """A card from the screenshot, k times larger, centred on where it is in the
    phone (moved dy screenshot pixels)."""
    raw, (x0, y0, x1, y1) = CARDS[card]
    s = scr['scale'] * k
    w, h = (x1 - x0) * s, (y1 - y0) * s
    cx = scr['x'] + (x0 + x1) / 2 * scr['scale']
    cy = scr['y'] + ((y0 + y1) / 2 + dy) * scr['scale']
    ring = (f'box-shadow:inset 0 0 0 {1.6 * k * scr["scale"] / 0.82:.1f}px rgba(255,255,255,.16),'
            f'0 {6 * k:.0f}px {14 * k:.0f}px rgba(0,0,0,.10),'
            f'0 {38 * k:.0f}px {80 * k:.0f}px rgba(5,4,18,.5);' if edge else '')
    return (f'<div class="lift" style="left:{cx - w / 2:.0f}px;top:{cy - h / 2:.0f}px;'
            f'width:{w:.0f}px;height:{h:.0f}px;border-radius:{radius * s:.0f}px;'
            f'background-image:url(file://{RAW}/{raw}.png);'
            f'background-size:{RAW_W * s:.1f}px {RAW_H * s:.1f}px;'
            f'background-position:{-x0 * s:.1f}px {-y0 * s:.1f}px;{ring}"></div>')


def brand(top, s, t):
    return (f'<div class="abs" style="left:0;right:0;top:{top:.0f}px;display:flex;'
            f'justify-content:center;align-items:center;gap:{20 * s:.0f}px;z-index:5">'
            f'<img src="file://{ICON}" style="width:{88 * s:.0f}px;height:{88 * s:.0f}px;'
            f'border-radius:{21 * s:.0f}px;box-shadow:0 {8*s:.0f}px {20*s:.0f}px rgba(0,0,0,.25)">'
            f'<span style="font-family:Brico;font-weight:800;font-size:{62 * s:.0f}px;'
            f'letter-spacing:-.02em;color:{t["text"]}">Kindose</span></div>')


def banner(W, top, s):
    """iOS notification with the app's real dose-day wording."""
    w = W * 0.88
    ic = 104 * s
    return (f'<div class="abs" style="left:{(W - w) / 2:.0f}px;top:{top:.0f}px;width:{w:.0f}px;'
            f'z-index:6;display:flex;align-items:center;gap:{26 * s:.0f}px;'
            f'padding:{30 * s:.0f}px {34 * s:.0f}px;border-radius:{56 * s:.0f}px;'
            f'background:rgba(248,248,250,.96);color:#111;'
            f'box-shadow:0 {8*s:.0f}px {18*s:.0f}px rgba(0,0,0,.12),'
            f'0 {40*s:.0f}px {90*s:.0f}px rgba(5,4,18,.45)">'
            f'<img src="file://{ICON}" style="width:{ic:.0f}px;height:{ic:.0f}px;'
            f'border-radius:{ic * 0.225:.0f}px;flex:none">'
            f'<div style="flex:1;min-width:0">'
            f'<div style="display:flex;justify-content:space-between;align-items:baseline">'
            f'<span style="font-weight:800;font-size:{40 * s:.0f}px;letter-spacing:-.01em">'
            f'It’s dose day</span>'
            f'<span style="font-weight:600;font-size:{31 * s:.0f}px;color:#8A8A8F">now</span></div>'
            f'<div style="font-weight:600;font-size:{35 * s:.0f}px;line-height:1.3;color:#3A3A3F;'
            f'margin-top:{4 * s:.0f}px">Tap to log it when you’re done. Lower right belly is next.'
            f'</div></div></div>')


def chips(H, top, s, t):
    """The medicines list, as selection pills like the app's own."""
    items = [f'{m}<sup>®</sup>' for m in MEDS] + ['Compounded']
    n = len(items)
    hgt = 158 * s
    room = H - top - 230 * s
    gap = max(34 * s, min(84 * s, (room - n * hgt) / (n - 1)))
    check = (f'<svg viewBox="0 0 24 24" width="{50 * s:.0f}" height="{50 * s:.0f}">'
             f'<path d="M5 12.5l4.2 4.2L19 7" fill="none" stroke="{INK}" stroke-width="3" '
             f'stroke-linecap="round" stroke-linejoin="round"/></svg>')
    rows = []
    for i, label in enumerate(items):
        off = (-1 if i % 2 == 0 else 1) * 84 * s
        rows.append(
            f'<div style="display:flex;justify-content:center;transform:translateX({off:.0f}px)">'
            f'<div style="display:flex;align-items:center;gap:{28 * s:.0f}px;height:{hgt:.0f}px;'
            f'padding:0 {58 * s:.0f}px 0 {26 * s:.0f}px;border-radius:{hgt / 2:.0f}px;'
            f'background:#FFFFFF;color:{INK};font-weight:800;font-size:{62 * s:.0f}px;'
            f'letter-spacing:-.012em;box-shadow:0 {6*s:.0f}px {14*s:.0f}px rgba(0,0,0,.08),'
            f'0 {28*s:.0f}px {64*s:.0f}px {t["lift"]}">'
            f'<span style="width:{106 * s:.0f}px;height:{106 * s:.0f}px;border-radius:50%;'
            f'background:{LIME};display:flex;align-items:center;justify-content:center;'
            f'flex:none">{check}</span><span>{label}</span></div></div>')
    return (f'<div class="abs" style="left:0;right:0;top:{top:.0f}px;display:flex;'
            f'flex-direction:column;gap:{gap:.0f}px;z-index:5">{"".join(rows)}'
            f'<div style="text-align:center;margin-top:{34 * s:.0f}px;font-weight:700;'
            f'font-size:{48 * s:.0f}px;color:{t["muted"]}">Pens, vials and tablets</div></div>')


def slide(sl, W, H, t):
    _, _, hsize, htop, pw_share, ptop = next(v for v in SIZES.values() if v[0] == W)
    s = W / 1290
    out = []
    if sl.get('brand'):
        out.append(brand(htop - 104 * s, s, t))
        htop += 64 * s
    if sl.get('banner'):
        out.append(banner(W, htop - 116 * s, s))
        htop += 150 * s
        ptop = htop + 2 * hsize + 110 * s
    out.append(f'<h1 style="top:{htop:.0f}px;font-size:{hsize:.0f}px">{sl["title"]}</h1>')
    pw = W * pw_share
    halo_y = ptop + 500 * s
    if sl.get('chips'):
        out.append(chips(H, htop + 2 * hsize + 150 * s, s, t))
        halo_y = H * 0.55
    else:
        dev, scr = device(sl['raw'], (W - pw) / 2, ptop, pw)
        out.append(dev)
        if sl.get('card'):
            out.append(lift(sl['card'], scr, sl.get('k', 1.26), sl.get('dy', 0),
                            sl.get('radius', CARD_R), sl.get('edge', False)))
    return background(W, H, t, halo_y) + ''.join(out)


def feature(t):
    W, H = 1024, 500
    dev, scr = device('01_today', 610, 64, 320)
    body = (background(W, H, t, 250)
            + f'<div class="abs" style="left:66px;top:0;bottom:0;width:480px;display:flex;'
              f'flex-direction:column;justify-content:center;z-index:5">'
              f'<div style="display:flex;align-items:center;gap:16px">'
              f'<img src="file://{ICON}" style="width:68px;height:68px;border-radius:16px">'
              f'<span style="font-family:Brico;font-weight:800;font-size:50px;'
              f'letter-spacing:-.02em;color:{t["text"]}">Kindose</span></div>'
              f'<h1 style="position:static;text-align:left;font-size:58px;margin-top:26px">'
              f'Your <em>calm</em><br>GLP-1 companion</h1>'
              f'<div style="font-weight:600;font-size:22px;line-height:1.4;margin-top:18px;'
              f'color:{t["muted"]}">Doses, injection sites, protein<br>and progress in one place.'
              f'</div></div>'
            + dev + lift('today_next', scr, 1.2, 50, edge=True))
    return (f'<!doctype html><html><head><meta charset="utf-8"><style>{css(1290 * 0.62, t)}'
            f'body{{width:{W}px;height:{H}px}}</style></head><body>{body}</body></html>')


# ----------------------------------------------------------------- render

def render(html, path, w, h):
    os.makedirs(TMP, exist_ok=True)
    src = os.path.join(TMP, os.path.basename(os.path.dirname(path)) + '_'
                       + os.path.basename(path) + '.html')
    with open(src, 'w') as f:
        f.write(html)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars',
                    '--force-device-scale-factor=1', '--allow-file-access-from-files',
                    f'--window-size={w},{h}', f'--screenshot={path}', 'file://' + src],
                   check=True, capture_output=True)
    print('wrote', os.path.relpath(path, ROOT))


def overview(paths, out, h=900):
    imgs = ''.join(f'<img src="file://{p}" style="height:{h}px;border-radius:{h * 0.04:.0f}px">'
                   for p in paths)
    html = (f'<html><body style="margin:0;background:#FFFFFF;display:flex;gap:28px;'
            f'padding:40px">{imgs}</body></html>')
    w = 80 + len(paths) * (h * 1290 / 2796 + 28)
    render(html, out, int(w), h + 80)


def main():
    name = sys.argv[1] if len(sys.argv) > 1 else 'ink'
    t = THEMES[name]
    global OUT
    if name != 'ink':
        OUT = os.path.join(ROOT, f'out-{name}')
    made = []
    for size, (W, H, *_rest) in SIZES.items():
        for i, sl in enumerate(SLIDES):
            path = os.path.join(OUT, size, f'{i + 1:02d}_{sl["name"]}.png')
            html = (f'<!doctype html><html><head><meta charset="utf-8"><style>{css(W, t)}'
                    f'body{{width:{W}px;height:{H}px}}</style></head><body>'
                    f'{slide(sl, W, H, t)}</body></html>')
            render(html, path, W, H)
            if size == 'appstore':
                made.append(path)
    render(feature(t), os.path.join(OUT, 'play', 'feature_graphic.png'), 1024, 500)
    icon = os.path.join(OUT, 'play', 'icon_512.png')
    subprocess.run(['sips', '-s', 'format', 'png', '-z', '512', '512', ICON, '--out', icon],
                   check=True, capture_output=True)
    print('wrote', os.path.relpath(icon, ROOT))
    overview(made, os.path.join(ROOT, 'overview.png' if name == 'ink' else f'overview-{name}.png'))


if __name__ == '__main__':
    main()
