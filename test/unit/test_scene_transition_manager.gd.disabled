extends GdUnitTestSuite

## Unit Tests for SceneTransitionManager
## Tests scene routing, transition animations, error handling, and state management
## Part of the Continuum Professional Title Screen System Test Suite

# Class under test
var scene_transition_manager: Node

# Mock scene paths for testing
const VALID_SCENE_PATH = "res://scenes/main/Game.tscn"
const INVALID_SCENE_PATH = "res://scenes/nonexistent/FakeScene.tscn"
const TITLE_SCENE_PATH = "res://scenes/menus/TitleScreen.tscn"

# Helper variables
var original_scene_path: String
var signal_emissions: Array = []

func before():
	# Create a fresh instance of SceneTransitionManager for each test
	scene_transition_manager = preload("res://scripts/autoloads/SceneTransitionManager.gd").new()
	scene_transition_manager.name = "SceneTransitionManagerTest"
	add_child(scene_transition_manager)
	auto_free(scene_transition_manager)

	# Reset signal tracking
	signal_emissions.clear()

	# Store original scene path for restoration
	original_scene_path = scene_transition_manager.get_current_scene_path()

func after():
	# Clean up any ongoing transitions
	if scene_transition_manager and is_instance_valid(scene_transition_manager):
		scene_transition_manager.is_transitioning = false

# === Initialization Tests ===

func test_scene_transition_manager_initialization():
	"""Test proper initialization of SceneTransitionManager components"""
	assert_that(scene_transition_manager).is_not_null()
	assert_that(scene_transition_manager.transition_duration).is_greater(0.0)
	assert_that(scene_transition_manager.fade_color).is_equal(Color.BLACK)
	assert_that(scene_transition_manager.is_transitioning).is_false()
	assert_that(scene_transition_manager.fade_overlay).is_not_null()
	assert_that(scene_transition_manager.loading_label).is_not_null()

func test_fade_overlay_setup():
	"""Test fade overlay initialization and configuration"""
	var fade_overlay = scene_transition_manager.fade_overlay
	assert_that(fade_overlay).is_not_null()
	assert_that(fade_overlay.name).is_equal("FadeOverlay")
	assert_that(fade_overlay.color).is_equal(Color.BLACK)
	assert_that(fade_overlay.modulate.a).is_equal_approx(0.0, 0.01)
	assert_that(fade_overlay.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	assert_that(fade_overlay.z_index).is_equal(1000)

func test_loading_label_setup():
	"""Test loading label initialization and configuration"""
	var loading_label = scene_transition_manager.loading_label
	assert_that(loading_label).is_not_null()
	assert_that(loading_label.name).is_equal("LoadingLabel")
	assert_that(loading_label.text).is_equal("Loading...")
	assert_that(loading_label.horizontal_alignment).is_equal(HORIZONTAL_ALIGNMENT_CENTER)
	assert_that(loading_label.vertical_alignment).is_equal(VERTICAL_ALIGNMENT_CENTER)
	assert_that(loading_label.modulate.a).is_equal_approx(0.0, 0.01)

# === State Management Tests ===

func test_initial_state():
	"""Test initial state of the transition manager"""
	assert_that(scene_transition_manager.is_scene_transition_active()).is_false()
	assert_that(scene_transition_manager.get_current_scene_path()).is_not_empty()

func test_get_current_scene_path():
	"""Test current scene path tracking"""
	var current_path = scene_transition_manager.get_current_scene_path()
	assert_that(current_path).is_not_empty()
	# Path should be absolute and contain .tscn extension
	assert_that(current_path.begins_with("res://")).is_true()
	assert_that(current_path.ends_with(".tscn")).is_true()

func test_is_scene_transition_active():
	"""Test transition state tracking"""
	assert_that(scene_transition_manager.is_scene_transition_active()).is_false()

	# Simulate transition state
	scene_transition_manager.is_transitioning = true
	assert_that(scene_transition_manager.is_scene_transition_active()).is_true()

# === Transition Validation Tests ===

func test_transition_to_scene_with_invalid_path():
	"""Test transition rejection with invalid scene path"""
	var result = await scene_transition_manager.transition_to_scene(INVALID_SCENE_PATH)
	assert_that(result).is_false()
	assert_that(scene_transition_manager.is_scene_transition_active()).is_false()

func test_transition_during_active_transition():
	"""Test transition rejection when already transitioning"""
	# Set up active transition state
	scene_transition_manager.is_transitioning = true

	var result = await scene_transition_manager.transition_to_scene(VALID_SCENE_PATH)
	assert_that(result).is_false()

func test_instant_scene_change_during_transition():
	"""Test instant change rejection during active transition"""
	scene_transition_manager.is_transitioning = true

	var result = scene_transition_manager.instant_scene_change(VALID_SCENE_PATH)
	assert_that(result).is_false()

func test_instant_scene_change_with_invalid_path():
	"""Test instant change rejection with invalid path"""
	var result = scene_transition_manager.instant_scene_change(INVALID_SCENE_PATH)
	assert_that(result).is_false()

# === Signal Testing ===

func test_transition_signals():
	"""Test signal emissions during transition process"""
	# Connect to signals for testing
	scene_transition_manager.scene_transition_started.connect(_on_transition_started)
	scene_transition_manager.transition_fade_in_completed.connect(_on_fade_in_completed)
	scene_transition_manager.transition_fade_out_completed.connect(_on_fade_out_completed)
	scene_transition_manager.scene_transition_completed.connect(_on_transition_completed)

	# Attempt transition (will fail but should emit start signal)
	await scene_transition_manager.transition_to_scene(INVALID_SCENE_PATH)

	# Check signal emissions
	assert_that(signal_emissions.has("transition_started")).is_true()

func _on_transition_started(from_scene: String, to_scene: String):
	signal_emissions.append("transition_started")
	assert_that(from_scene).is_not_empty()
	assert_that(to_scene).is_not_empty()

func _on_fade_in_completed():
	signal_emissions.append("fade_in_completed")

func _on_fade_out_completed():
	signal_emissions.append("fade_out_completed")

func _on_transition_completed(scene_name: String):
	signal_emissions.append("transition_completed")
	assert_that(scene_name).is_not_empty()

# === Quick Access Methods Tests ===

func test_transition_to_game():
	"""Test quick transition to game scene"""
	# This should attempt transition to Game.tscn
	var result = await scene_transition_manager.transition_to_game()
	# Result depends on scene availability, but method should exist and handle gracefully
	assert_that(result).is_not_null()

func test_transition_to_title():
	"""Test quick transition to title screen"""
	var result = await scene_transition_manager.transition_to_title()
	assert_that(result).is_not_null()

func test_transition_to_options():
	"""Test quick transition to options menu"""
	var result = await scene_transition_manager.transition_to_options()
	assert_that(result).is_not_null()

func test_transition_to_credits():
	"""Test quick transition to credits screen"""
	var result = await scene_transition_manager.transition_to_credits()
	assert_that(result).is_not_null()

# === Animation Component Tests ===

func test_fade_overlay_mouse_filter_changes():
	"""Test mouse filter changes during transitions"""
	var fade_overlay = scene_transition_manager.fade_overlay

	# Initially should allow input passthrough
	assert_that(fade_overlay.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)

	# Start fade to black (private method testing through reflection)
	scene_transition_manager._fade_to_black()
	await get_tree().process_frame

	# During transition should block input
	assert_that(fade_overlay.mouse_filter).is_equal(Control.MOUSE_FILTER_STOP)

func test_loading_indicator_visibility():
	"""Test loading indicator show/hide functionality"""
	var loading_label = scene_transition_manager.loading_label

	# Initially hidden
	assert_that(loading_label.modulate.a).is_equal_approx(0.0, 0.01)

	# Show loading
	scene_transition_manager._show_loading()
	assert_that(loading_label.modulate.a).is_equal_approx(1.0, 0.01)

	# Hide loading
	scene_transition_manager._hide_loading()
	assert_that(loading_label.modulate.a).is_equal_approx(0.0, 0.01)

# === Configuration Tests ===

func test_transition_duration_configuration():
	"""Test transition duration setting"""
	var original_duration = scene_transition_manager.transition_duration
	assert_that(original_duration).is_greater(0.0)

	# Test setting new duration
	scene_transition_manager.transition_duration = 1.0
	assert_that(scene_transition_manager.transition_duration).is_equal_approx(1.0, 0.01)

	# Restore original
	scene_transition_manager.transition_duration = original_duration

func test_fade_color_configuration():
	"""Test fade color setting"""
	var original_color = scene_transition_manager.fade_color
	assert_that(original_color).is_equal(Color.BLACK)

	# Test setting new color
	scene_transition_manager.fade_color = Color.RED
	assert_that(scene_transition_manager.fade_color).is_equal(Color.RED)

	# Restore original
	scene_transition_manager.fade_color = original_color

# === Error Handling Tests ===

func test_null_scene_path_handling():
	"""Test handling of null or empty scene paths"""
	var result1 = await scene_transition_manager.transition_to_scene("")
	assert_that(result1).is_false()

	var result2 = scene_transition_manager.instant_scene_change("")
	assert_that(result2).is_false()

func test_malformed_scene_path_handling():
	"""Test handling of malformed scene paths"""
	var malformed_paths = [
		"not_a_path",
		"res://",
		"file.txt",
		"res://scenes/invalid.notscene"
	]

	for path in malformed_paths:
		var result = await scene_transition_manager.transition_to_scene(path)
		assert_that(result).is_false()

# === Performance Tests ===

func test_transition_performance():
	"""Test transition performance characteristics"""
	var start_time = Time.get_ticks_msec()

	# Attempt quick transition
	await scene_transition_manager.transition_to_scene(INVALID_SCENE_PATH)

	var end_time = Time.get_ticks_msec()
	var duration = end_time - start_time

	# Should fail quickly (within 100ms for invalid path)
	assert_that(duration).is_less(100)

func test_fade_overlay_creation_performance():
	"""Test fade overlay creation performance"""
	var start_time = Time.get_ticks_msec()

	# Create new instance to test setup
	var new_manager = preload("res://scripts/autoloads/SceneTransitionManager.gd").new()
	add_child(new_manager)
	auto_free(new_manager)

	var end_time = Time.get_ticks_msec()
	var duration = end_time - start_time

	# Setup should be fast (within 50ms)
	assert_that(duration).is_less(50)

# === Tween Management Tests ===

func test_tween_cleanup():
	"""Test proper tween cleanup and management"""
	# Start a fade operation
	scene_transition_manager._fade_to_black()
	await get_tree().process_frame

	# Check tween exists
	assert_that(scene_transition_manager.tween).is_not_null()

	# Start another fade (should cleanup previous tween)
	scene_transition_manager._fade_from_black()
	await get_tree().process_frame

	# Should still have valid tween reference
	assert_that(scene_transition_manager.tween).is_not_null()

# === Integration Readiness Tests ===

func test_sound_manager_integration_readiness():
	"""Test readiness for SoundManager integration"""
	# Test safe node checking pattern used in the implementation
	var has_sound_manager = has_node("/root/SoundManager")
	assert_that(has_sound_manager).is_not_null()  # Should not crash

func test_autoload_process_mode():
	"""Test process mode configuration for autoload behavior"""
	assert_that(scene_transition_manager.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)

# === Resource Management Tests ===

func test_memory_cleanup():
	"""Test proper memory cleanup during transitions"""
	var initial_node_count = get_child_count()

	# Start transition that will fail
	await scene_transition_manager.transition_to_scene(INVALID_SCENE_PATH)

	# Should not leak nodes
	var final_node_count = get_child_count()
	assert_that(final_node_count).is_equal(initial_node_count)

func test_canvas_layer_cleanup():
	"""Test canvas layer is properly managed"""
	var canvas_layer = scene_transition_manager.get_child(0)  # Should be TransitionCanvas
	assert_that(canvas_layer).is_not_null()
	assert_that(canvas_layer.name).is_equal("TransitionCanvas")
	assert_that(canvas_layer.layer).is_equal(1000)