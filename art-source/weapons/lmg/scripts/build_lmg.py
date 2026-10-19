from pathlib import Path
import bpy
import bmesh
import math
import os
from mathutils import Vector, Euler, Matrix

def create_stylized_lmg():
    # Clear existing objects in the default collection
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    
    # Ensure collection exists
    coll_name = "LMG_Assets"
    if coll_name in bpy.data.collections:
        coll = bpy.data.collections[coll_name]
    else:
        coll = bpy.data.collections.new(coll_name)
        bpy.context.scene.collection.children.link(coll)
    
    # -------------------------------------------------------------
    # Materials Setup
    # -------------------------------------------------------------
    def get_or_create_material(name, base_color, metallic=0.0, roughness=0.5, emission=None, emission_strength=1.0, transmission=0.0):
        mat = bpy.data.materials.get(name)
        if mat is None:
            mat = bpy.data.materials.new(name=name)
            mat.use_nodes = True
        
        nodes = mat.node_tree.nodes
        bsdf = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
        
        # Base color
        bsdf.inputs['Base Color'].default_value = base_color
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

    # Define color palette matching reference
    mat_green = get_or_create_material("Mat_OliveGreen", (0.24, 0.31, 0.17, 1.0), metallic=0.15, roughness=0.38)
    mat_dark_green = get_or_create_material("Mat_DarkOlive", (0.17, 0.22, 0.13, 1.0), metallic=0.15, roughness=0.45)
    mat_gunmetal = get_or_create_material("Mat_Gunmetal", (0.05, 0.06, 0.07, 1.0), metallic=0.85, roughness=0.32)
    mat_steel = get_or_create_material("Mat_Steel", (0.2, 0.22, 0.24, 1.0), metallic=0.9, roughness=0.25)
    mat_teal = get_or_create_material("Mat_TealShroud", (0.08, 0.16, 0.18, 1.0), metallic=0.6, roughness=0.38)
    mat_brass = get_or_create_material("Mat_Brass", (0.78, 0.55, 0.18, 1.0), metallic=0.95, roughness=0.22)
    mat_copper = get_or_create_material("Mat_Copper", (0.75, 0.30, 0.15, 1.0), metallic=0.92, roughness=0.25)
    mat_orange_glow = get_or_create_material("Mat_OrangeGlow", (1.0, 0.35, 0.02, 1.0), emission=(1.0, 0.35, 0.02, 1.0), emission_strength=8.0)
    mat_amber_glass = get_or_create_material("Mat_AmberGlass", (1.0, 0.45, 0.1, 1.0), roughness=0.1, transmission=0.85)

    created_objects = []

    def register_obj(obj, mat=None):
        if mat:
            if obj.data.materials:
                obj.data.materials[0] = mat
            else:
                obj.data.materials.append(mat)
        created_objects.append(obj)
        # Link to collection
        for c in list(obj.users_collection):
            c.objects.unlink(obj)
        coll.objects.link(obj)
        return obj

    # -------------------------------------------------------------
    # 1. Receiver (Main Chassis)
    # -------------------------------------------------------------
    # Main Lower Receiver Box
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.3))
    rec = bpy.context.active_object
    rec.name = "Receiver_Body"
    rec.scale = (2.2, 0.55, 0.65)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(rec, mat_green)

    # Receiver top cover chamfer
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.1, 0, 0.68))
    rec_top = bpy.context.active_object
    rec_top.name = "Receiver_TopCover"
    rec_top.scale = (1.9, 0.5, 0.2)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(rec_top, mat_green)

    # Side Recess Plates (Left & Right)
    for sign in [-1, 1]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.1, sign * 0.28, 0.35))
        panel = bpy.context.active_object
        panel.name = f"Receiver_Panel_{sign}"
        panel.scale = (1.4, 0.06, 0.4)
        bpy.ops.object.transform_apply(scale=True)
        register_obj(panel, mat_dark_green)

    # Feed Port / Ejection Port (Right Side)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.05, 0.28, 0.42))
    eject = bpy.context.active_object
    eject.name = "Ejection_Port"
    eject.scale = (0.75, 0.08, 0.28)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(eject, mat_gunmetal)

    # Receiver Pins / Rivets
    pin_locations = [(-0.4, 0.3, 0.15), (0.45, 0.3, 0.15), (-0.7, 0.3, 0.35)]
    for idx, loc in enumerate(pin_locations):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.045, depth=0.62, location=(loc[0], 0, loc[2]), rotation=(math.radians(90), 0, 0))
        pin = bpy.context.active_object
        pin.name = f"Receiver_Pin_{idx}"
        register_obj(pin, mat_gunmetal)

    # Indicator light on Receiver
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.45, 0.285, 0.72))
    ind_rec = bpy.context.active_object
    ind_rec.name = "Receiver_Light"
    ind_rec.scale = (0.14, 0.04, 0.08)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(ind_rec, mat_orange_glow)

    # Rear Sight Base Block
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.45, 0, 0.76))
    rsb = bpy.context.active_object
    rsb.name = "Rear_Sight_Base"
    rsb.scale = (0.35, 0.38, 0.18)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(rsb, mat_gunmetal)

    # -------------------------------------------------------------
    # 2. Picatinny Rails (Top Spine)
    # -------------------------------------------------------------
    # Base rail strip
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.6, 0, 0.81))
    rail_base = bpy.context.active_object
    rail_base.name = "Picatinny_Rail_Base"
    rail_base.scale = (2.2, 0.32, 0.08)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(rail_base, mat_gunmetal)

    # Individual rail teeth
    teeth_count = 18
    rail_start_x = -0.3
    rail_end_x = 1.6
    step_x = (rail_end_x - rail_start_x) / (teeth_count - 1)
    for i in range(teeth_count):
        tx = rail_start_x + i * step_x
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(tx, 0, 0.86))
        tooth = bpy.context.active_object
        tooth.name = f"Rail_Tooth_{i}"
        tooth.scale = (step_x * 0.55, 0.34, 0.05)
        bpy.ops.object.transform_apply(scale=True)
        register_obj(tooth, mat_gunmetal)

    # -------------------------------------------------------------
    # 3. Stock Assembly
    # -------------------------------------------------------------
    # Stock Connector Collar
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-1.25, 0, 0.32))
    collar = bpy.context.active_object
    collar.name = "Stock_Collar"
    collar.scale = (0.3, 0.46, 0.5)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(collar, mat_gunmetal)

    # Stock Main Frame (Green stylized body)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-1.85, 0, 0.22))
    stk = bpy.context.active_object
    stk.name = "Stock_Body"
    stk.scale = (1.0, 0.38, 0.6)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(stk, mat_green)

    # Stock Lower Cutout Plate (Dark Grey Inset)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-1.7, 0, -0.05))
    stk_sub = bpy.context.active_object
    stk_sub.name = "Stock_LowerInset"
    stk_sub.scale = (0.7, 0.36, 0.3)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(stk_sub, mat_dark_green)

    # Rubber Buttpad (Dark Beveled Rear Plate)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-2.42, 0, 0.24))
    butt = bpy.context.active_object
    butt.name = "Stock_Buttpad"
    butt.scale = (0.16, 0.44, 0.85)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(butt, mat_gunmetal)

    # Buttpad Screws
    for sz in [-0.1, 0.55]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.035, depth=0.18, location=(-2.45, 0.18, sz), rotation=(0, math.radians(90), 0))
        sc = bpy.context.active_object
        sc.name = f"Stock_Screw_{sz}"
        register_obj(sc, mat_steel)

    # -------------------------------------------------------------
    # 4. Pistol Grip & Trigger
    # -------------------------------------------------------------
    # Angled Grip Body
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.58, 0, -0.42))
    grip = bpy.context.active_object
    grip.name = "Pistol_Grip"
    grip.rotation_euler = (0, math.radians(-18), 0)
    grip.scale = (0.35, 0.36, 0.8)
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    register_obj(grip, mat_gunmetal)

    # Grip Side Panels (Green Accent Inlay)
    for sign in [-1, 1]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.57, sign * 0.19, -0.42))
        gp = bpy.context.active_object
        gp.name = f"Grip_Panel_{sign}"
        gp.rotation_euler = (0, math.radians(-18), 0)
        gp.scale = (0.22, 0.04, 0.52)
        bpy.ops.object.transform_apply(rotation=True, scale=True)
        register_obj(gp, mat_teal)

    # Trigger Guard Loop
    bpy.ops.mesh.primitive_cylinder_add(radius=0.28, depth=0.12, location=(-0.25, 0, -0.12), rotation=(math.radians(90), 0, 0))
    tg = bpy.context.active_object
    tg.name = "Trigger_Guard"
    tg.scale = (1.0, 1.0, 0.65)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(tg, mat_gunmetal)

    # Trigger Shoe (Curved lever)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.26, 0, -0.12))
    trig = bpy.context.active_object
    trig.name = "Trigger"
    trig.rotation_euler = (0, math.radians(-25), 0)
    trig.scale = (0.05, 0.06, 0.22)
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    register_obj(trig, mat_steel)

    # -------------------------------------------------------------
    # 5. Drum Box Magazine & Cartridge Belt
    # -------------------------------------------------------------
    # Box Magazine Base
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.1, 0.08, -0.65))
    mag = bpy.context.active_object
    mag.name = "Magazine_Box"
    mag.scale = (0.85, 0.65, 0.85)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(mag, mat_green)

    # Magazine Reinforcement Rim / Bumper
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.1, 0.08, -0.65))
    mag_rim = bpy.context.active_object
    mag_rim.name = "Magazine_Rim"
    mag_rim.scale = (0.9, 0.68, 0.88)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(mag_rim, mat_dark_green)

    # Side Circular Hub Cap
    bpy.ops.mesh.primitive_cylinder_add(radius=0.3, depth=0.1, location=(-0.1, 0.44, -0.65), rotation=(math.radians(90), 0, 0))
    hub = bpy.context.active_object
    hub.name = "Magazine_Hub"
    register_obj(hub, mat_steel)

    # Inner Hub Circle
    bpy.ops.mesh.primitive_cylinder_add(radius=0.15, depth=0.12, location=(-0.1, 0.44, -0.65), rotation=(math.radians(90), 0, 0))
    hub_inner = bpy.context.active_object
    hub_inner.name = "Magazine_Hub_Inner"
    register_obj(hub_inner, mat_dark_green)

    # Ammunition Belt (5 Cartridges feeding upward)
    cartridge_coords = [
        (-0.25, 0.38, 0.35, -12),
        (-0.12, 0.40, 0.38, -6),
        (0.01, 0.41, 0.40, 0),
        (0.14, 0.39, 0.42, 8),
        (0.26, 0.35, 0.43, 15)
    ]
    for idx, (cx, cy, cz, crot) in enumerate(cartridge_coords):
        # Brass Case
        bpy.ops.mesh.primitive_cylinder_add(radius=0.048, depth=0.48, location=(cx, cy, cz), rotation=(0, math.radians(90 + crot), 0))
        case = bpy.context.active_object
        case.name = f"Ammo_Case_{idx}"
        register_obj(case, mat_brass)

        # Copper Bullet Tip
        bpy.ops.mesh.primitive_cone_add(radius1=0.046, radius2=0.005, depth=0.18, location=(cx + 0.3, cy, cz + math.sin(math.radians(crot))*0.05), rotation=(0, math.radians(90 + crot), 0))
        bullet = bpy.context.active_object
        bullet.name = f"Ammo_Bullet_{idx}"
        register_obj(bullet, mat_copper)

        # Steel Link Clip
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(cx - 0.05, cy, cz))
        link = bpy.context.active_object
        link.name = f"Ammo_Link_{idx}"
        link.scale = (0.16, 0.12, 0.12)
        bpy.ops.object.transform_apply(scale=True)
        register_obj(link, mat_gunmetal)

    # -------------------------------------------------------------
    # 6. Handguard / Heat Shield & Cooling Vents
    # -------------------------------------------------------------
    # Main Handguard Body (Teal / Dark Shroud)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(1.55, 0, 0.32))
    hg = bpy.context.active_object
    hg.name = "Handguard_Shroud"
    hg.scale = (1.5, 0.52, 0.58)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(hg, mat_teal)

    # Handguard Cooling Vents (Dual Row of horizontal slots)
    for row_z in [0.22, 0.42]:
        for col_i in range(5):
            vx = 1.05 + col_i * 0.24
            bpy.ops.mesh.primitive_cube_add(size=1.0, location=(vx, 0.28, row_z))
            vent = bpy.context.active_object
            vent.name = f"Vent_R_{row_z}_{col_i}"
            vent.scale = (0.14, 0.05, 0.07)
            bpy.ops.object.transform_apply(scale=True)
            register_obj(vent, mat_gunmetal)

    # Orange indicator on Handguard
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.95, 0.28, 0.48))
    hg_led = bpy.context.active_object
    hg_led.name = "Handguard_LED"
    hg_led.scale = (0.12, 0.04, 0.06)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(hg_led, mat_orange_glow)

    # -------------------------------------------------------------
    # 7. Barrel, Gas Block & Muzzle Brake
    # -------------------------------------------------------------
    # Main Barrel
    bpy.ops.mesh.primitive_cylinder_add(radius=0.085, depth=2.4, location=(2.6, 0, 0.42), rotation=(0, math.radians(90), 0))
    barrel = bpy.context.active_object
    barrel.name = "Barrel_Main"
    register_obj(barrel, mat_gunmetal)

    # Gas Tube (Under barrel)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.065, depth=1.6, location=(2.1, 0, 0.22), rotation=(0, math.radians(90), 0))
    gas_tube = bpy.context.active_object
    gas_tube.name = "Gas_Tube"
    register_obj(gas_tube, mat_steel)

    # Front Sight / Gas Block Assembly
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(3.25, 0, 0.46))
    f_block = bpy.context.active_object
    f_block.name = "Front_Sight_Block"
    f_block.scale = (0.28, 0.32, 0.65)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(f_block, mat_gunmetal)

    # Front Sight Post Wings
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(3.28, 0, 0.88))
    f_post = bpy.context.active_object
    f_post.name = "Front_Sight_Post"
    f_post.scale = (0.12, 0.22, 0.24)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(f_post, mat_gunmetal)

    # Front Sight Pin
    bpy.ops.mesh.primitive_cylinder_add(radius=0.02, depth=0.2, location=(3.28, 0, 0.88))
    f_pin = bpy.context.active_object
    f_pin.name = "Front_Sight_Pin"
    register_obj(f_pin, mat_steel)

    # Barrel Collar Ring
    bpy.ops.mesh.primitive_cylinder_add(radius=0.11, depth=0.1, location=(3.5, 0, 0.42), rotation=(0, math.radians(90), 0))
    b_collar = bpy.context.active_object
    b_collar.name = "Barrel_Collar"
    register_obj(b_collar, mat_steel)

    # Muzzle Brake Body
    bpy.ops.mesh.primitive_cylinder_add(radius=0.115, depth=0.55, location=(4.05, 0, 0.42), rotation=(0, math.radians(90), 0))
    muzzle = bpy.context.active_object
    muzzle.name = "Muzzle_Brake"
    register_obj(muzzle, mat_gunmetal)

    # Muzzle Brake Gas Slots (Cutout details)
    for mx in [3.9, 4.05, 4.2]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(mx, 0, 0.42))
        mslot = bpy.context.active_object
        mslot.name = f"Muzzle_Slot_{mx}"
        mslot.scale = (0.06, 0.25, 0.16)
        bpy.ops.object.transform_apply(scale=True)
        register_obj(mslot, mat_steel)

    # -------------------------------------------------------------
    # 8. Tactical Reflex Sight (Optic)
    # -------------------------------------------------------------
    # Riser Mount
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.4, 0, 0.94))
    optic_mount = bpy.context.active_object
    optic_mount.name = "Optic_Mount"
    optic_mount.scale = (0.6, 0.34, 0.12)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(optic_mount, mat_gunmetal)

    # Mount Clamping Screws
    bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=0.42, location=(0.35, 0, 0.94), rotation=(math.radians(90), 0, 0))
    mount_knob = bpy.context.active_object
    mount_knob.name = "Optic_Mount_Knob"
    register_obj(mount_knob, mat_steel)

    # Optic Main Hood / Housing
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.45, 0, 1.22))
    optic_hood = bpy.context.active_object
    optic_hood.name = "Optic_Housing"
    optic_hood.scale = (0.55, 0.42, 0.42)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(optic_hood, mat_green)

    # Optic Forward Battery Tube / Turret
    bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=0.45, location=(0.15, 0, 1.15), rotation=(0, math.radians(90), 0))
    optic_tube = bpy.context.active_object
    optic_tube.name = "Optic_BatteryTube"
    register_obj(optic_tube, mat_gunmetal)

    # Optic Tinted Glass Lens
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.6, 0, 1.22))
    optic_lens = bpy.context.active_object
    optic_lens.name = "Optic_Lens"
    optic_lens.scale = (0.04, 0.32, 0.32)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(optic_lens, mat_amber_glass)

    # Reticle Center Dot (Emissive)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.61, 0, 1.22))
    reticle = bpy.context.active_object
    reticle.name = "Optic_Reticle"
    reticle.scale = (0.02, 0.05, 0.05)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(reticle, mat_orange_glow)

    # -------------------------------------------------------------
    # 9. Subdivision Surface & Bevel Modifiers
    # -------------------------------------------------------------
    for obj in created_objects:
        if obj.type == 'MESH':
            # Add subtle Bevel for realistic stylized chamfered highlights
            bev = obj.modifiers.new(name="Bevel", type='BEVEL')
            bev.width = 0.015
            bev.segments = 2
            bev.limit_method = 'ANGLE'
            bev.angle_limit = math.radians(35)
            # Smooth shading
            for poly in obj.data.polygons:
                poly.use_smooth = True

    # -------------------------------------------------------------
    # 10. Join into Single Unified High-Poly Mesh
    # -------------------------------------------------------------
    mesh_objs = [o for o in created_objects if o.type == 'MESH']
    if mesh_objs:
        bpy.ops.object.select_all(action='DESELECT')
        for o in mesh_objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = mesh_objs[0]
        bpy.ops.object.join()
        unified_mesh = bpy.context.active_object
        unified_mesh.name = "LMG_HighPoly"
        
        # Add Subdivision Surface Modifier
        subd = unified_mesh.modifiers.new(name="Subdivision", type='SUBSURF')
        subd.levels = 1
        subd.render_levels = 2
    # -------------------------------------------------------------
    # Camera
    cam_data = bpy.data.cameras.new("Hero_Camera")
    cam_data.lens = 65  # Telephoto / portrait perspective
    cam_obj = bpy.data.objects.new("Hero_Camera", cam_data)
    coll.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj
    
    # Position camera for three-quarter hero view
    cam_obj.location = (1.5, -4.8, 1.8)
    cam_obj.rotation_euler = (math.radians(76), math.radians(0), math.radians(16))

    # Key Light (Upper front-right warm light)
    key_light_data = bpy.data.lights.new(name="Key_Light", type='AREA')
    key_light_data.energy = 450.0
    key_light_data.size = 3.0
    key_light_data.color = (1.0, 0.98, 0.95)
    key_light = bpy.data.objects.new("Key_Light", key_light_data)
    key_light.location = (2.0, -3.5, 3.5)
    key_light.rotation_euler = (math.radians(45), math.radians(15), math.radians(20))
    coll.objects.link(key_light)

    # Rim / Hair Light (Rear top backlight creating silhouette definition)
    rim_light_data = bpy.data.lights.new(name="Rim_Light", type='AREA')
    rim_light_data.energy = 600.0
    rim_light_data.size = 2.5
    rim_light_data.color = (0.85, 0.92, 1.0)
    rim_light = bpy.data.objects.new("Rim_Light", rim_light_data)
    rim_light.location = (0.5, 3.0, 3.0)
    rim_light.rotation_euler = (math.radians(-45), 0, math.radians(160))
    coll.objects.link(rim_light)

    # Fill Light (Soft subtle bounce from bottom left)
    fill_light_data = bpy.data.lights.new(name="Fill_Light", type='POINT')
    fill_light_data.energy = 120.0
    fill_light = bpy.data.objects.new("Fill_Light", fill_light_data)
    fill_light.location = (-1.5, -2.5, 0.5)
    coll.objects.link(fill_light)

    # Dark studio background
    world = bpy.context.scene.world
    if world is None:
        world = bpy.data.worlds.new("StudioWorld")
        bpy.context.scene.world = world
    world.use_nodes = True
    bg_node = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
    bg_node.inputs['Color'].default_value = (0.015, 0.015, 0.018, 1.0)
    bg_node.inputs['Strength'].default_value = 0.5

    # Render settings
    bpy.context.scene.render.resolution_x = 1280
    bpy.context.scene.render.resolution_y = 720
    bpy.context.scene.render.film_transparent = False

    blend_path = str(Path(__file__).resolve().parents[1] / 'models/stylized_lmg.blend')
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print(f"Saved Blender file to {blend_path}")

    print("Stylized Tactical LMG model generated successfully with all sub-assemblies and materials!")

create_stylized_lmg()
