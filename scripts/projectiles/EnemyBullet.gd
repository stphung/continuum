extends Area2D

@export var speed = 400  # Increased from 300
var direction = Vector2.DOWN
var is_aimed = false
var is_tracking = false
var is_spread = false
var is_sniper = false
var tracking_time = 0.0
var max_tracking_time = 1.5  # Track for 1.5 seconds
var target = null

func _ready():
	add_to_group("enemy_bullets")

	# Create visual representation
	if not has_node("Sprite"):
		var sprite = Polygon2D.new()
		sprite.name = "Sprite"
		sprite.polygon = PackedVector2Array([
			Vector2(0, -6), Vector2(-3, 0), Vector2(-2, 4),
			Vector2(0, 6), Vector2(2, 4), Vector2(3, 0)
		])
		add_child(sprite)

	# Enhanced color system based on bullet type and behavior
	if has_node("Sprite"):
		if is_tracking:
			$Sprite.color = Color(0.9, 0.1, 0.9, 1)  # Bright purple for tracking
		elif is_sniper:
			$Sprite.color = Color(0.3, 0.7, 1.0, 1)  # Bright blue for sniper/fast
		elif is_spread:
			$Sprite.color = Color(1.0, 0.5, 0.2, 1)  # Orange for spread pattern
		elif is_aimed:
			$Sprite.color = Color(1.0, 0.2, 0.2, 1)  # Bright red for aimed
		else:
			$Sprite.color = Color(1.0, 1.0, 0.3, 1)  # Bright yellow for normal

func _process(delta):
	# Handle tracking bullets
	if is_tracking and target and is_instance_valid(target):
		tracking_time += delta
		if tracking_time < max_tracking_time:
			# Gradually turn toward player
			var to_target = (target.position - position).normalized()
			direction = direction.lerp(to_target, delta * 2.0)  # Smooth tracking
			direction = direction.normalized()
			rotation = direction.angle() + PI/2

	position += direction * speed * delta

func _on_screen_exited():
	call_deferred("queue_free")

func set_aimed_at_player(player_pos: Vector2):
	# Calculate direction to player
	is_aimed = true
	direction = (player_pos - position).normalized()
	rotation = direction.angle() + PI/2

func set_tracking(player_node):
	# Enable tracking mode
	is_tracking = true
	target = player_node
	if target:
		direction = (target.position - position).normalized()
		rotation = direction.angle() + PI/2

func set_spread():
	# Mark as spread pattern bullet
	is_spread = true

func set_sniper():
	# Mark as high-speed sniper bullet
	is_sniper = true
	speed = 600  # Faster than normal bullets