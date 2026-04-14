# Mech Scavenger Roguelite - Design Summary

## Core Concept
A roguelite where you pilot a junk mech and rebuild it in real-time using a drone.

## Core Loop
- Explore
- Fight
- Salvage parts
- Physically swap parts
- Survive and extract

## Core Systems

### Chassis (Core)
You choose one at the start of the run and can't swap it. It's your base module.
Defines slot layout (arms, legs, shoulders, shields).

### Reactor (Power Core)
Defines power budget and behavior.
Extremely risky to swap out. Need to open the chassis and deactivate it completely. More of a level completion / boss / rare reward. When you get a better one you can fit more powerful parts at the same time so it's cooler.

### Legs
- Legs are one module
- Removing them → mech enters braced state
- Different Legs are different ways of moving. (Standard, Dashing, Treads, Jumping, Hover, etc...) 
- Rarer than other parts.
- Defines movement type
- Swapping puts mech in "braced state"
- Limited movement while no legs

### Other Parts

- Arms (Weapons / Utility)
- Shoulders (Weapons / Utility)
- Shields (non-regenerating defense, need to swap out often)

## Drone
- Drone is permanent and linked to early cahssis choice.
- This is is how you swap parts
- Switch POV anytime (mech third person drone first person)
- Tractor Ray
- Grab / detach / attach parts physically (yank out old parts plug in new part)
- Mech becomes vulnerable while active

## Defense
- Per-part damage
- Core = death
- Shields are physical and replaceable
- Repair = survival

## Key Pillar
Everything is physical and happens in real-time.

## MVP Scope
- 1 biome
- 1 chassis
- 1 reactor
- ~10 parts
- Drone system
- Part damage
- 2–3 enemies
