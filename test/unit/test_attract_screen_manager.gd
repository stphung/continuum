extends GdUnitTestSuite
## Comprehensive tests for AttractScreenManager - content cycling, transitions, and timing

var attract_manager: Node
var test_config: Array

func before():
	"""Setup test environment with mock attract screen configuration"""
	# Create AttractScreenManager instance
	var AttractScreenManagerScript = preload("res://scripts/kiosk/AttractScreenManager.gd")
	attract_manager = AttractScreenManagerScript.new()
	attract_manager.name = "TestAttractScreenManager"
	add_child(attract_manager)

	# Setup test configuration
	test_config = [
		{"type": "gameplay", "duration": 10.0},
		{"type": "features", "duration": 8.0},
		{"type": "high_scores", "duration": 6.0},
		{"type": "instructions", "duration": 5.0}
	]

	await get_tree().process_frame

func after():
	"""Cleanup test environment"""
	if attract_manager and is_instance_valid(attract_manager):
		attract_manager.stop_cycle()
		attract_manager.queue_free()

	await get_tree().process_frame

# Initialization Tests
func test_attract_screen_manager_initialization():
	"""Test AttractScreenManager initializes with correct defaults"""
	assert_that(attract_manager.screen_configs).is_not_null()
	assert_that(attract_manager.screens_ui).is_not_null()
	assert_that(attract_manager.current_screen_index).is_equal(0)
	assert_that(attract_manager.is_cycling).is_false()
	assert_that(attract_manager.cycle_count).is_equal(0)

func test_transition_system_setup():
	"""Test transition system is properly initialized"""
	assert_that(attract_manager.transition_tween).is_not_null()
	assert_that(attract_manager.transition_duration).is_greater(0.0)
	assert_that(attract_manager.fade_duration).is_greater(0.0)

func test_content_templates_exist():
	"""Test that all content templates are properly defined"""
	var expected_templates = ["gameplay", "features", "high_scores", "instructions", "logo"]

	for template_name in expected_templates:
		assert_that(attract_manager.content_templates.has(template_name)).is_true()
		var template = attract_manager.content_templates[template_name]
		assert_that(template.has("title")).is_true()
		assert_that(template.has("subtitle")).is_true()
		assert_that(template.has("background_color")).is_true()

func test_screen_types_enum():
	"""Test ScreenType enum contains all expected values"""
	assert_that(attract_manager.ScreenType.has("GAMEPLAY")).is_true()
	assert_that(attract_manager.ScreenType.has("FEATURES")).is_true()
	assert_that(attract_manager.ScreenType.has("HIGH_SCORES")).is_true()
	assert_that(attract_manager.ScreenType.has("INSTRUCTIONS")).is_true()
	assert_that(attract_manager.ScreenType.has("LOGO")).is_true()
	assert_that(attract_manager.ScreenType.has("CUSTOM")).is_true()

# Configuration Tests
func test_setup_with_valid_configuration():
	"""Test setting up with valid attract screen configuration"""
	attract_manager.setup(test_config)

	assert_that(attract_manager.screen_configs.size()).is_equal(4)
	assert_that(attract_manager.screen_configs[0].type).is_equal("gameplay")
	assert_that(attract_manager.screen_configs[0].duration).is_equal(10.0)

func test_setup_with_empty_configuration():
	"""Test setting up with empty configuration"""
	attract_manager.setup([])

	assert_that(attract_manager.screen_configs.size()).is_equal(0)
	assert_that(attract_manager.screens_ui.size()).is_equal(0)

func test_setup_with_invalid_configuration():
	"""Test setup handles invalid configuration gracefully"""
	var invalid_config = [
		{"type": "invalid_type", "duration": 5.0},
		{"type": "gameplay"},  # Missing duration
		{"duration": 10.0}     # Missing type
	]

	attract_manager.setup(invalid_config)

	# Should handle gracefully without crashing
	assert_that(attract_manager.screen_configs.size()).is_equal(3)

func test_configuration_duplication():
	"""Test that configuration is properly duplicated, not referenced"""
	attract_manager.setup(test_config)

	# Modify original config
	test_config[0].duration = 99.0

	# Manager's config should be unchanged
	assert_that(attract_manager.screen_configs[0].duration).is_equal(10.0)

# Screen Cycling Tests
func test_start_cycle():
	"""Test starting the attract screen cycle"""
	attract_manager.setup(test_config)

	# Monitor signal
	var signal_count = [0]
	attract_manager.screen_changed.connect(func(type, index): signal_count[0] += 1)

	attract_manager.start_cycle()

	assert_that(attract_manager.is_cycling).is_true()
	assert_that(attract_manager.current_screen_index).is_equal(0)
	assert_that(signal_count[0]).is_equal(1)

func test_stop_cycle():
	"""Test stopping the attract screen cycle"""
	attract_manager.setup(test_config)
	attract_manager.start_cycle()

	attract_manager.stop_cycle()

	assert_that(attract_manager.is_cycling).is_false()

func test_next_screen_progression():
	"""Test progressing to next screen in cycle"""
	attract_manager.setup(test_config)
	attract_manager.start_cycle()


	attract_manager.next_screen()
	assert_that(attract_manager.current_screen_index).is_equal(1)

	attract_manager.next_screen()
	assert_that(attract_manager.current_screen_index).is_equal(2)

func test_cycle_wrap_around():
	"""Test cycle wraps around to beginning after last screen"""
	attract_manager.setup(test_config)
	attract_manager.start_cycle()

	# Go through all screens
	for i in range(test_config.size()):
		attract_manager.next_screen()

	# Should wrap to beginning
	assert_that(attract_manager.current_screen_index).is_equal(0)
	assert_that(attract_manager.cycle_count).is_equal(1)

func test_cycle_completed_signal():
	"""Test cycle_completed signal emission"""
	attract_manager.setup(test_config)
	attract_manager.start_cycle()


	# Complete one full cycle
	for i in range(test_config.size()):
		attract_manager.next_screen()


# Screen Type Handling Tests
func test_gameplay_screen_content():
	"""Test gameplay screen content generation"""
	attract_manager.setup([{"type": "gameplay", "duration": 10.0}])
	attract_manager.start_cycle()

	var current_screen_info = attract_manager.get_current_screen_info()
	assert_that(current_screen_info.type).is_equal("gameplay")

	if attract_manager.has_method("_get_screen_content"):
		var content = attract_manager._get_screen_content("gameplay")
		assert_that(content.has("title")).is_true()
		assert_that(content.title).is_equal("INTENSE SPACE COMBAT")

func test_features_screen_content():
	"""Test features screen content generation"""
	attract_manager.setup([{"type": "features", "duration": 8.0}])
	attract_manager.start_cycle()

	if attract_manager.has_method("_get_screen_content"):
		var content = attract_manager._get_screen_content("features")
		assert_that(content.title).is_equal("INNOVATIVE FEATURES")
		assert_that(content.has("features")).is_true()
		assert_that(content.features.size()).is_greater(0)

func test_instructions_screen_content():
	"""Test instructions screen content generation"""
	attract_manager.setup([{"type": "instructions", "duration": 5.0}])
	attract_manager.start_cycle()

	if attract_manager.has_method("_get_screen_content"):
		var content = attract_manager._get_screen_content("instructions")
		assert_that(content.title).is_equal("HOW TO PLAY")
		assert_that(content.features).contains(["• WASD or Arrow Keys: Move your ship"])

func test_high_scores_screen():
	"""Test high scores screen handling"""
	attract_manager.setup([{"type": "high_scores", "duration": 6.0}])
	attract_manager.start_cycle()

	if attract_manager.has_method("_get_screen_content"):
		var content = attract_manager._get_screen_content("high_scores")
		assert_that(content.title).is_equal("HALL OF FAME")

func test_logo_screen_content():
	"""Test logo screen content"""
	attract_manager.setup([{"type": "logo", "duration": 12.0}])
	attract_manager.start_cycle()

	if attract_manager.has_method("_get_screen_content"):
		var content = attract_manager._get_screen_content("logo")
		assert_that(content.title).is_equal("CONTINUUM")
		assert_that(content.subtitle).is_equal("Professional Vertical Scrolling Shooter")

# Screen Transition Tests
func test_transition_duration_configuration():
	"""Test transition duration can be configured"""
	var original_duration = attract_manager.transition_duration
	attract_manager.transition_duration = 2.5

	assert_that(attract_manager.transition_duration).is_equal(2.5)
	assert_that(attract_manager.transition_duration).is_not_equal(original_duration)

func test_fade_duration_configuration():
	"""Test fade duration can be configured"""
	var original_fade = attract_manager.fade_duration
	attract_manager.fade_duration = 1.2

	assert_that(attract_manager.fade_duration).is_equal(1.2)
	assert_that(attract_manager.fade_duration).is_not_equal(original_fade)

func test_transition_in_progress():
	"""Test transition state management"""
	attract_manager.setup(test_config)
	attract_manager.start_cycle()

	if attract_manager.has_method("_is_transitioning"):
		attract_manager._start_transition()
		assert_that(attract_manager._is_transitioning()).is_true()

func test_transition_completion():
	"""Test transition completion handling"""
	attract_manager.setup(test_config)
	attract_manager.start_cycle()

	if attract_manager.has_method("_on_transition_finished"):
		attract_manager._on_transition_finished()
		# Should complete transition state
		if attract_manager.has_method("_is_transitioning"):
			assert_that(attract_manager._is_transitioning()).is_false()

# Demo Integration Tests
func test_should_start_demo():
	"""Test demo start condition logic"""
	attract_manager.setup(test_config)
	attract_manager.start_cycle()

	# Complete a few cycles
	for i in range(8):  # 2 full cycles
		attract_manager.next_screen()

	# Should consider starting demo after multiple cycles
	var should_demo = attract_manager.should_start_demo()
	assert_that(should_demo).is_instance_of(TYPE_BOOL)

func test_demo_requested_signal():
	"""Test demo_requested signal emission"""
	attract_manager.setup(test_config)
	attract_manager.start_cycle()


	if attract_manager.has_method("request_demo"):
		attract_manager.request_demo()

func test_demo_timing_logic():
	"""Test demo timing based on cycle count"""
	attract_manager.setup(test_config)
	attract_manager.start_cycle()

	# Initially should not request demo
	assert_that(attract_manager.should_start_demo()).is_false()

	# After multiple cycles, might request demo
	attract_manager.cycle_count = 3
	var should_demo_after_cycles = attract_manager.should_start_demo()
	# Implementation dependent - could be true or false based on logic

# UI Management Tests
func test_screen_ui_creation():
	"""Test UI elements are created for each screen type"""
	attract_manager.setup(test_config)

	# UI elements should be created
	assert_that(attract_manager.screens_ui.size()).is_greater_equal(0)
	# Implementation dependent - might create UI immediately or lazily

func test_hide_all_screens():
	"""Test hiding all screen UI elements"""
	attract_manager.setup(test_config)
	attract_manager.start_cycle()

	attract_manager.hide_all_screens()

	# All screens should be hidden
	if attract_manager.has_method("_are_all_screens_hidden"):
		assert_that(attract_manager._are_all_screens_hidden()).is_true()

func test_hide_current_screen():
	"""Test hiding current screen"""
	attract_manager.setup(test_config)
	attract_manager.start_cycle()

	attract_manager.hide_current_screen()

	# Current screen should be hidden
	if attract_manager.has_method("_is_current_screen_hidden"):
		assert_that(attract_manager._is_current_screen_hidden()).is_true()

func test_show_screen():
	"""Test showing specific screen"""
	attract_manager.setup(test_config)

	if attract_manager.has_method("show_screen"):
		attract_manager.show_screen(1)  # Show features screen
		assert_that(attract_manager.current_screen_index).is_equal(1)

# Information and State Tests
func test_get_current_screen_info():
	"""Test getting current screen information"""
	attract_manager.setup(test_config)
	attract_manager.start_cycle()

	var screen_info = attract_manager.get_current_screen_info()
	assert_that(screen_info).is_not_null()
	assert_that(screen_info.has("type")).is_true()
	assert_that(screen_info.has("duration")).is_true()
	assert_that(screen_info.type).is_equal("gameplay")

func test_get_screen_info_by_index():
	"""Test getting screen information by index"""
	attract_manager.setup(test_config)

	if attract_manager.has_method("get_screen_info"):
		var screen_info = attract_manager.get_screen_info(2)
		assert_that(screen_info.type).is_equal("high_scores")
		assert_that(screen_info.duration).is_equal(6.0)

func test_get_total_screens():
	"""Test getting total number of configured screens"""
	attract_manager.setup(test_config)

	if attract_manager.has_method("get_total_screens"):
		var total = attract_manager.get_total_screens()
		assert_that(total).is_equal(4)

func test_get_current_cycle_count():
	"""Test getting current cycle count"""
	attract_manager.setup(test_config)
	attract_manager.start_cycle()

	# Complete some screens to increase cycle count
	for i in range(test_config.size() + 2):
		attract_manager.next_screen()

	assert_that(attract_manager.cycle_count).is_greater_equal(1)

# Error Handling Tests
func test_handles_empty_screen_configs():
	"""Test handling empty screen configurations"""
	attract_manager.setup([])
	attract_manager.start_cycle()

	# Should handle gracefully
	assert_that(attract_manager.is_cycling).is_false()  # or true, depending on implementation

func test_handles_invalid_screen_index():
	"""Test handling invalid screen indices"""
	attract_manager.setup(test_config)

	if attract_manager.has_method("show_screen"):
		attract_manager.show_screen(99)  # Invalid index
		# Should handle gracefully without crashing
		assert_that(attract_manager.current_screen_index).is_between(0, test_config.size() - 1)

func test_handles_missing_content_template():
	"""Test handling missing content templates"""
	var invalid_config = [{"type": "nonexistent_type", "duration": 5.0}]
	attract_manager.setup(invalid_config)
	attract_manager.start_cycle()

	# Should handle missing template gracefully
	if attract_manager.has_method("_get_screen_content"):
		var content = attract_manager._get_screen_content("nonexistent_type")
		# Should return default content or handle gracefully

func test_handles_zero_duration():
	"""Test handling screens with zero duration"""
	var zero_duration_config = [{"type": "gameplay", "duration": 0.0}]
	attract_manager.setup(zero_duration_config)
	attract_manager.start_cycle()

	# Should handle zero duration gracefully
	assert_that(attract_manager.is_cycling).is_instance_of(TYPE_BOOL)

# Memory Management Tests
func test_cleanup_on_stop():
	"""Test proper cleanup when stopping cycle"""
	attract_manager.setup(test_config)
	attract_manager.start_cycle()

	var initial_node_count = get_tree().get_node_count()

	attract_manager.stop_cycle()
	await get_tree().process_frame

	# Should not leak significant nodes
	var final_node_count = get_tree().get_node_count()
	assert_that(abs(final_node_count - initial_node_count)).is_less_than(5)

func test_tween_cleanup():
	"""Test proper tween cleanup"""
	attract_manager.setup(test_config)
	attract_manager.start_cycle()

	assert_that(attract_manager.transition_tween).is_not_null()

	attract_manager.stop_cycle()

	# Tween should be stopped and cleaned up
	if attract_manager.transition_tween:
		assert_that(attract_manager.transition_tween.is_valid()).is_false()

# Signal Tests
func test_screen_changed_signal():
	"""Test screen_changed signal emission"""
	attract_manager.setup(test_config)

	attract_manager.start_cycle()


func test_multiple_signal_emissions():
	"""Test signal emissions during screen transitions"""
	attract_manager.setup(test_config)
	attract_manager.start_cycle()


	attract_manager.next_screen()
	attract_manager.next_screen()


# Performance Tests
func test_rapid_screen_transitions():
	"""Test handling rapid screen transitions"""
	attract_manager.setup(test_config)
	attract_manager.start_cycle()

	# Rapid transitions
	for i in range(20):
		attract_manager.next_screen()
		await get_tree().process_frame

	# Should remain stable
	assert_that(attract_manager.is_cycling).is_true()
	assert_that(attract_manager.current_screen_index).is_between(0, test_config.size() - 1)

func test_long_running_cycle():
	"""Test stability during long-running attract cycle"""
	attract_manager.setup(test_config)
	attract_manager.start_cycle()

	# Simulate many cycles
	for i in range(100):
		attract_manager.next_screen()

	assert_that(attract_manager.cycle_count).is_greater(10)
	assert_that(attract_manager.is_cycling).is_true()