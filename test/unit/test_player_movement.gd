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

class MockEnemy extends Area2D:
	func _init():
		add_to_group("enemies")