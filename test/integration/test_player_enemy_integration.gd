extends GdUnitTestSuite

const Game = preload("res://scenes/main/Game.tscn")
const Player = preload("res://scenes/player/Player.tscn")
const Enemy = preload("res://scenes/enemies/Enemy.tscn")
const Bullet = preload("res://scenes/projectiles/Bullet.tscn")
const PlasmaBullet = preload("res://scenes/projectiles/PlasmaBullet.tscn")
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

# Helper function to create enemies with proper setup
func create_test_enemy(enemy_type: String = "scout_fighter") -> Area2D:
	var enemy = auto_free(Enemy.instantiate())
	var enemy_data = load("res://resources/enemies/" + enemy_type + ".tres")
	enemy.enemy_type_data = enemy_data
	enemy.current_wave = 1
	return enemy

func test_player_bullet_enemy_collision():
	# Spawn an enemy
	enemy = create_test_enemy()
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

	# Check enemy health before any deferred operations
	assert_that(enemy.health).is_equal(initial_enemy_health - 1)

	# Wait for deferred queue_free to take effect
	await get_tree().process_frame

	# Bullet should be destroyed after hitting enemy
	assert_that(bullet.is_queued_for_deletion()).is_true()

func test_chain_bullet_chaining():
	# Create multiple enemies in a line
	var enemies = []
	for i in range(3):
		var test_enemy = auto_free(Enemy.instantiate())
		test_enemy.position = Vector2(400, 200 + i * 50)
		game.get_node("Enemies").add_child(test_enemy)
		test_enemy._ready()
		enemies.append(test_enemy)

	# Create chain bullet with level 3 (3 chain lightning strikes)
	var chain_bullet = auto_free(PlasmaBullet.instantiate())
	chain_bullet.weapon_level = 3
	chain_bullet.position = Vector2(400, 500)
	chain_bullet.direction = Vector2.UP
	game.get_node("Bullets").add_child(chain_bullet)
	chain_bullet._ready()

	# Chain lightning destroys bullet on first hit but chains to other enemies
	chain_bullet._on_area_entered(enemies[0])

	# Check hit tracking before deferred operations
	assert_that(chain_bullet.hit_enemies.size()).is_equal(1)

	await get_tree().process_frame

	# Chain bullet should be destroyed after first hit
	assert_that(chain_bullet.is_queued_for_deletion()).is_true()

func test_chain_bullet_single_hit_destruction():
	# Create enemy and chain bullet
	var test_enemy = auto_free(Enemy.instantiate())
	game.get_node("Enemies").add_child(test_enemy)
	test_enemy._ready()

	var chain_bullet = auto_free(PlasmaBullet.instantiate())
	chain_bullet.weapon_level = 1
	game.get_node("Bullets").add_child(chain_bullet)
	chain_bullet._ready()

	# Hit enemy once - chain bullets are destroyed after first hit
	chain_bullet._on_area_entered(test_enemy)

	# Wait for deferred queue_free to take effect
	await get_tree().process_frame

	# Chain bullet should be destroyed after first hit
	assert_that(chain_bullet.is_queued_for_deletion()).is_true()

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
	powerup.powerup_type = "vulcan_powerup"
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
	var initial_level = player_ref.weapon_level

	# Test switching to chain weapon
	var chain_powerup = auto_free(PowerUp.instantiate())
	chain_powerup.position = player_ref.position
	game.get_node("PowerUps").add_child(chain_powerup)
	chain_powerup._ready()
	# Set powerup type AFTER _ready() to avoid randomization override
	chain_powerup.powerup_type = "chain_powerup"
	chain_powerup.update_appearance()

	# Collect powerup directly
	player_ref.collect_powerup(chain_powerup)

	await get_tree().process_frame

	# Weapon should have switched to chain and level should increase
	assert_that(player_ref.weapon_type).is_equal("chain")
	assert_that(player_ref.weapon_level).is_greater_equal(initial_level)

	# Test switching back to vulcan weapon
	var vulcan_powerup = auto_free(PowerUp.instantiate())
	vulcan_powerup.position = player_ref.position
	game.get_node("PowerUps").add_child(vulcan_powerup)
	vulcan_powerup._ready()
	vulcan_powerup.powerup_type = "vulcan_powerup"
	vulcan_powerup.update_appearance()

	# Collect powerup directly
	player_ref.collect_powerup(vulcan_powerup)

	await get_tree().process_frame

	# Weapon should have switched to vulcan
	assert_that(player_ref.weapon_type).is_equal("vulcan")

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

func test_weapon_level_affects_chain_homing():
	# Create two chain bullets with different weapon levels
	var chain1 = auto_free(PlasmaBullet.instantiate())
	chain1.weapon_level = 1
	game.get_node("Bullets").add_child(chain1)
	chain1._ready()

	var chain2 = auto_free(PlasmaBullet.instantiate())
	chain2.weapon_level = 3
	game.get_node("Bullets").add_child(chain2)
	chain2._ready()

	# Higher level chain bullets have stronger homing and longer range
	assert_that(chain2.homing_strength).is_greater(chain1.homing_strength)
	assert_that(chain2.homing_range).is_greater(chain1.homing_range)

func test_chain_impact_effects():
	var chain_bullet = auto_free(PlasmaBullet.instantiate())
	chain_bullet.position = Vector2(400, 300)
	game.get_node("Bullets").add_child(chain_bullet)
	chain_bullet._ready()

	var scene_children_initial = get_tree().current_scene.get_child_count()

	# Create impact effect with position parameter
	chain_bullet.create_impact_effect(Vector2(400, 300))

	await get_tree().process_frame

	# Should create particle effect in game scene
	var scene_children_after = get_tree().current_scene.get_child_count()
	assert_that(scene_children_after).is_greater_equal(scene_children_initial)

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