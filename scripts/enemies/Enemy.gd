extends Area2D

signal enemy_destroyed(position)

@export var enemy_type_data: Resource
@export var health = 3
@export var speed = 150
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
var is_dying: bool = false  # Prevent multiple death triggers

# Off-screen cleanup variables
var off_screen_timer: float = 0.0
var is_off_screen: bool = false
var max_off_screen_time: float = 3.0  # 3 seconds max off-screen
var max_distance_from_viewport: float = 500.0  # Max pixels from viewport edge

# Visual animation variables
var current_velocity = Vector2.ZERO
var banking_angle = 0.0
var engine_glow_intensity = 1.0
var target_engine_intensity = 1.0
var time_since_spawn = 0.0
var visual_layers = []  # For multi-layer rendering

func _ready():
	add_to_group("enemies")
	initial_x = position.x

	# Debug tracking
	if has_node("/root/EnemyManager"):
		var enemy_manager = get_node("/root/EnemyManager")
		if "total_enemies_spawned" in enemy_manager:
			print("[Enemy] Created - Total enemies: ", get_tree().get_nodes_in_group("enemies").size())

	# Initialize from enemy type data if provided
	if enemy_type_data:
		setup_from_type_data()
	else:
		# Ensure enemy has basic working values even without type data
		max_health = health
		weapon_type = "none"
		damage_reduction = 0.0

	# More relaxed default firing
	$ShootTimer.wait_time = randf_range(1.8, 2.5)  # Slower firing rate

	# Initialize visual components
	setup_visual_layers()
	setup_engine_effects()

func setup_from_type_data():
	if not enemy_type_data:
		return

	# Set properties from data
	health = enemy_type_data.get_scaled_health(current_wave)
	max_health = health
	speed = enemy_type_data.get_scaled_speed(current_wave)
	movement_pattern = enemy_type_data.movement_pattern
	weapon_type = enemy_type_data.weapon_type
	damage_reduction = enemy_type_data.damage_reduction

	# Update visuals with wave-based scaling
	if has_node("Sprite"):
		# Apply base color with wave-based tinting
		var base_color = enemy_type_data.sprite_color
		var wave_tinted_color = get_wave_tinted_color(base_color, current_wave)
		$Sprite.color = wave_tinted_color

		if enemy_type_data.sprite_polygon.size() > 0:
			# Don't override the enhanced visuals we set up
			pass

		# Apply slight size scaling based on wave (max +25% at wave 100)
		var size_multiplier = 1.0 + min(current_wave / 100.0, 1.0) * 0.25
		$Sprite.scale = Vector2.ONE * enemy_type_data.sprite_scale * size_multiplier

	# Update collision (deferred to avoid physics query conflicts)
	if has_node("CollisionShape2D") and $CollisionShape2D.shape is CircleShape2D:
		call_deferred("update_collision_radius", enemy_type_data.collision_radius)

	# Update shooting with more aggressive rates
	if weapon_type != "none":
		$ShootTimer.wait_time = max(0.5, enemy_type_data.fire_rate * 0.5)  # Twice as fast firing

func update_collision_radius(radius: float):
	# Use set_deferred to avoid physics state conflicts
	($CollisionShape2D.shape as CircleShape2D).set_deferred("radius", radius)

func _process(delta):
	time_alive += delta
	spawn_timer += delta
	time_since_spawn += delta

	# Check for off-screen cleanup
	check_off_screen_cleanup(delta)

	# Store previous position for velocity calculation
	var prev_position = position

	# Handle spawning for support carriers
	if enemy_type_data and enemy_type_data.spawns_enemies and spawn_timer >= 2.0:
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

	# Calculate current velocity for animations
	current_velocity = (position - prev_position) / delta

	# Update visual animations
	update_visual_animations(delta)

func take_damage(damage):
	# Prevent processing damage if already dying
	if is_dying:
		return

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

	# Visual damage feedback - flash white then return to normal
	update_damage_visuals()

	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(2.0, 2.0, 2.0, 1), 0.05)  # Bright white flash
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.15)  # Return to normal

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
	# Prevent multiple destroy calls
	if is_dying:
		return
	is_dying = true

	# Play enemy destruction sound
	if has_node("/root/SoundManager"):
		SoundManager.play_random_pitch("enemy_destroy", -8.0, 0.15)

	enemy_destroyed.emit(position)

	# Debug tracking
	print("[Enemy] Destroyed - Remaining enemies: ", get_tree().get_nodes_in_group("enemies").size() - 1)

	call_deferred("queue_free")

func _on_area_entered(area):
	if area.is_in_group("player_bullets"):
		# Damage is handled by the bullet itself to avoid double-hits
		pass

func _on_screen_exited():
	# Mark as off-screen and start timer
	is_off_screen = true
	off_screen_timer = 0.0
	print("[Enemy] Exited screen at position: ", position)

func _on_shoot_timer_timeout():
	# Only shoot if enemy is on screen
	if is_on_screen():
		shoot()

func is_on_screen() -> bool:
	# Check if enemy is within visible screen bounds
	var viewport_size = get_viewport_rect().size
	var enemy_pos = global_position

	# Only allow margin on top (for enemies entering) and bottom
	# No margin on left/right to prevent offscreen firing
	var top_margin = 50  # Allow enemies just entering from top
	var bottom_margin = 50  # Some leeway at bottom
	var side_margin = 0  # No margin on sides - must be fully on screen

	return enemy_pos.x > side_margin and enemy_pos.x < viewport_size.x - side_margin and \
	       enemy_pos.y > -top_margin and enemy_pos.y < viewport_size.y + bottom_margin

func is_visible_for_damage() -> bool:
	# Stricter check for whether enemy should take damage from player bullets
	# No margins - enemy must be fully within visible screen
	var viewport_size = get_viewport_rect().size
	var enemy_pos = global_position

	return enemy_pos.x > 0 and enemy_pos.x < viewport_size.x and \
	       enemy_pos.y > 0 and enemy_pos.y < viewport_size.y

func shoot():
	# Double-check we're on screen before firing
	if not is_on_screen():
		return

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

		# Check if this is an elite enemy
		var is_elite = false
		if enemy_type_data and enemy_type_data.enemy_name:
			is_elite = enemy_type_data.enemy_name.begins_with("Elite") or enemy_type_data.enemy_name == "Fortress Ship"

		var player = get_tree().get_first_node_in_group("player")
		if player:
			if is_elite and randf() < 0.25:  # Elite enemies fire tracking bullets 25% of the time
				bullet.set_tracking(player)
			elif randf() < 0.35:  # Regular enemies aim 35% of the time
				bullet.set_aimed_at_player(player.position)

		get_parent().get_parent().get_node("Bullets").add_child(bullet)

func fire_spread_shot():
	var bullet_scene = preload("res://scenes/projectiles/EnemyBullet.tscn") if ResourceLoader.exists("res://scenes/projectiles/EnemyBullet.tscn") else null
	if bullet_scene:
		# Check if this is an elite enemy
		var is_elite = false
		if enemy_type_data and enemy_type_data.enemy_name:
			is_elite = enemy_type_data.enemy_name.begins_with("Elite")

		var player = get_tree().get_first_node_in_group("player")
		# Fire 3 bullets in spread pattern (5 for elites)
		var bullet_count = 5 if is_elite else 3
		for i in range(bullet_count):
			var bullet = bullet_scene.instantiate()
			bullet.position = position + Vector2(0, 20)

			if player:
				if is_elite and i == bullet_count/2 and randf() < 0.7:  # Center bullet tracks for elites
					bullet.set_tracking(player)
				elif randf() < 0.5:  # 50% chance to aim spread at player
					var to_player = (player.position - position).normalized()
					var angle = -20 + (i * (40.0/bullet_count))  # Adjust spread based on count
					bullet.direction = to_player.rotated(deg_to_rad(angle))
					bullet.is_aimed = true
				else:
					var angle = -30 + (i * (60.0/bullet_count))  # Normal spread
					bullet.direction = Vector2.DOWN.rotated(deg_to_rad(angle))
			else:
				var angle = -30 + (i * (60.0/bullet_count))  # Normal spread
				bullet.direction = Vector2.DOWN.rotated(deg_to_rad(angle))

			get_parent().get_parent().get_node("Bullets").add_child(bullet)

func fire_multi_directional():
	var bullet_scene = preload("res://scenes/projectiles/EnemyBullet.tscn") if ResourceLoader.exists("res://scenes/projectiles/EnemyBullet.tscn") else null
	if bullet_scene:
		var player = get_tree().get_first_node_in_group("player")
		# Fire 8 bullets in all directions (for fortress ship)
		for i in range(8):
			var bullet = bullet_scene.instantiate()
			bullet.position = position

			# Mix of aimed and radial bullets
			if i % 2 == 0 and player:  # Every other bullet aims at player
				var to_player = (player.position - position).normalized()
				var spread_angle = (i/2 - 2) * 15  # Slight spread
				bullet.direction = to_player.rotated(deg_to_rad(spread_angle))
				bullet.is_aimed = true
			else:
				var angle = i * 45  # Standard radial pattern
				bullet.direction = Vector2.DOWN.rotated(deg_to_rad(angle))

			get_parent().get_parent().get_node("Bullets").add_child(bullet)

func fire_rapid_burst():
	# Fire 5 shots quickly for heavy gunner
	for i in range(5):
		var timer = Timer.new()
		timer.wait_time = i * 0.1  # 0.1 second intervals
		timer.one_shot = true
		timer.timeout.connect(func():
			if is_on_screen():  # Check each burst shot
				fire_single_shot()
		)
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

func setup_visual_layers():
	# Initialize multi-layer visual system based on enemy type
	if not enemy_type_data:
		return

	# Create additional visual nodes for complex enemies
	match enemy_type_data.enemy_name:
		"Scout Fighter":
			setup_scout_fighter_visuals()
		"Elite Scout Fighter":
			setup_elite_scout_fighter_visuals()
		"Interceptor":
			setup_interceptor_visuals()
		"Guard Drone":
			setup_guard_drone_visuals()
		"Elite Guard Drone":
			setup_elite_guard_drone_visuals()
		"Heavy Gunner":
			setup_heavy_gunner_visuals()
		"Elite Heavy Gunner":
			setup_elite_heavy_gunner_visuals()
		"Support Carrier":
			setup_support_carrier_visuals()
		"Fortress Ship":
			setup_fortress_ship_visuals()

func setup_engine_effects():
	# Add engine glow and particle effects based on enemy type
	if not has_node("EngineGlow"):
		var engine_glow = Polygon2D.new()
		engine_glow.name = "EngineGlow"
		engine_glow.z_index = -1
		add_child(engine_glow)

	if not has_node("EngineParticles"):
		var particles = CPUParticles2D.new()
		particles.name = "EngineParticles"
		particles.emitting = false
		particles.amount = 20
		particles.lifetime = 0.5
		particles.spread = 25.0
		particles.initial_velocity_min = 50.0
		particles.initial_velocity_max = 150.0
		particles.scale_amount_min = 0.5
		particles.scale_amount_max = 1.5
		particles.color = Color(1, 0.5, 0, 1)
		add_child(particles)

func update_visual_animations(delta):
	# Update banking animation based on horizontal movement
	if movement_pattern == "zigzag":
		var banking_intensity = current_velocity.x / speed
		banking_angle = lerp(banking_angle, banking_intensity * 15.0, 5.0 * delta)
		rotation = deg_to_rad(banking_angle)
	elif movement_pattern == "dive" and current_velocity.length() > 0:
		# Point in direction of movement for dive bombers
		rotation = current_velocity.angle() + PI/2

	# Update engine effects
	if current_velocity.length() > 0:
		target_engine_intensity = 1.5
		if has_node("EngineParticles"):
			$EngineParticles.emitting = true
			$EngineParticles.direction = -current_velocity.normalized()
	else:
		target_engine_intensity = 0.8
		if has_node("EngineParticles"):
			$EngineParticles.emitting = false

	engine_glow_intensity = lerp(engine_glow_intensity, target_engine_intensity, 10.0 * delta)

	# Update engine glow visual
	if has_node("EngineGlow"):
		$EngineGlow.modulate = Color(1, 0.3, 0, 1) * engine_glow_intensity

	# Update any custom visual layers
	update_enemy_specific_visuals(delta)

func update_enemy_specific_visuals(delta):
	# Override in specific enemy types or handle here based on enemy_type_data
	if not enemy_type_data:
		return

	match enemy_type_data.enemy_name:
		"Heavy Gunner", "Elite Heavy Gunner":
			# Recoil animation when shooting
			if is_stopped and has_node("Sprite"):
				$Sprite.position.y = sin(time_alive * 20) * 2
		"Guard Drone", "Elite Guard Drone":
			# Rotating shield effect
			if has_node("ShieldLayer"):
				$ShieldLayer.rotation += delta * 1.0
		"Support Carrier":
			# Blinking lights animation
			if has_node("RunwayLights"):
				$RunwayLights.modulate.a = (sin(time_alive * 5) + 1.0) * 0.5

# Visual setup functions for each enemy type
func setup_scout_fighter_visuals():
	# Classic fighter jet design
	$Sprite.polygon = PackedVector2Array([
		# Nose
		Vector2(0, -22),
		# Right side
		Vector2(2, -18), Vector2(3, -14), Vector2(4, -10),
		# Right wing
		Vector2(12, -2), Vector2(14, 0), Vector2(12, 2),
		# Right engine
		Vector2(6, 8), Vector2(5, 14), Vector2(4, 18),
		# Tail
		Vector2(2, 20), Vector2(0, 20),
		# Left side
		Vector2(-2, 20), Vector2(-4, 18), Vector2(-5, 14), Vector2(-6, 8),
		# Left wing
		Vector2(-12, 2), Vector2(-14, 0), Vector2(-12, -2),
		# Left fuselage
		Vector2(-4, -10), Vector2(-3, -14), Vector2(-2, -18)
	])
	$Sprite.color = Color(0.5, 0.55, 0.6, 1)  # Military gray

	# Add cockpit canopy
	var cockpit = Polygon2D.new()
	cockpit.name = "Cockpit"
	cockpit.polygon = PackedVector2Array([
		Vector2(0, -12), Vector2(-2, -8), Vector2(-2, -4),
		Vector2(0, -2), Vector2(2, -4), Vector2(2, -8)
	])
	cockpit.color = Color(0.2, 0.3, 0.5, 0.8)  # Blue tinted glass
	add_child(cockpit)

	# Add wing details
	var wing_stripes = Polygon2D.new()
	wing_stripes.name = "WingStripes"
	wing_stripes.polygon = PackedVector2Array([
		# Right wing stripe
		Vector2(8, -1), Vector2(12, -1), Vector2(12, 1), Vector2(8, 1),
		# Left wing stripe
		Vector2(-8, -1), Vector2(-12, -1), Vector2(-12, 1), Vector2(-8, 1)
	])
	wing_stripes.color = Color(0.8, 0.2, 0.2, 1)  # Red stripes
	add_child(wing_stripes)

	# Configure engine glow
	if has_node("EngineGlow"):
		$EngineGlow.polygon = PackedVector2Array([
			Vector2(-4, 18), Vector2(-2, 22), Vector2(0, 23),
			Vector2(2, 22), Vector2(4, 18)
		])

func setup_elite_scout_fighter_visuals():
	# Advanced fighter with forward-swept wings
	$Sprite.polygon = PackedVector2Array([
		# Sharp nose
		Vector2(0, -25),
		# Right side
		Vector2(2, -20), Vector2(4, -15), Vector2(5, -10),
		# Right forward-swept wing
		Vector2(8, -5), Vector2(14, -8), Vector2(16, -6), Vector2(14, -2),
		# Right side body
		Vector2(8, 5), Vector2(7, 10),
		# Right engines
		Vector2(6, 15), Vector2(5, 18), Vector2(3, 20),
		# Tail
		Vector2(0, 22),
		# Left engines
		Vector2(-3, 20), Vector2(-5, 18), Vector2(-6, 15),
		# Left side body
		Vector2(-7, 10), Vector2(-8, 5),
		# Left forward-swept wing
		Vector2(-14, -2), Vector2(-16, -6), Vector2(-14, -8), Vector2(-8, -5),
		# Left side
		Vector2(-5, -10), Vector2(-4, -15), Vector2(-2, -20)
	])
	$Sprite.color = Color(0.6, 0.5, 0.7, 1)  # Purple-gray elite color
	$Sprite.scale = Vector2(1.15, 1.15)

	# Enhanced cockpit
	var cockpit = Polygon2D.new()
	cockpit.name = "Cockpit"
	cockpit.polygon = PackedVector2Array([
		Vector2(0, -14), Vector2(-3, -10), Vector2(-3, -4),
		Vector2(0, -2), Vector2(3, -4), Vector2(3, -10)
	])
	cockpit.color = Color(0.1, 0.3, 0.6, 0.9)  # Elite blue canopy
	add_child(cockpit)

	# Elite markings
	var markings = Polygon2D.new()
	markings.name = "EliteMarkings"
	markings.polygon = PackedVector2Array([
		# Chevron on nose
		Vector2(-2, -18), Vector2(0, -20), Vector2(2, -18), Vector2(0, -16),
		# Wing stripes
		Vector2(10, -6), Vector2(14, -6), Vector2(14, -4), Vector2(10, -4),
		Vector2(-10, -6), Vector2(-14, -6), Vector2(-14, -4), Vector2(-10, -4)
	])
	markings.color = Color(1, 0.8, 0, 1)  # Gold elite markings
	add_child(markings)

	# Triple engines
	if has_node("EngineGlow"):
		$EngineGlow.polygon = PackedVector2Array([
			Vector2(-6, 20), Vector2(-4, 24), Vector2(-2, 25),
			Vector2(0, 26), Vector2(2, 25), Vector2(4, 24), Vector2(6, 20)
		])

func setup_interceptor_visuals():
	# Sleek dart/arrow design for speed
	$Sprite.polygon = PackedVector2Array([
		# Sharp nose
		Vector2(0, -26),
		# Right side streamlined
		Vector2(1, -22), Vector2(2, -16), Vector2(3, -10),
		# Right thin wing
		Vector2(8, 0), Vector2(10, 2), Vector2(8, 4),
		# Right engine
		Vector2(4, 10), Vector2(3, 16),
		# Tail
		Vector2(2, 20), Vector2(0, 22),
		# Left side
		Vector2(-2, 20), Vector2(-3, 16), Vector2(-4, 10),
		# Left thin wing
		Vector2(-8, 4), Vector2(-10, 2), Vector2(-8, 0),
		# Left streamlined body
		Vector2(-3, -10), Vector2(-2, -16), Vector2(-1, -22)
	])
	$Sprite.color = Color(0.3, 0.4, 0.7, 1)  # Dark blue

	# Add speed stripes
	var speed_lines = Polygon2D.new()
	speed_lines.name = "SpeedLines"
	speed_lines.polygon = PackedVector2Array([
		Vector2(0, -20), Vector2(-1, -10), Vector2(0, 0), Vector2(1, -10)
	])
	speed_lines.color = Color(0.8, 0.8, 1.0, 1)  # Light blue accent
	add_child(speed_lines)

	# Large afterburner
	if has_node("EngineGlow"):
		$EngineGlow.polygon = PackedVector2Array([
			Vector2(-3, 20), Vector2(-2, 24), Vector2(0, 28),
			Vector2(2, 24), Vector2(3, 20)
		])
		$EngineGlow.scale = Vector2(1.0, 2.0)  # Long exhaust trail

func setup_guard_drone_visuals():
	# Compact defensive fighter craft
	$Sprite.polygon = PackedVector2Array([
		# Front
		Vector2(0, -18), Vector2(4, -16), Vector2(6, -14),
		# Right side armor
		Vector2(8, -10), Vector2(10, -6),
		# Right stubby wing
		Vector2(12, -2), Vector2(12, 2),
		# Right rear
		Vector2(10, 6), Vector2(8, 10), Vector2(6, 14),
		# Rear thrusters
		Vector2(4, 16), Vector2(2, 18), Vector2(0, 18),
		# Left side
		Vector2(-2, 18), Vector2(-4, 16), Vector2(-6, 14),
		Vector2(-8, 10), Vector2(-10, 6),
		# Left stubby wing
		Vector2(-12, 2), Vector2(-12, -2),
		# Left front
		Vector2(-10, -6), Vector2(-8, -10), Vector2(-6, -14), Vector2(-4, -16)
	])
	$Sprite.color = Color(0.4, 0.5, 0.4, 1)  # Military green

	# Add central cockpit dome
	var cockpit = Polygon2D.new()
	cockpit.name = "CockpitDome"
	cockpit.polygon = PackedVector2Array([
		Vector2(0, -8), Vector2(-3, -6), Vector2(-4, -2),
		Vector2(-3, 2), Vector2(0, 4),
		Vector2(3, 2), Vector2(4, -2), Vector2(3, -6)
	])
	cockpit.color = Color(0.2, 0.3, 0.4, 0.9)
	add_child(cockpit)

	# Add armor plating details
	var armor = Polygon2D.new()
	armor.name = "ArmorPlates"
	armor.polygon = PackedVector2Array([
		# Front armor
		Vector2(-4, -14), Vector2(4, -14), Vector2(4, -10), Vector2(-4, -10),
		# Side armor
		Vector2(-8, -4), Vector2(-6, -4), Vector2(-6, 4), Vector2(-8, 4),
		Vector2(6, -4), Vector2(8, -4), Vector2(8, 4), Vector2(6, 4)
	])
	armor.color = Color(0.3, 0.35, 0.3, 1)
	add_child(armor)

	# Four-point thruster configuration
	if has_node("EngineGlow"):
		$EngineGlow.polygon = PackedVector2Array([
			Vector2(-4, 16), Vector2(-2, 16), Vector2(-2, 20), Vector2(-4, 20),
			Vector2(2, 16), Vector2(4, 16), Vector2(4, 20), Vector2(2, 20)
		])

func setup_elite_guard_drone_visuals():
	# Heavy defense platform with extended shields
	$Sprite.polygon = PackedVector2Array([
		# Front armor
		Vector2(0, -22), Vector2(5, -20), Vector2(8, -18),
		# Right heavy armor
		Vector2(10, -14), Vector2(12, -10), Vector2(14, -6),
		# Right extended wing panel
		Vector2(16, -2), Vector2(18, 0), Vector2(18, 4), Vector2(16, 6),
		# Right rear section
		Vector2(14, 10), Vector2(12, 14), Vector2(10, 16),
		# Rear thruster array
		Vector2(6, 20), Vector2(3, 22), Vector2(0, 22),
		# Left rear
		Vector2(-3, 22), Vector2(-6, 20), Vector2(-10, 16),
		Vector2(-12, 14), Vector2(-14, 10),
		# Left extended wing panel
		Vector2(-16, 6), Vector2(-18, 4), Vector2(-18, 0), Vector2(-16, -2),
		# Left heavy armor
		Vector2(-14, -6), Vector2(-12, -10), Vector2(-10, -14),
		# Left front
		Vector2(-8, -18), Vector2(-5, -20)
	])
	$Sprite.color = Color(0.35, 0.45, 0.35, 1)  # Elite green
	$Sprite.scale = Vector2(1.25, 1.25)

	# Multi-layer shield system
	var shield_outer = Polygon2D.new()
	shield_outer.name = "ShieldOuter"
	shield_outer.polygon = PackedVector2Array([
		Vector2(0, -18), Vector2(-14, -9), Vector2(-14, 9),
		Vector2(0, 18), Vector2(14, 9), Vector2(14, -9)
	])
	shield_outer.color = Color(0.2, 0.6, 0.4, 0.3)
	shield_outer.z_index = 2
	add_child(shield_outer)

	var shield_inner = Polygon2D.new()
	shield_inner.name = "ShieldInner"
	shield_inner.polygon = PackedVector2Array([
		Vector2(0, -12), Vector2(-8, -6), Vector2(-8, 6),
		Vector2(0, 12), Vector2(8, 6), Vector2(8, -6)
	])
	shield_inner.color = Color(0.3, 0.7, 0.5, 0.4)
	shield_inner.z_index = 1
	add_child(shield_inner)

	# Elite cockpit dome
	var cockpit = Polygon2D.new()
	cockpit.name = "EliteDome"
	cockpit.polygon = PackedVector2Array([
		Vector2(0, -10), Vector2(-4, -7), Vector2(-5, -3),
		Vector2(-4, 1), Vector2(0, 4),
		Vector2(4, 1), Vector2(5, -3), Vector2(4, -7)
	])
	cockpit.color = Color(0.1, 0.4, 0.3, 0.9)
	add_child(cockpit)

	# Six-point thruster array
	if has_node("EngineGlow"):
		$EngineGlow.polygon = PackedVector2Array([
			Vector2(-6, 18), Vector2(-4, 18), Vector2(-4, 24), Vector2(-6, 24),
			Vector2(-2, 18), Vector2(0, 18), Vector2(0, 24), Vector2(-2, 24),
			Vector2(2, 18), Vector2(4, 18), Vector2(4, 24), Vector2(2, 24),
			Vector2(4, 18), Vector2(6, 18), Vector2(6, 24), Vector2(4, 24)
		])

func setup_heavy_gunner_visuals():
	# Assault frigate - bulky gunship
	$Sprite.polygon = PackedVector2Array([
		# Front hull
		Vector2(0, -24), Vector2(6, -22), Vector2(10, -20),
		# Right side hull
		Vector2(12, -16), Vector2(14, -12),
		# Right weapon wing
		Vector2(18, -8), Vector2(20, -4), Vector2(20, 4), Vector2(18, 8),
		# Right rear
		Vector2(14, 12), Vector2(12, 16),
		# Engine block
		Vector2(8, 20), Vector2(4, 22), Vector2(0, 22),
		# Left side
		Vector2(-4, 22), Vector2(-8, 20), Vector2(-12, 16), Vector2(-14, 12),
		# Left weapon wing
		Vector2(-18, 8), Vector2(-20, 4), Vector2(-20, -4), Vector2(-18, -8),
		# Left front
		Vector2(-14, -12), Vector2(-12, -16), Vector2(-10, -20), Vector2(-6, -22)
	])
	$Sprite.color = Color(0.35, 0.35, 0.4, 1)  # Dark gray-blue

	# Add forward gun turrets
	var turret_left = Polygon2D.new()
	turret_left.name = "TurretLeft"
	turret_left.polygon = PackedVector2Array([
		Vector2(-8, -18), Vector2(-6, -24), Vector2(-4, -24), Vector2(-2, -18)
	])
	turret_left.color = Color(0.25, 0.25, 0.3, 1)
	add_child(turret_left)

	var turret_right = Polygon2D.new()
	turret_right.name = "TurretRight"
	turret_right.polygon = PackedVector2Array([
		Vector2(2, -18), Vector2(4, -24), Vector2(6, -24), Vector2(8, -18)
	])
	turret_right.color = Color(0.25, 0.25, 0.3, 1)
	add_child(turret_right)

	# Wing mounted weapons
	var wing_guns = Polygon2D.new()
	wing_guns.name = "WingGuns"
	wing_guns.polygon = PackedVector2Array([
		# Right wing gun
		Vector2(16, -4), Vector2(18, -4), Vector2(18, 4), Vector2(16, 4),
		# Left wing gun
		Vector2(-16, -4), Vector2(-18, -4), Vector2(-18, 4), Vector2(-16, 4)
	])
	wing_guns.color = Color(0.2, 0.2, 0.25, 1)
	add_child(wing_guns)

	# Multiple rear engines
	if has_node("EngineGlow"):
		$EngineGlow.polygon = PackedVector2Array([
			Vector2(-8, 20), Vector2(-4, 20), Vector2(-4, 24), Vector2(-8, 24),
			Vector2(4, 20), Vector2(8, 20), Vector2(8, 24), Vector2(4, 24)
		])

func setup_elite_heavy_gunner_visuals():
	# Battle cruiser - larger assault vessel
	$Sprite.polygon = PackedVector2Array([
		# Reinforced bow
		Vector2(0, -28), Vector2(7, -26), Vector2(12, -24),
		# Right armored hull
		Vector2(15, -20), Vector2(18, -16), Vector2(20, -12),
		# Right heavy weapon wing
		Vector2(24, -8), Vector2(26, -4), Vector2(26, 4), Vector2(24, 8),
		# Right rear section
		Vector2(20, 12), Vector2(18, 16), Vector2(15, 20),
		# Quad engine cluster
		Vector2(10, 24), Vector2(5, 26), Vector2(0, 26),
		# Left rear
		Vector2(-5, 26), Vector2(-10, 24), Vector2(-15, 20),
		Vector2(-18, 16), Vector2(-20, 12),
		# Left heavy weapon wing
		Vector2(-24, 8), Vector2(-26, 4), Vector2(-26, -4), Vector2(-24, -8),
		# Left armored hull
		Vector2(-20, -12), Vector2(-18, -16), Vector2(-15, -20),
		# Left bow
		Vector2(-12, -24), Vector2(-7, -26)
	])
	$Sprite.color = Color(0.4, 0.2, 0.25, 1)  # Dark red elite
	$Sprite.scale = Vector2(1.3, 1.3)

	# Multiple turret positions
	var front_turrets = Polygon2D.new()
	front_turrets.name = "FrontTurrets"
	front_turrets.polygon = PackedVector2Array([
		# Center turret
		Vector2(-2, -24), Vector2(2, -24), Vector2(2, -28), Vector2(-2, -28),
		# Left turret
		Vector2(-10, -20), Vector2(-6, -20), Vector2(-6, -26), Vector2(-10, -26),
		# Right turret
		Vector2(6, -20), Vector2(10, -20), Vector2(10, -26), Vector2(6, -26)
	])
	front_turrets.color = Color(0.25, 0.15, 0.15, 1)
	add_child(front_turrets)

	# Heavy wing cannons
	var wing_cannons = Polygon2D.new()
	wing_cannons.name = "WingCannons"
	wing_cannons.polygon = PackedVector2Array([
		# Right wing double cannon
		Vector2(20, -6), Vector2(24, -6), Vector2(24, -2), Vector2(20, -2),
		Vector2(20, 2), Vector2(24, 2), Vector2(24, 6), Vector2(20, 6),
		# Left wing double cannon
		Vector2(-24, -6), Vector2(-20, -6), Vector2(-20, -2), Vector2(-24, -2),
		Vector2(-24, 2), Vector2(-20, 2), Vector2(-20, 6), Vector2(-24, 6)
	])
	wing_cannons.color = Color(0.2, 0.1, 0.12, 1)
	add_child(wing_cannons)

	# Additional armor plating
	var armor = Polygon2D.new()
	armor.name = "HeavyArmor"
	armor.polygon = PackedVector2Array([
		# Front armor
		Vector2(-10, -22), Vector2(10, -22), Vector2(12, -18), Vector2(-12, -18),
		# Side armor panels
		Vector2(-18, -10), Vector2(-14, -10), Vector2(-14, 10), Vector2(-18, 10),
		Vector2(14, -10), Vector2(18, -10), Vector2(18, 10), Vector2(14, 10)
	])
	armor.color = Color(0.3, 0.15, 0.18, 1)
	armor.z_index = -1
	add_child(armor)

	# Quad engine cluster
	if has_node("EngineGlow"):
		$EngineGlow.polygon = PackedVector2Array([
			Vector2(-10, 24), Vector2(-6, 24), Vector2(-6, 30), Vector2(-10, 30),
			Vector2(-4, 24), Vector2(0, 24), Vector2(0, 30), Vector2(-4, 30),
			Vector2(0, 24), Vector2(4, 24), Vector2(4, 30), Vector2(0, 30),
			Vector2(6, 24), Vector2(10, 24), Vector2(10, 30), Vector2(6, 30)
		])

func setup_support_carrier_visuals():
	# Carrier ship with flight deck
	$Sprite.polygon = PackedVector2Array([
		# Front hull
		Vector2(0, -35), Vector2(8, -34), Vector2(15, -32),
		# Right flight deck
		Vector2(22, -28), Vector2(26, -20), Vector2(28, -10),
		Vector2(28, 10), Vector2(26, 20), Vector2(22, 28),
		# Right rear
		Vector2(15, 32), Vector2(8, 34),
		# Engine section
		Vector2(4, 35), Vector2(0, 35),
		# Left rear
		Vector2(-4, 35), Vector2(-8, 34), Vector2(-15, 32),
		# Left flight deck
		Vector2(-22, 28), Vector2(-26, 20), Vector2(-28, 10),
		Vector2(-28, -10), Vector2(-26, -20), Vector2(-22, -28),
		# Left front
		Vector2(-15, -32), Vector2(-8, -34)
	])
	$Sprite.color = Color(0.4, 0.4, 0.45, 1)  # Naval gray

	# Add bridge tower
	var bridge = Polygon2D.new()
	bridge.name = "BridgeTower"
	bridge.polygon = PackedVector2Array([
		Vector2(-4, -20), Vector2(4, -20), Vector2(6, -16),
		Vector2(6, -8), Vector2(4, -4), Vector2(-4, -4),
		Vector2(-6, -8), Vector2(-6, -16)
	])
	bridge.color = Color(0.3, 0.3, 0.35, 1)
	bridge.z_index = 1
	add_child(bridge)

	# Add hangar bay openings
	var hangar = Polygon2D.new()
	hangar.name = "HangarBays"
	hangar.polygon = PackedVector2Array([
		# Center hangar
		Vector2(-12, -5), Vector2(12, -5), Vector2(12, 5), Vector2(-12, 5),
		# Rear hangar
		Vector2(-10, 10), Vector2(10, 10), Vector2(10, 20), Vector2(-10, 20)
	])
	hangar.color = Color(0.05, 0.05, 0.05, 1)  # Black openings
	add_child(hangar)

	# Add deck markings
	var deck_markings = Polygon2D.new()
	deck_markings.name = "DeckMarkings"
	deck_markings.polygon = PackedVector2Array([
		# Landing strip lines
		Vector2(-2, -30), Vector2(2, -30), Vector2(2, 30), Vector2(-2, 30),
		# Cross marks
		Vector2(-20, -2), Vector2(-10, -2), Vector2(-10, 2), Vector2(-20, 2),
		Vector2(10, -2), Vector2(20, -2), Vector2(20, 2), Vector2(10, 2)
	])
	deck_markings.color = Color(1, 1, 0.8, 0.6)  # Yellow markings
	add_child(deck_markings)

	# Dual engine pods
	if has_node("EngineGlow"):
		$EngineGlow.polygon = PackedVector2Array([
			Vector2(-10, 32), Vector2(-6, 32), Vector2(-6, 38), Vector2(-10, 38),
			Vector2(6, 32), Vector2(10, 32), Vector2(10, 38), Vector2(6, 38)
		])

func setup_fortress_ship_visuals():
	# Massive battleship design
	$Sprite.polygon = PackedVector2Array([
		# Pointed bow
		Vector2(0, -42), Vector2(4, -40), Vector2(8, -38), Vector2(12, -35),
		# Right side hull
		Vector2(18, -30), Vector2(24, -25), Vector2(28, -20),
		Vector2(32, -15), Vector2(34, -10), Vector2(35, -5),
		Vector2(35, 5), Vector2(34, 10), Vector2(32, 15),
		# Right rear
		Vector2(28, 20), Vector2(24, 25), Vector2(18, 30),
		Vector2(12, 35), Vector2(6, 38),
		# Stern
		Vector2(0, 40),
		# Left rear
		Vector2(-6, 38), Vector2(-12, 35), Vector2(-18, 30),
		Vector2(-24, 25), Vector2(-28, 20),
		# Left side hull
		Vector2(-32, 15), Vector2(-34, 10), Vector2(-35, 5),
		Vector2(-35, -5), Vector2(-34, -10), Vector2(-32, -15),
		Vector2(-28, -20), Vector2(-24, -25), Vector2(-18, -30),
		# Left bow
		Vector2(-12, -35), Vector2(-8, -38), Vector2(-4, -40)
	])
	$Sprite.color = Color(0.35, 0.35, 0.38, 1)  # Battleship gray

	# Command bridge superstructure
	var bridge = Polygon2D.new()
	bridge.name = "CommandBridge"
	bridge.polygon = PackedVector2Array([
		# Main tower
		Vector2(-8, -25), Vector2(8, -25), Vector2(10, -20),
		Vector2(10, -10), Vector2(8, -5), Vector2(-8, -5),
		Vector2(-10, -10), Vector2(-10, -20),
		# Upper bridge
		Vector2(-6, -30), Vector2(6, -30), Vector2(6, -25), Vector2(-6, -25)
	])
	bridge.color = Color(0.28, 0.28, 0.32, 1)
	bridge.z_index = 1
	add_child(bridge)

	# Main gun batteries
	var main_guns = Polygon2D.new()
	main_guns.name = "MainGuns"
	main_guns.polygon = PackedVector2Array([
		# Forward guns
		Vector2(-6, -35), Vector2(-4, -38), Vector2(-2, -38), Vector2(0, -35),
		Vector2(0, -35), Vector2(2, -38), Vector2(4, -38), Vector2(6, -35),
		# Mid guns
		Vector2(-10, -15), Vector2(-8, -18), Vector2(-6, -18), Vector2(-4, -15),
		Vector2(4, -15), Vector2(6, -18), Vector2(8, -18), Vector2(10, -15)
	])
	main_guns.color = Color(0.2, 0.2, 0.22, 1)
	add_child(main_guns)

	# Side weapon batteries
	for i in range(3):
		var battery = Polygon2D.new()
		battery.name = "Battery" + str(i)
		var y_pos = -10 + (i * 10)
		# Right side battery
		var right_battery = Polygon2D.new()
		right_battery.polygon = PackedVector2Array([
			Vector2(25, y_pos - 2), Vector2(30, y_pos - 2),
			Vector2(30, y_pos + 2), Vector2(25, y_pos + 2)
		])
		right_battery.color = Color(0.25, 0.25, 0.28, 1)
		add_child(right_battery)
		# Left side battery
		var left_battery = Polygon2D.new()
		left_battery.polygon = PackedVector2Array([
			Vector2(-30, y_pos - 2), Vector2(-25, y_pos - 2),
			Vector2(-25, y_pos + 2), Vector2(-30, y_pos + 2)
		])
		left_battery.color = Color(0.25, 0.25, 0.28, 1)
		add_child(left_battery)

	# Massive engine array
	if has_node("EngineGlow"):
		$EngineGlow.polygon = PackedVector2Array([
			Vector2(-12, 35), Vector2(-8, 35), Vector2(-8, 42), Vector2(-12, 42),
			Vector2(-4, 35), Vector2(0, 35), Vector2(0, 42), Vector2(-4, 42),
			Vector2(4, 35), Vector2(8, 35), Vector2(8, 42), Vector2(4, 42),
			Vector2(8, 35), Vector2(12, 35), Vector2(12, 42), Vector2(8, 42)
		])

func check_off_screen_cleanup(delta):
	"""Implement secondary cleanup mechanism for off-screen enemies"""
	var viewport_size = get_viewport_rect().size
	var enemy_pos = global_position

	# Check if enemy is off-screen
	var is_currently_off_screen = (enemy_pos.x < -50 or enemy_pos.x > viewport_size.x + 50 or
	                               enemy_pos.y < -50 or enemy_pos.y > viewport_size.y + 50)

	# Update off-screen status and timer
	if is_currently_off_screen:
		if not is_off_screen:
			is_off_screen = true
			off_screen_timer = 0.0
			print("[Enemy] Went off-screen at position: ", position)

		off_screen_timer += delta

		# Check for cleanup conditions
		var should_cleanup = false
		var cleanup_reason = ""

		# Condition 1: Too long off-screen
		if off_screen_timer > max_off_screen_time:
			should_cleanup = true
			cleanup_reason = "exceeded max off-screen time"

		# Condition 2: Too far from viewport
		var distance_from_viewport = 0.0
		if enemy_pos.x < 0:
			distance_from_viewport = abs(enemy_pos.x)
		elif enemy_pos.x > viewport_size.x:
			distance_from_viewport = enemy_pos.x - viewport_size.x

		if enemy_pos.y < 0:
			distance_from_viewport = max(distance_from_viewport, abs(enemy_pos.y))
		elif enemy_pos.y > viewport_size.y:
			distance_from_viewport = max(distance_from_viewport, enemy_pos.y - viewport_size.y)

		if distance_from_viewport > max_distance_from_viewport:
			should_cleanup = true
			cleanup_reason = "too far from viewport (" + str(int(distance_from_viewport)) + " pixels)"

		# Perform cleanup if needed
		if should_cleanup and not is_dying:
			print("[Enemy] Force cleanup - ", cleanup_reason, " at position: ", position)
			is_dying = true
			call_deferred("queue_free")
	else:
		# Enemy returned on-screen, reset timer
		if is_off_screen:
			is_off_screen = false
			off_screen_timer = 0.0
			print("[Enemy] Returned on-screen at position: ", position)

func _on_screen_entered():
	"""Called when enemy re-enters the screen"""
	is_off_screen = false
	off_screen_timer = 0.0
	print("[Enemy] Entered screen at position: ", position)

func get_wave_tinted_color(base_color: Color, wave: int) -> Color:
	"""Apply progressive color tinting based on wave number"""
	var tinted_color = base_color

	if wave >= 81:
		# Wave 81-100: White-hot legendary glow
		var glow_intensity = (wave - 80) / 20.0  # 0.0 to 1.0
		tinted_color = tinted_color.lerp(Color(2.0, 2.0, 2.0, 1.0), glow_intensity * 0.6)
		# Add pulsing effect for legendary enemies
		var pulse = (sin(Time.get_ticks_msec() * 0.01) + 1.0) * 0.5
		tinted_color = tinted_color.lerp(Color(2.5, 2.5, 2.5, 1.0), pulse * 0.3)
	elif wave >= 61:
		# Wave 61-80: Pulsing orange/red elite
		var elite_intensity = (wave - 60) / 20.0  # 0.0 to 1.0
		var orange_tint = Color(1.5, 0.8, 0.3, 1.0)
		tinted_color = tinted_color.lerp(orange_tint, elite_intensity * 0.5)
		# Add subtle pulsing
		var pulse = (sin(Time.get_ticks_msec() * 0.008) + 1.0) * 0.5
		tinted_color = tinted_color.lerp(Color(2.0, 1.0, 0.5, 1.0), pulse * 0.2)
	elif wave >= 41:
		# Wave 41-60: Orange/red veteran glow
		var veteran_intensity = (wave - 40) / 20.0  # 0.0 to 1.0
		var red_tint = Color(1.4, 0.7, 0.3, 1.0)
		tinted_color = tinted_color.lerp(red_tint, veteran_intensity * 0.4)
	elif wave >= 21:
		# Wave 21-40: Red battle-hardened tint
		var hardened_intensity = (wave - 20) / 20.0  # 0.0 to 1.0
		var battle_tint = Color(1.2, 0.8, 0.8, 1.0)
		tinted_color = tinted_color.lerp(battle_tint, hardened_intensity * 0.3)

	return tinted_color