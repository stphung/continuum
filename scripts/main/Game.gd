extends Node2D

@export var bullet_scene: PackedScene = preload("res://scenes/projectiles/Bullet.tscn") if ResourceLoader.exists("res://scenes/projectiles/Bullet.tscn") else null
@export var chain_bullet_scene: PackedScene = preload("res://scenes/projectiles/PlasmaBullet.tscn") if ResourceLoader.exists("res://scenes/projectiles/PlasmaBullet.tscn") else null
@export var powerup_scene: PackedScene = preload("res://scenes/pickups/PowerUp.tscn") if ResourceLoader.exists("res://scenes/pickups/PowerUp.tscn") else null

var lives = 3
var bombs = 3
var game_over = false
var current_player = null
var starfield_background

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
		starfield_background = starfield_scene.instantiate()
		# Insert starfield between background and other elements
		add_child(starfield_background)
		move_child(starfield_background, 1)  # Position after Background (index 0)

		# Configure for game scene
		starfield_background.set_screen_dimensions(720, 1280)
		starfield_background.star_count = 50
		starfield_background.star_speed = 100

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
		current_player.position = Vector2(360, 1100)
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
	# Check for wave 100 victory condition
	if wave_num >= 100:
		victory_sequence()
		return

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

	# Increase starfield speed with each wave for sense of acceleration
	if starfield_background:
		# Increase speed by 15% each wave, starting from wave 2
		if wave_num > 1:
			var speed_multiplier = 1.0 + (wave_num - 1) * 0.15
			starfield_background.set_star_speed(100 * speed_multiplier)

func _on_enemy_destroyed(pos):
	update_ui()
	EffectManager.create_explosion("enemy_destroy", pos, $Effects)

	if randf() < 0.1:
		spawn_powerup(pos)

func spawn_powerup(pos):
	if powerup_scene:
		var powerup = powerup_scene.instantiate()
		powerup.position = pos
		$PowerUps.add_child(powerup)

func _on_player_shoot(bullet_position, bullet_direction, weapon_type = "vulcan"):
	var scene_to_use
	match weapon_type:
		"vulcan":
			scene_to_use = bullet_scene
		"chain":
			scene_to_use = chain_bullet_scene
		_:
			scene_to_use = bullet_scene

	if scene_to_use:
		var bullet = scene_to_use.instantiate()
		bullet.position = bullet_position
		bullet.direction = bullet_direction

		# Pass weapon level to bullets for scaling
		if current_player and is_instance_valid(current_player):
			bullet.weapon_level = current_player.weapon_level

		# Initialize bullet with new weapon level
		if bullet.has_method("_initialize_bullet"):
			bullet._initialize_bullet()

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
		if enemy.is_in_group("enemies") and enemy.has_method("destroy"):
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
	timer.timeout.connect(func(): timer.queue_free())
	add_child(timer)
	timer.start()

func game_over_sequence():
	game_over = true
	EnemyManager.set_game_over(true)
	$UI/GameOverPanel.visible = true
	$UI/GameOverPanel/FinalWaveLabel.text = "Waves Completed: " + str(EnemyManager.get_current_wave() - 1)


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

func victory_sequence():
	"""Handle wave 100 victory condition"""
	game_over = true
	EnemyManager.set_game_over(true)

	# Victory achieved at wave 100

	# Show victory screen
	var victory_panel = Control.new()
	victory_panel.name = "VictoryPanel"
	victory_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	victory_panel.color = Color(0, 0, 0, 0.8)  # Semi-transparent background

	# Victory title
	var victory_label = Label.new()
	victory_label.text = "VICTORY!"
	victory_label.add_theme_font_size_override("font_size", 72)
	victory_label.modulate = Color(1, 1, 0, 1)  # Gold color
	victory_label.position = Vector2(250, 200)
	victory_label.size = Vector2(300, 100)
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Wave completion message
	var completion_label = Label.new()
	completion_label.text = "Wave 100 Complete!"
	completion_label.add_theme_font_size_override("font_size", 36)
	completion_label.modulate = Color(1, 0.8, 0, 1)
	completion_label.position = Vector2(200, 300)
	completion_label.size = Vector2(400, 50)
	completion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Waves completed info
	var waves_label = Label.new()
	waves_label.text = "100 Waves Completed!"
	waves_label.add_theme_font_size_override("font_size", 32)
	waves_label.modulate = Color(1, 1, 1, 1)
	waves_label.position = Vector2(200, 380)
	waves_label.size = Vector2(400, 50)
	waves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Restart button
	var restart_button = Button.new()
	restart_button.text = "Play Again"
	restart_button.position = Vector2(320, 500)
	restart_button.size = Vector2(120, 40)
	restart_button.pressed.connect(_on_restart_button_pressed)

	# Add all elements to victory panel
	victory_panel.add_child(victory_label)
	victory_panel.add_child(completion_label)
	victory_panel.add_child(waves_label)
	victory_panel.add_child(restart_button)

	$UI.add_child(victory_panel)

	# Play victory sound
	if has_node("/root/SoundManager"):
		SoundManager.play_sound("wave_start", 0.0)  # Use wave start sound for victory

	# Clean up player
	if current_player and is_instance_valid(current_player):
		current_player.call_deferred("queue_free")
		current_player = null

func update_ui():
	$UI/HUD/WaveLabel.text = "Wave: " + str(EnemyManager.get_current_wave())
	$UI/HUD/LivesLabel.text = "Lives: " + str(lives)
	$UI/HUD/BombsLabel.text = "Bombs: " + str(bombs)
	
	# Show weapon level if player exists
	if current_player and is_instance_valid(current_player) and current_player.has_method("get") and "weapon_type" in current_player:
		if not $UI/HUD.has_node("WeaponLabel"):
			var weapon_label = Label.new()
			weapon_label.name = "WeaponLabel"
			weapon_label.add_theme_font_size_override("font_size", 24)
			weapon_label.position = Vector2(10, 130)
			$UI/HUD.add_child(weapon_label)
		$UI/HUD/WeaponLabel.text = "Weapon: " + current_player.weapon_type.to_upper() + " LV" + str(current_player.weapon_level)

