extends Area2D

@export var fall_speed = 80
@export var powerup_type = "weapon_upgrade"
@export var drift_speed = 40.0
@export var wave_amplitude = 20.0

var time_alive = 0.0
var drift_direction: Vector2
var wave_offset: float

var powerup_colors = {
	"vulcan_powerup": Color(1, 0, 0, 1),      # Red for vulcan
	"laser_powerup": Color(0, 0.5, 1, 1),     # Blue for laser
	"chain_powerup": Color(0.8, 0.9, 1, 1),   # Electric blue-white for chain
	"bomb": Color(1, 1, 0, 1),                # Yellow for bomb
	"life": Color(0, 1, 0, 1)                 # Green for life
}

var powerup_letters = {
	"vulcan_powerup": "V",    # V for vulcan
	"laser_powerup": "L",     # L for laser
	"chain_powerup": "C",     # C for chain
	"bomb": "B",              # B for bomb
	"life": "1"               # 1 for extra life
}

func _ready():
	add_to_group("powerups")
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
	var types = ["vulcan_powerup", "laser_powerup", "chain_powerup", "bomb", "life"]
	var weights = [0.25, 0.25, 0.25, 0.15, 0.1]  # Equal chance for each weapon, less for bomb/life

	var rand = randf()
	var cumulative = 0.0

	for i in range(types.size()):
		cumulative += weights[i]
		if rand <= cumulative:
			powerup_type = types[i]
			break

func update_appearance():
	if powerup_type in powerup_colors:
		# Update all circle elements to the same color
		$CircleSprite.color = powerup_colors[powerup_type]
		$CircleBackground.color = powerup_colors[powerup_type]
		
		# Set the letter text
		if powerup_type in powerup_letters:
			$LetterLabel.text = powerup_letters[powerup_type]

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

func _on_life_timer_timeout():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.5)
	tween.tween_callback(queue_free)

func _on_screen_exited():
	call_deferred("queue_free")