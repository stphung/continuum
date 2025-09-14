extends Node
## AttractScreenManager - Manages cycling promotional content for kiosk mode
## Handles different types of attract screens with smooth transitions and timing

signal screen_changed(screen_type: String, screen_index: int)
signal cycle_completed
signal demo_requested

enum ScreenType {
	GAMEPLAY,     # Gameplay footage/screenshots
	FEATURES,     # Game features and highlights
	HIGH_SCORES,  # Current high scores
	INSTRUCTIONS, # How to play
	LOGO,         # Game logo and branding
	CUSTOM        # Custom promotional content
}

var screen_configs: Array = []
var current_screen_index: int = 0
var screens_ui: Array = []
var is_cycling: bool = false
var cycle_count: int = 0
var transition_tween: Tween

# Screen transition effects
var transition_duration: float = 1.0
var fade_duration: float = 0.5

# Content templates
var content_templates: Dictionary = {
	"gameplay": {
		"title": "INTENSE SPACE COMBAT",
		"subtitle": "Experience thrilling vertical scrolling action",
		"features": [
			"• Dual weapon system: Vulcan spread and Laser piercing",
			"• 5 upgrade levels for each weapon type",
			"• Strategic bomb system for emergencies",
			"• Procedural enemy wave generation",
			"• Dynamic difficulty progression"
		],
		"background_color": Color(0.1, 0.1, 0.3, 0.9)
	},
	"features": {
		"title": "INNOVATIVE FEATURES",
		"subtitle": "Cutting-edge game technology",
		"features": [
			"• Zero-dependency procedural audio synthesis",
			"• Professional testing framework integration",
			"• Advanced particle effect systems",
			"• Intelligent AI demonstration mode",
			"• Clean modular architecture design"
		],
		"background_color": Color(0.2, 0.1, 0.2, 0.9)
	},
	"high_scores": {
		"title": "HALL OF FAME",
		"subtitle": "Top pilots and their achievements",
		"background_color": Color(0.1, 0.2, 0.1, 0.9)
	},
	"instructions": {
		"title": "HOW TO PLAY",
		"subtitle": "Master the controls and dominate the skies",
		"features": [
			"• WASD or Arrow Keys: Move your ship",
			"• SPACE or Z: Fire primary weapons",
			"• X: Deploy smart bomb (limited supply)",
			"• Collect power-ups to upgrade weapons",
			"• Switch between Vulcan and Laser modes",
			"• Survive waves of increasing difficulty"
		],
		"background_color": Color(0.2, 0.2, 0.1, 0.9)
	},
	"logo": {
		"title": "CONTINUUM",
		"subtitle": "Professional Vertical Scrolling Shooter",
		"features": [
			"Built with Godot 4.4",
			"Demonstrates modern game architecture",
			"Open source and educational",
			"Professional-grade codebase"
		],
		"background_color": Color(0.1, 0.1, 0.1, 0.9)
	}
}

func _ready():
	print("AttractScreenManager: Initializing attract screen system...")
	_setup_transition_system()

func setup(attract_configs: Array):
	"""Setup attract screens based on configuration"""
	screen_configs = attract_configs.duplicate()
	_create_screen_ui_elements()
	print("AttractScreenManager: Configured ", screen_configs.size(), " attract screens")

func _setup_transition_system():
	"""Initialize screen transition system"""
	transition_tween = create_tween()
	transition_tween.finished.connect(_on_transition_finished)

func _create_screen_ui_elements():
	"""Create UI elements for each configured screen type"""
	screens_ui.clear()

	for i in range(screen_configs.size()):
		var config = screen_configs[i]
		var screen_ui = _create_screen_ui(config.type, i)
		screens_ui.append(screen_ui)
		add_child(screen_ui)
		screen_ui.visible = false

func _create_screen_ui(screen_type: String, index: int) -> Control:
	"""Create UI for a specific screen type"""
	var container = Control.new()
	container.name = "AttractScreen_" + str(index)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	match screen_type:
		"gameplay":
			_create_gameplay_screen(container)
		"features":
			_create_features_screen(container)
		"high_scores":
			_create_high_scores_screen(container)
		"instructions":
			_create_instructions_screen(container)
		"logo":
			_create_logo_screen(container)
		_:
			_create_generic_screen(container, screen_type)

	return container

func _create_gameplay_screen(container: Control):
	"""Create gameplay showcase screen"""
	var template = content_templates.gameplay

	# Background
	var background = ColorRect.new()
	background.color = template.background_color
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(background)

	# Main title
	var title = Label.new()
	title.text = template.title
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(50, 100)
	title.size = Vector2(700, 80)
	container.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = template.subtitle
	subtitle.add_theme_font_size_override("font_size", 32)
	subtitle.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(50, 180)
	subtitle.size = Vector2(700, 40)
	container.add_child(subtitle)

	# Feature list
	var features_container = VBoxContainer.new()
	features_container.position = Vector2(100, 280)
	features_container.size = Vector2(600, 400)
	container.add_child(features_container)

	for feature in template.features:
		var feature_label = Label.new()
		feature_label.text = feature
		feature_label.add_theme_font_size_override("font_size", 24)
		feature_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
		features_container.add_child(feature_label)

	# Add animated elements
	_add_floating_particles(container)
	_add_pulsing_effect(title)

func _create_features_screen(container: Control):
	"""Create features showcase screen"""
	var template = content_templates.features

	# Background
	var background = ColorRect.new()
	background.color = template.background_color
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(background)

	# Main title
	var title = Label.new()
	title.text = template.title
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(50, 120)
	title.size = Vector2(700, 70)
	container.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = template.subtitle
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(50, 200)
	subtitle.size = Vector2(700, 35)
	container.add_child(subtitle)

	# Feature boxes
	var feature_grid = GridContainer.new()
	feature_grid.columns = 1
	feature_grid.position = Vector2(80, 280)
	feature_grid.size = Vector2(640, 500)
	container.add_child(feature_grid)

	for feature in template.features:
		var feature_box = Panel.new()
		feature_box.custom_minimum_size = Vector2(600, 60)

		# Feature box background
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.3, 0.2, 0.3, 0.7)
		style_box.corner_radius_top_left = 10
		style_box.corner_radius_top_right = 10
		style_box.corner_radius_bottom_left = 10
		style_box.corner_radius_bottom_right = 10
		feature_box.add_theme_stylebox_override("panel", style_box)

		var feature_label = Label.new()
		feature_label.text = feature
		feature_label.add_theme_font_size_override("font_size", 22)
		feature_label.add_theme_color_override("font_color", Color.WHITE)
		feature_label.position = Vector2(20, 18)
		feature_box.add_child(feature_label)

		feature_grid.add_child(feature_box)

func _create_high_scores_screen(container: Control):
	"""Create high scores display screen"""
	var template = content_templates.high_scores

	# Background
	var background = ColorRect.new()
	background.color = template.background_color
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(background)

	# Title
	var title = Label.new()
	title.text = template.title
	title.add_theme_font_size_override("font_size", 60)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(50, 100)
	title.size = Vector2(700, 75)
	container.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = template.subtitle
	subtitle.add_theme_font_size_override("font_size", 30)
	subtitle.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(50, 180)
	subtitle.size = Vector2(700, 40)
	container.add_child(subtitle)

	# High scores list container (will be populated dynamically)
	var scores_container = VBoxContainer.new()
	scores_container.name = "HighScoresContainer"
	scores_container.position = Vector2(150, 260)
	scores_container.size = Vector2(500, 500)
	container.add_child(scores_container)

	_add_glowing_effect(title, Color(1.0, 1.0, 0.6))

func _create_instructions_screen(container: Control):
	"""Create instructions/how-to-play screen"""
	var template = content_templates.instructions

	# Background
	var background = ColorRect.new()
	background.color = template.background_color
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(background)

	# Title
	var title = Label.new()
	title.text = template.title
	title.add_theme_font_size_override("font_size", 58)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(50, 80)
	title.size = Vector2(700, 70)
	container.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = template.subtitle
	subtitle.add_theme_font_size_override("font_size", 26)
	subtitle.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(50, 160)
	subtitle.size = Vector2(700, 35)
	container.add_child(subtitle)

	# Instructions grid
	var instructions_container = VBoxContainer.new()
	instructions_container.position = Vector2(80, 220)
	instructions_container.size = Vector2(640, 600)
	container.add_child(instructions_container)

	for instruction in template.features:
		var instruction_panel = Panel.new()
		instruction_panel.custom_minimum_size = Vector2(620, 55)

		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.3, 0.3, 0.2, 0.8)
		style_box.corner_radius_top_left = 8
		style_box.corner_radius_top_right = 8
		style_box.corner_radius_bottom_left = 8
		style_box.corner_radius_bottom_right = 8
		instruction_panel.add_theme_stylebox_override("panel", style_box)

		var instruction_label = Label.new()
		instruction_label.text = instruction
		instruction_label.add_theme_font_size_override("font_size", 20)
		instruction_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.9))
		instruction_label.position = Vector2(15, 17)
		instruction_panel.add_child(instruction_label)

		instructions_container.add_child(instruction_panel)

func _create_logo_screen(container: Control):
	"""Create logo/branding screen"""
	var template = content_templates.logo

	# Background
	var background = ColorRect.new()
	background.color = template.background_color
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(background)

	# Large game title
	var main_title = Label.new()
	main_title.text = template.title
	main_title.add_theme_font_size_override("font_size", 80)
	main_title.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	main_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_title.position = Vector2(50, 200)
	main_title.size = Vector2(700, 90)
	container.add_child(main_title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = template.subtitle
	subtitle.add_theme_font_size_override("font_size", 32)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(50, 300)
	subtitle.size = Vector2(700, 40)
	container.add_child(subtitle)

	# Tech info
	var tech_container = VBoxContainer.new()
	tech_container.position = Vector2(250, 420)
	tech_container.size = Vector2(300, 200)
	container.add_child(tech_container)

	for info in template.features:
		var info_label = Label.new()
		info_label.text = info
		info_label.add_theme_font_size_override("font_size", 18)
		info_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
		info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tech_container.add_child(info_label)

	# Add dramatic effects
	_add_pulsing_effect(main_title)
	_add_glow_particles(container)

func _create_generic_screen(container: Control, screen_type: String):
	"""Create a generic screen for unknown types"""
	var background = ColorRect.new()
	background.color = Color(0.1, 0.1, 0.1, 0.9)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(background)

	var title = Label.new()
	title.text = screen_type.to_upper()
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(50, 300)
	title.size = Vector2(700, 60)
	container.add_child(title)

# Animation and Effects
func _add_floating_particles(container: Control):
	"""Add floating particle animation effects"""
	for i in range(15):
		var particle = ColorRect.new()
		particle.size = Vector2(3, 3)
		particle.color = Color(1, 1, 1, 0.6)
		particle.position = Vector2(randf_range(0, 800), randf_range(0, 900))
		container.add_child(particle)

		# Create floating animation
		var tween = create_tween()
		tween.set_loops()
		tween.parallel().tween_property(particle, "position:y", particle.position.y - 200, randf_range(8, 12))
		tween.parallel().tween_property(particle, "position:x", particle.position.x + randf_range(-50, 50), randf_range(6, 10))
		tween.parallel().tween_property(particle, "modulate:a", 0.0, randf_range(8, 12))

		tween.tween_callback(func():
			particle.position.y = 900 + randf_range(0, 100)
			particle.position.x = randf_range(0, 800)
			particle.modulate.a = 0.6
		)

func _add_pulsing_effect(label: Label):
	"""Add pulsing glow effect to label"""
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(label, "modulate", Color(1.2, 1.2, 1.2, 1.0), 1.5)
	tween.tween_property(label, "modulate", Color(0.8, 0.8, 0.8, 1.0), 1.5)

func _add_glowing_effect(label: Label, glow_color: Color):
	"""Add glowing outline effect to label"""
	# Set up the theme color override first
	label.add_theme_color_override("font_color", glow_color)
	var tween = create_tween()
	tween.set_loops()
	# Tween the modulate property to create a glowing effect
	tween.tween_property(label, "modulate", glow_color * 1.3, 1.0)
	tween.tween_property(label, "modulate", glow_color * 0.7, 1.0)

func _add_glow_particles(container: Control):
	"""Add glowing particle effects"""
	for i in range(8):
		var glow = ColorRect.new()
		glow.size = Vector2(6, 6)
		glow.color = Color(0.8, 0.9, 1.0, 0.4)
		glow.position = Vector2(randf_range(100, 700), randf_range(100, 800))
		container.add_child(glow)

		var tween = create_tween()
		tween.set_loops()
		tween.parallel().tween_property(glow, "scale", Vector2(1.5, 1.5), randf_range(2, 4))
		tween.parallel().tween_property(glow, "modulate:a", 0.1, randf_range(2, 4))
		tween.parallel().tween_property(glow, "scale", Vector2(0.5, 0.5), randf_range(2, 4))
		tween.parallel().tween_property(glow, "modulate:a", 0.8, randf_range(2, 4))

# Screen Management
func start_cycle():
	"""Start the attract screen cycle"""
	if screens_ui.size() == 0:
		push_error("AttractScreenManager: No screens configured")
		return

	print("AttractScreenManager: Starting attract screen cycle")
	is_cycling = true
	current_screen_index = 0
	_show_screen(current_screen_index)

func stop_cycle():
	"""Stop the attract screen cycle"""
	print("AttractScreenManager: Stopping attract screen cycle")
	is_cycling = false
	hide_all_screens()

func next_screen():
	"""Advance to the next screen in the cycle"""
	if not is_cycling or screens_ui.size() == 0:
		return

	var next_index = (current_screen_index + 1) % screens_ui.size()

	# Check if we should start a demo instead of showing next screen
	if _should_start_demo_at_index(next_index):
		demo_requested.emit()
		return

	_transition_to_screen(next_index)

func previous_screen():
	"""Go to the previous screen in the cycle"""
	if not is_cycling or screens_ui.size() == 0:
		return

	var prev_index = (current_screen_index - 1) % screens_ui.size()
	if prev_index < 0:
		prev_index = screens_ui.size() - 1

	_transition_to_screen(prev_index)

func _show_screen(index: int):
	"""Show a specific screen without transition"""
	if index < 0 or index >= screens_ui.size():
		return

	# Hide all screens
	hide_all_screens()

	# Show selected screen
	screens_ui[index].visible = true
	current_screen_index = index

	# Update high scores if showing high scores screen
	if screen_configs[index].type == "high_scores":
		_update_high_scores_display(screens_ui[index])

	screen_changed.emit(screen_configs[index].type, index)
	print("AttractScreenManager: Showing screen ", index, " (", screen_configs[index].type, ")")

func _transition_to_screen(target_index: int):
	"""Transition to target screen with effects"""
	if target_index < 0 or target_index >= screens_ui.size():
		return

	if target_index == current_screen_index:
		return

	print("AttractScreenManager: Transitioning to screen ", target_index)

	# Start transition
	var current_screen = screens_ui[current_screen_index]
	var target_screen = screens_ui[target_index]

	# Prepare target screen
	target_screen.modulate.a = 0.0
	target_screen.visible = true

	# Update high scores if needed
	if screen_configs[target_index].type == "high_scores":
		_update_high_scores_display(target_screen)

	# Create transition tween
	transition_tween = create_tween()
	transition_tween.set_parallel(true)

	# Fade out current screen
	transition_tween.tween_property(current_screen, "modulate:a", 0.0, fade_duration)

	# Fade in target screen
	transition_tween.tween_property(target_screen, "modulate:a", 1.0, fade_duration)

	# Complete transition
	transition_tween.tween_callback(func():
		current_screen.visible = false
		current_screen.modulate.a = 1.0
		current_screen_index = target_index
		screen_changed.emit(screen_configs[target_index].type, target_index)
	)

func _update_high_scores_display(screen: Control):
	"""Update high scores display with current data"""
	var scores_container = screen.find_child("HighScoresContainer")
	if not scores_container:
		return

	# Clear existing scores
	for child in scores_container.get_children():
		child.queue_free()

	# Get high scores from manager
	var high_scores = []
	if has_node("/root/KioskManager/HighScoreManager"):
		var manager = get_node("/root/KioskManager/HighScoreManager")
		high_scores = manager.get_scores()

	# Display high scores
	for i in range(min(10, high_scores.size())):
		var score_data = high_scores[i]
		var rank = i + 1

		var score_panel = Panel.new()
		score_panel.custom_minimum_size = Vector2(480, 40)

		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.2, 0.4, 0.2, 0.8) if rank <= 3 else Color(0.1, 0.2, 0.1, 0.6)
		style_box.corner_radius_top_left = 5
		style_box.corner_radius_top_right = 5
		style_box.corner_radius_bottom_left = 5
		style_box.corner_radius_bottom_right = 5
		score_panel.add_theme_stylebox_override("panel", style_box)

		var score_label = Label.new()
		var rank_text = str(rank) + ". "
		if rank <= 3:
			rank_text = ["1st", "2nd", "3rd"][rank - 1] + " "

		score_label.text = rank_text + score_data.name + " - " + str(score_data.score)
		score_label.add_theme_font_size_override("font_size", 24 if rank <= 3 else 20)
		score_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8) if rank <= 3 else Color(0.9, 0.9, 0.9))
		score_label.position = Vector2(15, 8)

		score_panel.add_child(score_label)
		scores_container.add_child(score_panel)

func hide_all_screens():
	"""Hide all attract screens"""
	for screen in screens_ui:
		screen.visible = false

func hide_current_screen():
	"""Hide the currently displayed screen"""
	if current_screen_index >= 0 and current_screen_index < screens_ui.size():
		screens_ui[current_screen_index].visible = false

func show_specific_screen(screen_type: String):
	"""Show a specific screen type"""
	for i in range(screen_configs.size()):
		if screen_configs[i].type == screen_type:
			_show_screen(i)
			return

func _should_start_demo_at_index(index: int) -> bool:
	"""Check if we should start a demo instead of showing this screen"""
	# Start demo after completing a full cycle of attract screens
	if index == 0 and cycle_count > 0:
		return true

	# Or based on specific screen configuration
	if index < screen_configs.size():
		return screen_configs[index].get("start_demo", false)

	return false

func should_start_demo() -> bool:
	"""Check if it's time to start a demo session"""
	cycle_count += 1
	return cycle_count % 3 == 0  # Start demo every 3rd cycle

func _on_transition_finished():
	"""Handle transition completion"""
	if current_screen_index == 0 and cycle_count > 0:
		cycle_completed.emit()

# Public API
func get_current_screen_info() -> Dictionary:
	"""Get information about the currently displayed screen"""
	if current_screen_index >= 0 and current_screen_index < screen_configs.size():
		return {
			"index": current_screen_index,
			"type": screen_configs[current_screen_index].type,
			"duration": screen_configs[current_screen_index].get("duration", 15.0),
			"is_cycling": is_cycling
		}
	return {}

func get_screen_count() -> int:
	"""Get total number of configured screens"""
	return screens_ui.size()

func is_active() -> bool:
	"""Check if attract screens are currently active"""
	return is_cycling

func set_transition_duration(duration: float):
	"""Set screen transition duration"""
	transition_duration = max(0.1, duration)
	fade_duration = transition_duration * 0.5

func add_custom_screen(config: Dictionary):
	"""Add a custom screen configuration at runtime"""
	screen_configs.append(config)
	var screen_ui = _create_screen_ui(config.type, screen_configs.size() - 1)
	screens_ui.append(screen_ui)
	add_child(screen_ui)
	screen_ui.visible = false

func _exit_tree():
	"""Cleanup on exit"""
	if transition_tween:
		transition_tween.kill()