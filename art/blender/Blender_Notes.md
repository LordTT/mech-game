# Blender Notes

## Blender Tips

### Automatic cleanup

Edit Mode:

`A -> M -> By Distance -> Shift + N -> Shift + Ctrl + Alt + M`

Object Mode:

`Ctrl + A -> Scale`

### Export Checklist

Before export:

Object Mode:

Ctrl + A -> Scale

Check origin location

Check dimensions

Apply cleanup:

A -> M -> By Distance
Shift + N

Rename object correctly

Export selected objects only

## Parts

### First Art Pass

port_arm
port_shoulder
port_legs

plug_arm
plug_shoulder
plug_legs

walker_basic

autocannon_light

shield_small

chassis_basic

### Initial Parts

CHASSIS (not swappable during run)
├── chassis_basic
├── chassis_heavy
├── chassis_light
CORES / REACTORS
├── core_small
├── core_medium
├── core_high_output
LEGS (one module)
├── walker_basic
├── walker_heavy
├── hover_basic
├── treads_basic
├── jump_legs
ARM MODULES
├── autocannon_light
├── shotgun_arm
├── laser_arm
├── plasma_cutter
├── repair_arm
├── mining_drill
SHOULDER MODULES
├── missile_rack
├── radar_module
├── shield_projector
├── smoke_launcher
├── sensor_pack
SHIELDS
├── shield_small
├── shield_medium
├── shield_heavy
PORTS
├── port_arm
├── port_shoulder
├── port_legs
├── port_shield
├── port_core
PLUGS
├── plug_arm
├── plug_shoulder
├── plug_legs
├── plug_shield
├── plug_core

### Library layout

ArmModules: X≈0
Connectors: X≈20
Plugs: X≈30
Legs: X≈40
ShoulderModules: X≈60
Shields: X≈80
Cores: X≈100
Armor/Misc: X≈120


## Blender Scale Rules (Mech Game)

### Units

Use:

* 1 Blender Unit = 1 meter
* Keep Godot and Blender scales identical

### Player Mech Reference Scale

Target mech size:

* Small mech: 2.5–3m
* Medium mech: 3–4m
* Heavy mech: 5–6m

Current target:

* Player mech ≈ 3.5m tall

Create reference object:

REF_player_mech_height

Dimensions:

X = 1m
Y = 1m
Z = 3.5m

Store in Misc collection.

### Recommended Module Sizes

Connectors:

port_arm:
0.3–0.5m

port_shoulder:
0.5–0.8m

port_legs:
0.5–1m

port_shield:
0.3–0.6m

port_core:
0.6–1m

Modules:

Arm modules:
0.8–1.5m

Shoulder modules:
0.5–1.2m

Shield modules:
0.5–1m

Core modules:
0.6–1m

Leg systems:

walker_basic:
1.5–2m tall

hover_basic:
0.5–1m thick

Chassis width:
2–2.5m

Leg spacing:
1.5–2m
