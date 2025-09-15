extends Area2D

@export var damage = 2
@export var beam_length = 400.0
@export var beam_segments = 8
@export var bend_strength = 1.0
@export var lock_on_range = 150.0

var weapon_level = 1
var direction = Vector2.UP
var lifetime = 0.0
var max_lifetime = 0.8  # Shorter lifetime for continuous beam

# Beam mechanics
var beam_line: Line2D
var beam_points: Array[Vector2] = []
var target_enemies: Array[Area2D] = []
var damage_timer = 0.0
var damage_interval = 0.1  # Damage every 0.1 seconds

# Progressive evolution
var evolution_time = 0.0
var is_beam_mode = false
var rapid_fire_shots = 0

func _ready():
	add_to_group("player_bullets")

	# Scale properties based on weapon level
	damage = 1 + weapon_level  # Lower base damage due to continuous nature

	# Level 1 stays as rapid individual shots for backward compatibility
	if weapon_level == 1:
		setup_rapid_fire_mode()
	else:
		setup_beam_mode()

func setup_rapid_fire_mode():
	"""Level 1: Fast individual shots that evolve into beam"""
	is_beam_mode = false
	# Use simple projectile behavior for level 1

func setup_beam_mode():
	"""Level 2+: Continuous bending beam"""
	is_beam_mode = true
	beam_segments = 6 + weapon_level  # More segments at higher levels
	beam_length = 300 + (weapon_level * 50)  # Longer beam at higher levels
	lock_on_range = 120 + (weapon_level * 30)  # Better lock-on range

	# Create the visual beam using Line2D
	beam_line = Line2D.new()
	beam_line.width = 8 + (weapon_level * 2)  # Thicker beam at higher levels
	beam_line.default_color = Color(0.8, 0.2, 1.0, 0.9)  # Purple plasma color
	beam_line.joint_mode = Line2D.LINE_JOINT_ROUND
	beam_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	beam_line.end_cap_mode = Line2D.LINE_CAP_ROUND

	# Add glow effect
	var glow_line = Line2D.new()
	glow_line.width = beam_line.width * 2
	glow_line.default_color = Color(0.5, 0.1, 0.6, 0.3)
	glow_line.z_index = -1
	beam_line.add_child(glow_line)

	add_child(beam_line)

	# Initialize beam points
	initialize_beam_points()

func initialize_beam_points():
	"""Set up initial beam point positions"""
	beam_points.clear()

	for i in range(beam_segments + 1):
		var segment_progress = float(i) / float(beam_segments)
		var point_position = Vector2(0, -segment_progress * beam_length)
		beam_points.append(point_position)

	update_beam_visual()

func _process(delta):
	lifetime += delta
	damage_timer += delta
	evolution_time += delta

	if is_beam_mode:
		update_beam_mechanics(delta)
		if damage_timer >= damage_interval:
			apply_beam_damage()
			damage_timer = 0.0
	else:
		# Level 1 rapid fire behavior
		update_rapid_fire_mode(delta)

	# Auto-destruct after lifetime
	if lifetime > max_lifetime:
		call_deferred("queue_free")

func update_rapid_fire_mode(delta):
	"""Level 1: Simple fast projectile movement"""
	position += direction * 1200 * delta  # Fast movement

func update_beam_mechanics(delta):
	"""Update the bending beam physics and visuals"""
	find_target_enemies()
	update_beam_bending(delta)
	update_beam_visual()

func find_target_enemies():
	"""Find enemies within lock-on range for beam targeting"""
	target_enemies.clear()
	var max_targets = min(weapon_level, 3)  # More targets at higher levels

	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearby_enemies = []

	# Find all enemies in range
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= lock_on_range:
			nearby_enemies.append({"enemy": enemy, "distance": distance})

	# Sort by distance and take closest ones
	nearby_enemies.sort_custom(func(a, b): return a.distance < b.distance)

	for i in range(min(max_targets, nearby_enemies.size())):
		target_enemies.append(nearby_enemies[i].enemy)

func update_beam_bending(delta):
	"""Update beam point positions to create bending/toothpaste effect"""
	if beam_points.size() == 0:
		return

	# Update each beam segment with smooth following behavior
	for i in range(1, beam_points.size()):
		var current_point = beam_points[i]
		var previous_point = beam_points[i-1]

		# Default forward position
		var target_pos = previous_point + Vector2(0, -beam_length / beam_segments)

		# Bend toward nearest target enemy if we have one
		if target_enemies.size() > 0:
			var nearest_enemy = target_enemies[0]
			if is_instance_valid(nearest_enemy):
				var enemy_pos = to_local(nearest_enemy.global_position)
				var to_enemy = (enemy_pos - current_point).normalized()

				# Apply bending force based on weapon level
				var bend_force = bend_strength * (weapon_level * 0.3)
				target_pos = target_pos.lerp(enemy_pos, bend_force * delta)

		# Smooth movement toward target position (creates the toothpaste lag effect)
		var follow_speed = 8.0 + (weapon_level * 2.0)
		beam_points[i] = current_point.lerp(target_pos, follow_speed * delta)

func update_beam_visual():
	"""Update the Line2D visual representation"""
	if not beam_line:
		return

	beam_line.clear_points()
	for point in beam_points:
		beam_line.add_point(point)

	# Update glow line to match
	var glow_line = beam_line.get_child(0) as Line2D
	if glow_line:
		glow_line.clear_points()
		for point in beam_points:
			glow_line.add_point(point)

func apply_beam_damage():
	"""Apply continuous damage to enemies touching the beam"""
	if not is_beam_mode:
		return

	# Check collision along beam segments
	var space_state = get_world_2d().direct_space_state

	for i in range(beam_points.size() - 1):
		var start_point = global_position + beam_points[i]
		var end_point = global_position + beam_points[i + 1]

		# Cast a thick line segment to detect enemies
		var query = PhysicsRayQueryParameters2D.create(start_point, end_point)
		query.collision_mask = collision_mask
		query.collide_with_areas = true
		query.collide_with_bodies = false

		var result = space_state.intersect_ray(query)
		if result and result.collider and result.collider.is_in_group("enemies"):
			var enemy = result.collider
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
				create_beam_impact_effect(result.position)

func create_beam_impact_effect(impact_pos: Vector2):
	"""Create continuous damage effect along the beam"""
	var flash = CPUParticles2D.new()
	flash.global_position = impact_pos
	flash.emitting = true
	flash.amount = 6
	flash.lifetime = 0.2
	flash.one_shot = true
	flash.initial_velocity_min = 20
	flash.initial_velocity_max = 80
	flash.scale_amount_min = 0.2
	flash.scale_amount_max = 0.5
	flash.color = Color(1, 0.4, 1, 0.8)  # Bright plasma purple
	get_parent().add_child(flash)

	# Auto cleanup
	var timer = Timer.new()
	timer.wait_time = 0.3
	timer.one_shot = true
	timer.timeout.connect(flash.call_deferred.bind("queue_free"))
	flash.add_child(timer)
	timer.start()

func _on_area_entered(area):
	"""Handle collision for level 1 rapid fire mode"""
	if not is_beam_mode and area.is_in_group("enemies"):
		area.take_damage(damage)
		create_simple_impact_effect()
		call_deferred("queue_free")

func create_simple_impact_effect():
	"""Simple impact effect for level 1 mode"""
	var flash = CPUParticles2D.new()
	flash.position = position
	flash.emitting = true
	flash.amount = 8
	flash.lifetime = 0.2
	flash.one_shot = true
	flash.initial_velocity_min = 30
	flash.initial_velocity_max = 100
	flash.scale_amount_min = 0.3
	flash.scale_amount_max = 0.7
	flash.color = Color(0.9, 0.3, 0.9, 1.0)
	get_parent().add_child(flash)

	var timer = Timer.new()
	timer.wait_time = 0.3
	timer.one_shot = true
	timer.timeout.connect(flash.call_deferred.bind("queue_free"))
	flash.add_child(timer)
	timer.start()

func _on_screen_exited():
	call_deferred("queue_free")