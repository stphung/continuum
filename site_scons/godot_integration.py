#!/usr/bin/env python3
"""
Godot Integration Module - SCons Build System
Advanced integration with Godot 4.4 export and project management
"""

import os
import subprocess
import json
from pathlib import Path
from SCons.Script import *

# Import the environment
Import('env')

def setup_godot_integration(env):
    """Setup Godot integration tools and functions"""

    # Verify Godot installation
    verify_godot_installation(env)

    # Setup export presets if they don't exist
    setup_export_presets(env)

    # Add Godot-specific build functions to environment
    env.AddMethod(godot_export, "GodotExport")
    env.AddMethod(godot_import_assets, "GodotImportAssets")
    env.AddMethod(godot_validate_project, "GodotValidateProject")
    env.AddMethod(godot_run_tests, "GodotRunTests")
    env.AddMethod(ensure_test_dependencies, "EnsureTestDependencies")

def verify_godot_installation(env):
    """Verify that Godot is properly installed and accessible"""
    godot_path = env['GODOT_EXECUTABLE']

    if not os.path.exists(godot_path):
        print(f"❌ Error: Godot executable not found at: {godot_path}")
        print("   Please install Godot 4.4+ or set GODOT_EXECUTABLE environment variable")
        Exit(1)

    try:
        # Test Godot version
        result = subprocess.run([godot_path, '--version'],
                              capture_output=True, text=True, timeout=10)

        if result.returncode == 0:
            version = result.stdout.strip()
            print(f"✅ Found Godot: {version}")

            # Check if it's Godot 4.x
            if not version.startswith('4.'):
                print(f"⚠️  Warning: Expected Godot 4.x, found: {version}")
        else:
            print(f"❌ Error: Failed to get Godot version")
            print(f"   stderr: {result.stderr}")
            Exit(1)

    except subprocess.TimeoutExpired:
        print("❌ Error: Godot version check timed out")
        Exit(1)
    except Exception as e:
        print(f"❌ Error: Failed to verify Godot installation: {e}")
        Exit(1)

def setup_export_presets(env):
    """Setup basic export presets if they don't exist"""
    export_presets_path = env['PROJECT_DIR'].File('export_presets.cfg')

    if not os.path.exists(str(export_presets_path)):
        print("📝 Creating basic export presets...")

        # Basic export presets content for common platforms
        presets_content = """[preset.0]

name="Desktop"
platform="Linux/X11"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="build/continuum-linux"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false

[preset.0.options]

custom_template/debug=""
custom_template/release=""
debug/export_console_wrapper=1
binary_format/embed_pck=false
texture_format/bptc=true
texture_format/s3tc=true
texture_format/etc=false
texture_format/etc2=false
binary_format/architecture="x86_64"
ssh_remote_deploy/enabled=false

[preset.1]

name="Windows Desktop"
platform="Windows Desktop"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="build/continuum-windows.exe"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false

[preset.1.options]

custom_template/debug=""
custom_template/release=""
debug/export_console_wrapper=1
binary_format/embed_pck=false
texture_format/bptc=true
texture_format/s3tc=true
texture_format/etc=false
texture_format/etc2=false
binary_format/architecture="x86_64"
codesign/enable=false
application/modify_resources=true
application/icon=""
application/console_wrapper_icon=""
application/icon_interpolation=4
application/file_version=""
application/product_version=""
application/company_name=""
application/product_name=""
application/file_description=""
application/copyright=""
application/trademarks=""
application/export_angle=0
ssh_remote_deploy/enabled=false

[preset.2]

name="macOS"
platform="macOS"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="build/continuum-macos.zip"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false

[preset.2.options]

binary_format/architecture="universal"
custom_template/debug=""
custom_template/release=""
debug/export_console_wrapper=1
application/icon=""
application/icon_interpolation=4
application/bundle_identifier=""
application/signature=""
application/app_category="Games"
application/short_version=""
application/version=""
application/copyright=""
application/copyright_localized={}
display/high_res=true
codesign/codesign=1
codesign/identity=""
codesign/certificate_file=""
codesign/certificate_password=""
codesign/entitlements/custom_file=""
codesign/entitlements/allow_jit_code_generation=false
codesign/entitlements/allow_unsigned_executable_memory=false
codesign/entitlements/allow_dyld_environment_variables=false
codesign/entitlements/disable_library_validation=false
codesign/entitlements/audio_input=false
codesign/entitlements/camera=false
codesign/entitlements/location=false
codesign/entitlements/address_book=false
codesign/entitlements/calendars=false
codesign/entitlements/photos_library=false
codesign/entitlements/apple_events=false
codesign/entitlements/debugging=false
codesign/entitlements/app_sandbox/enabled=false
codesign/entitlements/app_sandbox/network_server=false
codesign/entitlements/app_sandbox/network_client=false
codesign/entitlements/app_sandbox/device_usb=false
codesign/entitlements/app_sandbox/device_bluetooth=false
codesign/entitlements/app_sandbox/files_downloads=0
codesign/entitlements/app_sandbox/files_pictures=0
codesign/entitlements/app_sandbox/files_music=0
codesign/entitlements/app_sandbox/files_movies=0
codesign/entitlements/app_sandbox/helper_executables=[]
notarization/notarization=0
privacy/microphone_usage_description=""
privacy/microphone_usage_description_localized={}
privacy/camera_usage_description=""
privacy/camera_usage_description_localized={}
privacy/location_usage_description=""
privacy/location_usage_description_localized={}
privacy/address_book_usage_description=""
privacy/address_book_usage_description_localized={}
privacy/calendar_usage_description=""
privacy/calendar_usage_description_localized={}
privacy/photos_library_usage_description=""
privacy/photos_library_usage_description_localized={}
privacy/desktop_folder_usage_description=""
privacy/desktop_folder_usage_description_localized={}
privacy/documents_folder_usage_description=""
privacy/documents_folder_usage_description_localized={}
privacy/downloads_folder_usage_description=""
privacy/downloads_folder_usage_description_localized={}
privacy/network_volumes_usage_description=""
privacy/network_volumes_usage_description_localized={}
privacy/removable_volumes_usage_description=""
privacy/removable_volumes_usage_description_localized={}
ssh_remote_deploy/enabled=false
"""

        with open(str(export_presets_path), 'w') as f:
            f.write(presets_content)

        print(f"✅ Created export presets: {export_presets_path}")

def godot_export(env, preset_name, output_path, debug=False):
    """Export Godot project using specified preset"""
    godot_path = env['GODOT_EXECUTABLE']
    project_path = str(env['PROJECT_DIR'])

    # Ensure output directory exists
    output_dir = os.path.dirname(output_path)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Build export command
    export_type = '--export-debug' if debug else '--export-release'
    cmd = [
        godot_path,
        '--path', project_path,
        '--headless',
        export_type, preset_name,
        output_path
    ]

    print(f"🚀 Exporting {preset_name} {'(debug)' if debug else '(release)'} to: {output_path}")
    print(f"   Command: {' '.join(cmd)}")

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)

        if result.returncode == 0:
            print(f"✅ Export successful: {output_path}")
            return 0
        else:
            print(f"❌ Export failed for {preset_name}")
            print(f"   stdout: {result.stdout}")
            print(f"   stderr: {result.stderr}")
            return 1

    except subprocess.TimeoutExpired:
        print(f"❌ Export timed out for {preset_name}")
        return 1
    except Exception as e:
        print(f"❌ Export error for {preset_name}: {e}")
        return 1

def godot_import_assets(env):
    """Import and process project assets"""
    godot_path = env['GODOT_EXECUTABLE']
    project_path = str(env['PROJECT_DIR'])

    cmd = [
        godot_path,
        '--path', project_path,
        '--headless',
        '--quit-after', '1'
    ]

    print("📦 Importing project assets...")

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)

        if result.returncode == 0:
            print("✅ Asset import successful")
            return 0
        else:
            print("❌ Asset import failed")
            print(f"   stderr: {result.stderr}")
            return 1

    except subprocess.TimeoutExpired:
        print("❌ Asset import timed out")
        return 1
    except Exception as e:
        print(f"❌ Asset import error: {e}")
        return 1

def godot_validate_project(env):
    """Validate Godot project integrity"""
    project_path = env['PROJECT_DIR']

    # Check for required files
    required_files = [
        'project.godot',
        'scenes/main/Main.tscn',
        'scenes/main/Game.tscn'
    ]

    print("🔍 Validating project structure...")

    missing_files = []
    for file_path in required_files:
        full_path = project_path.File(file_path)
        if not os.path.exists(str(full_path)):
            missing_files.append(file_path)

    if missing_files:
        print("❌ Project validation failed - missing files:")
        for missing in missing_files:
            print(f"   - {missing}")
        return 1

    print("✅ Project structure validation passed")
    return 0

def ensure_test_dependencies(env):
    """Ensure test dependencies (gdUnit4) are properly installed"""
    project_path = str(env['PROJECT_DIR'])

    # Check if gdUnit4 is already installed
    gdunit_path = os.path.join(project_path, 'addons', 'gdUnit4', 'bin', 'GdUnitCmdTool.gd')
    if os.path.exists(gdunit_path):
        print("✅ gdUnit4 test framework already installed")
        return 0

    print("📦 Installing test dependencies...")

    # Try to install using gd-plug
    plug_script = os.path.join(project_path, 'plug.gd')
    if not os.path.exists(plug_script):
        print("❌ Error: plug.gd script not found - cannot install dependencies")
        print("   Please ensure gd-plug is properly set up")
        return 1

    try:
        # Use Godot directly to run plug.gd install (more reliable than shebang)
        godot_path = env['GODOT_EXECUTABLE']
        result = subprocess.run([
            godot_path,
            '--path', project_path,
            '--headless',
            '-s', plug_script,
            'install'
        ], capture_output=True, text=True, timeout=300)

        if result.returncode == 0:
            print("✅ Test dependencies installed successfully")

            # Verify gdUnit4 is now available
            if os.path.exists(gdunit_path):
                print("✅ gdUnit4 test framework verified")
                return 0
            else:
                print("⚠️  Warning: Dependencies installed but gdUnit4 not found")
                print(f"   Expected path: {gdunit_path}")
                # List what was actually installed
                addons_dir = os.path.join(project_path, 'addons')
                if os.path.exists(addons_dir):
                    print(f"   Available addons: {os.listdir(addons_dir)}")
                return 1
        else:
            print("❌ Failed to install test dependencies")
            print(f"   stdout: {result.stdout}")
            print(f"   stderr: {result.stderr}")
            return 1

    except subprocess.TimeoutExpired:
        print("❌ Dependency installation timed out")
        return 1
    except Exception as e:
        print(f"❌ Dependency installation error: {e}")
        return 1

def godot_run_tests(env, test_filter="", generate_report=False):
    """Run Godot test suite using gdUnit4 with enhanced options"""
    godot_path = env['GODOT_EXECUTABLE']
    project_path = str(env['PROJECT_DIR'])

    print("🧪 Running Godot test suite...")

    # Ensure test dependencies are installed
    if ensure_test_dependencies(env) != 0:
        print("❌ Cannot run tests: missing dependencies")
        return 1

    # First, import project assets (needed for running tests)
    print("📦 Importing project assets...")
    try:
        result = subprocess.run([
            godot_path,
            '--path', project_path,
            '--headless',
            '--quit-after', '1'
        ], capture_output=True, text=True, timeout=120)

        if result.returncode != 0:
            print(f"⚠️ Asset import warning: {result.stderr}")
    except Exception as e:
        print(f"⚠️ Asset import error: {e}")

    # Build test command with optional filtering
    test_cmd = [
        godot_path,
        '--path', project_path,
        '--headless',
        '-s', 'addons/gdUnit4/bin/GdUnitCmdTool.gd',
        '--add', test_filter if test_filter else 'test',
        '--continue',
        '--ignoreHeadlessMode'
    ]

    # Add report generation if requested
    if generate_report:
        reports_dir = os.path.join(project_path, 'reports')
        if not os.path.exists(reports_dir):
            os.makedirs(reports_dir)
        test_cmd.extend(['--report', '--reportFormat', 'html'])

    # Display test configuration
    if test_filter:
        print(f"🎯 Running filtered tests: {test_filter}")
    else:
        print("🎯 Running all tests")

    if generate_report:
        print("📊 Generating test reports")

    # Run the tests using gdUnit4
    try:
        result = subprocess.run(test_cmd, capture_output=True, text=True, timeout=600)

        # Parse and display results
        success = result.returncode == 0

        if success:
            print("✅ All tests passed")

            # Count test results from output
            stdout = result.stdout
            if "Passed:" in stdout:
                lines = stdout.split('\n')
                for line in lines:
                    if "Passed:" in line or "Failed:" in line or "Total:" in line:
                        print(f"   {line.strip()}")
        else:
            print("❌ Some tests failed")

            # Display detailed failure information
            stdout = result.stdout
            stderr = result.stderr

            if stdout:
                print("📋 Test output:")
                # Show last 20 lines of output for context
                lines = stdout.split('\n')
                for line in lines[-20:]:
                    if line.strip():
                        print(f"   {line}")

            if stderr:
                print("⚠️  Error output:")
                print(f"   {stderr}")

        if generate_report:
            reports_dir = os.path.join(project_path, 'reports')
            if os.path.exists(reports_dir):
                print(f"📊 Test reports generated in: {reports_dir}")

        return 0 if success else 1

    except subprocess.TimeoutExpired:
        print("❌ Test execution timed out")
        return 1
    except Exception as e:
        print(f"❌ Test execution error: {e}")
        return 1

# Initialize Godot integration
setup_godot_integration(env)

print("✅ Godot integration module loaded")