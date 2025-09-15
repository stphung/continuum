extends Node2D
class_name StarfieldBackground

## StarfieldBackground - Reusable Animated Starfield Component
## Extracted from Game.gd for use across multiple scenes (Title Screen, Game, etc.)
## Part of the Continuum Professional Title Screen System

# Configuration parameters
@export var star_count: int = 50
@export var star_speed: float = 100.0
@export var min_star_size: float = 1.0
@export var max_star_size: float = 3.0
@export var min_alpha: float = 0.3
@export var max_alpha: float = 0.8
@export var screen_width: float = 720.0
@export var screen_height: float = 1280.0
@export var star_color: Color = Color.WHITE
@export var animated: bool = true

# Internal state
var stars: Array[ColorRect] = []
var stars_container: Node2D

signal starfield_initialized()

func _ready():
	# Create container for stars
	stars_container = Node2D.new()
	stars_container.name = "StarsContainer"
	add_child(stars_container)

	# Auto-detect viewport dimensions if they seem incorrect
	update_to_viewport_size()

	# Initialize the starfield
	create_starfield()

	# Emit ready signal
	starfield_initialized.emit()

func create_starfield():
	"""Create the complete starfield with configured parameters"""
	clear_starfield()

	for i in range(star_count):
		_create_single_star()

func _create_single_star() -> ColorRect:
	"""Create and configure a single star"""
	var star = ColorRect.new()

	# Random size within configured range
	var size = randf_range(min_star_size, max_star_size)
	star.size = Vector2(size, size)

	# Random position across screen
	star.position = Vector2(
		randf_range(0, screen_width),
		randf_range(0, screen_height)
	)

	# Random alpha for twinkling effect (affects speed calculation too)
	var alpha = randf_range(min_alpha, max_alpha)
	star.color = Color(star_color.r, star_color.g, star_color.b, alpha)

	# Add to scene and track
	stars_container.add_child(star)
	stars.append(star)

	return star

func clear_starfield():
	"""Remove all existing stars and clean up resources"""
	# Clean up existing stars
	for star in stars:
		if is_instance_valid(star):
			star.get_parent().remove_child(star)
			star.queue_free()
	stars.clear()

	# Clear container children
	if stars_container:
		for child in stars_container.get_children():
			stars_container.remove_child(child)
			child.queue_free()

func _process(delta):
	if animated and stars.size() > 0:
		update_starfield_animation(delta)

func update_starfield_animation(delta: float):
	"""Update star positions for scrolling animation"""
	for star in stars:
		if not is_instance_valid(star):
			continue

		# Move star down at speed influenced by alpha (brighter = faster)
		var speed_multiplier = star.color.a
		star.position.y += star_speed * speed_multiplier * delta

		# Wrap star to top when it goes off bottom
		if star.position.y > screen_height:
			star.position.y = -10
			star.position.x = randf_range(0, screen_width)

func set_star_count(new_count: int):
	"""Dynamically change the number of stars"""
	if new_count == star_count:
		return

	star_count = new_count
	create_starfield()

func set_star_speed(new_speed: float):
	"""Change the animation speed of stars"""
	star_speed = new_speed

func set_animated(is_animated: bool):
	"""Enable or disable star animation"""
	animated = is_animated

func pause_animation():
	"""Pause starfield animation"""
	set_animated(false)

func resume_animation():
	"""Resume starfield animation"""
	set_animated(true)

func set_screen_dimensions(width: float, height: float):
	"""Update screen dimensions for proper star positioning"""
	screen_width = width
	screen_height = height

	# Recreate starfield to properly fill new dimensions
	create_starfield()

func add_stars(count: int):
	"""Add additional stars to the existing starfield"""
	for i in range(count):
		_create_single_star()
	star_count = stars.size()

func remove_stars(count: int):
	"""Remove stars from the starfield"""
	var to_remove = mini(count, stars.size())

	for i in range(to_remove):
		var star = stars.pop_back()
		if is_instance_valid(star):
			star.queue_free()

	star_count = stars.size()

func set_star_color(color: Color):
	"""Change the color of all stars"""
	star_color = color

	# Update existing stars while preserving alpha values
	for star in stars:
		if is_instance_valid(star):
			var current_alpha = star.color.a
			star.color = Color(color.r, color.g, color.b, current_alpha)

func create_twinkling_effect():
	"""Add a subtle twinkling effect to random stars"""
	var stars_to_twinkle = mini(5, stars.size())

	for i in range(stars_to_twinkle):
		var star = stars[randi() % stars.size()]
		if not is_instance_valid(star):
			continue

		var tween = create_tween()
		tween.set_loops()

		var original_alpha = star.color.a
		var dim_alpha = original_alpha * 0.3

		tween.tween_property(star, "color:a", dim_alpha, 0.5)
		tween.tween_property(star, "color:a", original_alpha, 0.5)

func reset_starfield():
	"""Reset the starfield to initial state"""
	create_starfield()

func update_to_viewport_size():
	"""Auto-detect and use current viewport dimensions"""
	var viewport = get_viewport()
	if viewport:
		var viewport_size = viewport.get_visible_rect().size
		set_screen_dimensions(viewport_size.x, viewport_size.y)

# Utility methods for external control
func get_star_count() -> int:
	"""Get current number of stars"""
	return stars.size()

func is_animation_active() -> bool:
	"""Check if starfield animation is currently active"""
	return animated