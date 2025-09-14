extends Node
## HighScoreManager - Persistent High Score System with JSON Storage
## Manages leaderboards, score validation, and persistent storage across sessions

signal scores_updated
signal high_score_achieved(score: int, rank: int)
signal score_validated(is_valid: bool, score: int)

const MAX_SCORES = 20
const SCORE_FILE_PATH = "user://high_scores.json"
const BACKUP_FILE_PATH = "user://high_scores_backup.json"

# Score validation settings
const MIN_VALID_SCORE = 100
const MAX_VALID_SCORE = 99999999
const SCORE_INCREMENT_THRESHOLD = 1000  # Minimum score increment for validation

var high_scores: Array = []
var session_scores: Array = []  # Scores from current session
var last_save_time: float = 0.0
var auto_save_interval: float = 30.0  # Auto-save every 30 seconds

# Anti-cheat system
var score_validation_enabled: bool = true
var last_validated_scores: Dictionary = {}
var suspicious_scores: Array = []

# Score entry structure:
# {
#   "name": "Player Name",
#   "score": 12345,
#   "timestamp": "2024-01-01 12:00:00",
#   "session_id": "unique_session_identifier",
#   "validation_hash": "security_hash",
#   "metadata": {
#     "difficulty": "intermediate",
#     "weapon_upgrades": 5,
#     "survival_time": 120.5,
#     "enemies_defeated": 45
#   }
# }

func _ready():
	print("HighScoreManager: Initializing persistent high score system...")
	_load_scores()
	_setup_auto_save()
	_validate_integrity()

func _setup_auto_save():
	"""Setup automatic score saving"""
	var timer = Timer.new()
	timer.name = "AutoSaveTimer"
	timer.wait_time = auto_save_interval
	timer.one_shot = false
	timer.timeout.connect(_auto_save)
	add_child(timer)
	timer.start()

func _load_scores():
	"""Load high scores from persistent storage"""
	if FileAccess.file_exists(SCORE_FILE_PATH):
		_load_from_file(SCORE_FILE_PATH)
	elif FileAccess.file_exists(BACKUP_FILE_PATH):
		print("HighScoreManager: Primary file missing, loading from backup")
		_load_from_file(BACKUP_FILE_PATH)
		_save_scores()  # Restore primary file
	else:
		print("HighScoreManager: No existing scores found, initializing with defaults")
		_initialize_default_scores()
		_save_scores()

func _load_from_file(file_path: String) -> bool:
	"""Load scores from a specific file"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("HighScoreManager: Cannot open file: " + file_path)
		return false

	var json_string = file.get_as_text()
	file.close()

	if json_string.is_empty():
		push_error("HighScoreManager: Score file is empty")
		return false

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("HighScoreManager: Invalid JSON in scores file: " + json.error_string)
		return false

	var data = json.data
	if typeof(data) != TYPE_DICTIONARY or not data.has("scores"):
		push_error("HighScoreManager: Invalid score file format")
		return false

	high_scores = data.scores
	print("HighScoreManager: Loaded ", high_scores.size(), " scores from ", file_path)

	# Validate loaded scores
	_validate_loaded_scores()
	return true

func _initialize_default_scores():
	"""Initialize with default high scores for demonstration"""
	high_scores = [
		{
			"name": "ACE PILOT",
			"score": 50000,
			"timestamp": _get_current_timestamp(),
			"session_id": "default",
			"validation_hash": "",
			"metadata": {
				"difficulty": "expert",
				"weapon_upgrades": 5,
				"survival_time": 300.0,
				"enemies_defeated": 120
			}
		},
		{
			"name": "SKY CAPTAIN",
			"score": 35000,
			"timestamp": _get_current_timestamp(),
			"session_id": "default",
			"validation_hash": "",
			"metadata": {
				"difficulty": "intermediate",
				"weapon_upgrades": 4,
				"survival_time": 250.0,
				"enemies_defeated": 85
			}
		},
		{
			"name": "WING COMMANDER",
			"score": 28000,
			"timestamp": _get_current_timestamp(),
			"session_id": "default",
			"validation_hash": "",
			"metadata": {
				"difficulty": "intermediate",
				"weapon_upgrades": 3,
				"survival_time": 200.0,
				"enemies_defeated": 67
			}
		},
		{
			"name": "FLIGHT OFFICER",
			"score": 22000,
			"timestamp": _get_current_timestamp(),
			"session_id": "default",
			"validation_hash": "",
			"metadata": {
				"difficulty": "beginner",
				"weapon_upgrades": 3,
				"survival_time": 180.0,
				"enemies_defeated": 55
			}
		},
		{
			"name": "ROOKIE",
			"score": 15000,
			"timestamp": _get_current_timestamp(),
			"session_id": "default",
			"validation_hash": "",
			"metadata": {
				"difficulty": "beginner",
				"weapon_upgrades": 2,
				"survival_time": 120.0,
				"enemies_defeated": 35
			}
		}
	]

func _validate_loaded_scores():
	"""Validate integrity of loaded scores"""
	var valid_scores = []
	var invalid_count = 0

	for score_entry in high_scores:
		if _validate_score_entry(score_entry):
			valid_scores.append(score_entry)
		else:
			invalid_count += 1
			suspicious_scores.append(score_entry)

	if invalid_count > 0:
		print("HighScoreManager: Removed ", invalid_count, " invalid score entries")
		high_scores = valid_scores
		_save_scores()  # Save cleaned scores

func _validate_score_entry(entry: Dictionary) -> bool:
	"""Validate a single score entry"""
	# Check required fields
	var required_fields = ["name", "score", "timestamp"]
	for field in required_fields:
		if not entry.has(field):
			return false

	# Validate score range
	var score = entry.score
	if typeof(score) != TYPE_INT and typeof(score) != TYPE_FLOAT:
		return false

	if score < MIN_VALID_SCORE or score > MAX_VALID_SCORE:
		return false

	# Validate name
	var name = entry.name
	if typeof(name) != TYPE_STRING or name.strip_edges().is_empty():
		return false

	if name.length() > 20:  # Reasonable name length limit
		return false

	return true

func add_score(player_name: String, score: int, metadata: Dictionary = {}) -> int:
	"""Add a new score to the high score table"""
	# Validate inputs
	if not _is_valid_score(score):
		print("HighScoreManager: Invalid score rejected: ", score)
		score_validated.emit(false, score)
		return -1

	player_name = player_name.strip_edges()
	if player_name.is_empty():
		player_name = "ANONYMOUS"

	# Limit name length
	if player_name.length() > 20:
		player_name = player_name.substr(0, 20)

	# Create score entry
	var score_entry = {
		"name": player_name,
		"score": score,
		"timestamp": _get_current_timestamp(),
		"session_id": _generate_session_id(),
		"validation_hash": _generate_validation_hash(score, player_name),
		"metadata": metadata.duplicate()
	}

	# Add to scores array
	high_scores.append(score_entry)
	session_scores.append(score_entry)

	# Sort by score (descending)
	high_scores.sort_custom(_compare_scores)

	# Limit to maximum number of scores
	if high_scores.size() > MAX_SCORES:
		high_scores = high_scores.slice(0, MAX_SCORES)

	# Find ranking
	var rank = -1
	for i in range(high_scores.size()):
		if high_scores[i] == score_entry:
			rank = i + 1
			break

	print("HighScoreManager: Added score ", score, " for ", player_name, " (rank: ", rank, ")")

	# Emit signals
	scores_updated.emit()
	if rank > 0:
		high_score_achieved.emit(score, rank)

	# Save scores
	_save_scores()

	score_validated.emit(true, score)
	return rank

func _is_valid_score(score: int) -> bool:
	"""Validate if a score is legitimate"""
	if not score_validation_enabled:
		return true

	# Basic range check
	if score < MIN_VALID_SCORE or score > MAX_VALID_SCORE:
		return false

	# Check for unrealistic score progression
	if session_scores.size() > 0:
		var last_score = session_scores[-1].score
		var score_jump = score - last_score

		# Flag extremely large score jumps as suspicious
		if score_jump > SCORE_INCREMENT_THRESHOLD * 10:
			print("HighScoreManager: Suspicious score jump detected: ", score_jump)
			return false

	return true

func remove_score(index: int) -> bool:
	"""Remove a score at the specified index"""
	if index < 0 or index >= high_scores.size():
		return false

	var removed_score = high_scores[index]
	high_scores.remove_at(index)

	print("HighScoreManager: Removed score: ", removed_score.name, " - ", removed_score.score)

	scores_updated.emit()
	_save_scores()
	return true

func clear_all_scores():
	"""Clear all high scores (requires confirmation)"""
	print("HighScoreManager: Clearing all scores")

	# Create backup before clearing
	_create_backup()

	high_scores.clear()
	session_scores.clear()

	scores_updated.emit()
	_save_scores()

func is_high_score(score: int) -> bool:
	"""Check if a score qualifies as a high score"""
	if high_scores.size() < MAX_SCORES:
		return score >= MIN_VALID_SCORE

	# Check if score beats the lowest high score
	var lowest_high_score = high_scores[-1].score if high_scores.size() > 0 else 0
	return score > lowest_high_score

func get_scores(limit: int = MAX_SCORES) -> Array:
	"""Get high scores array (optionally limited)"""
	var limited_scores = high_scores.slice(0, min(limit, high_scores.size()))
	return limited_scores.duplicate(true)

func get_top_score() -> Dictionary:
	"""Get the highest score entry"""
	if high_scores.size() > 0:
		return high_scores[0].duplicate()
	return {}

func get_player_best_score(player_name: String) -> Dictionary:
	"""Get a specific player's best score"""
	var normalized_name = player_name.strip_edges().to_upper()

	for score_entry in high_scores:
		if score_entry.name.to_upper() == normalized_name:
			return score_entry.duplicate()

	return {}

func get_rank_for_score(score: int) -> int:
	"""Get the rank a score would achieve"""
	var rank = 1

	for score_entry in high_scores:
		if score <= score_entry.score:
			rank += 1
		else:
			break

	return rank if rank <= MAX_SCORES else -1

func get_session_statistics() -> Dictionary:
	"""Get statistics for the current session"""
	if session_scores.is_empty():
		return {}

	var total_score = 0
	var best_score = 0

	for score_entry in session_scores:
		total_score += score_entry.score
		best_score = max(best_score, score_entry.score)

	return {
		"games_played": session_scores.size(),
		"total_score": total_score,
		"average_score": total_score / session_scores.size(),
		"best_score": best_score,
		"high_scores_achieved": _count_session_high_scores()
	}

func _count_session_high_scores() -> int:
	"""Count how many session scores made it to the high score table"""
	var count = 0

	for session_score in session_scores:
		for high_score in high_scores:
			if (session_score.session_id == high_score.session_id and
				session_score.score == high_score.score):
				count += 1
				break

	return count

func _save_scores():
	"""Save high scores to persistent storage"""
	var save_data = {
		"version": "1.0",
		"last_updated": _get_current_timestamp(),
		"scores": high_scores,
		"metadata": {
			"total_entries": high_scores.size(),
			"highest_score": high_scores[0].score if high_scores.size() > 0 else 0,
			"validation_enabled": score_validation_enabled
		}
	}

	var json_string = JSON.stringify(save_data, "\t")

	# Save primary file
	var file = FileAccess.open(SCORE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		last_save_time = Time.get_ticks_msec() / 1000.0
		print("HighScoreManager: Scores saved to ", SCORE_FILE_PATH)
	else:
		push_error("HighScoreManager: Failed to save scores to primary file")

	# Save backup file
	var backup_file = FileAccess.open(BACKUP_FILE_PATH, FileAccess.WRITE)
	if backup_file:
		backup_file.store_string(json_string)
		backup_file.close()
	else:
		push_warning("HighScoreManager: Failed to save backup file")

func _create_backup():
	"""Create an additional timestamped backup"""
	if high_scores.is_empty():
		return

	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var backup_path = "user://high_scores_backup_" + timestamp + ".json"

	var save_data = {
		"version": "1.0",
		"backup_timestamp": _get_current_timestamp(),
		"scores": high_scores
	}

	var json_string = JSON.stringify(save_data, "\t")
	var file = FileAccess.open(backup_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("HighScoreManager: Backup created: ", backup_path)

func _auto_save():
	"""Automatic periodic save"""
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_save_time > auto_save_interval:
		_save_scores()

func _validate_integrity():
	"""Validate the integrity of the high score system"""
	print("HighScoreManager: Validating score integrity...")

	# Check for duplicate entries
	var seen_entries = {}
	var duplicates_found = 0

	for i in range(high_scores.size()):
		var entry = high_scores[i]
		var key = str(entry.name) + "|" + str(entry.score) + "|" + str(entry.timestamp)

		if seen_entries.has(key):
			duplicates_found += 1
		else:
			seen_entries[key] = true

	if duplicates_found > 0:
		print("HighScoreManager: Found ", duplicates_found, " potential duplicates")

	# Verify sort order
	var sort_errors = 0
	for i in range(1, high_scores.size()):
		if high_scores[i-1].score < high_scores[i].score:
			sort_errors += 1

	if sort_errors > 0:
		print("HighScoreManager: Found ", sort_errors, " sort order errors, fixing...")
		high_scores.sort_custom(_compare_scores)
		_save_scores()

func _compare_scores(a: Dictionary, b: Dictionary) -> bool:
	"""Compare two score entries for sorting"""
	if a.score != b.score:
		return a.score > b.score  # Higher scores first

	# If scores are equal, sort by timestamp (newer first)
	return a.timestamp > b.timestamp

func _get_current_timestamp() -> String:
	"""Get current timestamp as formatted string"""
	var datetime = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d:%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]

func _generate_session_id() -> String:
	"""Generate unique session identifier"""
	var timestamp = Time.get_ticks_msec()
	var random_suffix = randi() % 10000
	return "session_" + str(timestamp) + "_" + str(random_suffix)

func _generate_validation_hash(score: int, name: String) -> String:
	"""Generate validation hash for score entry"""
	var data = str(score) + name + str(Time.get_ticks_msec())
	return data.sha256_text()

# Public API for external systems
func export_scores_to_text() -> String:
	"""Export scores to human-readable text format"""
	var output = "HIGH SCORES - CONTINUUM SHMUP\n"
	output += "========================================\n\n"

	for i in range(high_scores.size()):
		var entry = high_scores[i]
		var rank = i + 1
		var rank_text = str(rank) + ". "
		if rank <= 3:
			rank_text = ["1st", "2nd", "3rd"][rank - 1] + " "

		output += rank_text + entry.name + " - " + str(entry.score) + "\n"
		if entry.has("metadata") and entry.metadata.has("survival_time"):
			output += "    Survival: %.1fs" % entry.metadata.survival_time + "\n"

	output += "\nGenerated: " + _get_current_timestamp()
	return output

func import_scores_from_data(data: Dictionary) -> bool:
	"""Import scores from external data"""
	if not data.has("scores") or typeof(data.scores) != TYPE_ARRAY:
		return false

	var imported_count = 0

	for score_data in data.scores:
		if _validate_score_entry(score_data):
			high_scores.append(score_data)
			imported_count += 1

	if imported_count > 0:
		high_scores.sort_custom(_compare_scores)

		# Limit to max scores
		if high_scores.size() > MAX_SCORES:
			high_scores = high_scores.slice(0, MAX_SCORES)

		scores_updated.emit()
		_save_scores()

		print("HighScoreManager: Imported ", imported_count, " scores")
		return true

	return false

func get_system_info() -> Dictionary:
	"""Get high score system information"""
	return {
		"total_scores": high_scores.size(),
		"max_capacity": MAX_SCORES,
		"last_save_time": last_save_time,
		"validation_enabled": score_validation_enabled,
		"session_scores": session_scores.size(),
		"file_path": SCORE_FILE_PATH,
		"backup_path": BACKUP_FILE_PATH
	}

func set_validation_enabled(enabled: bool):
	"""Enable or disable score validation"""
	score_validation_enabled = enabled
	print("HighScoreManager: Score validation ", "enabled" if enabled else "disabled")

func _exit_tree():
	"""Cleanup on exit"""
	_save_scores()
	print("HighScoreManager: Final save completed")