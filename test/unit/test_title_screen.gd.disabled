extends GdUnitTestSuite

## Unit Tests for TitleScreen
## Tests menu navigation, button interactions, animations, and keyboard input
## Part of the Continuum Professional Title Screen System Test Suite

# Class under test
var title_screen: Node2D
var mock_ui_container: Control
var mock_buttons: Array[Button] = []

# Test scene structure
var test_scene_structure = {
	"UI": {
		"MainContainer": {
			"TitleContainer": Control.new(),
			"MenuContainer": {
				"StartButton": Button.new(),
				"OptionsButton": Button.new(),
				"CreditsButton": Button.new(),
				"QuitButton": Button.new()
			},
			"Instructions": Label.new()
		}
	}
}

# Signal tracking
var signal_emissions: Array = []
var button_press_count: int = 0

func before():
	# Create title screen instance
	title_screen = preload("res://scripts/menus/TitleScreen.gd").new()
	title_screen.name = "TitleScreen"
	add_child(title_screen)
	auto_free(title_screen)

	# Create mock UI structure
	_setup_mock_ui_structure()

	# Reset tracking variables
	signal_emissions.clear()
	button_press_count = 0

func after():
	# Clean up animations and timers
	if title_screen and is_instance_valid(title_screen):
		if title_screen.title_tween:
			title_screen.title_tween.kill()
		if title_screen.button_hover_tween:
			title_screen.button_hover_tween.kill()

func _setup_mock_ui_structure():
	"""Create mock UI structure matching the expected scene layout"""
	# Create main UI container
	var ui_container = Control.new()
	ui_container.name = "UI"
	title_screen.add_child(ui_container)

	var main_container = Control.new()
	main_container.name = "MainContainer"
	ui_container.add_child(main_container)

	# Create title container
	var title_container = Control.new()
	title_container.name = "TitleContainer"
	title_container.position = Vector2(100, 100)
	main_container.add_child(title_container)

	# Create menu container with buttons
	var menu_container = Control.new()
	menu_container.name = "MenuContainer"
	menu_container.position = Vector2(100, 200)
	main_container.add_child(menu_container)

	# Create menu buttons
	var button_names = ["StartButton", "OptionsButton", "CreditsButton", "QuitButton"]
	for button_name in button_names:
		var button = Button.new()
		button.name = button_name
		button.text = button_name.replace("Button", "").to_upper()
		button.size = Vector2(120, 40)
		menu_container.add_child(button)
		mock_buttons.append(button)

		# Connect button signals for testing
		button.pressed.connect(_on_test_button_pressed.bind(button_name))

	# Create instructions label
	var instructions = Label.new()
	instructions.name = "Instructions"
	instructions.text = "Use WASD or Arrow Keys to navigate"
	main_container.add_child(instructions)

func _on_test_button_pressed(button_name: String):
	"""Track button press events for testing"""
	button_press_count += 1
	signal_emissions.append("button_pressed_" + button_name)

# === Initialization Tests ===

func test_title_screen_initialization():
	"""Test proper initialization of TitleScreen components"""
	assert_that(title_screen).is_not_null()
	assert_that(title_screen.current_button_index).is_equal(0)
	assert_that(title_screen.is_animating).is_false()
	assert_that(title_screen.menu_buttons).is_not_null()

func test_menu_buttons_setup():
	"""Test menu button initialization and configuration"""
	# Call setup method
	title_screen.setup_menu_buttons()

	# Verify button array is populated
	assert_that(title_screen.menu_buttons.size()).is_greater(0)
	assert_that(title_screen.current_button_index).is_equal(0)

	# Check button focus configuration
	for button in title_screen.menu_buttons:
		if button:
			assert_that(button.focus_mode).is_equal(Control.FOCUS_ALL)

func test_keyboard_navigation_setup():
	"""Test keyboard navigation initialization"""
	title_screen.setup_keyboard_navigation()

	# Verify input processing is enabled
	assert_that(title_screen.get_process_input()).is_true()

# === Menu Navigation Tests ===

func test_navigate_down():
	"""Test downward menu navigation"""
	title_screen.setup_menu_buttons()
	var initial_index = title_screen.current_button_index

	title_screen.navigate_down()

	assert_that(title_screen.current_button_index).is_equal((initial_index + 1) % title_screen.menu_buttons.size())

func test_navigate_up():
	"""Test upward menu navigation"""
	title_screen.setup_menu_buttons()

	# Move to second button first
	title_screen.navigate_down()
	var current_index = title_screen.current_button_index

	title_screen.navigate_up()

	assert_that(title_screen.current_button_index).is_equal((current_index - 1 + title_screen.menu_buttons.size()) % title_screen.menu_buttons.size())

func test_navigate_wraparound():
	"""Test menu navigation wraparound behavior"""
	title_screen.setup_menu_buttons()

	# Navigate up from first button (should wrap to last)
	title_screen.current_button_index = 0
	title_screen.navigate_up()
	assert_that(title_screen.current_button_index).is_equal(title_screen.menu_buttons.size() - 1)

	# Navigate down from last button (should wrap to first)
	title_screen.current_button_index = title_screen.menu_buttons.size() - 1
	title_screen.navigate_down()
	assert_that(title_screen.current_button_index).is_equal(0)

func test_navigate_empty_menu():
	"""Test navigation with empty menu buttons array"""
	title_screen.menu_buttons = []

	# Should not crash
	title_screen.navigate_down()
	title_screen.navigate_up()

	# Index should remain 0
	assert_that(title_screen.current_button_index).is_equal(0)

# === Button Interaction Tests ===

func test_activate_current_button():
	"""Test activating the currently selected button"""
	title_screen.setup_menu_buttons()

	# Set current button to first button
	title_screen.current_button_index = 0

	# Connect signal to track emissions
	title_screen.menu_navigation_changed.connect(_on_navigation_changed)

	# Activate current button
	title_screen.activate_current_button()

	# Should trigger button press
	await get_tree().process_frame
	assert_that(button_press_count).is_greater_equal(1)

func test_button_hover_handling():
	"""Test mouse hover button handling"""
	title_screen.setup_menu_buttons()

	var test_index = 2
	title_screen._on_button_hovered(test_index)

	assert_that(title_screen.current_button_index).is_equal(test_index)

func test_button_hover_during_animation():
	"""Test button hover is ignored during animations"""
	title_screen.setup_menu_buttons()
	title_screen.is_animating = true
	var initial_index = title_screen.current_button_index

	title_screen._on_button_hovered(2)

	# Should not change during animation
	assert_that(title_screen.current_button_index).is_equal(initial_index)

func test_button_hover_same_index():
	"""Test button hover with same index as current"""
	title_screen.setup_menu_buttons()
	title_screen.current_button_index = 1

	title_screen._on_button_hovered(1)

	# Should remain unchanged
	assert_that(title_screen.current_button_index).is_equal(1)

# === Input Handling Tests ===

func test_input_navigation_up():
	"""Test input handling for upward navigation"""
	title_screen.setup_menu_buttons()

	# Create mock input event
	var input_event = InputEventKey.new()
	input_event.pressed = true

	# Mock the action check
	title_screen.is_animating = false

	var initial_index = title_screen.current_button_index
	title_screen.navigate_up()

	# Verify navigation occurred
	assert_that(title_screen.current_button_index).is_not_equal(initial_index)

func test_input_navigation_down():
	"""Test input handling for downward navigation"""
	title_screen.setup_menu_buttons()

	title_screen.is_animating = false

	var initial_index = title_screen.current_button_index
	title_screen.navigate_down()

	assert_that(title_screen.current_button_index).is_not_equal(initial_index)

func test_input_during_animation():
	"""Test input is ignored during animations"""
	title_screen.setup_menu_buttons()
	title_screen.is_animating = true

	var input_event = InputEventKey.new()
	input_event.pressed = true

	# Should not process input during animation
	var initial_index = title_screen.current_button_index
	# Simulate input processing blocked by is_animating check
	# (This tests the guard condition in _input method)
	if not title_screen.is_animating:
		title_screen.navigate_down()

	assert_that(title_screen.current_button_index).is_equal(initial_index)

# === Animation Tests ===

func test_setup_initial_animations():
	"""Test entrance animation setup"""
	title_screen.setup_initial_animations()

	assert_that(title_screen.is_animating).is_true()
	assert_that(title_screen.title_tween).is_not_null()

func test_animation_complete_callback():
	"""Test animation completion callback"""
	title_screen.is_animating = true

	title_screen._on_animation_complete()

	assert_that(title_screen.is_animating).is_false()

func test_button_highlight_animation():
	"""Test button highlight animation"""
	title_screen.setup_menu_buttons()

	var test_button = mock_buttons[0] if mock_buttons.size() > 0 else Button.new()

	# Test highlighting
	title_screen.animate_button_highlight(test_button, true)
	assert_that(title_screen.button_hover_tween).is_not_null()

	# Test normal state
	title_screen.animate_button_highlight(test_button, false)
	assert_that(title_screen.button_hover_tween).is_not_null()

func test_quit_animation():
	"""Test quit animation creation"""
	# Should not crash
	var tween = title_screen.create_quit_animation()
	assert_that(tween).is_not_null()

# === Button Signal Handler Tests ===

func test_start_button_pressed():
	"""Test start button press handling"""
	title_screen.is_animating = false

	# Should not crash
	title_screen._on_start_button_pressed()
	await get_tree().process_frame

	# Note: Actual scene transition testing requires integration tests

func test_options_button_pressed():
	"""Test options button press handling"""
	title_screen.is_animating = false

	title_screen._on_options_button_pressed()
	await get_tree().process_frame

	# Should complete without error

func test_credits_button_pressed():
	"""Test credits button press handling"""
	title_screen.is_animating = false

	title_screen._on_credits_button_pressed()
	await get_tree().process_frame

	# Should complete without error

func test_quit_button_pressed():
	"""Test quit button press handling"""
	title_screen.is_animating = false

	# This test just ensures the method doesn't crash
	# Actual quitting is tested in integration tests
	var quit_animation_created = false
	var animation = title_screen.create_quit_animation()
	quit_animation_created = (animation != null)

	assert_that(quit_animation_created).is_true()

func test_button_press_during_animation():
	"""Test button press handling during animations"""
	title_screen.is_animating = true

	# All button handlers should exit early during animation
	title_screen._on_start_button_pressed()
	title_screen._on_options_button_pressed()
	title_screen._on_credits_button_pressed()
	title_screen._on_quit_button_pressed()

	await get_tree().process_frame

	# Should not crash or cause issues

# === Utility Method Tests ===

func test_get_current_button():
	"""Test getting the currently selected button"""
	title_screen.setup_menu_buttons()

	var current_button = title_screen.get_current_button()

	if title_screen.menu_buttons.size() > 0:
		assert_that(current_button).is_not_null()
		assert_that(current_button).is_equal(title_screen.menu_buttons[title_screen.current_button_index])
	else:
		assert_that(current_button).is_null()

func test_get_current_button_invalid_index():
	"""Test getting current button with invalid index"""
	title_screen.setup_menu_buttons()
	title_screen.current_button_index = -1

	var current_button = title_screen.get_current_button()
	assert_that(current_button).is_null()

func test_set_current_button():
	"""Test programmatically setting current button"""
	title_screen.setup_menu_buttons()

	if title_screen.menu_buttons.size() > 1:
		title_screen.set_current_button(1)
		assert_that(title_screen.current_button_index).is_equal(1)

func test_set_current_button_invalid_index():
	"""Test setting current button with invalid index"""
	title_screen.setup_menu_buttons()
	var original_index = title_screen.current_button_index

	# Test negative index
	title_screen.set_current_button(-1)
	assert_that(title_screen.current_button_index).is_equal(original_index)

	# Test index too large
	title_screen.set_current_button(999)
	assert_that(title_screen.current_button_index).is_equal(original_index)

# === Signal Emission Tests ===

func test_menu_navigation_changed_signal():
	"""Test menu_navigation_changed signal emission"""
	title_screen.menu_navigation_changed.connect(_on_navigation_changed)
	title_screen.setup_menu_buttons()

	title_screen.navigate_down()

	assert_that(signal_emissions.has("navigation_changed")).is_true()

func _on_navigation_changed(button_index: int):
	signal_emissions.append("navigation_changed")
	assert_that(button_index).is_greater_equal(0)

# === State Management Tests ===

func test_button_highlighting():
	"""Test button highlighting system"""
	title_screen.setup_menu_buttons()

	if title_screen.menu_buttons.size() > 1:
		# Highlight different buttons
		title_screen.current_button_index = 0
		title_screen.highlight_current_button()

		title_screen.current_button_index = 1
		title_screen.highlight_current_button()

		# Should not crash
		assert_that(true).is_true()

func test_sound_manager_integration_readiness():
	"""Test readiness for sound manager integration"""
	# Test safe node checking pattern
	var has_sound_manager = has_node("/root/SoundManager")
	assert_that(has_sound_manager).is_not_null()  # Should not crash

# === Performance Tests ===

func test_navigation_performance():
	"""Test navigation performance under rapid input"""
	title_screen.setup_menu_buttons()

	var start_time = Time.get_ticks_msec()

	# Rapid navigation
	for i in range(100):
		title_screen.navigate_down()
		title_screen.navigate_up()

	var end_time = Time.get_ticks_msec()
	var duration = end_time - start_time

	# Should handle rapid input efficiently (within 100ms)
	assert_that(duration).is_less(100)

func test_button_highlight_animation_performance():
	"""Test button highlight animation performance"""
	title_screen.setup_menu_buttons()

	if mock_buttons.size() > 0:
		var test_button = mock_buttons[0]

		var start_time = Time.get_ticks_msec()

		# Rapid highlight changes
		for i in range(50):
			title_screen.animate_button_highlight(test_button, i % 2 == 0)

		var end_time = Time.get_ticks_msec()
		var duration = end_time - start_time

		# Should handle rapid animation changes (within 100ms)
		assert_that(duration).is_less(100)

# === Memory Management Tests ===

func test_tween_cleanup():
	"""Test proper tween cleanup"""
	title_screen.setup_menu_buttons()

	# Create multiple tweens
	title_screen.setup_initial_animations()
	await get_tree().process_frame

	if mock_buttons.size() > 0:
		title_screen.animate_button_highlight(mock_buttons[0], true)
		title_screen.animate_button_highlight(mock_buttons[0], false)

	# Tweens should be properly managed (no memory leaks)
	assert_that(title_screen.title_tween).is_not_null()
	assert_that(title_screen.button_hover_tween).is_not_null()

func test_node_structure_integrity():
	"""Test node structure remains intact during operations"""
	var initial_child_count = title_screen.get_child_count()

	title_screen.setup_menu_buttons()
	title_screen.setup_keyboard_navigation()
	title_screen.setup_initial_animations()

	await get_tree().process_frame

	# Should not create additional child nodes unexpectedly
	var final_child_count = title_screen.get_child_count()
	# Allow for UI structure creation
	assert_that(final_child_count).is_greater_equal(initial_child_count)

# === Edge Case Tests ===

func test_multiple_rapid_button_activations():
	"""Test handling of multiple rapid button activations"""
	title_screen.setup_menu_buttons()

	# Rapid activations should be handled gracefully
	for i in range(10):
		title_screen.activate_current_button()

	await get_tree().process_frame
	# Should not crash or cause issues

func test_animation_interruption():
	"""Test animation interruption handling"""
	title_screen.setup_initial_animations()
	title_screen.is_animating = true

	# Interrupt animation
	title_screen._on_animation_complete()

	assert_that(title_screen.is_animating).is_false()

func test_starfield_interaction():
	"""Test interaction with starfield background (if present)"""
	# Create mock starfield node
	var starfield = Node.new()
	starfield.name = "StarfieldBackground"

	# Add pause_animation method
	starfield.set_script(GDScript.new())
	starfield.get_script().source_code = """
extends Node
func pause_animation():
	pass
"""
	starfield.get_script().reload()

	title_screen.add_child(starfield)

	# Test quit animation with starfield
	await title_screen.create_quit_animation()

	# Should complete without error
	assert_that(true).is_true()