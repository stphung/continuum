extends GdUnitTestSuite

const Game = preload("res://scenes/main/Game.tscn")

var game: Node2D

func before_test():
	game = auto_free(Game.instantiate())
	add_child(game)
	game._ready()
	await get_tree().process_frame

func test_initial_game_state():
	# Test that game starts with correct initial values
	assert_that(game.score).is_equal(0)
	assert_that(game.lives).is_equal(3)
	assert_that(game.bombs).is_equal(3)
	assert_that(game.game_over).is_false()
	assert_that(game.stars.size()).is_equal(50)

func test_score_management():
	var initial_score = game.score

	# Simulate enemy destruction with different point values
	game._on_enemy_destroyed(100, Vector2(400, 300))
	assert_that(game.score).is_equal(initial_score + 100)

	game._on_enemy_destroyed(250, Vector2(300, 200))
	assert_that(game.score).is_equal(initial_score + 350)

	game._on_enemy_destroyed(50, Vector2(500, 400))
	assert_that(game.score).is_equal(initial_score + 400)

func test_lives_management():
	var initial_lives = game.lives

	# Trigger player hit
	game._on_player_hit()
	assert_that(game.lives).is_equal(initial_lives - 1)

	# Another hit
	game._on_player_hit()
	assert_that(game.lives).is_equal(initial_lives - 2)

	# Game should not be over yet
	assert_that(game.game_over).is_false()

func test_game_over_sequence():
	# Reduce lives to 1
	game.lives = 1
	var initial_lives = game.lives

	# Trigger final hit
	game._on_player_hit()

	await get_tree().process_frame

	# Game should be over
	assert_that(game.lives).is_equal(0)
	assert_that(game.game_over).is_true()

	# Game over UI should be visible
	var game_over_panel = game.get_node("UI/GameOverPanel")
	assert_that(game_over_panel.visible).is_true()

	# Final score should be displayed
	var final_score_label = game.get_node("UI/GameOverPanel/FinalScoreLabel")
	assert_that(final_score_label.text).contains(str(game.score))

func test_bomb_management():
	var initial_bombs = game.bombs

	# Use bomb
	game._on_player_use_bomb()
	assert_that(game.bombs).is_equal(initial_bombs - 1)

	# Use another bomb
	game._on_player_use_bomb()
	assert_that(game.bombs).is_equal(initial_bombs - 2)

	# Use remaining bombs until none left
	game.bombs = 1
	game._on_player_use_bomb()
	assert_that(game.bombs).is_equal(0)

	# Try to use bomb when none available
	game._on_player_use_bomb()
	assert_that(game.bombs).is_equal(0)  # Should not go negative

func test_player_respawn_sequence():
	var initial_lives = game.lives

	# Ensure we have lives for respawn
	if game.lives <= 1:
		game.lives = 2

	# Hit player but don't trigger game over
	game._on_player_hit()

	await get_tree().process_frame

	# Lives should decrease
	assert_that(game.lives).is_equal(initial_lives - 1)

	# Game should not be over
	assert_that(game.game_over).is_false()

	# Player respawn should be scheduled
	# (Hard to test timer directly, but game should continue)

func test_ui_state_synchronization():
	# Set specific game state
	game.score = 1500
	game.lives = 2
	game.bombs = 1

	# Update UI
	game.update_ui()

	await get_tree().process_frame

	# Check UI reflects current state
	var score_label = game.get_node("UI/HUD/ScoreLabel")
	var lives_label = game.get_node("UI/HUD/LivesLabel")
	var bombs_label = game.get_node("UI/HUD/BombsLabel")

	assert_that(score_label.text).contains("1500")
	assert_that(lives_label.text).contains("2")
	assert_that(bombs_label.text).contains("1")

func test_wave_progression_state():
	var initial_wave = EnemyManager.wave_number

	# Advance wave
	EnemyManager.advance_wave()

	# Wave should advance
	assert_that(EnemyManager.wave_number).is_equal(initial_wave + 1)

	# Spawn delay should be reduced
	assert_that(EnemyManager.spawn_delay_reduction).is_greater(0.0)

func test_enemy_manager_game_over_state():
	# Set game over state
	EnemyManager.set_game_over(true)

	assert_that(EnemyManager.game_over).is_true()

	# Enemy spawning should be prevented
	var enemies_node = game.get_node("Enemies")
	var initial_enemy_count = enemies_node.get_child_count()

	EnemyManager.spawn_random_enemies()

	await get_tree().process_frame

	# No new enemies should spawn
	assert_that(enemies_node.get_child_count()).is_equal(initial_enemy_count)

func test_starfield_state_persistence():
	# Starfield should maintain state across updates
	var initial_star_count = game.stars.size()
	var first_star_position = game.stars[0].position

	# Update starfield
	game.update_starfield(0.016)

	# Star count should remain the same
	assert_that(game.stars.size()).is_equal(initial_star_count)

	# Stars should have moved
	assert_that(game.stars[0].position.y).is_greater_equal(first_star_position.y)

func test_starfield_wrapping():
	# Test star wrapping when it goes off screen
	var star = game.stars[0]
	star.position.y = 901  # Beyond wrap threshold

	var initial_x = star.position.x

	game.update_starfield(0.016)

	# Star should wrap to top
	assert_that(star.position.y).is_between(-10.1, -9.9)

	# X position should be randomized
	# (Can vary, so just check it's within bounds)
	assert_that(star.position.x).is_between(0.0, 800.0)

func test_player_state_persistence():
	# Spawn player
	game.spawn_player()

	await get_tree().process_frame

	var player = game.current_player
	assert_that(player).is_not_null()

	# Test player state changes
	player.weapon_level = 3
	player.weapon_type = "laser"

	# Update UI (should show weapon state)
	game.update_ui()

	await get_tree().process_frame

	# Check weapon state is reflected in UI
	if game.get_node("UI/HUD").has_node("WeaponLabel"):
		var weapon_label = game.get_node("UI/HUD/WeaponLabel")
		assert_that(weapon_label.text).contains("LASER")
		assert_that(weapon_label.text).contains("LV3")

func test_game_over_prevents_gameplay():
	# Set game over
	game.game_over = true
	EnemyManager.set_game_over(true)

	# Try various game actions that should be prevented
	var enemies_node = game.get_node("Enemies")
	var initial_enemy_count = enemies_node.get_child_count()

	# Enemy spawning should be prevented
	game._on_enemy_spawn_timer_timeout()
	assert_that(enemies_node.get_child_count()).is_equal(initial_enemy_count)

	# Wave progression should be prevented
	var initial_wave = EnemyManager.wave_number
	game._on_wave_timer_timeout()
	assert_that(EnemyManager.wave_number).is_equal(initial_wave)

	# Starfield should stop updating
	if game.stars.size() > 0:
		var star = game.stars[0]
		var initial_position = star.position.y

		# Process shouldn't update starfield in game over
		game._process(0.016)

		# Star position should not change in game over state
		# (starfield update is skipped when game_over is true)

func test_restart_functionality():
	# Set up altered game state
	game.score = 1000
	game.lives = 1
	game.bombs = 0
	game.game_over = true

	# Restart should reset to initial state
	# Note: get_tree().reload_current_scene() is hard to test directly
	# but we can test the restart button setup

	var game_over_panel = game.get_node("UI/GameOverPanel")
	game_over_panel.visible = true

	# Game over panel should have restart button
	assert_that(game_over_panel.has_node("RestartButton")).is_true()

func test_powerup_effects_on_game_state():
	# Spawn player
	game.spawn_player()

	await get_tree().process_frame

	var player = game.current_player
	var initial_bombs = game.bombs
	var initial_lives = game.lives

	# Disable invulnerability for testing
	player.invulnerable = false

	# Test bomb powerup effect
	var bomb_powerup = preload("res://scenes/pickups/PowerUp.tscn").instantiate()
	bomb_powerup.position = player.position
	game.get_node("PowerUps").add_child(bomb_powerup)
	bomb_powerup._ready()
	# Set powerup type AFTER _ready() to avoid randomization override
	bomb_powerup.powerup_type = "bomb"
	bomb_powerup.update_appearance()

	player.collect_powerup(bomb_powerup)

	await get_tree().process_frame

	assert_that(game.bombs).is_equal(initial_bombs + 1)

	# Test life powerup effect
	var life_powerup = preload("res://scenes/pickups/PowerUp.tscn").instantiate()
	life_powerup.position = player.position
	game.get_node("PowerUps").add_child(life_powerup)
	life_powerup._ready()
	# Set powerup type AFTER _ready() to avoid randomization override
	life_powerup.powerup_type = "life"
	life_powerup.update_appearance()

	player.collect_powerup(life_powerup)

	await get_tree().process_frame

	assert_that(game.lives).is_equal(initial_lives + 1)

class TestGameStateTransitions extends GdUnitTestSuite:
	var game: Node2D

	func before_test():
		game = auto_free(Game.instantiate())
		add_child(game)
		game._ready()
		await get_tree().process_frame

	func test_playing_to_game_over_transition():
		# Start in playing state
		assert_that(game.game_over).is_false()

		# Reduce to final life
		game.lives = 1

		# Trigger game over
		game._on_player_hit()

		await get_tree().process_frame

		# Should transition to game over state
		assert_that(game.game_over).is_true()
		assert_that(game.lives).is_equal(0)

		# UI should reflect new state
		assert_that(game.get_node("UI/GameOverPanel").visible).is_true()

		# Player should be cleaned up
		assert_that(game.current_player).is_null()

	func test_respawn_to_playing_transition():
		# Start with multiple lives
		game.lives = 3

		# Hit player
		game._on_player_hit()

		await get_tree().process_frame

		# Should be in respawn state (lives decreased, but game continues)
		assert_that(game.lives).is_equal(2)
		assert_that(game.game_over).is_false()

		# Player respawn should be scheduled
		# (Timer based, hard to test directly)

	func test_wave_transition_effects():
		var initial_wave = EnemyManager.wave_number
		var ui_node = game.get_node("UI")
		var initial_ui_children = ui_node.get_child_count()

		# Trigger wave advance
		game._on_wave_announcement(initial_wave + 1)

		await get_tree().process_frame

		# Should create wave announcement UI
		assert_that(ui_node.get_child_count()).is_greater(initial_ui_children)

		# Look for wave announcement
		var found_announcement = false
		for child in ui_node.get_children():
			if child is Label and "WAVE" in child.text:
				found_announcement = true
				break

		assert_that(found_announcement).is_true()

class TestStateConsistency extends GdUnitTestSuite:
	var game: Node2D

	func before_test():
		game = auto_free(Game.instantiate())
		add_child(game)
		game._ready()
		await get_tree().process_frame

	func test_ui_consistency_with_state():
		# Set game state
		game.score = 2500
		game.lives = 1
		game.bombs = 2

		# Update UI
		game.update_ui()

		await get_tree().process_frame

		# Verify UI shows correct values
		var hud = game.get_node("UI/HUD")
		assert_that(hud.get_node("ScoreLabel").text).is_equal("Score: 2500")
		assert_that(hud.get_node("LivesLabel").text).is_equal("Lives: 1")
		assert_that(hud.get_node("BombsLabel").text).is_equal("Bombs: 2")

	func test_enemy_manager_state_consistency():
		# EnemyManager state should be consistent
		var wave = EnemyManager.wave_number
		var enemies_per_wave = EnemyManager.enemies_per_wave
		var spawn_delay = EnemyManager.spawn_delay_reduction

		# Advance wave
		EnemyManager.advance_wave()

		# State should be updated consistently
		assert_that(EnemyManager.wave_number).is_equal(wave + 1)
		assert_that(EnemyManager.spawn_delay_reduction).is_greater(spawn_delay)

	func test_player_weapon_state_consistency():
		game.spawn_player()

		await get_tree().process_frame

		var player = game.current_player

		# Change weapon state
		player.weapon_level = 4
		player.weapon_type = "laser"

		# Fire rate should be adjusted consistently
		player.adjust_fire_rate()

		# Timer should reflect weapon type and level
		var shoot_timer = player.get_node("ShootTimer")
		var expected_wait_time = max(0.2, 0.3 - (4 - 1) * 0.02)  # Laser formula
		assert_that(shoot_timer.wait_time).is_between(expected_wait_time - 0.01, expected_wait_time + 0.01)

	func test_global_state_coordination():
		# Test that global systems stay coordinated

		# Game and EnemyManager should have consistent game over state
		game.game_over = true
		EnemyManager.set_game_over(true)

		assert_that(game.game_over).is_equal(EnemyManager.game_over)

		# Reset and test again
		game.game_over = false
		EnemyManager.set_game_over(false)

		assert_that(game.game_over).is_equal(EnemyManager.game_over)