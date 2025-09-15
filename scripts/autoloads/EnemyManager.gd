extends Node

signal enemy_destroyed(points, pos)
signal wave_announcement(wave_num)

var enemy_scene: PackedScene
var enemy_types: Dictionary = {}

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
	# Load all enemy type data
	load_enemy_types()
	# Reset game state when starting fresh
	reset_game_state()

func load_enemy_types():
	# Load all enemy type configurations
	enemy_types["scout_fighter"] = load("res://resources/enemies/scout_fighter.tres")
	enemy_types["guard_drone"] = load("res://resources/enemies/guard_drone.tres")
	enemy_types["heavy_gunner"] = load("res://resources/enemies/heavy_gunner.tres")
	enemy_types["interceptor"] = load("res://resources/enemies/interceptor.tres")
	enemy_types["fortress_ship"] = load("res://resources/enemies/fortress_ship.tres")
	enemy_types["support_carrier"] = load("res://resources/enemies/support_carrier.tres")

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

func spawn_enemy(x_offset = 0, enemy_type_name: String = ""):
	if not enemy_scene or not enemies_container:
		return

	var enemy = enemy_scene.instantiate()
	var x_pos = randf_range(50, 750) + x_offset
	x_pos = clamp(x_pos, 50, 750)
	enemy.position = Vector2(x_pos, -50)

	# Set enemy type based on parameter or wave progression
	var type_name = enemy_type_name
	if type_name == "":
		type_name = get_random_enemy_type_for_wave()

	if enemy_types.has(type_name):
		enemy.enemy_type_data = enemy_types[type_name]
		enemy.current_wave = wave_number

	enemies_container.add_child(enemy)
	enemy.connect("enemy_destroyed", _on_enemy_destroyed)

func get_random_enemy_type_for_wave() -> String:
	# Get available enemy types for current wave
	var available_types = get_available_enemy_types()

	if available_types.is_empty():
		return "scout_fighter"  # Fallback

	# Create weighted selection
	var weighted_pool = []
	for type_name in available_types:
		var enemy_data = enemy_types[type_name]
		var weight = int(enemy_data.spawn_weight * 10)  # Convert to integer for weighted selection
		for i in weight:
			weighted_pool.append(type_name)

	if weighted_pool.is_empty():
		return available_types[0]

	return weighted_pool[randi() % weighted_pool.size()]

func get_available_enemy_types() -> Array[String]:
	var available = []

	for type_name in enemy_types.keys():
		var enemy_data = enemy_types[type_name]
		if enemy_data.can_spawn_on_wave(wave_number):
			available.append(type_name)

	return available

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
	var enemy_count = enemies_per_wave + wave_number
	# Mix enemy types in line formation
	for i in range(enemy_count):
		var timer = Timer.new()
		timer.wait_time = max(0.1, i * 0.2)  # Ensure minimum wait time
		timer.one_shot = true
		var x_offset = 400 - 200 + i * 40
		timer.timeout.connect(func(): spawn_enemy(x_offset))
		timer.timeout.connect(func(): timer.queue_free())
		add_child(timer)
		timer.start()

func _spawn_v_formation():
	var enemy_count = enemies_per_wave + wave_number
	# V formation with mixed enemy types
	for i in range(enemy_count):
		var timer = Timer.new()
		timer.wait_time = max(0.05, i * 0.1)  # Ensure minimum wait time
		timer.one_shot = true
		var x = 400 + (i - enemy_count / 2) * 60
		var x_offset = x - 400
		timer.timeout.connect(func(): spawn_enemy(x_offset))
		timer.timeout.connect(func(): timer.queue_free())
		add_child(timer)
		timer.start()

func _spawn_random_burst():
	var enemy_count = enemies_per_wave + wave_number * 2
	# Random burst with weighted selection toward appropriate types
	for i in range(enemy_count):
		spawn_enemy(0)

	# Special: Add one fortress ship on high waves
	if wave_number >= 26 and randf() < 0.3:
		spawn_enemy(0, "fortress_ship")

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