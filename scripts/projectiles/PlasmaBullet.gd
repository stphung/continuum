extends Area2D

@export var speed = 1000
@export var damage = 3

var weapon_level = 1
var direction = Vector2.UP
var lifetime = 0.0
var max_lifetime = 3.0
var hit_enemies: Array[Area2D] = []

func _ready():
	add_to_group("player_bullets")

	# Scale damage with weapon level
	damage = 3 + (weapon_level * 2)

func _process(delta):
	# Simple projectile movement like Bullet.gd
	position += direction * speed * delta

	lifetime += delta
	if lifetime > max_lifetime:
		call_deferred("queue_free")

func _on_area_entered(area):
	if area.is_in_group("enemies") and not area in hit_enemies:
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

		var distance = from_pos.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_enemy = enemy
			nearest_distance = distance

	return nearest_enemy

func create_lightning_arc(start_pos: Vector2, end_pos: Vector2):
	# Create a lightning arc effect using Line2D
	var lightning = Line2D.new()
	lightning.width = 4.0 + (weapon_level * 2.0)
	lightning.default_color = Color(0.8, 0.9, 1.0, 0.9)  # Electric blue-white
	lightning.z_index = 10

	# Create a slightly jagged line for lightning effect
	var mid_point = (start_pos + end_pos) * 0.5
	var perpendicular = (end_pos - start_pos).normalized().rotated(PI/2)
	var offset = randf_range(-30, 30)
	mid_point += perpendicular * offset

	lightning.add_point(to_local(start_pos))
	lightning.add_point(to_local(mid_point))
	lightning.add_point(to_local(end_pos))

	# Add glow effect
	var glow = Line2D.new()
	glow.width = lightning.width * 2.5
	glow.default_color = Color(0.6, 0.8, 1.0, 0.3)
	glow.z_index = 9
	glow.add_point(to_local(start_pos))
	glow.add_point(to_local(mid_point))
	glow.add_point(to_local(end_pos))

	get_parent().add_child(lightning)
	get_parent().add_child(glow)

	# Animate and cleanup
	var tween = create_tween()
	tween.parallel().tween_property(lightning, "modulate:a", 0, 0.2)
	tween.parallel().tween_property(glow, "modulate:a", 0, 0.2)
	tween.tween_callback(func():
		lightning.queue_free()
		glow.queue_free()
	)

func create_impact_effect(impact_pos: Vector2):
	# Electric impact effect
	var flash = CPUParticles2D.new()
	flash.global_position = impact_pos
	flash.emitting = true
	flash.amount = 15 + weapon_level * 3
	flash.lifetime = 0.3
	flash.one_shot = true
	flash.initial_velocity_min = 50
	flash.initial_velocity_max = 150
	flash.scale_amount_min = 0.3
	flash.scale_amount_max = 0.8
	flash.color = Color(0.8, 0.9, 1.0, 1.0)  # Electric blue-white
	flash.direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	flash.spread = 60.0
	get_parent().add_child(flash)

	# Auto cleanup
	var timer = Timer.new()
	timer.wait_time = 0.4
	timer.one_shot = true
	timer.timeout.connect(flash.call_deferred.bind("queue_free"))
	flash.add_child(timer)
	timer.start()

func _on_screen_exited():
	call_deferred("queue_free")