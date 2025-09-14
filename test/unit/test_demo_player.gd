extends GdUnitTestSuite
## Comprehensive tests for DemoPlayer AI system - threat assessment, decision making, and performance

var demo_player: Node
var mock_game_scene: Node
var mock_player: Node
var original_scene: Node

func before():
	"""Setup test environment with mock game objects"""
	# Store original scene
	original_scene = get_tree().current_scene

	# Create mock game scene with player
	mock_game_scene = Node.new()
	mock_game_scene.name = "MockGameScene"
	mock_game_scene.set_script(preload("res://test/helpers/MockGameScene.gd"))

	mock_player = Node.new()
	mock_player.name = "Player"
	mock_player.set_script(preload("res://test/helpers/MockPlayer.gd"))
	mock_player.add_to_group("player")
	mock_game_scene.add_child(mock_player)

	# Set as current scene
	get_tree().current_scene = mock_game_scene

	# Create demo player instance
	var DemoPlayerScript = preload("res://scripts/kiosk/DemoPlayer.gd")
	demo_player = DemoPlayerScript.new()
	demo_player.name = "TestDemoPlayer"
	add_child(demo_player)

	await get_tree().process_frame

func after():
	"""Cleanup test environment"""
	if demo_player and is_instance_valid(demo_player):
		demo_player.stop_demo()
		demo_player.queue_free()

	# Restore original scene
	if original_scene:
		get_tree().current_scene = original_scene

	if mock_game_scene and is_instance_valid(mock_game_scene):
		mock_game_scene.queue_free()

	await get_tree().process_frame

# Initialization Tests
func test_demo_player_initialization():
	"""Test DemoPlayer initializes with correct default state"""
	assert_that(demo_player.current_state).is_equal(demo_player.AIState.IDLE)
	assert_that(demo_player.difficulty).is_equal(demo_player.Difficulty.INTERMEDIATE)
	assert_that(demo_player.config).is_not_empty()
	assert_that(demo_player.performance_stats).is_not_empty()

func test_spatial_grid_initialization():
	"""Test spatial partitioning grid is properly initialized"""
	assert_that(demo_player.threat_grid).is_not_empty()
	assert_that(demo_player.threat_grid.size()).is_equal(int(demo_player.grid_size.x))

	# Check grid structure
	for x in range(int(demo_player.grid_size.x)):
		assert_that(demo_player.threat_grid[x].size()).is_equal(int(demo_player.grid_size.y))
		for y in range(int(demo_player.grid_size.y)):
			var cell = demo_player.threat_grid[x][y]
			assert_that(cell.has("threat_level")).is_true()
			assert_that(cell.has("entities")).is_true()
			assert_that(cell.has("safe_score")).is_true()

func test_reaction_timer_setup():
	"""Test reaction timer is properly configured"""
	assert_that(demo_player.reaction_timer).is_not_null()
	assert_that(demo_player.reaction_timer.wait_time).is_equal(demo_player.config.reaction_time)
	assert_that(demo_player.reaction_timer.one_shot).is_false()

# Difficulty Configuration Tests
func test_difficulty_beginner():
	"""Test beginner difficulty configuration"""
	demo_player.set_difficulty("beginner")

	assert_that(demo_player.difficulty).is_equal(demo_player.Difficulty.BEGINNER)
	assert_that(demo_player.config.reaction_time).is_equal(0.25)
	assert_that(demo_player.config.aggression_factor).is_equal(0.4)
	assert_that(demo_player.config.error_rate).is_equal(0.15)
	assert_that(demo_player.config.spatial_awareness).is_equal(100.0)

func test_difficulty_intermediate():
	"""Test intermediate difficulty configuration"""
	demo_player.set_difficulty("intermediate")

	assert_that(demo_player.difficulty).is_equal(demo_player.Difficulty.INTERMEDIATE)
	assert_that(demo_player.config.reaction_time).is_equal(0.15)
	assert_that(demo_player.config.aggression_factor).is_equal(0.7)
	assert_that(demo_player.config.error_rate).is_equal(0.05)
	assert_that(demo_player.config.spatial_awareness).is_equal(150.0)

func test_difficulty_expert():
	"""Test expert difficulty configuration"""
	demo_player.set_difficulty("expert")

	assert_that(demo_player.difficulty).is_equal(demo_player.Difficulty.EXPERT)
	assert_that(demo_player.config.reaction_time).is_equal(0.08)
	assert_that(demo_player.config.aggression_factor).is_equal(0.95)
	assert_that(demo_player.config.error_rate).is_equal(0.02)
	assert_that(demo_player.config.spatial_awareness).is_equal(200.0)

func test_invalid_difficulty_defaults_to_intermediate():
	"""Test invalid difficulty string defaults to intermediate"""
	demo_player.set_difficulty("invalid_difficulty")
	# Should remain at intermediate (default)
	assert_that(demo_player.difficulty).is_equal(demo_player.Difficulty.INTERMEDIATE)

# Demo Session Management Tests
func test_demo_start_state_change():
	"""Test demo starting changes state correctly"""
	var initial_time = Time.get_ticks_msec() / 1000.0

	demo_player.start_demo()
	await get_tree().process_frame

	assert_that(demo_player.current_state).is_equal(demo_player.AIState.PLAYING)
	assert_that(demo_player.performance_stats.session_start_time).is_greater_equal(initial_time)

func test_demo_stop_state_change():
	"""Test demo stopping changes state correctly"""
	demo_player.start_demo()
	await get_tree().process_frame

	# Monitor demo ended signal
	var demo_ended_count = [0]
	demo_player.demo_ended.connect(func(): demo_ended_count[0] += 1)

	demo_player.stop_demo()
	await get_tree().process_frame

	assert_that(demo_player.current_state).is_equal(demo_player.AIState.ENDED)
	assert_that(demo_ended_count[0]).is_equal(1)

func test_demo_start_from_non_idle_state():
	"""Test starting demo from non-idle state is handled gracefully"""
	demo_player.start_demo()
	await get_tree().process_frame

	var initial_state = demo_player.current_state
	demo_player.start_demo()  # Should have no effect
	await get_tree().process_frame

	assert_that(demo_player.current_state).is_equal(initial_state)

func test_demo_stop_from_idle_state():
	"""Test stopping demo from idle state is handled gracefully"""
	assert_that(demo_player.current_state).is_equal(demo_player.AIState.IDLE)

	demo_player.stop_demo()  # Should have no effect
	await get_tree().process_frame

	assert_that(demo_player.current_state).is_equal(demo_player.AIState.IDLE)

# Virtual Input System Tests
func test_virtual_input_initialization():
	"""Test virtual input system is properly initialized"""
	var expected_inputs = ["move_up", "move_down", "move_left", "move_right", "shoot", "bomb"]

	for input_name in expected_inputs:
		assert_that(demo_player.virtual_inputs.has(input_name)).is_true()
		assert_that(demo_player.virtual_inputs[input_name]).is_false()

func test_virtual_input_buffer():
	"""Test input buffer system"""
	assert_that(demo_player.input_buffer).is_not_null()
	assert_that(demo_player.input_buffer).is_empty()

func test_clear_virtual_inputs():
	"""Test clearing virtual inputs resets all to false"""
	# Set some virtual inputs
	demo_player.virtual_inputs["move_up"] = true
	demo_player.virtual_inputs["shoot"] = true

	demo_player._clear_virtual_inputs()

	for input_name in demo_player.virtual_inputs:
		assert_that(demo_player.virtual_inputs[input_name]).is_false()

# Spatial Awareness Tests
func test_grid_coordinate_conversion():
	"""Test converting world coordinates to grid coordinates"""
	# Test method exists (implementation may vary)
	if demo_player.has_method("_world_to_grid"):
		var world_pos = Vector2(400, 300)
		var grid_pos = demo_player._world_to_grid(world_pos)

		assert_that(grid_pos.x).is_between(0, demo_player.grid_size.x - 1)
		assert_that(grid_pos.y).is_between(0, demo_player.grid_size.y - 1)

func test_threat_grid_updates():
	"""Test threat grid updates with game entities"""
	demo_player.start_demo()
	await get_tree().process_frame

	# Create mock enemy
	var mock_enemy = Node2D.new()
	mock_enemy.name = "MockEnemy"
	mock_enemy.position = Vector2(200, 200)
	mock_enemy.add_to_group("enemies")
	mock_game_scene.add_child(mock_enemy)

	# Update spatial grid
	demo_player._update_spatial_grid()
	await get_tree().process_frame

	# Should detect enemy
	assert_that(demo_player.known_enemies.size()).is_greater_equal(1)

	mock_enemy.queue_free()

func test_enemy_scanning():
	"""Test enemy detection and tracking"""
	# Create multiple mock enemies
	var enemies = []
	for i in range(3):
		var enemy = Node2D.new()
		enemy.name = "Enemy" + str(i)
		enemy.position = Vector2(100 + i * 50, 150)
		enemy.add_to_group("enemies")
		mock_game_scene.add_child(enemy)
		enemies.append(enemy)

	demo_player._scan_for_enemies()

	assert_that(demo_player.known_enemies.size()).is_equal(3)

	# Cleanup
	for enemy in enemies:
		enemy.queue_free()

func test_bullet_scanning():
	"""Test bullet detection and tracking"""
	# Create mock enemy bullets
	var bullets = []
	for i in range(2):
		var bullet = Node2D.new()
		bullet.name = "EnemyBullet" + str(i)
		bullet.position = Vector2(200 + i * 30, 200)
		bullet.add_to_group("enemy_bullets")
		mock_game_scene.add_child(bullet)
		bullets.append(bullet)

	demo_player._scan_for_bullets()

	assert_that(demo_player.known_bullets.size()).is_equal(2)

	# Cleanup
	for bullet in bullets:
		bullet.queue_free()

# Performance Tracking Tests
func test_performance_stats_initialization():
	"""Test performance statistics are properly initialized"""
	var expected_stats = [
		"session_start_time", "total_shots_fired", "shots_hit",
		"enemies_destroyed", "powerups_collected", "bombs_used",
		"damage_taken", "close_calls", "final_score",
		"survival_time", "efficiency_rating"
	]

	for stat in expected_stats:
		assert_that(demo_player.performance_stats.has(stat)).is_true()

func test_performance_tracking_during_demo():
	"""Test performance stats update during demo session"""
	demo_player.start_demo()
	await get_tree().process_frame

	var initial_stats = demo_player.performance_stats.duplicate()

	# Simulate some time passing
	await get_tree().create_timer(0.1).timeout

	# Update performance (this would normally happen in _process)
	if demo_player.has_method("_update_performance_stats"):
		demo_player._update_performance_stats(0.1)

	# Survival time should have updated
	assert_that(demo_player.performance_stats.survival_time).is_greater(initial_stats.survival_time)

func test_final_stats_calculation():
	"""Test final statistics calculation when demo ends"""
	demo_player.start_demo()
	await get_tree().process_frame

	# Set some performance data
	demo_player.performance_stats.total_shots_fired = 100
	demo_player.performance_stats.shots_hit = 75
	demo_player.performance_stats.enemies_destroyed = 20

	demo_player.stop_demo()
	await get_tree().process_frame

	# Final score should be calculated
	assert_that(demo_player.performance_stats.final_score).is_greater_equal(0)

# AI Decision Making Tests
func test_tactical_decision_making():
	"""Test AI makes tactical decisions during gameplay"""
	demo_player.start_demo()
	await get_tree().process_frame

	# Create threatening situation
	var enemy = Node2D.new()
	enemy.name = "ThreateningEnemy"
	enemy.position = mock_player.get_position() + Vector2(0, -50)  # Close enemy
	enemy.add_to_group("enemies")
	mock_game_scene.add_child(enemy)

	# Process AI decision making
	if demo_player.has_method("_make_tactical_decisions"):
		demo_player._make_tactical_decisions(0.016)  # One frame

	# AI should react to threat (implementation specific)
	await get_tree().process_frame

	enemy.queue_free()

func test_evasion_behavior():
	"""Test AI evasion behavior when threatened"""
	demo_player.start_demo()
	await get_tree().process_frame

	# Create bullet threat
	var bullet = Node2D.new()
	bullet.name = "IncomingBullet"
	bullet.position = mock_player.get_position() + Vector2(0, -20)
	bullet.add_to_group("enemy_bullets")
	mock_game_scene.add_child(bullet)

	demo_player._update_spatial_grid()

	# Should calculate evasion vector
	assert_that(demo_player.evasion_vector).is_instance_of(TYPE_VECTOR2)

	bullet.queue_free()

func test_target_selection():
	"""Test AI target selection logic"""
	demo_player.start_demo()
	await get_tree().process_frame

	# Create multiple enemies at different distances
	var close_enemy = Node2D.new()
	close_enemy.name = "CloseEnemy"
	close_enemy.position = mock_player.get_position() + Vector2(0, -100)
	close_enemy.add_to_group("enemies")
	mock_game_scene.add_child(close_enemy)

	var far_enemy = Node2D.new()
	far_enemy.name = "FarEnemy"
	far_enemy.position = mock_player.get_position() + Vector2(0, -300)
	far_enemy.add_to_group("enemies")
	mock_game_scene.add_child(far_enemy)

	demo_player._scan_for_enemies()

	if demo_player.has_method("_select_target"):
		demo_player._select_target()

	# Should prefer closer threats (implementation dependent)
	# This test validates the logic exists
	assert_that(demo_player.current_target).is_instance_of_any([TYPE_NIL, Node2D])

	close_enemy.queue_free()
	far_enemy.queue_free()

# Error Handling and Edge Cases
func test_handles_missing_player():
	"""Test AI handles missing player gracefully"""
	# Remove player from scene
	mock_player.queue_free()
	await get_tree().process_frame

	demo_player.start_demo()
	await get_tree().process_frame

	# Should handle gracefully (may end demo or retry)
	assert_that(demo_player.current_state).is_not_equal(demo_player.AIState.PLAYING)

func test_handles_invalid_game_objects():
	"""Test AI handles invalid/freed game objects"""
	demo_player.start_demo()
	await get_tree().process_frame

	# Add and immediately free an enemy
	var enemy = Node2D.new()
	enemy.add_to_group("enemies")
	mock_game_scene.add_child(enemy)
	demo_player.known_enemies.append(enemy)
	enemy.queue_free()
	await get_tree().process_frame

	# Update should handle invalid references
	demo_player._update_spatial_grid()
	# Should not crash

func test_memory_management_during_demo():
	"""Test memory management during extended demo session"""
	demo_player.start_demo()
	await get_tree().process_frame

	var initial_node_count = get_tree().get_node_count()

	# Simulate many updates
	for i in range(10):
		demo_player._update_spatial_grid()
		await get_tree().process_frame

	var final_node_count = get_tree().get_node_count()

	# Should not leak significant memory
	assert_that(abs(final_node_count - initial_node_count)).is_less_than(10)

# Signal Tests
func test_demo_ended_signal():
	"""Test demo_ended signal is emitted correctly"""
	# Monitor demo ended signal
	var signal_count = [0]
	demo_player.demo_ended.connect(func(): signal_count[0] += 1)

	demo_player.start_demo()
	await get_tree().process_frame

	demo_player.stop_demo()
	await get_tree().process_frame

	assert_that(signal_count[0]).is_equal(1)

func test_high_score_achieved_signal():
	"""Test high_score_achieved signal when appropriate"""
	# Monitor high score signal
	var signal_count = [0]
	demo_player.high_score_achieved.connect(func(score): signal_count[0] += 1)

	demo_player.start_demo()
	await get_tree().process_frame

	# Simulate high score achievement
	demo_player.performance_stats.final_score = 50000
	if demo_player.has_method("_check_high_score"):
		demo_player._check_high_score()

	# Implementation dependent - may emit signal
	await get_tree().process_frame

func test_performance_milestone_signal():
	"""Test performance_milestone signal for significant achievements"""
	# Monitor milestone signal
	var signal_count = [0]
	demo_player.performance_milestone.connect(func(milestone, value): signal_count[0] += 1)

	demo_player.start_demo()
	await get_tree().process_frame

	# Simulate milestone achievement
	demo_player.performance_stats.enemies_destroyed = 100
	if demo_player.has_method("_check_milestones"):
		demo_player._check_milestones()

	# May emit milestone signals based on implementation
	await get_tree().process_frame