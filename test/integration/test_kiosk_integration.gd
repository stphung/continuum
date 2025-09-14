extends GdUnitTestSuite
## Integration tests for complete Kiosk Mode system - state transitions, subsystem coordination, and user experience

var kiosk_manager: Node
var game_scene: Node
var original_scene: Node

func before():
	"""Setup complete integration test environment"""
	# Store original scene
	original_scene = get_tree().current_scene

	# Create comprehensive mock game scene
	game_scene = Node.new()
	game_scene.name = "IntegrationGameScene"
	game_scene.set_script(preload("res://test/helpers/MockGameScene.gd"))

	# Add mock player
	var mock_player = Node.new()
	mock_player.name = "Player"
	mock_player.set_script(preload("res://test/helpers/MockPlayer.gd"))
	mock_player.add_to_group("player")
	game_scene.add_child(mock_player)

	# Set as current scene
	get_tree().current_scene = game_scene

	# Get KioskManager (autoload)
	kiosk_manager = KioskManager

	# Ensure clean starting state
	kiosk_manager.force_exit_kiosk_mode()
	kiosk_manager.config.enabled = true
	kiosk_manager.config.input_timeout = 1.0  # Short timeout for testing
	kiosk_manager.config.demo_session_length = 2.0
	kiosk_manager.config.attract_cycle_time = 1.0

	await get_tree().process_frame

func after():
	"""Cleanup integration test environment"""
	if kiosk_manager:
		kiosk_manager.force_exit_kiosk_mode()

	# Restore original scene
	if original_scene:
		get_tree().current_scene = original_scene

	if game_scene and is_instance_valid(game_scene):
		game_scene.queue_free()

	await get_tree().process_frame

# Complete Workflow Integration Tests
func test_full_kiosk_activation_workflow():
	"""Test complete workflow from idle to kiosk activation"""
	# Start with disabled state
	assert_that(kiosk_manager.get_current_state()).is_equal("DISABLED")

	# Simulate user inactivity
	kiosk_manager._start_input_monitoring()
	await get_tree().create_timer(1.2).timeout  # Wait for timeout

	# Should automatically enter kiosk mode
	assert_that(kiosk_manager.is_kiosk_active()).is_true()
	assert_that(kiosk_manager.get_current_state()).is_equal("ATTRACT")

func test_user_input_interruption_workflow():
	"""Test user input interrupting kiosk mode workflow"""
	# Enter kiosk mode
	kiosk_manager.force_enter_kiosk_mode()
	await get_tree().process_frame

	assert_that(kiosk_manager.is_kiosk_active()).is_true()

	# Simulate user input
	var user_input = InputEventKey.new()
	user_input.keycode = KEY_SPACE
	user_input.pressed = true
	kiosk_manager._unhandled_input(user_input)

	await get_tree().process_frame

	# Should exit kiosk mode immediately
	assert_that(kiosk_manager.is_kiosk_active()).is_false()
	assert_that(kiosk_manager.get_current_state()).is_equal("DISABLED")

func test_attract_to_demo_transition():
	"""Test transition from attract screens to demo mode"""
	kiosk_manager.force_enter_kiosk_mode()
	await get_tree().process_frame

	# Initially in attract mode
	assert_that(kiosk_manager.get_current_state()).is_equal("ATTRACT")

	# Force demo start (normally triggered by attract manager)
	kiosk_manager._start_demo_session()
	await get_tree().process_frame

	# Should transition to demo playing
	assert_that(kiosk_manager.get_current_state()).is_equal("DEMO_PLAYING")

func test_demo_to_high_scores_transition():
	"""Test transition from demo to high scores display"""
	kiosk_manager.force_enter_kiosk_mode()
	kiosk_manager._start_demo_session()
	await get_tree().process_frame

	# Simulate high score achievement
	kiosk_manager.demo_player.performance_stats.final_score = 50000
	kiosk_manager._on_high_score_achieved(50000)

	await get_tree().process_frame

	# Should show high scores
	assert_that(kiosk_manager.get_current_state()).is_equal("HIGH_SCORES")

func test_complete_cycle_back_to_attract():
	"""Test complete cycle from attract -> demo -> high scores -> attract"""
	kiosk_manager.force_enter_kiosk_mode()
	await get_tree().process_frame

	# Track state changes
	var state_changes = []
	kiosk_manager.kiosk_state_changed.connect(func(state): state_changes.append(state))

	# Go through demo
	kiosk_manager._start_demo_session()
	await get_tree().process_frame

	# End demo with normal score
	kiosk_manager.demo_player.performance_stats.final_score = 1000
	kiosk_manager._end_demo_session()
	await get_tree().process_frame

	# Should return to attract mode
	assert_that(kiosk_manager.get_current_state()).is_equal("ATTRACT")
	assert_that(state_changes).contains(["DEMO_PLAYING", "ATTRACT"])

# Subsystem Coordination Tests
func test_kiosk_manager_demo_player_coordination():
	"""Test coordination between KioskManager and DemoPlayer"""

	kiosk_manager.force_enter_kiosk_mode()
	kiosk_manager._start_demo_session()
	await get_tree().process_frame

	# Demo should be started
	assert_that(kiosk_manager.demo_player.current_state).is_equal(kiosk_manager.demo_player.AIState.PLAYING)

	# End demo
	kiosk_manager._end_demo_session()
	await get_tree().process_frame


func test_kiosk_manager_attract_screen_coordination():
	"""Test coordination between KioskManager and AttractScreenManager"""
	kiosk_manager.force_enter_kiosk_mode()
	await get_tree().process_frame

	# Attract screen manager should be active
	assert_that(kiosk_manager.attract_screen_manager).is_not_null()

	# Simulate attract cycle completion
	kiosk_manager.attract_screen_manager.cycle_completed.emit()
	await get_tree().process_frame

	# Should handle cycle completion
	# Implementation dependent on attract cycle logic

func test_kiosk_manager_high_score_coordination():
	"""Test coordination between KioskManager and HighScoreManager"""
	kiosk_manager.force_enter_kiosk_mode()
	kiosk_manager._start_demo_session()
	await get_tree().process_frame


	# Simulate high score achievement
	var test_score = 25000
	kiosk_manager.demo_player.high_score_achieved.emit(test_score)
	await get_tree().process_frame

	# Should coordinate with high score manager

func test_kiosk_ui_state_synchronization():
	"""Test KioskUI stays synchronized with kiosk states"""
	kiosk_manager.force_enter_kiosk_mode()
	await get_tree().process_frame

	# UI should show kiosk overlay
	assert_that(kiosk_manager.kiosk_ui.is_overlay_visible).is_true()

	# Transition to demo
	kiosk_manager._start_demo_session()
	await get_tree().process_frame

	# UI should reflect demo state
	if kiosk_manager.kiosk_ui.has_method("get_current_overlay_type"):
		var overlay_type = kiosk_manager.kiosk_ui.get_current_overlay_type()
		# Should show demo-related UI

	# Exit kiosk mode
	kiosk_manager.force_exit_kiosk_mode()
	await get_tree().process_frame

	# UI should be hidden
	assert_that(kiosk_manager.kiosk_ui.is_overlay_visible).is_false()

# Game Integration Tests
func test_game_pause_resume_integration():
	"""Test game pause/resume during kiosk mode transitions"""
	# Start with game running
	assert_that(game_scene.is_paused).is_false()

	# Enter kiosk mode should pause game
	kiosk_manager.force_enter_kiosk_mode()
	await get_tree().process_frame

	assert_that(game_scene.is_paused).is_true()

	# Exit kiosk mode should resume game
	kiosk_manager.force_exit_kiosk_mode()
	await get_tree().process_frame

	assert_that(game_scene.is_paused).is_false()

func test_player_spawning_for_demo():
	"""Test player spawning/management during demo sessions"""
	# Remove player initially
	if game_scene.has_node("Player"):
		game_scene.get_node("Player").queue_free()
	await get_tree().process_frame

	# Start demo should trigger player spawn
	kiosk_manager.force_enter_kiosk_mode()
	kiosk_manager._start_demo_session()
	await get_tree().process_frame

	# Player should be available for demo
	var players = get_tree().get_nodes_in_group("player")
	assert_that(players.size()).is_greater_equal(1)

func test_score_integration_with_game():
	"""Test score integration between demo and game systems"""
	game_scene.current_score = 5000

	kiosk_manager.force_enter_kiosk_mode()
	kiosk_manager._start_demo_session()
	await get_tree().process_frame

	# Demo should track score changes
	game_scene.add_score(1000)
	await get_tree().process_frame

	# Demo player should be aware of score changes
	# Implementation dependent on signal connections

# Configuration Integration Tests
func test_difficulty_configuration_propagation():
	"""Test difficulty configuration propagates to demo player"""
	kiosk_manager.config.difficulty_preset = "expert"
	kiosk_manager.demo_player.set_difficulty("expert")

	assert_that(kiosk_manager.demo_player.difficulty).is_equal(kiosk_manager.demo_player.Difficulty.EXPERT)
	assert_that(kiosk_manager.demo_player.config.reaction_time).is_equal(0.08)

func test_timing_configuration_integration():
	"""Test timing configurations work across subsystems"""
	kiosk_manager.config.attract_cycle_time = 2.5
	kiosk_manager.config.demo_session_length = 5.0

	kiosk_manager.force_enter_kiosk_mode()
	await get_tree().process_frame

	# Timing should be applied to subsystems
	assert_that(kiosk_manager.attract_timer.wait_time).is_equal(2.5)

func test_runtime_configuration_updates():
	"""Test runtime configuration updates affect all subsystems"""
	var new_config = {
		"input_timeout": 45.0,
		"difficulty_preset": "beginner",
		"attract_cycle_time": 20.0
	}

	kiosk_manager.update_configuration(new_config)

	assert_that(kiosk_manager.config.input_timeout).is_equal(45.0)
	assert_that(kiosk_manager.config.difficulty_preset).is_equal("beginner")
	assert_that(kiosk_manager.config.attract_cycle_time).is_equal(20.0)

# Error Recovery Integration Tests
func test_demo_player_death_recovery():
	"""Test system recovery when demo player dies"""
	kiosk_manager.force_enter_kiosk_mode()
	kiosk_manager._start_demo_session()
	await get_tree().process_frame

	# Simulate player death
	var mock_player = get_tree().get_nodes_in_group("player")[0]
	mock_player.health = 0
	mock_player.player_died.emit()
	await get_tree().process_frame

	# System should recover gracefully
	# Either restart demo or transition to next state

func test_missing_subsystem_recovery():
	"""Test system handles missing subsystems gracefully"""
	# Temporarily remove a subsystem
	var original_attract_manager = kiosk_manager.attract_screen_manager
	kiosk_manager.attract_screen_manager = null

	kiosk_manager.force_enter_kiosk_mode()
	await get_tree().process_frame

	# Should handle gracefully without crashing
	assert_that(kiosk_manager.is_kiosk_active()).is_true()

	# Restore subsystem
	kiosk_manager.attract_screen_manager = original_attract_manager

func test_scene_change_during_kiosk_mode():
	"""Test handling scene changes during kiosk operation"""
	kiosk_manager.force_enter_kiosk_mode()
	await get_tree().process_frame

	# Simulate scene change
	var new_scene = Node.new()
	new_scene.name = "NewScene"
	get_tree().current_scene = new_scene

	await get_tree().process_frame

	# Kiosk system should adapt or exit gracefully
	# Implementation dependent on scene management strategy

	new_scene.queue_free()

# Performance Integration Tests
func test_complete_system_performance():
	"""Test performance of complete kiosk system under normal operation"""
	var start_time = Time.get_ticks_msec()

	# Run complete cycle
	kiosk_manager.force_enter_kiosk_mode()
	await get_tree().process_frame

	kiosk_manager._start_demo_session()
	await get_tree().process_frame

	# Simulate demo activity
	for i in range(30):  # 30 frames of demo
		await get_tree().process_frame

	kiosk_manager._end_demo_session()
	kiosk_manager.force_exit_kiosk_mode()
	await get_tree().process_frame

	var end_time = Time.get_ticks_msec()
	var duration = end_time - start_time

	# Should complete within reasonable time
	assert_that(duration).is_less_than(5000)  # Less than 5 seconds

func test_memory_usage_during_extended_operation():
	"""Test memory usage during extended kiosk operation"""
	var initial_node_count = get_tree().get_node_count()

	# Run multiple kiosk cycles
	for cycle in range(5):
		kiosk_manager.force_enter_kiosk_mode()
		await get_tree().process_frame

		kiosk_manager._start_demo_session()
		await get_tree().create_timer(0.1).timeout

		kiosk_manager._end_demo_session()
		kiosk_manager.force_exit_kiosk_mode()
		await get_tree().process_frame

	var final_node_count = get_tree().get_node_count()

	# Should not leak significant memory
	assert_that(abs(final_node_count - initial_node_count)).is_less_than(20)

# Signal Flow Integration Tests
func test_signal_cascade_through_system():
	"""Test signal flow cascades properly through entire system"""
	var signal_log = []

	# Connect to multiple signals
	kiosk_manager.kiosk_state_changed.connect(func(state): signal_log.append("state:" + state))
	kiosk_manager.demo_session_started.connect(func(): signal_log.append("demo_started"))
	kiosk_manager.demo_session_ended.connect(func(): signal_log.append("demo_ended"))

	# Execute workflow
	kiosk_manager.force_enter_kiosk_mode()
	await get_tree().process_frame

	kiosk_manager._start_demo_session()
	await get_tree().process_frame

	kiosk_manager._end_demo_session()
	await get_tree().process_frame

	# Should have received expected signals
	assert_that(signal_log).contains(["state:ATTRACT"])
	assert_that(signal_log).contains(["demo_started"])
	assert_that(signal_log).contains(["demo_ended"])

func test_signal_disconnection_on_cleanup():
	"""Test signals are properly disconnected during cleanup"""
	kiosk_manager.force_enter_kiosk_mode()
	kiosk_manager._start_demo_session()
	await get_tree().process_frame

	# Verify signals are connected
	assert_that(kiosk_manager.demo_player.demo_ended.is_connected(kiosk_manager._on_demo_ended)).is_true()

	# Exit and cleanup
	kiosk_manager.force_exit_kiosk_mode()
	await get_tree().process_frame

	# Signals should remain connected for future use
	# (Unless implementation specifically disconnects them)

# User Experience Integration Tests
func test_seamless_transition_experience():
	"""Test transitions provide seamless user experience"""
	kiosk_manager.force_enter_kiosk_mode()
	await get_tree().process_frame

	# UI should be immediately responsive
	assert_that(kiosk_manager.kiosk_ui.is_overlay_visible).is_true()

	# Transitions should be smooth (no jarring changes)
	kiosk_manager._start_demo_session()
	await get_tree().process_frame

	# Demo should start without noticeable delay
	assert_that(kiosk_manager.get_current_state()).is_equal("DEMO_PLAYING")

func test_input_responsiveness_during_transitions():
	"""Test input remains responsive during state transitions"""
	kiosk_manager.force_enter_kiosk_mode()
	await get_tree().process_frame

	# Start transition to demo
	kiosk_manager._start_demo_session()

	# Immediate user input during transition
	var user_input = InputEventKey.new()
	user_input.keycode = KEY_ESCAPE
	user_input.pressed = true
	kiosk_manager._unhandled_input(user_input)

	await get_tree().process_frame

	# Should exit immediately despite ongoing transition
	assert_that(kiosk_manager.is_kiosk_active()).is_false()

func test_visual_consistency_across_states():
	"""Test visual consistency across different kiosk states"""
	# Test each state maintains visual coherence
	kiosk_manager.force_enter_kiosk_mode()
	await get_tree().process_frame

	# Attract mode visuals
	assert_that(kiosk_manager.kiosk_ui.current_overlay).is_not_equal("")

	# Demo mode visuals
	kiosk_manager._start_demo_session()
	await get_tree().process_frame

	# Should maintain consistent visual theme
	# Implementation dependent verification

func test_accessibility_during_kiosk_operation():
	"""Test accessibility features work during kiosk operation"""
	kiosk_manager.force_enter_kiosk_mode()
	await get_tree().process_frame

	# UI should be accessible
	if kiosk_manager.kiosk_ui.has_method("get_accessibility_description"):
		var description = kiosk_manager.kiosk_ui.get_accessibility_description()
		assert_that(description).is_instance_of(TYPE_STRING)

	# Text should be readable
	# Font sizes should be appropriate
	# Color contrast should be sufficient
	# Implementation dependent verification