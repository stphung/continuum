extends GdUnitTestSuite

const Player = preload("res://scenes/player/Player.tscn")
const PlasmaBullet = preload("res://scenes/projectiles/PlasmaBullet.tscn")
const Bullet = preload("res://scenes/projectiles/Bullet.tscn")

var player: Area2D

func before_test():
	player = auto_free(Player.instantiate())
	add_child(player)
	player._ready()

func test_vulcan_weapon_level_1_single_shot():
	player.weapon_type = "vulcan"
	player.weapon_level = 1

	# Connect signal to a simple counter to verify emission
	var signal_count = [0]  # Use array for reference semantics
	player.shoot.connect(func(pos, dir, weapon): signal_count[0] += 1)

	# Ensure muzzle position node exists
	assert_that(player.has_node("MuzzlePosition")).is_true()

	# Test the actual method
	player.fire_vulcan()

	# Check signal was emitted once for single shot
	assert_that(signal_count[0]).is_equal(1)

func test_vulcan_weapon_level_2_dual_shot():
	player.weapon_type = "vulcan"
	player.weapon_level = 2

	var signal_count = [0]
	player.shoot.connect(func(pos, dir, weapon): signal_count[0] += 1)

	player.fire_vulcan()

	# Check signal was emitted twice (level 2 shoots from left and right muzzles)
	assert_that(signal_count[0]).is_equal(2)

func test_vulcan_weapon_level_3_spread_shot():
	player.weapon_type = "vulcan"
	player.weapon_level = 3

	var signal_count = [0]
	player.shoot.connect(func(pos, dir, weapon): signal_count[0] += 1)

	player.fire_vulcan()

	# Check signal was emitted 3 times for spread shot
	assert_that(signal_count[0]).is_equal(3)

func test_vulcan_weapon_max_level_wide_spread():
	player.weapon_type = "vulcan"
	player.weapon_level = 5

	var signal_count = [0]
	player.shoot.connect(func(pos, dir, weapon): signal_count[0] += 1)

	player.fire_vulcan()

	# Check signal was emitted 5 times for max level spread
	assert_that(signal_count[0]).is_equal(5)

func test_chain_weapon_single_beam():
	player.weapon_type = "chain"

	var signal_count = [0]
	player.shoot.connect(func(pos, dir, weapon): signal_count[0] += 1)

	player.fire_chain()

	# Check signal was emitted once for chain lightning
	assert_that(signal_count[0]).is_equal(1)

func test_chain_bullet_damage_scaling():
	var chain_bullet = auto_free(PlasmaBullet.instantiate())
	chain_bullet.weapon_level = 3
	chain_bullet._ready()

	# Chain bullets have fixed damage of 1
	assert_that(chain_bullet.damage).is_equal(1)
	# Chain bullets have homing based on weapon level
	assert_that(chain_bullet.homing_strength).is_equal(3.0)  # weapon_level * 1.0

func test_chain_bullet_hit_tracking():
	var chain_bullet = auto_free(PlasmaBullet.instantiate())
	add_child(chain_bullet)
	chain_bullet.weapon_level = 2
	chain_bullet._ready()

	# Create mock enemies
	var enemy1 = auto_free(MockEnemy.new())
	var enemy2 = auto_free(MockEnemy.new())

	# First hit should destroy chain bullet (no piercing in chain lightning)
	chain_bullet._on_area_entered(enemy1)
	assert_that(chain_bullet.hit_enemies.size()).is_equal(1)
	assert_that(chain_bullet.is_queued_for_deletion()).is_true()

func test_weapon_fire_rate_adjustment():
	# Test vulcan fire rate
	player.weapon_type = "vulcan"
	player.weapon_level = 1
	player.adjust_fire_rate()
	var vulcan_wait_time = player.get_node("ShootTimer").wait_time

	# Test chain fire rate (should be faster)
	player.weapon_type = "chain"
	player.weapon_level = 1
	player.adjust_fire_rate()
	var chain_wait_time = player.get_node("ShootTimer").wait_time

	assert_that(chain_wait_time).is_less_equal(vulcan_wait_time)

func test_weapon_level_affects_fire_rate():
	player.weapon_type = "vulcan"

	# Level 1 baseline
	player.weapon_level = 1
	player.adjust_fire_rate()
	var level1_wait_time = player.get_node("ShootTimer").wait_time

	# Level 5 should be faster
	player.weapon_level = 5
	player.adjust_fire_rate()
	var level5_wait_time = player.get_node("ShootTimer").wait_time

	assert_that(level5_wait_time).is_less(level1_wait_time)

func test_regular_bullet_properties():
	var bullet = auto_free(Bullet.instantiate())
	bullet._ready()

	assert_that(bullet.speed).is_equal(800)
	assert_that(bullet.damage).is_equal(1)
	assert_that(bullet.direction).is_equal(Vector2.UP)

class MockEnemy extends Area2D:
	var health = 100

	func _init():
		add_to_group("enemies")

	func take_damage(amount: int):
		health -= amount