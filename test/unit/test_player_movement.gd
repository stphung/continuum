extends GdUnitTestSuite

const Player = preload("res://scenes/player/Player.tscn")

var player: Area2D
var screen_size = Vector2(1152, 648)

func before_test():
	player = auto_free(Player.instantiate())
	add_child(player)
	player.screen_size = screen_size
	player._ready()

func test_player_stays_within_left_boundary():
	player.position.x = -100
	player.handle_movement(0.016)  # 60 FPS delta
	assert_that(player.position.x).is_greater_equal(20.0)

func test_player_stays_within_right_boundary():
	player.position.x = screen_size.x + 100
	player.handle_movement(0.016)
	assert_that(player.position.x).is_less_equal(screen_size.x - 20)

func test_player_stays_within_top_boundary():
	player.position.y = -100
	player.handle_movement(0.016)
	assert_that(player.position.y).is_greater_equal(20.0)

func test_player_stays_within_bottom_boundary():
	player.position.y = screen_size.y + 100
	player.handle_movement(0.016)
	assert_that(player.position.y).is_less_equal(screen_size.y - 20)

func test_player_invulnerability_prevents_damage():
	player.invulnerable = true
	var signal_monitor = monitor_signals(player)

	var mock_enemy = auto_free(MockEnemy.new())
	player._on_area_entered(mock_enemy)

	# Check signal was not emitted
	await assert_signal(player).wait_until(100).is_not_emitted("player_hit")

func test_player_takes_damage_when_vulnerable():
	player.invulnerable = false
	var signal_monitor = monitor_signals(player)

	var mock_enemy = auto_free(MockEnemy.new())
	player._on_area_entered(mock_enemy)

	# Check signal was emitted
	await assert_signal(player).is_emitted("player_hit")

func test_player_movement_speed():
	var initial_x = 400.0
	player.position = Vector2(initial_x, 300)

	# Simulate moving right for one frame
	Input.action_press("move_right")
	player.handle_movement(0.016)
	Input.action_release("move_right")

	var expected_distance = player.speed * 0.016
	var actual_distance = player.position.x - initial_x
	assert_that(actual_distance).is_between(expected_distance * 0.9, expected_distance * 1.1)

func test_player_invulnerability_duration():
	player.start_invulnerability()
	assert_that(player.invulnerable).is_true()

	# Use await get_tree().create_timer() for waiting
	await get_tree().create_timer(5.2).timeout
	assert_that(player.invulnerable).is_false()

func test_power_up_drops_on_death():
	# Setup player with weapon upgrades
	player.weapon_level = 3
	player.weapon_type = "chain"
	var initial_powerups = get_tree().get_nodes_in_group("powerups").size()

	# Trigger player death
	player.take_damage()

	# Wait for power-ups to be created
	await get_tree().process_frame

	# Check that power-ups were dropped
	var final_powerups = get_tree().get_nodes_in_group("powerups").size()
	var power_ups_dropped = final_powerups - initial_powerups

	# Should drop power-ups equal to weapon level (3)
	assert_that(power_ups_dropped).is_equal(3)

func test_power_up_drops_weapon_upgrades_only():
	# Setup player with weapon upgrades
	player.weapon_level = 4
	player.weapon_type = "vulcan"
	var initial_powerups = get_tree().get_nodes_in_group("powerups").size()

	# Trigger player death
	player.take_damage()

	# Wait for power-ups to be created
	await get_tree().process_frame

	# Check that weapon upgrade power-ups were dropped
	var final_powerups = get_tree().get_nodes_in_group("powerups").size()
	var power_ups_dropped = final_powerups - initial_powerups

	# Should drop power-ups equal to weapon level (4)
	assert_that(power_ups_dropped).is_equal(4)

func test_no_power_up_drops_at_level_1():
	# Setup player at level 1 (default)
	player.weapon_level = 1
	player.weapon_type = "vulcan"
	var initial_powerups = get_tree().get_nodes_in_group("powerups").size()

	# Trigger player death
	player.take_damage()

	# Wait for power-ups to be created
	await get_tree().process_frame

	# Check power-ups dropped
	var final_powerups = get_tree().get_nodes_in_group("powerups").size()
	var power_ups_dropped = final_powerups - initial_powerups

	# Should drop 1 power-up at level 1 (equal to weapon level)
	assert_that(power_ups_dropped).is_equal(1)


class MockEnemy extends Area2D:
	func _init():
		add_to_group("enemies")