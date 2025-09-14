extends Node

var audio_players = {}
var sample_rate = 44100.0
var active_streams = []

func _ready():
	# Create audio players for different sound types (including menu sounds)
	var sound_types = ["shoot", "laser", "enemy_hit", "enemy_destroy", "player_hit", "powerup", "bomb", "wave_start",
					  "menu_navigate", "menu_hover", "menu_select", "menu_back", "menu_music"]
	for sound_type in sound_types:
		var player = AudioStreamPlayer.new()
		player.name = sound_type
		player.bus = "Master"
		add_child(player)
		audio_players[sound_type] = player

func play_sound(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0):
	if sound_name in audio_players:
		var player = audio_players[sound_name]

		# Clean up old stream before assigning new one
		if player.stream:
			var old_stream = player.stream
			if old_stream in active_streams:
				active_streams.erase(old_stream)
			# Clear PCM data to free memory
			if is_instance_valid(old_stream):
				old_stream.data.clear()

		var stream = generate_sound(sound_name)
		if stream:
			active_streams.append(stream)
			player.stream = stream
			player.volume_db = volume_db
			player.pitch_scale = pitch
			player.play()

			# Connect to finished signal to cleanup stream when done
			if not player.finished.is_connected(_on_sound_finished):
				player.finished.connect(_on_sound_finished.bind(player))

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
		"menu_navigate":
			return create_menu_navigate_sound()
		"menu_hover":
			return create_menu_hover_sound()
		"menu_select":
			return create_menu_select_sound()
		"menu_back":
			return create_menu_back_sound()
		"menu_music":
			return create_menu_music_loop()
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
		var player = audio_players[sound_name]
		player.stop()
		# Clean up stream reference when stopping
		if player.stream and player.stream in active_streams:
			active_streams.erase(player.stream)
		player.stream = null

func stop_all_sounds():
	for player in audio_players.values():
		if is_instance_valid(player):
			player.stop()
			# Clean up stream reference when stopping all
			if player.stream:
				var stream = player.stream
				if stream in active_streams:
					active_streams.erase(stream)
				# Clear PCM data to free memory
				if is_instance_valid(stream):
					stream.data.clear()
				player.stream = null

func _on_sound_finished(player: AudioStreamPlayer):
	# Clean up stream reference when sound finishes playing
	if player.stream:
		var stream = player.stream
		if stream in active_streams:
			active_streams.erase(stream)
		# Clear PCM data to free memory
		if is_instance_valid(stream):
			stream.data.clear()
		player.stream = null

func _exit_tree():
	# Clean up all active streams on exit
	stop_all_sounds()

	# Explicitly free all AudioStreamWAV resources
	for stream in active_streams:
		if is_instance_valid(stream):
			stream.data.clear()  # Clear PCM data
	active_streams.clear()

	# Clean up audio players
	for player in audio_players.values():
		if is_instance_valid(player):
			if player.stream:
				# Ensure stream reference is cleared before freeing player
				var stream = player.stream
				player.stream = null
				if is_instance_valid(stream):
					stream.data.clear()
			player.call_deferred("queue_free")
	audio_players.clear()

# Menu Audio Generation Functions - Professional Title Screen System

func preload_menu_sounds():
	"""Pre-generate essential menu sounds for immediate availability"""
	# This helps avoid audio delays during menu navigation
	var menu_sounds = ["menu_navigate", "menu_hover", "menu_select", "menu_back"]
	for sound in menu_sounds:
		var stream = generate_sound(sound)
		if audio_players.has(sound):
			active_streams.append(stream)
			audio_players[sound].stream = stream

func create_menu_navigate_sound() -> AudioStreamWAV:
	"""Generate subtle navigation sound for menu movement"""
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.stereo = false

	var duration = 0.08
	var num_samples = int(duration * sample_rate)
	var audio_data = PackedByteArray()

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = float(i) / num_samples

		# Two-tone blip: C5 to E5
		var freq1 = 523.25  # C5
		var freq2 = 659.25  # E5
		var freq = lerp(freq1, freq2, progress)

		# Clean sine wave with soft attack/release
		var sample = sin(2.0 * PI * freq * t) * 0.3

		# Envelope with quick attack and smooth release
		var envelope = 1.0
		if progress < 0.1:
			envelope = progress * 10
		elif progress > 0.6:
			envelope = 1.0 - (progress - 0.6) * 2.5

		sample *= envelope

		var int_sample = int(clamp(sample * 32767, -32768, 32767))
		audio_data.append(int_sample & 0xFF)
		audio_data.append((int_sample >> 8) & 0xFF)

	stream.data = audio_data
	return stream

func create_menu_hover_sound() -> AudioStreamWAV:
	"""Generate soft hover feedback sound"""
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.stereo = false

	var duration = 0.05
	var num_samples = int(duration * sample_rate)
	var audio_data = PackedByteArray()

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = float(i) / num_samples

		# Single pure tone - G5
		var freq = 783.99  # G5

		# Very soft sine wave
		var sample = sin(2.0 * PI * freq * t) * 0.15

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

func create_menu_select_sound() -> AudioStreamWAV:
	"""Generate confirmation sound for menu selection"""
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.stereo = false

	var duration = 0.15
	var num_samples = int(duration * sample_rate)
	var audio_data = PackedByteArray()

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = float(i) / num_samples

		# Rising chord: G4 -> C5 -> E5
		var base_freq = 392.00  # G4
		var chord_progress = progress * 2.0
		var freq = base_freq

		if chord_progress < 1.0:
			freq = lerp(392.00, 523.25, chord_progress)  # G4 to C5
		else:
			freq = lerp(523.25, 659.25, chord_progress - 1.0)  # C5 to E5

		# Rich harmonic content for satisfying sound
		var sample = sin(2.0 * PI * freq * t) * 0.4
		sample += sin(2.0 * PI * freq * 2 * t) * 0.15  # Octave
		sample += sin(2.0 * PI * freq * 1.5 * t) * 0.1  # Fifth

		# Professional envelope with sustain
		var envelope = 1.0
		if progress < 0.02:
			envelope = progress * 50  # Quick attack
		elif progress > 0.7:
			envelope = 1.0 - (progress - 0.7) * 3.33  # Gradual release

		sample *= envelope

		var int_sample = int(clamp(sample * 32767, -32768, 32767))
		audio_data.append(int_sample & 0xFF)
		audio_data.append((int_sample >> 8) & 0xFF)

	stream.data = audio_data
	return stream

func create_menu_back_sound() -> AudioStreamWAV:
	"""Generate back/cancel sound for menu navigation"""
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.stereo = false

	var duration = 0.12
	var num_samples = int(duration * sample_rate)
	var audio_data = PackedByteArray()

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = float(i) / num_samples

		# Descending tone: E5 to C5
		var freq = lerp(659.25, 523.25, progress)  # E5 to C5

		# Softer tone with slight modulation
		var sample = sin(2.0 * PI * freq * t) * 0.25
		sample += sin(2.0 * PI * freq * 0.995 * t) * 0.15  # Slight detune for warmth

		# Smooth envelope
		var envelope = 1.0 - progress
		if progress < 0.05:
			envelope = progress * 20

		sample *= envelope

		var int_sample = int(clamp(sample * 32767, -32768, 32767))
		audio_data.append(int_sample & 0xFF)
		audio_data.append((int_sample >> 8) & 0xFF)

	stream.data = audio_data
	return stream

func create_menu_music_loop() -> AudioStreamWAV:
	"""Generate ambient menu background music loop"""
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.stereo = false

	var duration = 8.0  # 8-second loop
	var num_samples = int(duration * sample_rate)
	var audio_data = PackedByteArray()

	# Chord progression: Am - F - C - G (in simplified form)
	var chord_notes = [
		[220.00, 261.63, 329.63],  # A minor (A3, C4, E4)
		[174.61, 220.00, 261.63],  # F major (F3, A3, C4)
		[130.81, 164.81, 196.00],  # C major (C3, E3, G3)
		[123.47, 155.56, 196.00]   # G major (B2, D3, G3)
	]

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = float(i) / num_samples

		# Determine which chord (2 seconds each)
		var chord_index = int(progress * 4) % 4
		var chord = chord_notes[chord_index]
		var chord_progress = fmod(progress * 4, 1.0)

		# Generate chord tones with slow attack/release
		var sample = 0.0
		for note_freq in chord:
			var note_sample = sin(2.0 * PI * note_freq * t) * 0.08
			# Add slight detuning and phase for richness
			note_sample += sin(2.0 * PI * note_freq * 1.002 * t) * 0.05
			sample += note_sample

		# Add pad-like texture with higher harmonics
		var bass_freq = chord[0]
		sample += sin(2.0 * PI * bass_freq * 0.5 * t) * 0.04  # Sub-bass

		# Smooth chord transitions
		var chord_envelope = 1.0
		if chord_progress < 0.1:
			chord_envelope = chord_progress * 10  # Fade in
		elif chord_progress > 0.9:
			chord_envelope = 1.0 - (chord_progress - 0.9) * 10  # Fade out

		# Overall gentle envelope for seamless looping
		var loop_envelope = 0.8  # Keep it subtle
		if progress < 0.01:
			loop_envelope = progress * 80
		elif progress > 0.99:
			loop_envelope = 1.0 - (progress - 0.99) * 80

		sample *= chord_envelope * loop_envelope

		var int_sample = int(clamp(sample * 32767, -32768, 32767))
		audio_data.append(int_sample & 0xFF)
		audio_data.append((int_sample >> 8) & 0xFF)

	stream.data = audio_data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD  # Enable looping
	stream.loop_begin = 0
	stream.loop_end = num_samples
	return stream
