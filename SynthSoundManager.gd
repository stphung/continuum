extends Node

var audio_players = {}
var sample_rate = 44100.0

func _ready():
	# Create audio players for different sound types
	var sound_types = ["shoot", "laser", "enemy_hit", "enemy_destroy", "player_hit", "powerup", "bomb", "wave_start"]
	for sound_type in sound_types:
		var player = AudioStreamPlayer.new()
		player.name = sound_type
		player.bus = "Master"
		add_child(player)
		audio_players[sound_type] = player

func play_sound(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0):
	if sound_name in audio_players:
		var player = audio_players[sound_name]
		var stream = generate_sound(sound_name)
		if stream:
			player.stream = stream
			player.volume_db = volume_db
			player.pitch_scale = pitch
			player.play()

func play_random_pitch(sound_name: String, volume_db: float = 0.0, pitch_range: float = 0.1):
	var random_pitch = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
	play_sound(sound_name, volume_db, random_pitch)

func generate_sound(sound_type: String) -> AudioStreamWAV:
	match sound_type:
		"shoot":
			return create_laser_shot(0.05, 800, 400)
		"laser":
			return create_laser_shot(0.1, 400, 200, true)
		"enemy_hit":
			return create_hit_sound(0.05)
		"enemy_destroy":
			return create_explosion(0.3)
		"player_hit":
			return create_alarm_sound(0.2)
		"powerup":
			return create_powerup_sound(0.2)
		"bomb":
			return create_big_explosion(0.5)
		"wave_start":
			return create_fanfare(0.5)
		_:
			return create_beep(0.1, 440)

func create_laser_shot(duration: float, start_freq: float, end_freq: float, with_reverb: bool = false) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.stereo = false
	
	var num_samples = int(duration * sample_rate)
	var audio_data = PackedByteArray()
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = float(i) / num_samples
		
		# Frequency sweep
		var freq = lerp(start_freq, end_freq, progress)
		
		# Generate waveform (combination of saw and square for "laser" sound)
		var sample = 0.0
		sample += sin(2.0 * PI * freq * t) * 0.3  # Sine wave
		sample += (fmod(freq * t, 1.0) - 0.5) * 0.3  # Saw wave
		sample += sign(sin(2.0 * PI * freq * t)) * 0.2  # Square wave
		
		# Add some noise for texture
		sample += (randf() - 0.5) * 0.1 * (1.0 - progress)
		
		# Envelope (quick attack, gradual decay)
		var envelope = 1.0 - progress
		if progress < 0.01:
			envelope = progress * 100
		
		sample *= envelope
		
		# Add reverb tail for laser
		if with_reverb and progress > 0.5:
			sample += sin(2.0 * PI * freq * 0.5 * t) * 0.1 * (1.0 - progress)
		
		# Convert to 16-bit integer
		var int_sample = int(clamp(sample * 32767, -32768, 32767))
		audio_data.append(int_sample & 0xFF)
		audio_data.append((int_sample >> 8) & 0xFF)
	
	stream.data = audio_data
	return stream

func create_hit_sound(duration: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.stereo = false
	
	var num_samples = int(duration * sample_rate)
	var audio_data = PackedByteArray()
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = float(i) / num_samples
		
		# White noise burst with pitch bend
		var sample = (randf() - 0.5)
		
		# Add some tonal elements
		sample += sin(2.0 * PI * (200 + progress * 100) * t) * 0.3
		
		# Quick decay envelope
		var envelope = pow(1.0 - progress, 2.0)
		sample *= envelope
		
		var int_sample = int(clamp(sample * 32767, -32768, 32767))
		audio_data.append(int_sample & 0xFF)
		audio_data.append((int_sample >> 8) & 0xFF)
	
	stream.data = audio_data
	return stream

func create_explosion(duration: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.stereo = false
	
	var num_samples = int(duration * sample_rate)
	var audio_data = PackedByteArray()
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = float(i) / num_samples
		
		# Brown noise (low frequency noise)
		var sample = 0.0
		if i == 0:
			sample = randf() - 0.5
		else:
			sample = (randf() - 0.5) * 0.1
		
		# Add low frequency rumble
		sample += sin(2.0 * PI * (50 - progress * 30) * t) * 0.5
		sample += sin(2.0 * PI * (100 - progress * 70) * t) * 0.3
		
		# Add crack at the beginning
		if progress < 0.05:
			sample += (randf() - 0.5) * (1.0 - progress * 20)
		
		# Exponential decay
		var envelope = pow(1.0 - progress, 1.5)
		sample *= envelope
		
		var int_sample = int(clamp(sample * 32767, -32768, 32767))
		audio_data.append(int_sample & 0xFF)
		audio_data.append((int_sample >> 8) & 0xFF)
	
	stream.data = audio_data
	return stream

func create_big_explosion(duration: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.stereo = false
	
	var num_samples = int(duration * sample_rate)
	var audio_data = PackedByteArray()
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = float(i) / num_samples
		
		# Multiple layers of noise and low frequencies
		var sample = 0.0
		
		# Initial blast
		if progress < 0.1:
			sample += (randf() - 0.5) * (1.0 - progress * 10)
		
		# Brown noise
		sample += (randf() - 0.5) * 0.3
		
		# Multiple low frequency layers for rumble
		sample += sin(2.0 * PI * (30 - progress * 20) * t) * 0.6
		sample += sin(2.0 * PI * (60 - progress * 40) * t) * 0.4
		sample += sin(2.0 * PI * (90 - progress * 60) * t) * 0.3
		
		# Sub-bass sweep
		if progress < 0.3:
			sample += sin(2.0 * PI * (150 - progress * 400) * t) * 0.5
		
		# Envelope with slower decay for bigger explosion
		var envelope = pow(1.0 - progress, 1.2)
		sample *= envelope
		
		var int_sample = int(clamp(sample * 32767, -32768, 32767))
		audio_data.append(int_sample & 0xFF)
		audio_data.append((int_sample >> 8) & 0xFF)
	
	stream.data = audio_data
	return stream

func create_alarm_sound(duration: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.stereo = false
	
	var num_samples = int(duration * sample_rate)
	var audio_data = PackedByteArray()
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = float(i) / num_samples
		
		# Alternating frequency alarm
		var freq = 800 if fmod(t * 8, 1.0) < 0.5 else 600
		
		# Square wave for harsh alarm sound
		var sample = sign(sin(2.0 * PI * freq * t)) * 0.5
		
		# Add harmonics
		sample += sign(sin(2.0 * PI * freq * 2 * t)) * 0.2
		
		# Pulse envelope
		var envelope = 1.0
		if progress > 0.8:
			envelope = 1.0 - (progress - 0.8) * 5
		
		sample *= envelope
		
		var int_sample = int(clamp(sample * 32767, -32768, 32767))
		audio_data.append(int_sample & 0xFF)
		audio_data.append((int_sample >> 8) & 0xFF)
	
	stream.data = audio_data
	return stream

func create_powerup_sound(duration: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.stereo = false
	
	var num_samples = int(duration * sample_rate)
	var audio_data = PackedByteArray()
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = float(i) / num_samples
		
		# Rising arpeggio
		var base_freq = 400
		var arp_step = int(progress * 8) % 4
		var freq = base_freq * pow(1.25, arp_step + progress * 4)
		
		# Clean sine wave with harmonics
		var sample = sin(2.0 * PI * freq * t) * 0.5
		sample += sin(2.0 * PI * freq * 2 * t) * 0.2
		sample += sin(2.0 * PI * freq * 3 * t) * 0.1
		
		# Bell-like envelope
		var envelope = 1.0 - progress
		if progress < 0.05:
			envelope = progress * 20
		
		sample *= envelope
		
		var int_sample = int(clamp(sample * 32767, -32768, 32767))
		audio_data.append(int_sample & 0xFF)
		audio_data.append((int_sample >> 8) & 0xFF)
	
	stream.data = audio_data
	return stream

func create_fanfare(duration: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.stereo = false
	
	var num_samples = int(duration * sample_rate)
	var audio_data = PackedByteArray()
	
	# Musical notes for fanfare (C-E-G-C major chord arpeggio)
	var notes = [261.63, 329.63, 392.00, 523.25]  # C4, E4, G4, C5
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = float(i) / num_samples
		
		# Play notes in sequence
		var note_index = int(progress * 4)
		if note_index >= notes.size():
			note_index = notes.size() - 1
		
		var freq = notes[note_index]
		
		# Rich harmonic content
		var sample = sin(2.0 * PI * freq * t) * 0.4
		sample += sin(2.0 * PI * freq * 2 * t) * 0.2
		sample += sin(2.0 * PI * freq * 3 * t) * 0.1
		sample += sin(2.0 * PI * freq * 0.5 * t) * 0.1  # Sub-harmonic
		
		# Add shimmer
		sample += sin(2.0 * PI * freq * 1.01 * t) * 0.1
		
		# ADSR envelope
		var envelope = 1.0
		if progress < 0.02:
			envelope = progress * 50  # Attack
		elif progress > 0.8:
			envelope = 1.0 - (progress - 0.8) * 5  # Release
		
		sample *= envelope
		
		var int_sample = int(clamp(sample * 32767, -32768, 32767))
		audio_data.append(int_sample & 0xFF)
		audio_data.append((int_sample >> 8) & 0xFF)
	
	stream.data = audio_data
	return stream

func create_beep(duration: float, freq: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.stereo = false
	
	var num_samples = int(duration * sample_rate)
	var audio_data = PackedByteArray()
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var sample = sin(2.0 * PI * freq * t)
		
		var int_sample = int(clamp(sample * 32767, -32768, 32767))
		audio_data.append(int_sample & 0xFF)
		audio_data.append((int_sample >> 8) & 0xFF)
	
	stream.data = audio_data
	return stream

func stop_sound(sound_name: String):
	if sound_name in audio_players:
		audio_players[sound_name].stop()

func stop_all_sounds():
	for player in audio_players.values():
		player.stop()
