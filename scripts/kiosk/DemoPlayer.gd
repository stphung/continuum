extends Node
## DemoPlayer - Advanced AI for Automated Gameplay Demonstration
## Implements sophisticated threat assessment, evasion algorithms, and strategic decision making

signal demo_ended
signal high_score_achieved(score: int)
signal performance_milestone(milestone: String, value: float)

enum Difficulty {
	BEGINNER,      # Conservative play, basic threat avoidance
	INTERMEDIATE,  # Balanced risk/reward, moderate aggression
	EXPERT         # Aggressive play, complex maneuvers, optimal routes
}

enum AIState {
	IDLE,
	PLAYING,
	PAUSED,
	ENDED
}

var current_state: AIState = AIState.IDLE
var difficulty: Difficulty = Difficulty.INTERMEDIATE
var game_scene: Node
var player_node: Node

# AI Configuration
var config: Dictionary = {
	"reaction_time": 0.15,        # Seconds delay for human-like responses
	"prediction_depth": 1.5,      # Seconds to predict enemy trajectories
	"evasion_distance": 80.0,     # Distance to maintain from threats
	"aggression_factor": 0.7,     # 0.0 = defensive, 1.0 = aggressive
	"bomb_threshold": 0.8,        # Threat level to trigger bomb usage
	"powerup_priority": 0.9,      # Willingness to risk collecting powerups
	"weapon_switch_intelligence": 0.85, # Smart weapon switching based on situation
	"movement_smoothness": 0.3,   # Lower = more jittery, higher = smoother
	"error_rate": 0.05,          # Chance of suboptimal decisions (human-like)
	"spatial_awareness": 150.0,   # Detection radius for threats and opportunities
}

# AI State Variables
var threat_grid: Array[Array] = []
var grid_size: Vector2 = Vector2(20, 22)  # 800x900 screen / 40x40 cells
var cell_size: Vector2 = Vector2(40, 40)
var known_enemies: Array = []
var known_bullets: Array = []
var known_powerups: Array = []
var current_target: Node = null
var evasion_vector: Vector2 = Vector2.ZERO
var last_decision_time: float = 0.0

# Performance Tracking
var performance_stats: Dictionary = {
	"session_start_time": 0.0,
	"total_shots_fired": 0,
	"shots_hit": 0,
	"enemies_destroyed": 0,
	"powerups_collected": 0,
	"bombs_used": 0,
	"damage_taken": 0,
	"close_calls": 0,  # Near misses
	"final_score": 0,
	"survival_time": 0.0,
	"efficiency_rating": 0.0
}

# Virtual Input System
var virtual_inputs: Dictionary = {
	"move_up": false,
	"move_down": false,
	"move_left": false,
	"move_right": false,
	"shoot": false,
	"bomb": false
}

var input_buffer: Array = []
var reaction_timer: Timer

func _ready():
	print("DemoPlayer: AI system initialized")
	_setup_spatial_grid()
	_setup_reaction_timer()

func _setup_spatial_grid():
	"""Initialize spatial partitioning grid for efficient threat detection"""
	threat_grid.clear()
	threat_grid.resize(int(grid_size.x))
	for x in range(int(grid_size.x)):
		threat_grid[x] = []
		threat_grid[x].resize(int(grid_size.y))
		for y in range(int(grid_size.y)):
			threat_grid[x][y] = {
				"threat_level": 0.0,
				"entities": [],
				"safe_score": 1.0
			}

func _setup_reaction_timer():
	"""Setup human-like reaction delay timer"""
	reaction_timer = Timer.new()
	reaction_timer.name = "ReactionTimer"
	reaction_timer.wait_time = config.reaction_time
	reaction_timer.one_shot = false
	reaction_timer.timeout.connect(_process_queued_inputs)
	add_child(reaction_timer)

func set_difficulty(difficulty_name: String):
	"""Configure AI based on difficulty preset"""
	match difficulty_name.to_lower():
		"beginner":
			difficulty = Difficulty.BEGINNER
			config.reaction_time = 0.25
			config.aggression_factor = 0.4
			config.bomb_threshold = 0.6
			config.error_rate = 0.15
			config.spatial_awareness = 100.0
		"intermediate":
			difficulty = Difficulty.INTERMEDIATE
			config.reaction_time = 0.15
			config.aggression_factor = 0.7
			config.bomb_threshold = 0.8
			config.error_rate = 0.05
			config.spatial_awareness = 150.0
		"expert":
			difficulty = Difficulty.EXPERT
			config.reaction_time = 0.08
			config.aggression_factor = 0.95
			config.bomb_threshold = 0.9
			config.error_rate = 0.02
			config.spatial_awareness = 200.0

	print("DemoPlayer: Difficulty set to ", difficulty_name, " with config: ", config)

func start_demo():
	"""Begin AI demonstration session"""
	if current_state != AIState.IDLE:
		return

	print("DemoPlayer: Starting demo session")
	current_state = AIState.PLAYING
	performance_stats.session_start_time = Time.get_ticks_msec() / 1000.0

	# Find or create game scene
	_setup_game_scene()

	if game_scene and player_node:
		_connect_game_signals()
		reaction_timer.start()
		set_process(true)
	else:
		push_error("DemoPlayer: Failed to setup game scene")
		current_state = AIState.ENDED

func stop_demo():
	"""End AI demonstration session"""
	if current_state == AIState.IDLE:
		return

	print("DemoPlayer: Stopping demo session")
	current_state = AIState.ENDED
	reaction_timer.stop()
	set_process(false)
	_clear_virtual_inputs()
	_calculate_final_stats()
	demo_ended.emit()

func _setup_game_scene():
	"""Find or setup the game scene and player"""
	# Try to find existing game scene
	game_scene = get_tree().current_scene

	# Look for player node
	if game_scene:
		player_node = game_scene.get_node("Player") if game_scene.has_node("Player") else null
		if not player_node:
			# Try to find player in scene tree
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				player_node = players[0]

	if not player_node:
		# Request new player spawn
		if game_scene and game_scene.has_method("spawn_player"):
			game_scene.spawn_player()
			await get_tree().process_frame
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				player_node = players[0]

func _connect_game_signals():
	"""Connect to game events for performance tracking"""
	if game_scene:
		# Connect score updates if available
		if game_scene.has_signal("score_changed") and not game_scene.score_changed.is_connected(_on_score_changed):
			game_scene.score_changed.connect(_on_score_changed)

	if player_node:
		# Connect player events if available
		if player_node.has_signal("player_hit") and not player_node.player_hit.is_connected(_on_player_hit):
			player_node.player_hit.connect(_on_player_hit)

func _process(delta):
	"""Main AI processing loop"""
	if current_state != AIState.PLAYING or not player_node or not is_instance_valid(player_node):
		return

	# Update spatial awareness
	_update_spatial_grid()

	# Make AI decisions
	_make_tactical_decisions(delta)

	# Update performance tracking
	_update_performance_stats(delta)

func _update_spatial_grid():
	"""Update threat assessment grid with current game state"""
	# Clear previous frame data
	for x in range(int(grid_size.x)):
		for y in range(int(grid_size.y)):
			threat_grid[x][y].threat_level = 0.0
			threat_grid[x][y].entities.clear()
			threat_grid[x][y].safe_score = 1.0

	# Update known entities
	_scan_for_enemies()
	_scan_for_bullets()
	_scan_for_powerups()

	# Calculate threat levels for each grid cell
	_calculate_threat_levels()

func _scan_for_enemies():
	"""Scan for enemy entities and update tracking"""
	known_enemies.clear()
	var enemies = get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if is_instance_valid(enemy):
			known_enemies.append(enemy)
			_add_entity_to_grid(enemy, "enemy")

func _scan_for_bullets():
	"""Scan for enemy bullets and update tracking"""
	known_bullets.clear()
	var bullets = get_tree().get_nodes_in_group("enemy_bullets")

	for bullet in bullets:
		if is_instance_valid(bullet):
			known_bullets.append(bullet)
			_add_entity_to_grid(bullet, "bullet")

func _scan_for_powerups():
	"""Scan for powerup items and update tracking"""
	known_powerups.clear()

	# Look for powerups in common parent nodes
	if game_scene and game_scene.has_node("PowerUps"):
		for powerup in game_scene.get_node("PowerUps").get_children():
			if is_instance_valid(powerup):
				known_powerups.append(powerup)
				_add_entity_to_grid(powerup, "powerup")

func _add_entity_to_grid(entity: Node, entity_type: String):
	"""Add entity to spatial grid for threat assessment"""
	var pos = entity.global_position
	var grid_x = int(pos.x / cell_size.x)
	var grid_y = int(pos.y / cell_size.y)

	# Clamp to grid bounds
	grid_x = clamp(grid_x, 0, int(grid_size.x) - 1)
	grid_y = clamp(grid_y, 0, int(grid_size.y) - 1)

	if grid_x >= 0 and grid_x < grid_size.x and grid_y >= 0 and grid_y < grid_size.y:
		threat_grid[grid_x][grid_y].entities.append({
			"node": entity,
			"type": entity_type,
			"position": pos
		})

func _calculate_threat_levels():
	"""Calculate threat levels for each grid cell"""
	for x in range(int(grid_size.x)):
		for y in range(int(grid_size.y)):
			var cell = threat_grid[x][y]
			var threat_level = 0.0

			for entity_data in cell.entities:
				match entity_data.type:
					"enemy":
						threat_level += _calculate_enemy_threat(entity_data.node, Vector2(x * cell_size.x, y * cell_size.y))
					"bullet":
						threat_level += _calculate_bullet_threat(entity_data.node, Vector2(x * cell_size.x, y * cell_size.y))
					"powerup":
						# Powerups reduce threat (increase desirability)
						threat_level -= 0.3

			# Apply threat spread to neighboring cells
			_spread_threat_to_neighbors(x, y, threat_level * 0.3)

			cell.threat_level = threat_level
			cell.safe_score = max(0.0, 1.0 - threat_level)

func _calculate_enemy_threat(enemy: Node, cell_pos: Vector2) -> float:
	"""Calculate threat level from an enemy entity"""
	if not is_instance_valid(enemy):
		return 0.0

	var distance = enemy.global_position.distance_to(cell_pos)
	var base_threat = 0.5

	# Closer enemies are more threatening
	var distance_factor = max(0.1, 1.0 - (distance / config.spatial_awareness))

	# Predict enemy movement for smarter threat assessment
	var predicted_pos = _predict_enemy_position(enemy, config.prediction_depth)
	var predicted_distance = predicted_pos.distance_to(cell_pos)
	var prediction_factor = max(0.1, 1.0 - (predicted_distance / config.spatial_awareness))

	return base_threat * distance_factor * prediction_factor

func _calculate_bullet_threat(bullet: Node, cell_pos: Vector2) -> float:
	"""Calculate threat level from a bullet entity"""
	if not is_instance_valid(bullet):
		return 0.0

	# High immediate threat from bullets
	var distance = bullet.global_position.distance_to(cell_pos)
	var base_threat = 1.0

	# Bullets are extremely dangerous when close
	var distance_factor = max(0.2, 2.0 - (distance / 60.0))  # 60 pixel danger zone

	# Predict bullet trajectory
	var bullet_velocity = _estimate_bullet_velocity(bullet)
	var predicted_pos = bullet.global_position + bullet_velocity * config.prediction_depth
	var trajectory_threat = max(0.1, 1.0 - (predicted_pos.distance_to(cell_pos) / 40.0))

	return base_threat * distance_factor * trajectory_threat

func _spread_threat_to_neighbors(grid_x: int, grid_y: int, threat_amount: float):
	"""Spread threat to neighboring grid cells"""
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue

			var nx = grid_x + dx
			var ny = grid_y + dy

			if nx >= 0 and nx < grid_size.x and ny >= 0 and ny < grid_size.y:
				threat_grid[nx][ny].threat_level += threat_amount

func _predict_enemy_position(enemy: Node, time_ahead: float) -> Vector2:
	"""Predict where an enemy will be based on current movement"""
	if not is_instance_valid(enemy):
		return Vector2.ZERO

	# Simple linear prediction - could be enhanced with enemy pattern analysis
	var current_pos = enemy.global_position

	# Try to estimate velocity from enemy movement (basic implementation)
	var velocity = Vector2(0, 100)  # Default downward movement

	if enemy.has_method("get_velocity"):
		velocity = enemy.get_velocity()
	elif enemy.has_meta("last_position"):
		var last_pos = enemy.get_meta("last_position")
		velocity = (current_pos - last_pos) / get_process_delta_time()
		enemy.set_meta("last_position", current_pos)
	else:
		enemy.set_meta("last_position", current_pos)

	return current_pos + velocity * time_ahead

func _estimate_bullet_velocity(bullet: Node) -> Vector2:
	"""Estimate bullet velocity for trajectory prediction"""
	if not is_instance_valid(bullet):
		return Vector2.ZERO

	# Try to get velocity from bullet properties
	if bullet.has_method("get_velocity"):
		return bullet.get_velocity()
	elif bullet.has_property("direction") and bullet.has_property("speed"):
		return bullet.direction * bullet.speed
	elif bullet.has_property("velocity"):
		return bullet.velocity
	else:
		# Default bullet behavior - assume moving toward player
		if player_node:
			return (player_node.global_position - bullet.global_position).normalized() * 300
		else:
			return Vector2(0, 200)  # Default downward

func _make_tactical_decisions(delta: float):
	"""Main AI decision making system"""
	if Time.get_ticks_msec() / 1000.0 - last_decision_time < config.reaction_time:
		return

	last_decision_time = Time.get_ticks_msec() / 1000.0

	# Clear previous inputs
	_clear_virtual_inputs()

	# Decision priority system
	var decisions = []

	# 1. Immediate survival (highest priority)
	var survival_decision = _make_survival_decision()
	if survival_decision.priority > 0.8:
		decisions.append(survival_decision)

	# 2. Combat decisions
	var combat_decision = _make_combat_decision()
	if combat_decision.priority > 0.3:
		decisions.append(combat_decision)

	# 3. Movement optimization
	var movement_decision = _make_movement_decision()
	decisions.append(movement_decision)

	# 4. Powerup collection
	var powerup_decision = _make_powerup_decision()
	if powerup_decision.priority > 0.2:
		decisions.append(powerup_decision)

	# 5. Weapon management
	var weapon_decision = _make_weapon_decision()
	if weapon_decision.priority > 0.4:
		decisions.append(weapon_decision)

	# Execute decisions based on priority
	decisions.sort_custom(_compare_decision_priority)
	for decision in decisions:
		_execute_decision(decision)

func _make_survival_decision() -> Dictionary:
	"""Make survival-critical decisions (evasion, bombs)"""
	var decision = {"type": "survival", "priority": 0.0, "actions": []}

	if not player_node:
		return decision

	var player_pos = player_node.global_position
	var immediate_threats = []

	# Check for immediate threats
	for bullet in known_bullets:
		if is_instance_valid(bullet):
			var distance = bullet.global_position.distance_to(player_pos)
			if distance < config.evasion_distance:
				var threat_level = config.evasion_distance / max(1.0, distance)
				immediate_threats.append({"entity": bullet, "threat": threat_level})

	for enemy in known_enemies:
		if is_instance_valid(enemy):
			var distance = enemy.global_position.distance_to(player_pos)
			if distance < config.evasion_distance * 0.7:  # Closer range for enemies
				var threat_level = (config.evasion_distance * 0.7) / max(1.0, distance)
				immediate_threats.append({"entity": enemy, "threat": threat_level * 0.5})

	if immediate_threats.size() > 0:
		# Calculate total threat level
		var total_threat = 0.0
		for threat in immediate_threats:
			total_threat += threat.threat

		decision.priority = min(1.0, total_threat / config.bomb_threshold)

		# Determine evasion direction
		var evasion_dir = _calculate_optimal_evasion_direction(immediate_threats)
		decision.actions.append({"type": "move", "direction": evasion_dir})

		# Consider bomb usage for extreme threats
		if total_threat >= config.bomb_threshold and _can_use_bomb():
			decision.actions.append({"type": "bomb"})
			decision.priority = 1.0

	return decision

func _make_combat_decision() -> Dictionary:
	"""Make combat-related decisions (shooting, targeting)"""
	var decision = {"type": "combat", "priority": 0.0, "actions": []}

	if not player_node:
		return decision

	# Always shoot when enemies are present (aggressive AI)
	if known_enemies.size() > 0:
		decision.priority = config.aggression_factor
		decision.actions.append({"type": "shoot"})

		# Select optimal target
		var best_target = _select_optimal_target()
		if best_target:
			current_target = best_target

	return decision

func _make_movement_decision() -> Dictionary:
	"""Make movement decisions for optimal positioning"""
	var decision = {"type": "movement", "priority": 0.5, "actions": []}

	if not player_node:
		return decision

	var player_pos = player_node.global_position
	var optimal_pos = _calculate_optimal_position(player_pos)

	if optimal_pos.distance_to(player_pos) > 20.0:  # Minimum movement threshold
		var move_dir = (optimal_pos - player_pos).normalized()
		decision.actions.append({"type": "move", "direction": move_dir})
		decision.priority = 0.3

	return decision

func _make_powerup_decision() -> Dictionary:
	"""Make powerup collection decisions"""
	var decision = {"type": "powerup", "priority": 0.0, "actions": []}

	if not player_node or known_powerups.size() == 0:
		return decision

	var player_pos = player_node.global_position
	var closest_powerup = null
	var closest_distance = INF

	# Find closest safe powerup
	for powerup in known_powerups:
		if is_instance_valid(powerup):
			var distance = powerup.global_position.distance_to(player_pos)
			var threat_at_powerup = _get_threat_at_position(powerup.global_position)

			# Only consider if reasonably safe
			if threat_at_powerup < 0.6 and distance < closest_distance:
				closest_powerup = powerup
				closest_distance = distance

	if closest_powerup and closest_distance < config.spatial_awareness:
		decision.priority = config.powerup_priority * (1.0 - closest_distance / config.spatial_awareness)
		var move_dir = (closest_powerup.global_position - player_pos).normalized()
		decision.actions.append({"type": "move", "direction": move_dir})

	return decision

func _make_weapon_decision() -> Dictionary:
	"""Make weapon switching decisions"""
	var decision = {"type": "weapon", "priority": 0.0, "actions": []}

	if not player_node or not player_node.has_property("weapon_type"):
		return decision

	var current_weapon = player_node.weapon_type
	var enemy_count = known_enemies.size()
	var enemy_density = _calculate_enemy_density()

	# Intelligent weapon switching based on situation
	var should_use_laser = false

	if enemy_count >= 3 and enemy_density > 0.4:
		# High density: use vulcan for spread damage
		should_use_laser = false
	elif enemy_count <= 2:
		# Few enemies: laser for precision and penetration
		should_use_laser = true
	elif current_target and _is_target_aligned():
		# Good alignment: laser for maximum damage
		should_use_laser = true

	# Switch if beneficial and we have the intelligence level
	if randf() < config.weapon_switch_intelligence:
		var desired_weapon = "laser" if should_use_laser else "vulcan"
		if current_weapon != desired_weapon:
			decision.priority = 0.6
			decision.actions.append({"type": "weapon_switch"})

	return decision

func _calculate_optimal_evasion_direction(threats: Array) -> Vector2:
	"""Calculate optimal direction to evade multiple threats"""
	if not player_node:
		return Vector2.ZERO

	var player_pos = player_node.global_position
	var avoidance_vector = Vector2.ZERO

	for threat_data in threats:
		var threat_pos = threat_data.entity.global_position
		var threat_level = threat_data.threat

		# Vector pointing away from threat
		var avoid_dir = (player_pos - threat_pos).normalized()
		avoidance_vector += avoid_dir * threat_level

	# Ensure we don't move off-screen
	var screen_bounds = Vector2(800, 900)  # Game screen size
	var safe_dir = avoidance_vector.normalized()

	# Adjust direction to stay within bounds
	var future_pos = player_pos + safe_dir * 60.0  # Predict 60 pixels ahead
	if future_pos.x < 40 or future_pos.x > screen_bounds.x - 40:
		safe_dir.x *= -0.5  # Reverse or reduce horizontal movement
	if future_pos.y < 40 or future_pos.y > screen_bounds.y - 40:
		safe_dir.y *= -0.5  # Reverse or reduce vertical movement

	return safe_dir

func _calculate_optimal_position(current_pos: Vector2) -> Vector2:
	"""Calculate optimal position for combat effectiveness and safety"""
	var best_pos = current_pos
	var best_score = -INF

	# Sample positions in a grid around current position
	var sample_radius = 80.0
	var samples_per_axis = 5

	for x in range(samples_per_axis):
		for y in range(samples_per_axis):
			var offset_x = (x - samples_per_axis/2) * (sample_radius / samples_per_axis)
			var offset_y = (y - samples_per_axis/2) * (sample_radius / samples_per_axis)
			var test_pos = current_pos + Vector2(offset_x, offset_y)

			# Ensure position is on screen
			test_pos.x = clamp(test_pos.x, 40, 760)
			test_pos.y = clamp(test_pos.y, 40, 860)

			var score = _evaluate_position(test_pos)
			if score > best_score:
				best_score = score
				best_pos = test_pos

	return best_pos

func _evaluate_position(pos: Vector2) -> float:
	"""Evaluate the strategic value of a position"""
	var score = 0.0

	# Safety component (avoid threats)
	var threat_level = _get_threat_at_position(pos)
	score += (1.0 - threat_level) * 3.0

	# Combat effectiveness (good angles to enemies)
	for enemy in known_enemies:
		if is_instance_valid(enemy):
			var distance = enemy.global_position.distance_to(pos)
			if distance < config.spatial_awareness:
				# Closer enemies are better for targeting
				score += (config.spatial_awareness - distance) / config.spatial_awareness

	# Center screen bonus (more maneuvering room)
	var screen_center = Vector2(400, 450)
	var center_distance = pos.distance_to(screen_center)
	score += max(0, 1.0 - center_distance / 200.0)

	# Powerup accessibility
	for powerup in known_powerups:
		if is_instance_valid(powerup):
			var distance = powerup.global_position.distance_to(pos)
			if distance < 100.0:
				score += (100.0 - distance) / 100.0 * 0.5

	return score

func _get_threat_at_position(pos: Vector2) -> float:
	"""Get threat level at specific position"""
	var grid_x = int(pos.x / cell_size.x)
	var grid_y = int(pos.y / cell_size.y)

	grid_x = clamp(grid_x, 0, int(grid_size.x) - 1)
	grid_y = clamp(grid_y, 0, int(grid_size.y) - 1)

	if grid_x >= 0 and grid_x < grid_size.x and grid_y >= 0 and grid_y < grid_size.y:
		return threat_grid[grid_x][grid_y].threat_level

	return 0.0

func _select_optimal_target() -> Node:
	"""Select best enemy target based on strategic criteria"""
	if known_enemies.size() == 0:
		return null

	var best_target = null
	var best_score = -INF

	for enemy in known_enemies:
		if not is_instance_valid(enemy):
			continue

		var score = 0.0
		var distance = enemy.global_position.distance_to(player_node.global_position)

		# Prefer closer enemies
		score += max(0, (config.spatial_awareness - distance) / config.spatial_awareness) * 2.0

		# Prefer enemies in front
		if enemy.global_position.y < player_node.global_position.y:
			score += 1.0

		# Prefer aligned enemies (easier to hit)
		var alignment = abs(enemy.global_position.x - player_node.global_position.x)
		score += max(0, 1.0 - alignment / 100.0)

		# Bonus for low-health enemies (if health info available)
		if enemy.has_property("health") and enemy.has_property("max_health"):
			var health_ratio = float(enemy.health) / float(enemy.max_health)
			score += (1.0 - health_ratio) * 0.5

		if score > best_score:
			best_score = score
			best_target = enemy

	return best_target

func _calculate_enemy_density() -> float:
	"""Calculate enemy density in player area"""
	if not player_node or known_enemies.size() == 0:
		return 0.0

	var density_radius = 120.0
	var nearby_enemies = 0

	for enemy in known_enemies:
		if is_instance_valid(enemy):
			var distance = enemy.global_position.distance_to(player_node.global_position)
			if distance <= density_radius:
				nearby_enemies += 1

	# Normalize by max possible enemies in area
	var max_enemies_in_area = 10  # Reasonable maximum
	return float(nearby_enemies) / float(max_enemies_in_area)

func _is_target_aligned() -> bool:
	"""Check if current target is well-aligned for laser attack"""
	if not current_target or not is_instance_valid(current_target) or not player_node:
		return false

	var alignment_threshold = 30.0  # pixels
	var x_diff = abs(current_target.global_position.x - player_node.global_position.x)
	return x_diff <= alignment_threshold

func _can_use_bomb() -> bool:
	"""Check if bombs are available and appropriate to use"""
	if not game_scene or not game_scene.has_property("bombs"):
		return false

	return game_scene.bombs > 0

func _compare_decision_priority(a: Dictionary, b: Dictionary) -> bool:
	"""Compare decisions by priority for sorting"""
	return a.priority > b.priority

func _execute_decision(decision: Dictionary):
	"""Execute AI decision by queuing appropriate inputs"""
	for action in decision.actions:
		match action.type:
			"move":
				_queue_movement_input(action.direction)
			"shoot":
				_queue_input("shoot", true)
			"bomb":
				_queue_input("bomb", true)
			"weapon_switch":
				# Weapon switching might need special handling
				pass

func _queue_movement_input(direction: Vector2):
	"""Queue movement inputs based on direction vector"""
	var threshold = 0.3

	if direction.x > threshold:
		_queue_input("move_right", true)
	elif direction.x < -threshold:
		_queue_input("move_left", true)

	if direction.y > threshold:
		_queue_input("move_down", true)
	elif direction.y < -threshold:
		_queue_input("move_up", true)

func _queue_input(action: String, pressed: bool):
	"""Queue input for delayed execution (human-like reaction time)"""
	input_buffer.append({"action": action, "pressed": pressed})

func _process_queued_inputs():
	"""Process queued inputs with reaction delay"""
	for input_data in input_buffer:
		virtual_inputs[input_data.action] = input_data.pressed
		_inject_virtual_input(input_data.action, input_data.pressed)

	input_buffer.clear()

func _inject_virtual_input(action: String, pressed: bool):
	"""Inject virtual input into Godot's input system"""
	# Create synthetic input event
	var event: InputEvent

	match action:
		"move_up", "move_down", "move_left", "move_right", "shoot", "bomb":
			event = InputEventAction.new()
			event.action = action
			event.pressed = pressed
			# Mark as AI-generated to distinguish from user input
			event.set_meta("ai_generated", true)

			# Inject the event
			Input.parse_input_event(event)

func _clear_virtual_inputs():
	"""Clear all virtual input states"""
	for key in virtual_inputs:
		virtual_inputs[key] = false

func _update_performance_stats(delta: float):
	"""Update performance tracking metrics"""
	performance_stats.survival_time += delta

	# Additional metrics would be updated through signal connections
	# to game events (enemy destroyed, shots fired, etc.)

func _calculate_final_stats():
	"""Calculate final performance statistics"""
	var session_time = performance_stats.survival_time

	if session_time > 0:
		performance_stats.efficiency_rating = float(performance_stats.shots_hit) / max(1, performance_stats.total_shots_fired)

	if game_scene and game_scene.has_property("score"):
		performance_stats.final_score = game_scene.score

func _on_score_changed(new_score: int):
	"""Handle score updates from game"""
	performance_stats.final_score = new_score

	# Check for high score achievement
	if new_score > 10000:  # Arbitrary high score threshold
		high_score_achieved.emit(new_score)

func _on_player_hit():
	"""Handle player damage events"""
	performance_stats.damage_taken += 1

# Public API
func get_performance_stats() -> Dictionary:
	"""Get current performance statistics"""
	return performance_stats.duplicate()

func get_current_state() -> String:
	"""Get current AI state as string"""
	return AIState.keys()[current_state]

func get_final_score() -> int:
	"""Get final achieved score"""
	return performance_stats.final_score

func is_playing() -> bool:
	"""Check if AI is currently playing"""
	return current_state == AIState.PLAYING

func pause_demo():
	"""Pause the AI demonstration"""
	if current_state == AIState.PLAYING:
		current_state = AIState.PAUSED
		reaction_timer.stop()
		set_process(false)

func resume_demo():
	"""Resume the AI demonstration"""
	if current_state == AIState.PAUSED:
		current_state = AIState.PLAYING
		reaction_timer.start()
		set_process(true)

func _exit_tree():
	"""Cleanup on exit"""
	if reaction_timer:
		reaction_timer.queue_free()