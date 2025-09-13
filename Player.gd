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

func _ready():
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
		position.x = clamp(position.x, 20, screen_size.x - 20)
		position.y = clamp(position.y, 20, screen_size.y - 20)

func handle_shooting():
	if Input.is_action_pressed("shoot") and can_shoot:
		pass

func handle_bomb():
	if Input.is_action_just_pressed("bomb"):
		emit_signal("use_bomb")

func _on_shoot_timer_timeout():
	if Input.is_action_pressed("shoot") and can_shoot:
		fire_weapon()

func fire_weapon():
	match weapon_type:
		"vulcan":
			fire_vulcan()
		"laser":
			fire_laser()
	
	# Play different shooting sounds for different weapons
	if has_node("/root/SoundManager"):
		if weapon_type == "laser":
			SoundManager.play_random_pitch("laser", -8.0, 0.1)  # Deeper, more focused sound
		else:
			SoundManager.play_random_pitch("shoot", -12.0, 0.15)  # Higher pitch for vulcan

func fire_vulcan():
	match weapon_level:
		1:
			emit_signal("shoot", $MuzzlePosition.global_position, Vector2.UP, "vulcan")
		2:
			emit_signal("shoot", $LeftMuzzle.global_position, Vector2.UP, "vulcan")
			emit_signal("shoot", $RightMuzzle.global_position, Vector2.UP, "vulcan")
		3:
			emit_signal("shoot", $MuzzlePosition.global_position, Vector2.UP, "vulcan")
			emit_signal("shoot", $LeftMuzzle.global_position, Vector2(-0.1, -1).normalized(), "vulcan")
			emit_signal("shoot", $RightMuzzle.global_position, Vector2(0.1, -1).normalized(), "vulcan")
		_:
			emit_signal("shoot", $MuzzlePosition.global_position, Vector2.UP, "vulcan")
			emit_signal("shoot", $LeftMuzzle.global_position, Vector2(-0.2, -1).normalized(), "vulcan")
			emit_signal("shoot", $RightMuzzle.global_position, Vector2(0.2, -1).normalized(), "vulcan")
			emit_signal("shoot", $LeftMuzzle.global_position, Vector2(-0.1, -1).normalized(), "vulcan")
			emit_signal("shoot", $RightMuzzle.global_position, Vector2(0.1, -1).normalized(), "vulcan")

func fire_laser():
	# Laser always fires a single, powerful beam regardless of level
	# Higher levels increase damage and pierce through more enemies
	emit_signal("shoot", $MuzzlePosition.global_position, Vector2.UP, "laser")

func _on_area_entered(area):
	if invulnerable:
		return
		
	if area.is_in_group("enemies") or area.is_in_group("enemy_bullets"):
		take_damage()
	elif area.is_in_group("powerups"):
		collect_powerup(area)

func take_damage():
	# Always create explosion effect for visual feedback
	create_death_explosion()
	
	# Play player hit sound
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("player_hit", -5.0)
	
	# Always destroy ship immediately on any hit
	destroy_ship()
	
	# Emit the hit signal - Game.gd will handle lives/respawn/game over logic
	emit_signal("player_hit")

func create_death_explosion():
	# Main orange/red explosion
	var explosion = CPUParticles2D.new()
	explosion.position = position
	explosion.emitting = true
	explosion.amount = 60
	explosion.lifetime = 1.5
	explosion.one_shot = true
	explosion.initial_velocity_min = 80
	explosion.initial_velocity_max = 400
	explosion.angular_velocity_min = -360
	explosion.angular_velocity_max = 360
	explosion.scale_amount_min = 0.5
	explosion.scale_amount_max = 3.0
	explosion.color = Color(1, 0.3, 0, 1)  # Bright orange
	explosion.color_ramp = null
	get_parent().add_child(explosion)
	
	# Inner white-hot core explosion
	var core_explosion = CPUParticles2D.new()
	core_explosion.position = position
	core_explosion.emitting = true
	core_explosion.amount = 25
	core_explosion.lifetime = 0.6
	core_explosion.one_shot = true
	core_explosion.initial_velocity_min = 20
	core_explosion.initial_velocity_max = 150
	core_explosion.scale_amount_min = 0.8
	core_explosion.scale_amount_max = 2.5
	core_explosion.color = Color(1, 1, 0.8, 1)  # White-yellow hot core
	get_parent().add_child(core_explosion)
	
	# Blue sparks for ship pieces
	var sparks = CPUParticles2D.new()
	sparks.position = position
	sparks.emitting = true
	sparks.amount = 40
	sparks.lifetime = 1.2
	sparks.one_shot = true
	sparks.initial_velocity_min = 100
	sparks.initial_velocity_max = 300
	sparks.gravity = Vector2(0, 50)
	sparks.scale_amount_min = 0.2
	sparks.scale_amount_max = 0.8
	sparks.color = Color(0.3, 0.6, 1, 1)  # Ship blue color
	get_parent().add_child(sparks)
	
	# Create larger ship fragments
	for i in range(5):
		var fragment = Polygon2D.new()
		fragment.position = position + Vector2(randf_range(-15, 15), randf_range(-15, 15))
		fragment.color = Color(0.3, 0.6, 1, 1)  # Ship color
		# Make fragments bigger and more varied
		var size_mult = randf_range(0.8, 2.0)
		fragment.polygon = PackedVector2Array([-3 * size_mult, -3 * size_mult, 3 * size_mult, -3 * size_mult, 0, 3 * size_mult])
		get_parent().add_child(fragment)
		
		# Animate fragments with more dramatic movement
		var fragment_tween = create_tween()
		var velocity = Vector2(randf_range(-200, 200), randf_range(-200, -100))
		fragment_tween.parallel().tween_method(
			func(pos): fragment.position = pos,
			fragment.position,
			fragment.position + velocity * 1.0,
			1.0
		)
		fragment_tween.parallel().tween_property(fragment, "modulate:a", 0, 1.0)
		fragment_tween.parallel().tween_property(fragment, "rotation", randf_range(-PI * 3, PI * 3), 1.0)
		fragment_tween.tween_callback(fragment.queue_free)
	
	# Enhanced screen flash effect
	var game = get_parent()
	if game:
		# Brighter, longer screen flash
		var flash = ColorRect.new()
		flash.size = Vector2(800, 900)
		flash.color = Color(1, 0.8, 0.2, 0.6)  # Orange flash instead of white
		game.add_child(flash)
		
		var flash_tween = create_tween()
		flash_tween.tween_property(flash, "modulate:a", 0, 0.4)  # Longer flash
		flash_tween.tween_callback(flash.queue_free)
		
		# Add screen shake rings
		for ring_i in range(3):
			var ring = Polygon2D.new()
			ring.position = position
			ring.color = Color(1, 0.5, 0, 0.3 - ring_i * 0.1)
			# Create expanding ring
			var radius = 20.0 + ring_i * 10
			var points = PackedVector2Array()
			for angle_i in range(16):
				var angle = angle_i * PI * 2 / 16
				points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
			ring.polygon = points
			game.add_child(ring)
			
			# Animate ring expansion and fade
			var ring_tween = create_tween()
			ring_tween.parallel().tween_property(ring, "scale", Vector2(4, 4), 0.6)
			ring_tween.parallel().tween_property(ring, "modulate:a", 0, 0.6)
			ring_tween.tween_callback(ring.queue_free)

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
		"weapon_upgrade":
			weapon_level = min(weapon_level + 1, 5)
			show_upgrade_effect("WEAPON LV " + str(weapon_level))
			# Adjust fire rate based on weapon type and level
			adjust_fire_rate()
		"weapon_switch":
			weapon_type = "laser" if weapon_type == "vulcan" else "vulcan"
			show_upgrade_effect(weapon_type.to_upper())
			adjust_fire_rate()
		"bomb":
			if game.has_method("add_bomb"):
				game.add_bomb()
			else:
				game.bombs += 1
			show_upgrade_effect("BOMB +1")
		"life":
			if game.has_method("add_life"):
				game.add_life()
			else:
				game.lives += 1
			show_upgrade_effect("LIFE +1")
	
	if game.has_method("update_ui"):
		game.update_ui()
	
	# Play power-up collection sound
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("powerup", -8.0, randf_range(0.9, 1.1))
	
	powerup.queue_free()

func adjust_fire_rate():
	# Adjust shooting timer based on weapon type and level
	match weapon_type:
		"vulcan":
			$ShootTimer.wait_time = max(0.08, 0.15 - (weapon_level - 1) * 0.01)  # Gets faster with levels
		"laser":
			$ShootTimer.wait_time = max(0.2, 0.3 - (weapon_level - 1) * 0.02)   # Slower but gets faster with levels

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
	queue_free()