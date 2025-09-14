extends Node2D

## Main Scene Router - Entry Point for Continuum Professional Title Screen System
## Manages initial scene routing and handles the application startup sequence

func _ready():
	# Initialize audio system first
	_initialize_audio()

	# Route to title screen on startup - use call_deferred to avoid async leak
	call_deferred("_route_to_title_screen")

func _initialize_audio():
	"""Initialize the synthesized sound system for menu sounds"""
	if has_node("/root/SoundManager"):
		# Audio system is ready - sounds will be generated on-demand
		pass

func _route_to_title_screen():
	"""Navigate to the title screen using the transition manager"""
	# Skip transition during headless runs to avoid ObjectDB leaks from orphaned async operations
	if DisplayServer.get_name() == "headless":
		return

	if has_node("/root/SceneTransitionManager"):
		SceneTransitionManager.transition_to_title()
	else:
		# Fallback direct routing if transition manager not available
		get_tree().change_scene_to_file("res://scenes/menus/TitleScreen.tscn")