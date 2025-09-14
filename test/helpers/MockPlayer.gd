extends Node
## Mock Player for testing AI Demo functionality

signal player_hit(damage: int)
signal player_died

var health: int = 100
var position: Vector2 = Vector2(400, 800)
var weapon_level: int = 1
var invulnerable: bool = false

func take_damage(amount: int):
	"""Mock damage taking"""
	if invulnerable:
		return

	health -= amount
	player_hit.emit(amount)

	if health <= 0:
		health = 0
		player_died.emit()

func heal(amount: int):
	"""Mock healing"""
	health = min(100, health + amount)

func upgrade_weapon():
	"""Mock weapon upgrade"""
	weapon_level = min(5, weapon_level + 1)

func set_position(new_pos: Vector2):
	"""Mock position setting"""
	position = new_pos

func get_position() -> Vector2:
	"""Mock position getting"""
	return position

func set_invulnerable(state: bool, duration: float = 0.0):
	"""Mock invulnerability"""
	invulnerable = state
	if duration > 0.0:
		var timer = get_tree().create_timer(duration)
		timer.timeout.connect(func(): invulnerable = false)

func is_alive() -> bool:
	"""Check if player is alive"""
	return health > 0