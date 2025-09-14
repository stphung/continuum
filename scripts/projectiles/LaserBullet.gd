extends Area2D

@export var speed = 1200
@export var damage = 3
@export var pierce_count = 2

var direction = Vector2.UP
var enemies_hit = 0
var weapon_level = 1

func _ready():
	add_to_group("player_bullets")
	
	# Scale properties based on weapon level
	damage = 3 + weapon_level
	pierce_count = 1 + weapon_level
	
	# Scale visual size based on level
	var scale_factor = 1.0 + (weapon_level - 1) * 0.2
	$Sprite.scale = Vector2(scale_factor, scale_factor)
	$Glow.scale = Vector2(scale_factor, scale_factor)
	$Core.scale = Vector2(scale_factor, scale_factor)
	
	# Add pulsing glow effect
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property($Glow, "modulate:a", 0.6, 0.2)
	tween.tween_property($Glow, "modulate:a", 0.2, 0.2)

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