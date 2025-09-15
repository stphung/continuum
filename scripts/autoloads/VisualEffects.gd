extends Node

# Safe cleanup function to prevent physics state errors
func safe_cleanup_node(node: Node):
	if not is_instance_valid(node):
		return

	# If it's an Area2D, disable monitoring before freeing to prevent physics state conflicts
	if node is Area2D:
		var area = node as Area2D
		call_deferred("_disable_area_monitoring", area)
	else:
		# For non-Area2D nodes, just queue free them normally
		node.call_deferred("queue_free")

func _disable_area_monitoring(area: Area2D):
	if is_instance_valid(area):
		area.monitoring = false
		area.monitorable = false
		area.call_deferred("queue_free")

func create_explosion(type: String, pos: Vector2, effects_parent: Node):
	match type:
		"enemy_destroy":
			_create_enemy_explosion(pos, effects_parent)
		"bomb":
			_create_bomb_explosion(pos, effects_parent)
		"player_death":
			_create_player_explosion(pos, effects_parent)

func _create_enemy_explosion(pos: Vector2, effects_parent: Node):
	var explosion = _create_particle_system(pos, {
		"amount": 45,
		"lifetime": 1.0,
		"velocity_min": 80,
		"velocity_max": 350,
		"scale_min": 0.8,
		"scale_max": 2.5,
		"color": Color(1, 0.4, 0, 1)
	})
	effects_parent.add_child(explosion)

	var core = _create_particle_system(pos, {
		"amount": 20,
		"lifetime": 0.4,
		"velocity_min": 20,
		"velocity_max": 120,
		"scale_min": 1.0,
		"scale_max": 2.0,
		"color": Color(1, 1, 0.6, 1)
	})
	effects_parent.add_child(core)

	var outer_burst = _create_particle_system(pos, {
		"amount": 30,
		"lifetime": 0.8,
		"velocity_min": 200,
		"velocity_max": 500,
		"scale_min": 0.3,
		"scale_max": 1.2,
		"color": Color(1, 0.2, 0.1, 1),
		"gravity": Vector2(0, 30)
	})
	effects_parent.add_child(outer_burst)

	_create_shockwave(pos, effects_parent, 15, Vector2(3, 3), 0.4)
	_schedule_cleanup([explosion, core, outer_burst], effects_parent, 1.5)

func _create_player_explosion(pos: Vector2, effects_parent: Node):
	var explosion = _create_particle_system(pos, {
		"amount": 60,
		"lifetime": 1.5,
		"velocity_min": 80,
		"velocity_max": 400,
		"scale_min": 0.5,
		"scale_max": 3.0,
		"color": Color(1, 0.3, 0, 1)
	})
	effects_parent.add_child(explosion)

	var core_explosion = _create_particle_system(pos, {
		"amount": 25,
		"lifetime": 0.8,
		"velocity_min": 30,
		"velocity_max": 200,
		"scale_min": 0.8,
		"scale_max": 2.5,
		"color": Color(1, 1, 0.8, 1)
	})
	effects_parent.add_child(core_explosion)

	_schedule_cleanup([explosion, core_explosion], effects_parent, 2.0)

func _create_bomb_explosion(pos: Vector2, effects_parent: Node):
	var mega_explosion = _create_particle_system(pos, {
		"amount": 100,
		"lifetime": 1.5,
		"velocity_min": 100,
		"velocity_max": 800,
		"scale_min": 1.0,
		"scale_max": 4.0,
		"color": Color(1, 0.8, 0, 1),
		"angular_velocity_min": -720,
		"angular_velocity_max": 720
	})
	effects_parent.add_child(mega_explosion)

	for ring_i in range(5):
		var shockwave = _create_shockwave_ring(pos, ring_i)
		effects_parent.add_child(shockwave)

		# Create timer-based delay for rings
		if ring_i > 0:
			var timer = Timer.new()
			timer.wait_time = ring_i * 0.1
			timer.one_shot = true
			effects_parent.add_child(timer)
			timer.timeout.connect(func():
				var ring_tween = effects_parent.create_tween()
				ring_tween.tween_property(shockwave, "scale", Vector2(8, 8), 0.8)
				ring_tween.parallel().tween_property(shockwave, "modulate:a", 0, 0.8)
				ring_tween.tween_callback(func(): safe_cleanup_node(shockwave))
				timer.queue_free()
			)
			timer.start()
		else:
			# First ring starts immediately
			var ring_tween = effects_parent.create_tween()
			ring_tween.tween_property(shockwave, "scale", Vector2(8, 8), 0.8)
			ring_tween.parallel().tween_property(shockwave, "modulate:a", 0, 0.8)
			ring_tween.tween_callback(shockwave.queue_free)

	_create_screen_flash_sequence(effects_parent)
	_schedule_cleanup([mega_explosion], effects_parent, 2.0)

func _create_particle_system(pos: Vector2, config: Dictionary) -> CPUParticles2D:
	var particles = CPUParticles2D.new()
	particles.position = pos
	particles.emitting = true
	particles.one_shot = true

	particles.amount = config.get("amount", 30)
	particles.lifetime = config.get("lifetime", 1.0)
	particles.initial_velocity_min = config.get("velocity_min", 50)
	particles.initial_velocity_max = config.get("velocity_max", 200)
	particles.scale_amount_min = config.get("scale_min", 0.5)
	particles.scale_amount_max = config.get("scale_max", 2.0)
	particles.color = config.get("color", Color.WHITE)

	if config.has("angular_velocity_min"):
		particles.angular_velocity_min = config.angular_velocity_min
		particles.angular_velocity_max = config.get("angular_velocity_max", 360)
	else:
		particles.angular_velocity_min = -360
		particles.angular_velocity_max = 360

	if config.has("gravity"):
		particles.gravity = config.gravity

	return particles

func _create_shockwave(pos: Vector2, parent: Node, radius: float, max_scale: Vector2, duration: float):
	var shockwave = Polygon2D.new()
	shockwave.position = pos
	shockwave.color = Color(1, 0.8, 0.4, 0.5)

	var points = PackedVector2Array()
	for i in range(12):
		var angle = i * PI * 2 / 12
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	shockwave.polygon = points
	parent.add_child(shockwave)

	var shockwave_tween = parent.create_tween()
	shockwave_tween.parallel().tween_property(shockwave, "scale", max_scale, duration)
	shockwave_tween.parallel().tween_property(shockwave, "modulate:a", 0, duration)
	shockwave_tween.tween_callback(shockwave.queue_free)

func _create_shockwave_ring(pos: Vector2, ring_index: int) -> Polygon2D:
	var shockwave = Polygon2D.new()
	shockwave.position = pos
	shockwave.color = Color(1, 1, 0.5, 0.4 - ring_index * 0.05)

	var points = PackedVector2Array()
	for i in range(20):
		var angle = i * PI * 2 / 20
		var radius = 30.0 + ring_index * 15
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	shockwave.polygon = points

	return shockwave

func _create_screen_flash_sequence(parent: Node):
	var flash = ColorRect.new()
	flash.size = Vector2(800, 900)
	flash.color = Color(1, 1, 0.8, 0.9)
	parent.add_child(flash)

	var flash_tween = parent.create_tween()
	flash_tween.tween_property(flash, "modulate:a", 0, 0.6)
	flash_tween.tween_callback(flash.queue_free)

	for pulse_i in range(3):
		var pulse_flash = ColorRect.new()
		pulse_flash.size = Vector2(800, 900)
		pulse_flash.color = Color(1, 0.9, 0.2, 0.2)
		parent.add_child(pulse_flash)

		# Create timer-based delay for pulses
		if pulse_i > 0:
			var timer = Timer.new()
			timer.wait_time = pulse_i * 0.15
			timer.one_shot = true
			parent.add_child(timer)
			timer.timeout.connect(func():
				var pulse_tween = parent.create_tween()
				pulse_tween.tween_property(pulse_flash, "modulate:a", 0, 0.1)
				pulse_tween.tween_callback(func(): safe_cleanup_node(pulse_flash))
				timer.queue_free()
			)
			timer.start()
		else:
			# First pulse starts immediately
			var pulse_tween = parent.create_tween()
			pulse_tween.tween_property(pulse_flash, "modulate:a", 0, 0.1)
			pulse_tween.tween_callback(pulse_flash.queue_free)

func _schedule_cleanup(particles: Array, parent: Node, delay: float):
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = delay
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func():
		for particle in particles:
			if is_instance_valid(particle):
				safe_cleanup_node(particle)
		cleanup_timer.queue_free()
	)
	parent.add_child(cleanup_timer)
	cleanup_timer.start()