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
	EffectManager.create_explosion("player_death", position, get_parent())

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