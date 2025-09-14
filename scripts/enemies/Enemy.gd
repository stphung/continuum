extends Area2D

signal enemy_destroyed(points, position)

@export var health = 3
@export var speed = 150
@export var points = 100
@export var movement_pattern = "straight"

var direction = Vector2.DOWN
var time_alive = 0.0
var initial_x

func _ready():
	add_to_group("enemies")
	initial_x = position.x
	$ShootTimer.wait_time = randf_range(1.5, 3.0)

func _process(delta):
	time_alive += delta
	
	match movement_pattern:
		"straight":
			position += direction * speed * delta
		"zigzag":
			position.y += speed * delta
			position.x = initial_x + sin(time_alive * 3) * 100
		"dive":
			var player = get_tree().get_first_node_in_group("player")
			if player and position.y > 200:
				direction = (player.position - position).normalized()
			position += direction * speed * delta
		_:
			position += direction * speed * delta

func take_damage(damage):
	health -= damage
	
	# Play enemy hit sound
	if has_node("/root/SoundManager"):
		SoundManager.play_random_pitch("enemy_hit", -12.0, 0.2)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)
	tween.tween_property(self, "modulate", Color(1, 0.5, 0.5, 1), 0.1)
	
	if health <= 0:
		destroy()

func destroy():
	# Play enemy destruction sound
	if has_node("/root/SoundManager"):
		SoundManager.play_random_pitch("enemy_destroy", -8.0, 0.15)
	
	enemy_destroyed.emit(points, position)
	queue_free()

func _on_area_entered(area):
	if area.is_in_group("player_bullets"):
		take_damage(1)

func _on_screen_exited():
	queue_free()

func _on_shoot_timer_timeout():
	shoot()

func shoot():
	var bullet_scene = preload("res://scenes/projectiles/EnemyBullet.tscn") if ResourceLoader.exists("res://scenes/projectiles/EnemyBullet.tscn") else null
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		bullet.position = position + Vector2(0, 20)
		get_parent().get_parent().get_node("Bullets").add_child(bullet)