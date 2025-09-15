extends Area2D

@export var speed = 1200
@export var damage = 3
@export var pierce_count = 2

var direction = Vector2.UP
var enemies_hit = 0
var weapon_level = 1

func _ready():
	add_to_group("player_bullets")

	# Scale properties based on weapon level - much more powerful now
	damage = 4 + (weapon_level * 2)  # Level 1: 6 damage, Level 5: 14 damage
	pierce_count = 2 + weapon_level  # Level 1: 3 pierce, Level 5: 7 pierce
	
	# Scale beam width dramatically based on level
	setup_beam_visuals()
	
	# Add pulsing glow effect
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property($Glow, "modulate:a", 0.6, 0.2)
	tween.tween_property($Glow, "modulate:a", 0.2, 0.2)

func setup_beam_visuals():
	# Calculate beam width: 6px → 48px progression
	var beam_width = 3 + (weapon_level - 1) * 11.25  # Half-width for polygon
	var glow_width = beam_width + 4  # Glow extends beyond main beam
	var core_width = max(1, beam_width * 0.3)  # Core is 30% of beam width

	# Update main beam polygon
	$Sprite.polygon = PackedVector2Array([
		Vector2(-beam_width, -10),
		Vector2(-beam_width, 10),
		Vector2(beam_width, 10),
		Vector2(beam_width, -10)
	])

	# Update glow polygon (wider and longer)
	$Glow.polygon = PackedVector2Array([
		Vector2(-glow_width, -12),
		Vector2(-glow_width, 12),
		Vector2(glow_width, 12),
		Vector2(glow_width, -12)
	])

	# Update core polygon (bright center)
	$Core.polygon = PackedVector2Array([
		Vector2(-core_width, -8),
		Vector2(-core_width, 8),
		Vector2(core_width, 8),
		Vector2(core_width, -8)
	])

	# Adjust collision shape to match beam width
	var collision_shape = $CollisionShape2D.shape as CapsuleShape2D
	collision_shape.radius = beam_width

	# Enhanced visual effects for higher levels
	if weapon_level >= 3:
		$Glow.modulate = Color(0.3, 0.7, 1.0, 0.4)  # Brighter blue glow
	if weapon_level >= 4:
		$Sprite.modulate = Color(1.2, 1.2, 1.0, 1.0)  # Slightly overbrightened
	if weapon_level >= 5:
		$Core.modulate = Color(1.5, 1.5, 1.5, 1.0)  # Super bright core

func _process(delta):
	position += direction * speed * delta

func _on_area_entered(area):
	if area.is_in_group("enemies"):
		area.take_damage(damage)
		enemies_hit += 1
		
		# Create impact effect
		create_impact_effect()
		
		# Pierce through multiple enemies
		if enemies_hit >= pierce_count:
			call_deferred("queue_free")

func create_impact_effect():
	var flash = CPUParticles2D.new()
	flash.position = position
	flash.emitting = true
	flash.amount = 8
	flash.lifetime = 0.2
	flash.one_shot = true
	flash.initial_velocity_min = 50
	flash.initial_velocity_max = 150
	flash.scale_amount_min = 0.3
	flash.scale_amount_max = 0.8
	flash.color = Color(0, 1, 1, 1)
	get_parent().add_child(flash)
	
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.timeout.connect(flash.call_deferred.bind("queue_free"))
	flash.add_child(timer)
	timer.start()

func _on_screen_exited():
	call_deferred("queue_free")