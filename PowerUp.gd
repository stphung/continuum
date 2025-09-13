extends Area2D

@export var fall_speed = 100
@export var powerup_type = "weapon_upgrade"

var powerup_colors = {
	"weapon_upgrade": Color(1, 0, 0, 1),
	"weapon_switch": Color(0, 0, 1, 1),
	"bomb": Color(1, 1, 0, 1),
	"life": Color(0, 1, 0, 1)
}

var powerup_letters = {
	"weapon_upgrade": "P",
	"weapon_switch": "L",
	"bomb": "B",
	"life": "1"
}

func _ready():
	add_to_group("powerups")
	randomize_type()
	update_appearance()
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "rotation", TAU, 2.0)

func randomize_type():
	var types = ["weapon_upgrade", "weapon_switch", "bomb", "life"]
	var weights = [0.4, 0.3, 0.2, 0.1]
	
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
	position.y += fall_speed * delta

func _on_life_timer_timeout():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.5)
	tween.tween_callback(queue_free)

func _on_screen_exited():
	queue_free()