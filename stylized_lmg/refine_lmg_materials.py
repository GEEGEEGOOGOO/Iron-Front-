"""Apply reference palette to the active refined LMG, preserving its geometry.
Run inside Blender. Saves a pre-material backup and the updated working file.
"""
import bpy
import os

OUT = '/Users/shashankkumar/Desktop/Game Development/stylized_lmg'
scene = bpy.context.scene
assert scene.name.startswith('LMG | Reference Rebuild'), 'Select the refined LMG scene first'
backup = os.path.join(OUT, 'LMG_Before_Material_Refinement.blend')
if not os.path.exists(backup):
    bpy.ops.wm.save_as_mainfile(filepath=backup, copy=True)

def surface(name, color, metallic, roughness, texture=0.0, glow=0.0):
    mat = bpy.data.materials.new('LMG REF | ' + name)
    mat.use_nodes = True
    mat.diffuse_color = (*color, 1)
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = next(n for n in nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs['Base Color'].default_value = (*color, 1)
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Roughness'].default_value = roughness
    if glow:
        bsdf.inputs['Emission Color'].default_value = (*color, 1)
        bsdf.inputs['Emission Strength'].default_value = glow
    if texture:
        noise = nodes.new('ShaderNodeTexNoise')
        noise.inputs['Scale'].default_value = 210
        noise.inputs['Detail'].default_value = 2
        ramp = nodes.new('ShaderNodeMapRange')
        ramp.inputs['To Min'].default_value = roughness - .04
        ramp.inputs['To Max'].default_value = roughness + .05
        links.new(noise.outputs['Fac'], ramp.inputs['Value'])
        links.new(ramp.outputs[0], bsdf.inputs['Roughness'])
        bump = nodes.new('ShaderNodeBump')
        bump.inputs['Strength'].default_value = texture
        bump.inputs['Distance'].default_value = .0012
        links.new(noise.outputs['Fac'], bump.inputs['Height'])
        links.new(bump.outputs['Normal'], bsdf.inputs['Normal'])
    return mat

olive = surface('olive sage satin paint', (.105,.13,.065), .38,.40,.08)
inset = surface('olive sage grip inlay', (.125,.165,.112), .05,.58,.12)
charcoal = surface('matte charcoal coated metal', (.024,.027,.030), .50,.46,.05)
rubber = surface('charcoal rubber butt pad', (.014,.016,.017), 0,.72,.08)
steel = surface('weathered satin gunmetal steel', (.26,.285,.30), .92,.30,.06)
darksteel = surface('dark gunmetal barrel', (.09,.105,.12), .93,.28,.04)
teal = surface('deep petrol teal painted metal', (.028,.095,.105), .48,.36,.07)
brass = surface('polished brass casings', (.57,.335,.105), .96,.23,.025)
copper = surface('polished copper tips', (.62,.265,.105), .95,.22,.025)
amber = surface('warm amber optic', (1,.30,.012), .10,.19,glow=.65)
lamp = surface('warm amber indicator', (1,.265,.008), .05,.26,glow=3)
fabric = surface('olive woven ammunition bag', (.18,.205,.115), 0,.78)
# Fine crossed weave, not an expensive displacement or image texture.
nodes, links = fabric.node_tree.nodes, fabric.node_tree.links
waves = []
for direction in ('X', 'Y'):
    wave = nodes.new('ShaderNodeTexWave')
    wave.bands_direction = direction
    wave.inputs['Scale'].default_value = 145
    waves.append(wave)
mix = nodes.new('ShaderNodeMath'); mix.operation = 'MULTIPLY'
for i, wave in enumerate(waves):
    links.new(wave.outputs['Fac'], mix.inputs[i])
bump = nodes.new('ShaderNodeBump')
bump.inputs['Strength'].default_value = .16
bump.inputs['Distance'].default_value = .0013
links.new(mix.outputs[0], bump.inputs['Height'])
links.new(bump.outputs['Normal'], next(n for n in nodes if n.type == 'BSDF_PRINCIPLED').inputs['Normal'])

counts = {}
for obj in scene.objects:
    if obj.type != 'MESH':
        continue
    name = obj.name
    old = obj.data.materials[0].name.lower() if obj.data.materials else ''
    # Semantic assignment prevents accidental shared-material edits to other scenes.
    mat = olive
    if 'black rubber' in old: mat = rubber
    elif 'dark machined' in old: mat = charcoal
    elif 'brushed exposed' in old or 'protective bronze' in old: mat = steel
    elif 'blue green' in old: mat = teal
    elif 'olive recessed' in old: mat = olive
    elif 'cartridge brass' in old: mat = brass
    elif 'copper projectile' in old: mat = copper
    elif 'amber glass' in old: mat = amber
    elif 'orange status' in old: mat = lamp
    if name.startswith('RAIL |'): mat = charcoal
    if name.startswith('GRIP | swept'): mat = charcoal
    if name.startswith('GRIP | inset'): mat = inset
    if name.startswith('STOCK | contoured buttpad'): mat = rubber
    if name.startswith('STOCK | steel connecting'): mat = steel
    if name.startswith('TRIGGER |'): mat = charcoal
    if name.startswith('MAGAZINE | olive fabric'): mat = fabric
    if name.startswith('MAGAZINE | main box'): mat = fabric
    if name.startswith('BARREL |'):
        mat = charcoal if 'gas tube' in name else darksteel
    if name.startswith('BELT | bright cartridge'): mat = brass
    if name.startswith('BELT | dark linking'): mat = steel
    if name.startswith('HANDGUARD | central steel seam'): mat = darksteel
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    counts[mat.name] = counts.get(mat.name, 0) + 1

scene['Material reference'] = 'Olive/sage paint; charcoal matte; petrol teal; gunmetal steel; brass/copper; warm amber only'
for area in bpy.context.screen.areas:
    if area.type == 'VIEW_3D':
        area.spaces.active.shading.type = 'RENDERED'
hero = next(o for o in scene.objects if o.name.startswith('CAM | hero'))
scene.camera = hero
scene.view_settings.exposure = -.35
# Smaller studio sources reveal satin metal reflections without bleaching the paint.
for obj in scene.objects:
    if obj.type == 'LIGHT':
        if 'Key' in obj.name: obj.data.size = 3.0
        elif 'Rim' in obj.name: obj.data.size = 2.5
scene.render.filepath = os.path.join(OUT, 'lmg_material_refined_hero.png')
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, 'LMG_Refined.blend'))
bpy.ops.render.render(write_still=True)
print('MATERIAL_REFINEMENT_COMPLETE', counts)
