extends Area2D

signal enemy_destroyed(points, position)

@export var enemy_type_data: Resource
@export var health = 3
@export var speed = 150
@export var points = 100
@export var movement_pattern = "straight"

var direction = Vector2.DOWN
var time_alive = 0.0
var initial_x
var dive_locked = false  # For dive pattern - lock direction after initial targeting
var max_health: int  # For visual damage states
var damage_reduction: float = 0.0
var weapon_type: String = "none"
var stop_timer: float = 0.0  # For stop_and_shoot pattern
var is_stopped: bool = false
var spawn_timer: float = 0.0  # For spawning enemies
var current_wave: int = 1

func _ready():
	add_to_group("enemies")
	initial_x = position.x

	# Initialize from enemy type data if provided
	if enemy_type_data:
		setup_from_type_data()
	else:
		# Ensure enemy has basic working values even without type data
		max_health = health
		weapon_type = "none"
		damage_reduction = 0.0

	$ShootTimer.wait_time = randf_range(1.5, 3.0)

func setup_from_type_data():
	if not enemy_type_data:
		return

	# Set properties from data
	health = enemy_type_data.get_scaled_health(current_wave)
	max_health = health
	speed = enemy_type_data.get_scaled_speed(current_wave)
	points = enemy_type_data.get_scaled_points(current_wave)
	movement_pattern = enemy_type_data.movement_pattern
	weapon_type = enemy_type_data.weapon_type
	damage_reduction = enemy_type_data.damage_reduction

	# Update visuals
	if has_node("Sprite"):
		$Sprite.color = enemy_type_data.sprite_color
		if enemy_type_data.sprite_polygon.size() > 0:
			$Sprite.polygon = enemy_type_data.sprite_polygon
		$Sprite.scale = Vector2.ONE * enemy_type_data.sprite_scale

	# Update collision
	if has_node("CollisionShape2D") and $CollisionShape2D.shape is CircleShape2D:
		($CollisionShape2D.shape as CircleShape2D).radius = enemy_type_data.collision_radius

	# Update shooting
	if weapon_type != "none":
		$ShootTimer.wait_time = enemy_type_data.fire_rate

func _process(delta):
	time_alive += delta
	spawn_timer += delta

	# Handle spawning for support carriers
	if enemy_type_data and enemy_type_data.spawns_enemies and spawn_timer >= 3.0:
		spawn_drone()
		spawn_timer = 0.0

	# Handle movement patterns
	match movement_pattern:
		"straight":
			position += direction * speed * delta
		"zigzag":
			position.y += speed * delta
			position.x = initial_x + sin(time_alive * 3) * 100
		"dive":
			# Standard shmup dive pattern: target player position at spawn time only, then continue straight
			if not dive_locked:
				var player = get_tree().get_first_node_in_group("player")
				if player:
					direction = (player.position - position).normalized()
					dive_locked = true  # Lock direction after first targeting - no more tracking
			position += direction * speed * delta
		"stop_and_shoot":
			# Heavy gunner pattern: move, stop, shoot burst, repeat
			stop_timer += delta
			if stop_timer >= 2.0:
				is_stopped = !is_stopped
				stop_timer = 0.0
				if is_stopped:
					# Fire rapid burst when stopping
					fire_rapid_burst()

			if not is_stopped:
				position += direction * speed * delta
		_:
			position += direction * speed * delta

func take_damage(damage):
	# Apply damage reduction for heavy enemies
	var actual_damage = damage
	if damage_reduction > 0.0:
		actual_damage = damage * (1.0 - damage_reduction)
		actual_damage = max(actual_damage, 0.1)  # Minimum damage to prevent immunity

	health -= actual_damage

	# Play enemy hit sound
	if has_node("/root/SoundManager"):
		var hit_sound = "enemy_hit"
		if enemy_type_data and enemy_type_data.hit_sound != "":
			hit_sound = enemy_type_data.hit_sound
		SoundManager.play_random_pitch(hit_sound, -12.0, 0.2)

	# Visual damage feedback
	update_damage_visuals()

	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)
	tween.tween_property(self, "modulate", Color(1, 0.5, 0.5, 1), 0.1)

	if health <= 0:
		destroy()

func update_damage_visuals():
	# Change visual appearance based on damage taken (for fortress ships)
	if enemy_type_data and enemy_type_data.enemy_name == "Fortress Ship" and max_health > 0:
		var health_percentage = float(health) / float(max_health)

		if health_percentage > 0.75:
			$Sprite.color = Color(0.3, 0.3, 0.3, 1)  # Dark gray
		elif health_percentage > 0.5:
			$Sprite.color = Color(0.6, 0.6, 0.2, 1)  # Yellow tint
		elif health_percentage > 0.25:
			$Sprite.color = Color(0.8, 0.4, 0.1, 1)  # Orange
		else:
			$Sprite.color = Color(0.8, 0.2, 0.2, 1)  # Red danger

func destroy():
	# Play enemy destruction sound
	if has_node("/root/SoundManager"):
		SoundManager.play_random_pitch("enemy_destroy", -8.0, 0.15)
	
	enemy_destroyed.emit(points, position)
	call_deferred("queue_free")

func _on_area_entered(area):
	if area.is_in_group("player_bullets"):
		take_damage(1)

func _on_screen_exited():
	call_deferred("queue_free")

func _on_shoot_timer_timeout():
	shoot()

func shoot():
	# Different shooting patterns based on weapon type
	match weapon_type:
		"single_shot":
			fire_single_shot()
		"rapid_fire":
			fire_single_shot()  # Regular shot for rapid fire bursts
		"multi_directional":
			fire_multi_directional()
		"spread_shot":
			fire_spread_shot()
		_:
			pass  # No weapon

func fire_single_shot():
	var bullet_scene = preload("res://scenes/projectiles/EnemyBullet.tscn") if ResourceLoader.exists("res://scenes/projectiles/EnemyBullet.tscn") else null
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		bullet.position = position + Vector2(0, 20)
		get_parent().get_parent().get_node("Bullets").add_child(bullet)

func fire_spread_shot():
	var bullet_scene = preload("res://scenes/projectiles/EnemyBullet.tscn") if ResourceLoader.exists("res://scenes/projectiles/EnemyBullet.tscn") else null
	if bullet_scene:
		# Fire 3 bullets in spread pattern
		for i in range(3):
			var bullet = bullet_scene.instantiate()
			var angle = -30 + (i * 30)  # -30, 0, 30 degrees
			var direction_vec = Vector2.DOWN.rotated(deg_to_rad(angle))
			bullet.position = position + Vector2(0, 20)
			bullet.direction = direction_vec
			get_parent().get_parent().get_node("Bullets").add_child(bullet)

func fire_multi_directional():
	var bullet_scene = preload("res://scenes/projectiles/EnemyBullet.tscn") if ResourceLoader.exists("res://scenes/projectiles/EnemyBullet.tscn") else null
	if bullet_scene:
		# Fire 8 bullets in all directions (for fortress ship)
		for i in range(8):
			var bullet = bullet_scene.instantiate()
			var angle = i * 45  # 8 directions: 0, 45, 90, 135, 180, 225, 270, 315
			var direction_vec = Vector2.DOWN.rotated(deg_to_rad(angle))
			bullet.position = position
			bullet.direction = direction_vec
			get_parent().get_parent().get_node("Bullets").add_child(bullet)

func fire_rapid_burst():
	# Fire 5 shots quickly for heavy gunner
	for i in range(5):
		var timer = Timer.new()
		timer.wait_time = i * 0.1  # 0.1 second intervals
		timer.one_shot = true
		timer.timeout.connect(func(): fire_single_shot())
		timer.timeout.connect(func(): timer.queue_free())
		add_child(timer)
		timer.start()

func spawn_drone():
	# Support carrier spawns scout drones
	if not enemy_type_data or not enemy_type_data.spawns_enemies:
		return

	var enemy_scene = preload("res://scenes/enemies/Enemy.tscn") if ResourceLoader.exists("res://scenes/enemies/Enemy.tscn") else null
	if enemy_scene:
		var drone = enemy_scene.instantiate()
		# Load scout fighter data
		var scout_data = preload("res://resources/enemies/scout_fighter.tres") if ResourceLoader.exists("res://resources/enemies/scout_fighter.tres") else null
		if scout_data:
			drone.enemy_type_data = scout_data
			drone.current_wave = current_wave

		# Spawn to the side of the carrier
		var spawn_offset = Vector2(randf_range(-50, 50), 30)
		drone.position = position + spawn_offset
		get_parent().add_child(drone)