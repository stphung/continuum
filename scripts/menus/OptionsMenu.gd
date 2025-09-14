extends Node2D

## OptionsMenu - Configuration Screen for Continuum Professional Title Screen System
## Provides user-configurable settings for audio, graphics, and gameplay

# Option values
var master_volume: float = 80.0
var is_fullscreen: bool = false
var difficulty_level: int = 1  # 0=Easy, 1=Normal, 2=Hard

# UI References
@onready var volume_slider = $UI/MainContainer/OptionsContainer/VolumeContainer/VolumeSlider
@onready var volume_value_label = $UI/MainContainer/OptionsContainer/VolumeContainer/VolumeValueLabel
@onready var fullscreen_checkbox = $UI/MainContainer/OptionsContainer/FullscreenContainer/FullscreenCheckBox
@onready var difficulty_option = $UI/MainContainer/OptionsContainer/DifficultyContainer/DifficultyOption

func _ready():
	setup_difficulty_options()
	load_settings()
	apply_current_settings()

func setup_difficulty_options():
	"""Initialize the difficulty dropdown options"""
	difficulty_option.clear()
	difficulty_option.add_item("Easy")
	difficulty_option.add_item("Normal")
	difficulty_option.add_item("Hard")

func load_settings():
	"""Load settings from persistent storage or set defaults"""
	# For now, we'll use default values
	# In a full implementation, you would load from a config file
	master_volume = 80.0
	is_fullscreen = false
	difficulty_level = 1  # Normal

	# Update UI to reflect loaded settings
	volume_slider.value = master_volume
	volume_value_label.text = str(int(master_volume)) + "%"
	fullscreen_checkbox.button_pressed = is_fullscreen
	difficulty_option.selected = difficulty_level

func apply_current_settings():
	"""Apply current settings to the game systems"""
	# Apply volume setting
	if has_node("/root/SoundManager"):
		var volume_db = linear_to_db(master_volume / 100.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)

	# Apply fullscreen setting
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	# Store difficulty for use by other systems
	# This could be accessed via a global settings manager
	set_meta("difficulty_level", difficulty_level)

func save_settings():
	"""Save current settings to persistent storage"""
	# In a full implementation, you would save to a config file
	# For now, we'll just apply the settings
	apply_current_settings()

# Signal handlers
func _on_volume_slider_value_changed(value: float):
	"""Handle volume slider changes"""
	master_volume = value
	volume_value_label.text = str(int(value)) + "%"

	# Apply volume change immediately for feedback
	if has_node("/root/SoundManager"):
		var volume_db = linear_to_db(value / 100.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)

		# Play a test sound for immediate feedback
		SoundManager.play_sound("menu_hover", -10.0)

func _on_fullscreen_check_box_toggled(toggled_on: bool):
	"""Handle fullscreen checkbox changes"""
	is_fullscreen = toggled_on

	# Play feedback sound
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("menu_navigate", 0.0)

func _on_difficulty_option_item_selected(index: int):
	"""Handle difficulty selection changes"""
	difficulty_level = index

	# Play feedback sound
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("menu_navigate", 0.0)

func _on_apply_button_pressed():
	"""Handle Apply button press - save and apply all settings"""
	# Play confirmation sound
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("menu_select", 0.0)

	# Save and apply settings
	save_settings()

	# Visual feedback that settings were applied
	var apply_button = $UI/MainContainer/OptionsContainer/ButtonContainer/ApplyButton
	apply_button.text = "APPLIED!"
	apply_button.modulate = Color.GREEN

	# Reset button appearance after brief delay
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(_reset_apply_button)
	add_child(timer)
	timer.start()

func _reset_apply_button():
	"""Reset the Apply button to normal appearance"""
	var apply_button = $UI/MainContainer/OptionsContainer/ButtonContainer/ApplyButton
	apply_button.text = "APPLY"
	apply_button.modulate = Color.WHITE

func _on_back_button_pressed():
	"""Handle Back button press - return to title screen"""
	# Play back sound
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("menu_back", 0.0)

	# Return to title screen
	if has_node("/root/SceneTransitionManager"):
		SceneTransitionManager.transition_to_title()
	else:
		get_tree().change_scene_to_file("res://scenes/menus/TitleScreen.tscn")

func _input(event):
	"""Handle keyboard input for quick navigation"""
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("bomb"):
		_on_back_button_pressed()
		get_viewport().set_input_as_handled()