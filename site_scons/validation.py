#!/usr/bin/env python3
"""
Validation Module - SCons Build System
Comprehensive project validation and quality assurance
"""

import os
import subprocess
from pathlib import Path
from SCons.Script import *

# Import the environment
Import('env')

def setup_validation_system(env):
    """Setup validation tools and functions"""

    # Add validation functions to environment
    env.AddMethod(run_comprehensive_validation, "RunComprehensiveValidation")
    env.AddMethod(validate_code_quality, "ValidateCodeQuality")
    env.AddMethod(validate_project_structure, "ValidateProjectStructure")
    env.AddMethod(validate_build_system, "ValidateBuildSystem")

def run_comprehensive_validation(env):
    """Run comprehensive project validation"""
    print("🔎 Running comprehensive project validation...")

    validation_results = {}

    # 1. Project structure validation
    print("  📁 Validating project structure...")
    validation_results['structure'] = validate_project_structure(env)

    # 2. Code quality validation
    print("  🔍 Validating code quality...")
    validation_results['code_quality'] = validate_code_quality(env)

    # 3. Asset validation
    print("  🎨 Validating assets...")
    validation_results['assets'] = env.ValidateAllAssets()

    # 4. Test execution
    print("  🧪 Running test suite...")
    validation_results['tests'] = env.GodotRunTests()

    # 5. Build system validation
    print("  ⚙️  Validating build system...")
    validation_results['build_system'] = validate_build_system(env)

    # Print validation summary
    print("\n📊 Validation Summary:")
    print("=" * 50)

    total_passed = 0
    total_checks = len(validation_results)

    for check, passed in validation_results.items():
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"  {check.replace('_', ' ').title():<20} {status}")
        if passed:
            total_passed += 1

    print("=" * 50)
    print(f"  Overall: {total_passed}/{total_checks} checks passed")

    if total_passed == total_checks:
        print("🎉 All validation checks passed!")
        return True
    else:
        print(f"❌ Validation failed: {total_checks - total_passed} issues found")
        return False

def validate_project_structure(env):
    """Validate project directory structure and organization"""
    required_structure = {
        'directories': [
            'scenes',
            'scenes/main',
            'scenes/player',
            'scenes/enemies',
            'scenes/projectiles',
            'scenes/pickups',
            'scenes/menus',
            'scripts',
            'scripts/autoloads',
            'scripts/main',
            'scripts/player',
            'scripts/enemies',
            'scripts/projectiles',
            'scripts/pickups',
            'scripts/menus',
            'assets',
            'test',
            'test/unit',
            'test/integration'
        ],
        'files': [
            'project.godot',
            'run_tests.sh',
            'CLAUDE.md',
            'README.md',
            'LICENSE.md'
        ]
    }

    project_root = str(env['PROJECT_DIR'])
    issues = []

    # Check directories
    for directory in required_structure['directories']:
        dir_path = os.path.join(project_root, directory)
        if not os.path.exists(dir_path):
            issues.append(f"Missing directory: {directory}")

    # Check files
    for file_name in required_structure['files']:
        file_path = os.path.join(project_root, file_name)
        if not os.path.exists(file_path):
            issues.append(f"Missing file: {file_name}")

    if issues:
        print(f"    ❌ Project structure issues found:")
        for issue in issues:
            print(f"      - {issue}")
        return False

    print(f"    ✅ Project structure validation passed")
    return True

def validate_code_quality(env):
    """Validate code quality and style"""
    scripts_dir = str(env['SCRIPTS_DIR'])
    issues = []

    if not os.path.exists(scripts_dir):
        issues.append("Scripts directory not found")
        return False

    # Find all GDScript files
    gdscript_files = []
    for root, dirs, files in os.walk(scripts_dir):
        for file in files:
            if file.endswith('.gd'):
                gdscript_files.append(os.path.join(root, file))

    print(f"    🔍 Checking {len(gdscript_files)} GDScript files...")

    # Quality checks
    for script_file in gdscript_files:
        file_issues = check_script_quality(script_file)
        issues.extend(file_issues)

    if issues:
        print(f"    ❌ Code quality issues found:")
        for issue in issues[:10]:  # Show first 10 issues
            print(f"      - {issue}")
        if len(issues) > 10:
            print(f"      ... and {len(issues) - 10} more issues")
        return False

    print(f"    ✅ Code quality validation passed")
    return True

def check_script_quality(script_path):
    """Check individual script for quality issues"""
    issues = []

    try:
        with open(script_path, 'r', encoding='utf-8') as f:
            content = f.read()

        lines = content.split('\n')
        script_name = os.path.basename(script_path)

        # Quality checks
        for i, line in enumerate(lines):
            line_num = i + 1
            stripped = line.strip()

            # Check for TODO comments (allowed during development)
            if 'TODO' in line.upper() and 'FIXME' in line.upper():
                issues.append(f"{script_name}:{line_num} - FIXME comment found")

            # Check for very long lines (soft limit)
            if len(line) > 120:
                issues.append(f"{script_name}:{line_num} - Line too long ({len(line)} characters)")

            # Check for missing docstrings on functions
            if stripped.startswith('func ') and '"""' not in stripped and '#' not in stripped:
                if 'func _' not in stripped:  # Skip private functions
                    # This is just a suggestion, not a hard requirement
                    pass

    except Exception as e:
        issues.append(f"Failed to check {script_path}: {e}")

    return issues

def validate_build_system(env):
    """Validate build system configuration and dependencies"""
    issues = []

    # Check SCons installation
    try:
        result = subprocess.run(['scons', '--version'], capture_output=True, text=True, timeout=10)
        if result.returncode != 0:
            issues.append("SCons not properly installed")
    except Exception:
        issues.append("SCons not found in PATH")

    # Check Godot installation
    godot_path = env['GODOT_EXECUTABLE']
    if not os.path.exists(godot_path):
        issues.append(f"Godot executable not found: {godot_path}")

    # Check build directories can be created
    try:
        test_dir = os.path.join(str(env['TEMP_DIR']), 'build_test')
        os.makedirs(test_dir, exist_ok=True)
        os.rmdir(test_dir)
    except Exception as e:
        issues.append(f"Cannot create build directories: {e}")

    # Check test runner
    test_script = os.path.join(str(env['PROJECT_DIR']), 'run_tests.sh')
    if not os.path.exists(test_script):
        issues.append("Test runner script missing: run_tests.sh")
    elif not os.access(test_script, os.X_OK):
        issues.append("Test runner script not executable")

    if issues:
        print(f"    ❌ Build system issues found:")
        for issue in issues:
            print(f"      - {issue}")
        return False

    print(f"    ✅ Build system validation passed")
    return True

# Initialize validation system
setup_validation_system(env)

print("✅ Validation module loaded")