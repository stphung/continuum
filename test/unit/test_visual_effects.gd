extends GdUnitTestSuite

var visual_effects: Node
var test_parent: Node

func before_test():
	visual_effects = EffectManager
	test_parent = Node2D.new()
	add_child(test_parent)

func after_test():
	if test_parent:
		test_parent.queue_free()
		test_parent = null
	# Wait for any cleanup timers to complete
	await get_tree().process_frame

func test_effect_manager_exists():
	assert_that(visual_effects).is_not_null()
	assert_that(visual_effects.has_method("create_explosion")).is_true()

func test_enemy_explosion_creation():
	var initial_child_count = test_parent.get_child_count()

	visual_effects.create_explosion("enemy_destroy", Vector2(400, 300), test_parent)

	# Should create multiple particle systems and effects
	assert_that(test_parent.get_child_count()).is_greater(initial_child_count)

func test_player_explosion_creation():
	var initial_child_count = test_parent.get_child_count()

	visual_effects.create_explosion("player_death", Vector2(400, 300), test_parent)

	assert_that(test_parent.get_child_count()).is_greater(initial_child_count)

func test_bomb_explosion_creation():
	var initial_child_count = test_parent.get_child_count()

	visual_effects.create_explosion("bomb", Vector2(400, 300), test_parent)

	# Bomb explosion should create the most effects (particles + shockwaves + flash)
	assert_that(test_parent.get_child_count()).is_greater(initial_child_count + 5)

func test_unknown_explosion_type():
	var initial_child_count = test_parent.get_child_count()

	visual_effects.create_explosion("unknown_type", Vector2(400, 300), test_parent)

	# Should not crash and should not create effects
	assert_that(test_parent.get_child_count()).is_equal(initial_child_count)

func test_particle_system_creation():
	var config = {
		"amount": 50,
		"lifetime": 1.5,
		"velocity_min": 100,
		"velocity_max": 300,
		"scale_min": 0.5,
		"scale_max": 2.0,
		"color": Color.RED
	}

	var particles = visual_effects._create_particle_system(Vector2(400, 300), config)
	add_child(particles)  # Add to scene tree for proper cleanup

	assert_that(particles).is_not_null()
	assert_that(particles is CPUParticles2D).is_true()
	assert_that(particles.amount).is_equal(50)
	assert_that(particles.lifetime).is_equal(1.5)
	assert_that(particles.initial_velocity_min).is_equal(100.0)
	assert_that(particles.initial_velocity_max).is_equal(300.0)
	assert_that(particles.scale_amount_min).is_equal(0.5)
	assert_that(particles.scale_amount_max).is_equal(2.0)
	assert_that(particles.color).is_equal(Color.RED)
	assert_that(particles.emitting).is_true()
	assert_that(particles.one_shot).is_true()

func test_particle_system_default_config():
	var particles = visual_effects._create_particle_system(Vector2(100, 200), {})
	add_child(particles)  # Add to scene tree for proper cleanup

	assert_that(particles.amount).is_equal(30)
	assert_that(particles.lifetime).is_equal(1.0)
	assert_that(particles.initial_velocity_min).is_equal(50.0)
	assert_that(particles.initial_velocity_max).is_equal(200.0)
	assert_that(particles.scale_amount_min).is_equal(0.5)
	assert_that(particles.scale_amount_max).is_equal(2.0)
	assert_that(particles.color).is_equal(Color.WHITE)

func test_particle_system_angular_velocity():
	var config = {
		"angular_velocity_min": -180,
		"angular_velocity_max": 180
	}

	var particles = visual_effects._create_particle_system(Vector2(0, 0), config)
	add_child(particles)  # Add to scene tree for proper cleanup

	assert_that(particles.angular_velocity_min).is_equal(-180.0)
	assert_that(particles.angular_velocity_max).is_equal(180.0)

func test_particle_system_gravity():
	var config = {
		"gravity": Vector2(0, 100)
	}

	var particles = visual_effects._create_particle_system(Vector2(0, 0), config)
	add_child(particles)  # Add to scene tree for proper cleanup

	assert_that(particles.gravity).is_equal(Vector2(0, 100))

func test_shockwave_creation():
	var initial_child_count = test_parent.get_child_count()

	visual_effects._create_shockwave(Vector2(400, 300), test_parent, 20.0, Vector2(2, 2), 0.5)

	assert_that(test_parent.get_child_count()).is_equal(initial_child_count + 1)

	var shockwave = test_parent.get_child(test_parent.get_child_count() - 1)
	assert_that(shockwave is Polygon2D).is_true()
	assert_that(shockwave.position).is_equal(Vector2(400, 300))

func test_shockwave_ring_creation():
	var shockwave_ring = visual_effects._create_shockwave_ring(Vector2(200, 400), 2)
	add_child(shockwave_ring)  # Add to scene tree for proper cleanup

	assert_that(shockwave_ring is Polygon2D).is_true()
	assert_that(shockwave_ring.position).is_equal(Vector2(200, 400))
	assert_that(shockwave_ring.polygon.size()).is_equal(20)

func test_screen_flash_creation():
	var initial_child_count = test_parent.get_child_count()

	visual_effects._create_screen_flash_sequence(test_parent)

	# Should create main flash + pulse flashes
	assert_that(test_parent.get_child_count()).is_greater(initial_child_count + 3)

	# Check that at least one flash is created
	var found_flash = false
	for child in test_parent.get_children():
		if child is ColorRect:
			found_flash = true
			break
	assert_that(found_flash).is_true()

func test_cleanup_scheduling():
	# Create some mock particles
	var mock_particles = [Node2D.new(), Node2D.new()]
	for particle in mock_particles:
		test_parent.add_child(particle)

	var initial_child_count = test_parent.get_child_count()

	# Schedule cleanup with very short delay for testing
	visual_effects._schedule_cleanup(mock_particles, test_parent, 0.1)

	# Timer should be added
	assert_that(test_parent.get_child_count()).is_equal(initial_child_count + 1)

	# Wait for cleanup to occur
	await get_tree().create_timer(0.15).timeout

	# Particles should be cleaned up, timer should be gone
	for particle in mock_particles:
		assert_that(is_instance_valid(particle)).is_false()

func test_enemy_explosion_components():
	visual_effects._create_enemy_explosion(Vector2(300, 400), test_parent)

	await get_tree().process_frame

	# Should create explosion particles, core particles, outer burst, and shockwave
	var particle_count = 0
	var polygon_count = 0
	var timer_count = 0

	for child in test_parent.get_children():
		if child is CPUParticles2D:
			particle_count += 1
		elif child is Polygon2D:
			polygon_count += 1
		elif child is Timer:
			timer_count += 1

	assert_that(particle_count).is_equal(3)  # explosion + core + outer_burst
	assert_that(polygon_count).is_equal(1)   # shockwave
	assert_that(timer_count).is_equal(1)     # cleanup timer

func test_player_explosion_components():
	visual_effects._create_player_explosion(Vector2(300, 400), test_parent)

	await get_tree().process_frame

	var particle_count = 0
	var timer_count = 0

	for child in test_parent.get_children():
		if child is CPUParticles2D:
			particle_count += 1
		elif child is Timer:
			timer_count += 1

	assert_that(particle_count).is_equal(2)  # explosion + core_explosion
	assert_that(timer_count).is_equal(1)     # cleanup timer

func test_bomb_explosion_components():
	visual_effects._create_bomb_explosion(Vector2(300, 400), test_parent)

	await get_tree().process_frame

	var particle_count = 0
	var polygon_count = 0
	var color_rect_count = 0
	var timer_count = 0

	for child in test_parent.get_children():
		if child is CPUParticles2D:
			particle_count += 1
		elif child is Polygon2D:
			polygon_count += 1
		elif child is ColorRect:
			color_rect_count += 1
		elif child is Timer:
			timer_count += 1

	assert_that(particle_count).is_equal(1)   # mega_explosion
	assert_that(polygon_count).is_equal(5)    # 5 shockwave rings
	assert_that(color_rect_count).is_greater_equal(1)  # screen flash effects
	assert_that(timer_count).is_greater_equal(1)  # cleanup timer + ring/pulse timers

func test_explosion_positioning():
	var test_position = Vector2(123, 456)

	visual_effects.create_explosion("enemy_destroy", test_position, test_parent)

	await get_tree().process_frame

	# Check that at least one particle system is positioned correctly
	var found_correct_position = false
	for child in test_parent.get_children():
		if child is CPUParticles2D and child.position == test_position:
			found_correct_position = true
			break

	assert_that(found_correct_position).is_true()

func test_different_explosion_intensities():
	# Test that different explosion types create different numbers of effects
	var enemy_parent = Node2D.new()
	var player_parent = Node2D.new()
	var bomb_parent = Node2D.new()

	add_child(enemy_parent)
	add_child(player_parent)
	add_child(bomb_parent)
	auto_free(enemy_parent)
	auto_free(player_parent)
	auto_free(bomb_parent)

	visual_effects._create_enemy_explosion(Vector2.ZERO, enemy_parent)
	visual_effects._create_player_explosion(Vector2.ZERO, player_parent)
	visual_effects._create_bomb_explosion(Vector2.ZERO, bomb_parent)

	await get_tree().process_frame

	# Bomb should create the most effects
	assert_that(bomb_parent.get_child_count()).is_greater(player_parent.get_child_count())
	assert_that(bomb_parent.get_child_count()).is_greater(enemy_parent.get_child_count())

func test_particle_emission_state():
	var config = {"amount": 25, "lifetime": 0.8}
	var particles = visual_effects._create_particle_system(Vector2.ZERO, config)
	add_child(particles)  # Add to scene tree for proper cleanup

	# Particles should be emitting and one-shot
	assert_that(particles.emitting).is_true()
	assert_that(particles.one_shot).is_true()

func test_shockwave_polygon_points():
	var shockwave_ring = visual_effects._create_shockwave_ring(Vector2.ZERO, 0)
	add_child(shockwave_ring)  # Add to scene tree for proper cleanup

	# Should create a 20-point polygon for circular shockwave
	assert_that(shockwave_ring.polygon.size()).is_equal(20)

	# All points should form a circle around the origin
	for point in shockwave_ring.polygon:
		var distance = point.length()
		assert_that(distance).is_between(29.0, 31.0)  # radius of 30 with small tolerance

func test_cleanup_timer_configuration():
	var mock_particles = [Node2D.new()]
	test_parent.add_child(mock_particles[0])

	visual_effects._schedule_cleanup(mock_particles, test_parent, 1.5)

	# Find the timer
	var cleanup_timer = null
	for child in test_parent.get_children():
		if child is Timer:
			cleanup_timer = child
			break

	assert_that(cleanup_timer).is_not_null()
	assert_that(cleanup_timer.wait_time).is_equal(1.5)
	assert_that(cleanup_timer.one_shot).is_true()

class TestVisualEffectsIntegration extends GdUnitTestSuite:
	var game_node: Node2D
	var effects_node: Node2D

	func before_test():
		game_node = Node2D.new()
		effects_node = Node2D.new()
		effects_node.name = "Effects"
		game_node.add_child(effects_node)
		add_child(game_node)

	func test_game_integration_enemy_destroy():
		# Simulate game calling effect creation
		EffectManager.create_explosion("enemy_destroy", Vector2(300, 200), effects_node)

		await get_tree().process_frame

		assert_that(effects_node.get_child_count()).is_greater(0)

	func test_game_integration_player_death():
		EffectManager.create_explosion("player_death", Vector2(400, 600), effects_node)

		await get_tree().process_frame

		assert_that(effects_node.get_child_count()).is_greater(0)

	func test_game_integration_bomb():
		EffectManager.create_explosion("bomb", Vector2(400, 450), effects_node)

		await get_tree().process_frame

		assert_that(effects_node.get_child_count()).is_greater(0)

	func test_multiple_simultaneous_explosions():
		# Test that multiple explosions can be created simultaneously
		EffectManager.create_explosion("enemy_destroy", Vector2(200, 300), effects_node)
		EffectManager.create_explosion("enemy_destroy", Vector2(600, 300), effects_node)
		EffectManager.create_explosion("player_death", Vector2(400, 500), effects_node)

		await get_tree().process_frame

		# Should have created many effect nodes
		assert_that(effects_node.get_child_count()).is_greater(10)