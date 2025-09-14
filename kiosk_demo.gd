extends SceneTree
## Kiosk Mode System Demonstration
## Run with: godot --script kiosk_demo.gd

var demo_phase = 0
var kiosk_manager: Node
var demo_timer: Timer

func _init():
	print("============================================================")
	print("   CONTINUUM KIOSK MODE SYSTEM DEMONSTRATION")
	print("============================================================")
	print()
	print("This demonstration showcases the comprehensive kiosk mode")
	print("system with AI gameplay, attract screens, and high scores.")
	print()
	print("System Features:")
	print("• Sophisticated AI player with threat assessment")
	print("• Professional attract screen cycling")
	print("• Persistent high score management with JSON storage")
	print("• Full-screen overlay UI system with transitions")
	print("• Configurable deployment presets for different venues")
	print("• Universal input detection for instant kiosk exit")
	print()
	print("============================================================")

	_initialize_kiosk_demo()

func _initialize_kiosk_demo():
	"""Initialize the kiosk system for demonstration"""
	# Load and configure the kiosk manager
	var KioskManagerScript = preload("res://scripts/autoloads/KioskManager.gd")
	kiosk_manager = KioskManagerScript.new()
	kiosk_manager.name = "KioskManager"

	# Enable kiosk mode for demo
	kiosk_manager.config.enabled = true
	kiosk_manager.config.input_timeout = 5.0  # Short timeout for demo
	kiosk_manager.config.demo_session_length = 15.0  # Short demo sessions

	root.add_child(kiosk_manager)

	# Connect to kiosk manager signals
	kiosk_manager.kiosk_state_changed.connect(_on_kiosk_state_changed)
	kiosk_manager.demo_session_started.connect(_on_demo_session_started)
	kiosk_manager.demo_session_ended.connect(_on_demo_session_ended)
	kiosk_manager.high_score_achieved.connect(_on_high_score_achieved)

	# Setup demo progression timer
	demo_timer = Timer.new()
	demo_timer.wait_time = 3.0
	demo_timer.one_shot = false
	demo_timer.timeout.connect(_advance_demo)
	root.add_child(demo_timer)
	demo_timer.start()

	print("Kiosk system initialized successfully!")
	print("Current state: ", kiosk_manager.get_current_state())
	print()

func _advance_demo():
	"""Advance through different demo phases"""
	demo_phase += 1

	match demo_phase:
		1:
			print("DEMO PHASE 1: High Score System")
			print("----------------------------------------")
			_demo_high_score_system()

		2:
			print("\nDEMO PHASE 2: AI Demonstration Player")
			print("----------------------------------------")
			_demo_ai_player()

		3:
			print("\nDEMO PHASE 3: Attract Screen Manager")
			print("----------------------------------------")
			_demo_attract_screens()

		4:
			print("\nDEMO PHASE 4: Configuration System")
			print("----------------------------------------")
			_demo_configuration_system()

		5:
			print("\nDEMO PHASE 5: Kiosk Mode Simulation")
			print("----------------------------------------")
			_demo_kiosk_mode()

		6:
			print("\nDEMO PHASE 6: Performance Statistics")
			print("----------------------------------------")
			_demo_performance_stats()

		_:
			print("\n============================================================")
			print("   DEMONSTRATION COMPLETED SUCCESSFULLY")
			print("============================================================")
			print()
			print("The Continuum Kiosk Mode System is ready for deployment!")
			print("Configure kiosk_config.json and set 'enabled: true' to activate.")
			print()
			print("Key Integration Points:")
			print("• KioskManager autoload handles all state management")
			print("• Game.gd reports scores automatically")
			print("• Player.gd works seamlessly with AI input injection")
			print("• All systems are modular and independently testable")
			print()
			quit()

func _demo_high_score_system():
	"""Demonstrate high score management"""
	var high_score_manager = kiosk_manager.high_score_manager

	print("Adding demo scores to the high score table...")

	var demo_scores = [
		{"name": "ACE PILOT", "score": 45000, "metadata": {"difficulty": "expert"}},
		{"name": "WING COMMANDER", "score": 32000, "metadata": {"difficulty": "intermediate"}},
		{"name": "SKY CAPTAIN", "score": 28000, "metadata": {"difficulty": "intermediate"}},
		{"name": "FLIGHT OFFICER", "score": 19000, "metadata": {"difficulty": "beginner"}},
		{"name": "AI DEMO", "score": 38000, "metadata": {"difficulty": "expert", "ai_generated": true}}
	]

	for score_data in demo_scores:
		var rank = high_score_manager.add_score(score_data.name, score_data.score, score_data.metadata)
		print("  %s: %d points (rank %d)" % [score_data.name, score_data.score, rank])

	print("\nTop 3 High Scores:")
	var top_scores = high_score_manager.get_scores(3)
	for i in range(top_scores.size()):
		var entry = top_scores[i]
		print("  %d. %s - %d" % [i + 1, entry.name, entry.score])

	print("\nSession Statistics:")
	var stats = high_score_manager.get_session_statistics()
	print("  Games played: %d" % stats.games_played)
	print("  Average score: %.0f" % stats.average_score)
	print("  Best session score: %d" % stats.best_score)

func _demo_ai_player():
	"""Demonstrate AI player capabilities"""
	var demo_player = kiosk_manager.demo_player

	print("AI Player Configuration:")
	print("  Difficulty: %s" % ["Beginner", "Intermediate", "Expert"][demo_player.difficulty])
	print("  Reaction time: %.2fs" % demo_player.config.reaction_time)
	print("  Aggression factor: %.1f" % demo_player.config.aggression_factor)
	print("  Spatial awareness: %.0f pixels" % demo_player.config.spatial_awareness)

	print("\nAI Capabilities:")
	print("  • Spatial partitioning for threat detection")
	print("  • Predictive trajectory analysis")
	print("  • Priority-based decision making")
	print("  • Strategic weapon switching")
	print("  • Smart powerup collection")
	print("  • Tactical bomb deployment")

	print("\nVirtual Input System:")
	print("  • Injects synthetic input events")
	print("  • Human-like reaction delays")
	print("  • Marked as AI-generated for filtering")
	print("  • Compatible with existing Player.gd")

func _demo_attract_screens():
	"""Demonstrate attract screen system"""
	var attract_manager = kiosk_manager.attract_screen_manager

	print("Attract Screen Configuration:")
	print("  Total screens: %d" % attract_manager.get_screen_count())
	print("  Transition duration: %.1fs" % attract_manager.transition_duration)

	print("\nScreen Types:")
	var screen_types = ["Logo/Branding", "Gameplay Features", "High Scores", "Instructions", "Custom Content"]
	for i in range(screen_types.size()):
		print("  • %s" % screen_types[i])

	print("\nVisual Effects:")
	print("  • Smooth fade transitions")
	print("  • Animated text reveals")
	print("  • Floating particle effects")
	print("  • Pulsing and glowing elements")
	print("  • Professional color schemes")

func _demo_configuration_system():
	"""Demonstrate configuration flexibility"""
	print("Deployment Presets:")
	var config = kiosk_manager.config
	var presets = config.deployment_presets

	for preset_name in presets:
		var preset = presets[preset_name]
		print("  %s:" % preset_name.capitalize())
		print("    - Input timeout: %.0fs" % preset.input_timeout)
		print("    - Demo length: %.0fs" % preset.demo_session_length)
		print("    - Difficulty: %s" % preset.difficulty_preset)
		print("    - Auto-transition: %s" % ("Yes" if preset.auto_transition else "No"))

	print("\nConfigurable Parameters:")
	print("  • Input sensitivity and timeouts")
	print("  • AI difficulty and behavior")
	print("  • Screen timing and transitions")
	print("  • Visual effects and animations")
	print("  • Audio settings and volume")
	print("  • Security and access controls")

func _demo_kiosk_mode():
	"""Demonstrate kiosk mode state transitions"""
	print("Kiosk State Machine:")
	var states = ["DISABLED", "ATTRACT", "DEMO_PLAYING", "HIGH_SCORES", "TRANSITIONING"]
	for state in states:
		print("  • %s - %s" % [state, _get_state_description(state)])

	print("\nCurrent State: %s" % kiosk_manager.get_current_state())

	print("\nState Transition Flow:")
	print("  1. User inactivity detected")
	print("  2. Enter ATTRACT mode (cycling screens)")
	print("  3. Transition to DEMO_PLAYING (AI gameplay)")
	print("  4. Show HIGH_SCORES if achieved")
	print("  5. Return to ATTRACT mode")
	print("  6. Any user input immediately exits to DISABLED")

func _demo_performance_stats():
	"""Show performance and system information"""
	print("System Performance:")

	var high_score_info = kiosk_manager.high_score_manager.get_system_info()
	print("  High Score System:")
	print("    - Total scores: %d" % high_score_info.total_scores)
	print("    - Storage capacity: %d" % high_score_info.max_capacity)
	print("    - Validation enabled: %s" % ("Yes" if high_score_info.validation_enabled else "No"))
	print("    - File path: %s" % high_score_info.file_path)

	var demo_stats = kiosk_manager.demo_player.get_performance_stats()
	print("  AI Performance:")
	print("    - Session time: %.1fs" % demo_stats.survival_time)
	print("    - Total shots: %d" % demo_stats.total_shots_fired)
	print("    - Accuracy: %.1f%%" % (demo_stats.shots_hit * 100.0 / max(1, demo_stats.total_shots_fired)))
	print("    - Final score: %d" % demo_stats.final_score)

func _get_state_description(state: String) -> String:
	"""Get description for kiosk states"""
	match state:
		"DISABLED":
			return "Normal game mode, kiosk inactive"
		"ATTRACT":
			return "Cycling promotional screens"
		"DEMO_PLAYING":
			return "AI demonstrating gameplay"
		"HIGH_SCORES":
			return "Displaying leaderboard"
		"TRANSITIONING":
			return "Smooth transition between modes"
		_:
			return "Unknown state"

# Signal handlers
func _on_kiosk_state_changed(new_state: String):
	"""Handle kiosk state changes"""
	print("    State changed to: %s" % new_state)

func _on_demo_session_started():
	"""Handle demo session start"""
	print("    AI demo session started")

func _on_demo_session_ended():
	"""Handle demo session end"""
	print("    AI demo session completed")

func _on_high_score_achieved(score: int, rank: int):
	"""Handle high score achievement"""
	print("    High score achieved: %d (rank %d)" % [score, rank])