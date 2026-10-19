import bpy
import bmesh
import math
import os
from mathutils import Vector, Euler, Matrix

def generate_final_stylized_lmg():
    # -------------------------------------------------------------------------
    # 1. Clean Scene
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
    # 2. PBR Shaders
    # -------------------------------------------------------------------------
    def get_or_create_mat(name, base_color, metallic=0.0, roughness=0.5, emission=None, emission_strength=1.0, transmission=0.0):
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

    m_green = get_or_create_mat("Mat_OliveArmor", (0.24, 0.31, 0.17, 1.0), metallic=0.18, roughness=0.35)
    m_dark_green = get_or_create_mat("Mat_DarkOlive", (0.14, 0.18, 0.11, 1.0), metallic=0.20, roughness=0.40)
    m_gunmetal = get_or_create_mat("Mat_GunmetalSteel", (0.04, 0.05, 0.06, 1.0), metallic=0.88, roughness=0.28)
    m_steel = get_or_create_mat("Mat_SteelAccents", (0.26, 0.29, 0.32, 1.0), metallic=0.92, roughness=0.22)
    m_teal = get_or_create_mat("Mat_TealShroud", (0.06, 0.14, 0.16, 1.0), metallic=0.62, roughness=0.34)
    m_brass = get_or_create_mat("Mat_BrassCartridge", (0.86, 0.62, 0.19, 1.0), metallic=0.96, roughness=0.18)
    m_copper = get_or_create_mat("Mat_CopperBullet", (0.82, 0.32, 0.14, 1.0), metallic=0.94, roughness=0.20)
    m_bronze = get_or_create_mat("Mat_BronzeBumper", (0.52, 0.38, 0.24, 1.0), metallic=0.82, roughness=0.32)
    m_orange = get_or_create_mat("Mat_OrangeLED", (1.0, 0.34, 0.01, 1.0), emission=(1.0, 0.34, 0.01, 1.0), emission_strength=12.0)
    m_amber_glass = get_or_create_mat("Mat_AmberGlass", (1.0, 0.48, 0.12, 1.0), roughness=0.06, transmission=0.88)

    # -------------------------------------------------------------------------
    # 3. Receiver & Chassis (Facing: Stock at -X, Muzzle at +X, Details on -Y)
    # -------------------------------------------------------------------------
    # Main Lower Receiver
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 0.28))
    rec = bpy.context.active_object
    rec.name = "Receiver_Chassis"
    rec.scale = (2.1, 0.52, 0.62)
    bpy.ops.object.transform_apply(scale=True)
    reg(rec, m_green)

    # Upper Receiver Dust Cover
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.05, 0.0, 0.64))
    rec_top = bpy.context.active_object
    rec_top.name = "Receiver_TopCover"
    rec_top.scale = (1.8, 0.46, 0.18)
    bpy.ops.object.transform_apply(scale=True)
    reg(rec_top, m_green)

    # Side Panels with Bevels
    for sign in [-1, 1]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.15, sign * 0.27, 0.32))
        panel = bpy.context.active_object
        panel.name = f"Receiver_Panel_{sign}"
        panel.scale = (1.35, 0.05, 0.38)
        bpy.ops.object.transform_apply(scale=True)
        reg(panel, m_dark_green)

    # Feed Tray / Port (on -Y side, viewer facing)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.05, -0.27, 0.40))
    port = bpy.context.active_object
    port.name = "Feed_Port"
    port.scale = (0.75, 0.08, 0.26)
    bpy.ops.object.transform_apply(scale=True)
    reg(port, m_gunmetal)

    # Receiver Screws / Rivets
    for idx, (px, pz) in enumerate([(-0.45, 0.12), (0.42, 0.14), (-0.75, 0.32)]):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=0.58, location=(px, 0.0, pz), rotation=(math.radians(90), 0, 0))
        pin = bpy.context.active_object
        pin.name = f"Receiver_Pin_{idx}"
        reg(pin, m_steel)

    # Glowing Orange LED on Receiver
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.48, -0.275, 0.68))
    led_rec = bpy.context.active_object
    led_rec.name = "Receiver_LED"
    led_rec.scale = (0.13, 0.035, 0.075)
    bpy.ops.object.transform_apply(scale=True)
    reg(led_rec, m_orange)

    # Rear Sight Aperture Post
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.48, 0.0, 0.72))
    rsight = bpy.context.active_object
    rsight.name = "Rear_Sight_Base"
    rsight.scale = (0.32, 0.34, 0.16)
    bpy.ops.object.transform_apply(scale=True)
    reg(rsight, m_gunmetal)

    # -------------------------------------------------------------------------
    # 4. Picatinny Rails (Top Spine)
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
    # 5. Stock Assembly
    # -------------------------------------------------------------------------
    # Stock Collar
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-1.20, 0.0, 0.30))
    collar = bpy.context.active_object
    collar.name = "Stock_Collar"
    collar.scale = (0.28, 0.44, 0.48)
    bpy.ops.object.transform_apply(scale=True)
    reg(collar, m_gunmetal)

    # Main Contoured Stock Body
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-1.80, 0.0, 0.22))
    s_body = bpy.context.active_object
    s_body.name = "Stock_Body"
    s_body.scale = (1.05, 0.36, 0.56)
    bpy.ops.object.transform_apply(scale=True)
    reg(s_body, m_green)

    # Lower Stock Cutout Plate (Dark Grey Composite)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-1.68, 0.0, -0.04))
    s_cut = bpy.context.active_object
    s_cut.name = "Stock_LowerPlate"
    s_cut.scale = (0.75, 0.34, 0.26)
    bpy.ops.object.transform_apply(scale=True)
    reg(s_cut, m_dark_green)

    # Rubberized Buttpad
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-2.38, 0.0, 0.24))
    bpad = bpy.context.active_object
    bpad.name = "Stock_Buttpad"
    bpad.scale = (0.16, 0.42, 0.80)
    bpy.ops.object.transform_apply(scale=True)
    reg(bpad, m_gunmetal)

    # Buttpad Mounting Screws (Facing -Y)
    for sz in [-0.08, 0.52]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.038, depth=0.16, location=(-2.40, -0.19, sz), rotation=(math.radians(90), 0, 0))
        sc = bpy.context.active_object
        sc.name = f"Stock_Screw_{sz}"
        reg(sc, m_steel)

    # -------------------------------------------------------------------------
    # 6. Pistol Grip & Trigger
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

    # Curved Trigger Shoe
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.25, 0.0, -0.12))
    trig = bpy.context.active_object
    trig.name = "Trigger"
    trig.rotation_euler = (0, math.radians(24), 0)
    trig.scale = (0.045, 0.05, 0.20)
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    reg(trig, m_steel)

    # -------------------------------------------------------------------------
    # 7. Box Magazine & Ammunition Belt
    # -------------------------------------------------------------------------
    # Magazine Main Pouch
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.10, -0.06, -0.62))
    mag = bpy.context.active_object
    mag.name = "Magazine_Box"
    mag.scale = (0.82, 0.62, 0.82)
    bpy.ops.object.transform_apply(scale=True)
    reg(mag, m_green)

    # Weathered Bronze Reinforcement Bumpers
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.10, -0.06, -0.62))
    mag_rim = bpy.context.active_object
    mag_rim.name = "Magazine_Bumper"
    mag_rim.scale = (0.88, 0.66, 0.86)
    bpy.ops.object.transform_apply(scale=True)
    reg(mag_rim, m_bronze)

    # Circular Hub Cap on Outer Face (Facing -Y)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.28, depth=0.08, location=(-0.10, -0.40, -0.62), rotation=(math.radians(90), 0, 0))
    hub = bpy.context.active_object
    hub.name = "Magazine_Hub_Outer"
    reg(hub, m_steel)

    # Inner Recessed Hub Ring
    bpy.ops.mesh.primitive_cylinder_add(radius=0.16, depth=0.10, location=(-0.10, -0.41, -0.62), rotation=(math.radians(90), 0, 0))
    hub_in = bpy.context.active_object
    hub_in.name = "Magazine_Hub_Inner"
    reg(hub_in, m_dark_green)

    # Center Hub Nut
    bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=0.12, location=(-0.10, -0.42, -0.62), rotation=(math.radians(90), 0, 0))
    hub_nut = bpy.context.active_object
    hub_nut.name = "Magazine_Hub_Nut"
    reg(hub_nut, m_gunmetal)

    # Ammunition Belt: 5 rounds feeding into the feed tray
    belt_data = [
        (-0.24, -0.36, 0.32, 14),
        (-0.12, -0.38, 0.36, 7),
        (0.01, -0.39, 0.38, 0),
        (0.14, -0.37, 0.39, -8),
        (0.26, -0.33, 0.40, -16)
    ]
    for idx, (bx, by, bz, brot) in enumerate(belt_data):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.046, depth=0.46, location=(bx, by, bz), rotation=(0, math.radians(90 + brot), 0))
        casing = bpy.context.active_object
        casing.name = f"Cartridge_Case_{idx}"
        reg(casing, m_brass)

        bpy.ops.mesh.primitive_cone_add(radius1=0.044, radius2=0.005, depth=0.18, location=(bx + 0.28, by, bz - math.sin(math.radians(brot))*0.04), rotation=(0, math.radians(90 + brot), 0))
        bullet = bpy.context.active_object
        bullet.name = f"Cartridge_Bullet_{idx}"
        reg(bullet, m_copper)

        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(bx - 0.04, by, bz))
        link = bpy.context.active_object
        link.name = f"Cartridge_Link_{idx}"
        link.scale = (0.16, 0.11, 0.11)
        bpy.ops.object.transform_apply(scale=True)
        reg(link, m_gunmetal)

    # -------------------------------------------------------------
    # 8. Handguard / Heat Shield
    # -------------------------------------------------------------
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(1.50, 0.0, 0.30))
    hguard = bpy.context.active_object
    hguard.name = "Handguard_Shroud"
    hguard.scale = (1.45, 0.48, 0.54)
    bpy.ops.object.transform_apply(scale=True)
    reg(hguard, m_teal)

    # Dual Rows of Oblong Cooling Vents (6 on each row)
    for rz in [0.20, 0.40]:
        for col in range(6):
            vx = 1.02 + col * 0.22
            bpy.ops.mesh.primitive_cube_add(size=1.0, location=(vx, -0.25, rz))
            vslot = bpy.context.active_object
            vslot.name = f"Vent_Slot_{rz}_{col}"
            vslot.scale = (0.13, 0.04, 0.065)
            bpy.ops.object.transform_apply(scale=True)
            reg(vslot, m_gunmetal)

    # Handguard Orange LED
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.95, -0.255, 0.46))
    led_hg = bpy.context.active_object
    led_hg.name = "Handguard_LED"
    led_hg.scale = (0.12, 0.035, 0.055)
    bpy.ops.object.transform_apply(scale=True)
    reg(led_hg, m_orange)

    # -------------------------------------------------------------
    # 9. Barrel, Gas Tube & Ported Muzzle Brake
    # -------------------------------------------------------------
    bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=2.25, location=(2.55, 0.0, 0.40), rotation=(0, math.radians(90), 0))
    barrel = bpy.context.active_object
    barrel.name = "Barrel_Main"
    reg(barrel, m_gunmetal)

    bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=1.55, location=(2.05, 0.0, 0.20), rotation=(0, math.radians(90), 0))
    gastube = bpy.context.active_object
    gastube.name = "Gas_Tube"
    reg(gastube, m_steel)

    # Front Sight Block
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(3.15, 0.0, 0.44))
    fsight = bpy.context.active_object
    fsight.name = "Front_Sight_Base"
    fsight.scale = (0.26, 0.30, 0.62)
    bpy.ops.object.transform_apply(scale=True)
    reg(fsight, m_gunmetal)

    # Front Sight Wings
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(3.18, 0.0, 0.84))
    fwings = bpy.context.active_object
    fwings.name = "Front_Sight_Wings"
    fwings.scale = (0.11, 0.20, 0.22)
    bpy.ops.object.transform_apply(scale=True)
    reg(fwings, m_gunmetal)

    # Front Sight Pin
    bpy.ops.mesh.primitive_cylinder_add(radius=0.018, depth=0.18, location=(3.18, 0.0, 0.84))
    fpin = bpy.context.active_object
    fpin.name = "Front_Sight_Pin"
    reg(fpin, m_steel)

    # Barrel Collar Ring
    bpy.ops.mesh.primitive_cylinder_add(radius=0.105, depth=0.08, location=(3.42, 0.0, 0.40), rotation=(0, math.radians(90), 0))
    bcollar = bpy.context.active_object
    bcollar.name = "Barrel_Collar"
    reg(bcollar, m_steel)

    # Muzzle Brake Body
    bpy.ops.mesh.primitive_cylinder_add(radius=0.11, depth=0.52, location=(3.92, 0.0, 0.40), rotation=(0, math.radians(90), 0))
    mbrake = bpy.context.active_object
    mbrake.name = "Muzzle_Brake"
    reg(mbrake, m_gunmetal)

    # Muzzle Gas Compensation Slots
    for mx in [3.78, 3.92, 4.06]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(mx, 0.0, 0.40))
        mslot = bpy.context.active_object
        mslot.name = f"Muzzle_Slot_{mx}"
        mslot.scale = (0.055, 0.24, 0.15)
        bpy.ops.object.transform_apply(scale=True)
        reg(mslot, m_steel)

    # -------------------------------------------------------------
    # 10. Tactical Reflex Sight Optic
    # -------------------------------------------------------------
    # Riser Mount
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.38, 0.0, 0.90))
    opt_mount = bpy.context.active_object
    opt_mount.name = "Optic_Mount"
    opt_mount.scale = (0.58, 0.32, 0.10)
    bpy.ops.object.transform_apply(scale=True)
    reg(opt_mount, m_gunmetal)

    # Thumbscrew Knob
    bpy.ops.mesh.primitive_cylinder_add(radius=0.055, depth=0.38, location=(0.35, 0.0, 0.90), rotation=(math.radians(90), 0, 0))
    opt_knob = bpy.context.active_object
    opt_knob.name = "Optic_Mount_Knob"
    reg(opt_knob, m_steel)

    # Hooded Optic Housing (Olive Green)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.42, 0.0, 1.18))
    opt_hood = bpy.context.active_object
    opt_hood.name = "Optic_Hood"
    opt_hood.scale = (0.52, 0.38, 0.40)
    bpy.ops.object.transform_apply(scale=True)
    reg(opt_hood, m_green)

    # Battery Turret
    bpy.ops.mesh.primitive_cylinder_add(radius=0.075, depth=0.42, location=(0.14, 0.0, 1.12), rotation=(0, math.radians(90), 0))
    opt_turret = bpy.context.active_object
    opt_turret.name = "Optic_Turret"
    reg(opt_turret, m_gunmetal)

    # Amber Coated Glass Lens
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.58, 0.0, 1.18))
    opt_lens = bpy.context.active_object
    opt_lens.name = "Optic_Lens"
    opt_lens.scale = (0.035, 0.30, 0.30)
    bpy.ops.object.transform_apply(scale=True)
    reg(opt_lens, m_amber_glass)

    # Glowing Reticle Dot
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.59, 0.0, 1.18))
    reticle = bpy.context.active_object
    reticle.name = "Optic_Reticle_Dot"
    reticle.scale = (0.015, 0.045, 0.045)
    bpy.ops.object.transform_apply(scale=True)
    reg(reticle, m_orange)

    # -------------------------------------------------------------
    # 11. Bevel Modifiers, Smooth Shading & Unified Mesh Assembly
    # -------------------------------------------------------------
    for obj in created_objects:
        if obj.type == 'MESH':
            bev = obj.modifiers.new(name="Bevel", type='BEVEL')
            bev.width = 0.012
            bev.segments = 2
            bev.limit_method = 'ANGLE'
            bev.angle_limit = math.radians(35)
            for poly in obj.data.polygons:
                poly.use_smooth = True

    # Join into single unified high-poly mesh
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
    # 12. Camera Tracking & Studio Lighting
    # -------------------------------------------------------------
    target = bpy.data.objects.new("Camera_Target", None)
    coll.objects.link(target)
    target.location = (0.9, -0.1, 0.15)

    # Hero Camera with Track-To Constraint & Balanced Framing
    cam_data = bpy.data.cameras.new("Hero_Camera")
    cam_data.lens = 42  # Perfect framing for entire weapon length
    cam_obj = bpy.data.objects.new("Hero_Camera", cam_data)
    coll.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj
    cam_obj.location = (1.5, -9.2, 1.3)
    
    con = cam_obj.constraints.new(type='TRACK_TO')
    con.target = target
    con.track_axis = 'TRACK_NEGATIVE_Z'
    con.up_axis = 'UP_Y'

    # Side Orthographic Camera
    side_cam_data = bpy.data.cameras.new("Side_Camera")
    side_cam_data.type = 'ORTHO'
    side_cam_data.ortho_scale = 7.2
    side_cam_obj = bpy.data.objects.new("Side_Camera", side_cam_data)
    coll.objects.link(side_cam_obj)
    side_cam_obj.location = (0.9, -6.5, 0.2)
    side_cam_obj.rotation_euler = (math.radians(90), 0, 0)

    # Lighting: 3-Point Studio Setup
    key_l = bpy.data.objects.new("Key_Light", bpy.data.lights.new("Key_Light", type='AREA'))
    key_l.data.energy = 650.0
    key_l.data.size = 4.0
    key_l.data.color = (1.0, 0.97, 0.94)
    key_l.location = (2.4, -5.5, 3.5)
    key_l.rotation_euler = (math.radians(50), math.radians(15), math.radians(-25))
    coll.objects.link(key_l)

    rim_l = bpy.data.objects.new("Rim_Light", bpy.data.lights.new("Rim_Light", type='AREA'))
    rim_l.data.energy = 850.0
    rim_l.data.size = 3.5
    rim_l.data.color = (0.85, 0.92, 1.0)
    rim_l.location = (0.5, 4.0, 3.5)
    rim_l.rotation_euler = (math.radians(-45), 0, math.radians(160))
    coll.objects.link(rim_l)

    fill_l = bpy.data.objects.new("Fill_Light", bpy.data.lights.new("Fill_Light", type='POINT'))
    fill_l.data.energy = 180.0
    fill_l.location = (-2.0, -3.5, 0.3)
    coll.objects.link(fill_l)

    # Studio World
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
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 900
    scene.render.film_transparent = False

    # Save Blend File
    blend_path = "/Users/shashankkumar/Desktop/Game Development/stylized_lmg/stylized_lmg.blend"
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print(f"Saved completed blend file to: {blend_path}")

    # Render Hero Shot
    scene.camera = cam_obj
    hero_path = "/Users/shashankkumar/Desktop/Game Development/stylized_lmg/render_hero.png"
    scene.render.filepath = hero_path
    bpy.ops.render.render(write_still=True)
    print(f"Rendered Hero Image to: {hero_path}")

    # Render Orthographic Side Shot
    scene.camera = side_cam_obj
    side_path = "/Users/shashankkumar/Desktop/Game Development/stylized_lmg/render_side.png"
    scene.render.filepath = side_path
    bpy.ops.render.render(write_still=True)
    print(f"Rendered Side Image to: {side_path}")

generate_final_stylized_lmg()
