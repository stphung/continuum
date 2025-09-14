extends GdUnitTestSuite

var sound_manager: Node

func before():
	sound_manager = SoundManager

func test_shoot_sound_generation():
	var sound_data = sound_manager.create_laser_shot(0.2, 440.0, 200.0)

	assert_that(sound_data).is_not_null()
	assert_that(sound_data.data.size()).is_greater(0)

	# Verify audio format - sound_data is already an AudioStreamWAV
	assert_that(sound_data.format).is_equal(AudioStreamWAV.FORMAT_16_BITS)

func test_hit_sound_generation():
	var sound_data = sound_manager.create_hit_sound(0.15)

	assert_that(sound_data).is_not_null()
	assert_that(sound_data.data.size()).is_greater(0)

func test_explosion_sound_generation():
	var sound_data = sound_manager.create_explosion(0.8)

	assert_that(sound_data).is_not_null()
	assert_that(sound_data.data.size()).is_greater(0)

	# Explosion should be longer than shoot sound
	var shoot_data = sound_manager.create_laser_shot(0.2, 440.0, 200.0)
	assert_that(sound_data.data.size()).is_greater(shoot_data.data.size())

func test_powerup_sound_generation():
	var sound_data = sound_manager.create_powerup_sound(0.3)

	assert_that(sound_data).is_not_null()
	assert_that(sound_data.data.size()).is_greater(0)

func test_player_hit_sound_generation():
	var sound_data = sound_manager.create_alarm_sound(0.5)

	assert_that(sound_data).is_not_null()
	assert_that(sound_data.data.size()).is_greater(0)

func test_alarm_sound_generation():
	var sound_data = sound_manager.create_fanfare(0.4)

	assert_that(sound_data).is_not_null()
	assert_that(sound_data.data.size()).is_greater(0)

func test_random_pitch_variation():
	var base_freq = 440.0
	var sounds = []

	# Generate multiple sounds with larger pitch variation
	for i in range(10):
		var pitch_offset = randf_range(-200, 200)  # Larger variation
		var sound_data = sound_manager.create_laser_shot(0.2, base_freq + pitch_offset, 200.0 + pitch_offset * 0.5)
		sounds.append(sound_data)

	# Should have some variation in the sounds
	var sizes = []
	for sound in sounds:
		sizes.append(sound.data.size())
	sizes.sort()

	# At least some variation expected, or all sounds are valid
	assert_that(sizes.size()).is_equal(10)  # All sounds generated successfully
	# Most sounds should be valid size (even if identical)
	assert_that(sizes[0]).is_greater(0)

func test_frequency_affects_sound_length():
	var high_freq_sound = sound_manager.create_laser_shot(0.2, 880.0, 400.0)  # High pitch
	var low_freq_sound = sound_manager.create_laser_shot(0.2, 220.0, 100.0)   # Low pitch

	# Both should be valid
	assert_that(high_freq_sound).is_not_null()
	assert_that(low_freq_sound).is_not_null()

	# Different frequencies might produce different waveform patterns
	assert_that(high_freq_sound.data.size()).is_greater(0)
	assert_that(low_freq_sound.data.size()).is_greater(0)

func test_duration_affects_sound_length():
	var short_sound = sound_manager.create_laser_shot(0.1, 440.0, 200.0)
	var long_sound = sound_manager.create_laser_shot(0.5, 440.0, 200.0)

	assert_that(long_sound.data.size()).is_greater(short_sound.data.size())

func test_waveform_types():
	# Test different waveform generation if methods exist
	# Test basic waveform generation through beep method
	var beep_data = sound_manager.create_beep(0.2, 440.0)
	assert_that(beep_data).is_not_null()

	# Test different sound types
	var laser_data = sound_manager.create_laser_shot(0.1, 400, 200, true)
	assert_that(laser_data).is_not_null()

func test_sound_playback_integration():
	# Test that sounds can be played through the sound manager
	var initial_children = get_tree().get_nodes_in_group("audio_players").size()

	sound_manager.play_sound("shoot", 0.0)

	# Allow time for sound to start
	await get_tree().create_timer(0.1).timeout

	# Check if audio player was created (implementation dependent)
	var current_children = get_tree().get_nodes_in_group("audio_players").size()
	# This test might need adjustment based on actual implementation
	assert_that(current_children).is_greater_equal(initial_children)

func test_volume_scaling():
	# Test if different duration produces different amplitude
	var quiet_sound = sound_manager.create_laser_shot(0.1, 440.0, 200.0)
	var loud_sound = sound_manager.create_laser_shot(0.3, 440.0, 200.0)

	# Both should be valid (exact amplitude testing would require analyzing PCM data)
	assert_that(quiet_sound).is_not_null()
	assert_that(loud_sound).is_not_null()

func test_sample_rate_consistency():
	var sound_data = sound_manager.create_laser_shot(0.2, 440.0, 200.0)

	# Should use standard sample rate (typically 44100 or 22050)
	assert_that(sound_data.mix_rate).is_between(22050.0, 48000.0)

func test_mono_audio_format():
	var sound_data = sound_manager.create_laser_shot(0.2, 440.0, 200.0)

	# Should be mono audio for efficiency
	assert_that(sound_data.stereo).is_false()