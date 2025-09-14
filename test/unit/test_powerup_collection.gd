extends GdUnitTestSuite

const Player = preload("res://scenes/player/Player.tscn")
const PowerUp = preload("res://scenes/pickups/PowerUp.tscn")

var player: Area2D
var game_mock: MockGame

func before_test():
	player = auto_free(Player.instantiate())
	game_mock = MockGame.new()
	add_child(game_mock)
	game_mock.add_child(player)
	player._ready()

func test_powerup_floating_animation():
	var powerup = auto_free(PowerUp.instantiate())
	add_child(powerup)
	powerup._ready()

	var initial_pos = powerup.position

	# Simulate 1 second of floating
	for i in range(60):  # 60 frames at 60 FPS
		powerup._process(0.016)

	# Should have moved due to floating animation
	assert_that(powerup.position).is_not_equal(initial_pos)

	# Y position should increase (falling)
	assert_that(powerup.position.y).is_greater(initial_pos.y)

func test_powerup_drift_movement():
	var powerup = auto_free(PowerUp.instantiate())
	add_child(powerup)
	powerup._ready()

	var initial_x = powerup.position.x

	# Simulate floating to see horizontal drift
	for i in range(120):  # 2 seconds
		powerup._process(0.016)

	# Should show some horizontal drift
	var x_difference = abs(powerup.position.x - initial_x)
	assert_that(x_difference).is_greater(0.0)

func test_weapon_upgrade_collection():
	var powerup = auto_free(PowerUp.instantiate())
	powerup.powerup_type = "weapon_upgrade"
	var initial_level = player.weapon_level

	player.collect_powerup(powerup)

	assert_that(player.weapon_level).is_equal(initial_level + 1)

func test_weapon_upgrade_max_level():
	player.weapon_level = 5
	var powerup = auto_free(PowerUp.instantiate())
	powerup.powerup_type = "weapon_upgrade"

	player.collect_powerup(powerup)

	# Should not exceed max level of 5
	assert_that(player.weapon_level).is_equal(5)

func test_weapon_switch_collection():
	player.weapon_type = "vulcan"
	var powerup = auto_free(PowerUp.instantiate())
	powerup.powerup_type = "weapon_switch"

	player.collect_powerup(powerup)

	assert_that(player.weapon_type).is_equal("laser")

func test_weapon_switch_back_to_vulcan():
	player.weapon_type = "laser"
	var powerup = auto_free(PowerUp.instantiate())
	powerup.powerup_type = "weapon_switch"

	player.collect_powerup(powerup)

	assert_that(player.weapon_type).is_equal("vulcan")

func test_bomb_powerup_collection():
	var powerup = auto_free(PowerUp.instantiate())
	powerup.powerup_type = "bomb"
	var initial_bombs = game_mock.bombs

	player.collect_powerup(powerup)

	assert_that(game_mock.bombs).is_equal(initial_bombs + 1)

func test_life_powerup_collection():
	var powerup = auto_free(PowerUp.instantiate())
	powerup.powerup_type = "life"
	var initial_lives = game_mock.lives

	player.collect_powerup(powerup)

	assert_that(game_mock.lives).is_equal(initial_lives + 1)

func test_powerup_destruction_after_collection():
	var powerup = auto_free(PowerUp.instantiate())
	powerup.powerup_type = "weapon_upgrade"

	player.collect_powerup(powerup)

	# Wait one frame for deletion
	await get_tree().process_frame
	assert_that(powerup.is_queued_for_deletion()).is_true()

func test_fire_rate_adjustment_after_upgrade():
	player.weapon_type = "vulcan"
	player.weapon_level = 1
	player.adjust_fire_rate()
	var initial_wait_time = player.get_node("ShootTimer").wait_time

	# Upgrade weapon
	var powerup = auto_free(PowerUp.instantiate())
	powerup.powerup_type = "weapon_upgrade"
	player.collect_powerup(powerup)

	# Fire rate should be faster (lower wait time)
	var new_wait_time = player.get_node("ShootTimer").wait_time
	assert_that(new_wait_time).is_less_equal(initial_wait_time)

func test_powerup_scale_animation():
	var powerup = auto_free(PowerUp.instantiate())
	add_child(powerup)
	powerup._ready()

	var initial_scale = powerup.scale

	# Let scale animation run - pulse animation should change scale
	await get_tree().create_timer(1.0).timeout

	# Scale should have changed due to pulsing animation
	# Since tweens run continuously, the scale should be different from initial
	var scale_changed = powerup.scale != initial_scale
	assert_that(scale_changed).is_true()

func test_powerup_rotation_animation():
	var powerup = auto_free(PowerUp.instantiate())
	add_child(powerup)
	powerup._ready()

	var initial_rotation = powerup.rotation

	# Wait for the tween-based rotation animation to run
	await get_tree().create_timer(0.5).timeout

	# Should have some rotation due to the rotation tween
	assert_that(powerup.rotation).is_not_equal(initial_rotation)

class MockGame extends Node2D:
	var bombs = 0
	var lives = 3
	var score = 0

	func add_bomb():
		bombs += 1

	func add_life():
		lives += 1

	func update_ui():
		pass  # Mock implementation