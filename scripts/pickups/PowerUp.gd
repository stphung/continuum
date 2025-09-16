extends Area2D

@export var fall_speed = 80
@export var powerup_type = "weapon_upgrade"
@export var drift_speed = 40.0
@export var wave_amplitude = 20.0

var time_alive = 0.0
var drift_direction: Vector2
var wave_offset: float
var screen_size: Vector2

var powerup_colors = {
	"vulcan_powerup": Color(1, 0.1, 0.1, 1),     # Bright red for vulcan
	"chain_powerup": Color(0.6, 0.2, 1, 1),      # Purple for chain
	"bomb": Color(1, 0.9, 0.1, 1),               # Bright yellow for bomb
	"life": Color(0.2, 1, 0.2, 1)                # Bright green for life
}

var powerup_letters = {
	"vulcan_powerup": "V",    # V for vulcan
	"chain_powerup": "C",     # C for chain
	"bomb": "B",              # B for bomb
	"life": "L"               # L for life (changed from "1")
}

func _ready():
	add_to_group("powerups")
	screen_size = get_viewport_rect().size
	randomize_type()
	update_appearance()
	_setup_floating_animation()

func _setup_floating_animation():
	# Random drift direction (more horizontal movement)
	drift_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-0.3, 0.1))
	drift_direction = drift_direction.normalized()

	# Random wave pattern offset so power-ups don't move in sync
	wave_offset = randf_range(0, TAU)

	# Rotating animation
	var rotation_tween = create_tween()
	rotation_tween.set_loops()
	rotation_tween.tween_property(self, "rotation", TAU, randf_range(1.5, 3.0))

	# Gentle pulsing scale animation
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(self, "scale", Vector2(1.1, 1.1), randf_range(1.0, 2.0))
	pulse_tween.tween_property(self, "scale", Vector2(1.0, 1.0), randf_range(1.0, 2.0))

func randomize_type():
	var types = ["vulcan_powerup", "chain_powerup", "bomb", "life"]
	var weights = [0.425, 0.425, 0.10, 0.05]  # Higher chance for weapons (85% combined), bomb 10%, life 5%

	var rand = randf()
	var cumulative = 0.0

	for i in range(types.size()):
		cumulative += weights[i]
		if rand <= cumulative:
			powerup_type = types[i]
			break

func update_appearance():
	if not powerup_type in powerup_colors:
		return

	var color = powerup_colors[powerup_type]

	# Hide the background for outlined shapes
	$CircleBackground.visible = false

	# Set the appropriate shape based on powerup type
	match powerup_type:
		"vulcan_powerup", "chain_powerup":
			# Square shape for weapons
			set_square_shape(color)
			add_glow_effect(color)
		"bomb":
			# Triangle shape for bomb
			set_triangle_shape(color)
		"life":
			# Circle shape for life
			set_circle_shape(color)

	# Set the letter text
	if powerup_type in powerup_letters:
		$LetterLabel.text = powerup_letters[powerup_type]
		$LetterLabel.modulate = Color.WHITE

func set_square_shape(color: Color):
	# Create square polygon
	var size = 18
	$CircleSprite.polygon = PackedVector2Array([
		Vector2(-size, -size),
		Vector2(size, -size),
		Vector2(size, size),
		Vector2(-size, size)
	])
	$CircleSprite.color = Color(0, 0, 0, 0)  # Transparent fill

	# Create square outline
	$OutlineRing.polygon = PackedVector2Array([
		# Outer square
		Vector2(-size-2, -size-2),
		Vector2(size+2, -size-2),
		Vector2(size+2, size+2),
		Vector2(-size-2, size+2),
		Vector2(-size-2, -size-2),
		# Inner square (creates the outline)
		Vector2(-size, -size),
		Vector2(-size, size),
		Vector2(size, size),
		Vector2(size, -size),
		Vector2(-size, -size)
	])
	$OutlineRing.color = color

func set_triangle_shape(color: Color):
	# Create triangle polygon
	var size = 20
	$CircleSprite.polygon = PackedVector2Array([
		Vector2(0, -size),
		Vector2(size * 0.866, size * 0.5),  # 60 degree angle
		Vector2(-size * 0.866, size * 0.5)
	])
	$CircleSprite.color = Color(0, 0, 0, 0)  # Transparent fill

	# Create triangle outline
	var outline_size = size + 2
	$OutlineRing.polygon = PackedVector2Array([
		# Outer triangle
		Vector2(0, -outline_size),
		Vector2(outline_size * 0.866, outline_size * 0.5),
		Vector2(-outline_size * 0.866, outline_size * 0.5),
		Vector2(0, -outline_size),
		# Inner triangle (creates the outline)
		Vector2(0, -size),
		Vector2(-size * 0.866, size * 0.5),
		Vector2(size * 0.866, size * 0.5),
		Vector2(0, -size)
	])
	$OutlineRing.color = color

func set_circle_shape(color: Color):
	# Create circle polygon (16 points)
	var points = PackedVector2Array()
	var outline_points = PackedVector2Array()
	var radius = 18
	var outline_radius = radius + 2

	for i in range(16):
		var angle = i * TAU / 16
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))

	# Create outline
	for i in range(16):
		var angle = i * TAU / 16
		outline_points.append(Vector2(cos(angle) * outline_radius, sin(angle) * outline_radius))

	# Add inner circle to create outline effect
	for i in range(16):
		var angle = (15 - i) * TAU / 16
		outline_points.append(Vector2(cos(angle) * radius, sin(angle) * radius))

	$CircleSprite.polygon = points
	$CircleSprite.color = Color(0, 0, 0, 0)  # Transparent fill
	$OutlineRing.polygon = outline_points
	$OutlineRing.color = color

func add_glow_effect(color: Color):
	# Create a glow effect for weapon powerups
	# We'll use the CircleBackground as a glow layer
	$CircleBackground.visible = true
	$CircleBackground.color = Color(color.r, color.g, color.b, 0.3)
	$CircleBackground.offset_left = -25
	$CircleBackground.offset_top = -25
	$CircleBackground.offset_right = 25
	$CircleBackground.offset_bottom = 25

	# Add pulsing glow animation
	var glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property($CircleBackground, "modulate:a", 0.6, 0.8)
	glow_tween.tween_property($CircleBackground, "modulate:a", 0.3, 0.8)

func _process(delta):
	time_alive += delta

	# Primary downward movement (slower than before)
	position.y += fall_speed * delta

	# Smooth wave-like horizontal drifting
	var wave_x = sin(time_alive * 1.2 + wave_offset) * wave_amplitude * delta
	var wave_y = cos(time_alive * 0.8 + wave_offset) * wave_amplitude * 0.3 * delta

	# Apply drift movement in the chosen direction
	var drift_movement = drift_direction * drift_speed * delta

	# Combine wave motion with drift for natural floating
	position.x += drift_movement.x + wave_x
	position.y += drift_movement.y + wave_y

	# Add some gentle randomness for organic movement
	if randf() < 0.02:  # 2% chance per frame
		drift_direction += Vector2(randf_range(-0.1, 0.1), randf_range(-0.05, 0.05))
		drift_direction = drift_direction.normalized() * 0.8  # Dampen over time

	# Bounce off screen edges
	var margin = 20  # Distance from edge to trigger bounce
	var bounce_damping = 0.8  # Reduce speed slightly on bounce

	# Check left and right boundaries
	if position.x <= margin:
		position.x = margin
		drift_direction.x = abs(drift_direction.x) * bounce_damping
		# Add a little randomness to the bounce
		drift_direction.y += randf_range(-0.2, 0.2)
		drift_direction = drift_direction.normalized()
	elif position.x >= screen_size.x - margin:
		position.x = screen_size.x - margin
		drift_direction.x = -abs(drift_direction.x) * bounce_damping
		drift_direction.y += randf_range(-0.2, 0.2)
		drift_direction = drift_direction.normalized()

	# Check top and bottom boundaries
	if position.y <= margin:
		position.y = margin
		drift_direction.y = abs(drift_direction.y) * bounce_damping
		drift_direction.x += randf_range(-0.2, 0.2)
		drift_direction = drift_direction.normalized()
	elif position.y >= screen_size.y - margin:
		position.y = screen_size.y - margin
		drift_direction.y = -abs(drift_direction.y) * bounce_damping
		drift_direction.x += randf_range(-0.2, 0.2)
		drift_direction = drift_direction.normalized()

func _on_life_timer_timeout():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.5)
	tween.tween_callback(queue_free)

# Power-ups now bounce off screen edges instead of being destroyed