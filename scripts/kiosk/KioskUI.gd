extends Node
## KioskUI - Full-Screen Overlay Interface System for Kiosk Mode
## Manages all kiosk-specific UI elements with smooth transitions and professional presentation

signal ui_interaction(interaction_type: String, data: Dictionary)
signal overlay_shown(overlay_type: String)
signal overlay_hidden(overlay_type: String)

var main_overlay: Control
var high_score_display: Control
var demo_overlay: Control
var transition_overlay: Control
var instruction_panel: Control

# UI State Management
var current_overlay: String = ""
var is_overlay_visible: bool = false
var transition_tween: Tween

# Visual Configuration
var overlay_fade_duration: float = 0.8
var text_animation_speed: float = 2.0
var particle_density: float = 0.3

# Color scheme for different modes
var color_schemes: Dictionary = {
	"attract": {
		"primary": Color(0.2, 0.4, 0.8, 0.9),
		"secondary": Color(0.1, 0.2, 0.4, 0.7),
		"accent": Color(0.8, 0.9, 1.0, 1.0),
		"text": Color(1.0, 1.0, 1.0, 1.0)
	},
	"demo": {
		"primary": Color(0.8, 0.2, 0.2, 0.9),
		"secondary": Color(0.4, 0.1, 0.1, 0.7),
		"accent": Color(1.0, 0.8, 0.8, 1.0),
		"text": Color(1.0, 1.0, 1.0, 1.0)
	},
	"high_scores": {
		"primary": Color(0.2, 0.8, 0.2, 0.9),
		"secondary": Color(0.1, 0.4, 0.1, 0.7),
		"accent": Color(0.8, 1.0, 0.8, 1.0),
		"text": Color(1.0, 1.0, 1.0, 1.0)
	},
	"transition": {
		"primary": Color(0.1, 0.1, 0.1, 0.95),
		"secondary": Color(0.05, 0.05, 0.05, 0.8),
		"accent": Color(0.9, 0.9, 0.9, 1.0),
		"text": Color(1.0, 1.0, 1.0, 1.0)
	}
}

func _ready():
	print("KioskUI: Initializing full-screen overlay system...")
	_setup_ui_hierarchy()
	_create_overlays()
	_setup_animations()

func _setup_ui_hierarchy():
	"""Setup the UI node hierarchy"""
	# Main overlay container (full screen)
	main_overlay = Control.new()
	main_overlay.name = "KioskMainOverlay"
	main_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_overlay.visible = false
	add_child(main_overlay)

	# Transition overlay (for smooth state changes)
	transition_overlay = Control.new()
	transition_overlay.name = "TransitionOverlay"
	transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.visible = false
	add_child(transition_overlay)

func _create_overlays():
	"""Create all overlay UI elements"""
	_create_demo_overlay()
	_create_high_score_display()
	_create_instruction_panel()
	_create_transition_effects()

func _create_demo_overlay():
	"""Create AI demo overlay with performance indicators"""
	demo_overlay = Control.new()
	demo_overlay.name = "DemoOverlay"
	demo_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	demo_overlay.visible = false
	main_overlay.add_child(demo_overlay)

	# Semi-transparent background
	var demo_bg = ColorRect.new()
	demo_bg.color = color_schemes.demo.primary
	demo_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	demo_overlay.add_child(demo_bg)

	# Demo status panel (top-left)
	var status_panel = Panel.new()
	status_panel.position = Vector2(20, 20)
	status_panel.size = Vector2(300, 120)
	status_panel.modulate = Color(1, 1, 1, 0.9)
	demo_overlay.add_child(status_panel)

	var status_style = StyleBoxFlat.new()
	status_style.bg_color = color_schemes.demo.secondary
	status_style.corner_radius_top_left = 10
	status_style.corner_radius_top_right = 10
	status_style.corner_radius_bottom_left = 10
	status_style.corner_radius_bottom_right = 10
	status_style.border_color = color_schemes.demo.accent
	status_style.border_width_left = 2
	status_style.border_width_right = 2
	status_style.border_width_top = 2
	status_style.border_width_bottom = 2
	status_panel.add_theme_stylebox_override("panel", status_style)

	# Demo title
	var demo_title = Label.new()
	demo_title.name = "DemoTitle"
	demo_title.text = "AI DEMONSTRATION"
	demo_title.add_theme_font_size_override("font_size", 20)
	demo_title.add_theme_color_override("font_color", color_schemes.demo.accent)
	demo_title.position = Vector2(10, 10)
	demo_title.size = Vector2(280, 25)
	demo_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_panel.add_child(demo_title)

	# AI performance stats
	var stats_container = VBoxContainer.new()
	stats_container.position = Vector2(15, 35)
	stats_container.size = Vector2(270, 75)
	status_panel.add_child(stats_container)

	# Score display
	var score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "Score: 0"
	score_label.add_theme_font_size_override("font_size", 16)
	score_label.add_theme_color_override("font_color", color_schemes.demo.text)
	stats_container.add_child(score_label)

	# Difficulty display
	var difficulty_label = Label.new()
	difficulty_label.name = "DifficultyLabel"
	difficulty_label.text = "Difficulty: Intermediate"
	difficulty_label.add_theme_font_size_override("font_size", 14)
	difficulty_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	stats_container.add_child(difficulty_label)

	# Performance metrics
	var performance_label = Label.new()
	performance_label.name = "PerformanceLabel"
	performance_label.text = "Accuracy: 0% | Efficiency: 0%"
	performance_label.add_theme_font_size_override("font_size", 12)
	performance_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	stats_container.add_child(performance_label)

	# AI indicator (bottom-right)
	var ai_indicator = Panel.new()
	ai_indicator.position = Vector2(650, 820)
	ai_indicator.size = Vector2(130, 40)
	demo_overlay.add_child(ai_indicator)

	var ai_indicator_style = StyleBoxFlat.new()
	ai_indicator_style.bg_color = Color(0.8, 0.2, 0.2, 0.8)
	ai_indicator_style.corner_radius_top_left = 20
	ai_indicator_style.corner_radius_top_right = 20
	ai_indicator_style.corner_radius_bottom_left = 20
	ai_indicator_style.corner_radius_bottom_right = 20
	ai_indicator.add_theme_stylebox_override("panel", ai_indicator_style)

	var ai_text = Label.new()
	ai_text.text = "AI PLAYING"
	ai_text.add_theme_font_size_override("font_size", 16)
	ai_text.add_theme_color_override("font_color", Color.WHITE)
	ai_text.position = Vector2(15, 10)
	ai_text.size = Vector2(100, 20)
	ai_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ai_indicator.add_child(ai_text)

	# Add pulsing effect to AI indicator
	_add_pulsing_effect(ai_indicator, Color(0.8, 0.2, 0.2, 0.8), Color(1.0, 0.4, 0.4, 1.0), 1.5)

func _create_high_score_display():
	"""Create high score display overlay"""
	high_score_display = Control.new()
	high_score_display.name = "HighScoreDisplay"
	high_score_display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	high_score_display.visible = false
	main_overlay.add_child(high_score_display)

	# Background
	var bg = ColorRect.new()
	bg.color = color_schemes.high_scores.primary
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	high_score_display.add_child(bg)

	# Main title
	var title = Label.new()
	title.name = "HighScoreTitle"
	title.text = "HALL OF FAME"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(50, 80)
	title.size = Vector2(700, 90)
	high_score_display.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Top Pilots and Their Legendary Achievements"
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(50, 170)
	subtitle.size = Vector2(700, 35)
	high_score_display.add_child(subtitle)

	# Scores container
	var scores_scroll = ScrollContainer.new()
	scores_scroll.name = "ScoresScroll"
	scores_scroll.position = Vector2(100, 230)
	scores_scroll.size = Vector2(600, 600)
	high_score_display.add_child(scores_scroll)

	var scores_list = VBoxContainer.new()
	scores_list.name = "ScoresList"
	scores_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scores_scroll.add_child(scores_list)

	# Add decorative elements
	_add_floating_stars(high_score_display, 20)
	_add_glow_effect(title, Color(1.0, 1.0, 0.8))

func _create_instruction_panel():
	"""Create instruction overlay"""
	instruction_panel = Control.new()
	instruction_panel.name = "InstructionPanel"
	instruction_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	instruction_panel.visible = false
	main_overlay.add_child(instruction_panel)

	# Semi-transparent background
	var instruction_bg = ColorRect.new()
	instruction_bg.color = Color(0.0, 0.0, 0.0, 0.7)
	instruction_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	instruction_panel.add_child(instruction_bg)

	# Central instruction box
	var instruction_box = Panel.new()
	instruction_box.position = Vector2(150, 200)
	instruction_box.size = Vector2(500, 400)
	instruction_panel.add_child(instruction_box)

	var box_style = StyleBoxFlat.new()
	box_style.bg_color = Color(0.2, 0.2, 0.3, 0.95)
	box_style.corner_radius_top_left = 15
	box_style.corner_radius_top_right = 15
	box_style.corner_radius_bottom_left = 15
	box_style.corner_radius_bottom_right = 15
	box_style.border_color = Color(0.6, 0.8, 1.0)
	box_style.border_width_left = 3
	box_style.border_width_right = 3
	box_style.border_width_top = 3
	box_style.border_width_bottom = 3
	instruction_box.add_theme_stylebox_override("panel", box_style)

	# Instruction title
	var instruction_title = Label.new()
	instruction_title.text = "PRESS ANY KEY TO PLAY"
	instruction_title.add_theme_font_size_override("font_size", 36)
	instruction_title.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	instruction_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_title.position = Vector2(20, 50)
	instruction_title.size = Vector2(460, 45)
	instruction_box.add_child(instruction_title)

	# Instructions text
	var instructions = Label.new()
	instructions.name = "InstructionsText"
	instructions.text = """Controls:
	WASD or Arrow Keys - Move Ship
	SPACE or Z - Fire Weapons
	X - Deploy Smart Bomb

	Collect power-ups to upgrade your weapons
	and increase your firepower!

	Survive increasingly difficult waves
	and achieve the highest score!"""

	instructions.add_theme_font_size_override("font_size", 18)
	instructions.add_theme_color_override("font_color", Color.WHITE)
	instructions.position = Vector2(30, 120)
	instructions.size = Vector2(440, 250)
	instruction_box.add_child(instructions)

	# Add blinking effect to main instruction
	_add_blinking_effect(instruction_title, 2.0)

func _create_transition_effects():
	"""Create transition effect overlays"""
	# Fade transition background
	var fade_bg = ColorRect.new()
	fade_bg.name = "FadeBG"
	fade_bg.color = Color.BLACK
	fade_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_bg.modulate.a = 0.0
	transition_overlay.add_child(fade_bg)

	# Loading/transition text
	var loading_label = Label.new()
	loading_label.name = "LoadingLabel"
	loading_label.text = "TRANSITIONING..."
	loading_label.add_theme_font_size_override("font_size", 48)
	loading_label.add_theme_color_override("font_color", Color.WHITE)
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loading_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loading_label.modulate.a = 0.0
	transition_overlay.add_child(loading_label)

func _setup_animations():
	"""Setup animation system"""
	transition_tween = create_tween()

# Overlay Management
func show_kiosk_overlay():
	"""Show the main kiosk overlay"""
	if is_overlay_visible:
		return

	print("KioskUI: Showing kiosk overlay")
	main_overlay.visible = true
	is_overlay_visible = true
	overlay_shown.emit("main")

	# Add to scene tree if needed
	if not get_tree().current_scene.has_node("KioskUI"):
		get_tree().current_scene.add_child(self)

func hide_kiosk_overlay():
	"""Hide the main kiosk overlay"""
	if not is_overlay_visible:
		return

	print("KioskUI: Hiding kiosk overlay")
	main_overlay.visible = false
	is_overlay_visible = false
	current_overlay = ""
	overlay_hidden.emit("main")

func show_demo_overlay():
	"""Show AI demo overlay"""
	_hide_all_sub_overlays()
	demo_overlay.visible = true
	current_overlay = "demo"
	overlay_shown.emit("demo")

func hide_demo_overlay():
	"""Hide AI demo overlay"""
	demo_overlay.visible = false
	if current_overlay == "demo":
		current_overlay = ""
	overlay_hidden.emit("demo")

func show_high_scores(scores: Array):
	"""Show high scores overlay with data"""
	_hide_all_sub_overlays()
	_populate_high_scores(scores)
	high_score_display.visible = true
	current_overlay = "high_scores"
	overlay_shown.emit("high_scores")

func hide_high_scores():
	"""Hide high scores overlay"""
	high_score_display.visible = false
	if current_overlay == "high_scores":
		current_overlay = ""
	overlay_hidden.emit("high_scores")

func show_instructions():
	"""Show instruction overlay"""
	_hide_all_sub_overlays()
	instruction_panel.visible = true
	current_overlay = "instructions"
	overlay_shown.emit("instructions")

func hide_instructions():
	"""Hide instruction overlay"""
	instruction_panel.visible = false
	if current_overlay == "instructions":
		current_overlay = ""
	overlay_hidden.emit("instructions")

func show_transition(text: String = "TRANSITIONING...", duration: float = 1.0):
	"""Show transition overlay with custom text"""
	var loading_label = transition_overlay.get_node("LoadingLabel")
	var fade_bg = transition_overlay.get_node("FadeBG")

	loading_label.text = text
	transition_overlay.visible = true

	# Animate transition in
	transition_tween = create_tween()
	transition_tween.set_parallel(true)
	transition_tween.tween_property(fade_bg, "modulate:a", 1.0, overlay_fade_duration * 0.5)
	transition_tween.tween_property(loading_label, "modulate:a", 1.0, overlay_fade_duration * 0.5)

	if duration > 0:
		transition_tween.tween_delay(duration)
		transition_tween.tween_property(fade_bg, "modulate:a", 0.0, overlay_fade_duration * 0.5)
		transition_tween.tween_property(loading_label, "modulate:a", 0.0, overlay_fade_duration * 0.5)
		transition_tween.tween_callback(func(): transition_overlay.visible = false)

func hide_transition():
	"""Hide transition overlay"""
	var loading_label = transition_overlay.get_node("LoadingLabel")
	var fade_bg = transition_overlay.get_node("FadeBG")

	transition_tween = create_tween()
	transition_tween.set_parallel(true)
	transition_tween.tween_property(fade_bg, "modulate:a", 0.0, overlay_fade_duration)
	transition_tween.tween_property(loading_label, "modulate:a", 0.0, overlay_fade_duration)
	transition_tween.tween_callback(func(): transition_overlay.visible = false)

func hide_all_interfaces():
	"""Hide all kiosk interfaces"""
	hide_kiosk_overlay()
	hide_transition()

func _hide_all_sub_overlays():
	"""Hide all sub-overlays within main overlay"""
	demo_overlay.visible = false
	high_score_display.visible = false
	instruction_panel.visible = false

# Data Management
func update_demo_stats(stats: Dictionary):
	"""Update demo overlay with AI performance statistics"""
	if not demo_overlay.visible:
		return

	var score_label = demo_overlay.get_node("DemoOverlay/Panel/VBoxContainer/ScoreLabel")
	var performance_label = demo_overlay.get_node("DemoOverlay/Panel/VBoxContainer/PerformanceLabel")

	if score_label and stats.has("final_score"):
		score_label.text = "Score: " + str(stats.final_score)

	if performance_label:
		var accuracy = stats.get("shots_hit", 0) * 100 / max(1, stats.get("total_shots_fired", 1))
		var efficiency = stats.get("efficiency_rating", 0.0) * 100
		performance_label.text = "Accuracy: %.1f%% | Efficiency: %.1f%%" % [accuracy, efficiency]

func _populate_high_scores(scores: Array):
	"""Populate high score display with score data"""
	var scores_list = high_score_display.get_node("ScoresScroll/ScoresList")

	# Clear existing scores
	for child in scores_list.get_children():
		child.queue_free()

	# Add new score entries
	for i in range(min(10, scores.size())):
		var score_data = scores[i]
		var rank = i + 1

		_create_score_entry(scores_list, score_data, rank)

func _create_score_entry(parent: Node, score_data: Dictionary, rank: int):
	"""Create a single score entry UI element"""
	var entry_panel = Panel.new()
	entry_panel.custom_minimum_size = Vector2(580, 50)

	# Different styling for top 3
	var is_top_three = rank <= 3
	var bg_color = Color(0.3, 0.6, 0.3, 0.9) if is_top_three else Color(0.2, 0.4, 0.2, 0.7)

	var style_box = StyleBoxFlat.new()
	style_box.bg_color = bg_color
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10

	if is_top_three:
		style_box.border_color = Color(1.0, 1.0, 0.6)
		style_box.border_width_left = 2
		style_box.border_width_right = 2
		style_box.border_width_top = 2
		style_box.border_width_bottom = 2

	entry_panel.add_theme_stylebox_override("panel", style_box)

	# Rank display
	var rank_label = Label.new()
	var rank_text = str(rank)
	if rank <= 3:
		rank_text = ["1st", "2nd", "3rd"][rank - 1]
	rank_label.text = rank_text
	rank_label.add_theme_font_size_override("font_size", 24 if is_top_three else 20)
	rank_label.add_theme_color_override("font_color", Color.WHITE)
	rank_label.position = Vector2(20, 12)
	rank_label.size = Vector2(60, 30)
	entry_panel.add_child(rank_label)

	# Player name
	var name_label = Label.new()
	name_label.text = score_data.name
	name_label.add_theme_font_size_override("font_size", 22 if is_top_three else 18)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.position = Vector2(90, 12)
	name_label.size = Vector2(200, 30)
	entry_panel.add_child(name_label)

	# Score
	var score_label = Label.new()
	score_label.text = str(score_data.score)
	score_label.add_theme_font_size_override("font_size", 22 if is_top_three else 18)
	score_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.position = Vector2(450, 12)
	score_label.size = Vector2(110, 30)
	entry_panel.add_child(score_label)

	parent.add_child(entry_panel)

	# Add entry animation
	entry_panel.modulate.a = 0.0
	entry_panel.scale = Vector2(0.8, 0.8)

	var entry_tween = create_tween()
	entry_tween.set_parallel(true)
	entry_tween.tween_property(entry_panel, "modulate:a", 1.0, 0.5)
	entry_tween.tween_property(entry_panel, "scale", Vector2(1.0, 1.0), 0.5)

func refresh_high_scores(scores: Array):
	"""Refresh high score display with updated data"""
	if high_score_display.visible:
		_populate_high_scores(scores)

# Visual Effects
func _add_floating_stars(parent: Control, count: int):
	"""Add floating star particle effects"""
	for i in range(count):
		var star = ColorRect.new()
		star.size = Vector2(2, 2)
		star.color = Color.WHITE
		star.position = Vector2(randf_range(0, 800), randf_range(0, 900))
		parent.add_child(star)

		var tween = create_tween()
		tween.set_loops()
		tween.parallel().tween_property(star, "position:y", star.position.y - 50, randf_range(5, 10))
		tween.parallel().tween_property(star, "modulate:a", 0.0, randf_range(5, 10))
		tween.tween_callback(func():
			star.position.y = 900
			star.position.x = randf_range(0, 800)
			star.modulate.a = 1.0
		)

func _add_pulsing_effect(node: Control, color_a: Color, color_b: Color, duration: float):
	"""Add pulsing color effect to a node"""
	var tween = create_tween()
	tween.set_loops()
	# Use tween_property instead of tween_method for simpler color tweening
	tween.tween_property(node, "modulate", color_b, duration)
	tween.tween_property(node, "modulate", color_a, duration)

func _add_glow_effect(label: Label, glow_color: Color):
	"""Add glowing text effect"""
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(label, "modulate", glow_color * 1.2, 2.0)
	tween.tween_property(label, "modulate", glow_color * 0.8, 2.0)

func _add_blinking_effect(node: Control, blink_speed: float):
	"""Add blinking effect to a node"""
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(node, "modulate:a", 0.3, blink_speed)
	tween.tween_property(node, "modulate:a", 1.0, blink_speed)

# Public API
func is_visible() -> bool:
	"""Check if any kiosk UI is currently visible"""
	return is_overlay_visible

func get_current_overlay() -> String:
	"""Get currently visible overlay type"""
	return current_overlay

func set_color_scheme(scheme_name: String, colors: Dictionary):
	"""Set custom color scheme"""
	color_schemes[scheme_name] = colors

func animate_text_reveal(text_node: Label, duration: float = 2.0):
	"""Animate text reveal effect"""
	if not text_node:
		return

	var original_text = text_node.text
	text_node.text = ""

	var tween = create_tween()
	var char_count = original_text.length()

	for i in range(char_count):
		tween.tween_callback(func(): text_node.text = original_text.substr(0, i + 1))
		tween.tween_delay(duration / char_count)

func _exit_tree():
	"""Cleanup on exit"""
	if transition_tween:
		transition_tween.kill()