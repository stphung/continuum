extends Node2D

## Main Scene Router - Entry Point for Continuum Professional Title Screen System
## Manages initial scene routing and handles the application startup sequence

func _ready():
	# Initialize audio system first
	_initialize_audio()

	# Route to title screen on startup
	await get_tree().process_frame  # Allow one frame for systems to initialize
	_route_to_title_screen()

func _initialize_audio():
	"""Initialize the synthesized sound system for menu sounds"""
	if has_node("/root/SoundManager"):
		# Pre-generate essential menu sounds for immediate availability
		SoundManager.preload_menu_sounds()

func _route_to_title_screen():
	"""Navigate to the title screen using the transition manager"""
	if has_node("/root/SceneTransitionManager"):
		SceneTransitionManager.transition_to_title()
	else:
		# Fallback direct routing if transition manager not available
		get_tree().change_scene_to_file("res://scenes/menus/TitleScreen.tscn")