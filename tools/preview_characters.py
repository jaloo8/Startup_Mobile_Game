#!/usr/bin/env python3
"""
Renders preview images of the 14×20 PixelCharacter sprites.
Mirrors the exact drawing logic from pixel_character.gd.
"""

from PIL import Image, ImageDraw, ImageFont
import os

CHAR_W = 14
CHAR_H = 20
SCALE = 12
PADDING = 10

# Palettes (same as GDScript)
SKIN_TONES = [
    (240, 204, 171), (222, 181, 140), (191, 145, 107),
    (153, 110, 79),  (115, 77, 51),
]
HAIR_COLORS = [
    (38, 31, 26), (89, 56, 36), (140, 97, 56), (199, 148, 77),
    (224, 184, 97), (158, 71, 46), (184, 184, 184),
]
SHIRT_COLORS = {
    0: (82, 184, 112),  1: (224, 128, 89),  2: (209, 179, 77),
    3: (92, 158, 224),   4: (163, 122, 219), 5: (140, 140, 153),
}
PANTS      = (56, 66, 87)
PANTS_SH   = (43, 51, 71)
BELT       = (77, 71, 61)
SHOE       = (46, 46, 51)
SHOE_HI    = (53, 53, 59)
GLASS      = (204, 209, 230, 235)
EYE_W      = (235, 235, 240)
EYE_P      = (31, 31, 41)
BG         = (18, 23, 33)

ASSIGN_NAMES = {
    0: "Features", 1: "Bugs", 2: "Tech Debt",
    3: "Infra", 4: "R&D", 5: "Idle",
}


def darken(c, a=0.15):
    return tuple(max(0, int(v * (1 - a))) for v in c[:3])

def lighten(c, a=0.12):
    return tuple(min(255, int(v + (255 - v) * a)) for v in c[:3])

def px(img, x, y, c):
    if 0 <= x < CHAR_W and 0 <= y < CHAR_H:
        img.putpixel((x, y), c[:3] + (255,) if len(c) == 3 else c)

def rect(img, x0, y0, w, h, c):
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            px(img, x, y, c)


def draw_char(skin, hair, shirt, hair_style, glasses, assignment, pose):
    img = Image.new("RGBA", (CHAR_W, CHAR_H), (0, 0, 0, 0))
    sk_sh = darken(skin, 0.12)
    h_hi = lighten(hair, 0.12)
    h_sh = darken(hair, 0.12)
    sh_hi = lighten(shirt, 0.10)
    sh_sh = darken(shirt, 0.15)
    cx = CHAR_W // 2  # 7
    head_w, head_x = 6, 4
    torso_w, torso_x = 8, 3

    # --- Hair ---
    if hair_style == 0:  # short crop
        rect(img, head_x, 0, head_w, 2, hair)
        px(img, head_x + 1, 0, h_hi)
    elif hair_style == 1:  # side-part
        rect(img, head_x, 0, head_w + 1, 2, hair)
        rect(img, head_x, 2, head_w, 1, h_sh)
        px(img, head_x + 2, 0, h_sh)
        px(img, head_x + 1, 0, h_hi)
    elif hair_style == 2:  # long
        rect(img, head_x - 1, 0, head_w + 2, 3, hair)
        px(img, head_x, 0, h_hi)
        for y in range(3, 7):
            px(img, head_x - 1, y, h_sh)
            px(img, head_x + head_w, y, h_sh)
    elif hair_style == 3:  # spiky
        rect(img, head_x, 1, head_w, 2, hair)
        for x in range(head_x, head_x + head_w):
            if (x + head_x) % 2 == 0:
                px(img, x, 0, hair)
        px(img, head_x + 1, 0, h_hi)
    elif hair_style == 4:  # bun
        rect(img, head_x, 1, head_w, 2, hair)
        rect(img, cx - 2, 0, 4, 1, hair)
        px(img, cx - 1, 0, h_hi)

    # --- Head ---
    rect(img, head_x, 2, head_w, 5, skin)
    for y in range(2, 7):
        px(img, head_x + head_w - 1, y, sk_sh)

    # Eyes
    ey = 4
    px(img, head_x + 1, ey, EYE_W)
    px(img, head_x + 2, ey, EYE_P)
    px(img, head_x + 3, ey, EYE_P)
    px(img, head_x + 4, ey, EYE_W)

    # Glasses
    if glasses:
        for gx in [head_x + 1, head_x + 2, head_x + 3, head_x + 4]:
            px(img, gx, ey - 1, GLASS)
            px(img, gx, ey + 1, GLASS)

    # Mouth
    px(img, head_x + 2, 5, sk_sh)
    px(img, head_x + 3, 5, sk_sh)

    # --- Neck ---
    px(img, cx - 1, 7, skin)
    px(img, cx, 7, sk_sh)

    # --- Torso ---
    ty = 8
    rect(img, torso_x, ty, torso_w, 1, sh_hi)
    px(img, cx - 1, ty, lighten(shirt, 0.25))
    px(img, cx, ty, lighten(shirt, 0.25))
    rect(img, torso_x, ty + 1, torso_w, 4, shirt)
    for y in range(ty + 1, ty + 4):
        px(img, torso_x, y, sh_hi)
        px(img, torso_x + torso_w - 1, y, sh_sh)

    # --- Arms ---
    arm_hi = darken(shirt, 0.08)
    arm_lo = darken(shirt, 0.22)

    if assignment in (0, 2, 3):
        if pose == 0:
            for y in range(ty, ty + 4):
                px(img, torso_x - 1, y, arm_hi)
                px(img, torso_x + torso_w, y, arm_lo)
            px(img, torso_x - 1, ty + 4, skin)
            px(img, torso_x + torso_w, ty + 4, sk_sh)
        else:
            for y in range(ty, ty + 3):
                px(img, torso_x - 1, y, arm_hi)
                px(img, torso_x + torso_w, y, arm_lo)
            px(img, torso_x, ty + 3, skin)
            px(img, torso_x + 1, ty + 3, skin)
            px(img, torso_x + torso_w - 2, ty + 3, sk_sh)
            px(img, torso_x + torso_w - 1, ty + 3, sk_sh)
    elif assignment == 1:
        if pose == 0:
            for y in range(ty, ty + 4):
                px(img, torso_x - 1, y, arm_hi)
                px(img, torso_x + torso_w, y, arm_lo)
            px(img, torso_x - 1, ty + 4, skin)
            px(img, torso_x + torso_w, ty + 4, sk_sh)
        else:
            for y in range(ty, ty + 4):
                px(img, torso_x - 1, y, arm_hi)
            px(img, torso_x - 1, ty + 4, skin)
            px(img, torso_x + torso_w, ty, arm_lo)
            px(img, torso_x + torso_w, ty - 1, arm_lo)
            px(img, torso_x + torso_w, ty - 2, sk_sh)
    elif assignment == 4:
        if pose == 0:
            for y in range(ty, ty + 4):
                px(img, torso_x - 1, y, arm_hi)
                px(img, torso_x + torso_w, y, arm_lo)
            px(img, torso_x - 1, ty + 4, skin)
            px(img, torso_x + torso_w, ty + 4, sk_sh)
        else:
            for y in range(ty, ty + 4):
                px(img, torso_x - 1, y, arm_hi)
            px(img, torso_x - 1, ty + 4, skin)
            px(img, torso_x + torso_w, ty, arm_lo)
            px(img, torso_x + torso_w, ty - 1, arm_lo)
            px(img, head_x + head_w - 1, 6, sk_sh)
    else:
        aty = ty + (1 if pose == 1 else 0)
        for y in range(aty, aty + 4):
            px(img, torso_x - 1, y, arm_hi)
            px(img, torso_x + torso_w, y, arm_lo)
        px(img, torso_x - 1, aty + 4, skin)
        px(img, torso_x + torso_w, aty + 4, sk_sh)

    # --- Belt ---
    rect(img, torso_x, 13, torso_w, 1, BELT)

    # --- Legs ---
    leg_inner = cx - 1
    lo_l = torso_x + 1
    lo_r = torso_x + torso_w - 2
    for y in range(14, 18):
        px(img, lo_l, y, PANTS); px(img, lo_l + 1, y, PANTS); px(img, leg_inner, y, PANTS_SH)
        px(img, leg_inner + 1, y, PANTS_SH); px(img, lo_r - 1, y, PANTS); px(img, lo_r, y, PANTS)

    # --- Shoes ---
    for y in range(18, 20):
        px(img, lo_l, y, SHOE); px(img, lo_l + 1, y, SHOE); px(img, leg_inner, y, SHOE)
        px(img, leg_inner + 1, y, SHOE); px(img, lo_r - 1, y, SHOE); px(img, lo_r, y, SHOE)
    px(img, lo_l, 19, SHOE_HI)
    px(img, lo_r, 19, SHOE_HI)

    return img


def render():
    out_dir = os.path.dirname(os.path.abspath(__file__))
    try:
        font = ImageFont.truetype("/System/Library/Fonts/SFNSMono.ttf", 13)
    except (OSError, IOError):
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", 13)
        except (OSError, IOError):
            font = ImageFont.load_default()

    # --- Assignment showcase ---
    cell_w = CHAR_W * SCALE + PADDING * 2
    cell_h = CHAR_H * SCALE + PADDING * 2
    label_h = 24
    cols = 6
    total_w = cols * cell_w + PADDING
    total_h = 2 * cell_h + label_h * 3 + PADDING * 3

    canvas = Image.new("RGBA", (total_w, total_h), BG + (255,))
    draw = ImageDraw.Draw(canvas)

    skin = SKIN_TONES[2]
    hair = HAIR_COLORS[1]
    styles = [0, 3, 1, 2, 4, 0]
    glass_map = [False, False, True, False, False, False]

    for col in range(6):
        shirt = SHIRT_COLORS[col]
        x_base = PADDING + col * cell_w
        draw.text((x_base + 2, PADDING - 2), ASSIGN_NAMES[col], fill=(200, 200, 210), font=font)
        for row, pose in enumerate([0, 1]):
            frame = draw_char(skin, hair, shirt, styles[col], glass_map[col], col, pose)
            scaled = frame.resize((CHAR_W * SCALE, CHAR_H * SCALE), Image.NEAREST)
            y_base = label_h + PADDING * 2 + row * (cell_h + label_h)
            canvas.paste(scaled, (x_base, y_base), scaled)
            lbl = "Rest" if pose == 0 else "Active"
            draw.text((x_base + 2, y_base + CHAR_H * SCALE + 2), lbl, fill=(120, 120, 140), font=font)

    p = os.path.join(out_dir, "preview_assignments.png")
    canvas.save(p); print(f"Saved: {p}")

    # --- Diversity + hair styles ---
    div_cols = 5
    dw = div_cols * cell_w + PADDING
    dh = cell_h + label_h + PADDING * 3

    dc = Image.new("RGBA", (dw, dh), BG + (255,))
    dd = ImageDraw.Draw(dc)
    dd.text((PADDING, PADDING), "Skin / hair / style diversity", fill=(200, 200, 210), font=font)
    hair_picks = [0, 2, 4, 5, 6]
    for i in range(5):
        frame = draw_char(SKIN_TONES[i], HAIR_COLORS[hair_picks[i]],
                          SHIRT_COLORS[0], i, i == 2, 0, 0)
        scaled = frame.resize((CHAR_W * SCALE, CHAR_H * SCALE), Image.NEAREST)
        dc.paste(scaled, (PADDING + i * cell_w, label_h + PADDING * 2), scaled)

    p = os.path.join(out_dir, "preview_diversity.png")
    dc.save(p); print(f"Saved: {p}")

    # --- Office scene ---
    sw, sh = 520, 240
    scene = Image.new("RGBA", (sw, sh), (14, 18, 26, 255))
    sd = ImageDraw.Draw(scene)
    sd.rectangle([(0, 170), (sw, sh)], fill=(22, 28, 38, 255))
    sd.text((10, 8), "Office scene — workers at desks", fill=(160, 160, 180), font=font)

    desks = [(50, 135), (150, 135), (260, 135), (360, 135), (440, 135)]
    configs = [
        (SKIN_TONES[0], HAIR_COLORS[4], 0, 1, True, 0),
        (SKIN_TONES[2], HAIR_COLORS[1], 1, 3, False, 1),
        (SKIN_TONES[3], HAIR_COLORS[0], 4, 2, True, 0),
        (SKIN_TONES[1], HAIR_COLORS[5], 3, 0, False, 0),
        (SKIN_TONES[4], HAIR_COLORS[6], 2, 4, False, 1),
    ]

    for (dx, dy), (sk, hr, a, hs, gl, p) in zip(desks, configs):
        sd.rectangle([(dx - 22, dy), (dx + 22, dy + 7)], fill=(40, 50, 68, 230))
        sd.rectangle([(dx + 6, dy - 5), (dx + 17, dy - 1)], fill=(35, 45, 60, 240))
        sd.rectangle([(dx + 7, dy - 4), (dx + 16, dy - 2)], fill=(70, 115, 185, 180))
        frame = draw_char(sk, hr, SHIRT_COLORS[a], hs, gl, a, p)
        ws = 7
        scaled = frame.resize((CHAR_W * ws, CHAR_H * ws), Image.NEAREST)
        scene.paste(scaled, (dx - CHAR_W * ws // 2, dy - CHAR_H * ws + 4), scaled)

    p = os.path.join(out_dir, "preview_office_scene.png")
    scene.save(p); print(f"Saved: {p}")


if __name__ == "__main__":
    render()
