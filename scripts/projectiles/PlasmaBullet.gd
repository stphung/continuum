extends Area2D

@export var speed = 1000
@export var damage = 2
@export var homing_strength = 0.0
@export var max_turn_rate = 2.0

var direction = Vector2.UP
var target_enemy: Area2D = null
var weapon_level = 1
var lifetime = 0.0
var max_lifetime = 3.0
var homing_range = 200.0

func _ready():
	add_to_group("player_bullets")

	# Scale properties based on weapon level
	damage = 2 + weapon_level

	# Higher levels get stronger homing
	match weapon_level:
		1:
			homing_strength = 0.0  # No homing, just fast forward shots
		2:
			homing_strength = 0.5  # Light homing
		3:
			homing_strength = 1.0  # Medium homing
		4:
			homing_strength = 1.5  # Strong homing
		5:
			homing_strength = 2.0  # Very strong homing
			homing_range = 300.0   # Longer range at max level

	# Scale visual size based on level
	var scale_factor = 1.0 + (weapon_level - 1) * 0.15
	scale = Vector2(scale_factor, scale_factor)

	# Add pulsing plasma effect
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "modulate:a", 0.8, 0.1)
	tween.tween_property(self, "modulate:a", 1.0, 0.1)

func _process(delta):
	lifetime += delta

	# Apply homing behavior if enabled and we have a target
	if homing_strength > 0.0:
		find_nearest_enemy()
		apply_homing(delta)

	# Move forward
	position += direction * speed * delta

	# Auto-destruct after lifetime
	if lifetime > max_lifetime:
		call_deferred("queue_free")

func find_nearest_enemy():
	# Only search for new target if we don't have one or current target is invalid
	if target_enemy == null or not is_instance_valid(target_enemy):
		target_enemy = null
		var nearest_distance = homing_range

		# Find all enemies in range
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if not is_instance_valid(enemy):
				continue

			var distance = position.distance_to(enemy.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				target_enemy = enemy

func apply_homing(delta):
	if target_enemy and is_instance_valid(target_enemy):
		# Calculate direction to target
		var target_direction = (target_enemy.global_position - position).normalized()

		# Gradually turn towards target based on homing strength
		var turn_amount = homing_strength * max_turn_rate * delta
		direction = direction.lerp(target_direction, turn_amount).normalized()

		# Rotate sprite to match direction for visual feedback
		rotation = direction.angle() + PI/2

func _on_area_entered(area):
	if area.is_in_group("enemies"):
		area.take_damage(damage)

		# Create plasma impact effect
		create_plasma_impact_effect()

		# Plasma bullets always destroy on hit (no piercing)
		call_deferred("queue_free")

func create_plasma_impact_effect():
	var flash = CPUParticles2D.new()
	flash.position = position
	flash.emitting = true
	flash.amount = 12
	flash.lifetime = 0.3
	flash.one_shot = true
	flash.initial_velocity_min = 30
	flash.initial_velocity_max = 120
	flash.scale_amount_min = 0.2
	flash.scale_amount_max = 0.6
	flash.color = Color(1, 0.3, 1, 1)  # Bright magenta/purple
	flash.direction = Vector2(0, -1)
	flash.spread = 45.0
	get_parent().add_child(flash)

	# Add brief purple screen flash for impact feedback
	var impact_flash = ColorRect.new()
	impact_flash.color = Color(0.8, 0.2, 0.8, 0.1)
	impact_flash.size = Vector2(50, 50)
	impact_flash.position = position - Vector2(25, 25)
	get_parent().add_child(impact_flash)

	# Quick fade out
	var tween = create_tween()
	tween.tween_property(impact_flash, "modulate:a", 0, 0.2)
	tween.tween_callback(impact_flash.queue_free)

	# Clean up particle effect after a delay
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.timeout.connect(flash.call_deferred.bind("queue_free"))
	flash.add_child(timer)
	timer.start()

func _on_screen_exited():
	call_deferred("queue_free")