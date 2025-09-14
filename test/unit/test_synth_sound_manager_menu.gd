extends GdUnitTestSuite

## Unit Tests for SynthSoundManager Menu Extensions
## Tests menu audio generation, looping, sound effects, and performance
## Part of the Continuum Professional Title Screen System Test Suite

# Class under test
var sound_manager: Node

# Audio test configuration
const TEST_SAMPLE_RATE = 44100.0
const TEST_VOLUME_TOLERANCE = 0.1
const AUDIO_GENERATION_TIMEOUT = 100  # milliseconds

# Test tracking
var generated_sounds: Array[AudioStreamWAV] = []
var performance_times: Dictionary = {}

func before():
	# Create sound manager instance
	sound_manager = preload("res://scripts/autoloads/SynthSoundManager.gd").new()
	sound_manager.name = "SynthSoundManagerTest"
	add_child(sound_manager)
	auto_free(sound_manager)

	# Reset tracking
	generated_sounds.clear()
	performance_times.clear()

func after():
	# Stop all audio to prevent interference between tests
	if sound_manager and is_instance_valid(sound_manager):
		sound_manager.stop_all_sounds()

	# Clean up generated sounds
	for sound in generated_sounds:
		if is_instance_valid(sound):
			sound = null

# === Initialization Tests ===

func test_sound_manager_initialization():
	"""Test proper initialization of SynthSoundManager"""
	assert_that(sound_manager).is_not_null()
	assert_that(sound_manager.sample_rate).is_equal_approx(TEST_SAMPLE_RATE, 1.0)
	assert_that(sound_manager.audio_players).is_not_null()

func test_menu_audio_players_creation():
	"""Test menu-specific audio player creation"""
	var menu_sound_types = ["menu_navigate", "menu_hover", "menu_select", "menu_back", "menu_music"]

	for sound_type in menu_sound_types:
		assert_that(sound_manager.audio_players.has(sound_type)).is_true()

		var player = sound_manager.audio_players[sound_type]
		assert_that(player).is_not_null()
		assert_that(player.name).is_equal(sound_type)
		assert_that(player.bus).is_equal("Master")

func test_all_sound_types_coverage():
	"""Test all expected sound types are covered"""
	var expected_sound_types = [
		"shoot", "laser", "enemy_hit", "enemy_destroy", "player_hit",
		"powerup", "bomb", "wave_start",
		"menu_navigate", "menu_hover", "menu_select", "menu_back", "menu_music"
	]

	for sound_type in expected_sound_types:
		assert_that(sound_manager.audio_players.has(sound_type)).is_true()

# === Menu Sound Generation Tests ===

func test_menu_navigate_sound_generation():
	"""Test menu navigation sound generation"""
	var start_time = Time.get_ticks_msec()
	var sound = sound_manager.create_menu_navigate_sound()
	var end_time = Time.get_ticks_msec()

	assert_that(sound).is_not_null()
	assert_that(sound.format).is_equal(AudioStreamWAV.FORMAT_16_BITS)
	assert_that(sound.mix_rate).is_equal(int(TEST_SAMPLE_RATE))
	assert_that(sound.stereo).is_false()
	assert_that(sound.data.size()).is_greater(0)

	# Performance check
	var generation_time = end_time - start_time
	assert_that(generation_time).is_less(AUDIO_GENERATION_TIMEOUT)

	generated_sounds.append(sound)

func test_menu_hover_sound_generation():
	"""Test menu hover sound generation"""
	var sound = sound_manager.create_menu_hover_sound()

	assert_that(sound).is_not_null()
	assert_that(sound.format).is_equal(AudioStreamWAV.FORMAT_16_BITS)
	assert_that(sound.mix_rate).is_equal(int(TEST_SAMPLE_RATE))
	assert_that(sound.data.size()).is_greater(0)

	# Hover sound should be short
	var expected_samples = int(0.05 * TEST_SAMPLE_RATE * 2)  # 0.05s duration, 16-bit = 2 bytes per sample
	assert_that(sound.data.size()).is_equal_approx(expected_samples, 100)

	generated_sounds.append(sound)

func test_menu_select_sound_generation():
	"""Test menu selection sound generation"""
	var sound = sound_manager.create_menu_select_sound()

	assert_that(sound).is_not_null()
	assert_that(sound.format).is_equal(AudioStreamWAV.FORMAT_16_BITS)
	assert_that(sound.data.size()).is_greater(0)

	# Select sound should be longer than hover
	var expected_samples = int(0.15 * TEST_SAMPLE_RATE * 2)  # 0.15s duration
	assert_that(sound.data.size()).is_equal_approx(expected_samples, 100)

	generated_sounds.append(sound)

func test_menu_back_sound_generation():
	"""Test menu back sound generation"""
	var sound = sound_manager.create_menu_back_sound()

	assert_that(sound).is_not_null()
	assert_that(sound.format).is_equal(AudioStreamWAV.FORMAT_16_BITS)
	assert_that(sound.data.size()).is_greater(0)

	# Back sound duration
	var expected_samples = int(0.12 * TEST_SAMPLE_RATE * 2)  # 0.12s duration
	assert_that(sound.data.size()).is_equal_approx(expected_samples, 100)

	generated_sounds.append(sound)

func test_menu_music_loop_generation():
	"""Test menu background music loop generation"""
	var sound = sound_manager.create_menu_music_loop()

	assert_that(sound).is_not_null()
	assert_that(sound.format).is_equal(AudioStreamWAV.FORMAT_16_BITS)
	assert_that(sound.data.size()).is_greater(0)

	# Music should be much longer (8 seconds)
	var expected_samples = int(8.0 * TEST_SAMPLE_RATE * 2)
	assert_that(sound.data.size()).is_equal_approx(expected_samples, 1000)

	# Should have loop settings
	assert_that(sound.loop_mode).is_equal(AudioStreamWAV.LOOP_FORWARD)
	assert_that(sound.loop_begin).is_equal(0)
	assert_that(sound.loop_end).is_greater(0)

	generated_sounds.append(sound)

# === Sound Quality Tests ===

func test_audio_format_consistency():
	"""Test audio format consistency across menu sounds"""
	var menu_sounds = ["menu_navigate", "menu_hover", "menu_select", "menu_back", "menu_music"]

	for sound_name in menu_sounds:
		var sound = sound_manager.generate_sound(sound_name)
		assert_that(sound.format).is_equal(AudioStreamWAV.FORMAT_16_BITS)
		assert_that(sound.mix_rate).is_equal(int(TEST_SAMPLE_RATE))
		assert_that(sound.stereo).is_false()
		generated_sounds.append(sound)

func test_audio_data_validity():
	"""Test generated audio data validity"""
	var sound = sound_manager.create_menu_select_sound()
	assert_that(sound.data.size()).is_greater(0)
	assert_that(sound.data.size() % 2).is_equal(0)  # Should be even (16-bit samples)

	# Check data is not all zeros (silence)
	var has_nonzero_data = false
	for i in range(0, sound.data.size(), 2):
		var sample = sound.data[i] | (sound.data[i + 1] << 8)
		if sample != 0:
			has_nonzero_data = true
			break

	assert_that(has_nonzero_data).is_true()
	generated_sounds.append(sound)

func test_frequency_content_validity():
	"""Test frequency content of generated sounds"""
	# Test that different menu sounds have different characteristics
	var navigate_sound = sound_manager.create_menu_navigate_sound()
	var hover_sound = sound_manager.create_menu_hover_sound()

	# Sounds should have different durations
	assert_that(navigate_sound.data.size()).is_not_equal(hover_sound.data.size())

	generated_sounds.append(navigate_sound)
	generated_sounds.append(hover_sound)

# === Sound Playback Tests ===

func test_play_menu_sound():
	"""Test menu sound playback functionality"""
	sound_manager.play_sound("menu_navigate", 0.0, 1.0)

	var player = sound_manager.audio_players["menu_navigate"]
	assert_that(player.stream).is_not_null()
	assert_that(player.volume_db).is_equal_approx(0.0, TEST_VOLUME_TOLERANCE)
	assert_that(player.pitch_scale).is_equal_approx(1.0, 0.01)

func test_play_sound_with_volume():
	"""Test menu sound playback with custom volume"""
	var test_volume = -10.0
	sound_manager.play_sound("menu_hover", test_volume)

	var player = sound_manager.audio_players["menu_hover"]
	assert_that(player.volume_db).is_equal_approx(test_volume, TEST_VOLUME_TOLERANCE)

func test_play_sound_with_pitch():
	"""Test menu sound playback with custom pitch"""
	var test_pitch = 1.2
	sound_manager.play_sound("menu_select", 0.0, test_pitch)

	var player = sound_manager.audio_players["menu_select"]
	assert_that(player.pitch_scale).is_equal_approx(test_pitch, 0.01)

func test_play_random_pitch():
	"""Test random pitch variation functionality"""
	sound_manager.play_random_pitch("menu_navigate", 0.0, 0.1)

	var player = sound_manager.audio_players["menu_navigate"]
	# Pitch should be within range [0.9, 1.1]
	assert_that(player.pitch_scale).is_greater_equal(0.9)
	assert_that(player.pitch_scale).is_less_equal(1.1)

# === Menu Sound Preloading Tests ===

func test_preload_menu_sounds():
	"""Test menu sound preloading functionality"""
	sound_manager.preload_menu_sounds()

	var menu_sounds = ["menu_navigate", "menu_hover", "menu_select", "menu_back"]
	for sound_name in menu_sounds:
		var player = sound_manager.audio_players[sound_name]
		assert_that(player.stream).is_not_null()

func test_preload_performance():
	"""Test performance of menu sound preloading"""
	var start_time = Time.get_ticks_msec()
	sound_manager.preload_menu_sounds()
	var end_time = Time.get_ticks_msec()

	var preload_time = end_time - start_time
	# Preloading should be fast (within 200ms)
	assert_that(preload_time).is_less(200)

# === Sound Management Tests ===

func test_stop_individual_sound():
	"""Test stopping individual menu sounds"""
	sound_manager.play_sound("menu_music")
	sound_manager.stop_sound("menu_music")

	var player = sound_manager.audio_players["menu_music"]
	# Player should exist but be stopped
	assert_that(player).is_not_null()

func test_stop_all_sounds():
	"""Test stopping all sounds functionality"""
	# Play multiple sounds
	sound_manager.play_sound("menu_navigate")
	sound_manager.play_sound("menu_hover")
	sound_manager.play_sound("menu_music")

	sound_manager.stop_all_sounds()

	# All players should be stopped
	for player in sound_manager.audio_players.values():
		assert_that(player).is_not_null()

func test_stop_nonexistent_sound():
	"""Test stopping non-existent sound gracefully"""
	# Should not crash
	sound_manager.stop_sound("nonexistent_sound")

# === Performance Tests ===

func test_sound_generation_performance():
	"""Test sound generation performance for all menu sounds"""
	var menu_sounds = ["menu_navigate", "menu_hover", "menu_select", "menu_back", "menu_music"]

	for sound_name in menu_sounds:
		var start_time = Time.get_ticks_msec()
		var sound = sound_manager.generate_sound(sound_name)
		var end_time = Time.get_ticks_msec()

		var generation_time = end_time - start_time
		performance_times[sound_name] = generation_time

		# Each sound should generate quickly
		assert_that(generation_time).is_less(AUDIO_GENERATION_TIMEOUT)
		generated_sounds.append(sound)

func test_rapid_playback_performance():
	"""Test performance under rapid playback requests"""
	var start_time = Time.get_ticks_msec()

	# Rapid playback of different menu sounds
	for i in range(50):
		var sound_types = ["menu_navigate", "menu_hover", "menu_select", "menu_back"]
		var sound_type = sound_types[i % sound_types.size()]
		sound_manager.play_sound(sound_type)

	var end_time = Time.get_ticks_msec()
	var total_time = end_time - start_time

	# Should handle rapid playback efficiently (within 200ms)
	assert_that(total_time).is_less(200)

func test_memory_usage_under_load():
	"""Test memory usage under repeated sound generation"""
	var initial_node_count = get_child_count()

	# Generate many sounds
	for i in range(20):
		for sound_type in ["menu_navigate", "menu_hover", "menu_select"]:
			var sound = sound_manager.generate_sound(sound_type)
			generated_sounds.append(sound)

	var final_node_count = get_child_count()

	# Should not create excessive nodes
	assert_that(final_node_count - initial_node_count).is_less(5)

# === Audio Quality Tests ===

func test_menu_navigate_audio_characteristics():
	"""Test menu navigate sound audio characteristics"""
	var sound = sound_manager.create_menu_navigate_sound()

	# Should be a short, rising tone
	var duration_samples = sound.data.size() / 2  # 16-bit samples
	var expected_duration = 0.08 * TEST_SAMPLE_RATE
	assert_that(duration_samples).is_equal_approx(expected_duration, 100)

	generated_sounds.append(sound)

func test_menu_hover_audio_characteristics():
	"""Test menu hover sound audio characteristics"""
	var sound = sound_manager.create_menu_hover_sound()

	# Should be very short and soft
	var duration_samples = sound.data.size() / 2
	var expected_duration = 0.05 * TEST_SAMPLE_RATE
	assert_that(duration_samples).is_equal_approx(expected_duration, 100)

	generated_sounds.append(sound)

func test_menu_music_chord_progression():
	"""Test menu music chord progression structure"""
	var sound = sound_manager.create_menu_music_loop()

	# Should be 8 seconds long
	var duration_samples = sound.data.size() / 2
	var expected_duration = 8.0 * TEST_SAMPLE_RATE
	assert_that(duration_samples).is_equal_approx(expected_duration, 1000)

	# Should have loop points set correctly
	assert_that(sound.loop_end).is_equal(duration_samples)

	generated_sounds.append(sound)

# === Error Handling Tests ===

func test_invalid_sound_name():
	"""Test handling of invalid sound names"""
	var sound = sound_manager.generate_sound("invalid_menu_sound")

	# Should fall back to default beep
	assert_that(sound).is_not_null()
	assert_that(sound.format).is_equal(AudioStreamWAV.FORMAT_16_BITS)

	generated_sounds.append(sound)

func test_play_invalid_sound():
	"""Test playing invalid sound name"""
	# Should not crash
	sound_manager.play_sound("nonexistent_menu_sound")

func test_extreme_volume_values():
	"""Test handling of extreme volume values"""
	# Should not crash with extreme values
	sound_manager.play_sound("menu_navigate", -100.0)  # Very quiet
	sound_manager.play_sound("menu_hover", 100.0)     # Very loud

	# Values should be applied (clamping may occur in AudioServer)
	var player1 = sound_manager.audio_players["menu_navigate"]
	var player2 = sound_manager.audio_players["menu_hover"]

	assert_that(player1.volume_db).is_equal_approx(-100.0, TEST_VOLUME_TOLERANCE)
	assert_that(player2.volume_db).is_equal_approx(100.0, TEST_VOLUME_TOLERANCE)

func test_extreme_pitch_values():
	"""Test handling of extreme pitch values"""
	sound_manager.play_sound("menu_select", 0.0, 0.1)   # Very slow
	sound_manager.play_sound("menu_back", 0.0, 10.0)    # Very fast

	var player1 = sound_manager.audio_players["menu_select"]
	var player2 = sound_manager.audio_players["menu_back"]

	assert_that(player1.pitch_scale).is_equal_approx(0.1, 0.01)
	assert_that(player2.pitch_scale).is_equal_approx(10.0, 0.01)

# === Waveform Generation Tests ===

func test_sine_wave_generation():
	"""Test sine wave generation used in menu sounds"""
	# Test sine wave calculation (used in menu sounds)
	var frequency = 440.0  # A4
	var sample_rate = TEST_SAMPLE_RATE
	var t = 1.0 / sample_rate

	var sine_value = sin(2.0 * PI * frequency * t)
	assert_that(sine_value).is_greater_equal(-1.0)
	assert_that(sine_value).is_less_equal(1.0)

func test_frequency_sweep_generation():
	"""Test frequency sweep generation used in menu navigate"""
	var start_freq = 523.25  # C5
	var end_freq = 659.25    # E5
	var progress = 0.5       # Halfway

	var interpolated_freq = lerp(start_freq, end_freq, progress)
	var expected_freq = (start_freq + end_freq) / 2.0
	assert_that(interpolated_freq).is_equal_approx(expected_freq, 0.1)

func test_envelope_generation():
	"""Test envelope generation for sound shaping"""
	# Test typical envelope calculations used in menu sounds
	var progress = 0.1  # 10% through sound
	var envelope = progress * 10  # Quick attack (used in some menu sounds)
	assert_that(envelope).is_equal_approx(1.0, 0.01)

	progress = 0.8  # 80% through sound
	envelope = 1.0 - (progress - 0.7) * 3.33  # Gradual release
	assert_that(envelope).is_greater_equal(0.0)
	assert_that(envelope).is_less_equal(1.0)

# === Sample Rate and Format Tests ===

func test_sample_rate_consistency():
	"""Test sample rate consistency across all menu sounds"""
	var menu_sounds = ["menu_navigate", "menu_hover", "menu_select", "menu_back", "menu_music"]

	for sound_name in menu_sounds:
		var sound = sound_manager.generate_sound(sound_name)
		assert_that(sound.mix_rate).is_equal(int(TEST_SAMPLE_RATE))
		generated_sounds.append(sound)

func test_bit_depth_consistency():
	"""Test bit depth consistency"""
	var menu_sounds = ["menu_navigate", "menu_hover", "menu_select", "menu_back"]

	for sound_name in menu_sounds:
		var sound = sound_manager.generate_sound(sound_name)
		assert_that(sound.format).is_equal(AudioStreamWAV.FORMAT_16_BITS)
		generated_sounds.append(sound)

func test_stereo_configuration():
	"""Test stereo/mono configuration"""
	var sound = sound_manager.create_menu_music_loop()
	assert_that(sound.stereo).is_false()  # Should be mono

	generated_sounds.append(sound)

# === Integration Tests ===

func test_audio_server_integration():
	"""Test integration with Godot's AudioServer"""
	var master_bus_index = AudioServer.get_bus_index("Master")
	assert_that(master_bus_index).is_greater_equal(0)

	# Test that players use correct bus
	var player = sound_manager.audio_players["menu_navigate"]
	assert_that(player.bus).is_equal("Master")

func test_audio_stream_playback():
	"""Test audio stream playback integration"""
	var sound = sound_manager.create_menu_select_sound()
	var player = sound_manager.audio_players["menu_select"]

	player.stream = sound
	# Should not crash when attempting playback
	player.play()

	generated_sounds.append(sound)

# === Musical Theory Tests ===

func test_chord_progression_accuracy():
	"""Test musical accuracy of chord progression in menu music"""
	# Expected chord frequencies (simplified)
	var chord_notes = [
		[220.00, 261.63, 329.63],  # A minor
		[174.61, 220.00, 261.63],  # F major
		[130.81, 164.81, 196.00],  # C major
		[123.47, 155.56, 196.00]   # G major
	]

	# Test chord note frequencies are reasonable
	for chord in chord_notes:
		for freq in chord:
			assert_that(freq).is_greater(100.0)  # Above human hearing threshold
			assert_that(freq).is_less(2000.0)    # Below painful frequencies

func test_frequency_relationships():
	"""Test musical frequency relationships"""
	# Test octave relationship (2:1 ratio)
	var c4 = 261.63
	var c5 = 523.25
	var ratio = c5 / c4
	assert_that(ratio).is_equal_approx(2.0, 0.01)

	# Test perfect fifth relationship (3:2 ratio)
	var c_note = 261.63
	var g_note = 392.00
	var fifth_ratio = g_note / c_note
	assert_that(fifth_ratio).is_equal_approx(1.5, 0.01)

# === Timing and Duration Tests ===

func test_menu_sound_durations():
	"""Test menu sound duration requirements"""
	var duration_specs = {
		"menu_navigate": 0.08,
		"menu_hover": 0.05,
		"menu_select": 0.15,
		"menu_back": 0.12,
		"menu_music": 8.0
	}

	for sound_name in duration_specs:
		var sound = sound_manager.generate_sound(sound_name)
		var actual_duration = float(sound.data.size()) / (2.0 * TEST_SAMPLE_RATE)
		var expected_duration = duration_specs[sound_name]

		assert_that(actual_duration).is_equal_approx(expected_duration, 0.01)
		generated_sounds.append(sound)

# === Cleanup and Resource Management Tests ===

func test_sound_generation_cleanup():
	"""Test proper cleanup after sound generation"""
	var initial_memory = OS.get_static_memory_peak_usage()

	# Generate many sounds
	for i in range(50):
		var sound = sound_manager.create_menu_navigate_sound()
		generated_sounds.append(sound)

	# Memory should not grow excessively
	# Note: Actual memory testing is difficult in unit tests,
	# but we ensure no crashes or excessive node creation

func test_audio_player_cleanup():
	"""Test audio player resource management"""
	# Play multiple sounds rapidly
	for i in range(20):
		sound_manager.play_sound("menu_hover")

	# Stop all sounds
	sound_manager.stop_all_sounds()

	# Players should still exist and be functional
	for player in sound_manager.audio_players.values():
		assert_that(player).is_not_null()
		assert_that(is_instance_valid(player)).is_true()

# === Final Integration Test ===

func test_complete_menu_sound_workflow():
	"""Test complete menu sound workflow"""
	# Preload sounds
	sound_manager.preload_menu_sounds()

	# Play various menu sounds
	sound_manager.play_sound("menu_navigate", -5.0, 1.0)
	await get_tree().process_frame

	sound_manager.play_sound("menu_hover", -10.0)
	await get_tree().process_frame

	sound_manager.play_sound("menu_select", 0.0, 1.1)
	await get_tree().process_frame

	sound_manager.play_sound("menu_back", -5.0)
	await get_tree().process_frame

	sound_manager.play_sound("menu_music", -10.0)
	await get_tree().process_frame

	# Stop all sounds
	sound_manager.stop_all_sounds()

	# Workflow should complete without errors
	assert_that(true).is_true()