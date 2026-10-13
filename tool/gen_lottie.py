"""Generates the CV Ready Lottie animations (palette-exact, clay style).

Run: python tool/gen_lottie.py  -> writes assets/lottie/*.json
"""
import json
import os

SCARLET = "#DA2C38"
TURF = "#226F54"
WILLOW = "#87C38F"
LEMON = "#F4F0BB"
COFFEE = "#43291F"

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "lottie")


def rgb(hex_, a=1.0):
    h = hex_.lstrip("#")
    return [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)] + [a]


def mix(a, b, t):
    ca, cb = rgb(a), rgb(b)
    return [ca[i] + (cb[i] - ca[i]) * t for i in range(3)]


EASE_OUT = {"o": {"x": [0.16], "y": [1]}, "i": {"x": [0.3], "y": [1]}}
EASE_IN_OUT = {"o": {"x": [0.65], "y": [0]}, "i": {"x": [0.35], "y": [1]}}
EASE_IN = {"o": {"x": [0.7], "y": [0]}, "i": {"x": [0.84], "y": [0]}}


def static(v):
    return {"a": 0, "k": v}


def anim(frames, ease=EASE_IN_OUT):
    """frames: list of (t, value). value list or scalar."""
    ks = []
    for i, (t, v) in enumerate(frames):
        v = v if isinstance(v, list) else [v]
        k = {"t": t, "s": v}
        if i < len(frames) - 1:
            dims = len(v)
            k["o"] = {"x": ease["o"]["x"] * dims, "y": ease["o"]["y"] * dims}
            k["i"] = {"x": ease["i"]["x"] * dims, "y": ease["i"]["y"] * dims}
        ks.append(k)
    return {"a": 1, "k": ks}


def transform(p=None, s=None, r=None, o=None, a=None):
    return {
        "ty": "tr",
        "p": p or static([0, 0]),
        "a": a or static([0, 0]),
        "s": s or static([100, 100]),
        "r": r or static(0),
        "o": o or static(100),
        "sk": static(0),
        "sa": static(0),
    }


def ellipse(w, h, p=(0, 0)):
    return {"ty": "el", "p": static(list(p)), "s": static([w, h]), "d": 1}


def rect(w, h, r, p=(0, 0)):
    return {"ty": "rc", "p": static(list(p)), "s": static([w, h]), "r": static(r), "d": 1}


def fill(hex_, a=100):
    return {"ty": "fl", "c": static(rgb(hex_)), "o": static(a), "r": 1}


def clay_fill(hex_, w, h):
    """Radial gradient: light top-left, base color, slightly darker rim."""
    light = mix(hex_, "#FFFFFF", 0.38)
    base = rgb(hex_)[:3]
    dark = mix(hex_, COFFEE, 0.28)
    stops = [0, *light, 0.55, *base, 1, *dark]
    return {
        "ty": "gf",
        "t": 2,
        "o": static(100),
        "r": 1,
        "s": static([-w * 0.28, -h * 0.32]),
        "e": static([w * 0.62, h * 0.62]),
        "h": static(0),
        "a": static(0),
        "g": {"p": 3, "k": static(stops)},
    }


def stroke(hex_, width, a=100):
    return {"ty": "st", "c": static(rgb(hex_)), "o": static(a), "w": static(width), "lc": 2, "lj": 2}


def group(items, tr=None, name="g"):
    return {"ty": "gr", "nm": name, "it": items + [tr or transform()]}


def layer(name, shapes, ind, op, ks=None):
    return {
        "ddd": 0,
        "ind": ind,
        "ty": 4,
        "nm": name,
        "sr": 1,
        "ks": ks or {
            "o": static(100), "r": static(0), "p": static([0, 0, 0]),
            "a": static([0, 0, 0]), "s": static([100, 100, 100]),
        },
        "ao": 0,
        "shapes": shapes,
        "ip": 0,
        "op": op,
        "st": 0,
        "bm": 0,
    }


def comp(name, w, h, op, layers, fr=60):
    # Lottie draws the first layer on top, so callers pass top-most first.
    return {"v": "5.7.4", "fr": fr, "ip": 0, "op": op, "w": w, "h": h, "nm": name,
            "ddd": 0, "assets": [], "layers": layers}


# ---------------------------------------------------------------- loading ---
def loading():
    """Three clay pebbles hop in sequence; their shadows breathe."""
    op = 72
    layers = []
    colors = [SCARLET, TURF, WILLOW]
    for i, c in enumerate(colors):
        x = 50 + i * 50
        d = i * 9  # stagger
        y_ground, y_top = 110, 62
        pos = anim([
            (0 + d, [x, y_ground]), (16 + d, [x, y_top]), (32 + d, [x, y_ground]), (op, [x, y_ground]),
        ], EASE_IN_OUT)
        squash = anim([
            (0 + d, [118, 84]), (8 + d, [92, 110]), (16 + d, [100, 100]),
            (28 + d, [96, 106]), (32 + d, [120, 82]), (40 + d, [100, 100]), (op, [100, 100]),
        ], EASE_OUT)
        blob = group([ellipse(34, 34), clay_fill(c, 34, 34)],
                     transform(p=pos, s=squash, a=static([0, 17])), name=f"blob{i}")
        shadow_s = anim([(0 + d, [100, 100]), (16 + d, [58, 58]), (32 + d, [100, 100]), (op, [100, 100])])
        shadow = group([ellipse(36, 8), fill(COFFEE, 16)],
                       transform(p=static([x, 113]), s=shadow_s), name=f"shadow{i}")
        layers.append(layer(f"pebble{i}", [blob], 2 * i + 1, op))
        layers.append(layer(f"shadow{i}", [shadow], 2 * i + 2, op))
    # Blobs above shadows.
    layers.sort(key=lambda l: 0 if l["nm"].startswith("pebble") else 1)
    for i, l in enumerate(layers):
        l["ind"] = i + 1
    return comp("cvready-loading", 200, 140, op, layers)


# ---------------------------------------------------------------- success ---
def success():
    op = 90
    disc_scale = anim([(0, [0, 0]), (14, [116, 116]), (24, [94, 94]), (32, [100, 100])], EASE_OUT)
    disc = group([ellipse(120, 120), clay_fill(WILLOW, 120, 120)],
                 transform(p=static([100, 96]), s=disc_scale), name="disc")
    # Check mark drawn with a trim path.
    check_path = {
        "ty": "sh",
        "ks": static({"i": [[0, 0], [0, 0], [0, 0]], "o": [[0, 0], [0, 0], [0, 0]],
                      "v": [[-26, 2], [-8, 20], [28, -18]], "c": False}),
    }
    trim = {"ty": "tm", "s": static(0), "e": anim([(18, 0), (40, 100)], EASE_OUT), "o": static(0), "m": 1}
    check = group([check_path, stroke(TURF, 14), trim], transform(p=static([100, 96]), s=disc_scale),
                  name="check")
    shadow = group([ellipse(110, 14), fill(COFFEE, 14)],
                   transform(p=static([100, 168]), s=anim([(0, [0, 0]), (18, [100, 100])], EASE_OUT)))
    layers = [layer("check", [check], 1, op), layer("disc", [disc], 2, op)]
    # Confetti burst.
    burst = [
        (SCARLET, (-70, -50)), (LEMON, (72, -44)), (TURF, (-80, 22)),
        (SCARLET, (78, 28)), (LEMON, (-30, -82)), (WILLOW, (36, -84)),
    ]
    for j, (c, (dx, dy)) in enumerate(burst):
        p = anim([(10, [100, 96]), (38, [100 + dx, 96 + dy])], EASE_OUT)
        s = anim([(10, [0, 0]), (20, [100, 100]), (48, [100, 100]), (62, [0, 0])], EASE_OUT)
        size = 14 if j % 2 == 0 else 10
        shape = rect(size, size, size / 2.6) if j % 3 == 0 else ellipse(size, size)
        layers.append(layer(f"confetti{j}", [group([shape, clay_fill(c, size, size)], transform(p=p, s=s))],
                            3 + j, op))
    layers.append(layer("shadow", [shadow], 20, op))
    for i, l in enumerate(layers):
        l["ind"] = i + 1
    return comp("cvready-success", 200, 200, op, layers)


# ------------------------------------------------------------------- hero ---
def hero():
    """A clay CV sheet writes its three lines, then the scarlet full stop drops in
    and presses - the CV Ready mark assembling itself. Loops gently."""
    op = 180
    cx, cy = 160, 150
    float_p = anim([(0, [cx, cy]), (90, [cx, cy - 7]), (180, [cx, cy])], EASE_IN_OUT)
    tilt = anim([(0, -4), (90, -1.5), (180, -4)], EASE_IN_OUT)
    sheet_items = [rect(170, 214, 30), clay_fill(LEMON, 170, 214)]
    layers = []

    # Lines grow from the left edge (scale x with anchor at left).
    lines = [(-58, 118, TURF, 18), (-20, 88, TURF, 30), (18, 54, TURF, 42)]
    line_groups = []
    for (y, w, c, start) in lines:
        x_left = -60
        grow = anim([(0, [0, 100]), (start, [0, 100]), (start + 22, [100, 100]),
                     (150, [100, 100]), (165, [0, 100]), (op, [0, 100])], EASE_OUT)
        line_groups.append(group([rect(w, 22, 11, p=(w / 2, 0)), clay_fill(c, w, 22)],
                                 transform(p=static([x_left, y]), s=grow)))
    # Full stop drops from above and squashes.
    dot_p = anim([(0, [24, -140]), (56, [24, -140]), (74, [24, 33]), (150, [24, 33]),
                  (166, [24, -140]), (op, [24, -140])], EASE_IN)
    dot_s = anim([(0, [100, 100]), (74, [100, 100]), (80, [128, 74]), (90, [92, 108]),
                  (100, [100, 100]), (op, [100, 100])], EASE_OUT)
    dot = group([ellipse(30, 30), clay_fill(SCARLET, 30, 30)],
                transform(p=dot_p, s=dot_s, a=static([0, 15])), name="dot")
    sheet_tr = transform(p=float_p, r=tilt)
    layers.append(layer("dot", [group([dot], sheet_tr)], 1, op))
    layers.append(layer("lines", [group(line_groups, transform(p=float_p, r=tilt))], 2, op))
    layers.append(layer("sheet", [group([group(sheet_items)], transform(p=float_p, r=tilt))], 3, op))

    # Back sheet (willow), offset, floats out of phase.
    back_p = anim([(0, [cx + 34, cy + 16]), (90, [cx + 34, cy + 22]), (180, [cx + 34, cy + 16])])
    back = group([rect(160, 200, 28), clay_fill(WILLOW, 160, 200)], transform(p=back_p, r=static(8)))
    layers.append(layer("back", [back], 4, op))

    # Shadow under everything breathes with the float.
    sh_s = anim([(0, [100, 100]), (90, [90, 90]), (180, [100, 100])])
    sh = group([ellipse(200, 22), fill(COFFEE, 14)], transform(p=static([cx + 14, 276]), s=sh_s))
    layers.append(layer("shadow", [sh], 5, op))

    # Small orbiting clay bits for life.
    bits = [(SCARLET, (52, 64), 16), (TURF, (276, 96), 12), (LEMON, (262, 240), 18)]
    for k, (c, (bx, by), sz) in enumerate(bits):
        p = anim([(0, [bx, by]), (60 + k * 20, [bx, by - 10]), (op, [bx, by])], EASE_IN_OUT)
        layers.insert(0, layer(f"bit{k}", [group([ellipse(sz, sz), clay_fill(c, sz, sz)], transform(p=p))],
                               10 + k, op))
    for i, l in enumerate(layers):
        l["ind"] = i + 1
    return comp("cvready-hero", 320, 300, op, layers)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, fn in [("loading", loading), ("success", success), ("hero", hero)]:
        path = os.path.join(OUT, f"{name}.json")
        with open(path, "w", encoding="utf-8") as f:
            json.dump(fn(), f, separators=(",", ":"))
        print("wrote", os.path.normpath(path))
