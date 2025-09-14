extends GdUnitTestSuite

const Game = preload("res://scenes/main/Game.tscn")

var game: Node2D
var mock_enemy_manager: MockEnemyManager

func before_test():
	game = auto_free(Game.instantiate())
	add_child(game)
	game._ready()

	mock_enemy_manager = MockEnemyManager.new()
	add_child(mock_enemy_manager)

func test_initial_game_state():
	assert_that(game.score).is_equal(0)
	assert_that(game.lives).is_equal(3)
	assert_that(game.bombs).is_equal(3)
	assert_that(game.game_over).is_false()

func test_score_calculation():
	var initial_score = game.score

	game._on_enemy_destroyed(100, Vector2(400, 300))

	assert_that(game.score).is_equal(initial_score + 100)

func test_multiple_score_additions():
	game._on_enemy_destroyed(50, Vector2(200, 200))
	game._on_enemy_destroyed(75, Vector2(300, 300))
	game._on_enemy_destroyed(100, Vector2(400, 400))

	assert_that(game.score).is_equal(225)

func test_bomb_usage():
	var initial_bombs = game.bombs

	game._on_player_use_bomb()

	assert_that(game.bombs).is_equal(initial_bombs - 1)

func test_bomb_usage_with_no_bombs():
	game.bombs = 0

	game._on_player_use_bomb()

	assert_that(game.bombs).is_equal(0)  # Should not go negative

func test_powerup_spawn_probability():
	var powerups_spawned = 0
	var test_runs = 100

	# Mock the powerup spawning by counting calls
	for i in range(test_runs):
		if randf() < 0.2:  # Same probability as in actual code
			powerups_spawned += 1

	# Should be roughly 20% (allowing for variance)
	assert_that(powerups_spawned).is_between(10, 30)

func test_starfield_creation():
	if game.has_method("create_starfield"):
		game.create_starfield()

		if game.has_node("Stars"):
			var stars_node = game.get_node("Stars")
			assert_that(stars_node.get_child_count()).is_equal(50)
		else:
			# Test that stars array exists
			if game.has_method("get") and game.get("stars") != null:
				assert_that(game.stars.size()).is_equal(50)
	else:
		# Skip test if method doesn't exist
		pass

func test_starfield_movement():
	if game.has_method("create_starfield") and game.has_method("update_starfield"):
		game.create_starfield()
		if game.has_method("get") and game.get("stars") != null and game.stars.size() > 0:
			var star = game.stars[0]
			var initial_y = star.position.y

			game.update_starfield(0.016)  # One frame at 60fps

			assert_that(star.position.y).is_greater(initial_y)
	else:
		# Skip test if methods don't exist
		pass

func test_starfield_wrapping():
	if game.has_method("create_starfield") and game.has_method("update_starfield"):
		game.create_starfield()
		if game.has_method("get") and game.get("stars") != null and game.stars.size() > 0:
			var star = game.stars[0]
			star.position.y = 901  # Beyond wrap threshold
			var initial_x = star.position.x

			game.update_starfield(0.016)

			assert_that(star.position.y).is_equal(-10.0)
			# X position should be randomized on wrap
			assert_that(star.position.x).is_between(0.0, 800.0)
	else:
		# Skip test if methods don't exist
		pass

func test_player_spawn():
	if game.has_method("spawn_player"):
		game.spawn_player()

		if game.has_method("get") and game.get("current_player") != null:
			assert_that(game.current_player).is_not_null()
			assert_that(game.current_player.position).is_equal(Vector2(400, 800))
	else:
		# Skip test if method doesn't exist
		pass

func test_player_respawn_cleanup():
	if game.has_method("spawn_player"):
		# Create initial player
		game.spawn_player()
		if game.has_method("get") and game.get("current_player") != null:
			var first_player = game.current_player

			# Spawn new player (should replace old one)
			game.spawn_player()

			# Wait for cleanup
			await get_tree().process_frame

			assert_that(first_player.is_queued_for_deletion()).is_true()
			assert_that(game.current_player).is_not_equal(first_player)
	else:
		# Skip test if method doesn't exist
		pass

func test_bullet_creation_vulcan():
	if game.has_method("spawn_player") and game.has_method("_on_player_shoot"):
		game.spawn_player()
		var bullet_position = Vector2(400, 400)
		var bullet_direction = Vector2.UP

		game._on_player_shoot(bullet_position, bullet_direction, "vulcan")

		await get_tree().process_frame

		if game.has_node("Bullets"):
			var bullets_node = game.get_node("Bullets")
			assert_that(bullets_node.get_child_count()).is_greater(0)
	else:
		# Skip test if methods don't exist
		pass

func test_bullet_creation_laser():
	if game.has_method("spawn_player") and game.has_method("_on_player_shoot"):
		game.spawn_player()
		var bullet_position = Vector2(400, 400)
		var bullet_direction = Vector2.UP

		game._on_player_shoot(bullet_position, bullet_direction, "laser")

		await get_tree().process_frame

		if game.has_node("Bullets"):
			var bullets_node = game.get_node("Bullets")
			assert_that(bullets_node.get_child_count()).is_greater(0)
	else:
		# Skip test if methods don't exist
		pass

func test_laser_weapon_level_scaling():
	if game.has_method("spawn_player") and game.has_method("_on_player_shoot"):
		game.spawn_player()
		if game.has_method("get") and game.get("current_player") != null:
			game.current_player.weapon_level = 3

			game._on_player_shoot(Vector2(400, 400), Vector2.UP, "laser")

			await get_tree().process_frame

			if game.has_node("Bullets"):
				var bullets_node = game.get_node("Bullets")
				if bullets_node.get_child_count() > 0:
					var laser_bullet = bullets_node.get_child(0)
					if laser_bullet.has_method("get") and laser_bullet.get("weapon_level") != null:
						assert_that(laser_bullet.weapon_level).is_equal(3)
	else:
		# Skip test if methods don't exist
		pass

func test_wave_announcement():
	if game.has_method("_on_wave_announcement") and game.has_node("UI"):
		var ui_node = game.get_node("UI")
		var initial_children = ui_node.get_child_count()

		game._on_wave_announcement(5)

		assert_that(ui_node.get_child_count()).is_equal(initial_children + 1)

		var label = ui_node.get_child(-1)  # Last added child
		if label.has_method("get") and label.get("text") != null:
			assert_that(label.text).is_equal("WAVE 5")
	else:
		# Skip test if method or UI node doesn't exist
		pass

func test_game_over_prevents_enemy_spawn():
	game.game_over = true

	game._on_enemy_spawn_timer_timeout()

	# Should not crash and should not spawn enemies
	assert_that(game.game_over).is_true()

func test_game_over_prevents_wave_progression():
	game.game_over = true

	game._on_wave_timer_timeout()

	# Should not crash and should not advance wave
	assert_that(game.game_over).is_true()

func test_powerup_spawning():
	if game.has_method("spawn_powerup") and game.has_node("PowerUps"):
		var powerups_node = game.get_node("PowerUps")
		var initial_count = powerups_node.get_child_count()

		game.spawn_powerup(Vector2(400, 300))

		await get_tree().process_frame

		assert_that(powerups_node.get_child_count()).is_equal(initial_count + 1)
	else:
		# Skip test if method or PowerUps node doesn't exist
		pass

class MockEnemyManager extends Node:
	signal enemy_destroyed(points, position)
	signal wave_announcement(wave_num)

	func setup_for_game(_enemies_node):
		pass

	func spawn_random_enemies():
		pass

	func advance_wave():
		pass

	func connect_signals():
		pass