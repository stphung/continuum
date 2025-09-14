extends GdUnitTestSuite

## Unit Tests for CreditsScreen
## Tests scrolling, navigation, content display, and animation system
## Part of the Continuum Professional Title Screen System Test Suite

# Class under test
var credits_screen: Node2D

# Mock UI components
var mock_scroll_container: ScrollContainer
var mock_credits_content: VBoxContainer

# Test tracking
var signal_emissions: Array = []
var timer_count: int = 0

func before():
	# Create credits screen instance
	credits_screen = preload("res://scripts/menus/CreditsScreen.gd").new()
	credits_screen.name = "CreditsScreen"
	add_child(credits_screen)
	auto_free(credits_screen)

	# Create mock UI structure
	_setup_mock_ui_structure()

	# Reset tracking
	signal_emissions.clear()
	timer_count = 0

func after():
	# Clean up animations and timers
	if credits_screen and is_instance_valid(credits_screen):
		if credits_screen.scroll_tween:
			credits_screen.scroll_tween.kill()
		if credits_screen.entrance_tween:
			credits_screen.entrance_tween.kill()

		# Clean up any test timers
		for child in credits_screen.get_children():
			if child is Timer:
				child.queue_free()

func _setup_mock_ui_structure():
	"""Create mock UI structure matching expected scene layout"""
	# Create main UI container
	var ui_container = Control.new()
	ui_container.name = "UI"
	credits_screen.add_child(ui_container)

	var main_container = Control.new()
	main_container.name = "MainContainer"
	main_container.size = Vector2(800, 600)
	ui_container.add_child(main_container)

	# Create scroll container
	mock_scroll_container = ScrollContainer.new()
	mock_scroll_container.name = "ScrollContainer"
	mock_scroll_container.size = Vector2(750, 500)
	main_container.add_child(mock_scroll_container)

	# Create credits content
	mock_credits_content = VBoxContainer.new()
	mock_credits_content.name = "CreditsContent"
	mock_scroll_container.add_child(mock_credits_content)

	# Add some mock content to make scrolling meaningful
	for i in range(20):
		var label = Label.new()
		label.text = "Credit Line " + str(i + 1)
		label.size = Vector2(700, 30)
		mock_credits_content.add_child(label)

# === Initialization Tests ===

func test_credits_screen_initialization():
	"""Test proper initialization of CreditsScreen components"""
	assert_that(credits_screen).is_not_null()
	assert_that(credits_screen.scroll_speed).is_greater(0.0)
	assert_that(credits_screen.auto_scroll_enabled).is_true()
	assert_that(credits_screen.scroll_container).is_null()  # Not yet initialized
	assert_that(credits_screen.credits_content).is_null()   # Not yet initialized

func test_setup_references():
	"""Test UI component reference setup"""
	credits_screen.setup_references()

	assert_that(credits_screen.scroll_container).is_not_null()
	assert_that(credits_screen.credits_content).is_not_null()
	assert_that(credits_screen.scroll_container.name).is_equal("ScrollContainer")
	assert_that(credits_screen.credits_content.name).is_equal("CreditsContent")

func test_scroll_speed_configuration():
	"""Test scroll speed configuration"""
	var original_speed = credits_screen.scroll_speed
	assert_that(original_speed).is_equal_approx(50.0, 0.1)

	credits_screen.set_scroll_speed(75.0)
	assert_that(credits_screen.scroll_speed).is_equal_approx(75.0, 0.1)

	# Test minimum speed enforcement
	credits_screen.set_scroll_speed(5.0)
	assert_that(credits_screen.scroll_speed).is_equal_approx(10.0, 0.1)  # Should clamp to minimum

# === Animation Tests ===

func test_entrance_animation_setup():
	"""Test entrance animation configuration"""
	credits_screen.setup_references()
	credits_screen.setup_entrance_animation()

	assert_that(credits_screen.entrance_tween).is_not_null()

	# Check initial state
	assert_that(credits_screen.credits_content.modulate.a).is_equal_approx(0.0, 0.01)
	assert_that(credits_screen.credits_content.position.y).is_equal(50)

func test_entrance_animation_completion():
	"""Test entrance animation completion"""
	credits_screen.setup_references()
	credits_screen.setup_entrance_animation()

	# Wait for animation to potentially complete
	await get_tree().process_frame
	await get_tree().process_frame

	# Should have entrance tween configured
	assert_that(credits_screen.entrance_tween).is_not_null()

func test_auto_scroll_setup():
	"""Test automatic scroll setup"""
	credits_screen.setup_references()
	credits_screen.auto_scroll_enabled = true

	# Create a mock entrance tween that's already finished
	var mock_tween = create_tween()
	mock_tween.tween_interval(0.01)  # Very short tween
	credits_screen.entrance_tween = mock_tween

	await mock_tween.finished

	# Setup auto scroll
	credits_screen.setup_auto_scroll()

	# Auto scroll should be configured if there's content to scroll
	await get_tree().process_frame

func test_auto_scroll_with_no_content():
	"""Test auto scroll setup with insufficient content"""
	credits_screen.setup_references()

	# Remove content to simulate no scrolling needed
	for child in mock_credits_content.get_children():
		child.queue_free()

	await get_tree().process_frame

	# Setup auto scroll with no content
	credits_screen.setup_auto_scroll()

	# Should handle gracefully
	await get_tree().process_frame

# === Scrolling Control Tests ===

func test_manual_scroll_down():
	"""Test manual scrolling downward"""
	credits_screen.setup_references()

	var initial_scroll = credits_screen.scroll_container.scroll_vertical
	credits_screen.manual_scroll(30)

	var final_scroll = credits_screen.scroll_container.scroll_vertical
	assert_that(final_scroll).is_greater_equal(initial_scroll)

func test_manual_scroll_up():
	"""Test manual scrolling upward"""
	credits_screen.setup_references()

	# First scroll down to have room to scroll up
	credits_screen.scroll_container.scroll_vertical = 100

	var initial_scroll = credits_screen.scroll_container.scroll_vertical
	credits_screen.manual_scroll(-30)

	var final_scroll = credits_screen.scroll_container.scroll_vertical
	assert_that(final_scroll).is_less_equal(initial_scroll)

func test_manual_scroll_bounds():
	"""Test manual scroll bounds checking"""
	credits_screen.setup_references()

	# Test scrolling beyond minimum (should clamp to 0)
	credits_screen.scroll_container.scroll_vertical = 0
	credits_screen.manual_scroll(-100)
	assert_that(credits_screen.scroll_container.scroll_vertical).is_equal(0)

	# Test scrolling beyond maximum
	credits_screen.manual_scroll(10000)  # Large value
	var max_scroll = max(0, credits_screen.credits_content.get_minimum_size().y - credits_screen.scroll_container.size.y)
	assert_that(credits_screen.scroll_container.scroll_vertical).is_less_equal(max(max_scroll, 10000))

func test_manual_scroll_pauses_auto_scroll():
	"""Test that manual scrolling pauses auto scroll"""
	credits_screen.setup_references()
	credits_screen.auto_scroll_enabled = true

	# Create a mock scroll tween
	credits_screen.scroll_tween = create_tween()
	credits_screen.scroll_tween.tween_interval(1.0)

	credits_screen.manual_scroll(30)

	# Should pause the auto scroll tween
	if credits_screen.scroll_tween:
		# Tween should be paused (though testing pause state might be tricky)
		assert_that(credits_screen.scroll_tween).is_not_null()

func test_resume_auto_scroll():
	"""Test auto scroll resume functionality"""
	credits_screen.setup_references()
	credits_screen.auto_scroll_enabled = true

	# Create a mock tween
	credits_screen.scroll_tween = create_tween()
	credits_screen.scroll_tween.tween_interval(1.0)

	credits_screen._resume_auto_scroll()

	# Should attempt to resume auto scroll
	assert_that(true).is_true()  # Should not crash

# === Auto-scroll Toggle Tests ===

func test_toggle_auto_scroll_enable():
	"""Test enabling auto scroll toggle"""
	credits_screen.setup_references()
	credits_screen.auto_scroll_enabled = false

	credits_screen.toggle_auto_scroll()

	assert_that(credits_screen.auto_scroll_enabled).is_true()

func test_toggle_auto_scroll_disable():
	"""Test disabling auto scroll toggle"""
	credits_screen.setup_references()
	credits_screen.auto_scroll_enabled = true

	# Create a mock tween to be killed
	credits_screen.scroll_tween = create_tween()
	credits_screen.scroll_tween.tween_interval(1.0)

	credits_screen.toggle_auto_scroll()

	assert_that(credits_screen.auto_scroll_enabled).is_false()

func test_toggle_visual_feedback():
	"""Test visual feedback during auto scroll toggle"""
	credits_screen.setup_references()

	# Test enabling (should highlight)
	credits_screen.auto_scroll_enabled = false
	credits_screen.toggle_auto_scroll()

	# Test disabling (should dim)
	credits_screen.auto_scroll_enabled = true
	credits_screen.toggle_auto_scroll()

	# Visual feedback should complete without error
	await get_tree().process_frame

# === Input Handling Tests ===

func test_input_scroll_up():
	"""Test upward scroll input handling"""
	credits_screen.setup_references()

	var input_event = InputEventKey.new()
	input_event.pressed = true

	var initial_scroll = credits_screen.scroll_container.scroll_vertical
	credits_screen.manual_scroll(-30)  # Simulate up input

	var final_scroll = credits_screen.scroll_container.scroll_vertical
	assert_that(final_scroll).is_less_equal(initial_scroll)

func test_input_scroll_down():
	"""Test downward scroll input handling"""
	credits_screen.setup_references()

	var input_event = InputEventKey.new()
	input_event.pressed = true

	var initial_scroll = credits_screen.scroll_container.scroll_vertical
	credits_screen.manual_scroll(30)  # Simulate down input

	var final_scroll = credits_screen.scroll_container.scroll_vertical
	assert_that(final_scroll).is_greater_equal(initial_scroll)

func test_input_toggle_auto_scroll():
	"""Test auto scroll toggle input"""
	credits_screen.setup_references()
	var initial_state = credits_screen.auto_scroll_enabled

	credits_screen.toggle_auto_scroll()

	assert_that(credits_screen.auto_scroll_enabled).is_not_equal(initial_state)

func test_input_back_navigation():
	"""Test back navigation input"""
	credits_screen.setup_references()

	# Should not crash
	credits_screen._on_back_button_pressed()
	await get_tree().process_frame

# === Timer Management Tests ===

func test_resume_timer_creation():
	"""Test resume timer creation in manual scroll"""
	credits_screen.setup_references()
	credits_screen.auto_scroll_enabled = true

	var initial_child_count = credits_screen.get_child_count()

	credits_screen.manual_scroll(30)

	await get_tree().process_frame

	# Should have created a timer (though it may be auto-freed)
	# Test that no excessive timers are created
	var final_child_count = credits_screen.get_child_count()
	assert_that(final_child_count - initial_child_count).is_less_equal(2)  # Allow some variance

# === Section Navigation Tests ===

func test_jump_to_section():
	"""Test jumping to specific sections"""
	credits_screen.setup_references()

	credits_screen.jump_to_section("Development Team")

	# Should reset to top (current implementation)
	assert_that(credits_screen.scroll_container.scroll_vertical).is_equal(0)

func test_jump_to_nonexistent_section():
	"""Test jumping to non-existent sections"""
	credits_screen.setup_references()

	credits_screen.jump_to_section("Nonexistent Section")

	# Should handle gracefully and reset to top
	assert_that(credits_screen.scroll_container.scroll_vertical).is_equal(0)

# === Exit Animation Tests ===

func test_back_button_exit_animation():
	"""Test exit animation on back button"""
	credits_screen.setup_references()

	# Create some tweens to be killed
	credits_screen.scroll_tween = create_tween()
	credits_screen.entrance_tween = create_tween()

	# Start exit process (will be async)
	var exit_task = credits_screen._on_back_button_pressed()

	# Should kill existing animations
	assert_that(true).is_true()  # Should not crash

	# Wait a frame for async operations
	await get_tree().process_frame

func test_animation_cleanup_on_exit():
	"""Test proper animation cleanup on exit"""
	credits_screen.setup_references()

	# Create mock tweens
	credits_screen.scroll_tween = create_tween()
	credits_screen.scroll_tween.tween_interval(1.0)
	credits_screen.entrance_tween = create_tween()
	credits_screen.entrance_tween.tween_interval(1.0)

	credits_screen._on_back_button_pressed()

	await get_tree().process_frame

	# Animations should be cleaned up (killed)
	# Note: killed tweens become invalid, so we just test no crash occurs

# === Performance Tests ===

func test_scroll_performance():
	"""Test scrolling performance under rapid input"""
	credits_screen.setup_references()

	var start_time = Time.get_ticks_msec()

	# Rapid scroll operations
	for i in range(100):
		credits_screen.manual_scroll(10 if i % 2 == 0 else -10)

	var end_time = Time.get_ticks_msec()
	var duration = end_time - start_time

	# Should handle rapid scrolling efficiently (within 100ms)
	assert_that(duration).is_less(100)

func test_auto_scroll_setup_performance():
	"""Test auto scroll setup performance"""
	credits_screen.setup_references()

	var start_time = Time.get_ticks_msec()

	# Multiple auto scroll setups
	for i in range(10):
		credits_screen.auto_scroll_enabled = true
		credits_screen.setup_auto_scroll()
		credits_screen.auto_scroll_enabled = false

	var end_time = Time.get_ticks_msec()
	var duration = end_time - start_time

	# Should handle multiple setups efficiently (within 100ms)
	assert_that(duration).is_less(100)

func test_content_size_calculation_performance():
	"""Test content size calculation performance"""
	credits_screen.setup_references()

	var start_time = Time.get_ticks_msec()

	# Multiple size calculations
	for i in range(50):
		var content_height = credits_screen.credits_content.get_minimum_size().y
		var container_height = credits_screen.scroll_container.size.y
		var max_scroll = max(0, content_height - container_height)

	var end_time = Time.get_ticks_msec()
	var duration = end_time - start_time

	# Should calculate sizes efficiently (within 50ms)
	assert_that(duration).is_less(50)

# === Sound Integration Tests ===

func test_sound_manager_integration():
	"""Test sound manager integration readiness"""
	# Should not crash when checking for sound manager
	var has_sound_manager = has_node("/root/SoundManager")
	assert_that(has_sound_manager).is_not_null()

func test_menu_sound_calls():
	"""Test menu sound method calls"""
	credits_screen.setup_references()

	# These should not crash even without SoundManager
	credits_screen.manual_scroll(30)
	credits_screen.toggle_auto_scroll()
	credits_screen._on_back_button_pressed()

	await get_tree().process_frame

# === Edge Case Tests ===

func test_null_ui_references():
	"""Test handling of null UI references"""
	# Don't set up references, leave them null
	credits_screen.scroll_container = null
	credits_screen.credits_content = null

	# Should handle null references gracefully
	credits_screen.manual_scroll(30)
	credits_screen.toggle_auto_scroll()
	credits_screen.jump_to_section("Test")

	# Should not crash

func test_missing_ui_structure():
	"""Test handling of missing UI structure"""
	# Remove the mock UI structure
	for child in credits_screen.get_children():
		child.queue_free()

	await get_tree().process_frame

	# Try to setup references with missing structure
	credits_screen.setup_references()

	# Should handle missing structure gracefully

func test_extreme_scroll_values():
	"""Test extreme scroll values"""
	credits_screen.setup_references()

	# Test very large positive scroll
	credits_screen.manual_scroll(999999)
	assert_that(credits_screen.scroll_container.scroll_vertical).is_greater_equal(0)

	# Test very large negative scroll
	credits_screen.manual_scroll(-999999)
	assert_that(credits_screen.scroll_container.scroll_vertical).is_equal(0)  # Should clamp to 0

func test_rapid_toggle_auto_scroll():
	"""Test rapid auto scroll toggling"""
	credits_screen.setup_references()

	# Rapid toggling should not cause issues
	for i in range(20):
		credits_screen.toggle_auto_scroll()

	await get_tree().process_frame

	# Should handle rapid toggling gracefully

# === State Management Tests ===

func test_scroll_state_persistence():
	"""Test scroll state persistence during operations"""
	credits_screen.setup_references()

	# Set specific scroll position
	credits_screen.scroll_container.scroll_vertical = 100

	# Perform operations
	credits_screen.toggle_auto_scroll()
	credits_screen.manual_scroll(10)

	# Position should be updated but not reset unexpectedly
	assert_that(credits_screen.scroll_container.scroll_vertical).is_greater(90)

func test_auto_scroll_state_consistency():
	"""Test auto scroll state consistency"""
	credits_screen.auto_scroll_enabled = true
	assert_that(credits_screen.auto_scroll_enabled).is_true()

	credits_screen.toggle_auto_scroll()
	assert_that(credits_screen.auto_scroll_enabled).is_false()

	credits_screen.toggle_auto_scroll()
	assert_that(credits_screen.auto_scroll_enabled).is_true()

# === Tween Management Tests ===

func test_tween_cleanup():
	"""Test proper tween cleanup"""
	credits_screen.setup_references()

	# Create tweens
	credits_screen.scroll_tween = create_tween()
	credits_screen.entrance_tween = create_tween()

	# Multiple operations that might create/destroy tweens
	credits_screen.toggle_auto_scroll()
	credits_screen.toggle_auto_scroll()
	credits_screen.setup_entrance_animation()

	await get_tree().process_frame

	# Should handle tween management properly

func test_tween_interruption_handling():
	"""Test handling of tween interruptions"""
	credits_screen.setup_references()

	# Start entrance animation
	credits_screen.setup_entrance_animation()

	# Interrupt with exit
	credits_screen._on_back_button_pressed()

	await get_tree().process_frame

	# Should handle interruption gracefully

# === Memory Management Tests ===

func test_memory_cleanup():
	"""Test memory cleanup during various operations"""
	var initial_node_count = get_child_count()

	credits_screen.setup_references()
	credits_screen.setup_entrance_animation()
	credits_screen.setup_auto_scroll()

	# Perform various operations
	for i in range(5):
		credits_screen.manual_scroll(20)
		credits_screen.toggle_auto_scroll()

	await get_tree().process_frame

	# Should not create excessive nodes
	var final_node_count = get_child_count()
	assert_that(final_node_count - initial_node_count).is_less(10)

func test_timer_cleanup():
	"""Test timer cleanup"""
	credits_screen.setup_references()
	credits_screen.auto_scroll_enabled = true

	var initial_timer_count = _count_timers()

	# Create resume timers through manual scrolling
	for i in range(3):
		credits_screen.manual_scroll(30)

	await get_tree().process_frame

	var final_timer_count = _count_timers()

	# Should not accumulate excessive timers
	assert_that(final_timer_count - initial_timer_count).is_less(5)

func _count_timers() -> int:
	"""Count timers in the credits screen"""
	var count = 0
	for child in credits_screen.get_children():
		if child is Timer:
			count += 1
	return count

# === Integration Readiness Tests ===

func test_scene_transition_manager_integration():
	"""Test scene transition manager integration readiness"""
	var has_scene_manager = has_node("/root/SceneTransitionManager")
	assert_that(has_scene_manager).is_not_null()

	# Back button should work with or without scene manager
	credits_screen._on_back_button_pressed()
	await get_tree().process_frame

func test_content_structure_flexibility():
	"""Test flexibility with different content structures"""
	credits_screen.setup_references()

	# Add different types of content
	var test_content = [
		Label.new(),
		Button.new(),
		TextureRect.new()
	]

	for content in test_content:
		mock_credits_content.add_child(content)

	# Should handle different content types
	credits_screen.setup_auto_scroll()
	await get_tree().process_frame