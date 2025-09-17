class_name WeaponPattern
extends RefCounted

## Base class for weapon firing patterns
## Provides a strategy pattern for different weapon behaviors

## Configuration data for a bullet shot
class BulletConfig:
	var position_offset: Vector2 = Vector2.ZERO
	var direction: Vector2 = Vector2.UP
	var muzzle_type: String = "center"  # "center", "left", "right"

	func _init(pos_offset: Vector2 = Vector2.ZERO, dir: Vector2 = Vector2.UP, muzzle: String = "center"):
		position_offset = pos_offset
		direction = dir
		muzzle_type = muzzle

## Abstract method - must be implemented by subclasses
func get_bullet_configs() -> Array[BulletConfig]:
	assert(false, "WeaponPattern.get_bullet_configs() must be implemented by subclass")
	return []

## Execute the firing pattern for the given player
func fire(player: Node2D) -> void:
	var configs = get_bullet_configs()

	for config in configs:
		var muzzle_position = get_muzzle_position(player, config.muzzle_type)
		player.shoot.emit(muzzle_position, config.direction, "vulcan")

## Get the appropriate muzzle position based on type
func get_muzzle_position(player: Node2D, muzzle_type: String) -> Vector2:
	match muzzle_type:
		"left":
			return player.get_node("LeftMuzzle").global_position
		"right":
			return player.get_node("RightMuzzle").global_position
		"center", _:
			return player.get_node("MuzzlePosition").global_position