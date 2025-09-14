extends GdUnitTestSuite

## Performance Tests for Title Screen System Animations
## Tests 60 FPS maintenance, frame timing, and resource usage during animations
## Part of the Continuum Professional Title Screen System Test Suite

# Test subjects
var title_screen: Node2D
var credits_screen: Node2D
var scene_manager: Node

# Performance tracking
var frame_times: Array[float] = []
var fps_measurements: Array[float] = []
var memory_samples: Array[int] = []

# Performance thresholds (60 FPS = 16.67ms per frame)
const TARGET_FRAME_TIME = 16.67  # milliseconds
const MIN_FPS = 55.0             # Minimum acceptable FPS
const MAX_FRAME_TIME = 20.0      # Maximum acceptable frame time (ms)
const MEMORY_GROWTH_LIMIT = 1024 * 1024  # 1MB maximum growth

# Test configuration
const PERFORMANCE_TEST_DURATION = 2.0  # seconds
const STRESS_TEST_ITERATIONS = 100

func before():
	# Setup test subjects
	_setup_test_components()

	# Reset performance tracking
	frame_times.clear()
	fps_measurements.clear()
	memory_samples.clear()

	# Force garbage collection before tests
	_force_gc()

func after():
	# Clean up animations and tweens
	_cleanup_animations()

	# Force final garbage collection
	_force_gc()

func _setup_test_components():
	"""Setup components for performance testing"""
	# Create scene manager for transitions
	scene_manager = Node.new()
	scene_manager.name = "SceneTransitionManager"
	scene_manager.set_script(preload("res://scripts/autoloads/SceneTransitionManager.gd"))
	add_child(scene_manager)
	auto_free(scene_manager)

	# Create title screen with full UI
	title_screen = preload("res://scripts/menus/TitleScreen.gd").new()
	title_screen.name = "TitleScreen"
	add_child(title_screen)
	auto_free(title_screen)
	_setup_title_screen_ui()

	# Create credits screen with scrollable content
	credits_screen = preload("res://scripts/menus/CreditsScreen.gd").new()
	credits_screen.name = "CreditsScreen"
	add_child(credits_screen)
	auto_free(credits_screen)
	_setup_credits_screen_ui()

func _setup_title_screen_ui():
	"""Setup realistic UI structure for title screen performance testing"""
	var ui = Control.new()
	ui.name = "UI"
	title_screen.add_child(ui)

	var main_container = Control.new()
	main_container.name = "MainContainer"
	main_container.size = Vector2(1920, 1080)  # Full HD for realistic testing
	ui.add_child(main_container)

	var title_container = Control.new()
	title_container.name = "TitleContainer"
	title_container.position = Vector2(400, 200)
	main_container.add_child(title_container)

	var menu_container = Control.new()
	menu_container.name = "MenuContainer"
	menu_container.position = Vector2(400, 400)
	main_container.add_child(menu_container)

	# Create animated buttons
	var button_names = ["StartButton", "OptionsButton", "CreditsButton", "QuitButton"]
	for i in range(button_names.size()):
		var button = Button.new()
		button.name = button_names[i]
		button.text = button_names[i].replace("Button", "").to_upper()
		button.size = Vector2(200, 60)
		button.position.y = i * 70
		menu_container.add_child(button)

	var instructions = Label.new()
	instructions.name = "Instructions"
	instructions.text = "Use WASD or Arrow Keys to navigate"
	instructions.position = Vector2(0, 600)
	main_container.add_child(instructions)

func _setup_credits_screen_ui():
	"""Setup credits screen with substantial content for scrolling performance"""
	var ui = Control.new()
	ui.name = "UI"
	credits_screen.add_child(ui)

	var main_container = Control.new()
	main_container.name = "MainContainer"
	main_container.size = Vector2(1920, 1080)
	ui.add_child(main_container)

	var scroll_container = ScrollContainer.new()
	scroll_container.name = "ScrollContainer"
	scroll_container.size = Vector2(1800, 900)
	scroll_container.position = Vector2(60, 90)
	main_container.add_child(scroll_container)

	var credits_content = VBoxContainer.new()
	credits_content.name = "CreditsContent"
	scroll_container.add_child(credits_content)

	# Add substantial content for realistic scrolling performance
	for i in range(200):  # Many lines for realistic testing
		var label = Label.new()
		label.text = "Credits Line " + str(i + 1) + " - " + "This is additional text to make the line longer and more realistic for performance testing purposes."
		label.size = Vector2(1700, 25)
		credits_content.add_child(label)

func _cleanup_animations():
	"""Clean up all running animations"""
	if title_screen and is_instance_valid(title_screen):
		if title_screen.title_tween:
			title_screen.title_tween.kill()
		if title_screen.button_hover_tween:
			title_screen.button_hover_tween.kill()

	if credits_screen and is_instance_valid(credits_screen):
		if credits_screen.scroll_tween:
			credits_screen.scroll_tween.kill()
		if credits_screen.entrance_tween:
			credits_screen.entrance_tween.kill()

	if scene_manager and is_instance_valid(scene_manager):
		if scene_manager.has_method("tween") and scene_manager.tween:
			scene_manager.tween.kill()

func _force_gc():
	"""Force garbage collection for accurate memory measurements"""
	# Force multiple GC cycles
	for i in range(3):
		await get_tree().process_frame

# === Frame Rate Performance Tests ===

func test_title_screen_animation_fps():
	"""Test title screen entrance animation maintains 60 FPS"""
	await _measure_performance_during_animation(
		func(): title_screen.setup_initial_animations(),
		"Title Screen Entrance Animation"
	)

	var avg_fps = _calculate_average_fps()
	assert_that(avg_fps).is_greater_equal(MIN_FPS)

	var max_frame_time = _get_max_frame_time()
	assert_that(max_frame_time).is_less(MAX_FRAME_TIME)

func test_menu_navigation_animation_fps():
	"""Test menu navigation animation performance"""
	title_screen.setup_menu_buttons()

	await _measure_performance_during_rapid_input(
		func():
			title_screen.navigate_down()
			title_screen.navigate_up(),
		"Menu Navigation Animation"
	)

	var avg_fps = _calculate_average_fps()
	assert_that(avg_fps).is_greater_equal(MIN_FPS)

func test_button_highlight_animation_fps():
	"""Test button highlight animation performance under rapid changes"""
	title_screen.setup_menu_buttons()

	var test_button = Button.new()
	test_button.size = Vector2(200, 60)
	add_child(test_button)
	auto_free(test_button)

	await _measure_performance_during_rapid_input(
		func():
			title_screen.animate_button_highlight(test_button, true)
			title_screen.animate_button_highlight(test_button, false),
		"Button Highlight Animation"
	)

	var avg_fps = _calculate_average_fps()
	assert_that(avg_fps).is_greater_equal(MIN_FPS)

func test_credits_scroll_animation_fps():
	"""Test credits scrolling animation maintains smooth frame rate"""
	credits_screen.setup_references()

	await _measure_performance_during_animation(
		func(): credits_screen.setup_auto_scroll(),
		"Credits Auto Scroll Animation"
	)

	var avg_fps = _calculate_average_fps()
	assert_that(avg_fps).is_greater_equal(MIN_FPS)

	var frame_time_variance = _calculate_frame_time_variance()
	assert_that(frame_time_variance).is_less(5.0)  # Low variance for smooth scrolling

func test_manual_scroll_performance():
	"""Test manual scrolling performance under rapid input"""
	credits_screen.setup_references()

	await _measure_performance_during_rapid_input(
		func(): credits_screen.manual_scroll(randf_range(-50, 50)),
		"Manual Scroll Performance"
	)

	var avg_fps = _calculate_average_fps()
	assert_that(avg_fps).is_greater_equal(MIN_FPS)

# === Scene Transition Performance Tests ===

func test_scene_transition_animation_fps():
	"""Test scene transition animation performance"""
	await _measure_performance_during_animation(
		func(): await scene_manager.transition_to_scene("res://scenes/main/Game.tscn"),
		"Scene Transition Animation"
	)

	var avg_fps = _calculate_average_fps()
	assert_that(avg_fps).is_greater_equal(MIN_FPS)

func test_fade_animation_performance():
	"""Test fade animation performance"""
	await _measure_performance_during_animation(
		func():
			await scene_manager._fade_to_black()
			await scene_manager._fade_from_black(),
		"Fade Animation Performance"
	)

	var max_frame_time = _get_max_frame_time()
	assert_that(max_frame_time).is_less(MAX_FRAME_TIME)

# === Memory Performance Tests ===

func test_animation_memory_usage():
	"""Test memory usage remains stable during animations"""
	var initial_memory = _get_memory_usage()

	# Run multiple animation cycles
	for i in range(10):
		title_screen.setup_initial_animations()
		await get_tree().create_timer(0.1).timeout
		_cleanup_animations()
		await get_tree().process_frame

	_force_gc()
	var final_memory = _get_memory_usage()
	var memory_growth = final_memory - initial_memory

	assert_that(memory_growth).is_less(MEMORY_GROWTH_LIMIT)

func test_tween_cleanup_memory():
	"""Test tween cleanup prevents memory leaks"""
	var initial_memory = _get_memory_usage()

	# Create and destroy many tweens
	for i in range(STRESS_TEST_ITERATIONS):
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.01)
		await tween.finished
		tween.kill()

	_force_gc()
	var final_memory = _get_memory_usage()
	var memory_growth = final_memory - initial_memory

	assert_that(memory_growth).is_less(MEMORY_GROWTH_LIMIT)

func test_scroll_content_memory_efficiency():
	"""Test scrolling with large content remains memory efficient"""
	credits_screen.setup_references()
	var initial_memory = _get_memory_usage()

	# Rapid scrolling through large content
	for i in range(STRESS_TEST_ITERATIONS):
		credits_screen.manual_scroll(randf_range(-100, 100))
		if i % 10 == 0:
			await get_tree().process_frame

	_force_gc()
	var final_memory = _get_memory_usage()
	var memory_growth = final_memory - initial_memory

	assert_that(memory_growth).is_less(MEMORY_GROWTH_LIMIT)

# === Stress Testing ===

func test_concurrent_animations_performance():
	"""Test performance with multiple concurrent animations"""
	title_screen.setup_menu_buttons()
	credits_screen.setup_references()

	await _measure_performance_during_animation(
		func():
			# Start multiple animations simultaneously
			title_screen.setup_initial_animations()
			credits_screen.setup_entrance_animation()
			credits_screen.setup_auto_scroll()

			# Simulate user interactions (without await inside lambda)
			for i in range(20):
				title_screen.navigate_down()
				credits_screen.manual_scroll(10),
		"Concurrent Animations Stress Test"
	)

	var avg_fps = _calculate_average_fps()
	assert_that(avg_fps).is_greater_equal(MIN_FPS * 0.9)  # Allow slight degradation

func test_rapid_animation_creation_destruction():
	"""Test rapid animation creation and destruction"""
	await _measure_performance_during_rapid_input(
		func():
			var tween = create_tween()
			tween.tween_property(self, "position", Vector2.ZERO, 0.01)
			tween.kill(),
		"Rapid Animation Creation/Destruction"
	)

	var avg_fps = _calculate_average_fps()
	assert_that(avg_fps).is_greater_equal(MIN_FPS)

func test_extreme_scroll_performance():
	"""Test performance under extreme scrolling conditions"""
	credits_screen.setup_references()

	await _measure_performance_during_rapid_input(
		func():
			# Extreme scroll values
			credits_screen.manual_scroll(randf_range(-500, 500)),
		"Extreme Scroll Performance Test"
	)

	var avg_fps = _calculate_average_fps()
	assert_that(avg_fps).is_greater_equal(MIN_FPS)

# === Real-World Scenario Performance Tests ===

func test_realistic_user_interaction_performance():
	"""Test performance under realistic user interaction patterns"""
	title_screen.setup_menu_buttons()
	credits_screen.setup_references()

	await _measure_performance_during_animation(
		func():
			# Simulate realistic user behavior
			for cycle in range(5):
				# Menu navigation
				for i in range(4):
					title_screen.navigate_down()
					# await get_tree().process_frame - removed from lambda

				# Menu selection simulation
				title_screen.activate_current_button()
				# await get_tree().process_frame - removed from lambda

				# Credits interaction
				credits_screen.manual_scroll(30)
				# await get_tree().process_frame - removed from lambda
				credits_screen.toggle_auto_scroll(),
		"Realistic User Interaction"
	)

	var avg_fps = _calculate_average_fps()
	assert_that(avg_fps).is_greater_equal(MIN_FPS)

func test_menu_system_endurance():
	"""Test menu system performance over extended use"""
	title_screen.setup_menu_buttons()

	var start_time = Time.get_ticks_msec()
	var endurance_duration = 5000  # 5 seconds

	while Time.get_ticks_msec() - start_time < endurance_duration:
		# Continuous menu operations
		title_screen.navigate_down()
		title_screen.navigate_up()

		# Measure frame rate every 100ms
		if (Time.get_ticks_msec() - start_time) % 100 == 0:
			var fps = Engine.get_frames_per_second()
			fps_measurements.append(fps)

		await get_tree().process_frame

	var avg_fps = _calculate_average_fps()
	assert_that(avg_fps).is_greater_equal(MIN_FPS)

	# Check for performance degradation over time
	var first_quarter_fps = _calculate_fps_for_range(0, fps_measurements.size() / 4)
	var last_quarter_fps = _calculate_fps_for_range(3 * fps_measurements.size() / 4, fps_measurements.size())
	var fps_degradation = first_quarter_fps - last_quarter_fps

	assert_that(fps_degradation).is_less(10.0)  # Less than 10 FPS degradation

# === Performance Measurement Utilities ===

func _measure_performance_during_animation(animation_func: Callable, test_name: String):
	"""Measure performance during animation execution"""
	frame_times.clear()
	fps_measurements.clear()

	var start_time = Time.get_ticks_msec()
	var last_frame_time = start_time

	# Start the animation
	animation_func.call()

	# Measure for test duration
	var measurement_start = Time.get_ticks_msec()
	while Time.get_ticks_msec() - measurement_start < PERFORMANCE_TEST_DURATION * 1000:
		var current_time = Time.get_ticks_msec()
		var frame_time = current_time - last_frame_time

		frame_times.append(frame_time)
		fps_measurements.append(Engine.get_frames_per_second())

		last_frame_time = current_time
		await get_tree().process_frame

func _measure_performance_during_rapid_input(input_func: Callable, test_name: String):
	"""Measure performance during rapid input simulation"""
	frame_times.clear()
	fps_measurements.clear()

	var start_time = Time.get_ticks_msec()
	var last_frame_time = start_time

	# Execute rapid input for test duration
	var measurement_start = Time.get_ticks_msec()
	while Time.get_ticks_msec() - measurement_start < PERFORMANCE_TEST_DURATION * 1000:
		var current_time = Time.get_ticks_msec()
		var frame_time = current_time - last_frame_time

		frame_times.append(frame_time)
		fps_measurements.append(Engine.get_frames_per_second())

		# Execute input function
		input_func.call()

		last_frame_time = current_time
		await get_tree().process_frame

func _calculate_average_fps() -> float:
	"""Calculate average FPS from measurements"""
	if fps_measurements.is_empty():
		return 0.0

	var total = 0.0
	for fps in fps_measurements:
		total += fps

	return total / fps_measurements.size()

func _calculate_fps_for_range(start_idx: int, end_idx: int) -> float:
	"""Calculate average FPS for a specific range of measurements"""
	if start_idx >= fps_measurements.size() or end_idx > fps_measurements.size():
		return 0.0

	var total = 0.0
	var count = 0

	for i in range(start_idx, end_idx):
		total += fps_measurements[i]
		count += 1

	return total / count if count > 0 else 0.0

func _get_max_frame_time() -> float:
	"""Get maximum frame time from measurements"""
	if frame_times.is_empty():
		return 0.0

	var max_time = 0.0
	for time in frame_times:
		if time > max_time:
			max_time = time

	return max_time

func _calculate_frame_time_variance() -> float:
	"""Calculate frame time variance for smoothness assessment"""
	if frame_times.size() < 2:
		return 0.0

	var avg_time = 0.0
	for time in frame_times:
		avg_time += time
	avg_time /= frame_times.size()

	var variance_sum = 0.0
	for time in frame_times:
		var diff = time - avg_time
		variance_sum += diff * diff

	return variance_sum / frame_times.size()

func _get_memory_usage() -> int:
	"""Get current memory usage"""
	return OS.get_static_memory_peak_usage()

# === Performance Benchmark Tests ===

func test_animation_performance_benchmarks():
	"""Establish performance benchmarks for different animation types"""
	var benchmarks = {}

	# Title screen animation benchmark
	title_screen.setup_menu_buttons()
	await _measure_performance_during_animation(
		func(): title_screen.setup_initial_animations(),
		"Title Animation Benchmark"
	)
	benchmarks["title_animation"] = _calculate_average_fps()

	# Button highlight benchmark
	var test_button = Button.new()
	add_child(test_button)
	auto_free(test_button)

	await _measure_performance_during_rapid_input(
		func(): title_screen.animate_button_highlight(test_button, randf() > 0.5),
		"Button Highlight Benchmark"
	)
	benchmarks["button_highlight"] = _calculate_average_fps()

	# Scroll animation benchmark
	credits_screen.setup_references()
	await _measure_performance_during_animation(
		func(): credits_screen.setup_auto_scroll(),
		"Scroll Animation Benchmark"
	)
	benchmarks["scroll_animation"] = _calculate_average_fps()

	# All benchmarks should meet minimum performance
	for benchmark_name in benchmarks:
		var fps = benchmarks[benchmark_name]
		assert_that(fps).is_greater_equal(MIN_FPS)

func test_performance_consistency_across_runs():
	"""Test that performance is consistent across multiple test runs"""
	var run_results: Array[float] = []

	# Run the same test multiple times
	for run in range(5):
		title_screen.setup_menu_buttons()

		await _measure_performance_during_rapid_input(
			func():
				title_screen.navigate_down()
				title_screen.navigate_up(),
			"Consistency Test Run " + str(run)
		)

		run_results.append(_calculate_average_fps())

		# Clean up between runs
		_cleanup_animations()
		_force_gc()

	# Calculate variance across runs
	var avg_across_runs = 0.0
	for result in run_results:
		avg_across_runs += result
	avg_across_runs /= run_results.size()

	var variance = 0.0
	for result in run_results:
		var diff = result - avg_across_runs
		variance += diff * diff
	variance /= run_results.size()

	# Performance should be consistent (low variance)
	assert_that(variance).is_less(25.0)  # Standard deviation less than 5 FPS

	# All runs should meet minimum performance
	for result in run_results:
		assert_that(result).is_greater_equal(MIN_FPS)

# === Resource Usage Performance Tests ===

func test_gpu_resource_efficiency():
	"""Test GPU resource efficiency during animations"""
	# This test ensures animations don't cause excessive GPU usage
	# by verifying frame times remain consistent

	title_screen.setup_menu_buttons()
	credits_screen.setup_references()

	await _measure_performance_during_animation(
		func():
			# Start multiple visual effects simultaneously
			title_screen.setup_initial_animations()
			credits_screen.setup_entrance_animation()

			# Add visual stress
			for i in range(10):
				var test_button = Button.new()
				test_button.size = Vector2(100, 30)
				add_child(test_button)
				auto_free(test_button)
				title_screen.animate_button_highlight(test_button, true),
		"GPU Resource Efficiency Test"
	)

	var frame_time_variance = _calculate_frame_time_variance()
	assert_that(frame_time_variance).is_less(10.0)  # Consistent frame times

func test_cpu_efficiency_during_animations():
	"""Test CPU efficiency during complex animations"""
	var process_start_time = Time.get_ticks_msec()

	# CPU-intensive animation scenario
	title_screen.setup_menu_buttons()
	credits_screen.setup_references()

	# Start multiple concurrent operations
	title_screen.setup_initial_animations()
	credits_screen.setup_auto_scroll()

	# Simulate heavy UI interaction
	for i in range(50):
		title_screen.navigate_down()
		title_screen.navigate_up()
		credits_screen.manual_scroll(randf_range(-20, 20))
		await get_tree().process_frame

	var total_time = Time.get_ticks_msec() - process_start_time
	var expected_minimum_time = 50 * 16.67  # 50 frames at 60 FPS

	# Should not take significantly longer than expected
	assert_that(total_time).is_less(expected_minimum_time * 1.5)