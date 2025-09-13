extends Node

signal enemy_destroyed(points, pos)
signal wave_announcement(wave_num)

var enemy_scene: PackedScene

var wave_number = 1
var enemies_per_wave = 3
var spawn_delay_reduction = 0.0
var game_over = false
var enemies_container: Node

func setup_for_game(container: Node):
	enemies_container = container
	# Load the enemy scene dynamically when the game starts
	if not enemy_scene:
		enemy_scene = load("res://scenes/enemies/Enemy.tscn")
	# Reset game state when starting fresh
	reset_game_state()

func reset_game_state():
	wave_number = 1
	enemies_per_wave = 3
	spawn_delay_reduction = 0.0
	game_over = false

func spawn_random_enemies():
	if game_over or not enemies_container:
		return

	var spawn_count = 1
	if randf() < 0.3:
		spawn_count = randi_range(2, min(3, wave_number))

	for i in spawn_count:
		spawn_enemy(i * 60)

func spawn_enemy(x_offset = 0):
	if not enemy_scene or not enemies_container:
		return

	var enemy = enemy_scene.instantiate()
	var x_pos = randf_range(50, 750) + x_offset
	x_pos = clamp(x_pos, 50, 750)
	enemy.position = Vector2(x_pos, -50)

	_configure_enemy_properties(enemy)
	_set_enemy_movement_pattern(enemy)

	enemies_container.add_child(enemy)
	enemy.connect("enemy_destroyed", _on_enemy_destroyed)

func _configure_enemy_properties(enemy):
	enemy.health = min(3 + int(wave_number / 3), 8)
	enemy.speed = min(150 + wave_number * 10, 400)
	enemy.points = 100 * (1 + int(wave_number / 2))

func _set_enemy_movement_pattern(enemy):
	var patterns = ["straight", "zigzag", "dive"]
	enemy.movement_pattern = patterns[randi() % patterns.size()]

func _on_wave_timer_timeout():
	advance_wave()

func advance_wave():
	wave_number += 1
	spawn_delay_reduction = min(0.4, wave_number * 0.02)
	spawn_wave()
	show_wave_announcement()

func spawn_wave():
	if not enemies_container:
		return

	var formation = randi() % 3

	match formation:
		0:  # Line formation
			_spawn_line_formation()
		1:  # V formation
			_spawn_v_formation()
		2:  # Random burst
			_spawn_random_burst()

func _spawn_line_formation():
	for i in range(enemies_per_wave + wave_number):
		var timer = Timer.new()
		timer.wait_time = i * 0.2
		timer.one_shot = true
		timer.timeout.connect(func(): spawn_enemy(400 - 200 + i * 40))
		enemies_container.add_child(timer)
		timer.start()

func _spawn_v_formation():
	for i in range(enemies_per_wave + wave_number):
		var timer = Timer.new()
		timer.wait_time = i * 0.1
		timer.one_shot = true
		var x = 400 + (i - (enemies_per_wave + wave_number) / 2) * 60
		timer.timeout.connect(func(): spawn_enemy(x - 400))
		enemies_container.add_child(timer)
		timer.start()

func _spawn_random_burst():
	for i in range(enemies_per_wave + wave_number * 2):
		spawn_enemy(0)

func show_wave_announcement():
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("wave_start", -3.0)

	emit_signal("wave_announcement", wave_number)

func _on_enemy_destroyed(points, pos):
	emit_signal("enemy_destroyed", points, pos)

func set_game_over(is_over: bool):
	game_over = is_over

func get_current_wave() -> int:
	return wave_number