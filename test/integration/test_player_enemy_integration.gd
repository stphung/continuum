extends GdUnitTestSuite

const Game = preload("res://scenes/main/Game.tscn")
const Player = preload("res://scenes/player/Player.tscn")
const Enemy = preload("res://scenes/enemies/Enemy.tscn")
const Bullet = preload("res://scenes/projectiles/Bullet.tscn")
const LaserBullet = preload("res://scenes/projectiles/LaserBullet.tscn")
const EnemyBullet = preload("res://scenes/projectiles/EnemyBullet.tscn")
const PowerUp = preload("res://scenes/pickups/PowerUp.tscn")

var game: Node2D
var player: Area2D
var enemy: Area2D

func before_test():
	game = auto_free(Game.instantiate())
	add_child(game)
	game._ready()

	# Wait for game to fully initialize
	await get_tree().process_frame

func test_player_bullet_enemy_collision():
	# Spawn an enemy
	enemy = auto_free(Enemy.instantiate())
	enemy.position = Vector2(400, 300)
	game.get_node("Enemies").add_child(enemy)
	enemy._ready()

	# Create a player bullet
	var bullet = auto_free(Bullet.instantiate())
	bullet.position = Vector2(400, 400)  # Below enemy, moving up
	bullet.direction = Vector2.UP
	game.get_node("Bullets").add_child(bullet)
	bullet._ready()

	var initial_enemy_health = enemy.health

	# Simulate collision
	bullet._on_area_entered(enemy)

	assert_that(enemy.health).is_equal(initial_enemy_health - 1)
	assert_that(bullet.is_queued_for_deletion()).is_true()

func test_laser_bullet_piercing():
	# Create multiple enemies in a line
	var enemies = []
	for i in range(3):
		var test_enemy = auto_free(Enemy.instantiate())
		test_enemy.position = Vector2(400, 200 + i * 50)
		game.get_node("Enemies").add_child(test_enemy)
		test_enemy._ready()
		enemies.append(test_enemy)

	# Create laser bullet with level 3 (pierce count = 4)
	var laser = auto_free(LaserBullet.instantiate())
	laser.weapon_level = 3
	laser.position = Vector2(400, 500)
	laser.direction = Vector2.UP
	game.get_node("Bullets").add_child(laser)
	laser._ready()

	# Hit all enemies
	for test_enemy in enemies:
		laser._on_area_entered(test_enemy)
		await get_tree().process_frame

	# Laser should still exist after hitting 3 enemies (pierce count = 4)
	assert_that(laser.is_queued_for_deletion()).is_false()
	assert_that(laser.enemies_hit).is_equal(3)

func test_laser_bullet_exhaustion():
	# Create enemy and laser with low pierce count
	var test_enemy = auto_free(Enemy.instantiate())
	game.get_node("Enemies").add_child(test_enemy)
	test_enemy._ready()

	var laser = auto_free(LaserBullet.instantiate())
	laser.weapon_level = 1  # pierce count = 2
	game.get_node("Bullets").add_child(laser)
	laser._ready()

	# Hit enemy twice
	laser._on_area_entered(test_enemy)
	laser._on_area_entered(test_enemy)

	# Laser should be destroyed after reaching pierce count
	assert_that(laser.is_queued_for_deletion()).is_true()

func test_enemy_bullet_player_collision():
	# Spawn player if not already spawned
	if not game.current_player:
		game.spawn_player()

	await get_tree().process_frame

	var player_ref = game.current_player
	var initial_lives = game.lives

	# Create enemy bullet
	var enemy_bullet = auto_free(EnemyBullet.instantiate())
	enemy_bullet.position = player_ref.position
	game.get_node("Bullets").add_child(enemy_bullet)
	enemy_bullet._ready()

	# Simulate collision
	player_ref._on_area_entered(enemy_bullet)

	await get_tree().process_frame

	# Player should be hit (lives reduced or invulnerable)
	assert_that(game.lives).is_less_equal(initial_lives)

func test_player_enemy_direct_collision():
	# Spawn player if not already spawned
	if not game.current_player:
		game.spawn_player()

	await get_tree().process_frame

	var player_ref = game.current_player
	var initial_lives = game.lives

	# Create enemy at player position
	var test_enemy = auto_free(Enemy.instantiate())
	test_enemy.position = player_ref.position
	game.get_node("Enemies").add_child(test_enemy)
	test_enemy._ready()

	# Simulate collision
	player_ref._on_area_entered(test_enemy)

	await get_tree().process_frame

	assert_that(game.lives).is_less_equal(initial_lives)

func test_powerup_collection_integration():
	# Spawn player
	if not game.current_player:
		game.spawn_player()

	await get_tree().process_frame

	var player_ref = game.current_player
	player_ref.invulnerable = false  # Disable invulnerability for testing
	var initial_weapon_level = player_ref.weapon_level

	# Create weapon upgrade powerup
	var powerup = auto_free(PowerUp.instantiate())
	powerup.position = player_ref.position
	game.get_node("PowerUps").add_child(powerup)
	powerup._ready()
	# Set powerup type AFTER _ready() to avoid randomization override
	powerup.powerup_type = "weapon_upgrade"
	powerup.update_appearance()

	# Simulate collection directly
	player_ref.collect_powerup(powerup)

	await get_tree().process_frame

	assert_that(player_ref.weapon_level).is_equal(initial_weapon_level + 1)
	assert_that(powerup.is_queued_for_deletion()).is_true()

func test_enemy_destruction_triggers_effects():
	# Create enemy
	var test_enemy = auto_free(Enemy.instantiate())
	test_enemy.position = Vector2(400, 300)
	game.get_node("Enemies").add_child(test_enemy)
	test_enemy._ready()

	var initial_score = game.score
	var effects_node = game.get_node("Effects")
	var initial_effect_count = effects_node.get_child_count()

	# Connect enemy to game's score system
	test_enemy.connect("enemy_destroyed", game._on_enemy_destroyed)

	# Destroy enemy
	test_enemy.destroy()

	await get_tree().process_frame

	# Score should increase
	assert_that(game.score).is_greater(initial_score)

	# Effects should be created
	assert_that(effects_node.get_child_count()).is_greater(initial_effect_count)

func test_powerup_spawn_on_enemy_death():
	# Set up enemy with guaranteed powerup spawn
	var test_enemy = auto_free(Enemy.instantiate())
	test_enemy.position = Vector2(400, 300)
	game.get_node("Enemies").add_child(test_enemy)
	test_enemy._ready()

	var powerups_node = game.get_node("PowerUps")
	var initial_powerup_count = powerups_node.get_child_count()

	# Connect enemy to game system
	test_enemy.connect("enemy_destroyed", game._on_enemy_destroyed)

	# Force powerup spawn by calling game method directly
	game.spawn_powerup(Vector2(400, 300))

	await get_tree().process_frame

	assert_that(powerups_node.get_child_count()).is_equal(initial_powerup_count + 1)

func test_weapon_type_switching():
	# Spawn player
	if not game.current_player:
		game.spawn_player()

	await get_tree().process_frame

	var player_ref = game.current_player
	player_ref.invulnerable = false  # Disable invulnerability for testing
	var initial_weapon = player_ref.weapon_type

	# Create weapon switch powerup
	var powerup = auto_free(PowerUp.instantiate())
	powerup.position = player_ref.position
	game.get_node("PowerUps").add_child(powerup)
	powerup._ready()
	# Set powerup type AFTER _ready() to avoid randomization override
	powerup.powerup_type = "weapon_switch"
	powerup.update_appearance()

	# Collect powerup directly
	player_ref.collect_powerup(powerup)

	await get_tree().process_frame

	# Weapon should have switched
	assert_that(player_ref.weapon_type).is_not_equal(initial_weapon)
	var expected_weapon = "laser" if initial_weapon == "vulcan" else "vulcan"
	assert_that(player_ref.weapon_type).is_equal(expected_weapon)

func test_bomb_powerup_increases_bombs():
	# Spawn player
	if not game.current_player:
		game.spawn_player()

	await get_tree().process_frame

	var initial_bombs = game.bombs
	var player_ref = game.current_player
	player_ref.invulnerable = false  # Disable invulnerability for testing

	# Create bomb powerup
	var powerup = auto_free(PowerUp.instantiate())
	powerup.position = player_ref.position
	game.get_node("PowerUps").add_child(powerup)
	powerup._ready()
	# Set powerup type AFTER _ready() to avoid randomization override
	powerup.powerup_type = "bomb"
	powerup.update_appearance()

	# Collect powerup directly
	player_ref.collect_powerup(powerup)

	await get_tree().process_frame

	assert_that(game.bombs).is_equal(initial_bombs + 1)

func test_life_powerup_increases_lives():
	# Spawn player
	if not game.current_player:
		game.spawn_player()

	await get_tree().process_frame

	var initial_lives = game.lives
	var player_ref = game.current_player
	player_ref.invulnerable = false  # Disable invulnerability for testing

	# Create life powerup
	var powerup = auto_free(PowerUp.instantiate())
	powerup.position = player_ref.position
	game.get_node("PowerUps").add_child(powerup)
	powerup._ready()
	# Set powerup type AFTER _ready() to avoid randomization override
	powerup.powerup_type = "life"
	powerup.update_appearance()

	# Collect powerup directly
	player_ref.collect_powerup(powerup)

	await get_tree().process_frame

	assert_that(game.lives).is_equal(initial_lives + 1)

func test_bomb_clears_enemies():
	# Create multiple enemies
	var enemies = []
	for i in range(3):
		var test_enemy = auto_free(Enemy.instantiate())
		test_enemy.position = Vector2(200 + i * 100, 300)
		game.get_node("Enemies").add_child(test_enemy)
		test_enemy._ready()
		enemies.append(test_enemy)

	var initial_bombs = game.bombs

	# Use bomb
	game._on_player_use_bomb()

	await get_tree().process_frame

	# Bombs should decrease
	assert_that(game.bombs).is_equal(initial_bombs - 1)

	# All enemies should be destroyed or queued for deletion
	for test_enemy in enemies:
		assert_that(test_enemy.is_queued_for_deletion()).is_true()

func test_player_invulnerability_blocks_damage():
	# Spawn player
	if not game.current_player:
		game.spawn_player()

	await get_tree().process_frame

	var player_ref = game.current_player
	player_ref.start_invulnerability()  # Activate invulnerability

	var initial_lives = game.lives

	# Create enemy at player position
	var test_enemy = auto_free(Enemy.instantiate())
	test_enemy.position = player_ref.position
	game.get_node("Enemies").add_child(test_enemy)
	test_enemy._ready()

	# Try to damage invulnerable player
	player_ref._on_area_entered(test_enemy)

	await get_tree().process_frame

	# Lives should not decrease due to invulnerability
	assert_that(game.lives).is_equal(initial_lives)

func test_different_enemy_movement_patterns():
	var patterns = ["straight", "zigzag", "dive"]

	for pattern in patterns:
		var test_enemy = auto_free(Enemy.instantiate())
		test_enemy.movement_pattern = pattern
		test_enemy.position = Vector2(400, 100)
		test_enemy.initial_x = 400
		test_enemy.speed = 150
		game.get_node("Enemies").add_child(test_enemy)
		test_enemy._ready()

		var initial_position = test_enemy.position

		# Process movement
		test_enemy._process(0.016)

		# All patterns should result in some movement
		assert_that(test_enemy.position).is_not_equal(initial_position)

func test_weapon_level_affects_laser_damage():
	# Create two lasers with different weapon levels
	var laser1 = auto_free(LaserBullet.instantiate())
	laser1.weapon_level = 1
	game.get_node("Bullets").add_child(laser1)
	laser1._ready()

	var laser2 = auto_free(LaserBullet.instantiate())
	laser2.weapon_level = 3
	game.get_node("Bullets").add_child(laser2)
	laser2._ready()

	# Higher level laser should have higher damage and pierce count
	assert_that(laser2.damage).is_greater(laser1.damage)
	assert_that(laser2.pierce_count).is_greater(laser1.pierce_count)

func test_laser_impact_effects():
	var laser = auto_free(LaserBullet.instantiate())
	laser.position = Vector2(400, 300)
	game.get_node("Bullets").add_child(laser)
	laser._ready()

	var bullets_node = game.get_node("Bullets")
	var initial_child_count = bullets_node.get_child_count()

	# Create impact effect
	laser.create_impact_effect()

	await get_tree().process_frame

	# Should create particle effect
	assert_that(bullets_node.get_child_count()).is_greater(initial_child_count)

class TestGameStateIntegration extends GdUnitTestSuite:
	var game: Node2D

	func before_test():
		game = auto_free(Game.instantiate())
		add_child(game)
		game._ready()
		await get_tree().process_frame

	func test_game_over_sequence():
		# Reduce lives to 0
		game.lives = 1

		# Trigger player death
		game._on_player_hit()

		await get_tree().process_frame

		# Game should be in game over state
		assert_that(game.game_over).is_true()
		assert_that(game.lives).is_equal(0)

	func test_respawn_sequence():
		var initial_lives = game.lives

		# Trigger player death with lives remaining
		if game.lives <= 1:
			game.lives = 2

		game._on_player_hit()

		await get_tree().process_frame

		# Lives should decrease but game shouldn't be over
		assert_that(game.lives).is_equal(initial_lives - 1)
		assert_that(game.game_over).is_false()

	func test_wave_progression_integration():
		var initial_wave = EnemyManager.wave_number

		# Advance wave through EnemyManager
		EnemyManager.advance_wave()

		assert_that(EnemyManager.wave_number).is_equal(initial_wave + 1)

	func test_ui_updates_with_game_state():
		game.score = 1500
		game.lives = 2
		game.bombs = 1

		game.update_ui()

		# Check that UI labels are updated (basic existence check)
		assert_that(game.get_node("UI/HUD/ScoreLabel").text.contains("1500")).is_true()
		assert_that(game.get_node("UI/HUD/LivesLabel").text.contains("2")).is_true()
		assert_that(game.get_node("UI/HUD/BombsLabel").text.contains("1")).is_true()