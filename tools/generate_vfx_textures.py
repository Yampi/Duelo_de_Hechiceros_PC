import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "vfx", "textures")
os.makedirs(OUTPUT_DIR, exist_ok=True)

def save_image(img_arr, filename):
    img = Image.fromarray(img_arr.astype(np.uint8), mode="RGBA")
    path = os.path.join(OUTPUT_DIR, filename)
    img.save(path)
    print(f"Generated: {path} ({img.size[0]}x{img.size[1]})")

# 1. Soft Radial Glow (256x256)
def gen_glow_soft(size=256):
    y, x = np.ogrid[:size, :size]
    center = (size - 1) / 2.0
    r = np.sqrt((x - center)**2 + (y - center)**2) / center
    r = np.clip(r, 0.0, 1.0)
    
    # Smooth cosine falloff
    alpha = np.cos(r * math.pi * 0.5) ** 2.2
    alpha = np.clip(alpha * 255.0, 0, 255)
    
    rgb = np.full((size, size, 3), 255)
    rgba = np.dstack([rgb, alpha])
    save_image(rgba, "glow_soft.png")

# 2. Spark Star 4-point (256x256)
def gen_spark_star(size=256):
    y, x = np.ogrid[:size, :size]
    center = (size - 1) / 2.0
    dx = np.abs(x - center) / center
    dy = np.abs(y - center) / center
    r = np.sqrt(dx**2 + dy**2)
    
    # Horizontal & vertical flares
    flare_h = 1.0 / (1.0 + 40.0 * (dy**1.2) + 1.8 * dx)
    flare_v = 1.0 / (1.0 + 40.0 * (dx**1.2) + 1.8 * dy)
    
    # Core round glow
    core = np.exp(-14.0 * (r**2))
    
    intensity = np.maximum(np.maximum(flare_h, flare_v), core * 1.2)
    # Mask out boundary
    mask = np.clip(1.0 - r, 0.0, 1.0) ** 1.5
    intensity = np.clip(intensity * mask * 255.0, 0, 255)
    
    rgb = np.full((size, size, 3), 255)
    rgba = np.dstack([rgb, intensity])
    save_image(rgba, "spark_star.png")

# 3. Smoke Noise (256x256)
def gen_smoke_noise(size=256):
    # Procedural multi-octave Perlin-like noise using sine harmonics
    y, x = np.mgrid[:size, :size] / float(size)
    noise = np.zeros((size, size))
    freqs = [3.0, 6.0, 12.0, 24.0]
    weights = [0.5, 0.25, 0.15, 0.1]
    
    for f, w in zip(freqs, weights):
        noise += w * (np.sin(x * f * 6.28 + np.cos(y * f * 3.14)) * 0.5 + 0.5)
        noise += w * (np.cos(y * f * 6.28 + np.sin(x * f * 3.14)) * 0.5 + 0.5)
    noise = noise / np.max(noise)
    
    center = 0.5
    r = np.sqrt((x - center)**2 + (y - center)**2) / 0.5
    mask = np.clip(1.0 - r, 0.0, 1.0) ** 2.0
    
    alpha = np.clip(noise * mask * 255.0 * 1.3, 0, 255)
    rgb = np.full((size, size, 3), 240)
    rgba = np.dstack([rgb, alpha])
    save_image(rgba, "smoke_noise.png")

# 4. Sharp Ring (256x256)
def gen_ring_sharp(size=256):
    y, x = np.ogrid[:size, :size]
    center = (size - 1) / 2.0
    r = np.sqrt((x - center)**2 + (y - center)**2) / center
    
    target_r = 0.72
    thickness = 0.08
    dist = np.abs(r - target_r) / thickness
    ring = np.exp(-3.5 * (dist**2))
    ring = np.clip(ring * (1.0 - np.clip(r - 0.9, 0, 1)), 0, 1)
    
    alpha = np.clip(ring * 255.0, 0, 255)
    rgb = np.full((size, size, 3), 255)
    rgba = np.dstack([rgb, alpha])
    save_image(rgba, "ring_sharp.png")

# 5. Flame Tear (256x256)
def gen_flame_tear(size=256):
    y, x = np.ogrid[:size, :size]
    center_x = (size - 1) / 2.0
    norm_x = (x - center_x) / (size * 0.5)
    norm_y = y / float(size) # 0 at top, 1 at bottom
    
    # Teardrop shape: width narrows as y decreases (towards top)
    # Bottom round, top pointed
    width = np.sin(norm_y * math.pi * 0.85) * 0.42 + 0.01
    dist_x = np.abs(norm_x) / np.maximum(width, 0.001)
    
    flame_mask = np.clip(1.0 - dist_x, 0.0, 1.0) ** 1.8
    vert_fade = np.clip(norm_y * 1.8, 0.0, 1.0) * np.clip((1.0 - norm_y) * 4.0, 0.0, 1.0)
    
    alpha = np.clip(flame_mask * vert_fade * 255.0 * 1.4, 0, 255)
    rgb = np.full((size, size, 3), 255)
    rgba = np.dstack([rgb, alpha])
    save_image(rgba, "flame_tear.png")

# 6. Snowflake Crystal (256x256)
def gen_snowflake_crystal(size=256):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    center = size / 2.0
    
    # 6 main branches with sub-spurs
    for angle_deg in range(0, 360, 60):
        rad = math.radians(angle_deg)
        cos_a = math.cos(rad)
        sin_a = math.sin(rad)
        
        # Main branch
        length = size * 0.42
        end_x = center + cos_a * length
        end_y = center + sin_a * length
        draw.line([center, center, end_x, end_y], fill=(255, 255, 255, 255), width=3)
        
        # Sub-spurs at 35% and 70% length
        for t, spur_len in [(0.38, 22), (0.70, 16), (0.88, 8)]:
            sp_x = center + cos_a * (length * t)
            sp_y = center + sin_a * (length * t)
            for branch_angle in [rad + math.radians(45), rad - math.radians(45)]:
                bx = sp_x + math.cos(branch_angle) * spur_len
                by = sp_y + math.sin(branch_angle) * spur_len
                draw.line([sp_x, sp_y, bx, by], fill=(255, 255, 255, 240), width=2)
                
    # Center crystal hexagon
    hex_pts = []
    for a in range(0, 360, 60):
        hr = math.radians(a)
        hex_pts.append((center + math.cos(hr) * 16, center + math.sin(hr) * 16))
    draw.polygon(hex_pts, outline=(255, 255, 255, 255), width=2)
    
    # Inner glow dot
    draw.ellipse([center - 6, center - 6, center + 6, center + 6], fill=(255, 255, 255, 255))
    
    # Soften / blur edges slightly with numpy convolution
    arr = np.array(img)
    save_image(arr, "snowflake_crystal.png")

# 7. Lightning Flash (256x256)
def gen_lightning_flash(size=256):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    center = size / 2.0
    
    # Zigzag jagged bolt from top to bottom
    np.random.seed(42)
    pts = [(center, 12)]
    curr_x = center
    steps = 14
    for i in range(1, steps):
        curr_y = 12 + (size - 24) * (i / float(steps))
        curr_x += np.random.uniform(-24, 24)
        curr_x = np.clip(curr_x, 30, size - 30)
        pts.append((curr_x, curr_y))
    pts.append((center + np.random.uniform(-10, 10), size - 12))
    
    # Draw halo line then core line
    for i in range(len(pts) - 1):
        draw.line([pts[i], pts[i+1]], fill=(255, 255, 255, 120), width=8)
    for i in range(len(pts) - 1):
        draw.line([pts[i], pts[i+1]], fill=(255, 255, 255, 255), width=3)
        
    # 2 small side branches
    b1_start = pts[4]
    b1_mid = (b1_start[0] - 28, b1_start[1] + 20)
    b1_end = (b1_start[0] - 42, b1_start[1] + 45)
    draw.line([b1_start, b1_mid, b1_end], fill=(255, 255, 255, 200), width=2)
    
    b2_start = pts[9]
    b2_mid = (b2_start[0] + 30, b2_start[1] + 22)
    b2_end = (b2_start[0] + 44, b2_start[1] + 48)
    draw.line([b2_start, b2_mid, b2_end], fill=(255, 255, 255, 200), width=2)
    
    arr = np.array(img)
    save_image(arr, "lightning_flash.png")

# 8. Magic Circle Runes (512x512)
def gen_magic_circle_runes(size=512):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c = size / 2.0
    
    # Outer concentric boundary rings
    draw.ellipse([c - 240, c - 240, c + 240, c + 240], outline=(255, 255, 255, 255), width=3)
    draw.ellipse([c - 228, c - 228, c + 228, c + 228], outline=(255, 255, 255, 180), width=1)
    draw.ellipse([c - 192, c - 192, c + 192, c + 192], outline=(255, 255, 255, 220), width=2)
    draw.ellipse([c - 140, c - 140, c + 140, c + 140], outline=(255, 255, 255, 180), width=2)
    draw.ellipse([c - 75, c - 75, c + 75, c + 75], outline=(255, 255, 255, 220), width=2)
    
    # 8-pointed star (two intersecting squares rotated by 45 degrees)
    r_star = 188
    for offset_deg in [0, 45]:
        pts = []
        for i in range(4):
            ang = math.radians(offset_deg + i * 90)
            pts.append((c + math.cos(ang) * r_star, c + math.sin(ang) * r_star))
        draw.polygon(pts, outline=(255, 255, 255, 240), width=2)
        
    # Secondary 12-fold geometric radial spokes
    for i in range(12):
        ang = math.radians(i * 30)
        x1 = c + math.cos(ang) * 140
        y1 = c + math.sin(ang) * 140
        x2 = c + math.cos(ang) * 192
        y2 = c + math.sin(ang) * 192
        draw.line([(x1, y1), (x2, y2)], fill=(255, 255, 255, 200), width=2)
        
    # Glyphs / Runes in the annular band between r=192 and r=228
    num_glyphs = 16
    for i in range(num_glyphs):
        ang = math.radians(i * (360.0 / num_glyphs) + 11.25)
        gx = c + math.cos(ang) * 210
        gy = c + math.sin(ang) * 210
        # Draw small arcane glyph symbol (cross / diamond / chevron / rune)
        glyph_type = i % 4
        if glyph_type == 0:
            draw.ellipse([gx - 5, gy - 5, gx + 5, gy + 5], outline=(255, 255, 255, 240), width=2)
        elif glyph_type == 1:
            draw.line([(gx - 6, gy - 6), (gx + 6, gy + 6)], fill=(255, 255, 255, 240), width=2)
            draw.line([(gx - 6, gy + 6), (gx + 6, gy - 6)], fill=(255, 255, 255, 240), width=2)
        elif glyph_type == 2:
            draw.polygon([(gx, gy - 7), (gx + 6, gy + 5), (gx - 6, gy + 5)], outline=(255, 255, 255, 240), width=2)
        else:
            draw.polygon([(gx, gy - 6), (gx + 6, gy), (gx, gy + 6), (gx - 6, gy)], outline=(255, 255, 255, 240), width=2)
            
    # Center arcane seal: 6-pointed star (hexagram)
    r_inner = 72
    for offset_deg in [0, 60]:
        pts = []
        for i in range(3):
            ang = math.radians(offset_deg + i * 120)
            pts.append((c + math.cos(ang) * r_inner, c + math.sin(ang) * r_inner))
        draw.polygon(pts, outline=(255, 255, 255, 255), width=2)
    draw.ellipse([c - 16, c - 16, c + 16, c + 16], fill=(255, 255, 255, 255))
    
    arr = np.array(img)
    save_image(arr, "magic_circle_runes.png")

# 9. Light Mote (128x128)
def gen_light_mote(size=128):
    y, x = np.ogrid[:size, :size]
    center = (size - 1) / 2.0
    r = np.sqrt((x - center)**2 + (y - center)**2) / center
    r = np.clip(r, 0.0, 1.0)
    
    # Sharp bright nucleus with soft corona
    core = np.exp(-18.0 * (r**2))
    corona = np.clip(1.0 - r, 0.0, 1.0) ** 3.0
    alpha = np.clip((core * 0.75 + corona * 0.45) * 255.0, 0, 255)
    
    rgb = np.full((size, size, 3), 255)
    rgba = np.dstack([rgb, alpha])
    save_image(rgba, "light_mote.png")

# 10. Shockwave Ring (256x256)
def gen_shockwave_ring(size=256):
    y, x = np.ogrid[:size, :size]
    center = (size - 1) / 2.0
    r = np.sqrt((x - center)**2 + (y - center)**2) / center
    
    # Sharp outer shock front at r=0.88 with decaying tail towards center
    tail = np.where((r >= 0.45) & (r <= 0.88), ((r - 0.45) / 0.43)**3.5, 0.0)
    outer_falloff = np.where((r > 0.88) & (r <= 1.0), (1.0 - (r - 0.88) / 0.12)**2.0, 0.0)
    wave = np.maximum(tail, outer_falloff)
    
    alpha = np.clip(wave * 255.0, 0, 255)
    rgb = np.full((size, size, 3), 255)
    rgba = np.dstack([rgb, alpha])
    save_image(rgba, "shockwave_ring.png")

# 11. Dust Puff (256x256)
def gen_dust_puff(size=256):
    y, x = np.ogrid[:size, :size]
    center = (size - 1) / 2.0
    r = np.sqrt((x - center)**2 + (y - center)**2) / center
    
    # Multiple soft circular clumps
    clumps = np.zeros((size, size))
    offsets = [(0, 0), (-25, 20), (30, -15), (-15, -28), (25, 25)]
    radii = [0.45, 0.35, 0.38, 0.32, 0.30]
    
    for (ox, oy), cr in zip(offsets, radii):
        cr_px = cr * (size * 0.5)
        dist = np.sqrt((x - (center + ox))**2 + (y - (center + oy))**2) / cr_px
        clump = np.clip(1.0 - dist, 0.0, 1.0) ** 2.2
        clumps = np.maximum(clumps, clump)
        
    mask = np.clip(1.0 - r, 0.0, 1.0) ** 1.5
    alpha = np.clip(clumps * mask * 230.0, 0, 255)
    rgb = np.full((size, size, 3), 220)
    rgba = np.dstack([rgb, alpha])
    save_image(rgba, "dust_puff.png")

if __name__ == "__main__":
    print("Generating procedural VFX particle textures...")
    gen_glow_soft()
    gen_spark_star()
    gen_smoke_noise()
    gen_ring_sharp()
    gen_flame_tear()
    gen_snowflake_crystal()
    gen_lightning_flash()
    gen_magic_circle_runes()
    gen_light_mote()
    gen_shockwave_ring()
    gen_dust_puff()
    print("All 11 textures generated successfully!")
