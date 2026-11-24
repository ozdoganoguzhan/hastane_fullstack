"""App Store görsellerini üretir: başlıklı ekran görüntüleri + ürün sayfası header'ı.

Kullanım (hastane_menu/ içinden):
    python -I tools/appstore-gorselleri.py store/appstore

Girdi : <dizin>/ham/{iphone,ipad}-<N>-<ad>.png  — emülatörden alınmış ham kareler
        (iPhone: `wm size 1290x2796` + `wm density 480`,
         iPad  : `wm size 2064x2752` + `wm density 320`; bkz. store/appstore/README.md)
Çıktı : <dizin>/iphone-*.png (1290×2796), <dizin>/ipad-*.png (2064×2752),
        <dizin>/header-*.png  — hepsi RGB (alfa yok), App Store Connect'e hazır.

Android durum çubuğu ve gezinme/görev çubuğu KIRPILIR — App Store ekran
görüntüsünde başka platformun arayüzü görünmemeli.
"""

import glob
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = sys.argv[1] if len(sys.argv) > 1 else 'store/appstore'
RAW = os.path.join(OUT, 'ham')
LOGO = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'kapari.png')

FONTS = r'C:\Windows\Fonts'
BOLD = os.path.join(FONTS, 'segoeuib.ttf')
SEMI = os.path.join(FONTS, 'seguisb.ttf')

# AppColors (lib/core/constants/app_colors.dart)
PRIMARY = (0x19, 0x22, 0x7D)
PRIMARY_LIGHT = (0x2E, 0x3A, 0xA6)
PRIMARY_DEEP = (0x0B, 0x11, 0x40)
PRIMARY_SOFT = (0xED, 0xEF, 0xF9)
ACCENT = (0x05, 0xA1, 0xE6)
ACCENT_LIGHT = (0x3C, 0xBA, 0xF0)
TEXT_LIGHT = (0x64, 0x74, 0x8B)
BEZEL = (0x0F, 0x17, 0x2A)
WHITE = (255, 255, 255)

# Ham karede uygulama içeriğinin dikey sınırları (üst: durum çubuğu, alt:
# gezinme çubuğu / iPad'de görev çubuğu). Emülatörde ölçüldü.
CROP = {'iphone': (84, 2724), 'ipad': (56, 2632)}

# Yükleme hedefleri: ad → (tuval, ham kaynak, biçim). Ölçüler App Store
# Connect'in yuva açıklamalarından (2026-11):
#  • "iPhone with Dynamic Island" (6.1"/6.3") → 1206×2622 (alt: 1179×2556)
#  • "iPhone Duo" → 2007×2853 (alt: 1398×2034). Oranı (~1.42) telefondan çok
#    tablete yakın → iPad ham karelerinden, yani uygulamanın geniş düzeninden.
#  • "iPad 13"" → 2064×2752
# ⚠️ Eski 6.9" ölçüsü (1290×2796) bu yuvalara YÜKLENMİYOR (dimension hatası).
TARGETS = {
    'iphone-dynamic-island': ((1206, 2622), 'iphone', 'phone'),
    'iphone-duo': ((2007, 2853), 'ipad', 'wide'),
    'ipad': ((2064, 2752), 'ipad', 'wide'),
}

SLIDES = {
    '1-ana-sayfa': ('Bugünün menüsü\ntek bakışta',
                    'Kahvaltı, öğle ve akşam yemeği — kalori bilgisiyle'),
    '2-haftalik-menu': ('Haftalık menü\nelinizin altında',
                        'Gün şeridinde kaydırın, istediğiniz güne geçin'),
    '3-aylik-takvim': ('Tüm ayın menüsü\ntek ekranda',
                       'Takvimden günü seçin, menüyü anında görün'),
    '4-qr-kart': ('Yemek kartınız\ntelefonunuzda',
                  'Yemekhane girişinde QR kodu okutmanız yeterli'),
    '5-bilgiler': ('Yemekhane bilgileri\nher an yanınızda',
                   'Çalışma saatleri, konum ve iletişim'),
}

SS = 4  # kenar yumuşatma için süper örnekleme katsayısı


def rr_mask(size, radius):
    """Kenarları yumuşatılmış yuvarlatılmış dikdörtgen maskesi."""
    w, h = size
    big = Image.new('L', (w * SS, h * SS), 0)
    ImageDraw.Draw(big).rounded_rectangle(
        [0, 0, w * SS - 1, h * SS - 1], radius=radius * SS, fill=255)
    return big.resize(size, Image.LANCZOS)


def vgradient(size, top, bottom):
    w, h = size
    g = Image.new('RGB', (1, h))
    for y in range(h):
        t = y / max(1, h - 1)
        g.putpixel((0, y), tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)))
    return g.resize(size)


def dgradient(size, stops):
    """Sol üstten sağ alta çok duraklı degrade (heroGradient benzeri)."""
    w, h = size
    sw, sh = max(2, w // 16), max(2, h // 16)
    g = Image.new('RGB', (sw, sh))
    for y in range(sh):
        for x in range(sw):
            t = (x / (sw - 1) + y / (sh - 1)) / 2
            for i in range(len(stops) - 1):
                p0, c0 = stops[i]
                p1, c1 = stops[i + 1]
                if p0 <= t <= p1:
                    k = (t - p0) / (p1 - p0)
                    g.putpixel((x, y), tuple(round(a + (b - a) * k) for a, b in zip(c0, c1)))
                    break
    return g.resize(size, Image.BICUBIC)


def device(screen, width, bezel, radius):
    """Ekranı koyu çerçeveli, yuvarlak köşeli genel bir cihaz kalıbına koyar."""
    sw = width - 2 * bezel
    sh = round(screen.height * sw / screen.width)
    scr = screen.resize((sw, sh), Image.LANCZOS)
    dev = Image.new('RGBA', (width, sh + 2 * bezel), (0, 0, 0, 0))
    body = Image.new('RGBA', dev.size, BEZEL + (255,))
    dev.paste(body, (0, 0), rr_mask(dev.size, radius + bezel))
    dev.paste(scr, (bezel, bezel), rr_mask((sw, sh), radius))
    return dev


def paste_with_shadow(canvas, img, xy, blur, offset, alpha):
    shadow = Image.new('RGBA', img.size, PRIMARY_DEEP + (0,))
    shadow.putalpha(img.getchannel('A').point(lambda a: a * alpha // 255))
    pad = blur * 3
    layer = Image.new('RGBA', (img.width + 2 * pad, img.height + 2 * pad), (0, 0, 0, 0))
    layer.paste(shadow, (pad, pad))
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    canvas.alpha_composite(layer, (xy[0] - pad, xy[1] - pad + offset))
    canvas.alpha_composite(img, xy)


def white_logo(height, opacity=255):
    logo = Image.open(LOGO).convert('RGBA')
    w = round(logo.width * height / logo.height)
    logo = logo.resize((w, height), Image.LANCZOS)
    out = Image.new('RGBA', logo.size, WHITE + (0,))
    out.putalpha(logo.getchannel('A').point(lambda a: a * opacity // 255))
    return out


def wrap(draw, text, font, max_w):
    """Metni max_w'a sığacak şekilde satırlara böler (\\n zorunlu kırılımdır)."""
    lines = []
    for para in text.split('\n'):
        cur = ''
        for word in para.split(' '):
            trial = f'{cur} {word}'.strip()
            if draw.textlength(trial, font=font) <= max_w or not cur:
                cur = trial
            else:
                lines.append(cur)
                cur = word
        lines.append(cur)
    return lines


def draw_lines(draw, lines, font, x_center, y, fill, spacing):
    for line in lines:
        w = draw.textlength(line, font=font)
        draw.text((x_center - w / 2, y), line, font=font, fill=fill)
        y += round(font.size * spacing)
    return y


def screenshot(target, slug, title, subtitle):
    (W, H), src, style = TARGETS[target]
    raw = Image.open(os.path.join(RAW, f'{src}-{slug}.png')).convert('RGB')
    top, bottom = CROP[src]
    screen = raw.crop((0, top, raw.width, bottom))
    phone = style == 'phone'

    canvas = vgradient((W, H), WHITE, PRIMARY_SOFT).convert('RGBA')
    # Sağ üstte yumuşak camgöbeği hale (marka aksanı).
    glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([W * 0.55, -H * 0.12, W * 1.25, H * 0.22],
                                 fill=ACCENT_LIGHT + (38,))
    canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(W // 10)))

    d = ImageDraw.Draw(canvas)
    u = W / 1290 if phone else W / 1720  # tipografi birimi
    f_title = ImageFont.truetype(BOLD, round(100 * u))
    f_sub = ImageFont.truetype(SEMI, round(46 * u))
    max_text_w = W * (0.86 if phone else 0.80)

    y = round(150 * u)
    bar_w, bar_h = round(110 * u), round(14 * u)
    d.rounded_rectangle([W / 2 - bar_w / 2, y, W / 2 + bar_w / 2, y + bar_h],
                        radius=bar_h // 2, fill=ACCENT)
    y += bar_h + round(46 * u)
    y = draw_lines(d, wrap(d, title, f_title, max_text_w), f_title, W / 2, y, PRIMARY, 1.12)
    y += round(34 * u)
    y = draw_lines(d, wrap(d, subtitle, f_sub, max_text_w), f_sub, W / 2, y, TEXT_LIGHT, 1.3)

    # Cihaz kalıbı: kalan alana sığacak en büyük genişlik.
    gap, bottom_margin = round(70 * u), round(110 * u)
    bezel = round((26 if phone else 30) * u)
    radius = round((64 if phone else 40) * u)
    avail_h = H - y - gap - bottom_margin
    max_w = W * (0.80 if phone else 0.78)
    ratio = screen.height / screen.width
    dev_w = min(max_w, (avail_h - 2 * bezel) / ratio + 2 * bezel)
    dev = device(screen, round(dev_w), bezel, radius)
    x = (W - dev.width) // 2
    paste_with_shadow(canvas, dev, (x, y + gap), blur=round(36 * u), offset=round(28 * u), alpha=90)

    out = os.path.join(OUT, f'{target}-{slug}.png')
    canvas.convert('RGB').save(out, optimize=True)
    print(out, canvas.size)


def header(size, name='header'):
    W, H = size
    # Kompozisyon birimi: 3840x1646 oranına göre; 16:9'da (5244x2950) taşmasın
    # diye genişlikle sınırlanır, fazla yükseklik dikey boşluk olarak kalır.
    U = min(H, W * 1646 / 3840)
    canvas = dgradient(size, [(0, PRIMARY_LIGHT), (0.5, PRIMARY), (1, PRIMARY_DEEP)]).convert('RGBA')

    # Filigran: büyük, soluk beyaz wordmark (uygulama hero'larındaki gibi).
    wm = white_logo(round(U * 0.9), opacity=14)
    canvas.alpha_composite(wm, (round(-wm.width * 0.12), round(H * 0.32)))

    # Sağ blok: üç cihaz (ortadaki önde).
    shots = [os.path.join(RAW, f'iphone-{s}.png') for s in ('2-haftalik-menu', '1-ana-sayfa', '4-qr-kart')]
    top, bottom = CROP['iphone']
    screens = [Image.open(p).convert('RGB').crop((0, top, 1290, bottom)) for p in shots]
    ratio = screens[0].height / screens[0].width
    big_h, small_h = U * 0.80, U * 0.68
    bezel = round(U * 0.012)
    big_w = round((big_h - 2 * bezel) / ratio + 2 * bezel)
    small_w = round((small_h - 2 * bezel) / ratio + 2 * bezel)
    radius = round(U * 0.03)
    left_dev = device(screens[0], small_w, bezel, radius)
    mid_dev = device(screens[1], big_w, bezel, radius)
    right_dev = device(screens[2], small_w, bezel, radius)

    overlap = round(small_w * 0.30)
    group_w = small_w * 2 + big_w - overlap * 2

    # Sol blok: logo + başlık + alt başlık.
    d = ImageDraw.Draw(canvas)
    f_title = ImageFont.truetype(BOLD, round(U * 0.085))
    f_sub = ImageFont.truetype(SEMI, round(U * 0.034))
    title = ['Yemekhane menünüz', 'artık cebinizde']
    sub = ['Günlük, haftalık ve aylık menü · kalori bilgisi', 'Personel QR yemek kartı']
    text_w = max(max(d.textlength(t, font=f_title) for t in title),
                 max(d.textlength(t, font=f_sub) for t in sub))
    logo = white_logo(round(U * 0.11))

    gap = round(W * 0.05)
    total = text_w + gap + group_w
    x0 = round((W - total) / 2)

    # Metin bloğunu dikeyde ortala.
    block_h = logo.height + round(U * 0.06) + len(title) * round(f_title.size * 1.1) \
        + round(U * 0.03) + len(sub) * round(f_sub.size * 1.35)
    y = round((H - block_h) / 2)
    canvas.alpha_composite(logo, (x0, y))
    y += logo.height + round(U * 0.06)
    for t in title:
        d.text((x0, y), t, font=f_title, fill=WHITE)
        y += round(f_title.size * 1.1)
    y += round(U * 0.03)
    for t in sub:
        d.text((x0, y), t, font=f_sub, fill=ACCENT_LIGHT)
        y += round(f_sub.size * 1.35)

    gx = x0 + round(text_w) + gap
    ys = round((H - left_dev.height) / 2)
    ym = round((H - mid_dev.height) / 2)
    blur, off = round(U * 0.025), round(U * 0.018)
    paste_with_shadow(canvas, left_dev, (gx, ys), blur, off, 150)
    paste_with_shadow(canvas, right_dev, (gx + small_w + big_w - overlap * 2, ys), blur, off, 150)
    paste_with_shadow(canvas, mid_dev, (gx + small_w - overlap, ym), blur, off, 170)

    out = os.path.join(OUT, f'{name}-{W}x{H}.png')
    canvas.convert('RGB').save(out, optimize=True)
    print(out, canvas.size)


if __name__ == '__main__':
    for target, (_, src, _) in TARGETS.items():
        for slug, (title, subtitle) in SLIDES.items():
            if os.path.exists(os.path.join(RAW, f'{src}-{slug}.png')):
                screenshot(target, slug, title, subtitle)
    for size in ((5244, 2950), (3840, 1646)):
        header(size)
    # "Search Results" sekmesi: 1920x1280, header ile aynı kompozisyon.
    header((1920, 1280), name='search-results')
    print(len(glob.glob(os.path.join(OUT, '*.png'))), 'dosya')
