extends Area2D

@export var damage = 2
@export var beam_length = 900.0  # Long reach across screen
@export var beam_segments = 16   # More segments for smooth curves
@export var max_bend_angle = 45.0  # Maximum bend per segment (degrees)
@export var lock_on_range = 500.0  # Massive targeting range

var weapon_level = 1
var direction = Vector2.UP
var lifetime = 0.0
var max_lifetime = 1.5  # Longer for dramatic effect

# Authentic Raiden beam mechanics using Bézier curves
var beam_line: Line2D
var control_points: Array[Vector2] = []  # Bézier control points
var beam_points: Array[Vector2] = []     # Final curve points
var target_enemies: Array[Area2D] = []
var damage_timer = 0.0
var damage_interval = 0.06  # Fast damage rate

# Sequential segment mechanics (authentic Raiden approach)
var segment_angles: Array[float] = []
var segment_directions: Array[Vector2] = []
var ship_movement_direction = Vector2.UP
var last_ship_position = Vector2.ZERO

var is_beam_mode = false

func _ready():
	add_to_group("player_bullets")

	# Scale properties dramatically with weapon level
	damage = 1 + (weapon_level * 2)

	# Level 1 stays as rapid individual shots
	if weapon_level == 1:
		setup_rapid_fire_mode()
	else:
		setup_authentic_beam_mode()

	last_ship_position = global_position

func setup_rapid_fire_mode():
	"""Level 1: Fast individual shots"""
	is_beam_mode = false

func setup_authentic_beam_mode():
	"""Level 2+: Authentic Raiden-style beam using Bézier curves"""
	is_beam_mode = true

	# Dramatic scaling based on research
	beam_segments = 12 + (weapon_level * 4)  # More segments = smoother curves
	beam_length = 700 + (weapon_level * 250)  # Up to 1950 pixels!
	lock_on_range = 400 + (weapon_level * 150)  # Massive range
	max_bend_angle = 35.0 + (weapon_level * 10.0)  # More flexible at higher levels

	# Create dramatic visual beam
	beam_line = Line2D.new()
	beam_line.width = 8 + (weapon_level * 5)  # Thick, substantial beam
	beam_line.default_color = Color(0.95, 0.4, 1.0, 0.98)  # Bright purple
	beam_line.joint_mode = Line2D.LINE_JOINT_ROUND
	beam_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	beam_line.end_cap_mode = Line2D.LINE_CAP_ROUND

	# Multiple glow layers for that authentic look
	for i in range(4):
		var glow_line = Line2D.new()
		glow_line.width = beam_line.width * (1.8 + i * 0.5)
		var alpha = 0.5 - (i * 0.08)
		glow_line.default_color = Color(0.7, 0.3, 0.9, alpha)
		glow_line.z_index = -1 - i
		beam_line.add_child(glow_line)

	add_child(beam_line)
	initialize_bezier_beam()

func initialize_bezier_beam():
	"""Initialize the Bézier-based beam system"""
	control_points.clear()
	beam_points.clear()
	segment_angles.clear()
	segment_directions.clear()

	# Initialize control points for Bézier curves
	var segments_count = beam_segments + 1
	for i in range(segments_count):
		var progress = float(i) / float(beam_segments)
		var point = Vector2(0, -progress * beam_length)
		control_points.append(point)
		segment_angles.append(0.0)
		segment_directions.append(Vector2.UP)

	generate_bezier_curve()

func _process(delta):
	lifetime += delta
	damage_timer += delta

	# Track ship movement for beam following
	var current_position = global_position
	ship_movement_direction = (current_position - last_ship_position).normalized()
	if ship_movement_direction.length() < 0.1:
		ship_movement_direction = Vector2.UP  # Default upward
	last_ship_position = current_position

	if is_beam_mode:
		update_authentic_beam(delta)
		if damage_timer >= damage_interval:
			apply_bezier_damage()
			damage_timer = 0.0
	else:
		# Level 1 rapid fire behavior
		position += direction * 1300 * delta

	# Auto-destruct
	if lifetime > max_lifetime:
		call_deferred("queue_free")

func update_authentic_beam(delta):
	"""Update beam using authentic Raiden mechanics"""
	find_priority_targets()
	update_sequential_segments(delta)
	generate_bezier_curve()
	update_beam_visual()

func find_priority_targets():
	"""Find enemies using Raiden's priority system"""
	target_enemies.clear()
	var max_targets = min(weapon_level + 2, 5)  # More targets at higher levels

	var enemies = get_tree().get_nodes_in_group("enemies")
	var priority_enemies = []

	# Find enemies within massive range and prioritize by distance and angle
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= lock_on_range:
			var angle_to_enemy = global_position.direction_to(enemy.global_position).angle()
			var priority = distance * 0.5 + abs(angle_to_enemy) * 50  # Closer + forward = higher priority
			priority_enemies.append({"enemy": enemy, "priority": priority})

	# Sort by priority and take the best targets
	priority_enemies.sort_custom(func(a, b): return a.priority < b.priority)

	for i in range(min(max_targets, priority_enemies.size())):
		target_enemies.append(priority_enemies[i].enemy)

func update_sequential_segments(delta):
	"""Update segments sequentially from ship, authentic Raiden style"""
	if control_points.size() <= 1:
		return

	# First segment always follows ship direction
	control_points[0] = Vector2.ZERO
	segment_directions[0] = ship_movement_direction
	segment_angles[0] = 0.0

	# Update each subsequent segment with bend angle limits
	for i in range(1, control_points.size()):
		var current_direction = segment_directions[i]
		var target_direction = Vector2.UP  # Default forward

		# Determine target direction: enemy lock-on or ship following
		if target_enemies.size() > 0:
			# Choose target enemy for this segment (distribute targets)
			var target_index = (i - 1) % target_enemies.size()
			var target_enemy = target_enemies[target_index]

			if is_instance_valid(target_enemy):
				var enemy_pos = to_local(target_enemy.global_position)
				var segment_pos = control_points[i-1]
				target_direction = (enemy_pos - segment_pos).normalized()
		else:
			# No enemies: follow ship movement direction
			target_direction = ship_movement_direction

		# Apply maximum bend angle constraint (authentic Raiden mechanic)
		var angle_diff = current_direction.angle_to(target_direction)
		var max_bend_radians = deg_to_rad(max_bend_angle)

		if abs(angle_diff) > max_bend_radians:
			# Limit bend to maximum angle
			var clamped_angle = sign(angle_diff) * max_bend_radians
			target_direction = current_direction.rotated(clamped_angle)

		# Smooth transition to new direction
		var turn_speed = 8.0 + (weapon_level * 2.0)
		segment_directions[i] = current_direction.lerp(target_direction, turn_speed * delta).normalized()
		segment_angles[i] = segment_directions[i].angle()

		# Calculate position using arc length (authentic approach)
		var segment_length = beam_length / beam_segments
		control_points[i] = control_points[i-1] + segment_directions[i] * segment_length

func generate_bezier_curve():
	"""Generate smooth Bézier curve from control points"""
	beam_points.clear()

	if control_points.size() < 3:
		beam_points = control_points.duplicate()
		return

	# Generate smooth curve using quadratic Bézier interpolation
	var curve_resolution = 3  # Points between each control point

	for i in range(control_points.size() - 1):
		var p0 = control_points[i]
		var p1 = control_points[i + 1]

		# Create control point for smooth curve
		var control_offset = Vector2.ZERO
		if i > 0:
			var prev_dir = (control_points[i] - control_points[i-1]).normalized()
			control_offset = prev_dir * 20.0  # Curve smoothness

		# Generate curve points
		for j in range(curve_resolution):
			var t = float(j) / float(curve_resolution)
			var curve_point = p0.lerp(p1, t) + control_offset * sin(t * PI) * 0.3
			beam_points.append(curve_point)

	# Add final point
	beam_points.append(control_points[-1])

func update_beam_visual():
	"""Update visual representation with all glow layers"""
	if not beam_line:
		return

	# Update main beam
	beam_line.clear_points()
	for point in beam_points:
		beam_line.add_point(point)

	# Update all glow layers
	for i in range(beam_line.get_child_count()):
		var glow_line = beam_line.get_child(i) as Line2D
		if glow_line:
			glow_line.clear_points()
			for point in beam_points:
				glow_line.add_point(point)

func apply_bezier_damage():
	"""Apply damage along the Bézier curve path"""
	if not is_beam_mode:
		return

	var space_state = get_world_2d().direct_space_state
	var beam_width = 8 + (weapon_level * 5)

	# Check collision along curve segments
	for i in range(beam_points.size() - 1):
		var start_point = global_position + beam_points[i]
		var end_point = global_position + beam_points[i + 1]

		# Multiple rays for thick beam collision
		var rays_count = 4
		for ray in range(rays_count):
			var offset_factor = (ray - 1.5) * (beam_width / 3)
			var perpendicular = (end_point - start_point).normalized().rotated(PI/2) * offset_factor

			var ray_start = start_point + perpendicular
			var ray_end = end_point + perpendicular

			var query = PhysicsRayQueryParameters2D.create(ray_start, ray_end)
			query.collision_mask = collision_mask
			query.collide_with_areas = true
			query.collide_with_bodies = false

			var result = space_state.intersect_ray(query)
			if result and result.collider and result.collider.is_in_group("enemies"):
				var enemy = result.collider
				if enemy.has_method("take_damage"):
					enemy.take_damage(damage)
					create_authentic_impact_effect(result.position)

func create_authentic_impact_effect(impact_pos: Vector2):
	"""Create authentic Raiden-style impact effects"""
	var flash = CPUParticles2D.new()
	flash.global_position = impact_pos
	flash.emitting = true
	flash.amount = 12 + weapon_level * 3
	flash.lifetime = 0.25
	flash.one_shot = true
	flash.initial_velocity_min = 40
	flash.initial_velocity_max = 140
	flash.scale_amount_min = 0.4
	flash.scale_amount_max = 1.0
	flash.color = Color(1, 0.6, 1, 1.0)  # Bright plasma purple
	flash.direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	flash.spread = 80.0
	get_parent().add_child(flash)

	# Dramatic screen flash at higher levels
	if weapon_level >= 4:
		var screen_flash = ColorRect.new()
		screen_flash.color = Color(0.9, 0.4, 0.9, 0.03)
		screen_flash.size = Vector2(120, 120)
		screen_flash.position = Vector2(impact_pos) - Vector2(60, 60)
		get_parent().add_child(screen_flash)

		var flash_tween = create_tween()
		flash_tween.tween_property(screen_flash, "modulate:a", 0, 0.12)
		flash_tween.tween_callback(screen_flash.queue_free)

	# Auto cleanup
	var timer = Timer.new()
	timer.wait_time = 0.35
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
	flash.amount = 10
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