from pathlib import Path
import bpy

scene = bpy.context.scene

# Closeup Camera
cam_data = bpy.data.cameras.new("Closeup_Camera")
cam_data.lens = 75
cam = bpy.data.objects.new("Closeup_Camera", cam_data)
bpy.context.scene.collection.objects.link(cam)

target = bpy.data.objects.get("Camera_Target")
if not target:
    target = bpy.data.objects.new("Camera_Target", None)
    bpy.context.scene.collection.objects.link(target)
target.location = (0.2, -0.2, 0.45)

cam.location = (0.8, -4.2, 0.9)
con = cam.constraints.new(type='TRACK_TO')
con.target = target
con.track_axis = 'TRACK_NEGATIVE_Z'
con.up_axis = 'UP_Y'

scene.camera = cam
scene.render.resolution_x = 1200
scene.render.resolution_y = 800
closeup_path = str(Path(__file__).resolve().parents[1] / 'previews/render_closeup.png')
scene.render.filepath = closeup_path
bpy.ops.render.render(write_still=True)
print(f"Rendered closeup to {closeup_path}")
