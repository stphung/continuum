extends Node2D

@export var enemy_scene: PackedScene = preload("res://Enemy.tscn") if ResourceLoader.exists("res://Enemy.tscn") else null
@export var bullet_scene: PackedScene = preload("res://Bullet.tscn") if ResourceLoader.exists("res://Bullet.tscn") else null
@export var laser_bullet_scene: PackedScene = preload("res://LaserBullet.tscn") if ResourceLoader.exists("res://LaserBullet.tscn") else null
@export var powerup_scene: PackedScene = preload("res://PowerUp.tscn") if ResourceLoader.exists("res://PowerUp.tscn") else null

var score = 0
var lives = 3
var bombs = 3
var game_over = false
var star_speed = 100
var stars = []
var current_player = null
var wave_number = 1
var enemies_per_wave = 3
var spawn_delay_reduction = 0.0

func _ready():
	randomize()
	create_starfield()
	spawn_player()
	update_ui()

func create_starfield():
	for i in range(50):
		var star = ColorRect.new()
		var size = randf_range(1, 3)
		star.size = Vector2(size, size)
		star.position = Vector2(randf_range(0, 800), randf_range(0, 900))
		star.color = Color(1, 1, 1, randf_range(0.3, 0.8))
		$Stars.add_child(star)
		stars.append(star)

func _process(delta):
	if not game_over:
		update_starfield(delta)

func update_starfield(delta):
	for star in stars:
		star.position.y += star_speed * star.color.a * delta
		if star.position.y > 900:
			star.position.y = -10
			star.position.x = randf_range(0, 800)

func spawn_player():
	var player_scene = preload("res://Player.tscn") if ResourceLoader.exists("res://Player.tscn") else null
	if player_scene:
		# Remove old player instance if it exists
		if current_player and is_instance_valid(current_player):
			current_player.queue_free()
			await current_player.tree_exited
		
		# Remove the placeholder Player node from scene if it exists
		if has_node("Player"):
			$Player.queue_free()
		
		# Create new player
		current_player = player_scene.instantiate()
		add_child(current_player)
		current_player.position = Vector2(400, 800)
		current_player.add_to_group("player")
		current_player.connect("player_hit", _on_player_hit)
		current_player.connect("shoot", _on_player_shoot)
		current_player.connect("use_bomb", _on_player_use_bomb)

func _on_enemy_spawn_timer_timeout():
	if game_over:
		return
	
	# Randomly spawn 1-3 enemies at once sometimes
	var spawn_count = 1
	if randf() < 0.3:  # 30% chance for multiple enemies
		spawn_count = randi_range(2, min(3, wave_number))
	
	for i in spawn_count:
		spawn_enemy(i * 60)  # Offset enemies horizontally
	
	# Gradually make spawning faster
	$EnemySpawnTimer.wait_time = max(0.3, 0.8 - spawn_delay_reduction)

func spawn_enemy(x_offset = 0):
	if enemy_scene:
		var enemy = enemy_scene.instantiate()
		var x_pos = randf_range(50, 750) + x_offset
		x_pos = clamp(x_pos, 50, 750)
		enemy.position = Vector2(x_pos, -50)
		
		# Vary enemy properties based on wave
		enemy.health = min(3 + int(wave_number / 3), 8)
		enemy.speed = min(150 + wave_number * 10, 400)
		enemy.points = 100 * (1 + int(wave_number / 2))
		
		# Set movement patterns
		var patterns = ["straight", "zigzag", "dive"]
		enemy.movement_pattern = patterns[randi() % patterns.size()]
		
		$Enemies.add_child(enemy)
		enemy.connect("enemy_destroyed", _on_enemy_destroyed)

func _on_wave_timer_timeout():
	if game_over:
		return
		
	wave_number += 1
	spawn_delay_reduction = min(0.4, wave_number * 0.02)
	
	# Spawn a wave of enemies
	spawn_wave()
	
	# Show wave announcement
	show_wave_announcement()

func spawn_wave():
	var formation = randi() % 3
	
	match formation:
		0:  # Line formation
			for i in range(enemies_per_wave + wave_number):
				var timer = Timer.new()
				timer.wait_time = i * 0.2
				timer.one_shot = true
				timer.timeout.connect(func(): spawn_enemy(400 - 200 + i * 40))
				add_child(timer)
				timer.start()
		1:  # V formation
			for i in range(enemies_per_wave + wave_number):
				var timer = Timer.new()
				timer.wait_time = i * 0.1
				timer.one_shot = true
				var x = 400 + (i - (enemies_per_wave + wave_number) / 2) * 60
				timer.timeout.connect(func(): spawn_enemy(x - 400))
				add_child(timer)
				timer.start()
		2:  # Random burst
			for i in range(enemies_per_wave + wave_number * 2):
				spawn_enemy()

func show_wave_announcement():
	# Play wave start sound
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("wave_start", -3.0)
	
	var label = Label.new()
	label.text = "WAVE " + str(wave_number)
	label.add_theme_font_size_override("font_size", 48)
	label.modulate = Color(1, 0.5, 0, 1)
	label.position = Vector2(350, 400)
	$UI.add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1, 0.5)
	tween.tween_property(label, "modulate:a", 0, 1.0)
	tween.tween_callback(label.queue_free)

func _on_enemy_destroyed(points, pos):
	score += points
	update_ui()
	create_explosion(pos)
	
	if randf() < 0.2:
		spawn_powerup(pos)

func spawn_powerup(pos):
	if powerup_scene:
		var powerup = powerup_scene.instantiate()
		powerup.position = pos
		$PowerUps.add_child(powerup)

func _on_player_shoot(bullet_position, bullet_direction, weapon_type = "vulcan"):
	var scene_to_use = bullet_scene if weapon_type == "vulcan" else laser_bullet_scene
	
	if scene_to_use:
		var bullet = scene_to_use.instantiate()
		bullet.position = bullet_position
		bullet.direction = bullet_direction
		
		# Pass weapon level to laser bullets for scaling
		if weapon_type == "laser" and current_player and is_instance_valid(current_player):
			bullet.weapon_level = current_player.weapon_level
		
		$Bullets.add_child(bullet)

func _on_player_use_bomb():
	if bombs > 0:
		bombs -= 1
		update_ui()
		
		# Play bomb sound
		if has_node("/root/SoundManager"):
			SoundManager.play_sound("bomb", 0.0)
		
		clear_screen_with_bomb()

func clear_screen_with_bomb():
	# Destroy all enemies (they will create their own explosions)
	for enemy in $Enemies.get_children():
		enemy.destroy()
	
	# Clear all enemy bullets too
	for bullet in $Bullets.get_children():
		if bullet.is_in_group("enemy_bullets"):
			bullet.queue_free()
	
	# Create massive screen-wide explosion effect
	var mega_explosion = CPUParticles2D.new()
	mega_explosion.position = Vector2(400, 450)  # Center screen
	mega_explosion.emitting = true
	mega_explosion.amount = 100
	mega_explosion.lifetime = 1.5
	mega_explosion.one_shot = true
	mega_explosion.initial_velocity_min = 100
	mega_explosion.initial_velocity_max = 800
	mega_explosion.angular_velocity_min = -720
	mega_explosion.angular_velocity_max = 720
	mega_explosion.scale_amount_min = 1.0
	mega_explosion.scale_amount_max = 4.0
	mega_explosion.color = Color(1, 0.8, 0, 1)  # Bright yellow
	$Effects.add_child(mega_explosion)
	
	# Multiple expanding shockwave rings
	for ring_i in range(5):
		var shockwave = Polygon2D.new()
		shockwave.position = Vector2(400, 450)
		shockwave.color = Color(1, 1, 0.5, 0.4 - ring_i * 0.05)
		# Create large circle
		var points = PackedVector2Array()
		for i in range(20):
			var angle = i * PI * 2 / 20
			var radius = 30.0 + ring_i * 15
			points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
		shockwave.polygon = points
		$Effects.add_child(shockwave)
		
		# Animate with delay for cascading effect
		var ring_tween = create_tween()
		ring_tween.tween_delay(ring_i * 0.1)
		ring_tween.parallel().tween_property(shockwave, "scale", Vector2(8, 8), 0.8)
		ring_tween.parallel().tween_property(shockwave, "modulate:a", 0, 0.8)
		ring_tween.tween_callback(shockwave.queue_free)
	
	# Dramatic screen flash sequence
	var flash = ColorRect.new()
	flash.size = Vector2(800, 900)
	flash.color = Color(1, 1, 0.8, 0.9)  # Bright yellow-white
	add_child(flash)
	
	var flash_tween = create_tween()
	flash_tween.tween_property(flash, "modulate:a", 0, 0.6)  # Longer dramatic flash
	flash_tween.tween_callback(flash.queue_free)
	
	# Screen shake effect with multiple pulses
	for pulse_i in range(3):
		var pulse_flash = ColorRect.new()
		pulse_flash.size = Vector2(800, 900)
		pulse_flash.color = Color(1, 0.9, 0.2, 0.2)
		add_child(pulse_flash)
		
		var pulse_tween = create_tween()
		pulse_tween.tween_delay(pulse_i * 0.15)
		pulse_tween.tween_property(pulse_flash, "modulate:a", 0, 0.1)
		pulse_tween.tween_callback(pulse_flash.queue_free)
	
	# Clean up mega explosion
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 2.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func():
		if is_instance_valid(mega_explosion): mega_explosion.queue_free()
	)
	add_child(cleanup_timer)
	cleanup_timer.start()

func _on_player_hit():
	lives -= 1
	update_ui()
	
	if lives <= 0:
		game_over_sequence()
	else:
		respawn_player()

func respawn_player():
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(spawn_player)
	add_child(timer)
	timer.start()

func game_over_sequence():
	game_over = true
	$UI/GameOverPanel.visible = true
	$UI/GameOverPanel/FinalScoreLabel.text = "Final Score: " + str(score)
	
	if current_player and is_instance_valid(current_player):
		current_player.queue_free()
		current_player = null

func _on_restart_button_pressed():
	get_tree().reload_current_scene()

func update_ui():
	$UI/HUD/ScoreLabel.text = "Score: " + str(score)
	$UI/HUD/LivesLabel.text = "Lives: " + str(lives)
	$UI/HUD/BombsLabel.text = "Bombs: " + str(bombs)
	
	# Show weapon level if player exists
	if current_player and is_instance_valid(current_player):
		if not $UI/HUD.has_node("WeaponLabel"):
			var weapon_label = Label.new()
			weapon_label.name = "WeaponLabel"
			weapon_label.add_theme_font_size_override("font_size", 24)
			weapon_label.position = Vector2(10, 130)
			$UI/HUD.add_child(weapon_label)
		$UI/HUD/WeaponLabel.text = "Weapon: " + current_player.weapon_type.to_upper() + " LV" + str(current_player.weapon_level)

func create_explosion(pos):
	# Main orange explosion burst
	var explosion = CPUParticles2D.new()
	explosion.position = pos
	explosion.emitting = true
	explosion.amount = 45
	explosion.lifetime = 1.0
	explosion.one_shot = true
	explosion.initial_velocity_min = 80
	explosion.initial_velocity_max = 350
	explosion.angular_velocity_min = -360
	explosion.angular_velocity_max = 360
	explosion.scale_amount_min = 0.8
	explosion.scale_amount_max = 2.5
	explosion.color = Color(1, 0.4, 0, 1)  # Bright orange
	$Effects.add_child(explosion)
	
	# Yellow-white hot center
	var core = CPUParticles2D.new()
	core.position = pos
	core.emitting = true
	core.amount = 20
	core.lifetime = 0.4
	core.one_shot = true
	core.initial_velocity_min = 20
	core.initial_velocity_max = 120
	core.scale_amount_min = 1.0
	core.scale_amount_max = 2.0
	core.color = Color(1, 1, 0.6, 1)  # Bright yellow-white
	$Effects.add_child(core)
	
	# Red outer particles
	var outer_burst = CPUParticles2D.new()
	outer_burst.position = pos
	outer_burst.emitting = true
	outer_burst.amount = 30
	outer_burst.lifetime = 0.8
	outer_burst.one_shot = true
	outer_burst.initial_velocity_min = 200
	outer_burst.initial_velocity_max = 500
	outer_burst.gravity = Vector2(0, 30)
	outer_burst.scale_amount_min = 0.3
	outer_burst.scale_amount_max = 1.2
	outer_burst.color = Color(1, 0.2, 0.1, 1)  # Red outer ring
	$Effects.add_child(outer_burst)
	
	# Add shockwave ring
	var shockwave = Polygon2D.new()
	shockwave.position = pos
	shockwave.color = Color(1, 0.8, 0.4, 0.5)
	# Create circle
	var points = PackedVector2Array()
	for i in range(12):
		var angle = i * PI * 2 / 12
		points.append(Vector2(cos(angle) * 15, sin(angle) * 15))
	shockwave.polygon = points
	$Effects.add_child(shockwave)
	
	# Animate shockwave
	var shockwave_tween = create_tween()
	shockwave_tween.parallel().tween_property(shockwave, "scale", Vector2(3, 3), 0.4)
	shockwave_tween.parallel().tween_property(shockwave, "modulate:a", 0, 0.4)
	shockwave_tween.tween_callback(shockwave.queue_free)
	
	# Clean up particles
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 1.5
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func():
		if is_instance_valid(explosion): explosion.queue_free()
		if is_instance_valid(core): core.queue_free()
		if is_instance_valid(outer_burst): outer_burst.queue_free()
	)
	add_child(cleanup_timer)
	cleanup_timer.start()