extends Node

signal enemy_destroyed(points, pos)
signal wave_announcement(wave_num)

var enemy_scene: PackedScene
var enemy_types: Dictionary = {}

var wave_number = 1
var enemies_per_wave = 2  # Start easier
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
	# Load all enemy type configurations with error checking
	var type_files = {
		"scout_fighter": "res://resources/enemies/scout_fighter.tres",
		"guard_drone": "res://resources/enemies/guard_drone.tres",
		"heavy_gunner": "res://resources/enemies/heavy_gunner.tres",
		"interceptor": "res://resources/enemies/interceptor.tres",
		"fortress_ship": "res://resources/enemies/fortress_ship.tres",
		"support_carrier": "res://resources/enemies/support_carrier.tres",
		"elite_scout_fighter": "res://resources/enemies/elite_scout_fighter.tres",
		"elite_guard_drone": "res://resources/enemies/elite_guard_drone.tres",
		"elite_heavy_gunner": "res://resources/enemies/elite_heavy_gunner.tres"
	}

	for type_name in type_files.keys():
		var file_path = type_files[type_name]
		if ResourceLoader.exists(file_path):
			var resource = load(file_path)
			if resource:
				enemy_types[type_name] = resource
				print("Loaded enemy type: ", type_name)
			else:
				print("Failed to load enemy type resource: ", type_name)
		else:
			print("Enemy type file not found: ", file_path)

	print("Total enemy types loaded: ", enemy_types.size())

func reset_game_state():
	wave_number = 1
	enemies_per_wave = 4  # Start with more enemies
	spawn_delay_reduction = 0.0
	game_over = false

func spawn_random_enemies():
	if game_over or not enemies_container:
		return

	var spawn_count = 1
	if randf() < 0.5:  # 50% chance for multi-spawn
		spawn_count = randi_range(2, min(5, 2 + wave_number / 2))  # More enemies as waves progress

	for i in spawn_count:
		spawn_enemy(i * 60)

func spawn_enemy(x_offset = 0, enemy_type_name: String = ""):
	if not enemy_scene or not enemies_container:
		print("Cannot spawn enemy: missing enemy_scene or enemies_container")
		return

	var enemy = enemy_scene.instantiate()
	var x_pos = randf_range(50, 750) + x_offset
	x_pos = clamp(x_pos, 50, 750)
	enemy.position = Vector2(x_pos, -50)

	# Set enemy type based on parameter or wave progression
	var type_name = enemy_type_name
	if type_name == "":
		type_name = get_random_enemy_type_for_wave()

	# Try to apply enemy type data
	if enemy_types.has(type_name) and enemy_types[type_name]:
		enemy.enemy_type_data = enemy_types[type_name]
		enemy.current_wave = wave_number
		print("Spawned enemy: ", type_name)
	else:
		# Fallback: set basic properties directly for compatibility
		enemy.health = 1 + (wave_number / 5)
		enemy.speed = 150 + (wave_number * 5)
		enemy.points = 100 + (wave_number * 10)
		enemy.movement_pattern = "straight"
		print("Spawned basic enemy (no type data available)")

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

func get_available_enemy_types() -> Array:
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
	spawn_delay_reduction = min(0.8, wave_number * 0.05)  # Much faster spawn acceleration
	spawn_wave()
	show_wave_announcement()

	# Dynamic wave timing - waves come faster as game progresses
	if enemies_container and enemies_container.has_node("../WaveTimer"):
		var wave_timer = enemies_container.get_node("../WaveTimer")
		var new_wait_time = max(3.0, 10.0 - (wave_number * 0.2))  # Start at 10s, min 3s
		wave_timer.wait_time = new_wait_time

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
	var enemy_count = enemies_per_wave + wave_number  # Uncapped increase
	# Mix enemy types in line formation - using delayed call instead of timer nodes
	for i in range(enemy_count):
		var delay = max(0.1, i * 0.15)  # Slightly faster spawning
		var x_offset = 400 - 200 + i * 40
		# Use get_tree().create_timer for more efficient timing
		get_tree().create_timer(delay).timeout.connect(func(): spawn_enemy(x_offset))

func _spawn_v_formation():
	var enemy_count = enemies_per_wave + wave_number  # Uncapped increase
	# V formation with mixed enemy types - using delayed call instead of timer nodes
	for i in range(enemy_count):
		var delay = max(0.05, i * 0.08)  # Faster V formation
		var x = 400 + (i - enemy_count / 2) * 60
		var x_offset = x - 400
		# Use get_tree().create_timer for more efficient timing
		get_tree().create_timer(delay).timeout.connect(func(): spawn_enemy(x_offset))

func _spawn_random_burst():
	var enemy_count = enemies_per_wave + min(wave_number * 2, 15)  # Up to 15 enemies in burst
	# Random burst with weighted selection toward appropriate types
	for i in range(enemy_count):
		spawn_enemy(0)

	# Special: Add fortress ships more often
	if wave_number >= 15 and randf() < 0.5:  # 50% chance from wave 15
		spawn_enemy(0, "fortress_ship")

	# Add support carriers too
	if wave_number >= 12 and randf() < 0.4:  # 40% chance from wave 12
		spawn_enemy(0, "support_carrier")

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