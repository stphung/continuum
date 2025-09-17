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
	# Logarithmic health scaling with hard cap at 3x base health
	# This ensures enemies remain killable even at wave 100
	var log_multiplier = 1.0 + log(wave_number + 1) * 0.3
	var capped_multiplier = min(log_multiplier, 3.0)  # Hard cap at 3x

	# Apply different scaling rates for different enemy tiers
	if enemy_name.begins_with("Elite"):
		capped_multiplier = min(log_multiplier * 1.2, 4.0)  # Elites cap at 4x
	elif base_health >= 10:  # Boss-tier enemies (Fortress, Carrier)
		capped_multiplier = min(log_multiplier * 1.1, 3.5)  # Bosses cap at 3.5x

	return int(base_health * capped_multiplier)

func get_scaled_speed(wave_number: int) -> float:
	# Logarithmic speed scaling, capped at +100 speed
	# Speed increases more gradually for better playability
	var speed_bonus = min(log(wave_number + 1) * 20, 100)  # Max +100 speed
	return base_speed + speed_bonus

func get_scaled_points(wave_number: int) -> int:
	# Exponential point rewards for risk/reward balance
	# Higher waves give much better scores
	var wave_multiplier = 1.0 + pow(wave_number / 10.0, 1.5)
	return int(base_points * wave_multiplier)

func can_spawn_on_wave(wave_number: int) -> bool:
	return wave_number >= min_wave