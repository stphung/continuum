class_name VulcanPatterns
extends RefCounted

## Collection of all vulcan weapon patterns
## Each pattern corresponds to a weapon level (1-20)

## Single shot pattern (Level 1)
class SingleShotPattern extends WeaponPattern:
	func get_bullet_configs() -> Array[BulletConfig]:
		return [BulletConfig.new(Vector2.ZERO, Vector2.UP, "center")]

## Dual shot pattern (Level 2)
class DualShotPattern extends WeaponPattern:
	func get_bullet_configs() -> Array[BulletConfig]:
		return [
			BulletConfig.new(Vector2.ZERO, Vector2.UP, "left"),
			BulletConfig.new(Vector2.ZERO, Vector2.UP, "right")
		]

## Spread shot pattern (Level 3)
class SpreadShotPattern extends WeaponPattern:
	func get_bullet_configs() -> Array[BulletConfig]:
		return [
			BulletConfig.new(Vector2.ZERO, Vector2.UP, "center"),
			BulletConfig.new(Vector2.ZERO, Vector2(-0.1, -1).normalized(), "left"),
			BulletConfig.new(Vector2.ZERO, Vector2(0.1, -1).normalized(), "right")
		]

## Wide spread pattern (Level 4)
class WideSpreadPattern extends WeaponPattern:
	func get_bullet_configs() -> Array[BulletConfig]:
		return [
			BulletConfig.new(Vector2.ZERO, Vector2.UP, "center"),
			BulletConfig.new(Vector2.ZERO, Vector2(-0.2, -1).normalized(), "left"),
			BulletConfig.new(Vector2.ZERO, Vector2(0.2, -1).normalized(), "right"),
			BulletConfig.new(Vector2.ZERO, Vector2(-0.1, -1).normalized(), "left"),
			BulletConfig.new(Vector2.ZERO, Vector2(0.1, -1).normalized(), "right")
		]

## Arc-based pattern for higher levels
class ArcPattern extends WeaponPattern:
	var bullet_count: int
	var arc_width: float
	var use_center_bullets: bool

	func _init(bullets: int, width: float, center: bool = true):
		bullet_count = bullets
		arc_width = width
		use_center_bullets = center

	func get_bullet_configs() -> Array[BulletConfig]:
		var configs: Array[BulletConfig] = []

		if bullet_count == 1:
			configs.append(BulletConfig.new(Vector2.ZERO, Vector2.UP, "center"))
			return configs

		# Generate arc pattern
		for i in range(bullet_count):
			var angle = -arc_width/2 + (i * arc_width / (bullet_count - 1))
			var direction = Vector2(angle, -1).normalized()
			var muzzle_type = get_muzzle_for_angle(angle)
			configs.append(BulletConfig.new(Vector2.ZERO, direction, muzzle_type))

		return configs

	func get_muzzle_for_angle(angle: float) -> String:
		if abs(angle) < 0.15:
			return "center"
		elif angle < 0:
			return "left"
		else:
			return "right"

## Factory class to create weapon patterns
static func create_pattern_for_level(level: int) -> WeaponPattern:
	match level:
		1:
			return SingleShotPattern.new()
		2:
			return DualShotPattern.new()
		3:
			return SpreadShotPattern.new()
		4:
			return WideSpreadPattern.new()
		5:
			return ArcPattern.new(5, 0.6)
		6:
			return ArcPattern.new(6, 0.6)
		7:
			return ArcPattern.new(7, 0.8)
		8:
			return ArcPattern.new(8, 0.9)
		9:
			return ArcPattern.new(9, 1.0)
		10:
			return ArcPattern.new(10, 1.2)
		11:
			return ArcPattern.new(11, 0.7)
		12:
			return ArcPattern.new(12, 0.7)
		13:
			return ArcPattern.new(13, 0.7)
		14:
			return ArcPattern.new(14, 0.75)
		15:
			return ArcPattern.new(15, 0.75)
		16:
			return ArcPattern.new(16, 0.75)
		17:
			return ArcPattern.new(17, 0.8)
		18:
			return ArcPattern.new(18, 0.8)
		19:
			return ArcPattern.new(19, 0.8)
		20, _:
			return ArcPattern.new(20, 0.9)  # Maximum firepower