"""Run with Blender -b -P this_file -- pistol|shotgun|flame.

Exports evaluated weapon geometry only. Source .blend files are never saved.
Small portable wear maps replace Blender-only procedural shader graphs.
"""
import bpy
import math
import os
import sys
from mathutils import Vector, noise

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KIND = sys.argv[sys.argv.index("--") + 1]
CONFIG = {
    "pistol": ("Pistol_Animated.blend", (.70, 0, 1.50), 1.0 / (4.46 - .70)),
    "shotgun": ("Shotgun_Animated.blend", (-1.10, 0, .40), 1.25 / (5.10 + 1.10)),
    "flame": ("Flamethrower_Animated.blend", (.05, 0, 1.20), 1.20 / (4.18 - .05)),
}
filename, anchor, scale = CONFIG[KIND]
bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT, filename))
scene = bpy.context.scene
scene.frame_set(1)
output = os.path.join(ROOT, "assets", "models", "weapons")
os.makedirs(output, exist_ok=True)
deps = bpy.context.evaluated_depsgraph_get()
anchor = Vector(anchor)
groups = {}
for obj in list(scene.objects):
    if obj.type not in {"MESH", "CURVE"}:
        continue
    name = obj.name
    if name.startswith(("FX |", "PLUME |", "AMMO |", "FUEL |", "TEST TARGET", "SIM |")):
        continue
    if any(word in name.lower() for word in ("floor", "ground", "backdrop", "presentation")):
        continue
    group = "Body"
    if KIND == "pistol" and name.startswith("SLIDE |"):
        group = "Slide"
    elif KIND == "shotgun" and name.startswith("PUMP |"):
        group = "Pump"
    elif name.startswith("TRIGGER |") and any(word in name.lower() for word in ("blade", "shoe")):
        group = "Trigger"
    evaluated = obj.evaluated_get(deps)
    mesh = bpy.data.meshes.new_from_object(evaluated, depsgraph=deps)
    for vertex in mesh.vertices:
        vertex.co = (obj.matrix_world @ vertex.co - anchor) * scale
    copy = bpy.data.objects.new(group + "_part", mesh)
    groups.setdefault(group, []).append(copy)

# New scene avoids exporting cameras, lights, hidden scenes, or driver scripts.
export_scene = bpy.data.scenes.new("Weapon")
bpy.context.window.scene = export_scene
root = bpy.data.objects.new("BlenderWeapon", None)
export_scene.collection.objects.link(root)
materials = set()
for name, objects in groups.items():
    for obj in objects:
        export_scene.collection.objects.link(obj)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    obj.parent = root
    # Portable UVs for the compact material textures.
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(island_margin=.02)
    bpy.ops.object.mode_set(mode="OBJECT")
    materials.update(m for m in obj.data.materials if m)

for mat in materials:
    if not mat.use_nodes:
        continue
    nt = mat.node_tree
    bsdf = next((n for n in nt.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if not bsdf:
        continue
    base = tuple(bsdf.inputs["Base Color"].default_value)
    ramp = next((n for n in nt.nodes if n.type == "VALTORGB"), None)
    worn = mat.name.startswith("FT |") and ramp is not None
    if worn:
        base = tuple(ramp.color_ramp.elements[0].color)
    # Export only supported PBR nodes; retain authored metalness and glow.
    for link in list(nt.links):
        if link.to_node == bsdf and link.to_socket.name in ("Base Color", "Normal"):
            nt.links.remove(link)
    bsdf.inputs["Base Color"].default_value = base
    if worn:
        size = 128
        image = bpy.data.images.new("Wear_" + mat.name, width=size, height=size)
        pixels = []
        for y in range(size):
            for x in range(size):
                p = Vector((x / 18., y / 18., 1.73))
                n = noise.fractal(p, 1., 2., 4)
                rust = max(0., min(1., (n - .12) * 4.))
                grain = .91 + .09 * math.sin(x * 11.3 + y * 19.1)
                color = [((1-rust)*base[i] + rust*(.105,.038,.012)[i])*grain for i in range(3)]
                pixels.extend((*color, 1.))
        image.pixels = pixels
        image.pack()
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = image
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])

bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=os.path.join(output, KIND + ".glb"),
                          export_format="GLB", use_selection=True, use_active_scene=True,
                          export_animations=False, export_cameras=False,
                          export_lights=False)
print("WEAPON_EXPORT_OK", KIND, [(n, len(o)) for n, o in groups.items()])
