import os, sys
from PIL import Image
A = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "characters")
def L(n):
    return Image.open(os.path.join(A, n + ".png")).convert("RGBA")
def compose(costume=None, mouth="smile", eyes="open"):
    order = ["frog_shadow"]
    if costume: order.append(f"costume_{costume}_back")
    order += ["frog_leg_l", "frog_leg_r", "frog_body", "frog_belly"]
    if costume: order.append(f"costume_{costume}_body")
    order += ["frog_arm_l", "frog_arm_r", "frog_head", "frog_cheek_l", "frog_cheek_r"]
    if eyes == "open":
        order += ["frog_eye_l", "frog_eye_r", "frog_pupil_l", "frog_pupil_r"]
    elif eyes == "happy":
        order += ["frog_happy_l", "frog_happy_r"]
    order.append({"smile": "frog_mouth_smile", "open": "frog_mouth_open", "o": "frog_mouth_o", "sad": "frog_mouth_sad"}[mouth])
    if costume: order.append(f"costume_{costume}_head")
    im = Image.new("RGBA", (512, 576), (0, 0, 0, 0))
    for n in order:
        im.alpha_composite(L(n))
    return im
if __name__ == "__main__":
    names = [None, "royal", "wizard", "ninja", "pirate", "galaxy"]
    sheet = Image.new("RGBA", (512 * 3, 576 * 2), (40, 90, 70, 255))
    for i, n in enumerate(names):
        sheet.alpha_composite(compose(n, "smile"), ((i % 3) * 512, (i // 3) * 576))
    sheet.resize((768, 576)).save(os.path.join(A, "..", "..", "build", "frog_sheet.png"))
