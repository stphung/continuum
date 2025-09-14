#!/usr/bin/env python3
"""
SConstruct - Continuum Build System
Advanced build automation for the Continuum professional shmup engine
"""

import os
import sys
import platform
from pathlib import Path

# SCons imports
from SCons.Script import *

# Build system version
BUILD_SYSTEM_VERSION = "1.0.0"

def print_banner():
    """Print the build system banner"""
    print("=" * 80)
    print("🚀 Continuum Professional Build System v{}".format(BUILD_SYSTEM_VERSION))
    print("   Advanced Godot 4.4 Build Automation")
    print("=" * 80)

def setup_build_environment():
    """Setup the main build environment with cross-platform support"""
    env = Environment()

    # Get platform information
    host_platform = platform.system().lower()
    target_platform = ARGUMENTS.get('platform', host_platform)

    # Build configuration
    debug = ARGUMENTS.get('debug', '0') == '1'
    profiling = ARGUMENTS.get('profiling', '0') == '1'
    hot_reload = ARGUMENTS.get('hot_reload', '0') == '1'

    # Store configuration in environment
    env['HOST_PLATFORM'] = host_platform
    env['TARGET_PLATFORM'] = target_platform
    env['DEBUG'] = debug
    env['PROFILING'] = profiling
    env['HOT_RELOAD'] = hot_reload

    # Build directories
    env['BUILD_DIR'] = Dir('build')
    env['DIST_DIR'] = Dir('dist')
    env['TOOLS_DIR'] = Dir('tools')
    env['TEMP_DIR'] = Dir('.temp')

    # Godot configuration
    env['GODOT_EXECUTABLE'] = find_godot_executable()
    env['PROJECT_DIR'] = Dir('.')
    env['ASSETS_DIR'] = Dir('assets')
    env['SCRIPTS_DIR'] = Dir('scripts')
    env['SCENES_DIR'] = Dir('scenes')

    return env

def find_godot_executable():
    """Find the Godot executable on the system"""
    # Common Godot executable paths by platform
    common_paths = {
        'darwin': [
            '/Applications/Godot.app/Contents/MacOS/Godot',
            '/usr/local/bin/godot',
            '~/Applications/Godot.app/Contents/MacOS/Godot'
        ],
        'linux': [
            '/usr/bin/godot',
            '/usr/local/bin/godot',
            '~/bin/godot'
        ],
        'windows': [
            'C:/Program Files/Godot/Godot.exe',
            'C:/Program Files (x86)/Godot/Godot.exe'
        ]
    }

    host_platform = platform.system().lower()
    paths = common_paths.get(host_platform, [])

    # Try common paths first
    for path in paths:
        expanded_path = os.path.expanduser(path)
        if os.path.exists(expanded_path):
            return expanded_path

    # Try environment variable
    godot_path = os.environ.get('GODOT_EXECUTABLE')
    if godot_path and os.path.exists(godot_path):
        return godot_path

    # Try finding in PATH
    import shutil
    godot_in_path = shutil.which('godot')
    if godot_in_path:
        return godot_in_path

    # Default fallback (will cause error if not found)
    return '/Applications/Godot.app/Contents/MacOS/Godot'

def setup_build_targets(env):
    """Setup the main build targets"""

    # Create build directories
    env.Execute(Mkdir(env['BUILD_DIR']))
    env.Execute(Mkdir(env['DIST_DIR']))
    env.Execute(Mkdir(env['TEMP_DIR']))

    # Import assets processing
    SConscript('site_scons/assets.py', exports='env')

    # Import validation tools
    SConscript('site_scons/validation.py', exports='env')

    # Import Godot integration
    SConscript('site_scons/godot_integration.py', exports='env')

def setup_command_line_targets(env):
    """Setup command-line build targets"""

    # Development build targets
    env.Alias('build-dev', env.Command('build-dev-target', [], build_dev_action))
    env.Alias('build-debug', env.Command('build-debug-target', [], build_debug_action))

    # Release build targets
    env.Alias('build-release', env.Command('build-release-target', [], build_release_action))
    env.Alias('package-release', env.Command('package-release-target', [], package_release_action))

    # Asset processing targets
    env.Alias('process-assets', env.Command('process-assets-target', [], process_assets_action))
    env.Alias('validate-assets', env.Command('validate-assets-target', [], validate_assets_action))

    # Quality assurance targets
    env.Alias('test', env.Command('test-target', [], run_tests_action))
    env.Alias('lint', env.Command('lint-target', [], run_lint_action))
    env.Alias('validate', env.Command('validate-target', [], run_validation_action))

    # Utility targets
    env.Alias('clean-build', env.Command('clean-build-target', [], clean_build_action))
    env.Alias('help', env.Command('help-target', [], show_help_action))

# Build action implementations
def build_dev_action(target, source, env):
    """Build development version"""
    output_path = str(env['BUILD_DIR'].abspath) + '/continuum-dev'
    return env.GodotExport('Desktop', output_path, debug=True)

def build_debug_action(target, source, env):
    """Build debug version with maximum debugging info"""
    output_path = str(env['BUILD_DIR'].abspath) + '/continuum-debug'
    return env.GodotExport('Desktop', output_path, debug=True)

def build_release_action(target, source, env):
    """Build optimized release version"""
    output_path = str(env['BUILD_DIR'].abspath) + '/continuum-release'
    return env.GodotExport('Desktop', output_path, debug=False)

def package_release_action(target, source, env):
    """Package release build for distribution"""
    print("📦 Packaging release for distribution...")
    # First build release
    build_release_action(target, source, env)
    # TODO: Add packaging logic (zip, installer creation, etc.)
    return 0

def process_assets_action(target, source, env):
    """Process and optimize game assets"""
    return env.ProcessAllAssets()

def validate_assets_action(target, source, env):
    """Validate asset integrity"""
    return env.ValidateAllAssets()

def run_tests_action(target, source, env):
    """Execute the full test suite"""
    return env.GodotRunTests()

def run_lint_action(target, source, env):
    """Run code quality checks"""
    print("🔍 Running code quality checks...")
    # TODO: Implement GDScript linting
    return 0

def run_validation_action(target, source, env):
    """Run comprehensive validation checks"""
    return env.RunComprehensiveValidation()

def clean_build_action(target, source, env):
    """Clean build artifacts"""
    print("🧹 Cleaning build artifacts...")
    import shutil
    for dir_path in [env['BUILD_DIR'], env['DIST_DIR'], env['TEMP_DIR']]:
        if os.path.exists(str(dir_path)):
            shutil.rmtree(str(dir_path))
    return 0

def show_help_action(target, source, env):
    """Show build system help"""
    help_text = """
🚀 Continuum Build System Help

Development Targets:
  scons build-dev                     # Debug build with profiling support
  scons build-debug                   # Maximum debug information
  scons build-dev profiling=1         # Enable performance profiling
  scons build-dev hot_reload=1        # Enable hot-reload features

Release Targets:
  scons build-release                 # Optimized release build
  scons build-release platform=all   # Build for all platforms
  scons package-release              # Create distribution packages

Asset Processing:
  scons process-assets               # Process and optimize all assets
  scons validate-assets              # Validate asset integrity

Quality Assurance:
  scons test                         # Execute complete test suite
  scons lint                         # Code quality checks
  scons validate                     # Comprehensive validation

Utilities:
  scons clean-build                  # Clean build artifacts
  scons help                         # Show this help message

Options:
  debug=1                            # Enable debug mode
  profiling=1                        # Enable profiling
  platform=<target>                  # Target platform
  hot_reload=1                       # Enable hot-reload
    """
    print(help_text)
    return 0

# Main build setup
if __name__ == "SCons.Script":
    print_banner()

    # Setup build environment
    env = setup_build_environment()

    print("🔧 Build Environment:")
    print(f"   Host Platform: {env['HOST_PLATFORM']}")
    print(f"   Target Platform: {env['TARGET_PLATFORM']}")
    print(f"   Godot: {env['GODOT_EXECUTABLE']}")
    print(f"   Debug: {env['DEBUG']}")
    print("")

    # Setup build targets
    setup_build_targets(env)
    setup_command_line_targets(env)

    # Default target
    Default('help')