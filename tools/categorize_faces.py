from PIL import Image

tex = Image.open("assets/characters/wizard/Wizard_Texture.png").convert("RGB")
w, h = tex.size

# Let's inspect different regions of Wizard_Texture.png
# Quaternius textures are usually color palettes / UV islands
print("Texture dimensions:", w, h)

# Let's check how Wizard.001 is textured
# Let's read all faces of Wizard.001 and see which parts correspond to:
# - Robe
# - Skin (Hands & Face)
# - Hat
# - Shoes / Belts / etc.

with open("assets/downloads/rpg_characters/RPG Characters - Nov 2020/OBJ/Wizard.obj", "r") as f:
    verts = []
    uvs = []
    faces = []
    for line in f:
        if line.startswith("o Wizard_Staff"):
            break
        if line.startswith("v "):
            parts = line.strip().split()
            verts.append((float(parts[1]), float(parts[2]), float(parts[3])))
        elif line.startswith("vt "):
            parts = line.strip().split()
            uvs.append((float(parts[1]), float(parts[2])))
        elif line.startswith("f "):
            parts = line.strip().split()[1:]
            face_verts = []
            for p in parts:
                vals = p.split("/")
                v_i = int(vals[0]) - 1
                vt_i = int(vals[1]) - 1 if len(vals) > 1 and vals[1] else None
                face_verts.append((v_i, vt_i))
            faces.append(face_verts)

# Categorize faces by Y and sampled colors
categories = {"skin": 0, "robe": 0, "hat": 0, "other": 0}
for f in faces:
    ys = [verts[v_i][1] for v_i, _ in f]
    avg_y = sum(ys) / len(ys)
    # Sample UV
    f_colors = []
    for v_i, vt_i in f:
        if vt_i is not None and vt_i < len(uvs):
            u, v = uvs[vt_i]
            px = int(u * (w - 1)) % w
            py = int((1.0 - v) * (h - 1)) % h
            f_colors.append(tex.getpixel((px, py)))
    
    if not f_colors:
        continue
    r = sum(c[0] for c in f_colors) / len(f_colors)
    g = sum(c[1] for c in f_colors) / len(f_colors)
    b = sum(c[2] for c in f_colors) / len(f_colors)
    
    # Check if skin
    # Skin in Quaternius is warm peach / flesh: r > 120, g > 80, b > 50, r > b + 25
    if (r > 120 and g > 80 and b > 50 and r > b + 25) or (r > 100 and g > 70 and b > 40 and r > b + 30):
        categories["skin"] += 1
    elif avg_y > 2.6:
        categories["hat"] += 1
    elif b > r and b > g:
        categories["robe"] += 1
    else:
        categories["other"] += 1

print("Categories in Wizard.001 faces:", categories)
