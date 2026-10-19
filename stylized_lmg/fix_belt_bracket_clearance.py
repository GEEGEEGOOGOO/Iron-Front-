"""Resolve the cartridge/bracket intersection in the live corrected LMG."""
import bpy
import os
from mathutils import Vector
s = bpy.context.scene
out = '/Users/shashankkumar/Desktop/Game Development/stylized_lmg'
bracket = bpy.data.objects['MOUNT | reverse top bracket']
assert bracket.name in s.objects
backup = os.path.join(out, 'LMG_Before_Belt_Clearance_Fix.blend')
if not os.path.exists(backup):
    bpy.ops.wm.save_as_mainfile(filepath=backup, copy=True)
bracket.location.x = -.38
bracket.dimensions.x = .12
bpy.context.view_layer.objects.active = bracket
bracket.select_set(True)
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
bridge = s.objects.get('MOUNT | outside return bridge')
if not bridge:
    bpy.ops.mesh.primitive_cube_add(location=(-.16,.84,.13))
    bridge=bpy.context.object
    bridge.name='MOUNT | outside return bridge'
    bridge.dimensions=(.56,.055,.10)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    bridge.parent=bracket.parent
    bridge.data.materials.append(bracket.active_material)
    bevel=bridge.modifiers.new('Steel edge rounding','BEVEL');bevel.width=.012;bevel.segments=3
    bridge.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
bpy.context.view_layer.update()

def bounds(o):
    mesh=o.evaluated_get(bpy.context.evaluated_depsgraph_get())
    points=[mesh.matrix_world@Vector(v) for v in mesh.bound_box]
    return [(min(p[i] for p in points),max(p[i] for p in points)) for i in range(3)]

hits=[]
for mount in [o for o in s.objects if o.name.startswith('MOUNT |')]:
    a=bounds(mount)
    for belt in [o for o in s.objects if o.name.startswith('BELT WRAP |')]:
        b=bounds(belt)
        if all(min(a[i][1],b[i][1])-max(a[i][0],b[i][0])>0 for i in range(3)):
            hits.append((mount.name,belt.name))
assert not hits, 'Mount/belt bounding intersections: '+str(hits)
s['Belt clearance']='Rear bracket repositioned behind cartridge bases, return bridge outside belt envelope; bounds checked'
hero=s.camera
camera=next(o for o in s.objects if o.name.startswith('CAM | feed and optic'))
old_scale=camera.data.ortho_scale
camera.data.ortho_scale=2.9
s.camera=camera
s.render.filepath=os.path.join(out,'lmg_belt_clearance_closeup.png')
bpy.ops.render.render(write_still=True)
camera.data.ortho_scale=old_scale
s.camera=hero
s.render.filepath=os.path.join(out,'lmg_sheet_corrected_hero.png')
bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out,'LMG_Refined.blend'))
print('BELT_CLEARANCE_PASS: all mounting parts clear of cartridge, tip and link bounds')
