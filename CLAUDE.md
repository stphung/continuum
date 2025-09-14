# CLAUDE.md

This file provides comprehensive guidance to Claude Code (claude.ai/code) when working with the Continuum shmup engine codebase.

## Project Overview

Continuum is a professional-grade vertical scrolling shmup built in Godot 4.4, demonstrating modern game development architecture and innovative technical solutions. The project emphasizes clean code practices, comprehensive testing, and zero-dependency audio generation.

## Claude Code Subagent Integration

### Subagent Usage Guidelines

Claude Code should proactively use specialized subagents to achieve higher quality work and faster development cycles:

#### **Mandatory Subagent Usage**
- **Code Review**: Always use `code-reviewer` agent after implementing significant features
- **Testing**: Use `test-automator` agent for comprehensive test creation and validation
- **Architecture Review**: Use `architect-review` agent for system design decisions
- **Debugging**: Use `debugger` agent when encountering errors or test failures
- **Performance**: Use `performance-engineer` agent for optimization and scalability analysis

#### **Parallel Execution Strategy**
When multiple independent tasks are required, execute subagents in parallel:
- Run `code-reviewer` and `test-automator` simultaneously after feature completion
- Execute `performance-engineer` and `security-auditor` together for production readiness
- Combine `frontend-developer` and `backend-architect` for full-stack features
- Use `architect-review` and `code-reviewer` in parallel for comprehensive quality assurance

#### **Specialized Agent Mapping for Game Development**
- **Audio/Music Systems**: Use `ai-engineer` or `data-scientist` agents for procedural audio work and DSP algorithms
- **Game Development**: Use `unity-developer` agent for game-specific patterns and optimizations
- **Performance Critical Code**: Use `performance-engineer` agent for optimization work and memory management
- **Database/Persistence**: Use `database-optimizer` agent for save game and leaderboard systems
- **API Development**: Use `fastapi-pro` or `backend-architect` agents for online features
- **Testing Automation**: Use `test-automator` agent for comprehensive gdUnit4 test generation
- **Visual Effects**: Use `performance-engineer` agent for particle system optimization
- **Enemy AI**: Use `ai-engineer` agent for behavior trees and state machines

#### **Quality Assurance Protocol**
1. Implement feature with appropriate domain-specific agent
2. Run `code-reviewer` agent for code quality assessment
3. Execute `test-automator` agent for comprehensive testing
4. Use `performance-engineer` agent for optimization verification
5. Apply `architect-review` agent for architectural consistency
6. Run `security-auditor` agent for security assessment when applicable

#### **Parallel Task Examples**
```
# Good: Parallel execution
- Launch code-reviewer AND test-automator simultaneously after feature completion
- Run performance-engineer AND security-auditor together for production assessment
- Execute architect-review AND code-reviewer in parallel for comprehensive quality checks

# Avoid: Sequential execution when parallel is possible
- Running code-reviewer, then test-automator, then performance-engineer separately
- Sequential quality checks that could be done simultaneously
```

### **Development Workflow with Subagents**

#### **Feature Implementation Workflow**
1. **Planning Phase**: Use `architect-review` agent to validate design decisions
2. **Implementation Phase**: Use domain-specific agents (e.g., `ai-engineer` for enemy AI)
3. **Quality Phase**: Run `code-reviewer` AND `test-automator` agents in parallel
4. **Optimization Phase**: Use `performance-engineer` agent for performance validation
5. **Integration Phase**: Use `architect-review` agent to ensure system consistency

#### **Bug Fixing Workflow**
1. **Analysis Phase**: Use `debugger` agent to identify root cause
2. **Solution Phase**: Use appropriate domain agent for fix implementation
3. **Validation Phase**: Run `test-automator` AND `code-reviewer` agents in parallel
4. **Regression Phase**: Use `test-automator` agent for comprehensive regression testing

#### **Refactoring Workflow**
1. **Assessment Phase**: Use `architect-review` agent to evaluate current architecture
2. **Planning Phase**: Use `legacy-modernizer` agent for refactoring strategy
3. **Implementation Phase**: Use `code-reviewer` agent during refactoring process
4. **Testing Phase**: Use `test-automator` agent to ensure functionality preservation
5. **Performance Phase**: Use `performance-engineer` agent to validate improvements

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

### Professional Testing Framework (gdUnit4)
```bash
# Execute complete test suite with detailed reports
./run_tests.sh

# Run tests with specific configuration
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

**Automated Quality Assurance with Subagents**
- Use `test-automator` agent for comprehensive test suite generation
- Apply `code-reviewer` agent for test quality assessment
- Execute `performance-engineer` agent for test performance optimization
- Run multiple agents in parallel for faster quality assurance cycles
- Use `debugger` agent for test failure analysis and resolution

## Development Patterns

### Adding New Game Features

**Subagent-Driven Development Workflow**
1. **Planning**: Use `architect-review` agent to validate feature design and integration
2. **Implementation**: Use domain-specific agents (e.g., `ai-engineer` for enemy AI, `performance-engineer` for optimization)
3. **Quality Assurance**: Run `code-reviewer` AND `test-automator` agents in parallel
4. **Performance Validation**: Use `performance-engineer` agent for optimization verification
5. **Architecture Review**: Apply `architect-review` agent for system consistency

**Parallel Development Strategy**
- Multiple agents should work simultaneously when tasks are independent
- Prefer parallel execution over sequential for faster development cycles
- Use specialized agents for their specific domain expertise
- Execute comprehensive quality checks with multiple agents running together

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

### Code Quality Standards

**Architecture Principles**
- Follow SOLID principles with clear separation of concerns
- Use composition over inheritance for complex systems
- Implement dependency injection through autoloaded singletons
- Maintain signal-based communication for loose coupling
- Prefer explicit resource management over implicit garbage collection

**Performance Optimization**
- Implement object pooling for frequently instantiated objects (bullets, particles)
- Use `is_instance_valid()` before accessing potentially freed nodes
- Minimize signal connections and disconnections during gameplay
- Optimize particle systems with appropriate emission limits
- Profile memory usage and implement cleanup strategies

**Testing Requirements**
- Maintain 80%+ test coverage for core game systems
- Write tests before implementing new features (TDD)
- Use meaningful test descriptions and organize by functionality
- Implement both unit and integration tests for complex systems
- Validate edge cases and error conditions

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

## Key Development Guidelines

### Resource Management
- Use `preload()` with `ResourceLoader.exists()` for safe resource loading
- Implement proper signal connection/disconnection lifecycle
- Clean up temporary nodes with `queue_free()` and await completion
- Monitor memory usage during development and testing

### Code Organization
- Follow Godot naming conventions (snake_case for files, PascalCase for classes)
- Organize scripts by functional domain (player/, enemies/, projectiles/)
- Use meaningful variable and function names that describe intent
- Document complex algorithms and mathematical formulas

### Version Control Best Practices
- Use semantic commit messages describing the change impact
- Test all changes with the automated test suite before committing
- **NEVER bypass pre-commit hooks** - all commits must pass quality gates
- Fix failing tests before committing - no exceptions or workarounds
- Keep commits focused and atomic (one feature/fix per commit)
- Use feature branches for significant changes or experiments

### Deployment and Distribution
- Validate all systems work correctly in release builds
- Test exported versions on target platforms before distribution
- Ensure all assets are properly included in export settings
- Verify performance characteristics match development environment

## Project Evolution Notes

This codebase represents the evolution from a simple arcade-style game into a professional-grade game engine demonstration. Key architectural decisions prioritize:

1. **Maintainability**: Clean separation of concerns with testable components
2. **Innovation**: Zero-dependency audio generation and procedural effects
3. **Performance**: Efficient memory management and 60 FPS target
4. **Quality**: Comprehensive testing and automated quality assurance
5. **Modularity**: Extensible systems that support easy feature addition

When extending or modifying the codebase, maintain these principles to preserve the project's professional standards and technical excellence.