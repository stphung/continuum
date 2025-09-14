extends GdUnitTestSuite
## Comprehensive tests for KioskManager state management and transitions

var kiosk_manager: Node
var mock_game_scene: Node
var original_scene: Node

func before():
	"""Setup test environment before each test"""
	# Store original scene
	original_scene = get_tree().current_scene

	# Create mock game scene
	mock_game_scene = Node.new()
	mock_game_scene.name = "MockGameScene"
	mock_game_scene.set_script(preload("res://test/helpers/MockGameScene.gd"))

	# Get KioskManager instance (it's an autoload)
	kiosk_manager = KioskManager

	# Ensure clean state
	kiosk_manager.force_exit_kiosk_mode()
	await get_tree().process_frame

func after():
	"""Cleanup after each test"""
	if kiosk_manager:
		kiosk_manager.force_exit_kiosk_mode()

	# Restore original scene
	if original_scene:
		get_tree().current_scene = original_scene

	# Clean up mock scene
	if mock_game_scene and is_instance_valid(mock_game_scene):
		mock_game_scene.queue_free()

	await get_tree().process_frame

# Configuration Tests
func test_default_configuration_loaded():
	"""Test that default configuration is properly loaded"""
	assert_that(kiosk_manager.config).is_not_empty()
	assert_that(kiosk_manager.config.has("enabled")).is_true()
	assert_that(kiosk_manager.config.has("input_timeout")).is_true()
	assert_that(kiosk_manager.config.has("attract_cycle_time")).is_true()
	assert_that(kiosk_manager.config.has("demo_session_length")).is_true()

func test_configuration_validation():
	"""Test configuration has all required keys"""
	var required_keys = [
		"enabled", "input_timeout", "attract_cycle_time",
		"demo_session_length", "high_score_display_time",
		"difficulty_preset", "auto_transition", "deployment_type",
		"attract_screens"
	]

	for key in required_keys:
		assert_that(kiosk_manager.config.has(key)).is_true()

func test_runtime_configuration_update():
	"""Test updating configuration at runtime"""
	var new_config = {"input_timeout": 45.0, "difficulty_preset": "expert"}
	kiosk_manager.update_configuration(new_config)

	assert_that(kiosk_manager.config.input_timeout).is_equal(45.0)
	assert_that(kiosk_manager.config.difficulty_preset).is_equal("expert")

# State Management Tests
func test_initial_state_is_disabled():
	"""Test KioskManager starts in disabled state"""
	assert_that(kiosk_manager.get_current_state()).is_equal("DISABLED")
	assert_that(kiosk_manager.is_kiosk_active()).is_false()

func test_state_transition_to_attract():
	"""Test transitioning to attract mode"""
	# Enable kiosk mode
	kiosk_manager.config.enabled = true

	# Monitor state change signal
	var state_changed_count = [0]
	var last_state = [""]
	kiosk_manager.kiosk_state_changed.connect(func(new_state):
		state_changed_count[0] += 1
		last_state[0] = new_state
	)

	kiosk_manager.force_enter_kiosk_mode()
	await get_tree().process_frame

	assert_that(kiosk_manager.get_current_state()).is_equal("ATTRACT")
	assert_that(kiosk_manager.is_kiosk_active()).is_true()
	assert_that(state_changed_count[0]).is_greater(0)
	assert_that(last_state[0]).is_equal("ATTRACT")

func test_state_transition_to_disabled():
	"""Test transitioning back to disabled state"""
	# Setup kiosk mode
	kiosk_manager.config.enabled = true
	kiosk_manager.force_enter_kiosk_mode()
	await get_tree().process_frame

	# Monitor state change signal
	var state_changed_count = [0]
	var last_state = [""]
	kiosk_manager.kiosk_state_changed.connect(func(new_state):
		state_changed_count[0] += 1
		last_state[0] = new_state
	)

	kiosk_manager.force_exit_kiosk_mode()
	await get_tree().process_frame

	assert_that(kiosk_manager.get_current_state()).is_equal("DISABLED")
	assert_that(kiosk_manager.is_kiosk_active()).is_false()
	assert_that(state_changed_count[0]).is_greater(0)
	assert_that(last_state[0]).is_equal("DISABLED")

func test_invalid_state_transitions():
	"""Test that invalid state transitions are handled gracefully"""
	# Try to enter kiosk mode when already active
	kiosk_manager.config.enabled = true
	kiosk_manager.force_enter_kiosk_mode()
	await get_tree().process_frame

	var initial_state = kiosk_manager.get_current_state()
	kiosk_manager.force_enter_kiosk_mode()  # Should have no effect
	await get_tree().process_frame

	assert_that(kiosk_manager.get_current_state()).is_equal(initial_state)

# Input Detection Tests
func test_user_input_detection():
	"""Test that user input is properly detected"""
	kiosk_manager.config.enabled = true

	# Create mock input event
	var mock_input = InputEventKey.new()
	mock_input.keycode = KEY_SPACE
	mock_input.pressed = true

	# Should be recognized as user input
	var result = kiosk_manager._is_user_input(mock_input)
	assert_that(result).is_true()

func test_ai_input_detection():
	"""Test that AI-generated input is filtered out"""
	kiosk_manager.config.enabled = true

	# Create mock AI input with metadata
	var mock_ai_input = InputEventKey.new()
	mock_ai_input.keycode = KEY_SPACE
	mock_ai_input.pressed = true
	mock_ai_input.set_meta("ai_generated", true)

	# Should not be recognized as user input
	var result = kiosk_manager._is_user_input(mock_ai_input)
	assert_that(result).is_false()

func test_input_timeout_functionality():
	"""Test input timeout triggers kiosk mode"""
	kiosk_manager.config.enabled = true
	kiosk_manager.config.input_timeout = 0.1  # Very short timeout for testing

	# Start input monitoring
	kiosk_manager._start_input_monitoring()

	# Wait for timeout
	await get_tree().create_timer(0.2).timeout

	# Should have entered kiosk mode
	assert_that(kiosk_manager.is_kiosk_active()).is_true()

func test_input_resets_timeout():
	"""Test that user input resets the inactivity timer"""
	kiosk_manager.config.enabled = true
	kiosk_manager.config.input_timeout = 0.2
	kiosk_manager._start_input_monitoring()

	# Wait half the timeout
	await get_tree().create_timer(0.1).timeout

	# Send user input
	var mock_input = InputEventKey.new()
	mock_input.keycode = KEY_SPACE
	kiosk_manager._unhandled_input(mock_input)

	# Wait another half timeout (should not trigger)
	await get_tree().create_timer(0.15).timeout

	assert_that(kiosk_manager.is_kiosk_active()).is_false()

# Subsystem Integration Tests
func test_subsystems_initialized():
	"""Test that all subsystems are properly initialized"""
	assert_that(kiosk_manager.demo_player).is_not_null()
	assert_that(kiosk_manager.attract_screen_manager).is_not_null()
	assert_that(kiosk_manager.high_score_manager).is_not_null()
	assert_that(kiosk_manager.kiosk_ui).is_not_null()

func test_subsystem_signal_connections():
	"""Test that subsystem signals are properly connected"""
	# Check demo player signals
	assert_that(kiosk_manager.demo_player.demo_ended.is_connected(kiosk_manager._on_demo_ended)).is_true()
	assert_that(kiosk_manager.demo_player.high_score_achieved.is_connected(kiosk_manager._on_high_score_achieved)).is_true()

	# Check attract screen signals
	assert_that(kiosk_manager.attract_screen_manager.cycle_completed.is_connected(kiosk_manager._on_attract_cycle_completed)).is_true()

	# Check high score signals
	assert_that(kiosk_manager.high_score_manager.scores_updated.is_connected(kiosk_manager._on_high_scores_updated)).is_true()

func test_demo_session_lifecycle():
	"""Test complete demo session lifecycle"""
	kiosk_manager.config.enabled = true
	kiosk_manager.config.demo_session_length = 0.2  # Short session for testing

	# Monitor demo signals
	var demo_started_count = [0]
	var demo_ended_count = [0]
	kiosk_manager.demo_session_started.connect(func(): demo_started_count[0] += 1)
	kiosk_manager.demo_session_ended.connect(func(): demo_ended_count[0] += 1)

	# Start demo
	kiosk_manager.force_enter_kiosk_mode()
	kiosk_manager._start_demo_session()
	await get_tree().process_frame

	assert_that(demo_started_count[0]).is_equal(1)

	# Wait for demo to end
	await get_tree().create_timer(0.3).timeout

	assert_that(demo_ended_count[0]).is_equal(1)

# Performance and Error Handling Tests
func test_handles_missing_game_scene():
	"""Test graceful handling when game scene is missing"""
	# Temporarily remove current scene
	get_tree().current_scene = null

	kiosk_manager.config.enabled = true
	kiosk_manager.force_enter_kiosk_mode()
	await get_tree().process_frame

	# Should handle gracefully without crashing
	assert_that(kiosk_manager.is_kiosk_active()).is_true()

func test_memory_cleanup_on_exit():
	"""Test proper memory cleanup when exiting kiosk mode"""
	kiosk_manager.config.enabled = true
	kiosk_manager.force_enter_kiosk_mode()
	await get_tree().process_frame

	var initial_node_count = get_tree().get_node_count()

	kiosk_manager.force_exit_kiosk_mode()
	await get_tree().process_frame

	# Node count should not significantly increase (allowing for some variance)
	var final_node_count = get_tree().get_node_count()
	assert_that(abs(final_node_count - initial_node_count)).is_less_than(5)

func test_signal_emission_timing():
	"""Test that signals are emitted at correct times"""
	kiosk_manager.config.enabled = true

	# Monitor signals
	var state_changed_count = [0]
	var attract_cycle_count = [0]
	kiosk_manager.kiosk_state_changed.connect(func(state): state_changed_count[0] += 1)
	kiosk_manager.attract_cycle_started.connect(func(): attract_cycle_count[0] += 1)

	kiosk_manager.force_enter_kiosk_mode()
	await get_tree().process_frame

	# State change should be immediate
	assert_that(state_changed_count[0]).is_greater(0)

func test_concurrent_state_changes():
	"""Test handling of rapid state change requests"""
	kiosk_manager.config.enabled = true

	# Rapid enter/exit requests
	kiosk_manager.force_enter_kiosk_mode()
	kiosk_manager.force_exit_kiosk_mode()
	kiosk_manager.force_enter_kiosk_mode()
	kiosk_manager.force_exit_kiosk_mode()

	await get_tree().process_frame

	# Should end in consistent state
	assert_that(kiosk_manager.get_current_state()).is_equal("DISABLED")

# API Tests
func test_public_api_methods():
	"""Test public API methods return expected types"""
	assert_that(kiosk_manager.is_kiosk_active()).is_false()
	assert_that(kiosk_manager.get_current_state()).is_instance_of(TYPE_STRING)
	assert_that(kiosk_manager.get_demo_statistics()).is_instance_of(TYPE_DICTIONARY)
	assert_that(kiosk_manager.get_attract_screen_info()).is_instance_of(TYPE_DICTIONARY)

func test_configuration_persistence():
	"""Test configuration changes persist through state transitions"""
	var original_timeout = kiosk_manager.config.input_timeout
	kiosk_manager.update_configuration({"input_timeout": 99.9})

	kiosk_manager.config.enabled = true
	kiosk_manager.force_enter_kiosk_mode()
	await get_tree().process_frame

	kiosk_manager.force_exit_kiosk_mode()
	await get_tree().process_frame

	assert_that(kiosk_manager.config.input_timeout).is_equal(99.9)

func test_disabled_mode_ignores_input():
	"""Test that disabled kiosk mode ignores input monitoring"""
	kiosk_manager.config.enabled = false

	var mock_input = InputEventKey.new()
	mock_input.keycode = KEY_SPACE

	# Should not affect anything when disabled
	kiosk_manager._unhandled_input(mock_input)
	await get_tree().process_frame

	assert_that(kiosk_manager.is_kiosk_active()).is_false()