extends Area2D

@export var speed = 800
@export var damage = 1

var direction = Vector2.UP

func _ready():
	add_to_group("player_bullets")

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

func _on_screen_exited():
	call_deferred("queue_free")