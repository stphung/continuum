extends GdUnitTestSuite

var enemy_manager: Node
var test_container: Node2D

func before():
	enemy_manager = EnemyManager
	test_container = Node2D.new()
	add_child(test_container)

func after():
	enemy_manager.reset_game_state()
	if test_container:
		test_container.queue_free()

func test_enemy_manager_initialization():
	enemy_manager.setup_for_game(test_container)

	assert_that(enemy_manager.enemies_container).is_equal(test_container)
	assert_that(enemy_manager.enemy_scene).is_not_null()

func test_wave_difficulty_scaling():
	enemy_manager.reset_game_state()

	# Wave 1 baseline
	var wave1_health = enemy_manager.get_enemy_health(1)
	var wave1_speed = enemy_manager.get_enemy_speed(1)
	var wave1_points = enemy_manager.get_enemy_points(1)

	# Wave 5 should be harder
	var wave5_health = enemy_manager.get_enemy_health(5)
	var wave5_speed = enemy_manager.get_enemy_speed(5)
	var wave5_points = enemy_manager.get_enemy_points(5)

	assert_that(wave5_health).is_greater(wave1_health)
	assert_that(wave5_speed).is_greater(wave1_speed)
	assert_that(wave5_points).is_greater(wave1_points)

func test_enemy_spawn_formation_line():
	enemy_manager.setup_for_game(test_container)
	enemy_manager.spawn_line_formation()

	# Allow spawn to complete
	await get_tree().create_timer(0.2).timeout

	var spawned_enemies = test_container.get_children()
	assert_that(spawned_enemies.size()).is_greater(0)

	# Verify line formation positioning (enemies should be spaced horizontally)
	if spawned_enemies.size() > 1:
		for i in range(spawned_enemies.size() - 1):
			var pos_diff = abs(spawned_enemies[i].position.x - spawned_enemies[i+1].position.x)
			assert_that(pos_diff).is_between(50.0, 150.0)  # Expected spacing

func test_enemy_spawn_formation_v_shape():
	enemy_manager.setup_for_game(test_container)
	enemy_manager.spawn_v_formation()

	# Allow spawn to complete
	await get_tree().create_timer(0.2).timeout

	var spawned_enemies = test_container.get_children()
	assert_that(spawned_enemies.size()).is_greater(0)

	# V formation should have enemies at different Y positions
	if spawned_enemies.size() > 2:
		var y_positions = []
		for enemy in spawned_enemies:
			y_positions.append(enemy.position.y)

		# Should have variation in Y positions for V shape
		y_positions.sort()
		assert_that(y_positions[0]).is_not_equal(y_positions[-1])

func test_enemy_spawn_random_burst():
	enemy_manager.setup_for_game(test_container)
	enemy_manager.spawn_random_burst()

	# Allow spawn to complete
	await get_tree().create_timer(0.2).timeout

	var spawned_enemies = test_container.get_children()
	assert_that(spawned_enemies.size()).is_between(3, 8)  # Random burst size

func test_wave_progression():
	enemy_manager.reset_game_state()
	assert_that(enemy_manager.current_wave).is_equal(1)

	enemy_manager.advance_wave()
	assert_that(enemy_manager.current_wave).is_equal(2)

	enemy_manager.advance_wave()
	assert_that(enemy_manager.current_wave).is_equal(3)

func test_game_state_reset():
	# Advance game state
	enemy_manager.current_wave = 5
	enemy_manager.enemies_spawned = 50

	# Reset should clear everything
	enemy_manager.reset_game_state()

	assert_that(enemy_manager.current_wave).is_equal(1)
	assert_that(enemy_manager.enemies_spawned).is_equal(0)

func test_spawn_delay_scaling():
	enemy_manager.reset_game_state()

	var wave1_delay = enemy_manager.get_spawn_delay(1)
	var wave5_delay = enemy_manager.get_spawn_delay(5)

	# Higher waves should spawn faster (shorter delay)
	assert_that(wave5_delay).is_less(wave1_delay)

func test_enemy_health_progression():
	# Test that enemy health increases with wave number
	var base_health = enemy_manager.get_enemy_health(1)

	for wave in range(2, 11):
		var wave_health = enemy_manager.get_enemy_health(wave)
		assert_that(wave_health).is_greater_equal(base_health)
		base_health = wave_health

func test_enemy_speed_progression():
	# Test that enemy speed increases with wave number
	var base_speed = enemy_manager.get_enemy_speed(1)

	for wave in range(2, 11):
		var wave_speed = enemy_manager.get_enemy_speed(wave)
		assert_that(wave_speed).is_greater_equal(base_speed)

func test_enemy_points_progression():
	# Test that enemy points increase with wave number
	var base_points = enemy_manager.get_enemy_points(1)

	for wave in range(2, 11):
		var wave_points = enemy_manager.get_enemy_points(wave)
		assert_that(wave_points).is_greater_equal(base_points)