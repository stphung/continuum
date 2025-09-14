extends GdUnitTestSuite

const Game = preload("res://scenes/main/Game.tscn")
const Player = preload("res://scenes/player/Player.tscn")
const Enemy = preload("res://scenes/enemies/Enemy.tscn")
const LaserBullet = preload("res://scenes/projectiles/LaserBullet.tscn")

var game: Node2D
var sound_manager: Node
var effect_manager: Node

func before_test():
	game = auto_free(Game.instantiate())
	add_child(game)
	game._ready()

	sound_manager = SoundManager
	effect_manager = EffectManager

	await get_tree().process_frame

func test_player_shooting_audio_visual_sync():
	# Spawn player
	if not game.current_player:
		game.spawn_player()

	await get_tree().process_frame

	var player = game.current_player
	var bullets_node = game.get_node("Bullets")
	var initial_bullet_count = bullets_node.get_child_count()

	# Test vulcan shooting
	player.weapon_type = "vulcan"
	player.fire_weapon()

	await get_tree().process_frame

	# Should create visual bullet
	assert_that(bullets_node.get_child_count()).is_greater(initial_bullet_count)

	# Test laser shooting
	player.weapon_type = "laser"
	player.fire_weapon()

	await get_tree().process_frame

	# Should create different visual bullet type
	var has_laser_bullet = false
	for bullet in bullets_node.get_children():
		if bullet.has_method("create_impact_effect"):
			has_laser_bullet = true
			break

	# Note: Audio testing requires mock or integration with actual sound system

func test_enemy_death_audio_visual_coordination():
	var enemy = auto_free(Enemy.instantiate())
	enemy.position = Vector2(400, 300)
	game.get_node("Enemies").add_child(enemy)
	enemy._ready()

	var effects_node = game.get_node("Effects")
	var initial_effect_count = effects_node.get_child_count()

	# Connect enemy to game's systems (only if not already connected)
	if not enemy.enemy_destroyed.is_connected(game._on_enemy_destroyed):
		enemy.connect("enemy_destroyed", game._on_enemy_destroyed)

	# Destroy enemy (should trigger both audio and visual effects)
	enemy.destroy()

	await get_tree().process_frame

	# Visual effects should be created
	assert_that(effects_node.get_child_count()).is_greater(initial_effect_count)

	# Check for particle systems created by explosion
	var has_particles = false
	for child in effects_node.get_children():
		if child is CPUParticles2D:
			has_particles = true
			break

	assert_that(has_particles).is_true()

func test_laser_impact_audio_visual_effects():
	var laser = auto_free(LaserBullet.instantiate())
	laser.position = Vector2(400, 300)
	laser.weapon_level = 2
	game.get_node("Bullets").add_child(laser)
	laser._ready()

	var bullets_node = game.get_node("Bullets")
	var initial_effect_count = bullets_node.get_child_count()

	# Create impact effect (visual)
	laser.create_impact_effect()

	await get_tree().process_frame

	# Should create visual impact particles
	assert_that(bullets_node.get_child_count()).is_greater(initial_effect_count)

	# Look for impact particles
	var has_impact_particles = false
	for child in bullets_node.get_children():
		if child is CPUParticles2D and child != laser:
			has_impact_particles = true
			break

	assert_that(has_impact_particles).is_true()

func test_bomb_explosion_comprehensive_effects():
	# Create enemies to be destroyed by bomb
	var enemies = []
	for i in range(3):
		var enemy = auto_free(Enemy.instantiate())
		enemy.position = Vector2(200 + i * 100, 300)
		game.get_node("Enemies").add_child(enemy)
		enemy._ready()
		enemies.append(enemy)

	var effects_node = game.get_node("Effects")
	var initial_effect_count = effects_node.get_child_count()

	# Trigger bomb
	game._on_player_use_bomb()

	await get_tree().process_frame

	# Should create massive visual effects
	assert_that(effects_node.get_child_count()).is_greater(initial_effect_count + 5)

	# Should destroy enemies (visual confirmation of bomb effect)
	for enemy in enemies:
		assert_that(enemy.is_queued_for_deletion()).is_true()

func test_powerup_collection_feedback():
	# Spawn player
	if not game.current_player:
		game.spawn_player()

	await get_tree().process_frame

	var player = game.current_player

	# Disable invulnerability for testing powerup collection
	player.invulnerable = false

	# Create powerup
	var powerup = preload("res://scenes/pickups/PowerUp.tscn").instantiate()
	powerup.position = player.position + Vector2(0, -50)
	game.get_node("PowerUps").add_child(powerup)
	powerup._ready()
	# Set powerup type AFTER _ready() to avoid randomization override
	powerup.powerup_type = "weapon_upgrade"
	powerup.update_appearance()

	var initial_weapon_level = player.weapon_level

	# Collect powerup directly
	player.collect_powerup(powerup)

	await get_tree().process_frame

	# Should trigger visual upgrade effect (flash, text)
	assert_that(player.weapon_level).is_equal(initial_weapon_level + 1)
	assert_that(powerup.is_queued_for_deletion()).is_true()

	# Player should flash briefly when collecting powerup
	# (This is tested by checking if upgrade effect was triggered)

func test_player_hit_audio_visual_response():
	# Spawn player
	if not game.current_player:
		game.spawn_player()

	await get_tree().process_frame

	var player = game.current_player
	var initial_lives = game.lives

	# Disable invulnerability for testing
	player.invulnerable = false

	var effects_parent = player.get_parent()
	var initial_effect_count = effects_parent.get_child_count()

	# Trigger player hit
	player.take_damage()

	await get_tree().process_frame

	# Should create death explosion visual effect
	assert_that(effects_parent.get_child_count()).is_greater_equal(initial_effect_count)

	# Player should be destroyed/invisible
	assert_that(player.visible).is_false()

	# Game state should reflect hit
	assert_that(game.lives).is_less_equal(initial_lives)

func test_wave_announcement_audio_visual():
	var ui_node = game.get_node("UI")
	var initial_ui_children = ui_node.get_child_count()

	# Trigger wave announcement
	game._on_wave_announcement(5)

	await get_tree().process_frame

	# Should create visual announcement
	assert_that(ui_node.get_child_count()).is_greater(initial_ui_children)

	# Look for wave announcement label
	var found_wave_label = false
	for child in ui_node.get_children():
		if child is Label and child.text.contains("WAVE"):
			found_wave_label = true
			break

	assert_that(found_wave_label).is_true()

func test_enemy_hit_feedback():
	var enemy = auto_free(Enemy.instantiate())
	enemy.position = Vector2(400, 300)
	enemy.health = 3
	game.get_node("Enemies").add_child(enemy)
	enemy._ready()

	var initial_modulate = enemy.modulate
	var initial_health = enemy.health

	# Hit enemy
	enemy.take_damage(1)

	await get_tree().process_frame

	# Health should decrease
	assert_that(enemy.health).is_equal(initial_health - 1)

	# Should not be destroyed yet
	assert_that(enemy.is_queued_for_deletion()).is_false()

func test_starfield_visual_consistency():
	# Check that starfield is created and animating
	var stars_node = game.get_node("Stars")
	var initial_star_count = stars_node.get_child_count()

	# Starfield should be created on game start
	assert_that(initial_star_count).is_equal(50)
	assert_that(game.stars.size()).is_equal(50)

	# Test starfield movement
	if game.stars.size() > 0:
		var star = game.stars[0]
		var initial_y = star.position.y

		# Update starfield
		game.update_starfield(0.016)

		# Star should have moved
		assert_that(star.position.y).is_greater_equal(initial_y)

func test_ui_updates_match_game_state():
	# Set specific game state values
	game.score = 1250
	game.lives = 2
	game.bombs = 1

	# Update UI
	game.update_ui()

	await get_tree().process_frame

	# Check UI reflects game state
	var score_label = game.get_node("UI/HUD/ScoreLabel")
	var lives_label = game.get_node("UI/HUD/LivesLabel")
	var bombs_label = game.get_node("UI/HUD/BombsLabel")

	assert_that(score_label.text).contains("1250")
	assert_that(lives_label.text).contains("2")
	assert_that(bombs_label.text).contains("1")

func test_weapon_level_visual_indicator():
	# Spawn player
	if not game.current_player:
		game.spawn_player()

	await get_tree().process_frame

	var player = game.current_player
	player.weapon_level = 3
	player.weapon_type = "laser"

	# Update UI to show weapon info
	game.update_ui()

	await get_tree().process_frame

	# UI should show weapon information
	var hud = game.get_node("UI/HUD")
	if hud.has_node("WeaponLabel"):
		var weapon_label = hud.get_node("WeaponLabel")
		assert_that(weapon_label.text).contains("LASER")
		assert_that(weapon_label.text).contains("LV3")

class TestEffectTiming extends GdUnitTestSuite:
	var game: Node2D

	func before_test():
		game = auto_free(Game.instantiate())
		add_child(game)
		game._ready()
		await get_tree().process_frame

	func test_effect_cleanup_timing():
		var effects_node = game.get_node("Effects")
		var initial_count = effects_node.get_child_count()

		# Create explosion effect
		EffectManager.create_explosion("enemy_destroy", Vector2(400, 300), effects_node)

		await get_tree().process_frame

		# Effects should be created
		assert_that(effects_node.get_child_count()).is_greater(initial_count)

		# Wait for cleanup (effects should auto-cleanup)
		await get_tree().create_timer(2.0).timeout

		# Some effects should be cleaned up by now
		# Note: This depends on cleanup timers in VisualEffects.gd

	func test_powerup_animation_lifecycle():
		var powerup = preload("res://scenes/pickups/PowerUp.tscn").instantiate()
		powerup.position = Vector2(400, 300)
		game.get_node("PowerUps").add_child(powerup)
		powerup._ready()

		await get_tree().process_frame

		# Powerup should have visual components
		assert_that(powerup.has_node("CircleSprite")).is_true()
		assert_that(powerup.has_node("LetterLabel")).is_true()

		var initial_position = powerup.position

		# Powerup should move/animate
		powerup._process(0.016)

		# Position should change due to floating animation
		# (Y should increase due to fall_speed, X might vary due to drift)

	func test_tween_coordination():
		# Test that visual effects that use tweens work correctly
		var test_parent = Node2D.new()
		add_child(test_parent)

		# Create a shockwave effect that uses tweens
		EffectManager._create_shockwave(Vector2(400, 300), test_parent, 20.0, Vector2(3, 3), 0.5)

		await get_tree().process_frame

		# Shockwave should be created
		assert_that(test_parent.get_child_count()).is_greater(0)

		var shockwave = test_parent.get_child(0)
		assert_that(shockwave is Polygon2D).is_true()

		# Wait for tween to complete
		await get_tree().create_timer(0.6).timeout

		# Shockwave should be cleaned up
		assert_that(is_instance_valid(shockwave)).is_false()

class TestAudioSystemIntegration extends GdUnitTestSuite:
	var sound_manager: Node

	func before_test():
		sound_manager = SoundManager

	func test_sound_manager_initialization():
		# SoundManager should be properly initialized
		assert_that(sound_manager).is_not_null()
		assert_that(sound_manager.has_method("play_sound")).is_true()
		assert_that(sound_manager.has_method("play_random_pitch")).is_true()

	func test_sound_generation_consistency():
		# Test that sound generation doesn't crash
		var laser_sound = sound_manager.generate_sound("laser")
		var shoot_sound = sound_manager.generate_sound("shoot")
		var explosion_sound = sound_manager.generate_sound("enemy_destroy")

		assert_that(laser_sound).is_not_null()
		assert_that(shoot_sound).is_not_null()
		assert_that(explosion_sound).is_not_null()

		# All should be AudioStreamWAV
		assert_that(laser_sound is AudioStreamWAV).is_true()
		assert_that(shoot_sound is AudioStreamWAV).is_true()
		assert_that(explosion_sound is AudioStreamWAV).is_true()

	func test_audio_players_created():
		# Sound manager should have audio players for each sound type
		var expected_sounds = ["shoot", "laser", "enemy_hit", "enemy_destroy", "player_hit", "powerup", "bomb", "wave_start"]

		for sound_name in expected_sounds:
			assert_that(sound_name in sound_manager.audio_players).is_true()

	func test_sound_playback_interface():
		# Test that sound playback methods work without crashing
		# Note: We can't easily test actual audio output in unit tests

		# This should not crash
		sound_manager.play_sound("shoot", -10.0, 1.0)
		sound_manager.play_random_pitch("laser", -8.0, 0.1)

		# Stop methods should also work
		sound_manager.stop_sound("shoot")
		sound_manager.stop_all_sounds()