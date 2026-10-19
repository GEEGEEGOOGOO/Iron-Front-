"""Reference-led editable LMG rebuild. Run in Blender; never resets preferences.

Keeps the source scene and writes a separate .blend and three review renders.
Coordinates trace the supplied 758px reference: rear at -X, muzzle at +X.
"""
import bpy
import bmesh
import math
import os
from mathutils import Vector

OUT = '/Users/shashankkumar/Desktop/Game Development/stylized_lmg'
os.makedirs(OUT, exist_ok=True)
previous = bpy.context.scene
backup = os.path.join(OUT, 'original_before_codex.blend')
if not os.path.exists(backup):
    bpy.ops.wm.save_as_mainfile(filepath=backup, copy=True)
scene = bpy.data.scenes.new('LMG | Reference Rebuild')
bpy.context.window.scene = scene
parts = []

def material(name, color, metallic=0.0, roughness=.4, emission=0):
    mat = bpy.data.materials.new('LMG2 | ' + name)
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs['Base Color'].default_value = (*color, 1)
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Roughness'].default_value = roughness
    mat.diffuse_color = (*color, 1)
    if emission:
        bsdf.inputs['Emission Color'].default_value = (*color, 1)
        bsdf.inputs['Emission Strength'].default_value = emission
    return mat

olive = material('satin olive receiver', (.155, .175, .105), .52, .37)
darkolive = material('olive recessed armor', (.105, .125, .075), .38, .43)
metal = material('dark machined steel', (.055, .065, .075), .88, .29)
edge = material('brushed exposed steel', (.32, .35, .36), .90, .28)
teal = material('blue green vented armor', (.035, .105, .115), .62, .37)
rubber = material('black rubber and recesses', (.009, .013, .014), .08, .58)
brass = material('cartridge brass', (.53, .29, .08), .86, .26)
copper = material('copper projectile tips', (.57, .21, .075), .85, .25)
bronze = material('magazine protective bronze', (.24, .19, .12), .76, .38)
amber = material('amber glass', (.8, .22, .015), .30, .18, .55)
lamp = material('orange status lamps', (1, .19, .005), .15, .3, 2.6)

for mat in (olive, darkolive, metal, edge, teal, bronze):
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
    tex = nt.nodes.new('ShaderNodeTexNoise')
    tex.inputs['Scale'].default_value = 180
    tex.inputs['Detail'].default_value = 2
    bump = nt.nodes.new('ShaderNodeBump')
    bump.inputs['Strength'].default_value = .12
    bump.inputs['Distance'].default_value = .003
    nt.links.new(tex.outputs['Fac'], bump.inputs['Height'])
    nt.links.new(bump.outputs['Normal'], bsdf.inputs['Normal'])

def finish(obj, mat, width=.02):
    obj.data.materials.append(mat)
    parts.append(obj)
    if width:
        bevel = obj.modifiers.new('Small machined edge radii', 'BEVEL')
        bevel.width = width
        bevel.segments = 3
        obj.modifiers.new('Weighted corner normals', 'WEIGHTED_NORMAL')
    return obj

def box(name, location, dimensions, mat, width=.02):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, mat, width)

def profile(name, pixels, depth, mat, y=0, width=.02):
    pts = [((x - 355) / 100, (155 - z) / 100) for x, z in pixels]
    n = len(pts)
    verts = [(x, y + dy, z) for dy in (-depth/2, depth/2) for x, z in pts]
    faces = [tuple(reversed(range(n))), tuple(range(n, 2*n))]
    faces += [(i, (i+1) % n, (i+1) % n+n, i+n) for i in range(n)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    scene.collection.objects.link(obj)
    return finish(obj, mat, width)

def cylinder(name, loc, radius, depth, mat, axis='X', width=.008):
    rotation = {'X': (0, math.pi/2, 0), 'Y': (math.pi/2, 0, 0), 'Z': (0, 0, 0)}[axis]
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=radius, depth=depth, location=loc, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    for face in obj.data.polygons:
        face.use_smooth = len(face.vertices) == 4
    return finish(obj, mat, width)

def cut(obj, tool):
    # Run booleans before finishing bevel/normal modifiers.
    bpy.context.view_layer.objects.active = obj
    mod = obj.modifiers.new('Machined aperture', 'BOOLEAN')
    mod.object = tool
    while list(obj.modifiers).index(mod) > 0:
        bpy.ops.object.modifier_move_up(modifier=mod.name)
    bpy.ops.object.modifier_apply(modifier=mod.name)
    if tool in parts:
        parts.remove(tool)
    bpy.data.objects.remove(tool, do_unlink=True)

def rounded_tool(loc, dims, radius):
    obj = box('temporary round aperture', loc, dims, rubber, radius)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=obj.modifiers[0].name)
    return obj

# STOCK: trace the stepped cheek and lower triangular contour, not a flat slab.
profile('STOCK | shaped olive chassis', [(65,105),(80,103),(96,110),(109,120),(184,120),(187,143),(137,155),(105,190),(89,217),(66,218)], .41, olive, width=.035)
profile('STOCK | recessed black web', [(86,127),(111,134),(178,134),(178,146),(133,149),(104,182),(90,201),(90,151)], .014, rubber, -.218, .015)
profile('STOCK | inset reverse web', [(86,127),(111,134),(178,134),(178,146),(133,149),(104,182),(90,201),(90,151)], .014, rubber, .218, .015)
profile('STOCK | contoured buttpad', [(57,100),(68,100),(70,220),(57,223),(51,216),(54,164),(51,112)], .49, metal, width=.025)
for z in [.40, -.48]:
    for side in [-1,1]:
        cylinder('STOCK | recessed screw', (-2.72, side*.231, z), .035, .018, edge, 'Y')
box('STOCK | steel connecting collar', (-1.60,0,.13), (.28,.51,.49), metal, .045)
box('STOCK | slim olive spacer', (-1.43,0,.13), (.08,.54,.52), olive, .015)

# RECEIVER: faceted upper shell, lower frame and a genuine cut feed opening.
receiver = profile('RECEIVER | stepped main housing', [(215,117),(228,105),(376,105),(395,117),(395,172),(229,172),(215,157)], .56, olive, width=.027)
cut(receiver, rounded_tool((-.125,-.225,.14), (.72,.30,.54), .025))
box('FEED | deep feedway shadow', (-.125,-.071,.14), (.70,.012,.51), rubber, .015)
profile('RECEIVER | top cover facets', [(231,105),(374,105),(387,112),(234,112)], .58, darkolive, width=.015)
for side in [-1,1]:
    profile('RECEIVER | lower side contour', [(231,145),(284,145),(292,156),(291,171),(238,169),(231,161)], .015, darkolive, side*.288, .012)
    cylinder('RECEIVER | receiver pin', (-.94,side*.302,-.05), .042,.02,edge,'Y')
    box('RECEIVER | narrow rear band', (-1.30,side*.30,.15), (.09,.045,.58),edge,.014)
box('FEED | port sill',(-.12,-.31,-.155),(.78,.06,.06),metal,.012)
box('FEED | port upper lip',(-.12,-.31,.435),(.78,.06,.055),edge,.012)

# Trigger guard cutout and swept-back grip.
guard = box('TRIGGER | thin guard',(-.63,0,-.35),(.68,.25,.35),metal,0)
cut(guard,rounded_tool((-.63,0,-.34),(.51,.65,.23),.06))
bevel=guard.modifiers.new('Guard edge rounding','BEVEL');bevel.width=.018;bevel.segments=3
profile('GRIP | swept pistol grip',[(249,175),(283,183),(273,210),(265,240),(270,252),(257,260),(218,245),(215,237)],.29,metal,width=.026)
for side in [-1,1]:
    profile('GRIP | inset green panel',[(245,194),(263,199),(250,238),(230,231)],.018,darkolive,side*.153,.014)
profile('TRIGGER | curved blade',[(278,177),(286,178),(283,187),(285,194),(279,195),(275,187)],.08,edge,width=.008)

# MAGAZINE: beveled olive box, protective bronze perimeter and circular end cap.
box('MAGAZINE | main box',(-.14,0,-.715),(.80,.82,.85),olive,.065)
for side in [-1,1]:
    box('MAGAZINE | bronze protective lip',(-.14,side*.42,-.715),(.81,.022,.84),bronze,.045)
    box('MAGAZINE | olive fabric face',(-.17,side*.437,-.715),(.65,.014,.72),olive,.03)
box('MAGAZINE | bottom bumper',(-.14,0,-1.118),(.80,.84,.075),bronze,.025)
box('MAGAZINE | feed connector',(-.13,0,-.24),(.65,.48,.17),metal,.02)
cylinder('MAGAZINE | end cap ring',(.27,0,-.715),.365,.045,bronze,'X')
cylinder('MAGAZINE | end cap dark inset',(.30,0,-.715),.310,.016,metal,'X')
cylinder('MAGAZINE | end cap olive disk',(.315,0,-.715),.267,.012,olive,'X')
cylinder('MAGAZINE | end cap center',(.33,0,-.715),.095,.018,bronze,'X')
# Asymmetric latch/strap on the reverse side from the new model sheet.
box('MOUNT | reverse latch backing',(-.17,.46,-.37),(.36,.06,.76),metal,.025)
box('MOUNT | reverse raised strap',(-.17,.50,-.30),(.20,.035,.56),edge,.012)
box('MOUNT | strap shadow',(-.17,.524,-.30),(.12,.012,.45),metal,.008)
box('MOUNT | upper attachment bar',(-.17,.39,.13),(.45,.12,.10),edge,.012)
box('MOUNT | lower latch foot',(-.17,.51,-.68),(.38,.07,.12),edge,.022)
for x in [-.28,-.06]:
    cylinder('MOUNT | latch fastener',(x,.555,-.66),.034,.024,metal,'Y')

# Five close-set cartridges from the side-view model sheet.
for i in range(5):
    z=.265-i*.107
    box('BELT | dark linking tab',(-.23,-.345,z),(.18,.075,.106),metal,.012)
    cylinder('BELT | bright cartridge case',(-.245,-.403,z),.050,.29,edge)
    cylinder('BELT | brass case neck',(-.075,-.403,z),.046,.065,brass)
    bpy.ops.mesh.primitive_cone_add(vertices=40,radius1=.046,radius2=.011,depth=.15,location=(.032,-.403,z),rotation=(0,math.pi/2,0))
    tip=bpy.context.object;tip.name='BELT | copper bullet tip';finish(tip,copper,.006)
    cylinder('BELT | brass cartridge rim',(-.397,-.403,z),.055,.018,brass)

# HANDGUARD: faceted steel shell and teal plates with two rows of open slots.
profile('HANDGUARD | upper steel spine',[(399,104),(550,104),(561,115),(557,137),(399,137)],.62,metal,width=.025)
profile('HANDGUARD | lower steel spine',[(399,140),(557,140),(556,165),(544,177),(402,177)],.61,metal,width=.025)
for side in [-1,1]:
    panel=box('HANDGUARD | teal perforated plate',(.67+.59,side*.32,.15),(1.55,.055,.48),teal,.018)
    for row,z in enumerate([.30,.015]):
        for j in range(5):
            x=.88+j*.23
            cut(panel,rounded_tool((x,side*.32,z),(.145,.19,.065),.025))
    box('HANDGUARD | central steel seam',(1.26,side*.36,.15),(1.54,.018,.04),edge,.006)
    box('HANDGUARD | olive lower rim',(1.25,side*.32,-.175),(1.52,.07,.065),olive,.012)
for z in [.28,.04]:
    cylinder('BARREL | inner barrel visible through slots',(1.45,0,z),.13,2.2,metal)
for x in [.51,2.01]:
    box('HANDGUARD | protective end band',(x,0,.10),(.105,.70,.64),olive,.018)

# Rail follows receiver and shroud, with low-profile teeth.
for start,end in [(-1.03,.39),(.55,2.00)]:
    box('RAIL | machined spine',((start+end)/2,0,.575),(end-start,.23,.065),metal,.008)
    count=int((end-start)/.115)
    for i in range(count):
        box('RAIL | cross tooth',(start+.045+i*.115,0,.623),(.068,.30,.045),edge,.006)

# Forward barrel stack, hollow front sight ring, and actual slotted muzzle brake.
cylinder('BARREL | large shoulder',(2.24,0,.28),.19,.37,metal)
cylinder('BARREL | forward tube',(2.80,0,.28),.115,1.00,edge)
cylinder('BARREL | lower gas tube',(2.38,0,.025),.11,.72,metal)
cylinder('BARREL | gas block collar',(2.50,0,.16),.22,.14,edge)
profile('SIGHT | front tower',[(598,147),(598,115),(605,100),(620,100),(623,148)],.16,edge,width=.012)
front=cylinder('SIGHT | hollow front aperture',(2.54,0,.675),.105,.16,edge)
cut(front,cylinder('sight bore tool',(2.54,0,.675),.058,.4,rubber,width=0))
brake=cylinder('MUZZLE | slotted steel brake',(3.43,0,.28),.165,.49,edge,width=0)
cut(brake,cylinder('muzzle bore tool',(3.43,0,.28),.108,.8,rubber,width=0))
for side in [-1,1]:
    for x in [3.28,3.43,3.58]:
        cut(brake,rounded_tool((x,side*.145,.28),(.065,.16,.23),.022))
bevel=brake.modifiers.new('Muzzle chamfers','BEVEL');bevel.width=.009;bevel.segments=3
cylinder('MUZZLE | deep bore shadow',(3.16,0,.28),.105,.008,rubber)

# Compact amber optic: actual opening, slanted hood, clamp, and capped adjustment.
box('OPTIC | rail clamp',(-.12,0,.70),(.63,.35,.12),metal,.015)
cylinder('OPTIC | mounting crossbolt',(-.15,-.22,.70),.043,.05,edge,'Y')
hood=profile('OPTIC | sloped protective hood',[(349,80),(349,70),(367,41),(397,41),(403,46),(403,80)],.32,olive,width=.018)
cut(hood,rounded_tool((.34,0,.965),(.82,.232,.235),.035))
box('OPTIC | orange glass lens',(.452,0,.965),(.018,.213,.215),amber,.028)
rim=box('OPTIC | hollow front steel rim',(.49,0,.965),(.07,.36,.38),metal,.025)
cut(rim,rounded_tool((.49,0,.965),(.20,.25,.28),.035))
box('OPTIC | exposed amber front lens',(.532,0,.965),(.012,.244,.272),amber,.025)
box('OPTIC | side electronics housing',(-.12,0,.835),(.43,.29,.19),darkolive,.035)
cylinder('OPTIC | side adjustment',(.07,-.185,.835),.067,.085,edge,'Y')
cylinder('OPTIC | adjustment inset',(.07,-.233,.835),.035,.012,metal,'Y')
box('OPTIC | rear mount',(-.27,0,.73),(.10,.38,.08),metal,.014)
profile('REAR SIGHT | trapezoid block',[(250,98),(258,84),(271,84),(286,98)],.26,metal,width=.014)
for x,z in [(-.92,.645),(.76,.345)]:
    box('STATUS | inset bezel',(x,-.347,z),(.16,.022,.11),rubber,.015)
    box('STATUS | amber status lens',(x,-.362,z),(.09,.012,.05),lamp,.008)

# Editable hierarchy; no global subdivision on the assembled model.
bpy.ops.object.empty_add()
root=bpy.context.object;root.name='LMG | editable asset root'
for obj in parts:
    obj.parent=root
root['Reference']='Supplied olive/teal belt-fed LMG concept'
root['Notes']='Separate parts; genuine feed, guard, shroud and muzzle apertures.'
scene.world=bpy.data.worlds.new('LMG2 | black studio')
scene.world.use_nodes=True
bg=next(n for n in scene.world.node_tree.nodes if n.type=='BACKGROUND')
bg.inputs['Color'].default_value=(.008,.008,.009,1)
bg.inputs['Strength'].default_value=.25

def aim(obj, target):
    obj.rotation_euler=(Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()
def camera(name, loc, target, scale):
    bpy.ops.object.camera_add(location=loc)
    obj=bpy.context.object;obj.name=name;obj.data.type='ORTHO';obj.data.ortho_scale=scale;aim(obj,target)
    return obj
hero=camera('CAM | hero', (3.5,-11,2.0),(.25,0,0),7.8)
side=camera('CAM | side',(.25,-12,.0),(.25,0,0),7.5)
close=camera('CAM | feed and optic',(.7,-5,1.4),(-.05,-.1,.12),3.2)
for name,loc,energy,size in [('Key',(-1,-4,5),1000,5),('Rim',(1,3,4),1400,4),('Front',(5,-3,2),650,3),('Stock',(-4,-2,1),250,2)]:
    bpy.ops.object.light_add(type='AREA',location=loc)
    obj=bpy.context.object;obj.name='LIGHT | '+name;obj.data.energy=energy;obj.data.shape='DISK';obj.data.size=size;aim(obj,(0,0,0))
scene.render.engine=previous.render.engine
scene.render.resolution_x=1800;scene.render.resolution_y=850;scene.render.resolution_percentage=100
scene.render.film_transparent=False
bpy.ops.object.select_all(action='DESELECT')
root.select_set(True);bpy.context.view_layer.objects.active=root
for area in bpy.context.screen.areas:
    if area.type=='VIEW_3D':
        area.spaces.active.shading.type='RENDERED'
        area.spaces.active.region_3d.view_perspective='CAMERA'
        area.spaces.active.overlay.show_overlays=False
for cam,filename in [(hero,'lmg_refined_hero.png'),(side,'lmg_refined_side.png'),(close,'lmg_refined_closeup.png')]:
    scene.camera=cam
    scene.render.filepath=os.path.join(OUT,filename)
    bpy.ops.render.render(write_still=True)
scene.camera=hero
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'LMG_Refined.blend'))
print('LMG_REBUILD_COMPLETE',len(parts),'editable objects; source preserved at',backup)
