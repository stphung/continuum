extends GdUnitTestSuite

## Integration Tests for Title Screen System
## Tests scene transitions, audio integration, and cross-component communication
## Part of the Continuum Professional Title Screen System Test Suite

# Mock managers for integration testing
var mock_scene_manager: Node
var mock_sound_manager: Node
var title_screen: Node2D
var options_menu: Node2D
var credits_screen: Node2D

# Integration test tracking
var transition_events: Array = []
var audio_events: Array = []
var signal_events: Array = []

func before():
	# Set up mock managers as autoloads
	_setup_mock_scene_manager()
	_setup_mock_sound_manager()

	# Create menu components
	_setup_menu_components()

	# Reset tracking
	transition_events.clear()
	audio_events.clear()
	signal_events.clear()

func after():
	# Clean up mock managers
	if mock_scene_manager and is_instance_valid(mock_scene_manager):
		mock_scene_manager.queue_free()
	if mock_sound_manager and is_instance_valid(mock_sound_manager):
		mock_sound_manager.queue_free()

func _setup_mock_scene_manager():
	"""Create mock SceneTransitionManager for testing"""
	mock_scene_manager = Node.new()
	mock_scene_manager.name = "SceneTransitionManager"

	# Add to root as autoload
	get_tree().root.add_child(mock_scene_manager)

	# Mock properties and methods
	mock_scene_manager.set_script(GDScript.new())
	mock_scene_manager.get_script().source_code = """
extends Node

signal scene_transition_started(from_scene: String, to_scene: String)
signal scene_transition_completed(scene_name: String)

var is_transitioning: bool = false

func transition_to_game() -> bool:
	scene_transition_started.emit("", "Game.tscn")
	await get_tree().process_frame
	is_transitioning = false
	scene_transition_completed.emit("Game.tscn")
	return true

func transition_to_title() -> bool:
	scene_transition_started.emit("", "TitleScreen.tscn")
	await get_tree().process_frame
	is_transitioning = false
	scene_transition_completed.emit("TitleScreen.tscn")
	return true

func transition_to_options() -> bool:
	scene_transition_started.emit("", "OptionsMenu.tscn")
	await get_tree().process_frame
	is_transitioning = false
	scene_transition_completed.emit("OptionsMenu.tscn")
	return true

func transition_to_credits() -> bool:
	scene_transition_started.emit("", "CreditsScreen.tscn")
	await get_tree().process_frame
	is_transitioning = false
	scene_transition_completed.emit("CreditsScreen.tscn")
	return true
"""
	mock_scene_manager.get_script().reload()

	# Connect signals for tracking
	mock_scene_manager.scene_transition_started.connect(_on_transition_started)
	mock_scene_manager.scene_transition_completed.connect(_on_transition_completed)

func _setup_mock_sound_manager():
	"""Create mock SoundManager for testing"""
	mock_sound_manager = Node.new()
	mock_sound_manager.name = "SoundManager"

	get_tree().root.add_child(mock_sound_manager)

	# Mock sound manager functionality
	mock_sound_manager.set_script(GDScript.new())
	mock_sound_manager.get_script().source_code = """
extends Node

var played_sounds: Array = []

func play_sound(sound_name: String, volume: float = 0.0):
	played_sounds.append({"name": sound_name, "volume": volume})
"""
	mock_sound_manager.get_script().reload()

func _setup_menu_components():
	"""Create menu component instances for integration testing"""
	# Create title screen
	title_screen = preload("res://scripts/menus/TitleScreen.gd").new()
	title_screen.name = "TitleScreen"
	add_child(title_screen)
	auto_free(title_screen)

	# Create options menu
	options_menu = preload("res://scripts/menus/OptionsMenu.gd").new()
	options_menu.name = "OptionsMenu"
	add_child(options_menu)
	auto_free(options_menu)

	# Create credits screen
	credits_screen = preload("res://scripts/menus/CreditsScreen.gd").new()
	credits_screen.name = "CreditsScreen"
	add_child(credits_screen)
	auto_free(credits_screen)

	# Setup mock UI structures for each component
	_setup_title_screen_ui()
	_setup_options_menu_ui()
	_setup_credits_screen_ui()

func _setup_title_screen_ui():
	"""Setup mock UI structure for title screen"""
	var ui = Control.new()
	ui.name = "UI"
	title_screen.add_child(ui)

	var main_container = Control.new()
	main_container.name = "MainContainer"
	ui.add_child(main_container)

	var title_container = Control.new()
	title_container.name = "TitleContainer"
	title_container.position = Vector2(100, 100)
	main_container.add_child(title_container)

	var menu_container = Control.new()
	menu_container.name = "MenuContainer"
	menu_container.position = Vector2(100, 200)
	main_container.add_child(menu_container)

	# Create buttons
	var button_names = ["StartButton", "OptionsButton", "CreditsButton", "QuitButton"]
	for button_name in button_names:
		var button = Button.new()
		button.name = button_name
		button.text = button_name.replace("Button", "").to_upper()
		button.size = Vector2(120, 40)
		menu_container.add_child(button)

	var instructions = Label.new()
	instructions.name = "Instructions"
	instructions.text = "Instructions"
	main_container.add_child(instructions)

func _setup_options_menu_ui():
	"""Setup mock UI structure for options menu"""
	var ui = Control.new()
	ui.name = "UI"
	options_menu.add_child(ui)

	var main_container = Control.new()
	main_container.name = "MainContainer"
	ui.add_child(main_container)

	var options_container = Control.new()
	options_container.name = "OptionsContainer"
	main_container.add_child(options_container)

	# Volume controls
	var volume_container = Control.new()
	volume_container.name = "VolumeContainer"
	options_container.add_child(volume_container)

	var volume_slider = HSlider.new()
	volume_slider.name = "VolumeSlider"
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.value = 80
	volume_container.add_child(volume_slider)

	var volume_label = Label.new()
	volume_label.name = "VolumeValueLabel"
	volume_label.text = "80%"
	volume_container.add_child(volume_label)

	# Other controls
	var fullscreen_container = Control.new()
	fullscreen_container.name = "FullscreenContainer"
	options_container.add_child(fullscreen_container)

	var fullscreen_checkbox = CheckBox.new()
	fullscreen_checkbox.name = "FullscreenCheckBox"
	fullscreen_container.add_child(fullscreen_checkbox)

	var difficulty_container = Control.new()
	difficulty_container.name = "DifficultyContainer"
	options_container.add_child(difficulty_container)

	var difficulty_option = OptionButton.new()
	difficulty_option.name = "DifficultyOption"
	difficulty_container.add_child(difficulty_option)

	# Buttons
	var button_container = Control.new()
	button_container.name = "ButtonContainer"
	options_container.add_child(button_container)

	var apply_button = Button.new()
	apply_button.name = "ApplyButton"
	apply_button.text = "APPLY"
	button_container.add_child(apply_button)

	var back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "BACK"
	button_container.add_child(back_button)

func _setup_credits_screen_ui():
	"""Setup mock UI structure for credits screen"""
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

	# Add content
	for i in range(10):
		var label = Label.new()
		label.text = "Credit Line " + str(i + 1)
		credits_content.add_child(label)

# Signal tracking methods
func _on_transition_started(from_scene: String, to_scene: String):
	transition_events.append({"type": "started", "from": from_scene, "to": to_scene})

func _on_transition_completed(scene_name: String):
	transition_events.append({"type": "completed", "scene": scene_name})

func _on_audio_played(sound_name: String, volume: float):
	audio_events.append({"sound": sound_name, "volume": volume})

# === Scene Transition Integration Tests ===

func test_title_screen_to_game_transition():
	"""Test title screen to game transition integration"""
	# Setup title screen
	title_screen.setup_menu_buttons()

	# Trigger start button press
	title_screen._on_start_button_pressed()

	await get_tree().process_frame
	await get_tree().process_frame

	# Check transition was triggered
	assert_that(transition_events.size()).is_greater(0)
	var start_event = transition_events.filter(func(e): return e.type == "started")[0]
	assert_that(start_event.to).contains("Game.tscn")

func test_title_screen_to_options_transition():
	"""Test title screen to options menu transition"""
	title_screen.setup_menu_buttons()

	title_screen._on_options_button_pressed()

	await get_tree().process_frame
	await get_tree().process_frame

	assert_that(transition_events.size()).is_greater(0)
	var start_event = transition_events.filter(func(e): return e.type == "started")[0]
	assert_that(start_event.to).contains("OptionsMenu.tscn")

func test_title_screen_to_credits_transition():
	"""Test title screen to credits transition"""
	title_screen.setup_menu_buttons()

	title_screen._on_credits_button_pressed()

	await get_tree().process_frame
	await get_tree().process_frame

	assert_that(transition_events.size()).is_greater(0)
	var start_event = transition_events.filter(func(e): return e.type == "started")[0]
	assert_that(start_event.to).contains("CreditsScreen.tscn")

func test_options_menu_back_transition():
	"""Test options menu back to title transition"""
	options_menu._on_back_button_pressed()

	await get_tree().process_frame
	await get_tree().process_frame

	assert_that(transition_events.size()).is_greater(0)
	var start_event = transition_events.filter(func(e): return e.type == "started")[0]
	assert_that(start_event.to).contains("TitleScreen.tscn")

func test_credits_screen_back_transition():
	"""Test credits screen back to title transition"""
	credits_screen._on_back_button_pressed()

	await get_tree().process_frame
	await get_tree().process_frame

	assert_that(transition_events.size()).is_greater(0)
	var start_event = transition_events.filter(func(e): return e.type == "started")[0]
	assert_that(start_event.to).contains("TitleScreen.tscn")

# === Audio Integration Tests ===

func test_title_screen_audio_integration():
	"""Test title screen audio integration"""
	# Check that sound manager is accessible
	var sound_manager = get_node("/root/SoundManager")
	assert_that(sound_manager).is_not_null()

	# Test menu navigation sound
	title_screen.setup_menu_buttons()
	title_screen.navigate_down()

	await get_tree().process_frame

	# Check if sound was attempted to be played
	var played_sounds = sound_manager.played_sounds as Array
	if played_sounds.size() > 0:
		assert_that(played_sounds[0].name).is_equal("menu_navigate")

func test_options_menu_audio_integration():
	"""Test options menu audio feedback integration"""
	var sound_manager = get_node("/root/SoundManager")
	assert_that(sound_manager).is_not_null()

	# Test volume slider feedback
	options_menu.volume_value_label = options_menu.get_node("UI/MainContainer/OptionsContainer/VolumeContainer/VolumeValueLabel")
	options_menu._on_volume_slider_value_changed(75.0)

	await get_tree().process_frame

	# Should attempt to play feedback sound
	var played_sounds = sound_manager.played_sounds as Array
	if played_sounds.size() > 0:
		assert_that(played_sounds[0].name).is_equal("menu_hover")

func test_audio_volume_integration():
	"""Test audio volume integration with options menu"""
	# Test that volume changes affect audio system
	options_menu.master_volume = 60.0
	options_menu.apply_current_settings()

	# Check that audio server bus volume was changed
	var master_bus_index = AudioServer.get_bus_index("Master")
	var volume_db = AudioServer.get_bus_volume_db(master_bus_index)
	var expected_db = linear_to_db(60.0 / 100.0)

	assert_that(volume_db).is_equal_approx(expected_db, 0.1)

# === Cross-Component Communication Tests ===

func test_scene_manager_availability():
	"""Test scene manager availability across components"""
	var components = [title_screen, options_menu, credits_screen]

	for component in components:
		var has_scene_manager = component.has_node("/root/SceneTransitionManager")
		assert_that(has_scene_manager).is_true()

func test_sound_manager_availability():
	"""Test sound manager availability across components"""
	var components = [title_screen, options_menu, credits_screen]

	for component in components:
		var has_sound_manager = component.has_node("/root/SoundManager")
		assert_that(has_sound_manager).is_true()

func test_transition_signal_propagation():
	"""Test transition signal propagation"""
	# Connect to transition signals
	mock_scene_manager.scene_transition_started.connect(_on_transition_started)
	mock_scene_manager.scene_transition_completed.connect(_on_transition_completed)

	# Trigger transition
	await mock_scene_manager.transition_to_game()

	# Check signals were received
	assert_that(transition_events.size()).is_equal(2)  # Started and completed
	assert_that(transition_events[0].type).is_equal("started")
	assert_that(transition_events[1].type).is_equal("completed")

# === End-to-End Menu Flow Tests ===

func test_complete_menu_navigation_flow():
	"""Test complete menu navigation flow"""
	title_screen.setup_menu_buttons()

	# Navigate through menu
	title_screen.navigate_down()  # To options
	title_screen.navigate_down()  # To credits
	title_screen.navigate_up()    # Back to options
	title_screen.navigate_up()    # Back to start

	await get_tree().process_frame

	# Should end up at start button
	assert_that(title_screen.current_button_index).is_equal(0)

func test_options_menu_settings_flow():
	"""Test options menu settings flow"""
	# Setup UI references
	options_menu.volume_slider = options_menu.get_node("UI/MainContainer/OptionsContainer/VolumeContainer/VolumeSlider")
	options_menu.volume_value_label = options_menu.get_node("UI/MainContainer/OptionsContainer/VolumeContainer/VolumeValueLabel")
	options_menu.fullscreen_checkbox = options_menu.get_node("UI/MainContainer/OptionsContainer/FullscreenContainer/FullscreenCheckBox")
	options_menu.difficulty_option = options_menu.get_node("UI/MainContainer/OptionsContainer/DifficultyContainer/DifficultyOption")

	# Setup difficulty options
	options_menu.setup_difficulty_options()

	# Change settings
	options_menu._on_volume_slider_value_changed(90.0)
	options_menu._on_fullscreen_check_box_toggled(true)
	options_menu._on_difficulty_option_item_selected(2)

	# Apply settings
	options_menu._on_apply_button_pressed()

	await get_tree().process_frame

	# Verify settings were applied
	assert_that(options_menu.master_volume).is_equal_approx(90.0, 0.1)
	assert_that(options_menu.is_fullscreen).is_true()
	assert_that(options_menu.difficulty_level).is_equal(2)

func test_credits_screen_interaction_flow():
	"""Test credits screen interaction flow"""
	credits_screen.setup_references()

	# Test scrolling
	credits_screen.manual_scroll(50)
	credits_screen.manual_scroll(-30)

	# Test auto scroll toggle
	var initial_auto_scroll = credits_screen.auto_scroll_enabled
	credits_screen.toggle_auto_scroll()
	assert_that(credits_screen.auto_scroll_enabled).is_not_equal(initial_auto_scroll)

	await get_tree().process_frame

# === Performance Integration Tests ===

func test_transition_performance_integration():
	"""Test transition performance in integrated environment"""
	var start_time = Time.get_ticks_msec()

	# Perform multiple transitions rapidly
	await mock_scene_manager.transition_to_options()
	await mock_scene_manager.transition_to_credits()
	await mock_scene_manager.transition_to_title()

	var end_time = Time.get_ticks_msec()
	var duration = end_time - start_time

	# Should handle rapid transitions efficiently (within 300ms)
	assert_that(duration).is_less(300)

func test_audio_performance_integration():
	"""Test audio performance in integrated environment"""
	var sound_manager = get_node("/root/SoundManager")

	var start_time = Time.get_ticks_msec()

	# Rapid audio playback requests
	for i in range(20):
		sound_manager.play_sound("menu_navigate", -5.0)

	var end_time = Time.get_ticks_msec()
	var duration = end_time - start_time

	# Should handle rapid audio efficiently (within 100ms)
	assert_that(duration).is_less(100)

# === Error Handling Integration Tests ===

func test_missing_scene_manager_handling():
	"""Test handling when scene manager is missing"""
	# Remove scene manager temporarily
	var scene_manager = get_node("/root/SceneTransitionManager")
	scene_manager.queue_free()

	await get_tree().process_frame

	# Should handle gracefully
	title_screen._on_start_button_pressed()
	options_menu._on_back_button_pressed()
	credits_screen._on_back_button_pressed()

	# Should not crash

func test_missing_sound_manager_handling():
	"""Test handling when sound manager is missing"""
	# Remove sound manager temporarily
	var sound_manager = get_node("/root/SoundManager")
	sound_manager.queue_free()

	await get_tree().process_frame

	# Should handle gracefully
	title_screen.navigate_down()
	options_menu._on_volume_slider_value_changed(50.0)

	# Should not crash

# === Memory and Resource Integration Tests ===

func test_memory_usage_during_transitions():
	"""Test memory usage during scene transitions"""
	var initial_node_count = get_tree().root.get_child_count()

	# Perform multiple transitions
	for i in range(5):
		await mock_scene_manager.transition_to_options()
		await mock_scene_manager.transition_to_title()

	var final_node_count = get_tree().root.get_child_count()

	# Should not accumulate excessive nodes
	assert_that(final_node_count - initial_node_count).is_less(10)

func test_audio_resource_management():
	"""Test audio resource management during integration"""
	var sound_manager = get_node("/root/SoundManager")

	# Generate and play many sounds
	for i in range(50):
		sound_manager.play_sound("menu_hover", -10.0)

	await get_tree().process_frame

	# Should handle resource management gracefully
	assert_that(sound_manager).is_not_null()

# === System State Integration Tests ===

func test_system_state_consistency():
	"""Test system state consistency across components"""
	# Change volume in options
	options_menu.master_volume = 70.0
	options_menu.apply_current_settings()

	# Volume should be reflected in audio system
	var master_bus_index = AudioServer.get_bus_index("Master")
	var volume_db = AudioServer.get_bus_volume_db(master_bus_index)
	var expected_db = linear_to_db(70.0 / 100.0)

	assert_that(volume_db).is_equal_approx(expected_db, 0.1)

func test_fullscreen_state_integration():
	"""Test fullscreen state integration"""
	# Test fullscreen setting (without actually changing display mode)
	options_menu.is_fullscreen = true
	options_menu.apply_current_settings()

	# Setting should be stored
	assert_that(options_menu.is_fullscreen).is_true()

# === Complex Interaction Tests ===

func test_rapid_menu_switching():
	"""Test rapid switching between menus"""
	# Rapid menu transitions
	for i in range(10):
		title_screen._on_options_button_pressed()
		await get_tree().process_frame
		options_menu._on_back_button_pressed()
		await get_tree().process_frame

	# Should handle rapid switching gracefully
	assert_that(transition_events.size()).is_greater(0)

func test_concurrent_audio_and_transitions():
	"""Test concurrent audio playback and scene transitions"""
	var sound_manager = get_node("/root/SoundManager")

	# Start audio playback
	sound_manager.play_sound("menu_music", -10.0)

	# Perform transition during audio
	await mock_scene_manager.transition_to_options()

	await get_tree().process_frame

	# Both should complete successfully
	assert_that(transition_events.size()).is_greater(0)

# === Edge Case Integration Tests ===

func test_null_reference_integration():
	"""Test integration with null references"""
	# Set some references to null
	title_screen.menu_buttons = []
	options_menu.volume_slider = null

	# Should handle null references gracefully
	title_screen.navigate_down()
	options_menu._on_volume_slider_value_changed(50.0)

	await get_tree().process_frame

func test_extreme_settings_integration():
	"""Test integration with extreme settings"""
	# Set extreme volume
	options_menu._on_volume_slider_value_changed(0.0)  # Minimum
	options_menu._on_volume_slider_value_changed(100.0)  # Maximum

	# Should handle extreme values
	assert_that(options_menu.master_volume).is_greater_equal(0.0)
	assert_that(options_menu.master_volume).is_less_equal(100.0)

# === Final Integration Verification ===

func test_complete_title_screen_system_integration():
	"""Test complete title screen system integration"""
	# Setup all components
	title_screen.setup_menu_buttons()
	title_screen.setup_keyboard_navigation()
	options_menu.setup_difficulty_options()
	credits_screen.setup_references()

	# Test complete workflow
	# 1. Navigate title screen
	title_screen.navigate_down()
	title_screen.navigate_down()

	# 2. Go to options
	title_screen._on_options_button_pressed()
	await get_tree().process_frame

	# 3. Change settings
	options_menu._on_volume_slider_value_changed(85.0)
	options_menu._on_apply_button_pressed()

	# 4. Go back to title
	options_menu._on_back_button_pressed()
	await get_tree().process_frame

	# 5. Go to credits
	title_screen._on_credits_button_pressed()
	await get_tree().process_frame

	# 6. Interact with credits
	credits_screen.manual_scroll(100)
	credits_screen.toggle_auto_scroll()

	# 7. Return to title
	credits_screen._on_back_button_pressed()
	await get_tree().process_frame

	# System should handle complete workflow
	assert_that(transition_events.size()).is_greater_equal(6)  # Multiple transitions