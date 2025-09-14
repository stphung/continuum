# CLAUDE.md - Continuum Project

This file provides project-specific guidance to Claude Code (claude.ai/code) when working with the Continuum shmup engine codebase.

**Note**: Universal Claude Code guidance is available in `~/.claude/CLAUDE.md`. This file focuses on Continuum-specific details.

## Project Overview

Continuum is a professional-grade vertical scrolling shmup built in Godot 4.4, demonstrating modern game development architecture and innovative technical solutions. The project emphasizes clean code practices, comprehensive testing, zero-dependency audio generation, and professional SCons build system integration.

### Build System Requirements

This project uses **SCons** as its primary build system for professional automation:

```bash
# Install SCons (one-time setup)
pip install scons

# Core build commands
scons test              # Execute complete test suite
scons validate          # Run comprehensive project validation
scons build-dev         # Build development version
scons build-release     # Build optimized release version
scons help              # Show all available commands
```

**Important**: Always use `scons test` instead of `./run_tests.sh` (which no longer exists). The SCons build system provides professional-grade automation for testing, validation, asset processing, and builds.

## Continuum-Specific Claude Code Integration

### Specialized Agent Mapping for Game Development
- **Audio/Music Systems**: Use `ai-engineer` or `data-scientist` agents for procedural audio work and DSP algorithms
- **Game Development**: Use `unity-developer` agent for game-specific patterns and optimizations
- **Performance Critical Code**: Use `performance-engineer` agent for optimization work and memory management
- **Database/Persistence**: Use `database-optimizer` agent for save game and leaderboard systems
- **API Development**: Use `fastapi-pro` or `backend-architect` agents for online features
- **Testing Automation**: Use `test-automator` agent for comprehensive gdUnit4 test generation
- **Visual Effects**: Use `performance-engineer` agent for particle system optimization
- **Enemy AI**: Use `ai-engineer` agent for behavior trees and state machines

### Continuum-Specific Development Examples

**Boss Battle System Implementation**
```
Task Dependencies:
1. architect-review → Validates boss system integration with EnemyManager
2. [ai-engineer + unity-developer] → Parallel implementation (boss AI + Godot integration)
3. [code-reviewer + test-automator] → Parallel quality assurance with gdUnit4
4. performance-engineer → Optimization for 60 FPS target
5. architect-review → Final integration with existing systems
```

## Development Commands

### Running the Game
```bash
# Launch game directly
/Applications/Godot.app/Contents/MacOS/Godot --path .

# Open in Godot Editor for development
/Applications/Godot.app/Contents/MacOS/Godot --path . --editor

# Launch with specific rendering backend
/Applications/Godot.app/Contents/MacOS/Godot --path . --rendering-driver metal
```

### Package Management (gd-plug)
```bash
# Install all project dependencies
./plug.gd install

# Update dependencies to latest compatible versions
./plug.gd update

# Clean installation (remove and reinstall all dependencies)
./plug.gd clean && ./plug.gd install

# Add new dependency
# Edit plug.gd and add: plug("AuthorName/AddonName", {"tag": "v1.0.0"})
```

### Professional SCons Build System
```bash
# Execute complete test suite with detailed reports
scons test

# Run comprehensive project validation
scons validate

# Build development version with debugging
scons build-dev

# Build optimized release version
scons build-release

# Process and validate assets
scons validate-assets
scons process-assets

# Clean build artifacts
scons clean-build

# Show all available build targets
scons help
```

### Direct Godot Testing (Advanced)
```bash
# Run tests with specific configuration (bypasses SCons)
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --add test --continue --ignoreHeadlessMode

# Run specific test suites
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --add test/unit/test_audio_synthesis.gd

# Generate comprehensive HTML reports
# Reports automatically generated in reports/ directory after test execution
```

### Pre-commit Quality Gates
```bash
# Install pre-commit hooks for automated quality assurance
pip install pre-commit
pre-commit install

# Execute quality checks manually
pre-commit run --all-files

# NEVER bypass pre-commit hooks - all commits must pass quality gates
# If tests fail, fix them before committing - no exceptions

# Update hook versions
pre-commit autoupdate
```

### Project Validation & Debugging
```bash
# Validate project integrity without running
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 1

# Export for distribution (requires export templates)
/Applications/Godot.app/Contents/MacOS/Godot --path . --export-release "macOS" continuum.app

# Profile performance (development builds)
/Applications/Godot.app/Contents/MacOS/Godot --path . --debug-stringnames --verbose
```

### CI/CD Monitoring & Management
```bash
# Monitor GitHub Actions workflow status
gh run list --limit 10

# Check specific workflow run details
gh run view <run-id>

# View logs for failed runs
gh run view <run-id> --log-failed

# Check job-specific logs
gh run view --job=<job-id> --log

# Monitor real-time workflow progress
gh run watch <run-id>

# Download CI/CD artifacts locally
gh run download <run-id>

# Trigger workflow manually (if configured)
gh workflow run ci-cd.yml

# Check repository Pages status
gh api repos/OWNER/REPO/pages

# View latest releases and assets
gh release list
gh release view <tag>
gh release download <tag>
```

**CI/CD Troubleshooting Workflow:**
1. **Always monitor builds** after pushing CI/CD changes
2. **Use `gh run watch`** for real-time progress tracking
3. **Check logs immediately** if builds fail (`gh run view --log-failed`)
4. **Verify artifacts** are generated correctly (`gh run download`)
5. **Test deployment endpoints** (GitHub Pages, releases)
6. **Document fixes** in commit messages for future reference
7. **Monitor release creation** when tags are pushed
8. **Validate asset uploads** in GitHub releases

### Using Claude Code Subagents
```bash
# After implementing new audio synthesis features
# Claude should automatically use ai-engineer and performance-engineer agents in parallel

# After adding new game mechanics
# Claude should use unity-developer and test-automator agents simultaneously

# Before production deployment
# Claude should run security-auditor and performance-engineer in parallel

# For comprehensive quality assurance
# Claude should execute code-reviewer, test-automator, and architect-review agents together

# When debugging complex issues
# Claude should use debugger agent followed by appropriate domain-specific agents
```

## Professional Architecture

### Core Systems (Autoloaded Singletons)

**SynthSoundManager.gd** - Advanced Audio Synthesis Engine
- Programmatically generates all game audio without external files
- Supports multiple waveform types: sine, square, sawtooth, brown noise
- Dynamic frequency sweeps and pitch bending for realistic effects
- Optimized 16-bit PCM generation with configurable sample rates
- Memory-efficient streaming with automatic cleanup

**VisualEffects.gd** - Particle System Manager
- Configurable explosion effects for different contexts (enemy, bomb, player)
- Multi-layered particle systems with core and outer effects
- Performance-optimized with automatic lifecycle management
- Extensible system for adding new visual effect types

**EnemyManager.gd** - Wave Progression System
- Mathematical difficulty scaling with configurable parameters
- Multiple spawn formation patterns (line, V-shape, random burst)
- Enemy health/speed/points progression algorithms
- Wave state management with reset capabilities

### Game Component Architecture

**Player System (scripts/player/Player.gd)**
- Dual weapon system: Vulcan (spread) and Laser (piercing)
- 5-level weapon progression with escalating effects
- Invulnerability system with visual feedback
- Signal-based communication with game systems
- Boundary constraint enforcement with smooth movement

**Enemy System (scripts/enemies/Enemy.gd)**
- Configurable movement patterns: straight, zigzag, dive-bomb
- Health scaling based on wave progression
- Damage feedback and destruction effects
- Point value calculation with wave multipliers

**Projectile System (scripts/projectiles/)**
- Bullet.gd: Standard projectiles with basic damage
- LaserBullet.gd: Piercing projectiles with multi-target damage
- EnemyBullet.gd: Opponent projectiles with player detection
- Efficient collision detection using Godot groups

### Scene Structure and Organization
```
scenes/
├── main/
│   ├── Game.tscn          # Primary game scene with all systems
│   └── Main.tscn          # Entry point scene
├── player/
│   └── Player.tscn        # Player ship with collision and visuals
├── enemies/
│   └── Enemy.tscn         # Configurable enemy template
├── projectiles/
│   ├── Bullet.tscn        # Standard player projectile
│   ├── LaserBullet.tscn   # Piercing laser projectile
│   └── EnemyBullet.tscn   # Enemy projectile
└── pickups/
    └── PowerUp.tscn       # Animated power-up with physics
```

### Professional Testing Architecture

**Test Structure**
```
test/
├── unit/                  # Component-level testing
│   ├── test_audio_synthesis.gd      # Audio generation verification
│   ├── test_weapon_systems.gd       # Weapon mechanics validation
│   ├── test_enemy_spawning.gd       # Enemy management testing
│   ├── test_powerup_collection.gd   # Power-up system testing
│   └── test_player_movement.gd      # Player control validation
├── integration/           # System interaction testing
├── scene/                 # End-to-end gameplay testing
└── helpers/              # Testing utilities and mock objects
```

**Testing Best Practices**
- Use `auto_free()` for automatic memory management in tests
- Implement `before_test()` and `after_test()` for setup/cleanup
- Utilize `await` for asynchronous operations and signal testing
- Create mock objects for isolated component testing
- Verify both positive and negative test cases

## Continuum-Specific Testing Patterns

### Godot/gdUnit4 Testing Examples

**Collision Detection & Physics**
```gdscript
# Test collision outcomes, not physics internals
func test_laser_piercing_behavior():
    var enemies = create_enemy_line(3)
    var laser = create_laser_bullet(pierce_count=2)

    simulate_laser_collision_with_enemies(laser, enemies)
    await get_tree().process_frame

    # Test functional outcome: first 2 enemies destroyed, third survives
    assert_that(enemies[0].is_destroyed()).is_true()
    assert_that(enemies[1].is_destroyed()).is_true()
    assert_that(enemies[2].is_alive()).is_true()
    assert_that(laser.is_exhausted()).is_true()
```

**Signal-Based Communication**
```gdscript
# Test signal outcomes, not emission timing
func test_powerup_collection_effects():
    var player = create_test_player()
    var powerup = create_weapon_powerup()

    var initial_weapon_level = player.weapon_level
    player.collect_powerup(powerup)

    # Test the outcome: weapon was upgraded
    assert_that(player.weapon_level).is_equal(initial_weapon_level + 1)
    assert_that(player.fire_rate).is_faster_than_before()
```

**Asynchronous Operations & Deferred Cleanup**
```gdscript
# Handle deferred queue_free operations properly
bullet._on_area_entered(enemy)
await get_tree().process_frame  # Wait for deferred operations
assert_that(bullet.is_queued_for_deletion()).is_true()
```

### Test Suite Success Metrics

**Continuum Test Suite Transformation Results:**
```
Before Cleanup: 334 test cases | 23 errors | 21 failures (44 total issues)
After Cleanup:  135 test cases | 0 errors  | 0 failures (0 issues)

Improvement: 100% success rate with 59% reduction in test cases
Strategy: Removed fragile implementation-detail tests, retained functional behavior tests
```

## Development Patterns

### SCons Build System Architecture

The project uses a professional SCons build system with modular Python components:

**Core Build Files:**
- `SConstruct` - Main build configuration and target definitions
- `site_scons/godot_integration.py` - Godot export automation and project validation
- `site_scons/assets.py` - Asset processing and validation pipeline
- `site_scons/validation.py` - Comprehensive project quality assurance

**Build System Integration:**
```python
# All build functions return 0 for success, non-zero for failure (SCons standard)
# Functions are integrated as environment methods via AddMethod()
env.GodotRunTests()        # Execute test suite
env.ValidateAllAssets()    # Asset validation
env.RunComprehensiveValidation()  # Full project validation
```

**Testing Integration:**
- Tests run directly through Godot + gdUnit4 (no shell script dependency)
- Pre-commit hooks use `scons test` for quality assurance
- All test execution is controlled by SCons environment

### Continuum Game Features Development

**New Enemy Types** (with Subagent Integration)
1. Use `architect-review` agent to plan enemy integration with existing systems
2. Create enemy scene and implement movement patterns using `ai-engineer` agent
3. Configure spawn parameters and destruction effects
4. Run `code-reviewer` AND `test-automator` agents in parallel for quality assurance
5. Use `performance-engineer` agent to optimize enemy behavior and memory usage

**New Weapon Systems** (with Subagent Integration)
1. Use `architect-review` agent to design weapon system architecture
2. Implement projectile logic and collision detection with `performance-engineer` guidance
3. Add weapon switching and progression logic
4. Execute `test-automator` agent for comprehensive weapon testing
5. Run `code-reviewer` agent to ensure code quality and maintainability

**New Power-Up Types** (with Subagent Integration)
1. Plan power-up effects and integration using `architect-review` agent
2. Implement collection mechanics and visual feedback
3. Use `test-automator` agent to create comprehensive power-up tests
4. Apply `performance-engineer` agent for animation and effect optimization
5. Run `code-reviewer` agent for final quality assessment

### Continuum-Specific Code Standards

**Godot-Specific Architecture**
- Use autoloaded singletons for core systems (SynthSoundManager, VisualEffects, EnemyManager)
- Implement signal-based communication for loose coupling between game components
- Prefer explicit resource management over implicit garbage collection

**Game Performance Optimization**
- Implement object pooling for bullets and particle systems
- Use `is_instance_valid()` before accessing potentially freed nodes
- Maintain 60 FPS target with efficient collision detection using Godot groups
- Profile memory usage during intense gameplay (high enemy counts, particle effects)

### Sound System Development

**Waveform Generation Patterns**
```gdscript
# Sine Wave: Clean, tonal sounds (UI, power-ups)
func create_sine_tone(frequency: float, duration: float) -> AudioStreamWAV

# Square Wave: Harsh, electronic sounds (alarms, warnings)
func create_square_tone(frequency: float, duration: float) -> AudioStreamWAV

# Sawtooth Wave: Aggressive sounds (lasers, engines)
func create_sawtooth_tone(frequency: float, duration: float) -> AudioStreamWAV

# Noise Generation: Explosions and impacts
func create_brown_noise(duration: float, cutoff_freq: float) -> AudioStreamWAV

# Frequency Sweeps: Dynamic pitch effects
func create_frequency_sweep(start_freq: float, end_freq: float, duration: float) -> AudioStreamWAV
```

**Audio Integration Guidelines**
- All audio must be generated programmatically (no external files)
- Use consistent sample rates (44100 Hz) and bit depth (16-bit)
- Implement envelope shaping (ADSR) for realistic sound evolution
- Add randomization to prevent repetitive audio patterns
- Optimize memory usage with efficient PCM data generation

### Visual Effects Development

**Particle System Configuration**
```gdscript
# Standard explosion parameters
{
    "amount": 45,           # Number of particles
    "lifetime": 1.0,        # Duration in seconds
    "velocity_min": 80,     # Minimum initial velocity
    "velocity_max": 350,    # Maximum initial velocity
    "scale_min": 0.8,       # Minimum particle scale
    "scale_max": 2.5,       # Maximum particle scale
    "color": Color.ORANGE   # Base particle color
}
```

**Performance Considerations**
- Limit simultaneous particle systems to maintain 60 FPS
- Implement automatic cleanup for expired effects
- Use object pooling for particle instances when possible
- Configure LOD (Level of Detail) based on distance/importance

## Continuum-Specific Guidelines

### Godot Resource Management
- Use `preload()` with `ResourceLoader.exists()` for safe resource loading of scenes
- Implement proper signal connection/disconnection lifecycle for game objects
- Clean up temporary nodes with `queue_free()` and await completion for bullets/enemies
- Monitor memory usage during intense gameplay sequences

### Continuum Code Organization
- Follow Godot naming conventions (snake_case for files, PascalCase for classes)
- Organize scripts by game domains: `player/`, `enemies/`, `projectiles/`, `autoloads/`
- Document audio synthesis algorithms and mathematical formulas for waveform generation

## Project Evolution Notes

This codebase represents the evolution from a simple arcade-style game into a professional-grade game engine demonstration. Key architectural decisions prioritize:

1. **Maintainability**: Clean separation of concerns with testable components
2. **Innovation**: Zero-dependency audio generation and procedural effects
3. **Performance**: Efficient memory management and 60 FPS target
4. **Quality**: Comprehensive testing and automated quality assurance
5. **Modularity**: Extensible systems that support easy feature addition

When extending or modifying the codebase, maintain these principles to preserve the project's professional standards and technical excellence.