extends Node

## SceneTransitionManager - Professional Scene Transition System
## Handles smooth transitions between game scenes with fade effects and loading states
## Part of the Continuum Professional Title Screen System

signal scene_transition_started(from_scene: String, to_scene: String)
signal scene_transition_completed(scene_name: String)
signal transition_fade_in_completed()
signal transition_fade_out_completed()

# Transition configuration
@export var transition_duration: float = 0.5
@export var fade_color: Color = Color.BLACK

# Internal state
var is_transitioning: bool = false
var current_scene_path: String = ""
var fade_overlay: ColorRect
var loading_label: Label
var tween: Tween

func _ready():
	# Initialize the fade overlay
	_setup_fade_overlay()

	# Set initial scene path
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene_path = current_scene.scene_file_path

	# Ensure we're at the top of the scene tree for proper rendering order
	process_mode = Node.PROCESS_MODE_ALWAYS

func _setup_fade_overlay():
	"""Create and configure the fade overlay for smooth transitions"""
	# Create main overlay container
	fade_overlay = ColorRect.new()
	fade_overlay.name = "FadeOverlay"
	fade_overlay.color = fade_color
	fade_overlay.size = get_viewport().get_visible_rect().size
	fade_overlay.anchor_right = 1.0
	fade_overlay.anchor_bottom = 1.0
	fade_overlay.modulate.a = 0.0  # Start transparent
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Allow input passthrough when transparent
	fade_overlay.z_index = 1000  # Ensure it's above everything else

	# Add to scene tree as a CanvasLayer for consistent rendering
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "TransitionCanvas"
	canvas_layer.layer = 1000  # Very high layer priority
	add_child(canvas_layer)
	canvas_layer.add_child(fade_overlay)

	# Create loading label for feedback
	loading_label = Label.new()
	loading_label.name = "LoadingLabel"
	loading_label.text = "Loading..."
	loading_label.add_theme_font_size_override("font_size", 32)
	loading_label.modulate = Color.WHITE
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loading_label.anchor_left = 0.0
	loading_label.anchor_top = 0.0
	loading_label.anchor_right = 1.0
	loading_label.anchor_bottom = 1.0
	loading_label.modulate.a = 0.0
	fade_overlay.add_child(loading_label)

func transition_to_scene(scene_path: String, show_loading: bool = false) -> bool:
	"""Perform smooth transition to target scene with optional loading indicator"""
	if is_transitioning:
		push_warning("SceneTransitionManager: Transition already in progress")
		return false

	# Validate scene path
	if not ResourceLoader.exists(scene_path):
		push_error("SceneTransitionManager: Scene path does not exist: " + scene_path)
		return false

	is_transitioning = true

	# Emit transition started signal
	scene_transition_started.emit(current_scene_path, scene_path)

	# Play menu navigation sound if available
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("menu_select", 0.0)

	# Start the transition sequence
	await _perform_transition(scene_path, show_loading)
	return true

func _perform_transition(scene_path: String, show_loading: bool):
	"""Execute the complete transition sequence"""
	# Phase 1: Fade to black
	await _fade_to_black()

	# Phase 2: Show loading if requested
	if show_loading:
		_show_loading()
		await get_tree().process_frame  # Allow one frame for UI update

	# Phase 3: Load and switch to new scene
	var success = await _change_scene(scene_path)

	if not success:
		push_error("SceneTransitionManager: Failed to load scene: " + scene_path)
		is_transitioning = false
		await _fade_from_black()
		return

	# Phase 4: Hide loading and fade from black
	if show_loading:
		_hide_loading()

	await _fade_from_black()

	# Transition complete
	is_transitioning = false
	scene_transition_completed.emit(scene_path)

func _fade_to_black() -> void:
	"""Fade overlay to opaque black"""
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # Block input during transition

	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	tween.tween_property(fade_overlay, "modulate:a", 1.0, transition_duration)
	await tween.finished

	transition_fade_in_completed.emit()

func _fade_from_black() -> void:
	"""Fade overlay from opaque black to transparent"""
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)

	tween.tween_property(fade_overlay, "modulate:a", 0.0, transition_duration)
	await tween.finished

	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Allow input passthrough
	transition_fade_out_completed.emit()

func _show_loading():
	"""Display loading indicator"""
	if loading_label:
		loading_label.modulate.a = 1.0

func _hide_loading():
	"""Hide loading indicator"""
	if loading_label:
		loading_label.modulate.a = 0.0

func _change_scene(scene_path: String) -> bool:
	"""Load and switch to the target scene"""
	var new_scene = load(scene_path)
	if not new_scene:
		return false

	# Get current scene and defer its removal
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.queue_free()

	# Instantiate and add new scene
	var new_scene_instance = new_scene.instantiate()
	get_tree().root.add_child(new_scene_instance)
	get_tree().current_scene = new_scene_instance

	# Update our tracking
	current_scene_path = scene_path

	# Allow one frame for scene setup
	await get_tree().process_frame

	return true

func instant_scene_change(scene_path: String) -> bool:
	"""Immediately change scene without transition effects"""
	if is_transitioning:
		push_warning("SceneTransitionManager: Cannot perform instant change during transition")
		return false

	if not ResourceLoader.exists(scene_path):
		push_error("SceneTransitionManager: Scene path does not exist: " + scene_path)
		return false

	get_tree().change_scene_to_file(scene_path)
	current_scene_path = scene_path
	return true

func get_current_scene_path() -> String:
	"""Get the path of the currently loaded scene"""
	return current_scene_path

func is_scene_transition_active() -> bool:
	"""Check if a scene transition is currently in progress"""
	return is_transitioning

# Quick access methods for common transitions
func transition_to_game() -> bool:
	"""Quick transition to main game scene"""
	return await transition_to_scene("res://scenes/main/Game.tscn", true)

func transition_to_title() -> bool:
	"""Quick transition to title screen"""
	return await transition_to_scene("res://scenes/menus/TitleScreen.tscn", false)

func transition_to_options() -> bool:
	"""Quick transition to options menu"""
	return await transition_to_scene("res://scenes/menus/OptionsMenu.tscn", false)

func transition_to_credits() -> bool:
	"""Quick transition to credits screen"""
	return await transition_to_scene("res://scenes/menus/CreditsScreen.tscn", false)

func _exit_tree():
	# Clean up tween and other resources on exit
	if tween:
		tween.kill()
		tween = null

	# Clean up UI elements
	if fade_overlay and is_instance_valid(fade_overlay):
		fade_overlay.queue_free()
		fade_overlay = null

	if loading_label and is_instance_valid(loading_label):
		loading_label.queue_free()
		loading_label = null