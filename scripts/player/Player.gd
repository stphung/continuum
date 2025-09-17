extends Area2D

## Weapon Pattern System Classes (embedded to avoid import issues)

## Base class for weapon firing patterns
class WeaponPattern extends RefCounted:
	class BulletConfig:
		var position_offset: Vector2 = Vector2.ZERO
		var direction: Vector2 = Vector2.UP
		var muzzle_type: String = "center"  # "center", "left", "right"

		func _init(pos_offset: Vector2 = Vector2.ZERO, dir: Vector2 = Vector2.UP, muzzle: String = "center"):
			position_offset = pos_offset
			direction = dir
			muzzle_type = muzzle

	func get_bullet_configs() -> Array:
		assert(false, "WeaponPattern.get_bullet_configs() must be implemented by subclass")
		return []

	func fire(player: Node2D) -> void:
		var configs = get_bullet_configs()
		for config in configs:
			var muzzle_position = get_muzzle_position(player, config.muzzle_type)
			player.shoot.emit(muzzle_position, config.direction, "vulcan")

	func get_muzzle_position(player: Node2D, muzzle_type: String) -> Vector2:
		match muzzle_type:
			"left":
				return player.get_node("LeftMuzzle").global_position
			"right":
				return player.get_node("RightMuzzle").global_position
			"center", _:
				return player.get_node("MuzzlePosition").global_position

## Specific weapon patterns
class SingleShotPattern extends WeaponPattern:
	func get_bullet_configs() -> Array:
		return [BulletConfig.new(Vector2.ZERO, Vector2.UP, "center")]

class DualShotPattern extends WeaponPattern:
	func get_bullet_configs() -> Array:
		return [
			BulletConfig.new(Vector2.ZERO, Vector2.UP, "left"),
			BulletConfig.new(Vector2.ZERO, Vector2.UP, "right")
		]

class SpreadShotPattern extends WeaponPattern:
	func get_bullet_configs() -> Array:
		return [
			BulletConfig.new(Vector2.ZERO, Vector2.UP, "center"),
			BulletConfig.new(Vector2.ZERO, Vector2(-0.1, -1).normalized(), "left"),
			BulletConfig.new(Vector2.ZERO, Vector2(0.1, -1).normalized(), "right")
		]

class ArcPattern extends WeaponPattern:
	var bullet_count: int
	var arc_width: float

	func _init(bullets: int, width: float):
		bullet_count = bullets
		arc_width = width

	func get_bullet_configs() -> Array:
		var configs: Array = []
		if bullet_count == 1:
			configs.append(BulletConfig.new(Vector2.ZERO, Vector2.UP, "center"))
			return configs

		for i in range(bullet_count):
			var angle = -arc_width/2 + (i * arc_width / (bullet_count - 1))
			var direction = Vector2(angle, -1).normalized()
			var muzzle_type = get_muzzle_for_angle(angle)
			configs.append(BulletConfig.new(Vector2.ZERO, direction, muzzle_type))
		return configs

	func get_muzzle_for_angle(angle: float) -> String:
		if abs(angle) < 0.15:
			return "center"
		elif angle < 0:
			return "left"
		else:
			return "right"

## Factory function to create weapon patterns
static func create_vulcan_pattern_for_level(level: int) -> WeaponPattern:
	match level:
		1:
			return SingleShotPattern.new()
		2:
			return DualShotPattern.new()
		3:
			return SpreadShotPattern.new()
		4, 5:
			return ArcPattern.new(level, 0.6)
		6, 7:
			return ArcPattern.new(level, 0.8)
		8, 9, 10:
			return ArcPattern.new(level, 1.0)
		11, 12, 13:
			return ArcPattern.new(level, 0.7)
		14, 15, 16:
			return ArcPattern.new(level, 0.75)
		17, 18, 19:
			return ArcPattern.new(level, 0.8)
		20, _:
			return ArcPattern.new(20, 0.9)  # Maximum firepower

signal player_hit
signal shoot(position, direction, weapon_type)
signal use_bomb

@export var speed = 400
@export var can_shoot = true

var screen_size
var invulnerable = false
var weapon_level = 1
var weapon_type = "vulcan"

# Weapon pattern system
var vulcan_patterns: Dictionary = {}  # Cache for weapon patterns

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

	# Stop timer first to ensure clean initialization
	$ShootTimer.stop()
	adjust_fire_rate()  # Initialize fire rate
	$ShootTimer.start()  # Start with correct fire rate

	# Ensure ship is visible and functional on spawn
	visible = true
	set_process(true)
	can_shoot = true

	# Start with invulnerability when spawned/respawned
	start_invulnerability()

	# Initialize weapon pattern system
	initialize_weapon_patterns()

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
		"chain":
			fire_chain()

	# Play different shooting sounds for different weapons
	if has_node("/root/SoundManager"):
		match weapon_type:
			"chain":
				SoundManager.play_random_pitch("shoot", -6.0, 0.2)  # Medium pitch for chain
			"vulcan":
				SoundManager.play_random_pitch("shoot", -12.0, 0.15)  # Higher pitch for vulcan

## Initialize weapon pattern system for vulcan weapons
func initialize_weapon_patterns():
	# Pre-populate patterns for all weapon levels to avoid runtime allocation
	for level in range(1, 21):  # Levels 1-20
		vulcan_patterns[level] = create_vulcan_pattern_for_level(level)

## New streamlined fire_vulcan method using pattern system
func fire_vulcan():
	var pattern = vulcan_patterns.get(weapon_level, vulcan_patterns[20])
	pattern.fire(self)


func fire_chain():
	# Chain lightning fires single projectiles that chain to nearby enemies
	# The chain count is handled in PlasmaBullet.gd based on weapon_level
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

	# Drop power-ups equal to weapon level (e.g., level 7 = drop 7 power-ups)
	var weapon_upgrades_to_drop = weapon_level
	for i in range(weapon_upgrades_to_drop):
		var powerup = powerup_scene.instantiate()
		# Drop the same weapon type the player had
		match weapon_type:
			"vulcan":
				powerup.powerup_type = "vulcan_powerup"
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
			# Always increase level when picking up any weapon
			weapon_level = min(weapon_level + 1, 20)
			if weapon_type != "vulcan":
				# Switch to vulcan if different type
				weapon_type = "vulcan"
			show_upgrade_effect("VULCAN LV " + str(weapon_level))
			adjust_fire_rate()
		"chain_powerup":
			# Always increase level when picking up any weapon
			weapon_level = min(weapon_level + 1, 20)
			if weapon_type != "chain":
				# Switch to chain if different type
				weapon_type = "chain"
			show_upgrade_effect("CHAIN LV " + str(weapon_level))
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
	var was_running = not $ShootTimer.is_stopped()
	if was_running:
		$ShootTimer.stop()

	match weapon_type:
		"vulcan":
			# Scale fire rate from 0.25s at level 1 to 0.05s at level 20
			$ShootTimer.wait_time = max(0.05, 0.25 - (weapon_level - 1) * 0.01)
		"chain":
			# ULTRA aggressive fire rate scaling for chain lightning
			# Level 1: 0.2s, Level 10: 0.03s, Level 20: 0.01s (insane speed!)
			$ShootTimer.wait_time = max(0.01, 0.2 - (weapon_level - 1) * 0.01)

	if was_running:
		$ShootTimer.start()

	print("Fire rate adjusted - Weapon: ", weapon_type, " Level: ", weapon_level, " Timer: ", $ShootTimer.wait_time)

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