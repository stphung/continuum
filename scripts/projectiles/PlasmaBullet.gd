extends Area2D

@export var speed = 1000
@export var damage = 1

var weapon_level = 1
var direction = Vector2.UP
var lifetime = 0.0
var max_lifetime = 3.0
var hit_enemies: Array[Area2D] = []

# Homing variables
var homing_strength = 0.0  # Radians per second turning speed
var homing_range = 0.0  # Detection range for enemies
var target_enemy: Area2D = null

# Trail effect variables
var trail_positions: Array = []
var max_trail_length = 8

func _ready():
	add_to_group("player_bullets")

	# Fixed damage of 1, same as vulcan
	damage = 1

	# Set homing parameters based on weapon level
	# Level 1: Very subtle homing
	# Level 20: Aggressive homing that rarely misses
	homing_strength = weapon_level * 1.0  # 1 to 20 radians/sec
	homing_range = 150.0 + (weapon_level * 20.0)  # 170 to 550 pixels

	# Scale bullet visuals based on level (thicker and longer)
	var scale_factor = 1.0 + (weapon_level - 1) * 0.05  # 1.0x to 1.95x at level 20
	var length_factor = 1.0 + (weapon_level - 1) * 0.1  # 1.0x to 2.9x length at level 20

	# Update all visual components to be thicker and longer
	$Sprite.scale = Vector2(scale_factor, length_factor)
	$Glow.scale = Vector2(scale_factor * 1.2, length_factor)
	$Core.scale = Vector2(scale_factor * 0.8, length_factor * 0.9)
	$Trail.scale = Vector2(scale_factor, length_factor)
	$Trail2.scale = Vector2(scale_factor, length_factor)
	$OuterGlow.scale = Vector2(scale_factor * 1.5, length_factor)

	# Also scale collision to match visual size
	if $CollisionShape2D.shape is CapsuleShape2D:
		$CollisionShape2D.shape.radius = 4.0 * scale_factor
		$CollisionShape2D.shape.height = 20.0 * length_factor

func _process(delta):
	# Store trail positions for curved visual effect
	trail_positions.append(global_position)
	if trail_positions.size() > max_trail_length:
		trail_positions.pop_front()

	# Find and track nearest enemy for homing
	update_homing_target()

	# Apply homing behavior if we have a target
	if target_enemy and is_instance_valid(target_enemy):
		# Calculate desired direction to target
		var to_target = (target_enemy.global_position - global_position).normalized()
		var angle_to_target = direction.angle_to(to_target)

		# If target goes behind us (more than 90 degrees), abandon it
		if abs(angle_to_target) > PI/2:
			target_enemy = null  # Abandon target that went behind
		else:
			# Smoothly rotate current direction towards target
			var turn_speed = homing_strength * delta
			direction = direction.rotated(angle_to_target * min(turn_speed, 1.0))
			direction = direction.normalized()

			# Visual feedback: rotate the bullet to match direction
			rotation = direction.angle() + PI/2

	# Move the bullet
	position += direction * speed * delta

	# Update trail visuals to show curve
	update_trail_visual()

	lifetime += delta
	if lifetime > max_lifetime:
		call_deferred("queue_free")

func update_trail_visual():
	# Dynamically adjust trail based on recent positions to show curve
	if trail_positions.size() >= 2:
		var trail_node = $Trail
		var trail2_node = $Trail2 if has_node("Trail2") else null

		# Calculate trail direction from recent positions
		var last_pos = trail_positions[-1]
		var prev_pos = trail_positions[-2] if trail_positions.size() >= 2 else last_pos

		# Elongate trail in opposite direction of movement to show path
		var trail_dir = (prev_pos - last_pos).normalized()
		if trail_dir.length() > 0:
			# Primary trail
			trail_node.polygon = PackedVector2Array([
				Vector2(-5, 10),
				Vector2(-5, 25) + trail_dir * 15,
				Vector2(5, 25) + trail_dir * 15,
				Vector2(5, 10)
			])

			# Secondary trail (if exists)
			if trail2_node:
				trail2_node.polygon = PackedVector2Array([
					Vector2(-3, 25) + trail_dir * 15,
					Vector2(-3, 40) + trail_dir * 25,
					Vector2(3, 40) + trail_dir * 25,
					Vector2(3, 25) + trail_dir * 15
				])

func update_homing_target():
	# Once a target is locked, never change it (prevents retargeting)
	if target_enemy and is_instance_valid(target_enemy):
		return  # Keep the current target until it's destroyed or bullet expires

	# Only find a target if we don't have one yet
	if not target_enemy or not is_instance_valid(target_enemy):
		var enemies = get_tree().get_nodes_in_group("enemies")
		var best_enemy: Area2D = null
		var best_score = INF

		for enemy in enemies:
			if not is_instance_valid(enemy) or enemy in hit_enemies:
				continue

			# ONLY target visible enemies - skip offscreen entirely
			var is_visible = true
			if enemy.has_method("is_visible_for_damage"):
				is_visible = enemy.is_visible_for_damage()

			if not is_visible:
				continue  # Skip offscreen enemies completely

			var distance = global_position.distance_to(enemy.global_position)
			if distance > homing_range:
				continue

			# Score based on distance and angle (prefer enemies ahead)
			var to_enemy = (enemy.global_position - global_position).normalized()
			var angle_diff = direction.angle_to(to_enemy)

			# Skip enemies that are behind the bullet (more than 90 degrees off)
			if abs(angle_diff) > PI/2:
				continue  # Don't target enemies behind us

			var score = distance + abs(angle_diff) * 100  # Weight angle difference

			if score < best_score:
				best_score = score
				best_enemy = enemy

		target_enemy = best_enemy

func _on_area_entered(area):
	if area.is_in_group("enemies") and not area in hit_enemies:
		# Only damage enemies that are visible on screen
		var is_visible = true
		if area.has_method("is_visible_for_damage"):
			is_visible = area.is_visible_for_damage()

		if is_visible:
			# Damage the first enemy
			area.take_damage(damage)
			hit_enemies.append(area)

			# Create impact effect
			create_impact_effect(area.global_position)

			# Chain lightning based on weapon level
			var chains_remaining = weapon_level  # Level 1 = 1 chain, Level 5 = 5 chains
			chain_lightning(area.global_position, chains_remaining)

			# Destroy the projectile after first hit
			call_deferred("queue_free")

func chain_lightning(from_position: Vector2, chains_remaining: int):
	if chains_remaining <= 0:
		return

	# Find nearest enemy within chain range
	var chain_range = 200.0 + (weapon_level * 50.0)  # Longer range at higher levels
	var nearest_enemy = find_nearest_enemy(from_position, chain_range)

	if nearest_enemy:
		# Only chain to visible enemies
		var is_visible = true
		if nearest_enemy.has_method("is_visible_for_damage"):
			is_visible = nearest_enemy.is_visible_for_damage()

		if is_visible:
			# Damage the chained enemy
			nearest_enemy.take_damage(damage)
			hit_enemies.append(nearest_enemy)

			# Create lightning arc visual effect
			create_lightning_arc(from_position, nearest_enemy.global_position)

			# Create impact effect on chained enemy
			create_impact_effect(nearest_enemy.global_position)

			# Continue the chain
			chain_lightning(nearest_enemy.global_position, chains_remaining - 1)

func find_nearest_enemy(from_pos: Vector2, max_range: float) -> Area2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_enemy: Area2D = null
	var nearest_distance = max_range

	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy in hit_enemies:
			continue

		# ONLY consider visible enemies for chaining
		var is_visible = true
		if enemy.has_method("is_visible_for_damage"):
			is_visible = enemy.is_visible_for_damage()

		if not is_visible:
			continue  # Skip offscreen enemies completely

		var distance = from_pos.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_enemy = enemy
			nearest_distance = distance

	return nearest_enemy

func create_lightning_arc(start_pos: Vector2, end_pos: Vector2):
	# Find the game scene to add effects to
	var game_scene = get_tree().current_scene
	if not game_scene:
		return

	# Create a container node for the lightning effect
	var lightning_container = Node2D.new()
	lightning_container.global_position = Vector2.ZERO  # Use world coordinates

	# Create main lightning arc using Line2D
	var lightning = Line2D.new()
	lightning.width = 4.0 + (weapon_level * 2.0)
	lightning.default_color = Color(0.8, 0.9, 1.0, 0.9)  # Electric blue-white
	lightning.z_index = 10

	# Create a slightly jagged line for lightning effect
	var mid_point = (start_pos + end_pos) * 0.5
	var perpendicular = (end_pos - start_pos).normalized().rotated(PI/2)
	var offset = randf_range(-30, 30)
	mid_point += perpendicular * offset

	# Use global positions directly
	lightning.add_point(start_pos)
	lightning.add_point(mid_point)
	lightning.add_point(end_pos)

	# Add glow effect
	var glow = Line2D.new()
	glow.width = lightning.width * 2.5
	glow.default_color = Color(0.6, 0.8, 1.0, 0.3)
	glow.z_index = 9
	glow.add_point(start_pos)
	glow.add_point(mid_point)
	glow.add_point(end_pos)

	# Add to container
	lightning_container.add_child(glow)
	lightning_container.add_child(lightning)

	# Add container to game scene
	game_scene.add_child(lightning_container)

	# Animate and cleanup - use efficient timer
	get_tree().create_timer(0.1).timeout.connect(lightning_container.queue_free)

	# Also fade out the effect
	var tween = lightning_container.create_tween()
	tween.tween_property(lightning_container, "modulate:a", 0, 0.1)

func create_impact_effect(impact_pos: Vector2):
	# Find the game scene to add effects to
	var game_scene = get_tree().current_scene
	if not game_scene:
		return

	# Electric impact effect - optimized particle count
	var flash = CPUParticles2D.new()
	flash.global_position = impact_pos
	flash.emitting = true
	flash.amount = min(10 + weapon_level * 2, 30)  # Reduced and capped particles
	flash.lifetime = 0.2  # Shorter lifetime
	flash.one_shot = true
	flash.initial_velocity_min = 50
	flash.initial_velocity_max = 150
	flash.scale_amount_min = 0.3
	flash.scale_amount_max = 0.8
	flash.color = Color(0.8, 0.9, 1.0, 1.0)  # Electric blue-white
	flash.direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	flash.spread = 60.0

	# Add to game scene
	game_scene.add_child(flash)

	# Auto cleanup - use efficient timer
	get_tree().create_timer(0.3).timeout.connect(flash.queue_free)

func _on_screen_exited():
	call_deferred("queue_free")