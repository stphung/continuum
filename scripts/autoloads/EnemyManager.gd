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

# Enemy tracking for cleanup
var total_enemies_spawned: int = 0
var total_enemies_destroyed: int = 0
var cleanup_timer: Timer = null
var cleanup_interval: float = 10.0  # Check every 10 seconds

func setup_for_game(container: Node):
	enemies_container = container
	# Load the enemy scene dynamically when the game starts
	if not enemy_scene:
		enemy_scene = load("res://scenes/enemies/Enemy.tscn")
	# Load all enemy type data
	load_enemy_types()
	# Reset game state when starting fresh
	reset_game_state()
	# Setup cleanup timer
	setup_cleanup_timer()

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
	total_enemies_spawned = 0
	total_enemies_destroyed = 0

func spawn_random_enemies():
	if game_over or not enemies_container:
		return

	var spawn_count = 1
	if randf() < 0.5:  # 50% chance for multi-spawn
		spawn_count = randi_range(2, min(5, 2 + wave_number / 2))  # More enemies as waves progress

	for i in spawn_count:
		spawn_enemy(i * 60)

func spawn_enemy(x_offset = 0, enemy_type_name: String = ""):
	if not enemies_container:
		print("Cannot spawn enemy: missing enemies_container")
		return

	if not enemy_scene:
		print("Cannot spawn enemy: missing enemy_scene")
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

	# Track spawned enemies
	total_enemies_spawned += 1
	print("[EnemyManager] Spawned enemy #", total_enemies_spawned, " - Active: ", get_tree().get_nodes_in_group("enemies").size())

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

	# Update enemy spawn timer for increased spawn rate
	if enemies_container and enemies_container.has_node("../EnemySpawnTimer"):
		var spawn_timer = enemies_container.get_node("../EnemySpawnTimer")
		# Decrease spawn interval - faster spawning as waves progress
		var spawn_rate_multiplier = 1.0 - min(wave_number * 0.01, 0.5)  # Up to 50% faster
		var new_spawn_time = max(0.5, 2.0 * spawn_rate_multiplier)  # Min 0.5s between spawns
		spawn_timer.wait_time = new_spawn_time

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
	# Scale enemy count with logarithmic progression to prevent overwhelming
	var base_count = enemies_per_wave + min(int(log(wave_number + 1) * 3), 10)  # Cap at 10 extra
	var enemy_count = min(base_count, 20)  # Hard cap at 20 enemies per formation

	# Mix enemy types in line formation - using delayed call instead of timer nodes
	for i in range(enemy_count):
		var delay = max(0.1, i * 0.15)  # Slightly faster spawning
		var x_offset = 400 - 200 + i * 40
		# Use get_tree().create_timer for more efficient timing
		get_tree().create_timer(delay).timeout.connect(func(): spawn_enemy(x_offset))

func _spawn_v_formation():
	# Scale enemy count with logarithmic progression to prevent overwhelming
	var base_count = enemies_per_wave + min(int(log(wave_number + 1) * 3), 10)  # Cap at 10 extra
	var enemy_count = min(base_count, 20)  # Hard cap at 20 enemies per formation

	# V formation with mixed enemy types - using delayed call instead of timer nodes
	for i in range(enemy_count):
		var delay = max(0.05, i * 0.08)  # Faster V formation
		var x = 400 + (i - enemy_count / 2) * 60
		var x_offset = x - 400
		# Use get_tree().create_timer for more efficient timing
		get_tree().create_timer(delay).timeout.connect(func(): spawn_enemy(x_offset))

func _spawn_random_burst():
	# Scale burst size with controlled progression
	var base_count = enemies_per_wave + min(int(log(wave_number + 1) * 4), 15)  # Cap at 15 extra
	var enemy_count = min(base_count, 25)  # Hard cap at 25 enemies per burst

	# Random burst with weighted selection toward appropriate types
	for i in range(enemy_count):
		spawn_enemy(0)

	# Special: Add fortress ships more often at higher waves
	if wave_number >= 15 and randf() < min(0.3 + (wave_number - 15) * 0.02, 0.8):  # Scale from 30% to 80%
		spawn_enemy(0, "fortress_ship")

	# Add support carriers with scaling probability
	if wave_number >= 12 and randf() < min(0.2 + (wave_number - 12) * 0.02, 0.6):  # Scale from 20% to 60%
		spawn_enemy(0, "support_carrier")

func show_wave_announcement():
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("wave_start", -3.0)

	emit_signal("wave_announcement", wave_number)

func _on_enemy_destroyed(points, pos):
	emit_signal("enemy_destroyed", points, pos)
	total_enemies_destroyed += 1
	print("[EnemyManager] Enemy destroyed #", total_enemies_destroyed, " - Remaining: ", get_tree().get_nodes_in_group("enemies").size() - 1)

func set_game_over(is_over: bool):
	game_over = is_over

func get_current_wave() -> int:
	return wave_number

func setup_cleanup_timer():
	if cleanup_timer:
		cleanup_timer.queue_free()

	cleanup_timer = Timer.new()
	cleanup_timer.wait_time = cleanup_interval
	cleanup_timer.timeout.connect(_on_cleanup_timer_timeout)
	add_child(cleanup_timer)
	cleanup_timer.start()
	print("[EnemyManager] Cleanup timer started with ", cleanup_interval, "s interval")

func _on_cleanup_timer_timeout():
	perform_enemy_cleanup_sweep()

func perform_enemy_cleanup_sweep():
	"""Periodic sweep to clean up orphaned enemies"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	var viewport_size = get_viewport().get_visible_rect().size
	var cleaned_count = 0
	var active_count = 0

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		# Check if enemy is way off-screen and should be cleaned
		var enemy_pos = enemy.global_position
		var max_distance = 1000  # Very generous boundary

		if (enemy_pos.x < -max_distance or enemy_pos.x > viewport_size.x + max_distance or
		    enemy_pos.y < -max_distance or enemy_pos.y > viewport_size.y + max_distance):
			print("[EnemyManager] Cleanup sweep found orphaned enemy at: ", enemy_pos)
			enemy.call_deferred("queue_free")
			cleaned_count += 1
		else:
			active_count += 1

	# Log statistics
	if cleaned_count > 0:
		print("[EnemyManager] Cleanup sweep removed ", cleaned_count, " orphaned enemies")

	print("[EnemyManager] Status - Spawned: ", total_enemies_spawned,
	      " | Destroyed: ", total_enemies_destroyed,
	      " | Active: ", active_count,
	      " | Discrepancy: ", total_enemies_spawned - total_enemies_destroyed - active_count)

	# Warn if there's a growing discrepancy
	var discrepancy = total_enemies_spawned - total_enemies_destroyed - active_count
	if discrepancy > 10:
		print("[EnemyManager] WARNING: High enemy discrepancy detected! ", discrepancy, " enemies unaccounted for")

func stop_cleanup_timer():
	if cleanup_timer:
		cleanup_timer.stop()
		print("[EnemyManager] Cleanup timer stopped")

func _exit_tree():
	if cleanup_timer:
		cleanup_timer.queue_free()