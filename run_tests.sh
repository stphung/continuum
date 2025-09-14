#!/bin/bash

# Godot Test Runner Script
# This script runs all unit tests using gdUnit4

set -e  # Exit on any error

echo "🧪 Running Godot Unit Tests..."

# Check if Godot is available
if ! command -v /Applications/Godot.app/Contents/MacOS/Godot &> /dev/null; then
    echo "❌ Godot not found at /Applications/Godot.app/Contents/MacOS/Godot"
    echo "Please install Godot 4.4 or update the path in this script"
    exit 1
fi

# Check if gdUnit4 is installed
if [ ! -d "addons/gdUnit4" ]; then
    echo "❌ gdUnit4 not found. Please install gdUnit4:"
    echo "git clone https://github.com/MikeSchulze/gdUnit4.git addons/gdUnit4"
    exit 1
fi

# Import project assets (needed for running tests)
echo "📦 Importing project assets..."
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --editor --quit-after 1

# Run the tests
echo "🚀 Running tests..."
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --add test --continue --ignoreHeadlessMode

TEST_EXIT_CODE=$?

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "✅ All tests passed!"
else
    echo "❌ Tests failed with exit code $TEST_EXIT_CODE"
    exit $TEST_EXIT_CODE
fi

echo "🎉 Test run completed successfully!"