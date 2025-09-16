extends Resource

class_name EnemyTypeData

@export var enemy_name: String = ""
@export var base_health: int = 1
@export var base_speed: float = 150.0
@export var base_points: int = 100
@export var movement_pattern: String = "straight"
@export var weapon_type: String = "none"
@export var fire_rate: float = 2.0
@export var damage_reduction: float = 0.0  # 0.0 = normal damage, 0.5 = 50% damage reduction
@export var special_abilities: Array[String] = []

# Visual properties
@export var sprite_color: Color = Color.RED
@export var sprite_polygon: PackedVector2Array = PackedVector2Array()
@export var collision_radius: float = 20.0
@export var sprite_scale: float = 1.0

# Advanced properties
@export var spawn_weight: float = 1.0  # Probability weight for spawning
@export var min_wave: int = 1  # Minimum wave for this enemy to appear
@export var max_simultaneous: int = -1  # -1 = no limit
@export var spawns_enemies: bool = false
@export var spawned_enemy_type: String = ""

# Sound effects
@export var hit_sound: String = "enemy_hit"
@export var destroy_sound: String = "enemy_destroy"
@export var attack_sound: String = ""

func get_scaled_health(wave_number: int) -> int:
	# Aggressive health scaling: 15% increase per wave
	var wave_multiplier = 1.0 + (wave_number * 0.15)
	return int(base_health * wave_multiplier)

func get_scaled_speed(wave_number: int) -> float:
	# Scale speed more aggressively: +5 per wave, capped at +150
	var wave_bonus = min(wave_number * 5, 150)  # Max +150 speed
	return base_speed + wave_bonus

func get_scaled_points(wave_number: int) -> int:
	# Better point rewards for tougher enemies
	var wave_multiplier = 1.0 + (wave_number / 2.0)
	return int(base_points * wave_multiplier)

func can_spawn_on_wave(wave_number: int) -> bool:
	return wave_number >= min_wave