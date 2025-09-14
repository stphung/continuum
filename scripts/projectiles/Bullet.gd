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
		area.take_damage(damage)
		call_deferred("queue_free")

func _on_screen_exited():
	call_deferred("queue_free")