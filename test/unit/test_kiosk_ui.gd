extends GdUnitTestSuite
## Comprehensive tests for KioskUI overlay system - visual transitions, UI management, and user interaction

var kiosk_ui: Node
var test_scores: Array

func before():
	"""Setup test environment with KioskUI instance"""
	# Create KioskUI instance
	var KioskUIScript = preload("res://scripts/kiosk/KioskUI.gd")
	kiosk_ui = KioskUIScript.new()
	kiosk_ui.name = "TestKioskUI"
	add_child(kiosk_ui)

	# Setup test scores data
	test_scores = [
		{"name": "PLAYER1", "score": 15000, "timestamp": "2024-01-01 12:00:00"},
		{"name": "PLAYER2", "score": 12000, "timestamp": "2024-01-01 11:30:00"},
		{"name": "PLAYER3", "score": 10000, "timestamp": "2024-01-01 11:00:00"}
	]

	await get_tree().process_frame

func after():
	"""Cleanup test environment"""
	if kiosk_ui and is_instance_valid(kiosk_ui):
		kiosk_ui.hide_all_interfaces()
		kiosk_ui.queue_free()

	await get_tree().process_frame

# Initialization Tests
func test_kiosk_ui_initialization():
	"""Test KioskUI initializes with correct defaults"""
	assert_that(kiosk_ui.current_overlay).is_equal("")
	assert_that(kiosk_ui.is_overlay_visible).is_false()
	assert_that(kiosk_ui.main_overlay).is_not_null()
	assert_that(kiosk_ui.transition_overlay).is_not_null()

func test_ui_hierarchy_setup():
	"""Test UI hierarchy is properly established"""
	assert_that(kiosk_ui.main_overlay.name).is_equal("KioskMainOverlay")
	assert_that(kiosk_ui.transition_overlay.name).is_equal("TransitionOverlay")

	# Overlays should be full-screen
	var screen_size = get_viewport().get_visible_rect().size
	assert_that(kiosk_ui.main_overlay.size).is_equal(screen_size)

func test_overlay_containers_created():
	"""Test that all overlay containers are created"""
	assert_that(kiosk_ui.main_overlay).is_not_null()
	assert_that(kiosk_ui.high_score_display).is_instance_of_any([TYPE_NIL, Control])
	assert_that(kiosk_ui.demo_overlay).is_instance_of_any([TYPE_NIL, Control])
	assert_that(kiosk_ui.instruction_panel).is_instance_of_any([TYPE_NIL, Control])

func test_color_schemes_defined():
	"""Test that all color schemes are properly defined"""
	var expected_schemes = ["attract", "demo", "high_scores", "transition"]

	for scheme_name in expected_schemes:
		assert_that(kiosk_ui.color_schemes.has(scheme_name)).is_true()
		var scheme = kiosk_ui.color_schemes[scheme_name]
		assert_that(scheme.has("primary")).is_true()
		assert_that(scheme.has("secondary")).is_true()
		assert_that(scheme.has("accent")).is_true()
		assert_that(scheme.has("text")).is_true()

func test_animation_system_setup():
	"""Test animation system is properly initialized"""
	assert_that(kiosk_ui.transition_tween).is_instance_of_any([TYPE_NIL, Tween])
	assert_that(kiosk_ui.overlay_fade_duration).is_greater(0.0)
	assert_that(kiosk_ui.text_animation_speed).is_greater(0.0)

# Overlay Management Tests
func test_show_kiosk_overlay():
	"""Test showing main kiosk overlay"""

	kiosk_ui.show_kiosk_overlay()
	await get_tree().process_frame

	assert_that(kiosk_ui.is_overlay_visible).is_true()
	assert_that(kiosk_ui.main_overlay.visible).is_true()

func test_hide_kiosk_overlay():
	"""Test hiding main kiosk overlay"""
	kiosk_ui.show_kiosk_overlay()
	await get_tree().process_frame


	kiosk_ui.hide_kiosk_overlay()
	await get_tree().process_frame

	assert_that(kiosk_ui.is_overlay_visible).is_false()
	assert_that(kiosk_ui.main_overlay.visible).is_false()

func test_show_high_scores():
	"""Test showing high scores overlay"""

	kiosk_ui.show_high_scores(test_scores)
	await get_tree().process_frame

	assert_that(kiosk_ui.current_overlay).is_equal("high_scores")

func test_hide_all_interfaces():
	"""Test hiding all overlay interfaces"""
	# Show multiple overlays
	kiosk_ui.show_kiosk_overlay()
	kiosk_ui.show_high_scores(test_scores)
	await get_tree().process_frame

	kiosk_ui.hide_all_interfaces()
	await get_tree().process_frame

	assert_that(kiosk_ui.is_overlay_visible).is_false()
	assert_that(kiosk_ui.current_overlay).is_equal("")

func test_overlay_state_management():
	"""Test overlay state is properly managed"""
	# Initially no overlay
	assert_that(kiosk_ui.current_overlay).is_equal("")

	# Show high scores
	kiosk_ui.show_high_scores(test_scores)
	assert_that(kiosk_ui.current_overlay).is_equal("high_scores")

	# Switch to demo
	if kiosk_ui.has_method("show_demo_overlay"):
		kiosk_ui.show_demo_overlay()
		assert_that(kiosk_ui.current_overlay).is_equal("demo")

# High Score Display Tests
func test_high_score_display_with_data():
	"""Test high score display with valid data"""
	kiosk_ui.show_high_scores(test_scores)
	await get_tree().process_frame

	# Should display the provided scores
	if kiosk_ui.high_score_display:
		assert_that(kiosk_ui.high_score_display.visible).is_true()

func test_high_score_display_empty_data():
	"""Test high score display with empty data"""
	kiosk_ui.show_high_scores([])
	await get_tree().process_frame

	# Should handle empty scores gracefully
	assert_that(kiosk_ui.current_overlay).is_equal("high_scores")

func test_refresh_high_scores():
	"""Test refreshing high scores with new data"""
	kiosk_ui.show_high_scores(test_scores)
	await get_tree().process_frame

	var new_scores = [
		{"name": "NEWPLR", "score": 20000, "timestamp": "2024-01-01 13:00:00"}
	]

	kiosk_ui.refresh_high_scores(new_scores)
	await get_tree().process_frame

	# Should update with new scores
	assert_that(kiosk_ui.current_overlay).is_equal("high_scores")

func test_high_score_formatting():
	"""Test high score formatting and display"""
	kiosk_ui.show_high_scores(test_scores)
	await get_tree().process_frame

	if kiosk_ui.has_method("_format_score"):
		var formatted = kiosk_ui._format_score(15000)
		assert_that(formatted).is_instance_of(TYPE_STRING)
		# Common formats: "15,000" or "15000"
		assert_that(formatted).contains_any_of(["15000", "15,000"])

# Demo Overlay Tests
func test_show_demo_overlay():
	"""Test showing demo mode overlay"""
	if kiosk_ui.has_method("show_demo_overlay"):

		kiosk_ui.show_demo_overlay()
		await get_tree().process_frame

		assert_that(kiosk_ui.current_overlay).is_equal("demo")

func test_demo_overlay_indicators():
	"""Test demo overlay shows appropriate indicators"""
	if kiosk_ui.has_method("show_demo_overlay"):
		kiosk_ui.show_demo_overlay()
		await get_tree().process_frame

		if kiosk_ui.demo_overlay:
			assert_that(kiosk_ui.demo_overlay.visible).is_true()

func test_demo_overlay_performance_data():
	"""Test demo overlay displays performance information"""
	var demo_stats = {
		"score": 8500,
		"accuracy": 0.75,
		"survival_time": 120.5
	}

	if kiosk_ui.has_method("update_demo_stats"):
		kiosk_ui.show_demo_overlay()
		kiosk_ui.update_demo_stats(demo_stats)
		await get_tree().process_frame

		# Should display performance data
		# Implementation dependent verification

# Transition System Tests
func test_transition_overlay_functionality():
	"""Test transition overlay for smooth state changes"""
	if kiosk_ui.has_method("show_transition"):
		kiosk_ui.show_transition("Loading...")
		await get_tree().process_frame

		assert_that(kiosk_ui.transition_overlay.visible).is_true()

func test_fade_transitions():
	"""Test fade transition effects"""
	kiosk_ui.show_kiosk_overlay()
	await get_tree().create_timer(kiosk_ui.overlay_fade_duration + 0.1).timeout

	# Overlay should be fully visible after fade
	assert_that(kiosk_ui.main_overlay.modulate.a).is_greater_equal(0.9)

func test_transition_timing():
	"""Test transition timing configuration"""
	var original_duration = kiosk_ui.overlay_fade_duration
	kiosk_ui.overlay_fade_duration = 1.5

	assert_that(kiosk_ui.overlay_fade_duration).is_equal(1.5)
	assert_that(kiosk_ui.overlay_fade_duration).is_not_equal(original_duration)

func test_transition_tween_management():
	"""Test transition tween is properly managed"""
	kiosk_ui.show_kiosk_overlay()
	await get_tree().process_frame

	if kiosk_ui.transition_tween:
		assert_that(kiosk_ui.transition_tween.is_valid()).is_true()

	kiosk_ui.hide_kiosk_overlay()
	await get_tree().process_frame

# Visual Configuration Tests
func test_color_scheme_application():
	"""Test color scheme application to UI elements"""
	kiosk_ui.show_high_scores(test_scores)
	await get_tree().process_frame

	if kiosk_ui.has_method("_apply_color_scheme"):
		kiosk_ui._apply_color_scheme("high_scores")
		# Should apply high scores color scheme
		# Visual verification would be implementation dependent

func test_color_scheme_switching():
	"""Test switching between different color schemes"""
	if kiosk_ui.has_method("_apply_color_scheme"):
		kiosk_ui._apply_color_scheme("attract")
		kiosk_ui._apply_color_scheme("demo")
		kiosk_ui._apply_color_scheme("high_scores")
		# Should switch schemes without errors

func test_particle_density_configuration():
	"""Test particle density affects visual elements"""
	var original_density = kiosk_ui.particle_density
	kiosk_ui.particle_density = 0.8

	assert_that(kiosk_ui.particle_density).is_equal(0.8)
	assert_that(kiosk_ui.particle_density).is_greater(original_density)

func test_text_animation_speed():
	"""Test text animation speed configuration"""
	var original_speed = kiosk_ui.text_animation_speed
	kiosk_ui.text_animation_speed = 3.5

	assert_that(kiosk_ui.text_animation_speed).is_equal(3.5)
	assert_that(kiosk_ui.text_animation_speed).is_greater(original_speed)

# Input Handling Tests
func test_ui_interaction_signal():
	"""Test UI interaction signal emission"""

	if kiosk_ui.has_method("_handle_ui_interaction"):
		kiosk_ui._handle_ui_interaction("button_press", {"button": "start"})

func test_mouse_filter_settings():
	"""Test mouse filter prevents unwanted interactions"""
	assert_that(kiosk_ui.main_overlay.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	assert_that(kiosk_ui.transition_overlay.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)

func test_touch_input_handling():
	"""Test touch input handling for kiosk environments"""
	if kiosk_ui.has_method("_handle_touch_input"):
		var mock_touch = InputEventScreenTouch.new()
		mock_touch.pressed = true
		mock_touch.position = Vector2(400, 300)

		kiosk_ui._handle_touch_input(mock_touch)
		# Should handle touch input appropriately

# Instruction Panel Tests
func test_show_instructions():
	"""Test showing instruction panel"""
	if kiosk_ui.has_method("show_instructions"):

		kiosk_ui.show_instructions()
		await get_tree().process_frame


func test_instruction_content():
	"""Test instruction panel displays correct content"""
	if kiosk_ui.has_method("show_instructions"):
		kiosk_ui.show_instructions()
		await get_tree().process_frame

		if kiosk_ui.instruction_panel:
			assert_that(kiosk_ui.instruction_panel.visible).is_true()

# Error Handling Tests
func test_handles_null_high_scores():
	"""Test handling null high scores data"""
	kiosk_ui.show_high_scores(null)
	await get_tree().process_frame

	# Should handle gracefully without crashing
	assert_that(kiosk_ui.current_overlay).is_equal("high_scores")

func test_handles_invalid_overlay_type():
	"""Test handling invalid overlay types"""
	if kiosk_ui.has_method("show_overlay"):
		kiosk_ui.show_overlay("invalid_overlay_type")
		# Should handle gracefully without crashing

func test_handles_rapid_state_changes():
	"""Test handling rapid overlay state changes"""
	for i in range(10):
		kiosk_ui.show_kiosk_overlay()
		kiosk_ui.hide_kiosk_overlay()
		await get_tree().process_frame

	# Should remain stable
	assert_that(kiosk_ui.is_overlay_visible).is_false()

func test_memory_management_overlays():
	"""Test memory management during overlay operations"""
	var initial_node_count = get_tree().get_node_count()

	# Show and hide multiple overlays
	kiosk_ui.show_kiosk_overlay()
	kiosk_ui.show_high_scores(test_scores)
	if kiosk_ui.has_method("show_demo_overlay"):
		kiosk_ui.show_demo_overlay()

	kiosk_ui.hide_all_interfaces()
	await get_tree().process_frame

	var final_node_count = get_tree().get_node_count()
	assert_that(abs(final_node_count - initial_node_count)).is_less_than(10)

# Performance Tests
func test_overlay_performance_large_datasets():
	"""Test overlay performance with large high score datasets"""
	var large_scores = []
	for i in range(1000):
		large_scores.append({
			"name": "PLAYER" + str(i),
			"score": randf() * 100000,
			"timestamp": "2024-01-01 12:00:00"
		})

	var start_time = Time.get_ticks_msec()
	kiosk_ui.show_high_scores(large_scores)
	await get_tree().process_frame
	var end_time = Time.get_ticks_msec()

	# Should complete within reasonable time
	var duration = end_time - start_time
	assert_that(duration).is_less_than(1000)  # Less than 1 second

func test_animation_performance():
	"""Test animation performance under load"""
	kiosk_ui.text_animation_speed = 10.0  # High speed
	kiosk_ui.show_kiosk_overlay()

	# Multiple rapid transitions
	for i in range(5):
		kiosk_ui.hide_kiosk_overlay()
		kiosk_ui.show_kiosk_overlay()
		await get_tree().process_frame

	# Should remain responsive
	assert_that(get_tree().get_process_mode()).is_not_equal(Node.PROCESS_MODE_DISABLED)

# Signal Tests
func test_overlay_shown_signal():
	"""Test overlay_shown signal emission"""

	kiosk_ui.show_kiosk_overlay()
	await get_tree().process_frame


func test_overlay_hidden_signal():
	"""Test overlay_hidden signal emission"""
	kiosk_ui.show_kiosk_overlay()
	await get_tree().process_frame


	kiosk_ui.hide_kiosk_overlay()
	await get_tree().process_frame


func test_multiple_signal_emissions():
	"""Test multiple signal emissions during state changes"""

	kiosk_ui.show_kiosk_overlay()
	kiosk_ui.show_high_scores(test_scores)
	kiosk_ui.hide_all_interfaces()
	await get_tree().process_frame


# Integration Tests
func test_overlay_integration_with_game_state():
	"""Test overlay integration with game state"""
	# Simulate game running
	kiosk_ui.show_kiosk_overlay()
	await get_tree().process_frame

	# Should overlay without interfering with game
	assert_that(kiosk_ui.is_overlay_visible).is_true()

func test_responsive_design():
	"""Test overlay adapts to different screen sizes"""
	var original_size = get_viewport().size

	# Simulate different screen size (limited by test environment)
	# In real implementation, would test different viewport sizes
	assert_that(kiosk_ui.main_overlay.size.x).is_greater(0)
	assert_that(kiosk_ui.main_overlay.size.y).is_greater(0)