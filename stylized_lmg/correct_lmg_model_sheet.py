"""Geometry corrections from the latest six-view LMG sheet; active scene only."""
import bpy
import math
import os
from mathutils import Vector
OUT = '/Users/shashankkumar/Desktop/Game Development/stylized_lmg'
s = bpy.context.scene
assert s.name.startswith('LMG | Reference Rebuild')
assert not s.get('Six-view corrections'), 'Corrections already applied'
backup = os.path.join(OUT, 'LMG_Before_Six_View_Corrections.blend')
if not os.path.exists(backup): bpy.ops.wm.save_as_mainfile(filepath=backup, copy=True)
root = next(o for o in s.objects if o.name.startswith('LMG | editable asset root'))
def mat(term):
    return next(m for m in bpy.data.materials if m.name.startswith('LMG REF | '+term))
olive, steel, dark, fabric = mat('olive sage satin'),mat('weathered satin'),mat('matte charcoal'),mat('olive woven')
brass, copper = mat('polished brass'), mat('polished copper')

# Correct longitudinal silhouette using sheet landmarks rather than global scaling.
landmarks = [(-3.04,36),(-1.43,158),(.50,300),(2.06,395),(2.54,426),(3.675,496)]
def trace_x(x):
    for (a,pa),(b,pb) in zip(landmarks,landmarks[1:]):
        if x <= b:
            pixel = pa+(x-a)/(b-a)*(pb-pa)
            return -3.04+(pixel-36)*6.715/460
    return x
for o in list(s.objects):
    if o.type != 'MESH': continue
    world, inv = o.matrix_world.copy(), o.matrix_world.inverted()
    for v in o.data.vertices:
        p=world@v.co
        p.x=trace_x(p.x)
        v.co=inv@p
    o.data.update()

# Replace only the outdated narrow magazine, retaining all unrelated parts.
for o in list(s.objects):
    if o.type=='MESH' and (o.name.startswith('MAGAZINE |') or o.name.startswith('MOUNT |') or o.name.startswith('BELT |')):
        bpy.data.objects.remove(o,do_unlink=True)

def finish(o, material, bevel=.015):
    o.parent=root
    o.data.materials.append(material)
    if bevel:
        b=o.modifiers.new('Reference edge radii','BEVEL');b.width=bevel;b.segments=3
        o.modifiers.new('Weighted surface normals','WEIGHTED_NORMAL')
    return o
def box(name,loc,dims,material,bevel=.015):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    o=bpy.context.object;o.name=name;o.dimensions=dims
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(o,material,bevel)
def cyl(name,loc,radius,depth,material):
    bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=radius,depth=depth,location=loc,rotation=(0,math.pi/2,0))
    o=bpy.context.object;o.name=name
    for p in o.data.polygons:p.use_smooth=len(p.vertices)==4
    return finish(o,material,.007)
def end_profile(name,x,depth,cy,cz,width,height,chamfer,material):
    w,h,c=width/2,height/2,chamfer
    pts=[(-w+c,-h),(w-c,-h),(w,-h+c),(w,h-c),(w-c,h),(-w+c,h),(-w,h-c),(-w,-h+c)]
    verts=[(x+dx,cy+y,cz+z) for dx in [-depth/2,depth/2] for y,z in pts]
    faces=[tuple(reversed(range(8))),tuple(range(8,16))]+[(i,(i+1)%8,(i+1)%8+8,i+8) for i in range(8)]
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    o=bpy.data.objects.new(name,mesh);s.collection.objects.link(o)
    return finish(o,material,.014)

xc=.07; cy=.10; cz=-.735
end_profile('MAGAZINE | wide olive ammunition box',xc,.69,cy,cz,1.79,.91,.10,fabric)
for x in [xc-.355,xc+.355]:
    end_profile('MAGAZINE | chamfered steel perimeter',x,.045,cy,cz,1.84,.96,.11,steel)
    end_profile('MAGAZINE | inset olive end panel',x+(-.026 if x<xc else .026),.012,cy,cz,1.73,.85,.085,olive)
for y in [cy-.907,cy+.907]:
    box('MAGAZINE | folded steel side border',(xc,y,cz),(.70,.035,.80),steel,.018)
    box('MAGAZINE | olive side insert',(xc,cy+(-.935 if y<cy else .935),cz),(.59,.022,.68),fabric,.02)
# Circular cap is offset to one half of the wide front face, as the front view shows.
for name,x,r,d,m in [('outer ring',.477,.405,.035,steel),('dark annulus',.501,.353,.018,dark),('olive disk',.516,.31,.015,olive),('inner rim',.529,.165,.014,steel),('center olive cap',.54,.133,.015,olive)]:
    cyl('MAGAZINE | offset '+name,(x,.49,cz),r,d,m)
box('MAGAZINE | feed neck',(.07,.10,-.245),(.57,.55,.18),dark,.025)
# Right-side strap, attachment bracket and pins.
box('MOUNT | reverse top bracket',(-.38,.55,.13),(.12,.65,.10),steel)
box('MOUNT | outside return bridge',(-.16,.84,.13),(.56,.055,.10),steel)
box('MOUNT | vertical reverse strap',(.04,.84,-.23),(.26,.055,.66),steel,.02)
box('MOUNT | latch foot',(.04,1.065,-.61),(.44,.065,.17),steel,.025)
for x in [-.09,.17]:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,radius=.031,location=(x,1.11,-.61))
    finish(bpy.context.object,dark,0).name='MOUNT | latch rivet'

# Belt return arcs: rounds seen end-on from front and rear, instead of a flat stack.
for side in [-1,1]:
    for i in range(7):
        t=i/6
        y=side*(.33+.33*math.sin(t*math.pi/2))+.06
        z=.28-.57*t
        x=-.12
        cyl('BELT WRAP | brass case',(x,y,z),.047,.29,brass)
        cyl('BELT WRAP | rear primer rim',(x-.155,y,z),.053,.018,brass)
        bpy.ops.mesh.primitive_cone_add(vertices=24,radius1=.045,radius2=.010,depth=.12,location=(x+.20,y,z),rotation=(0,math.pi/2,0))
        finish(bpy.context.object,copper,.004).name='BELT WRAP | copper tip'
        box('BELT WRAP | steel feed link',(x-.04,y,z),(.075,.112,.035),dark,.005)

# Steel buttplate rim surrounding the charcoal pad, rather than a solid black slab.
pad=next(o for o in s.objects if o.name.startswith('STOCK | contoured buttpad'))
pad.data.materials.clear();pad.data.materials.append(steel)
core=pad.copy();core.data=pad.data.copy();s.collection.objects.link(core);core.name='STOCK | inset charcoal buttpad core'
core.data.materials.clear();core.data.materials.append(mat('charcoal rubber'))
coords=[v.co.copy() for v in core.data.vertices];center=sum(coords,Vector())/len(coords)
for v in core.data.vertices:
    v.co.x=center.x+(v.co.x-center.x)*.68
    v.co.z=center.z+(v.co.z-center.z)*.91
    v.co.y*=1.025
# Optic should read as a shallow rounded housing with a recessed amber window.
for o in s.objects:
    if o.type=='MESH' and o.name.startswith('OPTIC |'):
        for modifier in o.modifiers:
            if modifier.type=='BEVEL':modifier.width=max(modifier.width,.024)
# Keep the charcoal rail finish, with subtly exposed steel tooth edges.
for o in s.objects:
    if o.type=='MESH' and o.name.startswith('RAIL | cross tooth'):
        for modifier in o.modifiers:
            if modifier.type=='BEVEL': modifier.width=.009

s['Six-view corrections']='Wide chamfered magazine; offset cap; bilateral feed belt; traced length landmarks; steel butt rim'
hero=next(o for o in s.objects if o.name.startswith('CAM | hero'))
s.camera=hero;s.render.filepath=os.path.join(OUT,'lmg_sheet_corrected_hero.png')
bpy.ops.object.select_all(action='DESELECT');root.select_set(True);bpy.context.view_layer.objects.active=root
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'LMG_Refined.blend'))
bpy.ops.render.render(write_still=True)
print('SIX_VIEW_CORRECTIONS_SAVED',len([o for o in s.objects if o.type=='MESH']))
