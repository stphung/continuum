extends Node2D

## CreditsScreen - Professional Credits Display for Continuum
## Showcases development team, technology stack, and innovation highlights
## Part of the Continuum Professional Title Screen System

# Scroll animation properties
var scroll_speed: float = 50.0  # Pixels per second
var auto_scroll_enabled: bool = true
var scroll_container: ScrollContainer
var credits_content: VBoxContainer

# Animation tweens
var scroll_tween: Tween
var entrance_tween: Tween

func _ready():
	setup_references()
	setup_entrance_animation()
	setup_auto_scroll()

	# Play credits music if available
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("menu_music", -5.0)

func setup_references():
	"""Initialize UI component references"""
	scroll_container = $UI/MainContainer/ScrollContainer
	credits_content = $UI/MainContainer/ScrollContainer/CreditsContent

func setup_entrance_animation():
	"""Create smooth entrance animation for credits"""
	# Start with content faded out and slightly offset
	credits_content.modulate.a = 0.0
	credits_content.position.y = 50

	# Create entrance animation
	entrance_tween = create_tween()
	entrance_tween.set_parallel(true)

	# Fade in content
	entrance_tween.tween_property(credits_content, "modulate:a", 1.0, 1.0)

	# Animate position
	entrance_tween.tween_property(credits_content, "position:y", 0, 1.0)
	entrance_tween.set_ease(Tween.EASE_OUT)
	entrance_tween.set_trans(Tween.TRANS_CUBIC)

func setup_auto_scroll():
	"""Configure automatic scrolling animation"""
	if not auto_scroll_enabled:
		return

	# Wait for entrance animation to complete
	await entrance_tween.finished

	# Calculate total scroll distance
	var content_height = credits_content.get_minimum_size().y
	var container_height = scroll_container.size.y
	var max_scroll = max(0, content_height - container_height)

	if max_scroll <= 0:
		return  # No scrolling needed

	# Create continuous scroll animation
	scroll_tween = create_tween()
	scroll_tween.set_loops()

	# Scroll down
	var scroll_down_time = max_scroll / scroll_speed
	scroll_tween.tween_property(scroll_container, "scroll_vertical", max_scroll, scroll_down_time)

	# Pause at bottom
	scroll_tween.tween_delay(2.0)

	# Scroll back to top
	var scroll_up_time = max_scroll / (scroll_speed * 1.5)  # Slightly faster return
	scroll_tween.tween_property(scroll_container, "scroll_vertical", 0, scroll_up_time)

	# Pause at top before repeating
	scroll_tween.tween_delay(3.0)

func _input(event):
	"""Handle user input for navigation and scroll control"""
	# Manual scroll control
	if event.is_action_pressed("move_up"):
		manual_scroll(-30)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		manual_scroll(30)
		get_viewport().set_input_as_handled()

	# Toggle auto-scroll
	elif event.is_action_pressed("shoot") or event.is_action_pressed("ui_accept"):
		toggle_auto_scroll()
		get_viewport().set_input_as_handled()

	# Back to menu
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("bomb"):
		_on_back_button_pressed()
		get_viewport().set_input_as_handled()

func manual_scroll(delta_pixels: int):
	"""Handle manual scrolling input"""
	# Pause auto-scroll temporarily
	if scroll_tween:
		scroll_tween.pause()

	# Apply manual scroll
	var current_scroll = scroll_container.scroll_vertical
	var new_scroll = clamp(current_scroll + delta_pixels, 0,
						  max(0, credits_content.get_minimum_size().y - scroll_container.size.y))

	scroll_container.scroll_vertical = new_scroll

	# Play subtle feedback sound
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("menu_navigate", -15.0)

	# Resume auto-scroll after delay
	if auto_scroll_enabled:
		var resume_timer = Timer.new()
		resume_timer.wait_time = 3.0
		resume_timer.one_shot = true
		resume_timer.timeout.connect(_resume_auto_scroll)
		add_child(resume_timer)
		resume_timer.start()

func _resume_auto_scroll():
	"""Resume automatic scrolling after manual intervention"""
	if scroll_tween and auto_scroll_enabled:
		scroll_tween.play()

func toggle_auto_scroll():
	"""Toggle automatic scrolling on/off"""
	auto_scroll_enabled = !auto_scroll_enabled

	if auto_scroll_enabled:
		setup_auto_scroll()
		# Visual feedback - briefly highlight scroll container
		var highlight_tween = create_tween()
		highlight_tween.tween_property(scroll_container, "modulate", Color(1.2, 1.2, 1.0, 1.0), 0.2)
		highlight_tween.tween_property(scroll_container, "modulate", Color.WHITE, 0.2)
	else:
		if scroll_tween:
			scroll_tween.kill()
		# Visual feedback - briefly dim scroll container
		var dim_tween = create_tween()
		dim_tween.tween_property(scroll_container, "modulate", Color(0.8, 0.8, 0.8, 1.0), 0.2)
		dim_tween.tween_property(scroll_container, "modulate", Color.WHITE, 0.2)

	# Play toggle sound
	if has_node("/root/SoundManager"):
		var sound_type = "menu_select" if auto_scroll_enabled else "menu_back"
		SoundManager.play_sound(sound_type, -5.0)

func _on_back_button_pressed():
	"""Handle Back button press - return to title screen"""
	# Stop all animations
	if scroll_tween:
		scroll_tween.kill()
	if entrance_tween:
		entrance_tween.kill()

	# Play back sound
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("menu_back", 0.0)

	# Create exit animation
	var exit_tween = create_tween()
	exit_tween.set_parallel(true)

	# Fade out
	exit_tween.tween_property(credits_content, "modulate:a", 0.0, 0.5)

	# Wait for exit animation
	await exit_tween.finished

	# Return to title screen
	if has_node("/root/SceneTransitionManager"):
		SceneTransitionManager.transition_to_title()
	else:
		get_tree().change_scene_to_file("res://scenes/menus/TitleScreen.tscn")

# Utility methods
func set_scroll_speed(new_speed: float):
	"""Adjust the automatic scroll speed"""
	scroll_speed = max(10.0, new_speed)
	if auto_scroll_enabled:
		setup_auto_scroll()

func jump_to_section(section_name: String):
	"""Jump to a specific section in the credits"""
	# This could be extended to support section navigation
	# For now, just scroll to top
	scroll_container.scroll_vertical = 0