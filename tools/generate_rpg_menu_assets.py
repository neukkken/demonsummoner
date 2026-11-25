#!/usr/bin/env python3
"""
Generador de assets visuales de alta calidad para el Menú RPG de Demon Summoner.
Genera texturas en sprites/ con diseño gótico oscuro, hierro forjado, bronce y runas demoníacas.
"""

from PIL import Image, ImageDraw, ImageFilter
import math
import os

os.makedirs("sprites", exist_ok=True)

def create_sigil():
    size = 600
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size / 2.0, size / 2.0

    # 1. Anillos concéntricos de fuego arcano
    draw.ellipse([20, 20, size-20, size-20], outline=(160, 30, 20, 160), width=3)
    draw.ellipse([30, 30, size-30, size-30], outline=(220, 80, 25, 230), width=4)
    draw.ellipse([42, 42, size-42, size-42], outline=(140, 30, 15, 140), width=2)
    draw.ellipse([65, 65, size-65, size-65], outline=(255, 140, 40, 190), width=2)

    # 2. Pentagrama ceremonial
    r = (size - 130) / 2.0
    pts = []
    for i in range(5):
        ang = -math.pi / 2.0 + i * (2.0 * math.pi / 5.0)
        pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))

    p_order = [0, 2, 4, 1, 3, 0]
    for k in range(len(p_order) - 1):
        p1 = pts[p_order[k]]
        p2 = pts[p_order[k+1]]
        draw.line([p1, p2], fill=(255, 90, 20, 240), width=4)

    # 3. Anillos internos y marcas rúnicas
    r_mid = r * 0.52
    draw.ellipse([cx - r_mid, cy - r_mid, cx + r_mid, cy + r_mid], outline=(220, 70, 20, 200), width=3)

    r_inner = r * 0.28
    draw.ellipse([cx - r_inner, cy - r_inner, cx + r_inner, cy + r_inner], outline=(255, 140, 50, 220), width=2)

    # Radios / Rayos arcanos
    for i in range(20):
        ang = i * (2.0 * math.pi / 20.0)
        x1 = cx + (r - 20) * math.cos(ang)
        y1 = cy + (r - 20) * math.sin(ang)
        x2 = cx + (r - 8) * math.cos(ang)
        y2 = cy + (r - 8) * math.sin(ang)
        draw.line([(x1, y1), (x2, y2)], fill=(240, 110, 30, 190), width=2)

    # Suave resplandor difuso
    glow = img.filter(ImageFilter.GaussianBlur(radius=3))
    final = Image.alpha_composite(glow, img)
    final.save("sprites/rpg_sigil.png")
    print("✓ sprites/rpg_sigil.png creado")

def create_rpg_button(w=300, h=56, state="normal"):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Paletas de color por estado
    if state == "normal":
        bg_col1 = (22, 16, 26, 240)    # Obsidiana púrpura oscura
        bg_col2 = (14, 10, 16, 250)
        border_outer = (50, 40, 55, 255)
        border_inner = (130, 95, 45, 230) # Bronce antiguo
        filigree = (190, 145, 55, 255)    # Oro viejo
        rune_glow = (0, 0, 0, 0)
    elif state == "hover":
        bg_col1 = (45, 22, 35, 245)    # Carmesí oscuro místico
        bg_col2 = (28, 12, 22, 255)
        border_outer = (120, 45, 45, 255)
        border_inner = (220, 160, 60, 255) # Oro brillante
        filigree = (255, 210, 90, 255)     # Oro radiante
        rune_glow = (255, 80, 20, 180)     # Resplandor de fuego
    else: # pressed
        bg_col1 = (10, 6, 12, 255)
        bg_col2 = (16, 10, 18, 255)
        border_outer = (40, 30, 40, 255)
        border_inner = (90, 65, 30, 200)
        filigree = (140, 105, 35, 220)
        rune_glow = (180, 50, 10, 100)

    # 1. Relleno con gradiente vertical y biselado
    for y in range(h):
        factor = y / float(h)
        # Curva de relieve
        shade = math.sin(factor * math.pi) * 0.25 + 0.75
        r = int(bg_col1[0] * (1.0 - factor) + bg_col2[0] * factor * shade)
        g = int(bg_col1[1] * (1.0 - factor) + bg_col2[1] * factor * shade)
        b = int(bg_col1[2] * (1.0 - factor) + bg_col2[2] * factor * shade)
        draw.line([(6, y), (w - 7, y)], fill=(r, g, b, 245))

    # 2. Marco exterior y bisel
    draw.rectangle([2, 2, w - 3, h - 3], outline=border_outer, width=1)
    draw.rectangle([4, 4, w - 5, h - 5], outline=border_inner, width=2)

    # 3. Esquineras ornamentadas góticas (Trilobuladas / Remaches dorados)
    corner_len = 12
    # Sup Izq
    draw.line([(4, 4), (4 + corner_len, 4)], fill=filigree, width=2)
    draw.line([(4, 4), (4, 4 + corner_len)], fill=filigree, width=2)
    draw.rectangle([6, 6, 8, 8], fill=filigree)

    # Sup Der
    draw.line([(w - 5, 4), (w - 5 - corner_len, 4)], fill=filigree, width=2)
    draw.line([(w - 5, 4), (w - 5, 4 + corner_len)], fill=filigree, width=2)
    draw.rectangle([w - 9, 6, w - 7, 8], fill=filigree)

    # Inf Izq
    draw.line([(4, h - 5), (4 + corner_len, h - 5)], fill=filigree, width=2)
    draw.line([(4, h - 5), (4, h - 5 - corner_len)], fill=filigree, width=2)
    draw.rectangle([6, h - 9, 8, h - 7], fill=filigree)

    # Inf Der
    draw.line([(w - 5, h - 5), (w - 5 - corner_len, h - 5)], fill=filigree, width=2)
    draw.line([(w - 5, h - 5), (w - 5, h - 5 - corner_len)], fill=filigree, width=2)
    draw.rectangle([w - 9, h - 9, w - 7, h - 7], fill=filigree)

    # 4. Gemas o runas laterales
    for cx_gem in [14, w - 14]:
        cy_gem = h // 2
        draw.polygon([
            (cx_gem, cy_gem - 5),
            (cx_gem + 4, cy_gem),
            (cx_gem, cy_gem + 5),
            (cx_gem - 4, cy_gem)
        ], fill=(220, 40, 30, 240) if state == "hover" else (140, 30, 25, 200), outline=filigree)

    filename = f"sprites/rpg_button_{state}.png"
    img.save(filename)
    print(f"✓ {filename} creado")

def create_panel_frame(w=460, h=560):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Fondo piedra pizarra oscura semitransparente
    for y in range(h):
        t = y / float(h)
        shade = 0.85 + 0.15 * math.cos(t * math.pi)
        r = int(14 * shade)
        g = int(10 * shade)
        b = int(18 * shade)
        draw.line([(10, y), (w - 11, y)], fill=(r, g, b, 235))

    # Moldura gótica exterior
    draw.rectangle([4, 4, w - 5, h - 5], outline=(35, 25, 40, 255), width=2)
    draw.rectangle([8, 8, w - 9, h - 9], outline=(140, 105, 45, 240), width=2)
    draw.rectangle([12, 12, w - 13, h - 13], outline=(60, 45, 25, 180), width=1)

    # Arcos decorativos superiores
    cx = w // 2
    draw.arc([cx - 90, 8, cx + 90, 80], start=180, end=360, fill=(190, 145, 55, 220), width=2)
    draw.line([(cx - 90, 44), (cx + 90, 44)], fill=(150, 110, 40, 180), width=1)

    # Remates góticos en las 4 esquinas
    for (x, y, dx, dy) in [(12, 12, 1, 1), (w - 13, 12, -1, 1), (12, h - 13, 1, -1), (w - 13, h - 13, -1, -1)]:
        draw.line([(x, y), (x + dx * 24, y)], fill=(220, 170, 70, 240), width=3)
        draw.line([(x, y), (x, y + dy * 24)], fill=(220, 170, 70, 240), width=3)
        draw.ellipse([x - 3, y - 3, x + 3, y + 3], fill=(240, 80, 40, 255), outline=(220, 170, 70, 255))

    img.save("sprites/rpg_panel_frame.png")
    print("✓ sprites/rpg_panel_frame.png creado")

if __name__ == "__main__":
    create_sigil()
    create_rpg_button(300, 56, "normal")
    create_rpg_button(300, 56, "hover")
    create_rpg_button(300, 56, "pressed")
    create_panel_frame(460, 560)
    print("Todos los assets del menú RPG fueron generados con éxito!")
