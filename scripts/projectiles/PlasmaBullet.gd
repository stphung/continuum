extends Area2D

@export var damage = 2
@export var beam_length = 800.0
@export var segment_count = 20
@export var segment_size = 40.0
@export var lock_on_range = 450.0

var weapon_level = 1
var direction = Vector2.UP
var lifetime = 0.0
var max_lifetime = 1.8

# Simple snake-following mechanics (authentic Raiden approach)
var beam_line: Line2D
var segment_positions: Array[Vector2] = []
var target_enemy: Area2D = null
var damage_timer = 0.0
var damage_interval = 0.08

# Head movement
var head_position = Vector2.ZERO
var head_velocity = Vector2.ZERO
var head_speed = 600.0

var is_beam_mode = false

func _ready():
	add_to_group("player_bullets")

	# Scale properties with weapon level
	damage = 2 + (weapon_level * 2)

	if weapon_level == 1:
		setup_rapid_fire_mode()
	else:
		setup_snake_beam_mode()

func setup_rapid_fire_mode():
	"""Level 1: Fast individual shots"""
	is_beam_mode = false

func setup_snake_beam_mode():
	"""Level 2+: Simple snake-following beam"""
	is_beam_mode = true

	# Scale with weapon level
	segment_count = 15 + (weapon_level * 5)  # More segments = longer beam
	segment_size = 35.0 + (weapon_level * 5.0)  # Bigger segments
	lock_on_range = 350 + (weapon_level * 100)  # Better targeting
	head_speed = 500 + (weapon_level * 100)  # Faster head movement

	# Create visual beam
	beam_line = Line2D.new()
	beam_line.width = 10 + (weapon_level * 4)
	beam_line.default_color = Color(0.9, 0.4, 1.0, 0.95)
	beam_line.joint_mode = Line2D.LINE_JOINT_ROUND
	beam_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	beam_line.end_cap_mode = Line2D.LINE_CAP_ROUND

	# Add glow layers
	for i in range(3):
		var glow_line = Line2D.new()
		glow_line.width = beam_line.width * (1.5 + i * 0.4)
		var alpha = 0.4 - (i * 0.08)
		glow_line.default_color = Color(0.6, 0.3, 0.8, alpha)
		glow_line.z_index = -1 - i
		beam_line.add_child(glow_line)

	add_child(beam_line)
	initialize_snake()

func initialize_snake():
	"""Initialize the snake segments"""
	segment_positions.clear()
	head_position = Vector2.ZERO

	# Start all segments at ship position, spaced along initial direction
	for i in range(segment_count):
		var pos = Vector2(0, i * segment_size)  # Spaced behind ship
		segment_positions.append(pos)

	update_beam_visual()

func _process(delta):
	lifetime += delta
	damage_timer += delta

	if is_beam_mode:
		update_snake_beam(delta)
		if damage_timer >= damage_interval:
			apply_snake_damage()
			damage_timer = 0.0
	else:
		# Level 1 rapid fire
		position += direction * 1200 * delta

	if lifetime > max_lifetime:
		call_deferred("queue_free")

func update_snake_beam(delta):
	"""Update the snake beam using simple following mechanics"""
	find_target_enemy()
	update_head_movement(delta)
	update_snake_following(delta)
	update_beam_visual()

func find_target_enemy():
	"""Find the nearest enemy for the head to target"""
	target_enemy = null
	var nearest_distance = lock_on_range

	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			target_enemy = enemy

func update_head_movement(delta):
	"""Update the head position - this is what drives the snake"""
	var target_direction = Vector2.UP  # Default forward

	if target_enemy and is_instance_valid(target_enemy):
		# Head moves directly toward enemy
		var enemy_pos = to_local(target_enemy.global_position)
		target_direction = (enemy_pos - head_position).normalized()
	else:
		# No enemy: move forward
		target_direction = Vector2.UP

	# Smooth head movement
	var turn_speed = 6.0 + (weapon_level * 1.5)
	head_velocity = head_velocity.lerp(target_direction * head_speed, turn_speed * delta)

	# Update head position
	head_position += head_velocity * delta

	# Keep head as first segment
	if segment_positions.size() > 0:
		segment_positions[0] = head_position

func update_snake_following(delta):
	"""Each segment follows the previous segment - this creates the snake effect"""
	if segment_positions.size() <= 1:
		return

	# Each segment smoothly follows the one in front of it
	for i in range(1, segment_positions.size()):
		var current_pos = segment_positions[i]
		var target_pos = segment_positions[i - 1]  # Follow previous segment

		# Calculate direction to follow
		var to_target = target_pos - current_pos
		var distance = to_target.length()

		# If too far, move closer
		if distance > segment_size:
			var follow_direction = to_target.normalized()
			var follow_speed = 400.0 + (weapon_level * 80.0)
			segment_positions[i] = current_pos + follow_direction * follow_speed * delta
		else:
			# If close enough, just smooth interpolation
			var follow_speed = 8.0 + (weapon_level * 2.0)
			segment_positions[i] = current_pos.lerp(target_pos, follow_speed * delta)

func update_beam_visual():
	"""Update the visual representation"""
	if not beam_line:
		return

	# Update main beam line
	beam_line.clear_points()
	for pos in segment_positions:
		beam_line.add_point(pos)

	# Update glow layers
	for i in range(beam_line.get_child_count()):
		var glow_line = beam_line.get_child(i) as Line2D
		if glow_line:
			glow_line.clear_points()
			for pos in segment_positions:
				glow_line.add_point(pos)

func apply_snake_damage():
	"""Apply damage along the snake path"""
	if not is_beam_mode or segment_positions.size() < 2:
		return

	var space_state = get_world_2d().direct_space_state
	var beam_width = 10 + (weapon_level * 4)

	# Check collision along each segment
	for i in range(segment_positions.size() - 1):
		var start_point = global_position + segment_positions[i]
		var end_point = global_position + segment_positions[i + 1]

		# Cast ray for collision detection
		var query = PhysicsRayQueryParameters2D.create(start_point, end_point)
		query.collision_mask = collision_mask
		query.collide_with_areas = true
		query.collide_with_bodies = false

		var result = space_state.intersect_ray(query)
		if result and result.collider and result.collider.is_in_group("enemies"):
			var enemy = result.collider
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
				create_snake_impact_effect(result.position)

		# Additional rays for thicker beam
		var perpendicular = (end_point - start_point).normalized().rotated(PI/2)
		for offset in [-beam_width/2, beam_width/2]:
			var offset_start = start_point + perpendicular * offset
			var offset_end = end_point + perpendicular * offset

			var offset_query = PhysicsRayQueryParameters2D.create(offset_start, offset_end)
			offset_query.collision_mask = collision_mask
			offset_query.collide_with_areas = true
			offset_query.collide_with_bodies = false

			var offset_result = space_state.intersect_ray(offset_query)
			if offset_result and offset_result.collider and offset_result.collider.is_in_group("enemies"):
				var enemy = offset_result.collider
				if enemy.has_method("take_damage"):
					enemy.take_damage(damage)

func create_snake_impact_effect(impact_pos: Vector2):
	"""Create impact effects for the snake beam"""
	var flash = CPUParticles2D.new()
	flash.global_position = impact_pos
	flash.emitting = true
	flash.amount = 8 + weapon_level * 2
	flash.lifetime = 0.2
	flash.one_shot = true
	flash.initial_velocity_min = 30
	flash.initial_velocity_max = 100
	flash.scale_amount_min = 0.3
	flash.scale_amount_max = 0.8
	flash.color = Color(1, 0.5, 1, 1.0)
	flash.direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	flash.spread = 60.0
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