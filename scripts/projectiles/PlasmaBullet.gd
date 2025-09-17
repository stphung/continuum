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
var max_trail_length = 12

# Animation variables
var time_alive: float = 0.0
var pulse_intensity: float = 1.0
var core_base_scale: Vector2
var glow_base_scale: Vector2

func _ready():
	add_to_group("player_bullets")
	_initialize_bullet()

func _initialize_bullet():
	# Fixed damage of 1, same as vulcan
	damage = 1

	# Set homing parameters based on weapon level
	# Level 1: Very subtle homing
	# Level 10: Aggressive homing that rarely misses
	homing_strength = weapon_level * 1.0  # 1 to 10 radians/sec
	homing_range = 150.0 + (weapon_level * 20.0)  # 170 to 350 pixels

	# Scale bullet visuals based on level (thicker and longer)
	var scale_factor = 1.0 + (weapon_level - 1) * 0.05  # 1.0x to 1.45x at level 10
	var length_factor = 1.0 + (weapon_level - 1) * 0.1  # 1.0x to 1.9x length at level 10

	# Store base scales for animation
	core_base_scale = Vector2(scale_factor * 0.8, length_factor * 0.9)
	glow_base_scale = Vector2(scale_factor * 1.2, length_factor)

	# Update all visual components to be thicker and longer
	$Sprite.scale = Vector2(scale_factor, length_factor)
	$Glow.scale = glow_base_scale
	$Core.scale = core_base_scale
	$OuterGlow.scale = Vector2(scale_factor * 1.5, length_factor)

	# Set up Line2D trail properties based on weapon level
	$FluidTrail.width = 6.0 + (weapon_level * 1.5)
	$FluidTrail2.width = 10.0 + (weapon_level * 2.0)

	# Scale particle effects based on weapon level
	if has_node("EnergyParticles"):
		$EnergyParticles.amount = 10 + (weapon_level * 2)
		$EnergyParticles.emission_sphere_radius = 4.0 + (weapon_level * 0.5)

	# Also scale collision to match visual size
	if $CollisionShape2D.shape is CapsuleShape2D:
		$CollisionShape2D.shape.radius = 4.0 * scale_factor
		$CollisionShape2D.shape.height = 20.0 * length_factor

func _process(delta):
	time_alive += delta

	# Store trail positions for curved visual effect
	trail_positions.append(global_position)
	if trail_positions.size() > max_trail_length:
		trail_positions.pop_front()

	# Update pulsing animation
	update_pulsing_animation(delta)

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

	# Update fluid trail system
	update_fluid_trail()

	# Update particle direction based on movement
	if has_node("EnergyParticles"):
		$EnergyParticles.direction = -direction

	lifetime += delta
	if lifetime > max_lifetime:
		call_deferred("queue_free")

func update_pulsing_animation(delta):
	# Create smooth pulsing effect using sine waves
	var pulse_speed = 8.0 + (weapon_level * 0.5)  # Faster pulse at higher levels
	pulse_intensity = 0.9 + sin(time_alive * pulse_speed) * 0.2  # Pulse between 0.7 and 1.1

	# Apply pulsing to core and glow
	if has_node("Core"):
		$Core.scale = core_base_scale * pulse_intensity
		# Add slight color pulsing
		var pulse_brightness = 0.8 + sin(time_alive * pulse_speed * 2) * 0.2
		$Core.modulate = Color(1, 1, 1, pulse_brightness)

	if has_node("Glow"):
		$Glow.scale = glow_base_scale * (0.9 + sin(time_alive * pulse_speed * 0.7) * 0.15)

	# Add rotation effect to main sprite for energy feel
	if has_node("Sprite"):
		$Sprite.rotation = sin(time_alive * 4.0) * 0.05  # Slight oscillation

func update_fluid_trail():
	# Create smooth curved trail through all trail positions
	if trail_positions.size() >= 2 and has_node("FluidTrail"):
		var trail = $FluidTrail
		var trail2 = $FluidTrail2 if has_node("FluidTrail2") else null

		# Clear existing points
		trail.clear_points()
		if trail2:
			trail2.clear_points()

		# Add points with smooth interpolation
		var points_to_add = min(trail_positions.size(), max_trail_length)
		for i in range(points_to_add):
			var pos = trail_positions[trail_positions.size() - 1 - i]
			var relative_pos = pos - global_position

			# Add smooth curve by slightly offsetting alternating points
			var curve_offset = Vector2(sin(i * 0.3) * 2.0, 0)
			trail.add_point(relative_pos + curve_offset)

			# Secondary trail with more offset for layered effect
			if trail2 and i % 2 == 0:  # Add every other point for smoother secondary trail
				trail2.add_point(relative_pos + curve_offset * 1.5)

		# Animate trail width based on speed and weapon level
		var base_width = 6.0 + (weapon_level * 1.5)
		var speed_factor = clamp(direction.length() * 2.0, 0.8, 1.5)
		var animated_width = base_width * speed_factor * pulse_intensity
		trail.width = animated_width

		if trail2:
			trail2.width = (10.0 + (weapon_level * 2.0)) * speed_factor * (pulse_intensity * 0.8)

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
	var chain_range = 200.0 + (weapon_level * 50.0)  # 250-700 pixels (level 1-10)
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