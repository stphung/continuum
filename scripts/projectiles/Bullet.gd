extends Area2D

@export var speed = 800
@export var damage = 1

var direction = Vector2.UP
var weapon_level = 1

func _ready():
	add_to_group("player_bullets")

	# Scale damage based on weapon level (every 5 levels)
	if weapon_level >= 20:
		damage = 5  # Level 20: 5x damage
	elif weapon_level >= 15:
		damage = 4  # Level 15-19: 4x damage
	elif weapon_level >= 10:
		damage = 3  # Level 10-14: 3x damage
	elif weapon_level >= 5:
		damage = 2  # Level 5-9: 2x damage
	else:
		damage = 1  # Level 1-4: 1x damage

	# Update bullet color based on damage level
	update_bullet_color()

func _process(delta):
	position += direction * speed * delta

func _on_area_entered(area):
	if area.is_in_group("enemies"):
		# Only damage enemies that are visible on screen
		if area.has_method("is_visible_for_damage") and area.is_visible_for_damage():
			area.take_damage(damage)
			call_deferred("queue_free")
		elif not area.has_method("is_visible_for_damage"):
			# Fallback for any enemies without the new method
			area.take_damage(damage)
			call_deferred("queue_free")

func update_bullet_color():
	# Change bullet color based on damage level
	# Yellow -> Orange -> Red -> Purple -> Blue (increasing damage)
	match damage:
		1:
			modulate = Color(1, 1, 0.4, 1)     # Yellow (Level 1-4)
		2:
			modulate = Color(1, 0.7, 0.2, 1)   # Orange (Level 5-9)
		3:
			modulate = Color(1, 0.3, 0.2, 1)   # Red (Level 10-14)
		4:
			modulate = Color(0.8, 0.2, 1, 1)   # Purple (Level 15-19)
		5:
			modulate = Color(0.2, 0.6, 1, 1)   # Blue (Level 20)

func _on_screen_exited():
	call_deferred("queue_free")