#!/usr/bin/env python3
"""
Generates the Glow Dash app icon (1024x1024 PNG).
Requires: pip install Pillow

Usage: python scripts/generate_icon.py

Output: GlowDash/Assets.xcassets/AppIcon.appiconset/icon_1024.png
"""

from PIL import Image, ImageDraw, ImageFilter
import math
import os

SIZE = 1024
CENTER = SIZE // 2

# Colors matching the game's neon theme
BG_COLOR = (10, 5, 30)           # Deep dark purple
NEON_CYAN = (0, 255, 255)        # Primary neon color
NEON_GLOW = (0, 200, 255, 180)   # Glow overlay


def draw_bird(draw, cx, cy, scale, color):
    """Draw the chevron bird shape."""
    w = 120 * scale
    h = 90 * scale

    points = [
        (cx + w, cy),                       # nose
        (cx - w * 0.3, cy + h),             # bottom-back
        (cx - w * 0.6, cy + h * 0.3),       # indent bottom
        (cx - w, cy + h * 0.5),             # tail bottom
        (cx - w, cy - h * 0.5),             # tail top
        (cx - w * 0.6, cy - h * 0.3),       # indent top
        (cx - w * 0.3, cy - h),             # top-back
    ]
    draw.polygon(points, fill=color)


def main():
    # Base image (dark background)
    img = Image.new("RGBA", (SIZE, SIZE), BG_COLOR + (255,))

    # --- Background gradient ---
    gradient = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    grad_draw = ImageDraw.Draw(gradient)
    for y in range(SIZE):
        alpha = int(40 * (y / SIZE))
        grad_draw.line([(0, y), (SIZE, y)], fill=(30, 10, 60, alpha))
    img = Image.alpha_composite(img, gradient)

    # --- Subtle grid lines ---
    grid = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    grid_draw = ImageDraw.Draw(grid)
    spacing = 60
    for x in range(0, SIZE, spacing):
        grid_draw.line([(x, 0), (x, SIZE)], fill=(0, 255, 255, 8), width=1)
    for y in range(0, SIZE, spacing):
        grid_draw.line([(0, y), (SIZE, y)], fill=(0, 255, 255, 8), width=1)
    img = Image.alpha_composite(img, grid)

    # --- Glow layer (large blurred bird shape) ---
    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    draw_bird(glow_draw, CENTER + 10, CENTER - 20, 2.2, (0, 255, 255, 100))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=60))
    img = Image.alpha_composite(img, glow)

    # --- Medium glow ---
    glow2 = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    glow2_draw = ImageDraw.Draw(glow2)
    draw_bird(glow2_draw, CENTER + 10, CENTER - 20, 1.8, (0, 255, 255, 150))
    glow2 = glow2.filter(ImageFilter.GaussianBlur(radius=30))
    img = Image.alpha_composite(img, glow2)

    # --- Main bird shape ---
    bird = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    bird_draw = ImageDraw.Draw(bird)
    draw_bird(bird_draw, CENTER + 10, CENTER - 20, 1.5, (0, 220, 240, 200))
    img = Image.alpha_composite(img, bird)

    # --- Bright core ---
    core = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    core_draw = ImageDraw.Draw(core)
    draw_bird(core_draw, CENTER + 10, CENTER - 20, 1.0, (150, 255, 255, 220))
    core = core.filter(ImageFilter.GaussianBlur(radius=8))
    img = Image.alpha_composite(img, core)

    # --- Eye ---
    eye_x = CENTER + 10 + 50
    eye_y = CENTER - 20 - 15
    eye = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    eye_draw = ImageDraw.Draw(eye)
    eye_draw.ellipse([eye_x - 18, eye_y - 18, eye_x + 18, eye_y + 18], fill=(255, 255, 255, 240))
    img = Image.alpha_composite(img, eye)

    # --- Particle trail dots ---
    trail = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    trail_draw = ImageDraw.Draw(trail)
    import random
    random.seed(42)  # Deterministic
    for i in range(20):
        tx = CENTER - 200 - i * 15 + random.randint(-20, 20)
        ty = CENTER - 20 + random.randint(-30, 30)
        r = max(3, 12 - i)
        alpha = max(30, 200 - i * 10)
        trail_draw.ellipse([tx - r, ty - r, tx + r, ty + r], fill=(0, 255, 255, alpha))
    trail = trail.filter(ImageFilter.GaussianBlur(radius=5))
    img = Image.alpha_composite(img, trail)

    # --- Ground neon line ---
    ground_y = SIZE - 180
    ground = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ground_draw = ImageDraw.Draw(ground)
    ground_draw.line([(0, ground_y), (SIZE, ground_y)], fill=(0, 255, 255, 120), width=3)
    ground = ground.filter(ImageFilter.GaussianBlur(radius=4))
    img = Image.alpha_composite(img, ground)
    # Sharp line on top
    sharp = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sharp_draw = ImageDraw.Draw(sharp)
    sharp_draw.line([(0, ground_y), (SIZE, ground_y)], fill=(0, 255, 255, 200), width=2)
    img = Image.alpha_composite(img, sharp)

    # Convert to RGB (App Store requires no alpha channel)
    final = Image.new("RGB", (SIZE, SIZE), BG_COLOR)
    final.paste(img, mask=img.split()[3])

    # Save
    output_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)),
                              "GlowDash", "Assets.xcassets", "AppIcon.appiconset")
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, "icon_1024.png")
    final.save(output_path, "PNG")
    print(f"App icon saved to: {output_path}")
    print(f"Size: {SIZE}x{SIZE}")


if __name__ == "__main__":
    main()
