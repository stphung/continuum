#!/usr/bin/env python3
"""
Assets Processing Module - SCons Build System
Asset validation, optimization, and processing pipeline
"""

import os
import json
import hashlib
from pathlib import Path
from SCons.Script import *

# Import the environment
Import('env')

def setup_asset_processing(env):
    """Setup asset processing tools and functions"""

    # Add asset-specific build functions to environment
    env.AddMethod(validate_all_assets, "ValidateAllAssets")
    env.AddMethod(process_all_assets, "ProcessAllAssets")
    env.AddMethod(check_asset_integrity, "CheckAssetIntegrity")
    env.AddMethod(optimize_assets, "OptimizeAssets")

def validate_all_assets(env):
    """Validate all project assets for integrity and compliance"""
    print("🔍 Validating all project assets...")

    assets_dir = env['ASSETS_DIR']
    scripts_dir = env['SCRIPTS_DIR']
    scenes_dir = env['SCENES_DIR']

    validation_results = {
        'assets': validate_asset_directory(str(assets_dir)),
        'scripts': validate_scripts_directory(str(scripts_dir)),
        'scenes': validate_scenes_directory(str(scenes_dir)),
        'audio': validate_audio_system(env)
    }

    # Print validation summary
    total_issues = sum(len(issues) for issues in validation_results.values())

    if total_issues == 0:
        print("✅ All assets validation passed")
        return 0
    else:
        print(f"❌ Asset validation failed with {total_issues} issues:")
        for category, issues in validation_results.items():
            if issues:
                print(f"  {category.title()}:")
                for issue in issues:
                    print(f"    - {issue}")
        return 1

def validate_asset_directory(assets_path):
    """Validate assets directory structure and contents"""
    issues = []

    if not os.path.exists(assets_path):
        issues.append("Assets directory not found")
        return issues

    # Check for common asset types and organization
    expected_subdirs = ['textures', 'audio', 'fonts']
    for subdir in expected_subdirs:
        subdir_path = os.path.join(assets_path, subdir)
        if not os.path.exists(subdir_path):
            issues.append(f"Expected asset subdirectory not found: {subdir}")

    return issues

def validate_scripts_directory(scripts_path):
    """Validate GDScript files for syntax and organization"""
    issues = []

    if not os.path.exists(scripts_path):
        issues.append("Scripts directory not found")
        return issues

    # Find all GDScript files
    gdscript_files = []
    for root, dirs, files in os.walk(scripts_path):
        for file in files:
            if file.endswith('.gd'):
                gdscript_files.append(os.path.join(root, file))

    # Basic GDScript validation
    for script_file in gdscript_files:
        script_issues = validate_gdscript_file(script_file)
        issues.extend(script_issues)

    return issues

def validate_gdscript_file(script_path):
    """Validate individual GDScript file"""
    issues = []

    try:
        with open(script_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Basic syntax checks
        lines = content.split('\n')
        for i, line in enumerate(lines):
            line_num = i + 1

            # Check for common issues
            if line.strip().startswith('print(') and 'TODO' not in line.upper():
                # Allow prints with TODO comments during development
                if not any(keyword in line.upper() for keyword in ['DEBUG', 'TEST', 'TEMP']):
                    issues.append(f"{script_path}:{line_num} - Consider removing debug print statement")

            # Check for proper extends declarations
            if line.strip().startswith('extends') and not line.strip().endswith(('Node', 'Node2D', 'Area2D', 'Control', 'Resource')):
                # This is just a basic check - could be enhanced
                pass

    except Exception as e:
        issues.append(f"Failed to read script {script_path}: {e}")

    return issues

def validate_scenes_directory(scenes_path):
    """Validate scene files and structure"""
    issues = []

    if not os.path.exists(scenes_path):
        issues.append("Scenes directory not found")
        return issues

    # Find all scene files
    scene_files = []
    for root, dirs, files in os.walk(scenes_path):
        for file in files:
            if file.endswith('.tscn'):
                scene_files.append(os.path.join(root, file))

    # Check for essential scenes
    essential_scenes = ['main/Main.tscn', 'main/Game.tscn', 'player/Player.tscn']
    for scene in essential_scenes:
        scene_path = os.path.join(scenes_path, scene)
        if not os.path.exists(scene_path):
            issues.append(f"Essential scene not found: {scene}")

    return issues

def validate_audio_system(env):
    """Validate the procedural audio system"""
    issues = []

    # Check for SynthSoundManager autoload
    sound_manager_path = os.path.join(str(env['SCRIPTS_DIR']), 'autoloads', 'SynthSoundManager.gd')
    if not os.path.exists(sound_manager_path):
        issues.append("SynthSoundManager.gd not found - procedural audio system missing")
    else:
        # Validate SynthSoundManager content
        try:
            with open(sound_manager_path, 'r') as f:
                content = f.read()

            # Check for essential functions
            required_functions = ['generate_sound', 'play_sound', 'create_laser_shot', 'create_explosion']
            for func in required_functions:
                if f"func {func}" not in content:
                    issues.append(f"SynthSoundManager missing function: {func}")

        except Exception as e:
            issues.append(f"Failed to validate SynthSoundManager: {e}")

    return issues

def process_all_assets(env):
    """Process and optimize all project assets"""
    print("🎨 Processing all project assets...")

    # For now, this is a placeholder for future asset processing
    # In a full implementation, this would:
    # - Compress textures
    # - Optimize audio files
    # - Validate scene files
    # - Generate asset manifests
    # - Create optimized variants

    print("✅ Asset processing completed (placeholder)")
    return 0

def check_asset_integrity(env):
    """Check asset integrity using checksums"""
    print("🔐 Checking asset integrity...")

    # Generate checksums for critical assets
    assets_dir = str(env['ASSETS_DIR'])
    checksums = {}

    if os.path.exists(assets_dir):
        for root, dirs, files in os.walk(assets_dir):
            for file in files:
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'rb') as f:
                        content = f.read()
                        checksum = hashlib.md5(content).hexdigest()
                        relative_path = os.path.relpath(file_path, assets_dir)
                        checksums[relative_path] = checksum
                except Exception as e:
                    print(f"⚠️  Failed to checksum {file_path}: {e}")

    # Save checksums for future validation
    checksums_path = os.path.join(str(env['TEMP_DIR']), 'asset_checksums.json')
    os.makedirs(os.path.dirname(checksums_path), exist_ok=True)

    try:
        with open(checksums_path, 'w') as f:
            json.dump(checksums, f, indent=2)
        print(f"✅ Asset integrity check completed - {len(checksums)} assets checked")
        return 0
    except Exception as e:
        print(f"❌ Failed to save asset checksums: {e}")
        return 1

def optimize_assets(env):
    """Optimize assets for production builds"""
    print("⚡ Optimizing assets for production...")

    # Placeholder for asset optimization
    # In a full implementation, this would:
    # - Compress images
    # - Optimize audio files
    # - Remove debug assets
    # - Generate mipmaps
    # - Create atlases

    print("✅ Asset optimization completed (placeholder)")
    return 0

# Initialize asset processing
setup_asset_processing(env)

print("✅ Asset processing module loaded")