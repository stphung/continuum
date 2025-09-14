extends SceneTree
## Test script for Kiosk Mode System Integration
## Run with: godot --script test_kiosk_integration.gd

func _init():
	print("=== KIOSK MODE INTEGRATION TEST ===")
	_test_kiosk_manager_initialization()
	_test_high_score_manager()
	_test_demo_player_ai()
	_test_attract_screen_manager()
	_test_kiosk_ui()
	_test_configuration_loading()
	print("=== ALL TESTS COMPLETED ===")
	quit()

func _test_kiosk_manager_initialization():
	print("\n1. Testing KioskManager Initialization...")

	# Load the KioskManager script
	var kiosk_manager_script = load("res://scripts/autoloads/KioskManager.gd")
	if not kiosk_manager_script:
		print("❌ FAILED: Could not load KioskManager.gd")
		return

	print("✅ KioskManager script loaded successfully")

	# Test state enum
	var kiosk_states = kiosk_manager_script.KioskState
	var expected_states = ["DISABLED", "ATTRACT", "DEMO_PLAYING", "HIGH_SCORES", "TRANSITIONING"]

	for state in expected_states:
		if not kiosk_states.has(state):
			print("❌ FAILED: Missing KioskState.", state)
			return

	print("✅ All KioskState enum values present")

func _test_high_score_manager():
	print("\n2. Testing HighScoreManager...")

	var high_score_script = load("res://scripts/kiosk/HighScoreManager.gd")
	if not high_score_script:
		print("❌ FAILED: Could not load HighScoreManager.gd")
		return

	print("✅ HighScoreManager script loaded successfully")

	# Create instance and test basic functionality
	var manager = high_score_script.new()
	manager.set_validation_enabled(false)  # Disable validation for testing

	# Test adding scores
	var rank1 = manager.add_score("TEST_PLAYER_1", 5000)
	var rank2 = manager.add_score("TEST_PLAYER_2", 3000)
	var rank3 = manager.add_score("TEST_PLAYER_3", 7000)

	if rank1 != 2 or rank2 != 3 or rank3 != 1:
		print("❌ FAILED: Score ranking not working correctly")
		print("  Expected ranks: 2, 3, 1 | Got ranks: ", rank1, ", ", rank2, ", ", rank3)
		return

	print("✅ Score addition and ranking working correctly")

	# Test score retrieval
	var scores = manager.get_scores(3)
	if scores.size() != 3:
		print("❌ FAILED: Wrong number of scores returned")
		return

	if scores[0].score != 7000 or scores[1].score != 5000 or scores[2].score != 3000:
		print("❌ FAILED: Scores not sorted correctly")
		return

	print("✅ Score retrieval and sorting working correctly")

	manager.queue_free()

func _test_demo_player_ai():
	print("\n3. Testing DemoPlayer AI...")

	var demo_player_script = load("res://scripts/kiosk/DemoPlayer.gd")
	if not demo_player_script:
		print("❌ FAILED: Could not load DemoPlayer.gd")
		return

	print("✅ DemoPlayer script loaded successfully")

	# Create instance and test difficulty settings
	var demo_player = demo_player_script.new()

	# Test difficulty configurations
	var difficulties = ["beginner", "intermediate", "expert"]
	for difficulty in difficulties:
		demo_player.set_difficulty(difficulty)
		var config = demo_player.config

		if not config.has("reaction_time") or not config.has("aggression_factor"):
			print("❌ FAILED: Configuration not set properly for difficulty: ", difficulty)
			return

	print("✅ Difficulty configuration working correctly")

	# Test AI state management
	if demo_player.get_current_state() != "IDLE":
		print("❌ FAILED: Initial AI state should be IDLE")
		return

	print("✅ AI state management working correctly")

	demo_player.queue_free()

func _test_attract_screen_manager():
	print("\n4. Testing AttractScreenManager...")

	var attract_script = load("res://scripts/kiosk/AttractScreenManager.gd")
	if not attract_script:
		print("❌ FAILED: Could not load AttractScreenManager.gd")
		return

	print("✅ AttractScreenManager script loaded successfully")

	# Create instance and test screen configuration
	var attract_manager = attract_script.new()

	var test_config = [
		{"type": "gameplay", "duration": 15.0},
		{"type": "features", "duration": 12.0},
		{"type": "high_scores", "duration": 10.0}
	]

	attract_manager.setup(test_config)

	if attract_manager.get_screen_count() != 3:
		print("❌ FAILED: Screen configuration not working correctly")
		return

	print("✅ Screen configuration working correctly")

	# Test screen info
	var screen_info = attract_manager.get_current_screen_info()
	if not screen_info.has("type") or not screen_info.has("is_cycling"):
		print("❌ FAILED: Screen info structure incorrect")
		return

	print("✅ Screen info retrieval working correctly")

	attract_manager.queue_free()

func _test_kiosk_ui():
	print("\n5. Testing KioskUI...")

	var kiosk_ui_script = load("res://scripts/kiosk/KioskUI.gd")
	if not kiosk_ui_script:
		print("❌ FAILED: Could not load KioskUI.gd")
		return

	print("✅ KioskUI script loaded successfully")

	# Create instance and test basic functionality
	var kiosk_ui = kiosk_ui_script.new()

	if kiosk_ui.is_visible():
		print("❌ FAILED: KioskUI should not be visible initially")
		return

	print("✅ Initial visibility state correct")

	# Test color scheme configuration
	var test_colors = {
		"primary": Color.RED,
		"secondary": Color.BLUE,
		"accent": Color.GREEN,
		"text": Color.WHITE
	}

	kiosk_ui.set_color_scheme("test", test_colors)

	if not kiosk_ui.color_schemes.has("test"):
		print("❌ FAILED: Color scheme setting not working")
		return

	print("✅ Color scheme configuration working correctly")

	kiosk_ui.queue_free()

func _test_configuration_loading():
	print("\n6. Testing Configuration Loading...")

	# Check if configuration file exists
	if not FileAccess.file_exists("res://kiosk_config.json"):
		print("❌ FAILED: kiosk_config.json not found")
		return

	print("✅ Configuration file exists")

	# Test loading configuration
	var file = FileAccess.open("res://kiosk_config.json", FileAccess.READ)
	if not file:
		print("❌ FAILED: Could not open configuration file")
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		print("❌ FAILED: Configuration file contains invalid JSON")
		return

	var config = json.data

	# Check required configuration keys
	var required_keys = ["enabled", "input_timeout", "attract_cycle_time", "demo_session_length", "difficulty_preset"]

	for key in required_keys:
		if not config.has(key):
			print("❌ FAILED: Missing required configuration key: ", key)
			return

	print("✅ Configuration structure valid")

	# Test deployment presets
	if not config.has("deployment_presets"):
		print("❌ FAILED: Missing deployment presets")
		return

	var presets = config.deployment_presets
	var expected_presets = ["arcade", "exhibition", "retail", "demonstration"]

	for preset in expected_presets:
		if not presets.has(preset):
			print("❌ FAILED: Missing deployment preset: ", preset)
			return

	print("✅ Deployment presets configured correctly")
	print("✅ Configuration loading test completed successfully")