extends Node2D

@export var bullet_scene: PackedScene = preload("res://scenes/projectiles/Bullet.tscn") if ResourceLoader.exists("res://scenes/projectiles/Bullet.tscn") else null
@export var laser_bullet_scene: PackedScene = preload("res://scenes/projectiles/LaserBullet.tscn") if ResourceLoader.exists("res://scenes/projectiles/LaserBullet.tscn") else null
@export var powerup_scene: PackedScene = preload("res://scenes/pickups/PowerUp.tscn") if ResourceLoader.exists("res://scenes/pickups/PowerUp.tscn") else null

var score = 0
var lives = 3
var bombs = 3
var game_over = false
var current_player = null

func _ready():
	randomize()
	setup_starfield_background()
	spawn_player()
	update_ui()
	_setup_enemy_system()

func setup_starfield_background():
	"""Initialize the reusable StarfieldBackground component"""
	var starfield_scene = preload("res://scenes/shared/StarfieldBackground.tscn")
	if starfield_scene:
		var starfield = starfield_scene.instantiate()
		# Insert starfield between background and other elements
		add_child(starfield)
		move_child(starfield, 1)  # Position after Background (index 0)

		# Configure for game scene
		starfield.set_screen_dimensions(800, 900)
		starfield.star_count = 50
		starfield.star_speed = 100

func _process(delta):
	# Starfield animation is now handled by the StarfieldBackground component
	pass

func spawn_player():
	var player_scene = preload("res://scenes/player/Player.tscn") if ResourceLoader.exists("res://scenes/player/Player.tscn") else null
	if player_scene:
		# Remove old player instance if it exists
		if current_player and is_instance_valid(current_player):
			current_player.call_deferred("queue_free")
			await current_player.tree_exited
		
		# Remove the placeholder Player node from scene if it exists
		if has_node("Player"):
			$Player.call_deferred("queue_free")
		
		# Create new player
		current_player = player_scene.instantiate()
		add_child(current_player)
		current_player.position = Vector2(400, 800)
		current_player.add_to_group("player")
		current_player.connect("player_hit", _on_player_hit)
		current_player.connect("shoot", _on_player_shoot)
		current_player.connect("use_bomb", _on_player_use_bomb)





func _setup_enemy_system():
	# Only connect signals if not already connected
	if not EnemyManager.enemy_destroyed.is_connected(_on_enemy_destroyed):
		EnemyManager.connect("enemy_destroyed", _on_enemy_destroyed)
	if not EnemyManager.wave_announcement.is_connected(_on_wave_announcement):
		EnemyManager.connect("wave_announcement", _on_wave_announcement)
	EnemyManager.setup_for_game($Enemies)

	# Connect the existing timers to the EnemyManager (check if not already connected)
	if not $EnemySpawnTimer.timeout.is_connected(_on_enemy_spawn_timer_timeout):
		$EnemySpawnTimer.timeout.connect(_on_enemy_spawn_timer_timeout)
	if not $WaveTimer.timeout.is_connected(_on_wave_timer_timeout):
		$WaveTimer.timeout.connect(_on_wave_timer_timeout)

func _on_enemy_spawn_timer_timeout():
	if game_over:
		return
	EnemyManager.spawn_random_enemies()

func _on_wave_timer_timeout():
	if game_over:
		return
	EnemyManager.advance_wave()

func _on_wave_announcement(wave_num: int):
	var label = Label.new()
	label.text = "WAVE " + str(wave_num)
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
	EffectManager.create_explosion("enemy_destroy", pos, $Effects)

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
		if enemy.has_method("destroy"):
			enemy.destroy()

	# Clear all enemy bullets too
	for bullet in $Bullets.get_children():
		if bullet.is_in_group("enemy_bullets"):
			bullet.call_deferred("queue_free")

	# Create massive bomb explosion effect
	EffectManager.create_explosion("bomb", Vector2(400, 450), $Effects)

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
	timer.timeout.connect(timer.call_deferred.bind("queue_free"))
	add_child(timer)
	timer.start()

func game_over_sequence():
	game_over = true
	EnemyManager.set_game_over(true)
	$UI/GameOverPanel.visible = true
	$UI/GameOverPanel/FinalScoreLabel.text = "Final Score: " + str(score)


	if current_player and is_instance_valid(current_player):
		current_player.call_deferred("queue_free")
		current_player = null

func _on_restart_button_pressed():
	get_tree().reload_current_scene()


func get_player_weapon_info() -> Dictionary:
	"""Get player weapon information for AI system"""
	if current_player and is_instance_valid(current_player):
		return {
			"weapon_type": current_player.weapon_type,
			"weapon_level": current_player.weapon_level,
			"can_shoot": current_player.can_shoot
		}
	return {}

func is_game_active() -> bool:
	"""Check if game is actively being played"""
	return not game_over and current_player != null and is_instance_valid(current_player)

func add_bomb():
	"""Add a bomb to player inventory (for powerup system)"""
	bombs += 1
	update_ui()

func add_life():
	"""Add a life to player (for powerup system)"""
	lives += 1
	update_ui()

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

