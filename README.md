# Continuum

An open-source vertical scrolling shmup built with Godot 4.4, featuring dual weapon systems, wave-based progression, and procedurally generated audio.

![Game Screenshot](https://img.shields.io/badge/Godot-4.4-blue.svg) ![Language](https://img.shields.io/badge/Language-GDScript-orange.svg) ![License](https://img.shields.io/badge/License-GPL%20v3.0-blue.svg) ![Open Source](https://img.shields.io/badge/Open%20Source-Yes-brightgreen.svg)

[![CI/CD Pipeline](https://github.com/stphung/continuum/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/stphung/continuum/actions/workflows/ci-cd.yml) [![GitHub Pages](https://img.shields.io/badge/Play%20Online-GitHub%20Pages-success)](https://stphung.github.io/continuum/)

## 🎮 **Game Features**

### **Dual Weapon System**
Switch between two distinct weapon types, each with 5 upgrade levels:
- **Vulcan Cannon**: Rapid-fire spread shots that increase from 1 to 5 projectiles
- **Laser System**: Piercing beams that penetrate multiple enemies with scaling damage

### **Wave-Based Gameplay**
Face increasingly challenging waves of enemies with:
- **Dynamic Difficulty**: Enemy health, speed, and point values scale with each wave
- **Formation Patterns**: Enemies spawn in line formations, V-shapes, and random bursts
- **Movement Behaviors**: Straight-line attacks, zigzag patterns, and dive-bomb maneuvers

### **Power-Up System**
Collect floating power-ups that provide:
- **Weapon Upgrades**: Increase your weapon level for more firepower
- **Weapon Switch**: Toggle between Vulcan and Laser systems
- **Bombs**: Screen-clearing explosions for emergency situations
- **Extra Lives**: Extend your survival in the increasingly difficult waves

### **Unique Audio**
Experience a completely procedural soundscape:
- **Zero Audio Files**: All sound effects are generated in real-time using mathematical waveforms
- **Dynamic Audio**: Sounds vary based on context with pitch and frequency modulation
- **Rich Sound Design**: From laser blasts to explosion effects, everything is synthesized on-the-fly

## 🚀 **Quick Start**

### **System Requirements**
- Godot Engine 4.4.1 or newer
- SCons build system (`pip install scons`)
- Windows, macOS, or Linux

### **Installation & Play**
```bash
# Clone the repository
git clone <repository-url>
cd continuum

# Install dependencies (one-time setup)
./plug.gd install

# Launch the game
/Applications/Godot.app/Contents/MacOS/Godot --path .

# Or use the professional build system
scons help  # Show all available commands
```

### **Controls**
```
Movement: Arrow Keys or WASD
Shooting: Spacebar (automatic firing)
Bomb:     Z key (limited use)
Pause:    Escape key
```

## 🎯 **How to Play**

1. **Survive the Waves**: Destroy incoming enemies before they overwhelm you
2. **Collect Power-Ups**: Grab floating items to upgrade your weapons and capabilities
3. **Master Both Weapons**: Learn when to use spread fire vs. piercing lasers
4. **Use Bombs Wisely**: Save screen-clearing bombs for critical moments
5. **Achieve High Scores**: Earn points by destroying enemies, with higher waves worth more

### **Weapon Strategy**
- **Vulcan (Spread Fire)**: Excellent for crowd control and multiple weak enemies
- **Laser (Piercing Beam)**: Perfect for tough enemies and tight formations
- **Weapon Levels**: Higher levels increase damage, fire rate, and special effects

### **Survival Tips**
- Stay mobile - movement is key to avoiding enemy fire
- Prioritize power-ups to stay competitive with wave difficulty
- Learn enemy movement patterns to predict and avoid attacks
- Use the invulnerability period after getting hit to reposition safely

## 🏗️ **Technical Highlights**

### **Open Source Architecture**
- **Modular Design**: Clean separation between player systems, enemy management, and audio
- **Signal-Based Communication**: Decoupled systems communicate through Godot's signal system
- **Resource Efficiency**: Smart instantiation and cleanup for smooth 60 FPS gameplay

### **Innovative Features**
- **Procedural Audio Engine**: Complete sound synthesis without external audio files
- **Particle Effects System**: Dynamic explosions and visual feedback
- **Mathematical Difficulty Scaling**: Algorithmic wave progression for balanced challenge

### **Development Quality**
- **Professional Build System**: SCons integration for advanced build automation
- **Modern Package Management**: Dependencies managed with gd-plug
- **Comprehensive Testing**: Professional testing framework with gdUnit4
- **Automated Quality Assurance**: Pre-commit hooks ensure code quality

## 🔧 **Development & Modding**

### **Development Setup**
```bash
# Install development dependencies
./plug.gd install

# Run tests to verify setup
scons test

# Run comprehensive project validation
scons validate

# Open in Godot Editor for modifications
/Applications/Godot.app/Contents/MacOS/Godot --path . --editor
```

### **SCons Build System**
Professional build automation with comprehensive targets:
```bash
scons test              # Execute complete test suite
scons validate          # Run project validation
scons build-dev         # Build development version
scons build-release     # Build optimized release
scons help             # Show all available commands
```

### **Project Structure**
```
SConstruct       # Main SCons build configuration
site_scons/      # SCons build modules
  ├── assets.py    # Asset processing and validation
  ├── godot_integration.py  # Godot export automation
  └── validation.py # Comprehensive quality assurance
scenes/          # Game scenes (player, enemies, projectiles)
scripts/         # Game logic organized by system
  ├── autoloads/   # Global systems (audio, effects, enemy management)
  ├── player/      # Player ship and weapon systems
  ├── enemies/     # Enemy AI and behaviors
  └── projectiles/ # Bullet and laser implementations
test/            # Comprehensive test suite
assets/          # Ready for sprites, sounds, fonts
```

### **Adding Content**
The game is designed for easy modification:
- **New Enemy Types**: Extend the base Enemy class with custom movement patterns
- **New Weapons**: Create new projectile types and add them to the player system
- **New Power-Ups**: Add power-up types and implement their effects
- **New Audio**: Extend the synthesis engine with new waveform generators

### **Testing Your Changes**
```bash
# Run the complete test suite
scons test

# Run comprehensive project validation
scons validate

# Direct Godot testing (advanced)
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --add test/unit
```

## 🎨 **Game Design Philosophy**

Continuum combines classic arcade shmup action with modern technical innovation:

- **Accessibility**: Easy to learn controls with deep strategic weapon management
- **Progression**: Satisfying power-up system that keeps gameplay fresh
- **Challenge**: Mathematically balanced difficulty that scales fairly
- **Innovation**: Unique procedural audio creates a distinctive soundscape
- **Performance**: Optimized for smooth 60 FPS gameplay across platforms

## 📈 **Technical Stats**

- **Language**: 100% GDScript
- **Audio**: 100% procedurally generated (zero external sound files)
- **Testing**: Comprehensive test coverage with automated quality assurance
- **Performance**: Optimized for 60 FPS with efficient memory management
- **Platforms**: Cross-platform compatibility through Godot Engine

## 🔄 **Automated Builds & Deployment**

Continuum features a comprehensive CI/CD pipeline that automatically builds and deploys across multiple platforms:

### **Available Platforms**
- **🌐 Web Version**: [Play instantly in your browser](https://stphung.github.io/continuum/) (GitHub Pages)
- **🐧 Linux**: Native executable for Linux distributions
- **🪟 Windows**: Executable for Windows 10/11
- **🍎 macOS**: Universal binary for Intel and Apple Silicon Macs
- **📱 Android**: APK for Android devices (ARM64)

### **Continuous Integration**
- **Automated Testing**: Every commit triggers comprehensive test suite
- **Multi-Platform Builds**: Parallel builds for all supported platforms
- **Quality Gates**: Code must pass all tests and validation checks
- **Release Automation**: Git tags automatically create GitHub releases with all builds

### **Download Options**
1. **Latest Release**: Visit [Releases](https://github.com/stphung/continuum/releases) for stable builds
2. **Play Online**: [stphung.github.io/continuum](https://stphung.github.io/continuum/) for instant browser gameplay
3. **Development Builds**: Available as artifacts from successful CI runs

See [CI/CD Documentation](.github/CICD.md) for complete pipeline details.

## 🤝 **Contributing**

Continuum is open source and welcomes contributions:

1. **Fork the Repository**: Create your own copy to work on
2. **Install Development Tools**: Run `./plug.gd install` for the full development environment
3. **Make Your Changes**: Add features, fix bugs, or improve existing systems
4. **Run Tests**: Ensure your changes don't break existing functionality with `scons test`
5. **Validate Quality**: Run `scons validate` to ensure comprehensive quality assurance
6. **Submit a Pull Request**: Share your improvements with the community

### **Contribution Areas**
- **Gameplay**: New enemy types, weapon systems, or power-up mechanics
- **Audio**: Additional waveform generators or sound effect variations
- **Visual Effects**: New particle systems or visual feedback
- **Performance**: Optimization and efficiency improvements
- **Testing**: Additional test coverage for new features

## 📄 **License**

Continuum is licensed under GPL v3.0, making it free and open source software. You're free to:
- Play the game
- Modify the source code
- Distribute your modifications
- Use it for learning game development

See [LICENSE.md](LICENSE.md) for complete terms.

## 🎵 **Soundtrack Notes**

One of Continuum's unique features is its completely procedural audio system. Every sound you hear - from laser blasts to explosions - is generated mathematically in real-time. This creates a unique audio experience that's both retro-inspired and technically innovative.

---

**Experience the evolution of shmup gameplay - download, play, and modify Continuum today!**