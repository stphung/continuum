# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.4 vertical shooter game inspired by Raiden. It's a 2D arcade-style shoot-em-up with programmatically generated sound effects.

## Development Commands

### Running the Game
```bash
# Run the game directly
/Applications/Godot.app/Contents/MacOS/Godot --path .

# Run in editor mode
/Applications/Godot.app/Contents/MacOS/Godot --path . --editor

# Run with specific renderer
/Applications/Godot.app/Contents/MacOS/Godot --path . --rendering-driver metal
```

### Testing and Validation
```bash
# Check for script errors without running
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 1

# Export for distribution (requires export templates)
/Applications/Godot.app/Contents/MacOS/Godot --path . --export-release "macOS" game.app
```

## Architecture

### Core Systems

**Game.gd (Main Game Controller)**
- Manages game state (score, lives, bombs, waves)
- Handles enemy spawning with escalating difficulty
- Controls UI updates and game over sequences
- Manages the signal flow between Player, Enemies, and UI
- Creates and updates the scrolling starfield background

**Player System**
- Player.gd: Handles movement, shooting, power-up collection, invulnerability
- Two weapon types: Vulcan (spread shot) and Laser (piercing beam)
- Weapon levels (1-5) affect fire rate and damage output
- Signals: `player_hit`, `shoot(position, direction, weapon_type)`, `use_bomb`

**Enemy System**
- Enemy.gd: Configurable health, speed, points, and movement patterns
- Three movement patterns: straight, zigzag, dive
- Enemies scale in difficulty based on wave number
- EnemyBullet.gd: Simple projectiles fired by enemies

**Projectile System**
- Bullet.gd: Standard vulcan projectiles (1 damage, no pierce)
- LaserBullet.gd: Laser projectiles (3+ damage, pierces 2+ enemies, scales with level)
- Both inherit from Area2D and use collision groups for hit detection

**Audio System (SynthSoundManager.gd)**
- Programmatically generates all sound effects using waveform synthesis
- No external audio files required
- Creates distinct sounds for: shooting, hits, explosions, power-ups, alarms
- Uses AudioStreamWAV with 16-bit PCM data

### Scene Structure
- Game.tscn: Main scene containing all game nodes
- Player/Enemy/Bullet scenes: Reusable components instantiated at runtime
- Node hierarchy: Game > [Background, Stars, Enemies, Bullets, PowerUps, Effects, Player, UI]

### Signal Flow
1. Player shoots → Game spawns bullets in Bullets node
2. Enemy destroyed → Game updates score, spawns power-ups
3. Player hit → Game decreases lives, triggers respawn or game over
4. Power-up collected → Player upgrades, Game updates UI

## Key Development Patterns

### Adding New Features
- New enemy types: Extend Enemy.gd, add movement pattern in `_process()`
- New weapons: Create bullet scene/script, add to Player's `fire_weapon()`, handle in Game's `_on_player_shoot()`
- New power-ups: Add type to PowerUp.gd, handle in Player's `collect_powerup()`

### Common Modifications
- Difficulty tuning: Adjust `wave_number`, `spawn_delay_reduction`, enemy properties in Game.gd
- Weapon balance: Modify damage, pierce_count, fire rates in weapon scripts
- Sound adjustments: Edit waveform parameters in SynthSoundManager.gd functions

### Godot-Specific Considerations
- Use `preload()` with `ResourceLoader.exists()` checks for optional resources
- Signal connections must be made after instantiation
- Use `is_instance_valid()` before accessing nodes that might be freed
- Group system ("enemies", "player_bullets", etc.) for efficient collision detection