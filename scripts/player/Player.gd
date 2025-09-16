extends Area2D

signal player_hit
signal shoot(position, direction, weapon_type)
signal use_bomb

@export var speed = 400
@export var can_shoot = true

var screen_size
var invulnerable = false
var weapon_level = 1
var weapon_type = "vulcan"

# Movement animation variables
var current_velocity = Vector2.ZERO
var banking_angle = 0.0
var max_banking_angle = 20.0  # Maximum tilt in degrees
var banking_smoothing = 8.0
var engine_glow_intensity = 1.0
var target_engine_intensity = 1.0
var is_main_thrusting = false  # Backward movement (main engine)
var is_forward_thrusting = false  # Forward movement (forward thrusters)
var is_braking = false  # Downward movement (air brakes)

func _ready():
	# Only set screen_size if it hasn't been set by external code (like tests)
	if screen_size == null:
		screen_size = get_viewport_rect().size
	position = Vector2(screen_size.x / 2, screen_size.y - 100)
	add_to_group("player")
	adjust_fire_rate()  # Initialize fire rate
	
	# Ensure ship is visible and functional on spawn
	visible = true
	set_process(true)
	can_shoot = true
	
	# Start with invulnerability when spawned/respawned
	start_invulnerability()

func _process(delta):
	handle_movement(delta)
	handle_shooting()
	handle_bomb()
	update_visual_animations(delta)

	if invulnerable:
		modulate.a = sin(Time.get_ticks_msec() * 0.02) * 0.5 + 0.5

func handle_movement(delta):
	var velocity = Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		velocity.y -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_right"):
		velocity.x += 1

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		position += velocity * delta

	# Store current velocity for visual animations
	current_velocity = velocity

	# Update movement states for visual effects
	is_forward_thrusting = Input.is_action_pressed("move_up")  # Moving forward/up on screen
	is_main_thrusting = Input.is_action_pressed("move_down")  # Moving backward/down on screen
	is_braking = Input.is_action_pressed("move_down")  # Also counts as braking

	# Always enforce screen boundaries regardless of movement
	position.x = clamp(position.x, 20, screen_size.x - 20)
	position.y = clamp(position.y, 20, screen_size.y - 20)

func handle_shooting():
	if Input.is_action_pressed("shoot") and can_shoot:
		pass

func handle_bomb():
	if Input.is_action_just_pressed("bomb"):
		use_bomb.emit()

func _on_shoot_timer_timeout():
	if Input.is_action_pressed("shoot") and can_shoot:
		fire_weapon()

func fire_weapon():
	match weapon_type:
		"vulcan":
			fire_vulcan()
		"laser":
			fire_laser()
		"chain":
			fire_chain()

	# Play different shooting sounds for different weapons
	if has_node("/root/SoundManager"):
		match weapon_type:
			"laser":
				SoundManager.play_random_pitch("laser", -8.0, 0.1)  # Deeper, more focused sound
			"chain":
				SoundManager.play_random_pitch("laser", -6.0, 0.2)  # Medium pitch for chain
			"vulcan":
				SoundManager.play_random_pitch("shoot", -12.0, 0.15)  # Higher pitch for vulcan

func fire_vulcan():
	match weapon_level:
		1:
			shoot.emit($MuzzlePosition.global_position, Vector2.UP, "vulcan")
		2:
			shoot.emit($LeftMuzzle.global_position, Vector2.UP, "vulcan")
			shoot.emit($RightMuzzle.global_position, Vector2.UP, "vulcan")
		3:
			shoot.emit($MuzzlePosition.global_position, Vector2.UP, "vulcan")
			shoot.emit($LeftMuzzle.global_position, Vector2(-0.1, -1).normalized(), "vulcan")
			shoot.emit($RightMuzzle.global_position, Vector2(0.1, -1).normalized(), "vulcan")
		_:
			shoot.emit($MuzzlePosition.global_position, Vector2.UP, "vulcan")
			shoot.emit($LeftMuzzle.global_position, Vector2(-0.2, -1).normalized(), "vulcan")
			shoot.emit($RightMuzzle.global_position, Vector2(0.2, -1).normalized(), "vulcan")
			shoot.emit($LeftMuzzle.global_position, Vector2(-0.1, -1).normalized(), "vulcan")
			shoot.emit($RightMuzzle.global_position, Vector2(0.1, -1).normalized(), "vulcan")

func fire_laser():
	# Laser always fires a single, powerful beam regardless of level
	# Higher levels increase damage and pierce through more enemies
	shoot.emit($MuzzlePosition.global_position, Vector2.UP, "laser")

func fire_chain():
	# Chain lightning fires single projectiles that chain to nearby enemies
	match weapon_level:
		1:
			# Level 1: Single shot, 1 chain
			shoot.emit($MuzzlePosition.global_position, Vector2.UP, "chain")
		2:
			# Level 2: Single shot, 2 chains
			shoot.emit($MuzzlePosition.global_position, Vector2.UP, "chain")
		3:
			# Level 3: Single shot, 3 chains
			shoot.emit($MuzzlePosition.global_position, Vector2.UP, "chain")
		4:
			# Level 4: Single shot, 4 chains
			shoot.emit($MuzzlePosition.global_position, Vector2.UP, "chain")
		5:
			# Level 5: Single shot, 5 chains
			shoot.emit($MuzzlePosition.global_position, Vector2.UP, "chain")

func _on_area_entered(area):
	if area.is_in_group("enemies") or area.is_in_group("enemy_bullets"):
		# Check invulnerability and immediately set it to prevent multiple hits in same frame
		if invulnerable:
			return
		invulnerable = true  # Immediately set invulnerable to prevent multiple damage
		take_damage()
	elif area.is_in_group("powerups"):
		collect_powerup(area)

func take_damage():
	# Always create explosion effect for visual feedback
	create_death_explosion()

	# Play player hit sound
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("player_hit", -5.0)

	# Drop power-ups equivalent to current upgrades
	drop_power_ups()

	# Always destroy ship immediately on any hit
	destroy_ship()

	# Emit the hit signal - Game.gd will handle lives/respawn/game over logic
	player_hit.emit()

func create_death_explosion():
	EffectManager.create_explosion("player_death", position, get_parent())

func drop_power_ups():
	"""Drop power-ups equivalent to current player upgrades when dying"""
	var powerup_scene = preload("res://scenes/pickups/PowerUp.tscn")
	var parent = get_parent()

	# Drop weapon power-ups equal to weapon level - 1 (level 1 is default)
	var weapon_upgrades_to_drop = weapon_level - 1
	for i in range(weapon_upgrades_to_drop):
		var powerup = powerup_scene.instantiate()
		# Drop the same weapon type the player had
		match weapon_type:
			"vulcan":
				powerup.powerup_type = "vulcan_powerup"
			"laser":
				powerup.powerup_type = "laser_powerup"
			"chain":
				powerup.powerup_type = "chain_powerup"
		powerup.update_appearance()

		# Position power-ups in a spread around death location
		var spread_angle = (i * TAU / max(weapon_upgrades_to_drop, 1)) + randf_range(-0.5, 0.5)
		var spread_distance = randf_range(30, 60)
		var offset = Vector2(cos(spread_angle), sin(spread_angle)) * spread_distance
		powerup.position = position + offset

		parent.add_child(powerup)


func destroy_ship():
	# Make ship invisible immediately
	visible = false
	# Disable further input/collision
	set_process(false)
	can_shoot = false

func start_invulnerability():
	# Start 5 seconds of invulnerability with flashing
	invulnerable = true
	$InvulnerabilityTimer.start()
	
	# Create flashing effect for 5 seconds
	var tween = create_tween()
	tween.set_loops(25)  # 25 loops over 5 seconds = 0.2s per loop
	tween.tween_property(self, "modulate:a", 0.3, 0.1)
	tween.tween_property(self, "modulate:a", 1.0, 0.1)

func _on_invulnerability_timer_timeout():
	invulnerable = false
	modulate.a = 1.0

func collect_powerup(powerup):
	var game = get_parent()
	match powerup.powerup_type:
		"vulcan_powerup":
			if weapon_type == "vulcan":
				# Same weapon type: upgrade level
				weapon_level = min(weapon_level + 1, 5)
				show_upgrade_effect("VULCAN LV " + str(weapon_level))
			else:
				# Different weapon type: switch and reset to level 1
				weapon_type = "vulcan"
				weapon_level = 1
				show_upgrade_effect("VULCAN")
			adjust_fire_rate()
		"laser_powerup":
			if weapon_type == "laser":
				# Same weapon type: upgrade level
				weapon_level = min(weapon_level + 1, 5)
				show_upgrade_effect("LASER LV " + str(weapon_level))
			else:
				# Different weapon type: switch and reset to level 1
				weapon_type = "laser"
				weapon_level = 1
				show_upgrade_effect("LASER")
			adjust_fire_rate()
		"chain_powerup":
			if weapon_type == "chain":
				# Same weapon type: upgrade level
				weapon_level = min(weapon_level + 1, 5)
				show_upgrade_effect("CHAIN LV " + str(weapon_level))
			else:
				# Different weapon type: switch and reset to level 1
				weapon_type = "chain"
				weapon_level = 1
				show_upgrade_effect("CHAIN")
			adjust_fire_rate()
		"bomb":
			if game.has_method("add_bomb"):
				game.add_bomb()
			elif "bombs" in game:
				game.bombs += 1
			show_upgrade_effect("BOMB +1")
		"life":
			if game.has_method("add_life"):
				game.add_life()
			elif "lives" in game:
				game.lives += 1
			show_upgrade_effect("LIFE +1")

	if game.has_method("update_ui"):
		game.update_ui()

	# Play power-up collection sound
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("powerup", -8.0, randf_range(0.9, 1.1))

	powerup.call_deferred("queue_free")

func adjust_fire_rate():
	# Adjust shooting timer based on weapon type and level
	match weapon_type:
		"vulcan":
			$ShootTimer.wait_time = max(0.15, 0.25 - (weapon_level - 1) * 0.02)  # Faster spread fire rate
		"laser":
			$ShootTimer.wait_time = max(0.18, 0.28 - (weapon_level - 1) * 0.02)  # Increased laser rate
		"chain":
			$ShootTimer.wait_time = max(0.11, 0.15 - (weapon_level - 1) * 0.01)  # 2x faster chain lightning

func show_upgrade_effect(text):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 24)
	label.modulate = Color(1, 1, 0, 1)
	label.position = Vector2(-50, -50)
	add_child(label)
	
	var tween = create_tween()
	tween.parallel().tween_property(label, "position:y", -100, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0, 1.0)
	tween.tween_callback(label.queue_free)
	
	# Flash the player to show upgrade
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color(2, 2, 2, 1), 0.1)
	flash_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)

func destroy():
	call_deferred("queue_free")

func update_visual_animations(delta):
	# Banking animation - use asymmetric scaling for 3D perspective effect
	var banking_intensity = 0.0
	if current_velocity.x != 0:
		banking_intensity = current_velocity.x / speed  # -1 to 1

	# Reset polygon to new detailed fighter-jet shape
	$Sprite.polygon = PackedVector2Array([
		Vector2(0, -25), Vector2(-3, -18), Vector2(-8, -10), Vector2(-18, 5),
		Vector2(-20, 12), Vector2(-15, 18), Vector2(-8, 20), Vector2(-3, 22),
		Vector2(0, 15), Vector2(3, 22), Vector2(8, 20), Vector2(15, 18),
		Vector2(20, 12), Vector2(18, 5), Vector2(8, -10), Vector2(3, -18), Vector2(0, -25)
	])

	# Apply 3D banking perspective using transform scaling + subtle rotation
	if abs(banking_intensity) > 0.05:
		# Banking creates asymmetric horizontal scaling + perspective rotation
		var scale_factor = 1.0 + abs(banking_intensity) * 0.3  # 30% scale change max
		var perspective_skew = banking_intensity * 0.15  # Subtle perspective skew

		# Banking right: left side compresses, right side stretches
		# Banking left: right side compresses, left side stretches
		var scale_x = 1.0 + banking_intensity * 0.2  # Horizontal scaling
		var scale_y = 1.0 - abs(banking_intensity) * 0.1  # Slight vertical compression

		# Apply asymmetric scaling to simulate 3D perspective
		$Sprite.scale = Vector2(scale_x, scale_y)

		# Add subtle rotation for banking effect (much less than before)
		rotation = lerp(rotation, deg_to_rad(banking_intensity * 8.0), 12.0 * delta)
	else:
		# Return to neutral
		$Sprite.scale = Vector2(1.0, 1.0)
		rotation = lerp(rotation, 0.0, 8.0 * delta)

	# INSANE engine glow - only for forward movement
	if current_velocity.length() > 0:
		if is_forward_thrusting:
			target_engine_intensity = 8.0  # INSANE glow for forward movement only
			$Engine.modulate = Color(1, 0.2, 0, 1) * target_engine_intensity  # Ultra bright orange
		else:
			target_engine_intensity = 1.5  # Subtle for other directions
			$Engine.modulate = Color(1, 0.5, 0, 1) * target_engine_intensity
	else:
		target_engine_intensity = 1.0
		$Engine.modulate = Color(1, 0.5, 0, 1) * target_engine_intensity

	engine_glow_intensity = lerp(engine_glow_intensity, target_engine_intensity, 15.0 * delta)

	# MASSIVE forward thrust particles (when moving up/forward) - ULTIMATE DRAMA
	if is_forward_thrusting:
		if not $MainThrusterParticles.emitting:
			$MainThrusterParticles.emitting = true
		# INSANE particle increase - make it impossible to miss
		$MainThrusterParticles.amount = 300 + int(abs(current_velocity.y) / speed * 200)

		# EXTREME velocity and scale for maximum visibility
		$MainThrusterParticles.initial_velocity_min = 300.0
		$MainThrusterParticles.initial_velocity_max = 600.0
		$MainThrusterParticles.scale_amount_min = 2.0
		$MainThrusterParticles.scale_amount_max = 6.0
		$MainThrusterParticles.lifetime = 2.0  # Longer lasting
		$MainThrusterParticles.spread = 45.0  # Wider spread
	else:
		$MainThrusterParticles.emitting = false

	# NO backward movement effects - completely disabled
	$ForwardThrusterParticles.emitting = false
	$BrakingParticles.emitting = false