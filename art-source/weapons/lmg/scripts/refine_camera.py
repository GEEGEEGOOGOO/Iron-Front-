from pathlib import Path
import bpy
import math

scene = bpy.context.scene

# Create or find Target Empty
target_name = "Camera_Target"
if target_name in bpy.data.objects:
    target = bpy.data.objects[target_name]
else:
    target = bpy.data.objects.new(target_name, None)
    bpy.context.collection.objects.link(target)
target.location = (0.9, -0.1, 0.15)

# Update Hero Camera
cam = bpy.data.objects.get("Hero_Camera")
if cam:
    cam.location = (1.8, -7.6, 1.4)
    cam.data.lens = 52
    
    # Remove old constraints
    cam.constraints.clear()
    con = cam.constraints.new(type='TRACK_TO')
    con.target = target
    con.track_axis = 'TRACK_NEGATIVE_Z'
    con.up_axis = 'UP_Y'

# Set render resolution
scene.render.resolution_x = 1600
scene.render.resolution_y = 900

# Render hero view
scene.camera = cam
hero_path = str(Path(__file__).resolve().parents[1] / 'previews/render_hero.png')
scene.render.filepath = hero_path
bpy.ops.render.render(write_still=True)
print(f"Re-rendered Hero Image to {hero_path}")

# Save mainfile
bpy.ops.wm.save_as_mainfile(filepath=str(Path(__file__).resolve().parents[1] / 'models/stylized_lmg.blend'))
print("Saved blend file.")
