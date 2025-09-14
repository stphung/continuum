extends Node
## KioskManager - Comprehensive Kiosk Mode System
## Handles state management, AI demo player, attract screens, and user interaction detection

signal kiosk_state_changed(new_state: String)
signal demo_session_started
signal demo_session_ended
signal attract_cycle_started
signal high_score_achieved(score: int, rank: int)

enum KioskState {
	DISABLED,        # Normal game mode
	ATTRACT,         # Cycling through promotional content
	DEMO_PLAYING,    # AI playing the game
	HIGH_SCORES,     # Displaying leaderboards
	TRANSITIONING    # Between states
}

var current_state: KioskState = KioskState.DISABLED
var config: Dictionary = {}
var input_timeout: float = 0.0
var input_timer: Timer
var attract_timer: Timer
var demo_player: Node
var attract_screen_manager: Node
var high_score_manager: Node
var kiosk_ui: Node

# Configuration defaults
const DEFAULT_CONFIG = {
	"enabled": false,
	"input_timeout": 30.0,          # Seconds of inactivity before entering kiosk mode
	"attract_cycle_time": 15.0,      # Seconds per attract screen
	"demo_session_length": 120.0,    # Seconds of AI gameplay demo
	"high_score_display_time": 20.0, # Seconds showing high scores
	"difficulty_preset": "intermediate", # AI difficulty: beginner, intermediate, expert
	"auto_transition": true,         # Automatically cycle through kiosk modes
	"deployment_type": "arcade",     # arcade, exhibition, retail
	"attract_screens": [
		{"type": "gameplay", "duration": 15.0},
		{"type": "features", "duration": 12.0},
		{"type": "high_scores", "duration": 10.0},
		{"type": "instructions", "duration": 8.0}
	]
}

func _ready():
	print("KioskManager: Initializing comprehensive kiosk system...")
	_load_configuration()
	_setup_timers()
	_initialize_subsystems()
	_setup_input_detection()

	if config.enabled:
		print("KioskManager: Kiosk mode enabled - monitoring for user inactivity")
		_start_input_monitoring()
	else:
		print("KioskManager: Kiosk mode disabled - running in normal game mode")

func _load_configuration():
	"""Load kiosk configuration from file or use defaults"""
	var config_path = "res://kiosk_config.json"
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()

			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				config = json.data
				print("KioskManager: Loaded configuration from ", config_path)
			else:
				push_error("KioskManager: Failed to parse configuration file")
				config = DEFAULT_CONFIG.duplicate(true)
		else:
			push_error("KioskManager: Could not open configuration file")
			config = DEFAULT_CONFIG.duplicate(true)
	else:
		config = DEFAULT_CONFIG.duplicate(true)
		print("KioskManager: Using default configuration")

	# Ensure all required keys exist
	for key in DEFAULT_CONFIG:
		if not config.has(key):
			config[key] = DEFAULT_CONFIG[key]

func _setup_timers():
	"""Initialize all timing systems"""
	# Input timeout timer
	input_timer = Timer.new()
	input_timer.name = "InputTimer"
	input_timer.one_shot = true
	input_timer.timeout.connect(_on_input_timeout)
	add_child(input_timer)

	# Attract screen cycling timer
	attract_timer = Timer.new()
	attract_timer.name = "AttractTimer"
	attract_timer.one_shot = false
	attract_timer.timeout.connect(_on_attract_timer_timeout)
	add_child(attract_timer)

func _initialize_subsystems():
	"""Initialize all kiosk subsystems"""
	# High Score Manager
	var HighScoreManagerScript = preload("res://scripts/kiosk/HighScoreManager.gd")
	high_score_manager = HighScoreManagerScript.new()
	high_score_manager.name = "HighScoreManager"
	add_child(high_score_manager)

	# Demo Player AI
	var DemoPlayerScript = preload("res://scripts/kiosk/DemoPlayer.gd")
	demo_player = DemoPlayerScript.new()
	demo_player.name = "DemoPlayer"
	demo_player.set_difficulty(config.difficulty_preset)
	add_child(demo_player)

	# Attract Screen Manager
	var AttractScreenManagerScript = preload("res://scripts/kiosk/AttractScreenManager.gd")
	attract_screen_manager = AttractScreenManagerScript.new()
	attract_screen_manager.name = "AttractScreenManager"
	attract_screen_manager.setup(config.attract_screens)
	add_child(attract_screen_manager)

	# Kiosk UI Manager
	var KioskUIScript = preload("res://scripts/kiosk/KioskUI.gd")
	kiosk_ui = KioskUIScript.new()
	kiosk_ui.name = "KioskUI"
	add_child(kiosk_ui)

	# Connect subsystem signals
	demo_player.demo_ended.connect(_on_demo_ended)
	demo_player.high_score_achieved.connect(_on_high_score_achieved)
	attract_screen_manager.cycle_completed.connect(_on_attract_cycle_completed)
	high_score_manager.scores_updated.connect(_on_high_scores_updated)

func _setup_input_detection():
	"""Setup universal input detection for kiosk exit"""
	# Input detection will be handled through _unhandled_input
	# when this node is added to the scene tree

func _start_input_monitoring():
	"""Begin monitoring for user inactivity"""
	input_timeout = config.input_timeout
	input_timer.wait_time = input_timeout
	input_timer.start()

func _unhandled_input(event: InputEvent):
	"""Handle any user input - resets timers and exits kiosk mode"""
	if not config.enabled:
		return

	# Check for genuine user input (not synthetic AI input)
	if _is_user_input(event):
		_reset_input_timer()

		# Exit kiosk mode if currently active
		if current_state != KioskState.DISABLED:
			exit_kiosk_mode()

func _is_user_input(event: InputEvent) -> bool:
	"""Determine if input is from user or AI system"""
	# AI input will have specific metadata to identify it
	if event.has_meta("ai_generated"):
		return false

	# Check for mouse, keyboard, or controller input
	return (event is InputEventMouseButton or
			event is InputEventMouseMotion or
			event is InputEventKey or
			event is InputEventJoypadButton or
			event is InputEventJoypadMotion)

func _reset_input_timer():
	"""Reset the inactivity timer"""
	if input_timer and config.enabled:
		input_timer.stop()
		input_timer.wait_time = input_timeout
		input_timer.start()

func _on_input_timeout():
	"""Handle user inactivity timeout"""
	if current_state == KioskState.DISABLED:
		print("KioskManager: User inactivity detected - entering kiosk mode")
		enter_kiosk_mode()

func enter_kiosk_mode():
	"""Enter kiosk mode and begin attract sequence"""
	if current_state != KioskState.DISABLED:
		return

	print("KioskManager: Entering kiosk mode")
	_transition_to_state(KioskState.ATTRACT)

	# Pause or modify current game if needed
	_prepare_for_kiosk_mode()

	# Start attract screen cycle
	_start_attract_sequence()

func exit_kiosk_mode():
	"""Exit kiosk mode and return to normal operation"""
	if current_state == KioskState.DISABLED:
		return

	print("KioskManager: Exiting kiosk mode - user input detected")

	# Stop all kiosk activities
	attract_timer.stop()
	demo_player.stop_demo()
	attract_screen_manager.hide_all_screens()
	kiosk_ui.hide_all_interfaces()

	_transition_to_state(KioskState.DISABLED)
	_restore_normal_mode()
	_start_input_monitoring()

func _prepare_for_kiosk_mode():
	"""Prepare game systems for kiosk mode operation"""
	# Save current game state if needed
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_method("pause_game"):
		current_scene.pause_game()

	# Initialize kiosk UI overlay
	kiosk_ui.show_kiosk_overlay()

func _restore_normal_mode():
	"""Restore normal game operation"""
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_method("resume_game"):
		current_scene.resume_game()

	kiosk_ui.hide_kiosk_overlay()

func _start_attract_sequence():
	"""Begin the attract screen sequence"""
	attract_screen_manager.start_cycle()
	# Configure timer for repeating attract screen cycling
	attract_timer.stop()
	attract_timer.one_shot = false
	attract_timer.wait_time = config.attract_cycle_time
	attract_timer.start()

func _on_attract_timer_timeout():
	"""Handle attract screen cycling"""
	match current_state:
		KioskState.ATTRACT:
			if attract_screen_manager.should_start_demo():
				_start_demo_session()
			else:
				attract_screen_manager.next_screen()
		KioskState.HIGH_SCORES:
			if config.auto_transition:
				# Stop the current timer to prevent multiple timeouts
				attract_timer.stop()
				# Hide high scores UI before transitioning
				kiosk_ui.hide_high_scores()
				_transition_to_state(KioskState.ATTRACT)
				_start_attract_sequence()
			else:
				# If auto_transition is disabled, stay in high scores
				print("KioskManager: Auto transition disabled, staying in HIGH_SCORES")

func _start_demo_session():
	"""Begin AI gameplay demonstration"""
	print("KioskManager: Starting AI demo session")
	_transition_to_state(KioskState.DEMO_PLAYING)

	attract_screen_manager.hide_current_screen()
	demo_player.start_demo()
	demo_session_started.emit()

	# Set demo session timer
	var demo_timer = Timer.new()
	demo_timer.wait_time = config.demo_session_length
	demo_timer.one_shot = true
	demo_timer.timeout.connect(_on_demo_session_timeout)
	add_child(demo_timer)
	demo_timer.start()

func _on_demo_session_timeout():
	"""Handle demo session timeout"""
	print("KioskManager: Demo session timeout")
	_end_demo_session()

func _on_demo_ended():
	"""Handle demo player completion/death"""
	print("KioskManager: Demo ended naturally")
	_end_demo_session()

func _end_demo_session():
	"""End the current demo session"""
	demo_player.stop_demo()
	demo_session_ended.emit()

	# Check if high score was achieved
	var demo_score = demo_player.get_final_score()
	print("KioskManager: Demo final score: ", demo_score)
	if high_score_manager.is_high_score(demo_score):
		print("KioskManager: High score achieved, showing high scores")
		_show_high_scores()
	else:
		print("KioskManager: No high score, returning to attract mode")
		# Return to attract sequence
		_transition_to_state(KioskState.ATTRACT)
		_start_attract_sequence()

func _show_high_scores():
	"""Display high score screen"""
	print("KioskManager: _show_high_scores() called from: ", get_stack())
	print("KioskManager: Current state: ", KioskState.keys()[current_state])

	# Prevent recursive calls
	if current_state == KioskState.HIGH_SCORES:
		print("KioskManager: Already showing high scores, ignoring duplicate call")
		return

	print("KioskManager: Showing high scores")
	_transition_to_state(KioskState.HIGH_SCORES)

	kiosk_ui.show_high_scores(high_score_manager.get_scores())

	# Set high score display timer (one-shot for this state)
	attract_timer.stop()
	attract_timer.one_shot = true
	attract_timer.wait_time = config.high_score_display_time
	attract_timer.start()

func _on_attract_cycle_completed():
	"""Handle completion of attract screen cycle"""
	attract_cycle_started.emit()

func _on_high_score_achieved(score: int):
	"""Handle high score achievement during demo"""
	var rank = high_score_manager.add_score("AI DEMO", score)
	high_score_achieved.emit(score, rank)

func _on_high_scores_updated():
	"""Handle high score data updates"""
	if current_state == KioskState.HIGH_SCORES:
		kiosk_ui.refresh_high_scores(high_score_manager.get_scores())

func _transition_to_state(new_state: KioskState):
	"""Safely transition between kiosk states"""
	var old_state = current_state
	current_state = new_state

	print("KioskManager: State transition: ",
		  KioskState.keys()[old_state], " -> ",
		  KioskState.keys()[new_state])

	kiosk_state_changed.emit(KioskState.keys()[new_state])

# Public API for external systems
func is_kiosk_active() -> bool:
	"""Check if kiosk mode is currently active"""
	return current_state != KioskState.DISABLED

func get_current_state() -> String:
	"""Get current kiosk state as string"""
	return KioskState.keys()[current_state]

func force_enter_kiosk_mode():
	"""Manually enter kiosk mode (for testing/debugging)"""
	if config.enabled:
		enter_kiosk_mode()

func force_exit_kiosk_mode():
	"""Manually exit kiosk mode (for testing/debugging)"""
	exit_kiosk_mode()

func update_configuration(new_config: Dictionary):
	"""Update kiosk configuration at runtime"""
	for key in new_config:
		if config.has(key):
			config[key] = new_config[key]

	# Restart systems with new configuration
	if config.enabled and current_state == KioskState.DISABLED:
		_start_input_monitoring()

func get_demo_statistics() -> Dictionary:
	"""Get AI demo performance statistics"""
	return demo_player.get_performance_stats()

func get_attract_screen_info() -> Dictionary:
	"""Get current attract screen information"""
	return attract_screen_manager.get_current_screen_info()

func _exit_tree():
	"""Cleanup on exit"""
	if input_timer:
		input_timer.queue_free()
	if attract_timer:
		attract_timer.queue_free()