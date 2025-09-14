extends GdUnitTestSuite
## Performance tests for DemoPlayer AI calculations - spatial partitioning, threat assessment, and decision making efficiency

var demo_player: Node
var mock_game_scene: Node
var mock_player: Node
var performance_data: Dictionary

func before():
	"""Setup performance test environment with controlled entity counts"""
	# Create test environment
	mock_game_scene = Node.new()
	mock_game_scene.name = "PerfTestGameScene"
	mock_game_scene.set_script(preload("res://test/helpers/MockGameScene.gd"))

	mock_player = Node.new()
	mock_player.name = "Player"
	mock_player.set_script(preload("res://test/helpers/MockPlayer.gd"))
	mock_player.add_to_group("player")
	mock_game_scene.add_child(mock_player)

	get_tree().current_scene = mock_game_scene

	# Create demo player
	var DemoPlayerScript = preload("res://scripts/kiosk/DemoPlayer.gd")
	demo_player = DemoPlayerScript.new()
	demo_player.name = "PerfTestDemoPlayer"
	add_child(demo_player)

	# Initialize performance tracking
	performance_data = {
		"frame_times": [],
		"spatial_update_times": [],
		"decision_making_times": [],
		"memory_usage": []
	}

	await get_tree().process_frame

func after():
	"""Cleanup performance test environment"""
	if demo_player and is_instance_valid(demo_player):
		demo_player.stop_demo()
		demo_player.queue_free()

	if mock_game_scene and is_instance_valid(mock_game_scene):
		mock_game_scene.queue_free()

	await get_tree().process_frame

# Spatial Grid Performance Tests
func test_spatial_grid_initialization_performance():
	"""Test spatial grid initialization performance with different grid sizes"""
	var start_time = Time.get_ticks_msec()

	demo_player.grid_size = Vector2(40, 45)  # Large grid
	demo_player._setup_spatial_grid()

	var end_time = Time.get_ticks_msec()
	var duration = end_time - start_time

	# Should initialize large grid within reasonable time
	assert_that(duration).is_less_than(100)  # Less than 100ms
	assert_that(demo_player.threat_grid.size()).is_equal(40)

func test_spatial_grid_update_performance_empty():
	"""Test spatial grid update performance with no entities"""
	demo_player.start_demo()
	await get_tree().process_frame

	var start_time = Time.get_ticks_usec()
	demo_player._update_spatial_grid()
	var end_time = Time.get_ticks_usec()

	var duration = end_time - start_time

	# Empty grid update should be very fast
	assert_that(duration).is_less_than(1000)  # Less than 1ms

func test_spatial_grid_update_performance_with_entities():
	"""Test spatial grid update performance with many entities"""
	demo_player.start_demo()
	await get_tree().process_frame

	# Create many enemies
	var enemies = []
	for i in range(100):
		var enemy = Node2D.new()
		enemy.name = "PerfEnemy" + str(i)
		enemy.position = Vector2(randf() * 800, randf() * 600)
		enemy.add_to_group("enemies")
		mock_game_scene.add_child(enemy)
		enemies.append(enemy)

	# Create many bullets
	var bullets = []
	for i in range(200):
		var bullet = Node2D.new()
		bullet.name = "PerfBullet" + str(i)
		bullet.position = Vector2(randf() * 800, randf() * 600)
		bullet.add_to_group("enemy_bullets")
		mock_game_scene.add_child(bullet)
		bullets.append(bullet)

	var start_time = Time.get_ticks_usec()
	demo_player._update_spatial_grid()
	var end_time = Time.get_ticks_usec()

	var duration = end_time - start_time

	# Should handle many entities efficiently
	assert_that(duration).is_less_than(5000)  # Less than 5ms

	# Cleanup
	for enemy in enemies:
		enemy.queue_free()
	for bullet in bullets:
		bullet.queue_free()

func test_threat_level_calculation_performance():
	"""Test threat level calculation performance across grid"""
	demo_player.start_demo()
	await get_tree().process_frame

	# Fill grid with entities
	for i in range(50):
		var enemy = Node2D.new()
		enemy.position = Vector2(randf() * 800, randf() * 600)
		enemy.add_to_group("enemies")
		mock_game_scene.add_child(enemy)

	demo_player._update_spatial_grid()

	var start_time = Time.get_ticks_usec()
	if demo_player.has_method("_calculate_threat_levels"):
		demo_player._calculate_threat_levels()
	var end_time = Time.get_ticks_usec()

	var duration = end_time - start_time

	# Threat calculation should be efficient
	assert_that(duration).is_less_than(3000)  # Less than 3ms

# Entity Scanning Performance Tests
func test_enemy_scanning_performance_scale():
	"""Test enemy scanning performance with increasing entity counts"""
	demo_player.start_demo()
	await get_tree().process_frame

	var test_counts = [10, 50, 100, 200]
	var scan_times = []

	for count in test_counts:
		# Create enemies
		var enemies = []
		for i in range(count):
			var enemy = Node2D.new()
			enemy.name = "ScanEnemy" + str(i)
			enemy.add_to_group("enemies")
			mock_game_scene.add_child(enemy)
			enemies.append(enemy)

		# Measure scanning time
		var start_time = Time.get_ticks_usec()
		demo_player._scan_for_enemies()
		var end_time = Time.get_ticks_usec()

		var duration = end_time - start_time
		scan_times.append(duration)

		# Cleanup
		for enemy in enemies:
			enemy.queue_free()
		await get_tree().process_frame

	# Scanning should scale reasonably (not exponentially)
	assert_that(scan_times[0]).is_less_than(1000)  # 10 entities < 1ms
	assert_that(scan_times[1]).is_less_than(2000)  # 50 entities < 2ms
	assert_that(scan_times[2]).is_less_than(4000)  # 100 entities < 4ms
	assert_that(scan_times[3]).is_less_than(8000)  # 200 entities < 8ms

func test_bullet_scanning_performance():
	"""Test bullet scanning performance with many projectiles"""
	demo_player.start_demo()
	await get_tree().process_frame

	# Create many bullets (simulating bullet hell scenario)
	var bullets = []
	for i in range(500):
		var bullet = Node2D.new()
		bullet.name = "PerfBullet" + str(i)
		bullet.add_to_group("enemy_bullets")
		mock_game_scene.add_child(bullet)
		bullets.append(bullet)

	var start_time = Time.get_ticks_usec()
	demo_player._scan_for_bullets()
	var end_time = Time.get_ticks_usec()

	var duration = end_time - start_time

	# Should handle many bullets efficiently
	assert_that(duration).is_less_than(10000)  # Less than 10ms for 500 bullets
	assert_that(demo_player.known_bullets.size()).is_equal(500)

	# Cleanup
	for bullet in bullets:
		bullet.queue_free()

func test_powerup_scanning_performance():
	"""Test powerup scanning performance"""
	demo_player.start_demo()
	await get_tree().process_frame

	# Create powerups
	var powerups = []
	for i in range(20):  # Fewer powerups is realistic
		var powerup = Node2D.new()
		powerup.name = "PerfPowerup" + str(i)
		powerup.add_to_group("powerups")
		mock_game_scene.add_child(powerup)
		powerups.append(powerup)

	var start_time = Time.get_ticks_usec()
	demo_player._scan_for_powerups()
	var end_time = Time.get_ticks_usec()

	var duration = end_time - start_time

	# Powerup scanning should be very fast
	assert_that(duration).is_less_than(1000)  # Less than 1ms

	# Cleanup
	for powerup in powerups:
		powerup.queue_free()

# Decision Making Performance Tests
func test_tactical_decision_performance():
	"""Test tactical decision making performance under load"""
	demo_player.start_demo()
	await get_tree().process_frame

	# Create complex scenario
	for i in range(30):
		var enemy = Node2D.new()
		enemy.position = Vector2(randf() * 800, randf() * 600)
		enemy.add_to_group("enemies")
		mock_game_scene.add_child(enemy)

	for i in range(100):
		var bullet = Node2D.new()
		bullet.position = Vector2(randf() * 800, randf() * 600)
		bullet.add_to_group("enemy_bullets")
		mock_game_scene.add_child(bullet)

	demo_player._update_spatial_grid()

	var start_time = Time.get_ticks_usec()
	if demo_player.has_method("_make_tactical_decisions"):
		demo_player._make_tactical_decisions(0.016)  # One frame
	var end_time = Time.get_ticks_usec()

	var duration = end_time - start_time

	# Decision making should complete within frame budget
	assert_that(duration).is_less_than(5000)  # Less than 5ms (30% of 16ms frame)

func test_threat_assessment_performance():
	"""Test threat assessment calculation performance"""
	demo_player.start_demo()
	await get_tree().process_frame

	# Create threatening scenario
	var threats = []
	for i in range(50):
		var threat = Node2D.new()
		threat.position = mock_player.position + Vector2(
			randf_range(-200, 200),
			randf_range(-200, 200)
		)
		threat.add_to_group("enemy_bullets")
		mock_game_scene.add_child(threat)
		threats.append(threat)

	demo_player._update_spatial_grid()

	var start_time = Time.get_ticks_usec()
	if demo_player.has_method("_assess_threats"):
		demo_player._assess_threats()
	var end_time = Time.get_ticks_usec()

	var duration = end_time - start_time

	# Threat assessment should be efficient
	assert_that(duration).is_less_than(3000)  # Less than 3ms

	# Cleanup
	for threat in threats:
		threat.queue_free()

func test_pathfinding_performance():
	"""Test AI pathfinding/evasion calculation performance"""
	demo_player.start_demo()
	await get_tree().process_frame

	# Create obstacle field
	for i in range(25):
		var obstacle = Node2D.new()
		obstacle.position = Vector2(randf() * 800, randf() * 600)
		obstacle.add_to_group("enemies")
		mock_game_scene.add_child(obstacle)

	demo_player._update_spatial_grid()

	var start_time = Time.get_ticks_usec()
	if demo_player.has_method("_calculate_evasion_path"):
		demo_player._calculate_evasion_path()
	var end_time = Time.get_ticks_usec()

	var duration = end_time - start_time

	# Pathfinding should be reasonably fast
	assert_that(duration).is_less_than(4000)  # Less than 4ms

# Memory Usage Performance Tests
func test_memory_usage_during_extended_demo():
	"""Test memory usage remains stable during extended demo sessions"""
	demo_player.start_demo()
	await get_tree().process_frame

	var initial_memory = OS.get_static_memory_peak_usage()

	# Simulate extended demo with many entities
	for frame in range(600):  # 10 seconds at 60 FPS
		# Add some entities
		if frame % 10 == 0:
			var enemy = Node2D.new()
			enemy.add_to_group("enemies")
			mock_game_scene.add_child(enemy)

		# Update AI systems
		demo_player._update_spatial_grid()
		await get_tree().process_frame

		# Remove some entities periodically
		if frame % 30 == 0:
			var enemies = get_tree().get_nodes_in_group("enemies")
			if enemies.size() > 20:
				enemies[0].queue_free()

	var final_memory = OS.get_static_memory_peak_usage()

	# Memory usage shouldn't grow significantly
	# This is a rough check as memory usage can vary
	var memory_growth = abs(final_memory - initial_memory)
	# Allow some growth but not excessive
	assert_that(memory_growth).is_less_than(1000000)  # Less than 1MB growth

func test_spatial_grid_memory_efficiency():
	"""Test spatial grid memory usage scales appropriately"""
	var small_grid_size = Vector2(10, 10)
	var large_grid_size = Vector2(50, 50)

	# Test small grid
	demo_player.grid_size = small_grid_size
	demo_player._setup_spatial_grid()
	var initial_node_count = get_tree().get_node_count()

	# Test large grid
	demo_player.grid_size = large_grid_size
	demo_player._setup_spatial_grid()
	var final_node_count = get_tree().get_node_count()

	# Grid size increase shouldn't create excessive nodes
	var node_growth = final_node_count - initial_node_count
	assert_that(node_growth).is_less_than(10)  # Grid data is in arrays, not nodes

# Frame Rate Performance Tests
func test_maintains_60fps_with_ai_load():
	"""Test AI maintains 60 FPS under typical game load"""
	demo_player.start_demo()
	await get_tree().process_frame

	# Create typical game scenario
	for i in range(20):  # 20 enemies
		var enemy = Node2D.new()
		enemy.position = Vector2(randf() * 800, randf() * 600)
		enemy.add_to_group("enemies")
		mock_game_scene.add_child(enemy)

	for i in range(80):  # 80 bullets
		var bullet = Node2D.new()
		bullet.position = Vector2(randf() * 800, randf() * 600)
		bullet.add_to_group("enemy_bullets")
		mock_game_scene.add_child(bullet)

	var frame_times = []
	var frames_tested = 60  # Test 1 second worth

	for frame in range(frames_tested):
		var frame_start = Time.get_ticks_usec()

		# Perform AI calculations
		demo_player._update_spatial_grid()
		if demo_player.has_method("_make_tactical_decisions"):
			demo_player._make_tactical_decisions(0.016)

		await get_tree().process_frame

		var frame_end = Time.get_ticks_usec()
		frame_times.append(frame_end - frame_start)

	# Calculate average frame time
	var total_time = 0
	for time in frame_times:
		total_time += time

	var avg_frame_time = total_time / frame_times.size()

	# Should maintain 60 FPS (16.67ms per frame)
	# AI should use only a fraction of frame budget
	assert_that(avg_frame_time).is_less_than(8000)  # Less than 8ms average (50% of frame)

func test_frame_distribution_consistency():
	"""Test AI processing time is distributed evenly across frames"""
	demo_player.start_demo()
	demo_player.config.reaction_time = 0.05  # Fast reactions for more processing
	await get_tree().process_frame

	# Create moderate load
	for i in range(30):
		var enemy = Node2D.new()
		enemy.add_to_group("enemies")
		mock_game_scene.add_child(enemy)

	var processing_times = []

	for frame in range(120):  # 2 seconds
		var start_time = Time.get_ticks_usec()
		demo_player._update_spatial_grid()
		var end_time = Time.get_ticks_usec()

		processing_times.append(end_time - start_time)
		await get_tree().process_frame

	# Calculate variance in processing times
	var avg_time = 0
	for time in processing_times:
		avg_time += time
	avg_time /= processing_times.size()

	var variance = 0
	for time in processing_times:
		variance += (time - avg_time) * (time - avg_time)
	variance /= processing_times.size()

	# Processing times should be relatively consistent
	# High variance indicates irregular performance spikes
	assert_that(variance).is_less_than(avg_time * avg_time)  # Variance < avg²

# Scalability Performance Tests
func test_ai_scalability_with_difficulty():
	"""Test AI performance scales with difficulty settings"""
	var difficulties = ["beginner", "intermediate", "expert"]
	var performance_times = {}

	for difficulty in difficulties:
		demo_player.set_difficulty(difficulty)
		demo_player.start_demo()
		await get_tree().process_frame

		# Create test scenario
		for i in range(40):
			var enemy = Node2D.new()
			enemy.add_to_group("enemies")
			mock_game_scene.add_child(enemy)

		var start_time = Time.get_ticks_usec()

		# Perform calculations
		demo_player._update_spatial_grid()
		if demo_player.has_method("_make_tactical_decisions"):
			demo_player._make_tactical_decisions(0.016)

		var end_time = Time.get_ticks_usec()
		performance_times[difficulty] = end_time - start_time

		demo_player.stop_demo()

		# Cleanup
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			enemy.queue_free()
		await get_tree().process_frame

	# Expert should not be significantly slower than beginner
	# All difficulties should maintain reasonable performance
	assert_that(performance_times["beginner"]).is_less_than(5000)  # 5ms
	assert_that(performance_times["intermediate"]).is_less_than(6000)  # 6ms
	assert_that(performance_times["expert"]).is_less_than(8000)  # 8ms

func test_concurrent_ai_instances_performance():
	"""Test performance with multiple AI instances (future-proofing)"""
	# Create additional AI instances
	var ai_instances = []
	for i in range(3):
		var ai = preload("res://scripts/kiosk/DemoPlayer.gd").new()
		ai.name = "AI" + str(i)
		add_child(ai)
		ai_instances.append(ai)

	# Start all instances
	for ai in ai_instances:
		ai.start_demo()
	await get_tree().process_frame

	# Create shared game scenario
	for i in range(60):
		var enemy = Node2D.new()
		enemy.add_to_group("enemies")
		mock_game_scene.add_child(enemy)

	var start_time = Time.get_ticks_usec()

	# Update all AI instances
	for ai in ai_instances:
		ai._update_spatial_grid()

	var end_time = Time.get_ticks_usec()
	var total_time = end_time - start_time

	# Multiple AI instances shouldn't cause excessive slowdown
	assert_that(total_time).is_less_than(15000)  # Less than 15ms total

	# Cleanup
	for ai in ai_instances:
		ai.stop_demo()
		ai.queue_free()

# Optimization Verification Tests
func test_spatial_partitioning_efficiency():
	"""Test spatial partitioning provides performance benefits"""
	demo_player.start_demo()
	await get_tree().process_frame

	# Create scattered entities
	for i in range(100):
		var enemy = Node2D.new()
		enemy.position = Vector2(randf() * 800, randf() * 600)
		enemy.add_to_group("enemies")
		mock_game_scene.add_child(enemy)

	# Time with spatial partitioning
	demo_player._update_spatial_grid()
	var start_time = Time.get_ticks_usec()

	if demo_player.has_method("_find_nearby_threats_spatial"):
		demo_player._find_nearby_threats_spatial(Vector2(400, 300), 100.0)

	var spatial_time = Time.get_ticks_usec() - start_time

	# Time with brute force (if implemented for comparison)
	start_time = Time.get_ticks_usec()

	if demo_player.has_method("_find_nearby_threats_brute_force"):
		demo_player._find_nearby_threats_brute_force(Vector2(400, 300), 100.0)

	var brute_force_time = Time.get_ticks_usec() - start_time

	# Spatial partitioning should be faster (if both methods exist)
	if brute_force_time > 0:
		assert_that(spatial_time).is_less_than(brute_force_time)

func test_caching_effectiveness():
	"""Test AI caching mechanisms improve performance"""
	demo_player.start_demo()
	await get_tree().process_frame

	# Create static scenario
	for i in range(50):
		var enemy = Node2D.new()
		enemy.position = Vector2(i * 16, 100)  # Organized line
		enemy.add_to_group("enemies")
		mock_game_scene.add_child(enemy)

	# First calculation (cache miss)
	var start_time = Time.get_ticks_usec()
	demo_player._update_spatial_grid()
	var first_time = Time.get_ticks_usec() - start_time

	# Second calculation (should use cache if implemented)
	start_time = Time.get_ticks_usec()
	demo_player._update_spatial_grid()
	var second_time = Time.get_ticks_usec() - start_time

	# Second time might be faster due to caching
	# This test verifies caching doesn't hurt performance
	assert_that(second_time).is_less_equal(first_time * 1.2)  # Within 20% of first time

# Regression Performance Tests
func test_performance_regression_baseline():
	"""Test establishes performance baseline for regression detection"""
	demo_player.start_demo()
	await get_tree().process_frame

	# Standard test scenario
	for i in range(25):
		var enemy = Node2D.new()
		enemy.add_to_group("enemies")
		mock_game_scene.add_child(enemy)

	for i in range(100):
		var bullet = Node2D.new()
		bullet.add_to_group("enemy_bullets")
		mock_game_scene.add_child(bullet)

	# Measure full AI cycle
	var start_time = Time.get_ticks_usec()

	demo_player._update_spatial_grid()
	if demo_player.has_method("_make_tactical_decisions"):
		demo_player._make_tactical_decisions(0.016)

	var end_time = Time.get_ticks_usec()
	var cycle_time = end_time - start_time

	# Establish baseline - adjust based on target hardware
	# This should be updated if AI algorithms improve
	assert_that(cycle_time).is_less_than(10000)  # 10ms baseline

	print("AI Performance Baseline: ", cycle_time, " microseconds")

func test_worst_case_performance():
	"""Test AI performance under worst-case scenario"""
	demo_player.set_difficulty("expert")  # Most complex AI
	demo_player.start_demo()
	await get_tree().process_frame

	# Worst case: maximum entities in close proximity
	var player_pos = mock_player.position

	for i in range(100):  # Maximum reasonable enemies
		var enemy = Node2D.new()
		enemy.position = player_pos + Vector2(
			randf_range(-150, 150),
			randf_range(-150, 150)
		)
		enemy.add_to_group("enemies")
		mock_game_scene.add_child(enemy)

	for i in range(300):  # Bullet hell scenario
		var bullet = Node2D.new()
		bullet.position = player_pos + Vector2(
			randf_range(-200, 200),
			randf_range(-200, 200)
		)
		bullet.add_to_group("enemy_bullets")
		mock_game_scene.add_child(bullet)

	var start_time = Time.get_ticks_usec()

	demo_player._update_spatial_grid()
	if demo_player.has_method("_make_tactical_decisions"):
		demo_player._make_tactical_decisions(0.016)

	var end_time = Time.get_ticks_usec()
	var worst_case_time = end_time - start_time

	# Even worst case should maintain playable performance
	assert_that(worst_case_time).is_less_than(16000)  # Less than one frame budget

	print("AI Worst Case Performance: ", worst_case_time, " microseconds")