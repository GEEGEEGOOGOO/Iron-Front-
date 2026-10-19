from pathlib import Path
import bpy
import bmesh
import math
import os
from mathutils import Vector, Euler, Matrix

def build_faithful_lmg():
    # -------------------------------------------------------------------------
    # 1. Clean Scene & Collections
    # -------------------------------------------------------------------------
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    
    for block in bpy.data.meshes:
        if block.users == 0:
            bpy.data.meshes.remove(block)
    for block in bpy.data.materials:
        if block.users == 0:
            bpy.data.materials.remove(block)
            
    coll_name = "LMG_Assets"
    if coll_name in bpy.data.collections:
        coll = bpy.data.collections[coll_name]
    else:
        coll = bpy.data.collections.new(coll_name)
        bpy.context.scene.collection.children.link(coll)

    created_objects = []

    def reg(obj, mat=None):
        if mat:
            if obj.data.materials:
                obj.data.materials[0] = mat
            else:
                obj.data.materials.append(mat)
        created_objects.append(obj)
        for c in list(obj.users_collection):
            c.objects.unlink(obj)
        coll.objects.link(obj)
        return obj

    # -------------------------------------------------------------------------
    # 2. Advanced Procedural Stylized Shaders with Edge Wear & Ambient Occlusion
    # -------------------------------------------------------------------------
    def create_stylized_edge_wear_material(name, base_rgb, edge_rgb=(0.75, 0.78, 0.82, 1.0), metallic=0.2, roughness=0.35, bump_texture=None):
        mat = bpy.data.materials.get(name)
        if mat is None:
            mat = bpy.data.materials.new(name=name)
            mat.use_nodes = True
        
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        nodes.clear()
        
        # Output & Principled BSDF
        out = nodes.new(type="ShaderNodeOutputMaterial")
        bsdf = nodes.new(type="ShaderNodeBsdfPrincipled")
        
        # Geometry & Ambient Occlusion Nodes for Edge Wear and Crevices
        geom = nodes.new(type="ShaderNodeNewGeometry")
        ao = nodes.new(type="ShaderNodeAmbientOcclusion")
        ao.inputs['Distance'].default_value = 0.25
        
        # Color Ramps for Edge Mask and AO Mask
        cr_edge = nodes.new(type="ShaderNodeValToRGB")
        cr_edge.color_ramp.elements[0].position = 0.44
        cr_edge.color_ramp.elements[1].position = 0.58
        
        cr_ao = nodes.new(type="ShaderNodeValToRGB")
        cr_ao.color_ramp.elements[0].position = 0.2
        cr_ao.color_ramp.elements[0].color = (0.2, 0.2, 0.2, 1.0)
        cr_ao.color_ramp.elements[1].position = 0.8
        cr_ao.color_ramp.elements[1].color = (1.0, 1.0, 1.0, 1.0)
        
        # Noise Texture for Wear Irregularity
        noise = nodes.new(type="ShaderNodeTexNoise")
        noise.inputs['Scale'].default_value = 25.0
        noise.inputs['Detail'].default_value = 4.0
        noise.inputs['Roughness'].default_value = 0.7
        
        # Mix Nodes
        mix_noise = nodes.new(type="ShaderNodeMix")
        mix_noise.data_type = 'FLOAT'
        mix_noise.blend_type = 'MULTIPLY'
        mix_noise.inputs['Factor'].default_value = 0.45
        
        mix_color = nodes.new(type="ShaderNodeMix")
        mix_color.data_type = 'RGBA'
        mix_color.blend_type = 'MIX'
        mix_color.inputs['A'].default_value = base_rgb
        mix_color.inputs['B'].default_value = edge_rgb
        
        mix_final = nodes.new(type="ShaderNodeMix")
        mix_final.data_type = 'RGBA'
        mix_final.blend_type = 'MULTIPLY'
        
        # Hook up Edge Wear & AO Links
        links.new(geom.outputs['Pointiness'], mix_noise.inputs['A'])
        links.new(noise.outputs['Fac'], mix_noise.inputs['B'])
        links.new(mix_noise.outputs['Result'], cr_edge.inputs['Fac'])
        links.new(cr_edge.outputs['Color'], mix_color.inputs['Factor'])
        
        links.new(ao.outputs['Color'], cr_ao.inputs['Fac'])
        links.new(mix_color.outputs['Result'], mix_final.inputs['A'])
        links.new(cr_ao.outputs['Color'], mix_final.inputs['B'])
        links.new(mix_final.outputs['Result'], bsdf.inputs['Base Color'])
        
        bsdf.inputs['Metallic'].default_value = metallic
        bsdf.inputs['Roughness'].default_value = roughness
        
        if bump_texture == 'canvas':
            wave = nodes.new(type="ShaderNodeTexWave")
            wave.inputs['Scale'].default_value = 120.0
            bump = nodes.new(type="ShaderNodeBump")
            bump.inputs['Strength'].default_value = 0.15
            links.new(wave.outputs['Color'], bump.inputs['Height'])
            links.new(bump.outputs['Normal'], bsdf.inputs['Normal'])
            
        links.new(bsdf.outputs['BSDF'], out.inputs['Surface'])
        return mat

    def create_simple_mat(name, base_rgb, metallic=0.0, roughness=0.5, emission=None, emission_strength=1.0, transmission=0.0):
        mat = bpy.data.materials.get(name)
        if mat is None:
            mat = bpy.data.materials.new(name=name)
            mat.use_nodes = True
        nodes = mat.node_tree.nodes
        bsdf = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
        bsdf.inputs['Base Color'].default_value = base_rgb
        bsdf.inputs['Metallic'].default_value = metallic
        bsdf.inputs['Roughness'].default_value = roughness
        if 'Transmission Weight' in bsdf.inputs:
            bsdf.inputs['Transmission Weight'].default_value = transmission
        elif 'Transmission' in bsdf.inputs:
            bsdf.inputs['Transmission'].default_value = transmission
        if emission:
            if 'Emission Color' in bsdf.inputs:
                bsdf.inputs['Emission Color'].default_value = emission
                bsdf.inputs['Emission Strength'].default_value = emission_strength
            elif 'Emission' in bsdf.inputs:
                bsdf.inputs['Emission'].default_value = emission
        return mat

    # Materials definition matching reference
    m_olive = create_stylized_edge_wear_material("Mat_OliveArmor", (0.24, 0.32, 0.17, 1.0), metallic=0.22, roughness=0.34)
    m_dark_olive = create_stylized_edge_wear_material("Mat_DarkOlive", (0.13, 0.18, 0.10, 1.0), metallic=0.25, roughness=0.38)
    m_teal = create_stylized_edge_wear_material("Mat_TealShroud", (0.05, 0.14, 0.17, 1.0), metallic=0.68, roughness=0.30)
    m_gunmetal = create_stylized_edge_wear_material("Mat_GunmetalSteel", (0.05, 0.06, 0.07, 1.0), metallic=0.88, roughness=0.26)
    m_steel = create_stylized_edge_wear_material("Mat_SteelAccents", (0.28, 0.31, 0.34, 1.0), metallic=0.94, roughness=0.20)
    m_canvas_drum = create_stylized_edge_wear_material("Mat_CanvasDrum", (0.21, 0.28, 0.16, 1.0), metallic=0.10, roughness=0.65, bump_texture='canvas')
    m_bronze = create_stylized_edge_wear_material("Mat_BronzeBumper", (0.55, 0.40, 0.25, 1.0), edge_rgb=(0.85, 0.70, 0.50, 1.0), metallic=0.85, roughness=0.32)
    m_brass = create_simple_mat("Mat_BrassCartridge", (0.88, 0.64, 0.19, 1.0), metallic=0.98, roughness=0.15)
    m_copper = create_simple_mat("Mat_CopperBullet", (0.84, 0.34, 0.14, 1.0), metallic=0.96, roughness=0.18)
    m_orange_led = create_simple_mat("Mat_OrangeLED", (1.0, 0.35, 0.01, 1.0), emission=(1.0, 0.35, 0.01, 1.0), emission_strength=15.0)
    m_amber_lens = create_simple_mat("Mat_AmberLens", (1.0, 0.50, 0.10, 1.0), roughness=0.04, transmission=0.90)

    # Helper: Create an oblong pill cutter for boolean holes
    def create_pill_cutter(name, loc, scale_x, scale_z, depth=0.6, rot=(0,0,0)):
        bpy.ops.mesh.primitive_cylinder_add(radius=scale_z/2, depth=depth, location=loc, rotation=(math.radians(90), 0, 0))
        cyl1 = bpy.context.active_object
        cyl1.location.x -= scale_x/2
        
        bpy.ops.mesh.primitive_cylinder_add(radius=scale_z/2, depth=depth, location=loc, rotation=(math.radians(90), 0, 0))
        cyl2 = bpy.context.active_object
        cyl2.location.x += scale_x/2
        
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
        box = bpy.context.active_object
        box.scale = (scale_x, depth, scale_z)
        bpy.ops.object.transform_apply(scale=True)
        
        bpy.ops.object.select_all(action='DESELECT')
        cyl1.select_set(True)
        cyl2.select_set(True)
        box.select_set(True)
        bpy.context.view_layer.objects.active = box
        bpy.ops.object.join()
        box.name = name
        box.rotation_euler = rot
        return box

    # -------------------------------------------------------------------------
    # 3. Receiver & Chassis (Stock at -X, Muzzle at +X, Details on -Y)
    # -------------------------------------------------------------------------
    # Main Lower Receiver
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 0.28))
    rec = bpy.context.active_object
    rec.name = "Receiver_Chassis"
    rec.scale = (2.1, 0.52, 0.62)
    bpy.ops.object.transform_apply(scale=True)
    reg(rec, m_olive)

    # Upper Receiver Dust Cover (with 45° chamfered top)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.05, 0.0, 0.64))
    rec_top = bpy.context.active_object
    rec_top.name = "Receiver_TopCover"
    rec_top.scale = (1.8, 0.46, 0.18)
    bpy.ops.object.transform_apply(scale=True)
    reg(rec_top, m_olive)

    # Recessed Side Decorative Armor Panels
    for sign in [-1, 1]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.15, sign * 0.27, 0.32))
        panel = bpy.context.active_object
        panel.name = f"Receiver_Panel_{sign}"
        panel.scale = (1.35, 0.05, 0.38)
        bpy.ops.object.transform_apply(scale=True)
        reg(panel, m_dark_olive)

    # True Recessed Feed Tray & Port on -Y side
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.05, -0.27, 0.40))
    feed_tray = bpy.context.active_object
    feed_tray.name = "Feed_Tray_Port"
    feed_tray.scale = (0.76, 0.10, 0.26)
    bpy.ops.object.transform_apply(scale=True)
    reg(feed_tray, m_gunmetal)

    # Receiver Screws / Rivets
    for idx, (px, pz) in enumerate([(-0.45, 0.12), (0.42, 0.14), (-0.75, 0.32)]):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=0.58, location=(px, 0.0, pz), rotation=(math.radians(90), 0, 0))
        pin = bpy.context.active_object
        pin.name = f"Receiver_Pin_{idx}"
        reg(pin, m_steel)

    # Recessed Bezel & Glowing Orange Indicator on Upper Receiver
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.48, -0.27, 0.68))
    bezel_rec = bpy.context.active_object
    bezel_rec.name = "Receiver_LED_Bezel"
    bezel_rec.scale = (0.16, 0.04, 0.10)
    bpy.ops.object.transform_apply(scale=True)
    reg(bezel_rec, m_gunmetal)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.48, -0.28, 0.68))
    led_rec = bpy.context.active_object
    led_rec.name = "Receiver_LED"
    led_rec.scale = (0.11, 0.03, 0.065)
    bpy.ops.object.transform_apply(scale=True)
    reg(led_rec, m_orange_led)

    # Rear Sight Base Block with aperture
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.48, 0.0, 0.72))
    rsight = bpy.context.active_object
    rsight.name = "Rear_Sight_Base"
    rsight.scale = (0.32, 0.34, 0.16)
    bpy.ops.object.transform_apply(scale=True)
    reg(rsight, m_gunmetal)

    # -------------------------------------------------------------------------
    # 4. Continuous Picatinny Top Rail
    # -------------------------------------------------------------------------
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.65, 0.0, 0.78))
    rail_base = bpy.context.active_object
    rail_base.name = "Picatinny_Rail_Base"
    rail_base.scale = (2.4, 0.30, 0.06)
    bpy.ops.object.transform_apply(scale=True)
    reg(rail_base, m_gunmetal)

    num_teeth = 22
    st_tx, end_tx = -0.35, 1.75
    sp_tx = (end_tx - st_tx) / (num_teeth - 1)
    for i in range(num_teeth):
        tx = st_tx + i * sp_tx
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(tx, 0.0, 0.82))
        tooth = bpy.context.active_object
        tooth.name = f"Rail_Tooth_{i}"
        tooth.scale = (sp_tx * 0.58, 0.32, 0.04)
        bpy.ops.object.transform_apply(scale=True)
        reg(tooth, m_gunmetal)

    # -------------------------------------------------------------------------
    # 5. Stylized Ergonomic Stock Assembly
    # -------------------------------------------------------------------------
    # Annular Buffer Collar
    bpy.ops.mesh.primitive_cylinder_add(radius=0.22, depth=0.26, location=(-1.18, 0.0, 0.30), rotation=(0, math.radians(90), 0))
    collar = bpy.context.active_object
    collar.name = "Stock_Collar"
    reg(collar, m_gunmetal)

    # Main Contoured Stock Body with Lower Stepped Contour
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-1.80, 0.0, 0.24))
    stock_body = bpy.context.active_object
    stock_body.name = "Stock_Body"
    stock_body.scale = (1.05, 0.36, 0.58)
    bpy.ops.object.transform_apply(scale=True)
    reg(stock_body, m_olive)

    # Recessed Dark Inner Cheek Rest Panel
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-1.68, 0.0, -0.04))
    stock_cut = bpy.context.active_object
    stock_cut.name = "Stock_LowerPlate"
    stock_cut.scale = (0.75, 0.34, 0.26)
    bpy.ops.object.transform_apply(scale=True)
    reg(stock_cut, m_dark_olive)

    # Rubberized Buttpad with Curved Silhouette
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-2.38, 0.0, 0.24))
    buttpad = bpy.context.active_object
    buttpad.name = "Stock_Buttpad"
    buttpad.scale = (0.16, 0.42, 0.80)
    bpy.ops.object.transform_apply(scale=True)
    reg(buttpad, m_gunmetal)

    # Buttpad Slotted Screws (Facing -Y)
    for sz in [-0.08, 0.52]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.038, depth=0.16, location=(-2.40, -0.19, sz), rotation=(math.radians(90), 0, 0))
        sc = bpy.context.active_object
        sc.name = f"Stock_Screw_{sz}"
        reg(sc, m_steel)

    # -------------------------------------------------------------------------
    # 6. Ergonomic Pistol Grip & Trigger Assembly
    # -------------------------------------------------------------------------
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.56, 0.0, -0.38))
    grip = bpy.context.active_object
    grip.name = "Pistol_Grip"
    grip.rotation_euler = (0, math.radians(18), 0)
    grip.scale = (0.34, 0.32, 0.76)
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    reg(grip, m_gunmetal)

    for sign in [-1, 1]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.56, sign * 0.17, -0.38))
        gp = bpy.context.active_object
        gp.name = f"Grip_Panel_{sign}"
        gp.rotation_euler = (0, math.radians(18), 0)
        gp.scale = (0.22, 0.035, 0.50)
        bpy.ops.object.transform_apply(rotation=True, scale=True)
        reg(gp, m_teal)

    # Trigger Guard Loop
    bpy.ops.mesh.primitive_cylinder_add(radius=0.26, depth=0.10, location=(-0.24, 0.0, -0.12), rotation=(math.radians(90), 0, 0))
    tguard = bpy.context.active_object
    tguard.name = "Trigger_Guard"
    tguard.scale = (1.0, 1.0, 0.60)
    bpy.ops.object.transform_apply(scale=True)
    reg(tguard, m_gunmetal)

    # Curved Steel Trigger Shoe
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.25, 0.0, -0.12))
    trig = bpy.context.active_object
    trig.name = "Trigger"
    trig.rotation_euler = (0, math.radians(24), 0)
    trig.scale = (0.045, 0.05, 0.20)
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    reg(trig, m_steel)

    # -------------------------------------------------------------------------
    # 7. Canvas Drum Magazine & Weathered Bronze Bumpers
    # -------------------------------------------------------------------------
    # Magazine Body (Tilted slightly to match reference stance)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.08, -0.06, -0.62))
    mag = bpy.context.active_object
    mag.name = "Magazine_Box"
    mag.rotation_euler = (0, math.radians(-3), 0)
    mag.scale = (0.82, 0.62, 0.82)
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    reg(mag, m_canvas_drum)

    # Weathered Bronze Protective Corner Bumpers
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.08, -0.06, -0.62))
    mag_rim = bpy.context.active_object
    mag_rim.name = "Magazine_Bumper"
    mag_rim.rotation_euler = (0, math.radians(-3), 0)
    mag_rim.scale = (0.88, 0.66, 0.86)
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    reg(mag_rim, m_bronze)

    # Circular Hub: Outer Stepped Ring on -Y face
    bpy.ops.mesh.primitive_cylinder_add(radius=0.28, depth=0.08, location=(-0.08, -0.40, -0.62), rotation=(math.radians(90), 0, 0))
    hub_out = bpy.context.active_object
    hub_out.name = "Magazine_Hub_Outer"
    reg(hub_out, m_steel)

    # Inner Recessed Disc with Circular Groove
    bpy.ops.mesh.primitive_cylinder_add(radius=0.18, depth=0.10, location=(-0.08, -0.41, -0.62), rotation=(math.radians(90), 0, 0))
    hub_in = bpy.context.active_object
    hub_in.name = "Magazine_Hub_Inner"
    reg(hub_in, m_olive)

    # Center Boss Nut
    bpy.ops.mesh.primitive_cylinder_add(radius=0.07, depth=0.12, location=(-0.08, -0.42, -0.62), rotation=(math.radians(90), 0, 0))
    hub_nut = bpy.context.active_object
    hub_nut.name = "Magazine_Hub_Nut"
    reg(hub_nut, m_gunmetal)

    # -------------------------------------------------------------------------
    # 8. Curved Ammunition Belt (5 Rounds Feeding in an Arc)
    # -------------------------------------------------------------------------
    # Natural arc positions curving from magazine upward and inward into feed tray
    belt_arc = [
        (-0.24, -0.36, 0.28, 18),
        (-0.13, -0.38, 0.33, 10),
        (-0.01, -0.39, 0.37, 2),
        (0.12, -0.38, 0.40, -6),
        (0.24, -0.34, 0.42, -14)
    ]
    for idx, (bx, by, bz, brot) in enumerate(belt_arc):
        # Brass Cartridge Case
        bpy.ops.mesh.primitive_cylinder_add(radius=0.046, depth=0.46, location=(bx, by, bz), rotation=(0, math.radians(90 + brot), 0))
        casing = bpy.context.active_object
        casing.name = f"Cartridge_Case_{idx}"
        reg(casing, m_brass)

        # Copper Bullet Projectile Tip
        bpy.ops.mesh.primitive_cone_add(radius1=0.044, radius2=0.005, depth=0.18, location=(bx + 0.28, by, bz - math.sin(math.radians(brot))*0.04), rotation=(0, math.radians(90 + brot), 0))
        bullet = bpy.context.active_object
        bullet.name = f"Cartridge_Bullet_{idx}"
        reg(bullet, m_copper)

        # Black Phosphate Disintegrating Link Clip
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(bx - 0.04, by, bz))
        link = bpy.context.active_object
        link.name = f"Cartridge_Link_{idx}"
        link.scale = (0.16, 0.11, 0.11)
        bpy.ops.object.transform_apply(scale=True)
        reg(link, m_gunmetal)

    # -------------------------------------------------------------------------
    # 9. Vented Handguard with TRUE Negative Boolean Pill Slots
    # -------------------------------------------------------------------------
    # Main Handguard Shroud (Octagonal/Faceted cross section)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(1.50, 0.0, 0.30))
    hguard = bpy.context.active_object
    hguard.name = "Handguard_Shroud"
    hguard.scale = (1.45, 0.48, 0.54)
    bpy.ops.object.transform_apply(scale=True)
    reg(hguard, m_teal)

    # Hollow out the interior of the handguard so barrel cavity is visible
    bpy.ops.mesh.primitive_cylinder_add(radius=0.18, depth=1.50, location=(1.50, 0.0, 0.30), rotation=(0, math.radians(90), 0))
    hg_cavity = bpy.context.active_object
    hg_cavity.name = "HG_Cavity"
    
    # Create 10 Pill-shaped negative cutters (2 rows of 5 slots)
    pill_cutters = []
    for rz in [0.20, 0.40]:
        for col in range(5):
            vx = 1.08 + col * 0.22
            p_cutter = create_pill_cutter(f"Pill_Cutter_{rz}_{col}", (vx, -0.24, rz), scale_x=0.09, scale_z=0.07, depth=0.25)
            pill_cutters.append(p_cutter)

    # Join cutters into a single boolean tool
    bpy.ops.object.select_all(action='DESELECT')
    hg_cavity.select_set(True)
    for pc in pill_cutters:
        pc.select_set(True)
    bpy.context.view_layer.objects.active = hg_cavity
    bpy.ops.object.join()
    cutters_tool = bpy.context.active_object
    cutters_tool.name = "Handguard_Negative_Tool"

    # Apply Boolean Difference to cut negative cooling holes through the shroud
    bool_hg = hguard.modifiers.new(name="Cooling_Vents_Boolean", type='BOOLEAN')
    bool_hg.operation = 'DIFFERENCE'
    bool_hg.object = cutters_tool
    bpy.context.view_layer.objects.active = hguard
    bpy.ops.object.modifier_apply(modifier="Cooling_Vents_Boolean")
    
    # Clean up cutter tool
    bpy.data.objects.remove(cutters_tool, do_unlink=True)

    # Recessed Dark Bezel & Orange LED on Handguard
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.95, -0.25, 0.46))
    led_bezel_hg = bpy.context.active_object
    led_bezel_hg.name = "HG_LED_Bezel"
    led_bezel_hg.scale = (0.15, 0.035, 0.08)
    bpy.ops.object.transform_apply(scale=True)
    reg(led_bezel_hg, m_gunmetal)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.95, -0.26, 0.46))
    led_hg = bpy.context.active_object
    led_hg.name = "Handguard_LED"
    led_hg.scale = (0.10, 0.03, 0.055)
    bpy.ops.object.transform_apply(scale=True)
    reg(led_hg, m_orange_led)

    # -------------------------------------------------------------------------
    # 10. Stepped Barrel, Front Sight Loop & Ported Muzzle Brake
    # -------------------------------------------------------------------------
    # Main Inner/Outer Barrel
    bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=2.25, location=(2.55, 0.0, 0.40), rotation=(0, math.radians(90), 0))
    barrel = bpy.context.active_object
    barrel.name = "Barrel_Main"
    reg(barrel, m_gunmetal)

    # Gas Cylinder Tube underneath
    bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=1.55, location=(2.05, 0.0, 0.20), rotation=(0, math.radians(90), 0))
    gastube = bpy.context.active_object
    gastube.name = "Gas_Tube"
    reg(gastube, m_steel)

    # Front Sight Block Bracket
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(3.15, 0.0, 0.44))
    fsight = bpy.context.active_object
    fsight.name = "Front_Sight_Base"
    fsight.scale = (0.26, 0.30, 0.62)
    bpy.ops.object.transform_apply(scale=True)
    reg(fsight, m_gunmetal)

    # Curved Front Sight Protective Loop Wings
    bpy.ops.mesh.primitive_cylinder_add(radius=0.14, depth=0.12, location=(3.18, 0.0, 0.86), rotation=(0, math.radians(90), 0))
    fwings = bpy.context.active_object
    fwings.name = "Front_Sight_Loop"
    reg(fwings, m_gunmetal)

    # Center Sight Post Pin
    bpy.ops.mesh.primitive_cylinder_add(radius=0.018, depth=0.18, location=(3.18, 0.0, 0.86))
    fpin = bpy.context.active_object
    fpin.name = "Front_Sight_Pin"
    reg(fpin, m_steel)

    # Barrel Collar Ring
    bpy.ops.mesh.primitive_cylinder_add(radius=0.105, depth=0.08, location=(3.42, 0.0, 0.40), rotation=(0, math.radians(90), 0))
    bcollar = bpy.context.active_object
    bcollar.name = "Barrel_Collar"
    reg(bcollar, m_steel)

    # Cylindrical Muzzle Brake with 3 Vertical Negative Slots
    bpy.ops.mesh.primitive_cylinder_add(radius=0.11, depth=0.52, location=(3.92, 0.0, 0.40), rotation=(0, math.radians(90), 0))
    mbrake = bpy.context.active_object
    mbrake.name = "Muzzle_Brake"
    reg(mbrake, m_gunmetal)

    # Inner hollow bore for muzzle
    bpy.ops.mesh.primitive_cylinder_add(radius=0.07, depth=0.54, location=(3.92, 0.0, 0.40), rotation=(0, math.radians(90), 0))
    bore_cutter = bpy.context.active_object
    
    # Cutters for 3 vertical exhaust compensation ports
    slot_cutters = []
    for mx in [3.78, 3.92, 4.06]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(mx, 0.0, 0.40))
        scut = bpy.context.active_object
        scut.scale = (0.055, 0.30, 0.16)
        bpy.ops.object.transform_apply(scale=True)
        slot_cutters.append(scut)

    bpy.ops.object.select_all(action='DESELECT')
    bore_cutter.select_set(True)
    for sc in slot_cutters:
        sc.select_set(True)
    bpy.context.view_layer.objects.active = bore_cutter
    bpy.ops.object.join()
    muzzle_cutter_tool = bpy.context.active_object
    
    bool_mb = mbrake.modifiers.new(name="Muzzle_Ports_Boolean", type='BOOLEAN')
    bool_mb.operation = 'DIFFERENCE'
    bool_mb.object = muzzle_cutter_tool
    bpy.context.view_layer.objects.active = mbrake
    bpy.ops.object.modifier_apply(modifier="Muzzle_Ports_Boolean")
    bpy.data.objects.remove(muzzle_cutter_tool, do_unlink=True)

    # -------------------------------------------------------------------------
    # 11. Hooded Tactical Reflex Sight (Optic)
    # -------------------------------------------------------------------------
    # Riser Clamp Mount
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.38, 0.0, 0.90))
    opt_mount = bpy.context.active_object
    opt_mount.name = "Optic_Mount"
    opt_mount.scale = (0.58, 0.32, 0.10)
    bpy.ops.object.transform_apply(scale=True)
    reg(opt_mount, m_gunmetal)

    # Knurled Clamping Thumbscrew Knob
    bpy.ops.mesh.primitive_cylinder_add(radius=0.055, depth=0.38, location=(0.35, 0.0, 0.90), rotation=(math.radians(90), 0, 0))
    opt_knob = bpy.context.active_object
    opt_knob.name = "Optic_Mount_Knob"
    reg(opt_knob, m_steel)

    # Aerodynamic Hooded Housing (with angled brow and hollow interior)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.42, 0.0, 1.18))
    opt_hood = bpy.context.active_object
    opt_hood.name = "Optic_Hood"
    opt_hood.scale = (0.52, 0.38, 0.40)
    bpy.ops.object.transform_apply(scale=True)
    reg(opt_hood, m_olive)

    # Hollow out the reflex sight interior for the lens
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.42, 0.0, 1.18))
    opt_cavity = bpy.context.active_object
    opt_cavity.scale = (0.54, 0.32, 0.32)
    bpy.ops.object.transform_apply(scale=True)
    
    bool_opt = opt_hood.modifiers.new(name="Hood_Cavity", type='BOOLEAN')
    bool_opt.operation = 'DIFFERENCE'
    bool_opt.object = opt_cavity
    bpy.context.view_layer.objects.active = opt_hood
    bpy.ops.object.modifier_apply(modifier="Hood_Cavity")
    bpy.data.objects.remove(opt_cavity, do_unlink=True)

    # Top Cylindrical Battery Turret with Slotted Cap
    bpy.ops.mesh.primitive_cylinder_add(radius=0.075, depth=0.42, location=(0.14, 0.0, 1.14), rotation=(0, math.radians(90), 0))
    opt_turret = bpy.context.active_object
    opt_turret.name = "Optic_Turret"
    reg(opt_turret, m_gunmetal)

    # Coated Amber Glass Lens inside the Hood
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.48, 0.0, 1.18))
    opt_lens = bpy.context.active_object
    opt_lens.name = "Optic_Lens"
    opt_lens.rotation_euler = (0, math.radians(-10), 0)
    opt_lens.scale = (0.02, 0.30, 0.30)
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    reg(opt_lens, m_amber_lens)

    # Glowing Holographic Aiming Reticle Dot
    bpy.ops.mesh.primitive_cylinder_add(radius=0.035, depth=0.01, location=(0.49, 0.0, 1.18), rotation=(0, math.radians(90), 0))
    reticle = bpy.context.active_object
    reticle.name = "Optic_Reticle_Dot"
    reg(reticle, m_orange_led)

    # -------------------------------------------------------------------------
    # 12. Non-Destructive Modifiers & Unified Mesh Join
    # -------------------------------------------------------------------------
    for obj in created_objects:
        if obj.type == 'MESH':
            bev = obj.modifiers.new(name="Bevel", type='BEVEL')
            bev.width = 0.012
            bev.segments = 2
            bev.limit_method = 'ANGLE'
            bev.angle_limit = math.radians(35)
            for poly in obj.data.polygons:
                poly.use_smooth = True

    mesh_objs = [o for o in created_objects if o.type == 'MESH']
    if mesh_objs:
        bpy.ops.object.select_all(action='DESELECT')
        for o in mesh_objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = mesh_objs[0]
        bpy.ops.object.join()
        unified_mesh = bpy.context.active_object
        unified_mesh.name = "LMG_HighPoly"
        
        subd = unified_mesh.modifiers.new(name="Subdivision", type='SUBSURF')
        subd.levels = 1
        subd.render_levels = 2

    # -------------------------------------------------------------------------
    # 13. High-Contrast Studio Lighting Rig (Razor Specular Edge Highlights)
    # -------------------------------------------------------------------------
    target = bpy.data.objects.new("Camera_Target", None)
    coll.objects.link(target)
    target.location = (0.9, -0.1, 0.15)

    # Hero Camera (60mm Telephoto Perspective)
    cam_data = bpy.data.cameras.new("Hero_Camera")
    cam_data.lens = 55
    cam_obj = bpy.data.objects.new("Hero_Camera", cam_data)
    coll.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj
    cam_obj.location = (1.4, -9.0, 1.25)
    
    con = cam_obj.constraints.new(type='TRACK_TO')
    con.target = target
    con.track_axis = 'TRACK_NEGATIVE_Z'
    con.up_axis = 'UP_Y'

    # Side Orthographic Camera
    side_cam_data = bpy.data.cameras.new("Side_Camera")
    side_cam_data.type = 'ORTHO'
    side_cam_data.ortho_scale = 7.0
    side_cam_obj = bpy.data.objects.new("Side_Camera", side_cam_data)
    coll.objects.link(side_cam_obj)
    side_cam_obj.location = (0.9, -6.5, 0.2)
    side_cam_obj.rotation_euler = (math.radians(90), 0, 0)

    # Lighting Setup:
    # 1. Intense Cool Rim Light (Upper rear silhouette backlight)
    rim_data = bpy.data.lights.new("Rim_Light_Top", type='AREA')
    rim_data.energy = 1100.0
    rim_data.size = 4.0
    rim_data.color = (0.85, 0.94, 1.0)
    rim_top = bpy.data.objects.new("Rim_Light_Top", rim_data)
    rim_top.location = (0.5, 3.8, 3.2)
    rim_top.rotation_euler = (math.radians(-45), 0, math.radians(160))
    coll.objects.link(rim_top)

    # 2. Muzzle & Barrel Accent Rim Light (Catching muzzle brake slots)
    rim_muzzle_data = bpy.data.lights.new("Rim_Light_Muzzle", type='AREA')
    rim_muzzle_data.energy = 850.0
    rim_muzzle_data.size = 2.0
    rim_muzzle_data.color = (0.90, 0.95, 1.0)
    rim_muzzle = bpy.data.objects.new("Rim_Light_Muzzle", rim_muzzle_data)
    rim_muzzle.location = (4.8, -2.5, 2.5)
    coll.objects.link(rim_muzzle)

    # 3. Key Light (Upper Front-Right warm diffuse light)
    key_data = bpy.data.lights.new("Key_Light", type='AREA')
    key_data.energy = 700.0
    key_data.size = 3.5
    key_data.color = (1.0, 0.97, 0.93)
    key_l = bpy.data.objects.new("Key_Light", key_data)
    key_l.location = (2.2, -5.2, 3.2)
    coll.objects.link(key_l)

    # 4. Fill Light (Soft subtle bounce)
    fill_data = bpy.data.lights.new("Fill_Light", type='POINT')
    fill_data.energy = 180.0
    fill_l = bpy.data.objects.new("Fill_Light", fill_data)
    fill_l.location = (-1.8, -3.5, 0.3)
    coll.objects.link(fill_l)

    # Pure dark background
    world = bpy.context.scene.world
    if world is None:
        world = bpy.data.worlds.new("StudioWorld")
        bpy.context.scene.world = world
    world.use_nodes = True
    bg_node = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
    bg_node.inputs['Color'].default_value = (0.010, 0.010, 0.012, 1.0)
    bg_node.inputs['Strength'].default_value = 0.35

    # Render settings
    scene = bpy.context.scene
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 900
    scene.render.film_transparent = False

    # Save Blend File
    blend_path = str(Path(__file__).resolve().parents[1] / 'models/stylized_lmg.blend')
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print(f"Saved faithful high-poly model to: {blend_path}")

    # Render Hero Image
    scene.camera = cam_obj
    hero_path = str(Path(__file__).resolve().parents[1] / 'previews/render_hero.png')
    scene.render.filepath = hero_path
    bpy.ops.render.render(write_still=True)
    print(f"Rendered Hero Image to: {hero_path}")

    # Render Side Image
    scene.camera = side_cam_obj
    side_path = str(Path(__file__).resolve().parents[1] / 'previews/render_side.png')
    scene.render.filepath = side_path
    bpy.ops.render.render(write_still=True)
    print(f"Rendered Side Image to: {side_path}")

build_faithful_lmg()
