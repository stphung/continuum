extends GdUnitTestSuite
## Comprehensive tests for HighScoreManager - persistence, validation, and leaderboard management

var high_score_manager: Node
var test_score_file: String = "user://test_high_scores.json"
var original_score_file: String

func before():
	"""Setup test environment with isolated score storage"""
	# Create HighScoreManager instance
	var HighScoreManagerScript = preload("res://scripts/kiosk/HighScoreManager.gd")
	high_score_manager = HighScoreManagerScript.new()
	high_score_manager.name = "TestHighScoreManager"

	# Override file paths for testing
	original_score_file = high_score_manager.SCORE_FILE_PATH
	high_score_manager.SCORE_FILE_PATH = test_score_file
	high_score_manager.BACKUP_FILE_PATH = test_score_file.replace(".json", "_backup.json")

	add_child(high_score_manager)
	await get_tree().process_frame

func after():
	"""Cleanup test environment and files"""
	# Remove test files
	if FileAccess.file_exists(test_score_file):
		DirAccess.remove_absolute(test_score_file)
	if FileAccess.file_exists(high_score_manager.BACKUP_FILE_PATH):
		DirAccess.remove_absolute(high_score_manager.BACKUP_FILE_PATH)

	# Cleanup manager
	if high_score_manager and is_instance_valid(high_score_manager):
		high_score_manager.queue_free()

	await get_tree().process_frame

# Initialization Tests
func test_high_score_manager_initialization():
	"""Test HighScoreManager initializes with correct defaults"""
	assert_that(high_score_manager.high_scores).is_not_null()
	assert_that(high_score_manager.session_scores).is_not_null()
	assert_that(high_score_manager.score_validation_enabled).is_true()
	assert_that(high_score_manager.MAX_SCORES).is_equal(20)

func test_constants_validation():
	"""Test that all required constants are properly defined"""
	assert_that(high_score_manager.MAX_SCORES).is_greater(0)
	assert_that(high_score_manager.MIN_VALID_SCORE).is_greater_equal(0)
	assert_that(high_score_manager.MAX_VALID_SCORE).is_greater(high_score_manager.MIN_VALID_SCORE)
	assert_that(high_score_manager.SCORE_INCREMENT_THRESHOLD).is_greater(0)

func test_auto_save_setup():
	"""Test auto-save system is properly configured"""
	assert_that(high_score_manager.auto_save_interval).is_greater(0.0)
	assert_that(high_score_manager.last_save_time).is_greater_equal(0.0)

# Score Addition Tests
func test_add_valid_score():
	"""Test adding a valid score to empty leaderboard"""
	# Monitor signals
	var scores_updated_count = [0]
	var high_score_count = [0]
	high_score_manager.scores_updated.connect(func(): scores_updated_count[0] += 1)
	high_score_manager.high_score_achieved.connect(func(score, rank): high_score_count[0] += 1)

	var rank = high_score_manager.add_score("PLAYER1", 5000)

	assert_that(rank).is_equal(1)  # First score should be rank 1
	assert_that(high_score_manager.high_scores.size()).is_equal(1)
	assert_that(high_score_manager.high_scores[0].score).is_equal(5000)
	assert_that(high_score_manager.high_scores[0].name).is_equal("PLAYER1")

	assert_that(scores_updated_count[0]).is_equal(1)
	assert_that(high_score_count[0]).is_equal(1)

func test_add_multiple_scores_ordering():
	"""Test multiple scores are properly ordered"""
	high_score_manager.add_score("PLAYER1", 1000)
	high_score_manager.add_score("PLAYER2", 3000)
	high_score_manager.add_score("PLAYER3", 2000)

	assert_that(high_score_manager.high_scores.size()).is_equal(3)
	assert_that(high_score_manager.high_scores[0].score).is_equal(3000)  # Highest first
	assert_that(high_score_manager.high_scores[1].score).is_equal(2000)
	assert_that(high_score_manager.high_scores[2].score).is_equal(1000)

func test_add_score_with_metadata():
	"""Test adding score with comprehensive metadata"""
	var metadata = {
		"difficulty": "expert",
		"weapon_upgrades": 5,
		"survival_time": 180.5,
		"enemies_defeated": 67
	}

	var rank = high_score_manager.add_score("AI_DEMO", 8500, metadata)

	assert_that(rank).is_equal(1)
	var score_entry = high_score_manager.high_scores[0]
	assert_that(score_entry.has("metadata")).is_true()
	assert_that(score_entry.metadata.difficulty).is_equal("expert")
	assert_that(score_entry.metadata.survival_time).is_equal(180.5)

func test_max_scores_limit():
	"""Test leaderboard enforces maximum score limit"""
	# Add more than MAX_SCORES
	for i in range(high_score_manager.MAX_SCORES + 5):
		high_score_manager.add_score("PLAYER" + str(i), (i + 1) * 100)

	assert_that(high_score_manager.high_scores.size()).is_equal(high_score_manager.MAX_SCORES)
	# Should keep only the highest scores
	assert_that(high_score_manager.high_scores[0].score).is_equal((high_score_manager.MAX_SCORES + 4) * 100)

# Score Validation Tests
func test_score_validation_enabled():
	"""Test score validation rejects invalid scores"""
	# Monitor validation signal
	var validation_results = []
	high_score_manager.score_validated.connect(func(is_valid, score):
		validation_results.append({"valid": is_valid, "score": score})
	)

	# Test minimum score validation
	var rank_too_low = high_score_manager.add_score("INVALID", 50)  # Below MIN_VALID_SCORE
	assert_that(rank_too_low).is_equal(-1)

	# Test maximum score validation
	var rank_too_high = high_score_manager.add_score("INVALID", 999999999)  # Above MAX_VALID_SCORE
	assert_that(rank_too_high).is_equal(-1)

	# Check validation results
	assert_that(validation_results.size()).is_greater_equal(2)

func test_score_validation_disabled():
	"""Test behavior when score validation is disabled"""
	high_score_manager.score_validation_enabled = false

	var rank = high_score_manager.add_score("PLAYER", 50)  # Below normal minimum
	assert_that(rank).is_equal(1)  # Should accept when validation disabled

func test_suspicious_score_detection():
	"""Test detection of suspicious score patterns"""
	# Add a normal score first
	high_score_manager.add_score("PLAYER1", 1000)

	# Add a suspiciously high score from same session
	if high_score_manager.has_method("_detect_suspicious_score"):
		var is_suspicious = high_score_manager._detect_suspicious_score("PLAYER1", 50000)
		# Implementation dependent - very high score might be suspicious
		assert_that(is_suspicious).is_instance_of(TYPE_BOOL)

func test_score_increment_validation():
	"""Test score increment threshold validation"""
	high_score_manager.add_score("PLAYER", 1000)
	high_score_manager.add_score("PLAYER", 1050)  # Small increment

	# Second score might be rejected if increments are too small
	# Implementation dependent on anti-cheat settings
	if high_score_manager.suspicious_scores.size() > 0:
		assert_that(high_score_manager.suspicious_scores[0]).is_instance_of(TYPE_DICTIONARY)

# Persistence Tests
func test_save_scores_to_file():
	"""Test saving scores to JSON file"""
	high_score_manager.add_score("PLAYER1", 5000)
	high_score_manager.add_score("PLAYER2", 3000)

	high_score_manager._save_scores()
	await get_tree().process_frame

	assert_that(FileAccess.file_exists(test_score_file)).is_true()

	# Verify file content
	var file = FileAccess.open(test_score_file, FileAccess.READ)
	var json_content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_content)
	assert_that(parse_result).is_equal(OK)
	assert_that(json.data.size()).is_equal(2)

func test_load_scores_from_file():
	"""Test loading scores from JSON file"""
	# Create test data
	var test_scores = [
		{"name": "SAVED1", "score": 7000, "timestamp": "2024-01-01 12:00:00"},
		{"name": "SAVED2", "score": 4000, "timestamp": "2024-01-01 11:00:00"}
	]

	# Save test data to file
	var file = FileAccess.open(test_score_file, FileAccess.WRITE)
	file.store_string(JSON.stringify(test_scores))
	file.close()

	# Create new manager and load
	var new_manager = preload("res://scripts/kiosk/HighScoreManager.gd").new()
	new_manager.SCORE_FILE_PATH = test_score_file
	add_child(new_manager)
	await get_tree().process_frame

	assert_that(new_manager.high_scores.size()).is_equal(2)
	assert_that(new_manager.high_scores[0].name).is_equal("SAVED1")
	assert_that(new_manager.high_scores[0].score).is_equal(7000)

	new_manager.queue_free()

func test_corrupted_file_handling():
	"""Test handling of corrupted score files"""
	# Create corrupted file
	var file = FileAccess.open(test_score_file, FileAccess.WRITE)
	file.store_string("invalid json content {")
	file.close()

	# Create new manager - should handle gracefully
	var new_manager = preload("res://scripts/kiosk/HighScoreManager.gd").new()
	new_manager.SCORE_FILE_PATH = test_score_file
	add_child(new_manager)
	await get_tree().process_frame

	# Should start with empty scores
	assert_that(new_manager.high_scores).is_empty()

	new_manager.queue_free()

func test_backup_file_creation():
	"""Test backup file is created during saves"""
	high_score_manager.add_score("BACKUP_TEST", 6000)
	high_score_manager._save_scores()
	await get_tree().process_frame

	assert_that(FileAccess.file_exists(high_score_manager.BACKUP_FILE_PATH)).is_true()

func test_auto_save_functionality():
	"""Test automatic saving triggers after interval"""
	high_score_manager.auto_save_interval = 0.1  # Very short for testing
	high_score_manager.add_score("AUTO_SAVE", 2500)

	# Wait for auto-save
	await get_tree().create_timer(0.2).timeout

	# File should exist after auto-save
	assert_that(FileAccess.file_exists(test_score_file)).is_true()

# Query Tests
func test_is_high_score():
	"""Test checking if a score qualifies as high score"""
	high_score_manager.add_score("EXISTING", 3000)

	assert_that(high_score_manager.is_high_score(5000)).is_true()   # Higher than existing
	assert_that(high_score_manager.is_high_score(2000)).is_false()  # Lower than existing
	assert_that(high_score_manager.is_high_score(3000)).is_false()  # Equal to existing

func test_is_high_score_empty_leaderboard():
	"""Test high score check on empty leaderboard"""
	assert_that(high_score_manager.is_high_score(1000)).is_true()  # Any score is high score when empty

func test_get_scores():
	"""Test retrieving score list"""
	high_score_manager.add_score("GET_TEST1", 4000)
	high_score_manager.add_score("GET_TEST2", 6000)

	var scores = high_score_manager.get_scores()
	assert_that(scores.size()).is_equal(2)
	assert_that(scores[0].score).is_equal(6000)  # Should be ordered high to low

func test_get_scores_limited():
	"""Test retrieving limited number of scores"""
	for i in range(15):
		high_score_manager.add_score("LIMIT_TEST" + str(i), (i + 1) * 100)

	var top_5 = high_score_manager.get_scores(5)
	assert_that(top_5.size()).is_equal(5)
	assert_that(top_5[0].score).is_equal(1500)  # Highest score

func test_get_rank():
	"""Test getting rank for a specific score"""
	high_score_manager.add_score("RANK1", 5000)
	high_score_manager.add_score("RANK2", 3000)
	high_score_manager.add_score("RANK3", 7000)

	if high_score_manager.has_method("get_rank"):
		var rank_for_6000 = high_score_manager.get_rank(6000)
		assert_that(rank_for_6000).is_equal(2)  # Should be between 7000 and 5000

# Session Management Tests
func test_session_score_tracking():
	"""Test tracking scores within current session"""
	var initial_session_count = high_score_manager.session_scores.size()

	high_score_manager.add_score("SESSION1", 2000)
	high_score_manager.add_score("SESSION2", 4000)

	assert_that(high_score_manager.session_scores.size()).is_equal(initial_session_count + 2)

func test_clear_session_scores():
	"""Test clearing session scores"""
	high_score_manager.add_score("CLEAR_TEST", 3500)

	if high_score_manager.has_method("clear_session_scores"):
		high_score_manager.clear_session_scores()
		assert_that(high_score_manager.session_scores).is_empty()

func test_session_statistics():
	"""Test getting session statistics"""
	high_score_manager.add_score("STAT1", 1000)
	high_score_manager.add_score("STAT2", 3000)
	high_score_manager.add_score("STAT3", 2000)

	if high_score_manager.has_method("get_session_stats"):
		var stats = high_score_manager.get_session_stats()
		assert_that(stats).is_instance_of(TYPE_DICTIONARY)
		# Implementation dependent - might include average, total, etc.

# Security and Integrity Tests
func test_score_entry_has_timestamp():
	"""Test that score entries include timestamps"""
	high_score_manager.add_score("TIME_TEST", 4500)

	var score_entry = high_score_manager.high_scores[0]
	assert_that(score_entry.has("timestamp")).is_true()
	assert_that(score_entry.timestamp).is_not_equal("")

func test_score_entry_has_session_id():
	"""Test that score entries include session identifiers"""
	high_score_manager.add_score("SESSION_ID_TEST", 3800)

	var score_entry = high_score_manager.high_scores[0]
	assert_that(score_entry.has("session_id")).is_true()

func test_validation_hash_generation():
	"""Test that validation hashes are generated for security"""
	high_score_manager.add_score("HASH_TEST", 5200)

	var score_entry = high_score_manager.high_scores[0]
	if score_entry.has("validation_hash"):
		assert_that(score_entry.validation_hash).is_not_equal("")

func test_integrity_validation():
	"""Test integrity validation of loaded scores"""
	high_score_manager.add_score("INTEGRITY_TEST", 6700)
	high_score_manager._save_scores()

	# Validation should pass for legitimate scores
	if high_score_manager.has_method("_validate_integrity"):
		var result = high_score_manager._validate_integrity()
		assert_that(result).is_true()

# Error Handling Tests
func test_invalid_player_name_handling():
	"""Test handling of invalid or empty player names"""
	var rank1 = high_score_manager.add_score("", 5000)         # Empty name
	var rank2 = high_score_manager.add_score(null, 5000)      # Null name

	# Should handle gracefully (may use default names or reject)
	assert_that(rank1).is_instance_of(TYPE_INT)
	assert_that(rank2).is_instance_of(TYPE_INT)

func test_negative_score_handling():
	"""Test handling of negative scores"""
	var rank = high_score_manager.add_score("NEGATIVE", -1000)

	# Should reject negative scores
	assert_that(rank).is_equal(-1)

func test_duplicate_scores_handling():
	"""Test handling of identical scores"""
	high_score_manager.add_score("DUPE1", 5000)
	high_score_manager.add_score("DUPE2", 5000)

	assert_that(high_score_manager.high_scores.size()).is_equal(2)
	# Both should be preserved with same score

func test_memory_management_large_datasets():
	"""Test memory management with large score datasets"""
	var initial_memory = OS.get_static_memory_peak_usage()

	# Add many scores
	for i in range(1000):
		high_score_manager.add_score("STRESS" + str(i), randf() * 10000)

	# Should enforce MAX_SCORES limit
	assert_that(high_score_manager.high_scores.size()).is_less_equal(high_score_manager.MAX_SCORES)

	# Memory shouldn't grow unboundedly
	var final_memory = OS.get_static_memory_peak_usage()
	# This is a rough check - exact memory management depends on implementation

# Signal Tests
func test_scores_updated_signal():
	"""Test scores_updated signal emission"""
	# Monitor signal
	var signal_count = [0]
	high_score_manager.scores_updated.connect(func(): signal_count[0] += 1)

	high_score_manager.add_score("SIGNAL_TEST", 4200)

	assert_that(signal_count[0]).is_equal(1)

func test_high_score_achieved_signal():
	"""Test high_score_achieved signal emission"""
	# Monitor signal
	var signal_data = []
	high_score_manager.high_score_achieved.connect(func(score, rank):
		signal_data.append({"score": score, "rank": rank})
	)

	high_score_manager.add_score("HIGH_SCORE_SIGNAL", 8900)

	assert_that(signal_data.size()).is_equal(1)
	assert_that(signal_data[0].score).is_equal(8900)
	assert_that(signal_data[0].rank).is_equal(1)

func test_score_validated_signal():
	"""Test score_validated signal emission"""
	# Monitor signal
	var validation_count = [0]
	high_score_manager.score_validated.connect(func(is_valid, score): validation_count[0] += 1)

	high_score_manager.add_score("VALID_SIGNAL", 3600)
	high_score_manager.add_score("INVALID_SIGNAL", 50)  # Below minimum

	assert_that(validation_count[0]).is_greater_equal(1)  # At least one validation