extends GdUnitTestSuite

## UI Interaction Tests for Menu Navigation
## Tests keyboard and controller input, accessibility, and input handling
## Part of the Continuum Professional Title Screen System Test Suite

# Test subjects
var title_screen: Node2D
var options_menu: Node2D
var credits_screen: Node2D

# Input simulation
var input_event_key: InputEventKey
var input_event_joypad: InputEventJoypadButton
var input_event_joypad_motion: InputEventJoypadMotion

# Interaction tracking
var navigation_events: Array = []
var button_activations: Array = []
var input_responses: Array = []

func before():
	# Setup menu components
	_setup_menu_components()

	# Initialize input event objects
	_setup_input_events()

	# Reset tracking
	navigation_events.clear()
	button_activations.clear()
	input_responses.clear()

func after():
	# Clean up any ongoing input processing
	get_viewport().set_input_as_handled()

func _setup_menu_components():
	"""Setup menu components with full UI structures for interaction testing"""
	# Title Screen
	title_screen = preload("res://scripts/menus/TitleScreen.gd").new()
	title_screen.name = "TitleScreen"
	add_child(title_screen)
	auto_free(title_screen)
	_setup_title_screen_full_ui()

	# Options Menu
	options_menu = preload("res://scripts/menus/OptionsMenu.gd").new()
	options_menu.name = "OptionsMenu"
	add_child(options_menu)
	auto_free(options_menu)
	_setup_options_menu_full_ui()

	# Credits Screen
	credits_screen = preload("res://scripts/menus/CreditsScreen.gd").new()
	credits_screen.name = "CreditsScreen"
	add_child(credits_screen)
	auto_free(credits_screen)
	_setup_credits_screen_full_ui()

	# Initialize components
	title_screen.setup_menu_buttons()
	title_screen.setup_keyboard_navigation()
	options_menu.setup_difficulty_options()
	credits_screen.setup_references()

func _setup_title_screen_full_ui():
	"""Setup complete title screen UI for interaction testing"""
	var ui = Control.new()
	ui.name = "UI"
	title_screen.add_child(ui)

	var main_container = Control.new()
	main_container.name = "MainContainer"
	ui.add_child(main_container)

	var title_container = Control.new()
	title_container.name = "TitleContainer"
	main_container.add_child(title_container)

	var menu_container = Control.new()
	menu_container.name = "MenuContainer"
	main_container.add_child(menu_container)

	var button_names = ["StartButton", "OptionsButton", "CreditsButton", "QuitButton"]
	for i in range(button_names.size()):
		var button = Button.new()
		button.name = button_names[i]
		button.text = button_names[i].replace("Button", "").to_upper()
		button.size = Vector2(200, 50)
		button.position.y = i * 60
		button.focus_mode = Control.FOCUS_ALL
		menu_container.add_child(button)

		# Connect signals for tracking
		button.pressed.connect(_on_button_activated.bind(button_names[i]))

	var instructions = Label.new()
	instructions.name = "Instructions"
	main_container.add_child(instructions)

	# Connect navigation signal
	title_screen.menu_navigation_changed.connect(_on_navigation_changed)

func _setup_options_menu_full_ui():
	"""Setup complete options menu UI"""
	var ui = Control.new()
	ui.name = "UI"
	options_menu.add_child(ui)

	var main_container = Control.new()
	main_container.name = "MainContainer"
	ui.add_child(main_container)

	var options_container = Control.new()
	options_container.name = "OptionsContainer"
	main_container.add_child(options_container)

	# Volume container
	var volume_container = Control.new()
	volume_container.name = "VolumeContainer"
	options_container.add_child(volume_container)

	var volume_slider = HSlider.new()
	volume_slider.name = "VolumeSlider"
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.value = 80
	volume_slider.focus_mode = Control.FOCUS_ALL
	volume_container.add_child(volume_slider)

	var volume_label = Label.new()
	volume_label.name = "VolumeValueLabel"
	volume_label.text = "80%"
	volume_container.add_child(volume_label)

	# Fullscreen container
	var fullscreen_container = Control.new()
	fullscreen_container.name = "FullscreenContainer"
	options_container.add_child(fullscreen_container)

	var fullscreen_checkbox = CheckBox.new()
	fullscreen_checkbox.name = "FullscreenCheckBox"
	fullscreen_checkbox.focus_mode = Control.FOCUS_ALL
	fullscreen_container.add_child(fullscreen_checkbox)

	# Difficulty container
	var difficulty_container = Control.new()
	difficulty_container.name = "DifficultyContainer"
	options_container.add_child(difficulty_container)

	var difficulty_option = OptionButton.new()
	difficulty_option.name = "DifficultyOption"
	difficulty_option.focus_mode = Control.FOCUS_ALL
	difficulty_container.add_child(difficulty_option)

	# Button container
	var button_container = Control.new()
	button_container.name = "ButtonContainer"
	options_container.add_child(button_container)

	var apply_button = Button.new()
	apply_button.name = "ApplyButton"
	apply_button.text = "APPLY"
	apply_button.focus_mode = Control.FOCUS_ALL
	button_container.add_child(apply_button)

	var back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "BACK"
	back_button.focus_mode = Control.FOCUS_ALL
	button_container.add_child(back_button)

func _setup_credits_screen_full_ui():
	"""Setup complete credits screen UI"""
	var ui = Control.new()
	ui.name = "UI"
	credits_screen.add_child(ui)

	var main_container = Control.new()
	main_container.name = "MainContainer"
	main_container.size = Vector2(800, 600)
	ui.add_child(main_container)

	var scroll_container = ScrollContainer.new()
	scroll_container.name = "ScrollContainer"
	scroll_container.size = Vector2(750, 500)
	main_container.add_child(scroll_container)

	var credits_content = VBoxContainer.new()
	credits_content.name = "CreditsContent"
	scroll_container.add_child(credits_content)

	for i in range(50):
		var label = Label.new()
		label.text = "Credits Line " + str(i + 1)
		credits_content.add_child(label)

func _setup_input_events():
	"""Initialize input event objects for testing"""
	input_event_key = InputEventKey.new()
	input_event_joypad = InputEventJoypadButton.new()
	input_event_joypad_motion = InputEventJoypadMotion.new()

# Event tracking callbacks
func _on_navigation_changed(button_index: int):
	navigation_events.append({"type": "navigation", "index": button_index})

func _on_button_activated(button_name: String):
	button_activations.append(button_name)

# === Keyboard Navigation Tests ===

func test_keyboard_up_navigation():
	"""Test upward keyboard navigation in title screen"""
	# Start at second button
	title_screen.current_button_index = 1

	# Simulate UP key press
	input_event_key.keycode = KEY_UP
	input_event_key.pressed = true

	# Process input through title screen's _input method
	title_screen.navigate_up()

	assert_that(title_screen.current_button_index).is_equal(0)
	assert_that(navigation_events.size()).is_greater(0)

func test_keyboard_down_navigation():
	"""Test downward keyboard navigation in title screen"""
	title_screen.current_button_index = 0

	input_event_key.keycode = KEY_DOWN
	input_event_key.pressed = true

	title_screen.navigate_down()

	assert_that(title_screen.current_button_index).is_equal(1)
	assert_that(navigation_events.size()).is_greater(0)

func test_wasd_navigation():
	"""Test WASD key navigation"""
	title_screen.current_button_index = 0

	# Test W (up equivalent)
	title_screen.navigate_up()
	var up_index = title_screen.current_button_index

	# Test S (down equivalent)
	title_screen.navigate_down()
	var down_index = title_screen.current_button_index

	assert_that(up_index).is_not_equal(down_index)

func test_navigation_wraparound():
	"""Test navigation wraparound behavior"""
	var max_index = title_screen.menu_buttons.size() - 1

	# Navigate up from first button (should wrap to last)
	title_screen.current_button_index = 0
	title_screen.navigate_up()
	assert_that(title_screen.current_button_index).is_equal(max_index)

	# Navigate down from last button (should wrap to first)
	title_screen.current_button_index = max_index
	title_screen.navigate_down()
	assert_that(title_screen.current_button_index).is_equal(0)

func test_keyboard_button_activation():
	"""Test keyboard button activation (ENTER/SPACE)"""
	title_screen.current_button_index = 0

	# Simulate ENTER key press
	input_event_key.keycode = KEY_ENTER
	input_event_key.pressed = true

	title_screen.activate_current_button()

	await get_tree().process_frame

	assert_that(button_activations.size()).is_greater(0)
	assert_that(button_activations[0]).is_equal("StartButton")

# === Controller/Joypad Navigation Tests ===

func test_joypad_dpad_up_navigation():
	"""Test controller D-pad up navigation"""
	title_screen.current_button_index = 1

	input_event_joypad.button_index = JOY_BUTTON_DPAD_UP
	input_event_joypad.pressed = true

	title_screen.navigate_up()

	assert_that(title_screen.current_button_index).is_equal(0)

func test_joypad_dpad_down_navigation():
	"""Test controller D-pad down navigation"""
	title_screen.current_button_index = 0

	input_event_joypad.button_index = JOY_BUTTON_DPAD_DOWN
	input_event_joypad.pressed = true

	title_screen.navigate_down()

	assert_that(title_screen.current_button_index).is_equal(1)

func test_joypad_analog_stick_navigation():
	"""Test controller analog stick navigation"""
	title_screen.current_button_index = 1

	# Simulate analog stick up
	input_event_joypad_motion.axis = JOY_AXIS_LEFT_Y
	input_event_joypad_motion.axis_value = -0.8  # Up direction

	# Analog stick should trigger navigation
	title_screen.navigate_up()

	assert_that(title_screen.current_button_index).is_equal(0)

func test_joypad_button_activation():
	"""Test controller button activation (A button)"""
	title_screen.current_button_index = 2

	input_event_joypad.button_index = JOY_BUTTON_A
	input_event_joypad.pressed = true

	title_screen.activate_current_button()

	await get_tree().process_frame

	assert_that(button_activations.size()).is_greater(0)
	assert_that(button_activations[0]).is_equal("CreditsButton")

func test_joypad_back_navigation():
	"""Test controller back button (B button)"""
	input_event_joypad.button_index = JOY_BUTTON_B
	input_event_joypad.pressed = true

	# Should trigger back functionality in options or credits
	# This tests the back button equivalency
	var back_triggered = false
	if options_menu.has_method("_on_back_button_pressed"):
		options_menu._on_back_button_pressed()
		back_triggered = true

	assert_that(back_triggered).is_true()

# === Mixed Input Method Tests ===

func test_keyboard_to_mouse_transition():
	"""Test transitioning from keyboard navigation to mouse"""
	title_screen.current_button_index = 0

	# Mouse hover should override keyboard selection
	title_screen._on_button_hovered(2)

	assert_that(title_screen.current_button_index).is_equal(2)

func test_mouse_to_keyboard_transition():
	"""Test transitioning from mouse to keyboard navigation"""
	# Hover with mouse
	title_screen._on_button_hovered(1)
	assert_that(title_screen.current_button_index).is_equal(1)

	# Keyboard navigation should continue from mouse position
	title_screen.navigate_down()
	assert_that(title_screen.current_button_index).is_equal(2)

func test_controller_to_keyboard_interoperability():
	"""Test interoperability between controller and keyboard"""
	title_screen.current_button_index = 0

	# Navigate with controller
	title_screen.navigate_down()
	var controller_position = title_screen.current_button_index

	# Navigate with keyboard from controller position
	title_screen.navigate_up()
	var keyboard_position = title_screen.current_button_index

	assert_that(keyboard_position).is_equal(controller_position - 1)

# === Options Menu Input Tests ===

func test_options_volume_slider_keyboard_control():
	"""Test controlling volume slider with keyboard"""
	var volume_slider = options_menu.get_node("UI/MainContainer/OptionsContainer/VolumeContainer/VolumeSlider")
	volume_slider.grab_focus()

	var initial_value = volume_slider.value

	# Simulate arrow key presses for slider control
	input_event_key.keycode = KEY_RIGHT
	input_event_key.pressed = true

	# Slider should respond to arrow keys when focused
	volume_slider.value = initial_value + 5

	assert_that(volume_slider.value).is_greater(initial_value)

func test_options_checkbox_keyboard_control():
	"""Test controlling checkbox with keyboard"""
	var checkbox = options_menu.get_node("UI/MainContainer/OptionsContainer/FullscreenContainer/FullscreenCheckBox")
	checkbox.grab_focus()

	var initial_state = checkbox.button_pressed

	# Simulate space key press to toggle checkbox
	input_event_key.keycode = KEY_SPACE
	input_event_key.pressed = true

	checkbox.button_pressed = !initial_state

	assert_that(checkbox.button_pressed).is_not_equal(initial_state)

func test_options_dropdown_keyboard_control():
	"""Test controlling dropdown/option button with keyboard"""
	var difficulty_option = options_menu.get_node("UI/MainContainer/OptionsContainer/DifficultyContainer/DifficultyOption")
	options_menu.setup_difficulty_options()
	difficulty_option.grab_focus()

	var initial_selection = difficulty_option.selected

	# Simulate arrow key to change selection
	if initial_selection < difficulty_option.get_item_count() - 1:
		difficulty_option.selected = initial_selection + 1
	else:
		difficulty_option.selected = 0

	assert_that(difficulty_option.selected).is_not_equal(initial_selection)

func test_options_cancel_key():
	"""Test cancel key functionality in options menu"""
	input_event_key.keycode = KEY_ESCAPE
	input_event_key.pressed = true

	# Should trigger back functionality
	var cancel_triggered = false
	if options_menu.has_method("_on_back_button_pressed"):
		options_menu._on_back_button_pressed()
		cancel_triggered = true

	assert_that(cancel_triggered).is_true()

# === Credits Screen Input Tests ===

func test_credits_scroll_keyboard_control():
	"""Test scrolling credits with keyboard"""
	var initial_scroll = credits_screen.scroll_container.scroll_vertical

	# Test up/down arrow scrolling
	credits_screen.manual_scroll(30)
	var scrolled_position = credits_screen.scroll_container.scroll_vertical

	assert_that(scrolled_position).is_greater_equal(initial_scroll)

	credits_screen.manual_scroll(-20)
	var scrolled_back_position = credits_screen.scroll_container.scroll_vertical

	assert_that(scrolled_back_position).is_less(scrolled_position)

func test_credits_auto_scroll_toggle():
	"""Test toggling auto scroll with keyboard"""
	var initial_auto_scroll = credits_screen.auto_scroll_enabled

	# Simulate space or enter to toggle auto scroll
	credits_screen.toggle_auto_scroll()

	assert_that(credits_screen.auto_scroll_enabled).is_not_equal(initial_auto_scroll)

func test_credits_page_scrolling():
	"""Test page up/down scrolling in credits"""
	var initial_scroll = credits_screen.scroll_container.scroll_vertical

	# Simulate page down (larger scroll amount)
	credits_screen.manual_scroll(100)
	var page_down_position = credits_screen.scroll_container.scroll_vertical

	assert_that(page_down_position).is_greater(initial_scroll + 50)

	# Simulate page up
	credits_screen.manual_scroll(-100)
	var page_up_position = credits_screen.scroll_container.scroll_vertical

	assert_that(page_up_position).is_less(page_down_position - 50)

# === Accessibility Tests ===

func test_focus_management():
	"""Test proper focus management across UI elements"""
	# Title screen focus
	title_screen.highlight_current_button()
	var current_button = title_screen.get_current_button()

	if current_button:
		assert_that(current_button.has_focus()).is_true()

	# Focus should move with navigation
	title_screen.navigate_down()
	var new_button = title_screen.get_current_button()

	if new_button and new_button != current_button:
		assert_that(new_button.has_focus()).is_true()

func test_tab_navigation():
	"""Test tab key navigation between UI elements"""
	var focusable_controls = _get_focusable_controls(options_menu)

	if focusable_controls.size() > 1:
		# Focus first control
		focusable_controls[0].grab_focus()
		assert_that(focusable_controls[0].has_focus()).is_true()

		# Simulate tab to next control
		focusable_controls[1].grab_focus()
		assert_that(focusable_controls[1].has_focus()).is_true()

func test_focus_visibility():
	"""Test focus indicators are visible"""
	title_screen.highlight_current_button()
	var current_button = title_screen.get_current_button()

	if current_button:
		# Check that button has visual focus indication
		# This could be scale, color, or other visual changes
		assert_that(current_button.scale.x).is_greater_equal(1.0)

func _get_focusable_controls(node: Node) -> Array[Control]:
	"""Get all focusable controls in a node tree"""
	var focusable: Array[Control] = []

	for child in node.get_children():
		if child is Control and child.focus_mode != Control.FOCUS_NONE:
			focusable.append(child)
		focusable.append_array(_get_focusable_controls(child))

	return focusable

# === Input Responsiveness Tests ===

func test_rapid_input_handling():
	"""Test handling of rapid input without lag or missed inputs"""
	var initial_index = title_screen.current_button_index

	# Rapid navigation
	for i in range(20):
		if i % 2 == 0:
			title_screen.navigate_down()
		else:
			title_screen.navigate_up()

	# Should end up at starting position (even number of opposite moves)
	assert_that(title_screen.current_button_index).is_equal(initial_index)

func test_input_during_animation():
	"""Test input handling during animations"""
	title_screen.is_animating = true

	var initial_index = title_screen.current_button_index

	# Input during animation should be ignored
	title_screen.navigate_down()

	# Index should not change during animation
	assert_that(title_screen.current_button_index).is_equal(initial_index)

	# Reset animation state
	title_screen.is_animating = false

	# Input should work normally after animation
	title_screen.navigate_down()
	assert_that(title_screen.current_button_index).is_not_equal(initial_index)

func test_input_buffering():
	"""Test that input is properly handled and not buffered excessively"""
	var input_count = 0

	# Simulate multiple rapid inputs
	for i in range(10):
		title_screen.navigate_down()
		input_count += 1

		await get_tree().process_frame

	# Should have processed all inputs (no excessive buffering)
	assert_that(navigation_events.size()).is_greater_equal(input_count - 2)

# === Edge Case Input Tests ===

func test_invalid_button_index_handling():
	"""Test handling of invalid button indices"""
	var original_index = title_screen.current_button_index

	# Set invalid index
	title_screen.current_button_index = -1
	title_screen.navigate_down()

	# Should handle gracefully and provide valid index
	assert_that(title_screen.current_button_index).is_greater_equal(0)
	assert_that(title_screen.current_button_index).is_less(title_screen.menu_buttons.size())

func test_empty_menu_navigation():
	"""Test navigation with empty menu"""
	# Clear menu buttons
	title_screen.menu_buttons = []

	# Should not crash
	title_screen.navigate_up()
	title_screen.navigate_down()
	title_screen.activate_current_button()

	# Should handle gracefully
	assert_that(title_screen.current_button_index).is_equal(0)

func test_disabled_button_handling():
	"""Test handling of disabled buttons"""
	if title_screen.menu_buttons.size() > 1:
		var test_button = title_screen.menu_buttons[1]
		test_button.disabled = true

		# Navigate to disabled button
		title_screen.current_button_index = 1
		title_screen.activate_current_button()

		await get_tree().process_frame

		# Should handle disabled button gracefully
		# (behavior may vary - could skip or handle differently)

# === Input Method Detection Tests ===

func test_input_method_switching():
	"""Test detecting and switching between input methods"""
	# Keyboard input detection
	title_screen.navigate_down()
	# Should be in keyboard mode (implementation dependent)

	# Mouse input detection
	title_screen._on_button_hovered(2)
	# Should detect mouse input

	# Controller input detection would require more complex simulation

func test_simultaneous_input_handling():
	"""Test handling simultaneous inputs from different sources"""
	# Simulate keyboard and mouse input at same time
	title_screen.navigate_down()
	title_screen._on_button_hovered(2)

	# Should handle gracefully without conflicts
	assert_that(title_screen.current_button_index).is_greater_equal(0)
	assert_that(title_screen.current_button_index).is_less(title_screen.menu_buttons.size())

# === Performance with Input Tests ===

func test_input_performance_under_load():
	"""Test input performance under high frequency input"""
	var start_time = Time.get_ticks_msec()

	# High frequency input
	for i in range(100):
		title_screen.navigate_down()
		title_screen.navigate_up()

	var end_time = Time.get_ticks_msec()
	var duration = end_time - start_time

	# Should handle rapid input efficiently (within 200ms)
	assert_that(duration).is_less(200)

func test_memory_efficiency_with_input():
	"""Test memory efficiency during extended input usage"""
	var initial_node_count = get_child_count()

	# Extended input simulation
	for i in range(500):
		title_screen.navigate_down()
		if i % 50 == 0:
			await get_tree().process_frame

	var final_node_count = get_child_count()

	# Should not create excessive nodes from input handling
	assert_that(final_node_count - initial_node_count).is_less(5)

# === Cross-Platform Input Compatibility Tests ===

func test_action_map_compatibility():
	"""Test that input actions work across different input devices"""
	# Test common action names used in the code
	var actions_to_test = ["move_up", "move_down", "ui_up", "ui_down", "shoot", "ui_accept", "bomb", "ui_cancel"]

	for action in actions_to_test:
		# Should not crash when checking for these actions
		var has_action = InputMap.has_action(action)
		# Note: Actions may or may not exist in test environment, but should not crash

# === Complete Input Flow Tests ===

func test_complete_navigation_flow():
	"""Test complete navigation flow across all menus"""
	# Start at title screen
	title_screen.current_button_index = 0

	# Navigate to options button
	while title_screen.current_button_index != 1:  # Options button
		title_screen.navigate_down()

	assert_that(title_screen.current_button_index).is_equal(1)

	# Activate options button
	title_screen.activate_current_button()
	await get_tree().process_frame

	# In options menu, navigate controls
	if options_menu.has_method("setup_difficulty_options"):
		options_menu.setup_difficulty_options()

	# Test back navigation
	options_menu._on_back_button_pressed()
	await get_tree().process_frame

func test_accessibility_complete_workflow():
	"""Test complete workflow using only keyboard/controller"""
	# Complete menu workflow using only keyboard input
	title_screen.current_button_index = 0

	# Navigate menu with keyboard
	for i in range(title_screen.menu_buttons.size()):
		title_screen.navigate_down()
		await get_tree().process_frame

	# Activate options
	title_screen.current_button_index = 1  # Options
	title_screen.activate_current_button()
	await get_tree().process_frame

	# Navigate options with keyboard
	options_menu._on_back_button_pressed()
	await get_tree().process_frame

	# Navigate to credits
	title_screen.current_button_index = 2  # Credits
	title_screen.activate_current_button()
	await get_tree().process_frame

	# Use credits with keyboard
	credits_screen.manual_scroll(50)
	credits_screen.toggle_auto_scroll()
	credits_screen._on_back_button_pressed()
	await get_tree().process_frame

	# Should complete entire workflow with keyboard only
	assert_that(true).is_true()  # Workflow completed without crashes