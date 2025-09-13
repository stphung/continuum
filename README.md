# Continuum

A classic vertical shooter game inspired by Raiden, built with Godot 4.4.

![Game Screenshot](https://img.shields.io/badge/Godot-4.4-blue.svg) ![Language](https://img.shields.io/badge/Language-GDScript-orange.svg)

## Features

🚀 **Classic Vertical Shooter Gameplay**
- Raiden-inspired arcade action
- Progressive difficulty with wave-based enemies
- Three lives system with dramatic death explosions

⚔️ **Dual Weapon System**
- **Vulcan**: Rapid-fire spread shot that widens with upgrades
- **Laser**: Powerful piercing beam that damages multiple enemies
- 5 upgrade levels for each weapon type

💥 **Enhanced Visual Effects**
- Multi-layered explosion particles
- Expanding shockwave rings
- Screen flash effects
- Ship fragment physics

🎵 **Programmatic Audio**
- Real-time synthesized sound effects
- No external audio files required
- Distinct sounds for each weapon and action

🎮 **Power-up System**
- **Red "P"**: Weapon power upgrade
- **Blue "L"**: Laser weapon switch
- **Yellow "B"**: Screen-clearing bomb
- **Green "1"**: Extra life

## Controls

- **Movement**: WASD or Arrow Keys
- **Shoot**: Space or Z (hold for continuous fire)
- **Bomb**: X (clears screen of enemies and bullets)

## Getting Started

### Prerequisites
- Godot 4.4 or later

### Running the Game
1. Clone this repository
2. Open Godot Engine
3. Click "Import" and select the project directory
4. Choose `project.godot` to import
5. Press F5 or click "Run" to play

### Command Line (macOS)
```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . 
```

## Architecture

The game uses a signal-based architecture with these core systems:

- **Game.gd**: Main controller managing score, lives, waves, and spawning
- **Player.gd**: Ship movement, weapons, collision, and effects
- **Enemy.gd**: AI patterns (straight, zigzag, dive) with scaling difficulty
- **SynthSoundManager.gd**: Real-time audio synthesis using waveforms
- **Bullet/LaserBullet**: Distinct projectile systems with different behaviors

## Development

Built using Godot's scene-component system with GDScript. The codebase emphasizes:
- Clean separation of concerns
- Signal-based communication
- Programmatic particle effects
- Mathematical audio generation

See `CLAUDE.md` for detailed development guidance.

## Technical Highlights

- **Collision Detection**: Precise triangular hitboxes matching ship visuals
- **Particle Systems**: Multi-layered CPUParticles2D for dramatic explosions
- **Audio Synthesis**: Mathematical waveform generation (sine, saw, square waves)
- **Performance**: Efficient object pooling and cleanup systems

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE.md) file for details.

This means you are free to:
- Run the program for any purpose
- Study and modify the source code
- Redistribute copies
- Distribute modified versions

Under the condition that any distributed versions (modified or not) are also licensed under GPL v3.0.

## Acknowledgments

Inspired by the classic Raiden series by Seibu Kaihatsu.