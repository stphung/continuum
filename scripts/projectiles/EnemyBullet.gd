extends Area2D

@export var speed = 300
var direction = Vector2.DOWN

func _ready():
	add_to_group("enemy_bullets")

func _process(delta):
	position += direction * speed * delta

func _on_screen_exited():
	call_deferred("queue_free")