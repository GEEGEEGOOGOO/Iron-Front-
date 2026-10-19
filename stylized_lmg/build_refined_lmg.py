import bpy
import bmesh
import math
import os
from mathutils import Vector, Euler, Matrix

def build_highpoly_lmg():
    # -------------------------------------------------------------------------
    # Scene Cleanup & Initialization
    # -------------------------------------------------------------------------
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    
    # Clean unused meshes and materials
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

    def register_obj(obj, mat=None):
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
    # Materials Definition
    # -------------------------------------------------------------------------
    def get_or_create_material(name, base_color, metallic=0.0, roughness=0.5, emission=None, emission_strength=1.0, transmission=0.0):
        mat = bpy.data.materials.get(name)
        if mat is None:
            mat = bpy.data.materials.new(name=name)
            mat.use_nodes = True
        
        nodes = mat.node_tree.nodes
        bsdf = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
        
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

    # Accurate colors sampled & refined from the reference image
    mat_green = get_or_create_material("Mat_OliveArmor", (0.22, 0.29, 0.16, 1.0), metallic=0.18, roughness=0.35)
    mat_dark_green = get_or_create_material("Mat_DarkOlive", (0.13, 0.17, 0.10, 1.0), metallic=0.20, roughness=0.42)
    mat_gunmetal = get_or_create_material("Mat_GunmetalSteel", (0.04, 0.05, 0.06, 1.0), metallic=0.88, roughness=0.30)
    mat_steel = get_or_create_material("Mat_SteelAccents", (0.24, 0.27, 0.29, 1.0), metallic=0.92, roughness=0.22)
    mat_teal = get_or_create_material("Mat_TealShroud", (0.05, 0.13, 0.15, 1.0), metallic=0.62, roughness=0.36)
    mat_brass = get_or_create_material("Mat_BrassCartridge", (0.86, 0.62, 0.19, 1.0), metallic=0.96, roughness=0.18)
    mat_copper = get_or_create_material("Mat_CopperBullet", (0.82, 0.32, 0.14, 1.0), metallic=0.94, roughness=0.20)
    mat_bronze = get_or_create_material("Mat_BronzeBumper", (0.52, 0.38, 0.24, 1.0), metallic=0.82, roughness=0.35)
    mat_orange_led = get_or_create_material("Mat_OrangeLED", (1.0, 0.32, 0.01, 1.0), emission=(1.0, 0.32, 0.01, 1.0), emission_strength=10.0)
    mat_amber_glass = get_or_create_material("Mat_AmberGlass", (1.0, 0.48, 0.12, 1.0), roughness=0.08, transmission=0.88)

    # -------------------------------------------------------------------------
    # 1. Receiver & Chassis (Facing: Stock at -X, Barrel at +X, Front at -Y)
    # -------------------------------------------------------------------------
    # Main lower receiver chassis
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 0.28))
    rec = bpy.context.active_object
    rec.name = "Receiver_Chassis"
    rec.scale = (2.1, 0.52, 0.62)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(rec, mat_green)

    # Receiver top cover with chamfer
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.05, 0.0, 0.64))
    rec_top = bpy.context.active_object
    rec_top.name = "Receiver_TopCover"
    rec_top.scale = (1.8, 0.46, 0.18)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(rec_top, mat_green)

    # Side decorative panels with chamfered bevels
    for sign in [-1, 1]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.15, sign * 0.27, 0.32))
        panel = bpy.context.active_object
        panel.name = f"Receiver_Panel_{sign}"
        panel.scale = (1.35, 0.05, 0.38)
        bpy.ops.object.transform_apply(scale=True)
        register_obj(panel, mat_dark_green)

    # Ejection / Ammo Feed Port (on -Y side, viewer facing)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.05, -0.27, 0.40))
    port = bpy.context.active_object
    port.name = "Feed_Port"
    port.scale = (0.75, 0.08, 0.26)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(port, mat_gunmetal)

    # Receiver Pins / Rivet Screws
    pins_data = [(-0.45, 0.12), (0.42, 0.14), (-0.75, 0.32)]
    for idx, (px, pz) in enumerate(pins_data):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=0.58, location=(px, 0.0, pz), rotation=(math.radians(90), 0, 0))
        pin = bpy.context.active_object
        pin.name = f"Receiver_Pin_{idx}"
        register_obj(pin, mat_gunmetal)

    # Glowing Orange Indicator LED on Receiver (viewer side -Y)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.48, -0.275, 0.68))
    led_rec = bpy.context.active_object
    led_rec.name = "Receiver_LED"
    led_rec.scale = (0.13, 0.035, 0.075)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(led_rec, mat_orange_led)

    # Rear Iron Sight Housing
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.48, 0.0, 0.72))
    rsight = bpy.context.active_object
    rsight.name = "Rear_Sight_Base"
    rsight.scale = (0.32, 0.34, 0.16)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(rsight, mat_gunmetal)

    # -------------------------------------------------------------------------
    # 2. Picatinny Rails (Top Spine)
    # -------------------------------------------------------------------------
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.65, 0.0, 0.78))
    rail_base = bpy.context.active_object
    rail_base.name = "Picatinny_Rail_Base"
    rail_base.scale = (2.4, 0.30, 0.06)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(rail_base, mat_gunmetal)

    num_teeth = 22
    start_tx = -0.35
    end_tx = 1.75
    step_tx = (end_tx - start_tx) / (num_teeth - 1)
    for i in range(num_teeth):
        tx = start_tx + i * step_tx
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(tx, 0.0, 0.82))
        tooth = bpy.context.active_object
        tooth.name = f"Rail_Tooth_{i}"
        tooth.scale = (step_tx * 0.58, 0.32, 0.04)
        bpy.ops.object.transform_apply(scale=True)
        register_obj(tooth, mat_gunmetal)

    # -------------------------------------------------------------------------
    # 3. Stock Assembly (Left Side / -X)
    # -------------------------------------------------------------------------
    # Stock Collar Ring
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-1.20, 0.0, 0.30))
    collar = bpy.context.active_object
    collar.name = "Stock_Collar"
    collar.scale = (0.28, 0.44, 0.48)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(collar, mat_gunmetal)

    # Main Contoured Stock Body
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-1.80, 0.0, 0.22))
    stock_body = bpy.context.active_object
    stock_body.name = "Stock_Body"
    stock_body.scale = (1.05, 0.36, 0.56)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(stock_body, mat_green)

    # Lower Stock Cutout Plate (Dark Grey Composite)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-1.68, 0.0, -0.04))
    stock_cut = bpy.context.active_object
    stock_cut.name = "Stock_LowerPlate"
    stock_cut.scale = (0.75, 0.34, 0.26)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(stock_cut, mat_dark_green)

    # Rubberized Buttpad
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-2.38, 0.0, 0.24))
    buttpad = bpy.context.active_object
    buttpad.name = "Stock_Buttpad"
    buttpad.scale = (0.16, 0.42, 0.80)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(buttpad, mat_gunmetal)

    # Buttpad Mounting Screws (Facing -Y)
    for sz in [-0.08, 0.52]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.038, depth=0.16, location=(-2.40, -0.19, sz), rotation=(math.radians(90), 0, 0))
        sc = bpy.context.active_object
        sc.name = f"Stock_Screw_{sz}"
        register_obj(sc, mat_steel)

    # -------------------------------------------------------------------------
    # 4. Pistol Grip & Trigger Assembly
    # -------------------------------------------------------------------------
    # Ergonomic Angled Grip
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.56, 0.0, -0.38))
    grip = bpy.context.active_object
    grip.name = "Pistol_Grip"
    grip.rotation_euler = (0, math.radians(18), 0)
    grip.scale = (0.34, 0.32, 0.76)
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    register_obj(grip, mat_gunmetal)

    # Grip Side Panels (Teal / Green Inlay)
    for sign in [-1, 1]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.56, sign * 0.17, -0.38))
        gpanel = bpy.context.active_object
        gpanel.name = f"Grip_Panel_{sign}"
        gpanel.rotation_euler = (0, math.radians(18), 0)
        gpanel.scale = (0.22, 0.035, 0.50)
        bpy.ops.object.transform_apply(rotation=True, scale=True)
        register_obj(gpanel, mat_teal)

    # Trigger Guard Loop
    bpy.ops.mesh.primitive_cylinder_add(radius=0.26, depth=0.10, location=(-0.24, 0.0, -0.12), rotation=(math.radians(90), 0, 0))
    tguard = bpy.context.active_object
    tguard.name = "Trigger_Guard"
    tguard.scale = (1.0, 1.0, 0.60)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(tguard, mat_gunmetal)

    # Trigger Shoe
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.25, 0.0, -0.12))
    trig = bpy.context.active_object
    trig.name = "Trigger"
    trig.rotation_euler = (0, math.radians(24), 0)
    trig.scale = (0.045, 0.05, 0.20)
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    register_obj(trig, mat_steel)

    # -------------------------------------------------------------------------
    # 5. Box Magazine & Exposed Cartridge Belt
    # -------------------------------------------------------------------------
    # Magazine Main Pouch / Box
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.10, -0.06, -0.62))
    mag = bpy.context.active_object
    mag.name = "Magazine_Box"
    mag.scale = (0.82, 0.62, 0.82)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(mag, mat_green)

    # Weathered Bronze Reinforcement Bumpers
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.10, -0.06, -0.62))
    mag_rim = bpy.context.active_object
    mag_rim.name = "Magazine_Bumper"
    mag_rim.scale = (0.88, 0.66, 0.86)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(mag_rim, mat_bronze)

    # Circular Hub Cap on Outer Face (Facing -Y)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.28, depth=0.08, location=(-0.10, -0.40, -0.62), rotation=(math.radians(90), 0, 0))
    hub = bpy.context.active_object
    hub.name = "Magazine_Hub_Outer"
    register_obj(hub, mat_steel)

    # Inner Recessed Hub Ring
    bpy.ops.mesh.primitive_cylinder_add(radius=0.16, depth=0.10, location=(-0.10, -0.41, -0.62), rotation=(math.radians(90), 0, 0))
    hub_in = bpy.context.active_object
    hub_in.name = "Magazine_Hub_Inner"
    register_obj(hub_in, mat_dark_green)

    # Center Hub Nut
    bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=0.12, location=(-0.10, -0.42, -0.62), rotation=(math.radians(90), 0, 0))
    hub_nut = bpy.context.active_object
    hub_nut.name = "Magazine_Hub_Nut"
    register_obj(hub_nut, mat_gunmetal)

    # Ammunition Belt: 5 rounds curving from magazine upward to feed port on -Y
    belt_data = [
        (-0.24, -0.36, 0.32, 14),
        (-0.12, -0.38, 0.36, 7),
        (0.01, -0.39, 0.38, 0),
        (0.14, -0.37, 0.39, -8),
        (0.26, -0.33, 0.40, -16)
    ]
    for idx, (bx, by, bz, brot) in enumerate(belt_data):
        # Brass Cartridge Casing
        bpy.ops.mesh.primitive_cylinder_add(radius=0.046, depth=0.46, location=(bx, by, bz), rotation=(0, math.radians(90 + brot), 0))
        casing = bpy.context.active_object
        casing.name = f"Cartridge_Case_{idx}"
        register_obj(casing, mat_brass)

        # Copper Bullet Tip
        bpy.ops.mesh.primitive_cone_add(radius1=0.044, radius2=0.005, depth=0.18, location=(bx + 0.28, by, bz - math.sin(math.radians(brot))*0.04), rotation=(0, math.radians(90 + brot), 0))
        bullet = bpy.context.active_object
        bullet.name = f"Cartridge_Bullet_{idx}"
        register_obj(bullet, mat_copper)

        # Black Steel Disintegrating Link Clip
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(bx - 0.04, by, bz))
        link = bpy.context.active_object
        link.name = f"Cartridge_Link_{idx}"
        link.scale = (0.16, 0.11, 0.11)
        bpy.ops.object.transform_apply(scale=True)
        register_obj(link, mat_gunmetal)

    # -------------------------------------------------------------------------
    # 6. Handguard / Heat Shield & Cooling Vents
    # -------------------------------------------------------------------------
    # Main Handguard Shroud (Teal Metallic)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(1.50, 0.0, 0.30))
    hguard = bpy.context.active_object
    hguard.name = "Handguard_Shroud"
    hguard.scale = (1.45, 0.48, 0.54)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(hguard, mat_teal)

    # Handguard Cooling Vents (Dual Row of horizontal slots on -Y face)
    for rz in [0.20, 0.40]:
        for col in range(6):
            vx = 1.02 + col * 0.22
            bpy.ops.mesh.primitive_cube_add(size=1.0, location=(vx, -0.25, rz))
            vslot = bpy.context.active_object
            vslot.name = f"Vent_Slot_{rz}_{col}"
            vslot.scale = (0.13, 0.04, 0.065)
            bpy.ops.object.transform_apply(scale=True)
            register_obj(vslot, mat_gunmetal)

    # Orange Indicator LED on Handguard
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.95, -0.255, 0.46))
    led_hg = bpy.context.active_object
    led_hg.name = "Handguard_LED"
    led_hg.scale = (0.12, 0.035, 0.055)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(led_hg, mat_orange_led)

    # -------------------------------------------------------------------------
    # 7. Barrel, Gas Tube & Ported Muzzle Brake
    # -------------------------------------------------------------------------
    # Main Steel Barrel
    bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=2.25, location=(2.55, 0.0, 0.40), rotation=(0, math.radians(90), 0))
    barrel = bpy.context.active_object
    barrel.name = "Barrel_Main"
    register_obj(barrel, mat_gunmetal)

    # Gas Tube (Parallel underneath barrel)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=1.55, location=(2.05, 0.0, 0.20), rotation=(0, math.radians(90), 0))
    gastube = bpy.context.active_object
    gastube.name = "Gas_Tube"
    register_obj(gastube, mat_steel)

    # Front Sight / Gas Block Base
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(3.15, 0.0, 0.44))
    fsight_base = bpy.context.active_object
    fsight_base.name = "Front_Sight_Base"
    fsight_base.scale = (0.26, 0.30, 0.62)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(fsight_base, mat_gunmetal)

    # Front Sight Protective Wings
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(3.18, 0.0, 0.84))
    fsight_wings = bpy.context.active_object
    fsight_wings.name = "Front_Sight_Wings"
    fsight_wings.scale = (0.11, 0.20, 0.22)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(fsight_wings, mat_gunmetal)

    # Front Sight Vertical Pin
    bpy.ops.mesh.primitive_cylinder_add(radius=0.018, depth=0.18, location=(3.18, 0.0, 0.84))
    fpin = bpy.context.active_object
    fpin.name = "Front_Sight_Pin"
    register_obj(fpin, mat_steel)

    # Barrel Collar Ring
    bpy.ops.mesh.primitive_cylinder_add(radius=0.105, depth=0.08, location=(3.42, 0.0, 0.40), rotation=(0, math.radians(90), 0))
    bcollar = bpy.context.active_object
    bcollar.name = "Barrel_Collar"
    register_obj(bcollar, mat_steel)

    # Heavy Cylindrical Muzzle Brake
    bpy.ops.mesh.primitive_cylinder_add(radius=0.11, depth=0.52, location=(3.92, 0.0, 0.40), rotation=(0, math.radians(90), 0))
    mbrake = bpy.context.active_object
    mbrake.name = "Muzzle_Brake"
    register_obj(mbrake, mat_gunmetal)

    # Muzzle Brake Gas Slots (Cutout Details)
    for mx in [3.78, 3.92, 4.06]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(mx, 0.0, 0.40))
        mslot = bpy.context.active_object
        mslot.name = f"Muzzle_Slot_{mx}"
        mslot.scale = (0.055, 0.24, 0.15)
        bpy.ops.object.transform_apply(scale=True)
        register_obj(mslot, mat_steel)

    # -------------------------------------------------------------------------
    # 8. Tactical Reflex Sight Optic
    # -------------------------------------------------------------------------
    # Picatinny Riser Mount
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.38, 0.0, 0.90))
    opt_mount = bpy.context.active_object
    opt_mount.name = "Optic_Mount"
    opt_mount.scale = (0.58, 0.32, 0.10)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(opt_mount, mat_gunmetal)

    # Mount Knurled Thumbscrew (Facing -Y)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.055, depth=0.38, location=(0.35, 0.0, 0.90), rotation=(math.radians(90), 0, 0))
    opt_knob = bpy.context.active_object
    opt_knob.name = "Optic_Mount_Knob"
    register_obj(opt_knob, mat_steel)

    # Main Optic Housing / Hood (Olive Green)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.42, 0.0, 1.18))
    opt_hood = bpy.context.active_object
    opt_hood.name = "Optic_Hood"
    opt_hood.scale = (0.52, 0.38, 0.40)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(opt_hood, mat_green)

    # Top Cylindrical Battery / Elevation Turret
    bpy.ops.mesh.primitive_cylinder_add(radius=0.075, depth=0.42, location=(0.14, 0.0, 1.12), rotation=(0, math.radians(90), 0))
    opt_turret = bpy.context.active_object
    opt_turret.name = "Optic_Turret"
    register_obj(opt_turret, mat_gunmetal)

    # Amber Coated Reflex Glass Lens
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.58, 0.0, 1.18))
    opt_lens = bpy.context.active_object
    opt_lens.name = "Optic_Lens"
    opt_lens.scale = (0.035, 0.30, 0.30)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(opt_lens, mat_amber_glass)

    # Glowing Reticle Center Dot
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.59, 0.0, 1.18))
    reticle = bpy.context.active_object
    reticle.name = "Optic_Reticle_Dot"
    reticle.scale = (0.015, 0.045, 0.045)
    bpy.ops.object.transform_apply(scale=True)
    register_obj(reticle, mat_orange_led)

    # -------------------------------------------------------------------------
    # 9. Modifiers, Shading & Unified Mesh Assembly
    # -------------------------------------------------------------------------
    for obj in created_objects:
        if obj.type == 'MESH':
            # Add subtle Bevel modifier for realistic stylized hard-surface highlights
            bev = obj.modifiers.new(name="Bevel", type='BEVEL')
            bev.width = 0.012
            bev.segments = 2
            bev.limit_method = 'ANGLE'
            bev.angle_limit = math.radians(35)
            for poly in obj.data.polygons:
                poly.use_smooth = True

    # Join into single unified high-poly mesh as requested by user
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

    # -------------------------------------------------------------------------
    # 10. Studio Camera & Presentation Lighting matching Reference
    # -------------------------------------------------------------------------
    # Hero Camera matching three-quarter side elevation
    cam_data = bpy.data.cameras.new("Hero_Camera")
    cam_data.lens = 70  # Telephoto compression matching reference
    cam_obj = bpy.data.objects.new("Hero_Camera", cam_data)
    coll.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj

    # Position camera: X=1.1, Y=-5.8, Z=1.1, looking slightly down and to right
    cam_obj.location = (1.1, -5.8, 1.1)
    cam_obj.rotation_euler = (math.radians(82), math.radians(0), math.radians(-10))

    # Side Orthographic Camera for detail inspection
    side_cam_data = bpy.data.cameras.new("Side_Camera")
    side_cam_data.type = 'ORTHO'
    side_cam_data.ortho_scale = 7.0
    side_cam_obj = bpy.data.objects.new("Side_Camera", side_cam_data)
    coll.objects.link(side_cam_obj)
    side_cam_obj.location = (0.8, -6.0, 0.2)
    side_cam_obj.rotation_euler = (math.radians(90), 0, 0)

    # Key Light (Warm frontal illumination)
    key_light_data = bpy.data.lights.new(name="Key_Light", type='AREA')
    key_light_data.energy = 550.0
    key_light_data.size = 3.5
    key_light_data.color = (1.0, 0.96, 0.92)
    key_light = bpy.data.objects.new("Key_Light", key_light_data)
    key_light.location = (2.2, -4.2, 3.2)
    key_light.rotation_euler = (math.radians(45), math.radians(15), math.radians(-25))
    coll.objects.link(key_light)

    # Rim Light (Cool silhouette edge backlight)
    rim_light_data = bpy.data.lights.new(name="Rim_Light", type='AREA')
    rim_light_data.energy = 750.0
    rim_light_data.size = 2.8
    rim_light_data.color = (0.82, 0.90, 1.0)
    rim_light = bpy.data.objects.new("Rim_Light", rim_light_data)
    rim_light.location = (0.2, 3.5, 3.2)
    rim_light.rotation_euler = (math.radians(-40), 0, math.radians(165))
    coll.objects.link(rim_light)

    # Fill Light (Gentle lower fill)
    fill_light_data = bpy.data.lights.new(name="Fill_Light", type='POINT')
    fill_light_data.energy = 160.0
    fill_light = bpy.data.objects.new("Fill_Light", fill_light_data)
    fill_light.location = (-1.8, -3.2, 0.2)
    coll.objects.link(fill_light)

    # World Environment (Dark studio backdrop)
    world = bpy.context.scene.world
    if world is None:
        world = bpy.data.worlds.new("StudioWorld")
        bpy.context.scene.world = world
    world.use_nodes = True
    bg_node = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
    bg_node.inputs['Color'].default_value = (0.012, 0.012, 0.015, 1.0)
    bg_node.inputs['Strength'].default_value = 0.4

    # Render settings
    scene = bpy.context.scene
    scene.render.resolution_x = 1440
    scene.render.resolution_y = 810
    scene.render.film_transparent = False

    # Save Blend file
    blend_path = "/Users/shashankkumar/Desktop/Game Development/stylized_lmg/stylized_lmg.blend"
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print(f"Saved refined high-poly model to {blend_path}")

    # Render Hero Image
    scene.camera = cam_obj
    hero_render_path = "/Users/shashankkumar/Desktop/Game Development/stylized_lmg/render_hero.png"
    scene.render.filepath = hero_render_path
    bpy.ops.render.render(write_still=True)
    print(f"Rendered Hero Image to {hero_render_path}")

    # Render Orthographic Side View
    scene.camera = side_cam_obj
    side_render_path = "/Users/shashankkumar/Desktop/Game Development/stylized_lmg/render_side.png"
    scene.render.filepath = side_render_path
    bpy.ops.render.render(write_still=True)
    print(f"Rendered Side Image to {side_render_path}")

build_highpoly_lmg()
