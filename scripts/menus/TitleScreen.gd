extends Node2D

## TitleScreen - Professional Title Screen with Menu Navigation
## Part of the Continuum Professional Title Screen System
## Features smooth animations, keyboard navigation, and audio feedback

# Menu button references for keyboard navigation
var menu_buttons: Array[Button] = []
var current_button_index: int = 0
var is_animating: bool = false

# Animation tweens
var title_tween: Tween
var button_hover_tween: Tween

signal menu_navigation_changed(button_index: int)

func _ready():
	# Initialize menu system
	setup_menu_buttons()
	setup_initial_animations()
	setup_keyboard_navigation()

	# Play title screen music if available
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("menu_music", 0.0)

func setup_menu_buttons():
	"""Initialize menu button array and configure initial states"""
	menu_buttons = [
		$UI/MainContainer/MenuContainer/StartButton,
		$UI/MainContainer/MenuContainer/OptionsButton,
		$UI/MainContainer/MenuContainer/CreditsButton,
		$UI/MainContainer/MenuContainer/QuitButton
	]

	# Set initial button selection
	current_button_index = 0
	highlight_current_button()

func setup_initial_animations():
	"""Create smooth entrance animations for UI elements"""
	if is_animating:
		return

	is_animating = true

	# Animate title entrance
	var title_container = $UI/MainContainer/TitleContainer
	var menu_container = $UI/MainContainer/MenuContainer
	var instructions = $UI/MainContainer/Instructions

	# Start with elements off-screen/transparent
	title_container.position.y -= 50
	title_container.modulate.a = 0.0
	menu_container.position.y += 50
	menu_container.modulate.a = 0.0
	instructions.modulate.a = 0.0

	# Create entrance animation sequence
	title_tween = create_tween()
	title_tween.set_parallel(true)

	# Animate title container
	title_tween.tween_property(title_container, "position:y", title_container.position.y + 50, 1.0)
	title_tween.tween_property(title_container, "modulate:a", 1.0, 1.0)

	# Animate menu container with delay
	title_tween.tween_property(menu_container, "position:y", menu_container.position.y - 50, 0.8)
	title_tween.tween_property(menu_container, "modulate:a", 1.0, 0.8)
	title_tween.tween_delay(0.3)

	# Animate instructions last
	title_tween.tween_property(instructions, "modulate:a", 1.0, 0.5)
	title_tween.tween_delay(0.8)

	# Animation complete
	title_tween.tween_callback(_on_animation_complete)

func _on_animation_complete():
	"""Called when entrance animations complete"""
	is_animating = false

func setup_keyboard_navigation():
	"""Configure keyboard and controller navigation"""
	# Connect to input events
	set_process_input(true)

	# Enable focus for button navigation
	for i in range(menu_buttons.size()):
		var button = menu_buttons[i]
		button.focus_mode = Control.FOCUS_ALL

		# Connect hover events for mouse interaction
		button.mouse_entered.connect(_on_button_hovered.bind(i))

func _input(event):
	"""Handle keyboard and controller input for menu navigation"""
	if is_animating:
		return

	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		navigate_up()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		navigate_down()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("shoot") or event.is_action_pressed("ui_accept"):
		activate_current_button()
		get_viewport().set_input_as_handled()

func navigate_up():
	"""Navigate to previous menu button"""
	if menu_buttons.size() == 0:
		return

	current_button_index = (current_button_index - 1) % menu_buttons.size()
	highlight_current_button()

	# Play navigation sound
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("menu_navigate", 0.0)

	menu_navigation_changed.emit(current_button_index)

func navigate_down():
	"""Navigate to next menu button"""
	if menu_buttons.size() == 0:
		return

	current_button_index = (current_button_index + 1) % menu_buttons.size()
	highlight_current_button()

	# Play navigation sound
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("menu_navigate", 0.0)

	menu_navigation_changed.emit(current_button_index)

func _on_button_hovered(button_index: int):
	"""Handle mouse hover over buttons"""
	if is_animating or button_index == current_button_index:
		return

	current_button_index = button_index
	highlight_current_button()

	# Play hover sound
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("menu_hover", 0.0)

func highlight_current_button():
	"""Visual highlight for currently selected button"""
	# Reset all button styles
	for i in range(menu_buttons.size()):
		var button = menu_buttons[i]
		if i == current_button_index:
			# Highlight current button
			animate_button_highlight(button, true)
		else:
			# Normal state
			animate_button_highlight(button, false)

func animate_button_highlight(button: Button, highlighted: bool):
	"""Smooth button highlight animation"""
	if button_hover_tween:
		button_hover_tween.kill()
	button_hover_tween = create_tween()

	var target_scale = Vector2(1.1, 1.1) if highlighted else Vector2(1.0, 1.0)
	var target_modulate = Color(1.2, 1.2, 1.0, 1.0) if highlighted else Color.WHITE

	button_hover_tween.set_parallel(true)
	button_hover_tween.tween_property(button, "scale", target_scale, 0.2)
	button_hover_tween.tween_property(button, "modulate", target_modulate, 0.2)

	# Focus the button for accessibility
	if highlighted:
		button.grab_focus()

func activate_current_button():
	"""Activate the currently selected button"""
	if current_button_index >= 0 and current_button_index < menu_buttons.size():
		var current_button = menu_buttons[current_button_index]
		current_button.pressed.emit()

# Button signal handlers
func _on_start_button_pressed():
	"""Handle Start Game button press"""
	if is_animating:
		return

	# Play selection sound
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("menu_select", 0.0)

	# Transition to game
	if has_node("/root/SceneTransitionManager"):
		SceneTransitionManager.transition_to_game()
	else:
		get_tree().change_scene_to_file("res://scenes/main/Game.tscn")

func _on_options_button_pressed():
	"""Handle Options button press"""
	if is_animating:
		return

	# Play selection sound
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("menu_select", 0.0)

	# Transition to options
	if has_node("/root/SceneTransitionManager"):
		SceneTransitionManager.transition_to_options()
	else:
		get_tree().change_scene_to_file("res://scenes/menus/OptionsMenu.tscn")

func _on_credits_button_pressed():
	"""Handle Credits button press"""
	if is_animating:
		return

	# Play selection sound
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("menu_select", 0.0)

	# Transition to credits
	if has_node("/root/SceneTransitionManager"):
		SceneTransitionManager.transition_to_credits()
	else:
		get_tree().change_scene_to_file("res://scenes/menus/CreditsScreen.tscn")

func _on_quit_button_pressed():
	"""Handle Quit button press"""
	if is_animating:
		return

	# Play selection sound
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("menu_select", 0.0)

	# Create exit confirmation or quit immediately
	await create_quit_animation()
	get_tree().quit()

func create_quit_animation():
	"""Smooth exit animation before quitting"""
	var fade_tween = create_tween()
	fade_tween.set_parallel(true)

	# Fade out UI elements
	fade_tween.tween_property($UI/MainContainer, "modulate:a", 0.0, 0.5)

	# Stop starfield animation
	if has_node("StarfieldBackground"):
		$StarfieldBackground.pause_animation()

	await fade_tween.finished

# Utility methods
func get_current_button() -> Button:
	"""Get currently selected button"""
	if current_button_index >= 0 and current_button_index < menu_buttons.size():
		return menu_buttons[current_button_index]
	return null

func set_current_button(index: int):
	"""Programmatically set current button selection"""
	if index >= 0 and index < menu_buttons.size():
		current_button_index = index
		highlight_current_button()