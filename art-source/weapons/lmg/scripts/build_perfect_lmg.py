from pathlib import Path
import bpy
import bmesh
import math
import os
from mathutils import Vector, Euler, Matrix

def build_perfect_lmg():
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
    # 2. PBR Materials Definition (Rich, Saturated, Stylized)
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

    # Exact palette matching reference concept
    m_olive = get_or_create_mat("Mat_OliveArmor", (0.24, 0.31, 0.17, 1.0), metallic=0.18, roughness=0.35)
    m_dark_olive = get_or_create_mat("Mat_DarkOlive", (0.13, 0.17, 0.10, 1.0), metallic=0.20, roughness=0.42)
    m_gunmetal = get_or_create_mat("Mat_GunmetalSteel", (0.05, 0.06, 0.07, 1.0), metallic=0.88, roughness=0.28)
    m_steel = get_or_create_mat("Mat_SteelAccents", (0.28, 0.31, 0.34, 1.0), metallic=0.94, roughness=0.20)
    m_teal = get_or_create_mat("Mat_TealShroud", (0.05, 0.15, 0.18, 1.0), metallic=0.65, roughness=0.34)
    m_brass = get_or_create_mat("Mat_BrassCartridge", (0.88, 0.64, 0.19, 1.0), metallic=0.98, roughness=0.15)
    m_copper = get_or_create_mat("Mat_CopperBullet", (0.84, 0.34, 0.14, 1.0), metallic=0.96, roughness=0.18)
    m_bronze = get_or_create_mat("Mat_BronzeBumper", (0.55, 0.40, 0.25, 1.0), metallic=0.85, roughness=0.32)
    m_orange_led = get_or_create_mat("Mat_OrangeLED", (1.0, 0.35, 0.01, 1.0), emission=(1.0, 0.35, 0.01, 1.0), emission_strength=15.0)
    m_amber_lens = get_or_create_mat("Mat_AmberLens", (1.0, 0.50, 0.10, 1.0), roughness=0.04, transmission=0.90)

    # -------------------------------------------------------------------------
    # 3. Receiver & Chassis (Facing: Stock at -X, Muzzle at +X, Details on -Y)
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

    # Recessed Side Decorative Armor Panels with Bevels
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
    # 7. Olive Green Drum Magazine & Weathered Bronze Bumpers
    # -------------------------------------------------------------------------
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.08, -0.06, -0.62))
    mag = bpy.context.active_object
    mag.name = "Magazine_Box"
    mag.rotation_euler = (0, math.radians(-3), 0)
    mag.scale = (0.82, 0.62, 0.82)
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    reg(mag, m_olive)

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
    reg(hub_in, m_dark_olive)

    # Center Boss Nut
    bpy.ops.mesh.primitive_cylinder_add(radius=0.07, depth=0.12, location=(-0.08, -0.42, -0.62), rotation=(math.radians(90), 0, 0))
    hub_nut = bpy.context.active_object
    hub_nut.name = "Magazine_Hub_Nut"
    reg(hub_nut, m_gunmetal)

    # -------------------------------------------------------------------------
    # 8. Curved Ammunition Belt (5 Rounds in Natural Arc)
    # -------------------------------------------------------------------------
    belt_arc = [
        (-0.24, -0.36, 0.28, 18),
        (-0.13, -0.38, 0.33, 10),
        (-0.01, -0.39, 0.37, 2),
        (0.12, -0.38, 0.40, -6),
        (0.24, -0.34, 0.42, -14)
    ]
    for idx, (bx, by, bz, brot) in enumerate(belt_arc):
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

    # -------------------------------------------------------------------------
    # 9. Handguard / Heat Shield & Recessed Cooling Slots (Clean & Robust)
    # -------------------------------------------------------------------------
    # Upper Rail / Shroud Spine
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(1.50, 0.0, 0.52))
    hg_spine = bpy.context.active_object
    hg_spine.name = "Handguard_Spine"
    hg_spine.scale = (1.45, 0.44, 0.12)
    bpy.ops.object.transform_apply(scale=True)
    reg(hg_spine, m_gunmetal)

    # Lower Shroud Grip Plate
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(1.50, 0.0, 0.08))
    hg_base = bpy.context.active_object
    hg_base.name = "Handguard_Base"
    hg_base.scale = (1.45, 0.44, 0.12)
    bpy.ops.object.transform_apply(scale=True)
    reg(hg_base, m_gunmetal)

    # Teal Side Plates (Left & Right)
    for sign in [-1, 1]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(1.50, sign * 0.22, 0.30))
        hg_side = bpy.context.active_object
        hg_side.name = f"Handguard_Side_{sign}"
        hg_side.scale = (1.45, 0.06, 0.38)
        bpy.ops.object.transform_apply(scale=True)
        reg(hg_side, m_teal)

    # Recessed Dark Pill Cooling Slots on the visible -Y face
    # By creating dark recessed cavities set into the teal plate, we achieve crisp pill slots with 0 boolean artifacts!
    for rz in [0.22, 0.38]:
        for col in range(5):
            vx = 1.08 + col * 0.21
            # Inner recessed dark cavity
            bpy.ops.mesh.primitive_cube_add(size=1.0, location=(vx, -0.225, rz))
            slot_inner = bpy.context.active_object
            slot_inner.name = f"Vent_Slot_{rz}_{col}"
            slot_inner.scale = (0.11, 0.04, 0.055)
            bpy.ops.object.transform_apply(scale=True)
            reg(slot_inner, m_gunmetal)
            
            # Subtle rounded end caps for pill look
            for end_sign in [-1, 1]:
                bpy.ops.mesh.primitive_cylinder_add(radius=0.027, depth=0.04, location=(vx + end_sign * 0.055, -0.225, rz), rotation=(math.radians(90), 0, 0))
                cyl_cap = bpy.context.active_object
                cyl_cap.name = f"Vent_Cap_{rz}_{col}_{end_sign}"
                reg(cyl_cap, m_gunmetal)

    # Recessed Bezel & Orange LED on Handguard
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.95, -0.24, 0.46))
    led_bezel_hg = bpy.context.active_object
    led_bezel_hg.name = "HG_LED_Bezel"
    led_bezel_hg.scale = (0.14, 0.035, 0.075)
    bpy.ops.object.transform_apply(scale=True)
    reg(led_bezel_hg, m_gunmetal)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.95, -0.25, 0.46))
    led_hg = bpy.context.active_object
    led_hg.name = "Handguard_LED"
    led_hg.scale = (0.10, 0.03, 0.05)
    bpy.ops.object.transform_apply(scale=True)
    reg(led_hg, m_orange_led)

    # -------------------------------------------------------------------------
    # 10. Stepped Barrel, Gas Block with Wings & Ported Muzzle Brake
    # -------------------------------------------------------------------------
    # Main Barrel
    bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=2.25, location=(2.55, 0.0, 0.36), rotation=(0, math.radians(90), 0))
    barrel = bpy.context.active_object
    barrel.name = "Barrel_Main"
    reg(barrel, m_gunmetal)

    # Gas Cylinder Tube underneath
    bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=1.55, location=(2.05, 0.0, 0.18), rotation=(0, math.radians(90), 0))
    gastube = bpy.context.active_object
    gastube.name = "Gas_Tube"
    reg(gastube, m_steel)

    # Front Sight Block Bracket
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(3.15, 0.0, 0.40))
    fsight = bpy.context.active_object
    fsight.name = "Front_Sight_Base"
    fsight.scale = (0.26, 0.30, 0.58)
    bpy.ops.object.transform_apply(scale=True)
    reg(fsight, m_gunmetal)

    # Curved Front Sight Protective Loop Wings
    bpy.ops.mesh.primitive_cylinder_add(radius=0.14, depth=0.12, location=(3.18, 0.0, 0.82), rotation=(0, math.radians(90), 0))
    fwings = bpy.context.active_object
    fwings.name = "Front_Sight_Loop"
    reg(fwings, m_gunmetal)

    # Center Sight Post Pin
    bpy.ops.mesh.primitive_cylinder_add(radius=0.018, depth=0.18, location=(3.18, 0.0, 0.82))
    fpin = bpy.context.active_object
    fpin.name = "Front_Sight_Pin"
    reg(fpin, m_steel)

    # Barrel Collar Ring
    bpy.ops.mesh.primitive_cylinder_add(radius=0.105, depth=0.08, location=(3.42, 0.0, 0.36), rotation=(0, math.radians(90), 0))
    bcollar = bpy.context.active_object
    bcollar.name = "Barrel_Collar"
    reg(bcollar, m_steel)

    # Cylindrical Muzzle Brake Body
    bpy.ops.mesh.primitive_cylinder_add(radius=0.11, depth=0.52, location=(3.92, 0.0, 0.36), rotation=(0, math.radians(90), 0))
    mbrake = bpy.context.active_object
    mbrake.name = "Muzzle_Brake"
    reg(mbrake, m_gunmetal)

    # 3 Vertical Exhaust Ports on Muzzle Brake
    for mx in [3.78, 3.92, 4.06]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(mx, 0.0, 0.36))
        mslot = bpy.context.active_object
        mslot.name = f"Muzzle_Slot_{mx}"
        mslot.scale = (0.055, 0.24, 0.16)
        bpy.ops.object.transform_apply(scale=True)
        reg(mslot, m_steel)

    # -------------------------------------------------------------------------
    # 11. Hooded Tactical Reflex Sight (Angled Brow & Amber Glass Lens)
    # -------------------------------------------------------------------------
    # Picatinny Riser Mount
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

    # Left & Right Hood Walls (Open Sunshade Structure)
    for sign in [-1, 1]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.42, sign * 0.18, 1.18))
        hwall = bpy.context.active_object
        hwall.name = f"Optic_Hood_Wall_{sign}"
        hwall.scale = (0.52, 0.05, 0.40)
        bpy.ops.object.transform_apply(scale=True)
        reg(hwall, m_olive)

    # Angled Forward Brow / Sunshade Roof
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.42, 0.0, 1.37))
    hroof = bpy.context.active_object
    hroof.name = "Optic_Hood_Roof"
    hroof.rotation_euler = (0, math.radians(-6), 0)
    hroof.scale = (0.54, 0.40, 0.05)
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    reg(hroof, m_olive)

    # Top Cylindrical Battery / Elevation Turret with Slotted Cap
    bpy.ops.mesh.primitive_cylinder_add(radius=0.075, depth=0.38, location=(0.14, 0.0, 1.16), rotation=(0, math.radians(90), 0))
    opt_turret = bpy.context.active_object
    opt_turret.name = "Optic_Turret"
    reg(opt_turret, m_gunmetal)

    # Coated Amber Reflex Glass Lens
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.46, 0.0, 1.18))
    opt_lens = bpy.context.active_object
    opt_lens.name = "Optic_Lens"
    opt_lens.rotation_euler = (0, math.radians(-10), 0)
    opt_lens.scale = (0.025, 0.28, 0.28)
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    reg(opt_lens, m_amber_lens)

    # Glowing Holographic Aiming Reticle Dot
    bpy.ops.mesh.primitive_cylinder_add(radius=0.035, depth=0.015, location=(0.47, 0.0, 1.18), rotation=(0, math.radians(90), 0))
    reticle = bpy.context.active_object
    reticle.name = "Optic_Reticle_Dot"
    reg(reticle, m_orange_led)

    # -------------------------------------------------------------------------
    # 12. Bevel Modifiers, Smooth Shading & Unified Mesh Assembly
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

    # -------------------------------------------------------------------------
    # 13. Studio Lighting & Cameras
    # -------------------------------------------------------------------------
    target = bpy.data.objects.new("Camera_Target", None)
    coll.objects.link(target)
    target.location = (0.9, -0.1, 0.15)

    # Hero Camera (55mm lens with Track-To Constraint)
    cam_data = bpy.data.cameras.new("Hero_Camera")
    cam_data.lens = 45
    cam_obj = bpy.data.objects.new("Hero_Camera", cam_data)
    coll.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj
    cam_obj.location = (1.4, -9.2, 1.25)
    
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

    # Studio Lighting Rig
    # 1. Intense Cool Rim Light (Top-rear silhouette)
    rim_data = bpy.data.lights.new("Rim_Light_Top", type='AREA')
    rim_data.energy = 1200.0
    rim_data.size = 4.0
    rim_data.color = (0.85, 0.94, 1.0)
    rim_top = bpy.data.objects.new("Rim_Light_Top", rim_data)
    rim_top.location = (0.5, 3.8, 3.2)
    rim_top.rotation_euler = (math.radians(-45), 0, math.radians(160))
    coll.objects.link(rim_top)

    # 2. Muzzle & Barrel Accent Light
    rim_muzzle_data = bpy.data.lights.new("Rim_Light_Muzzle", type='AREA')
    rim_muzzle_data.energy = 900.0
    rim_muzzle_data.size = 2.0
    rim_muzzle_data.color = (0.90, 0.95, 1.0)
    rim_muzzle = bpy.data.objects.new("Rim_Light_Muzzle", rim_muzzle_data)
    rim_muzzle.location = (4.8, -2.5, 2.5)
    coll.objects.link(rim_muzzle)

    # 3. Front Key Light
    key_data = bpy.data.lights.new("Key_Light", type='AREA')
    key_data.energy = 750.0
    key_data.size = 3.5
    key_data.color = (1.0, 0.97, 0.93)
    key_l = bpy.data.objects.new("Key_Light", key_data)
    key_l.location = (2.2, -5.2, 3.2)
    coll.objects.link(key_l)

    # 4. Fill Light
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
    print(f"Saved perfect high-poly model to: {blend_path}")

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

build_perfect_lmg()
