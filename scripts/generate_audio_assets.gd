extends SceneTree

func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/audio/ui")
	DirAccess.make_dir_recursive_absolute("res://assets/audio/music")
	
	print("[AUDIO_GEN] Synthesizing UI SFX and ambient loops...")
	
	# 1. UI Hover (0.04s crisp airy tick)
	_generate_wav("res://assets/audio/ui/ui_hover.wav", _synth_hover(), 44100)
	
	# 2. UI Click (0.08s parchment/stone click)
	_generate_wav("res://assets/audio/ui/ui_click.wav", _synth_click(), 44100)
	
	# 3. UI Open (0.22s ethereal swell)
	_generate_wav("res://assets/audio/ui/ui_open.wav", _synth_open(), 44100)
	
	# 4. UI Close (0.18s descending whoosh)
	_generate_wav("res://assets/audio/ui/ui_close.wav", _synth_close(), 44100)
	
	# 5. UI Error / Sin Maná (0.22s dissonant arcane low buzz)
	_generate_wav("res://assets/audio/ui/ui_error.wav", _synth_error(), 44100)
	
	# 6. UI Loot Pickup (0.35s crystal chime arpeggio)
	_generate_wav("res://assets/audio/ui/ui_loot.wav", _synth_loot(), 44100)
	
	# 7. UI Shrine Activation (0.65s resonant power chord)
	_generate_wav("res://assets/audio/ui/ui_shrine.wav", _synth_shrine(), 44100)
	
	# 8. UI Victory (1.2s triumphant fanfare)
	_generate_wav("res://assets/audio/ui/ui_victory.wav", _synth_victory(), 44100)
	
	# 9. UI Defeat (1.4s deep ominous bell)
	_generate_wav("res://assets/audio/ui/ui_defeat.wav", _synth_defeat(), 44100)
	
	# 10. Ambient Exploration Loop (8.0s seamless mystic drone)
	_generate_wav("res://assets/audio/music/ambient_exploration.wav", _synth_ambient_explore(), 44100)
	
	# 11. Ambient Boss Loop (4.0s tense battle pulse)
	_generate_wav("res://assets/audio/music/ambient_boss.wav", _synth_ambient_boss(), 44100)
	
	print("[AUDIO_GEN] All audio files generated successfully!")
	quit(0)

func _synth_hover() -> PackedByteArray:
	var dur = 0.045
	var sr = 44100
	var n_samples = int(dur * sr)
	var samples: Array[float] = []
	for i in range(n_samples):
		var t = float(i) / sr
		var env = exp(-t * 90.0)
		var freq = lerp(480.0, 720.0, float(i) / n_samples)
		var val = sin(2.0 * PI * freq * t) * env * 0.4
		samples.append(val)
	return _samples_to_bytes(samples)

func _synth_click() -> PackedByteArray:
	var dur = 0.07
	var sr = 44100
	var n_samples = int(dur * sr)
	var samples: Array[float] = []
	for i in range(n_samples):
		var t = float(i) / sr
		var env = exp(-t * 60.0)
		var tone = sin(2.0 * PI * 340.0 * t) * 0.45
		var click = (randf() * 2.0 - 1.0) * exp(-t * 180.0) * 0.35
		samples.append((tone + click) * env)
	return _samples_to_bytes(samples)

func _synth_open() -> PackedByteArray:
	var dur = 0.22
	var sr = 44100
	var n_samples = int(dur * sr)
	var samples: Array[float] = []
	for i in range(n_samples):
		var t = float(i) / sr
		var norm = float(i) / n_samples
		var env = sin(norm * PI) * 0.5
		var f1 = sin(2.0 * PI * 261.6 * t) * 0.35 # C4
		var f2 = sin(2.0 * PI * 392.0 * t) * 0.30 # G4
		var f3 = sin(2.0 * PI * 523.2 * t) * 0.25 # C5
		samples.append((f1 + f2 + f3) * env)
	return _samples_to_bytes(samples)

func _synth_close() -> PackedByteArray:
	var dur = 0.18
	var sr = 44100
	var n_samples = int(dur * sr)
	var samples: Array[float] = []
	for i in range(n_samples):
		var t = float(i) / sr
		var env = exp(-t * 22.0)
		var freq = lerp(440.0, 180.0, float(i) / n_samples)
		var val = sin(2.0 * PI * freq * t) * env * 0.45
		samples.append(val)
	return _samples_to_bytes(samples)

func _synth_error() -> PackedByteArray:
	var dur = 0.22
	var sr = 44100
	var n_samples = int(dur * sr)
	var samples: Array[float] = []
	for i in range(n_samples):
		var t = float(i) / sr
		var env = exp(-t * 18.0)
		var f1 = sin(2.0 * PI * 130.8 * t) * 0.4 # C3
		var f2 = sin(2.0 * PI * 138.6 * t) * 0.4 # C#3 (Dissonant beat)
		var buzz = sin(2.0 * PI * 261.6 * t) * 0.2
		samples.append((f1 + f2 + buzz) * env * 0.6)
	return _samples_to_bytes(samples)

func _synth_loot() -> PackedByteArray:
	var dur = 0.38
	var sr = 44100
	var n_samples = int(dur * sr)
	var samples: Array[float] = []
	var notes = [1046.5, 1318.5, 1567.98, 2093.0] # C6, E6, G6, C7
	for i in range(n_samples):
		var t = float(i) / sr
		var s = 0.0
		for n_idx in range(notes.size()):
			var note_start = float(n_idx) * 0.065
			if t >= note_start:
				var note_t = t - note_start
				var note_env = exp(-note_t * 22.0)
				s += sin(2.0 * PI * notes[n_idx] * note_t) * note_env * 0.3
		samples.append(s)
	return _samples_to_bytes(samples)

func _synth_shrine() -> PackedByteArray:
	var dur = 0.65
	var sr = 44100
	var n_samples = int(dur * sr)
	var samples: Array[float] = []
	for i in range(n_samples):
		var t = float(i) / sr
		var env = exp(-t * 4.5) * sin(min(1.0, t * 15.0) * (PI * 0.5))
		var f1 = sin(2.0 * PI * 293.66 * t) * 0.35 # D4
		var f2 = sin(2.0 * PI * 440.0 * t) * 0.30  # A4
		var f3 = sin(2.0 * PI * 587.33 * t) * 0.25 # D5
		var f4 = sin(2.0 * PI * 880.0 * t) * 0.15  # A5
		samples.append((f1 + f2 + f3 + f4) * env * 0.6)
	return _samples_to_bytes(samples)

func _synth_victory() -> PackedByteArray:
	var dur = 1.3
	var sr = 44100
	var n_samples = int(dur * sr)
	var samples: Array[float] = []
	var notes = [349.23, 440.0, 523.25, 698.46] # F4, A4, C5, F5
	for i in range(n_samples):
		var t = float(i) / sr
		var s = 0.0
		for n_idx in range(notes.size()):
			var note_start = float(n_idx) * 0.14
			if t >= note_start:
				var note_t = t - note_start
				var note_env = exp(-note_t * 5.0)
				s += sin(2.0 * PI * notes[n_idx] * note_t) * note_env * 0.3
		samples.append(s)
	return _samples_to_bytes(samples)

func _synth_defeat() -> PackedByteArray:
	var dur = 1.5
	var sr = 44100
	var n_samples = int(dur * sr)
	var samples: Array[float] = []
	for i in range(n_samples):
		var t = float(i) / sr
		var env = exp(-t * 3.2)
		var f1 = sin(2.0 * PI * 65.41 * t) * 0.45 # C2
		var f2 = sin(2.0 * PI * 98.00 * t) * 0.35 # G2
		var f3 = sin(2.0 * PI * 130.81 * t) * 0.25 # C3
		var f4 = sin(2.0 * PI * 155.56 * t) * 0.20 # Eb3 (Minor gloom)
		samples.append((f1 + f2 + f3 + f4) * env * 0.5)
	return _samples_to_bytes(samples)

func _synth_ambient_explore() -> PackedByteArray:
	var dur = 8.0 # Seamless 8 second loop
	var sr = 44100
	var n_samples = int(dur * sr)
	var samples: Array[float] = []
	# E minor ethereal pad frequencies: E2 (82.4), B2 (123.47), E3 (164.81), G3 (196.0), B3 (246.94)
	var freqs = [82.4069, 123.4708, 164.8138, 196.0, 246.9417]
	for i in range(n_samples):
		var t = float(i) / sr
		var s = 0.0
		var chorus = sin(2.0 * PI * 0.25 * t) * 0.15 # Slow 0.25Hz modulation
		for f_idx in range(freqs.size()):
			var base_f = freqs[f_idx]
			var f = base_f + (chorus * (f_idx + 1))
			var phase = 2.0 * PI * f * t
			s += sin(phase) * (0.28 / float(f_idx + 1))
		# Loop windowing: seamless wrap around boundaries
		var loop_window = 1.0
		var edge_samples = 4410 # 0.1s crossfade
		if i < edge_samples:
			loop_window = float(i) / float(edge_samples)
		elif i > (n_samples - edge_samples):
			loop_window = float(n_samples - i) / float(edge_samples)
		samples.append(s * loop_window * 0.45)
	return _samples_to_bytes(samples)

func _synth_ambient_boss() -> PackedByteArray:
	var dur = 4.0 # Seamless 4 second loop
	var sr = 44100
	var n_samples = int(dur * sr)
	var samples: Array[float] = []
	for i in range(n_samples):
		var t = float(i) / sr
		# Low D drone + rhythmic heartbeat pulse every 0.5s (120 BPM)
		var drone = sin(2.0 * PI * 73.42 * t) * 0.35 # D2
		var beat_t = fmod(t, 0.5)
		var beat_env = exp(-beat_t * 18.0)
		var kick = sin(2.0 * PI * (60.0 + (120.0 * exp(-beat_t * 35.0))) * beat_t) * beat_env * 0.55
		# Tense dissonant overtone
		var tension = sin(2.0 * PI * 220.0 * t) * 0.12 * (0.5 + (0.5 * sin(2.0 * PI * 2.0 * t)))
		var val = (drone + kick + tension) * 0.5
		samples.append(val)
	return _samples_to_bytes(samples)

func _samples_to_bytes(samples: Array[float]) -> PackedByteArray:
	var bytes = PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		var clamped = clamp(samples[i], -1.0, 1.0)
		var val16 = int(clamped * 32767.0)
		if val16 < -32768:
			val16 = -32768
		elif val16 > 32767:
			val16 = 32767
		var u16 = val16 if val16 >= 0 else (65536 + val16)
		bytes[i * 2] = u16 & 0xFF
		bytes[i * 2 + 1] = (u16 >> 8) & 0xFF
	return bytes

func _generate_wav(path: String, data: PackedByteArray, sample_rate: int) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Could not write: " + path)
		return
	
	var subchunk2_size = data.size()
	var chunk_size = 36 + subchunk2_size
	var num_channels = 1
	var bits_per_sample = 16
	var byte_rate = sample_rate * num_channels * (bits_per_sample / 8)
	var block_align = num_channels * (bits_per_sample / 8)
	
	# RIFF Header
	file.store_string("RIFF")
	file.store_32(chunk_size)
	file.store_string("WAVE")
	
	# "fmt " subchunk
	file.store_string("fmt ")
	file.store_32(16) # Subchunk1Size for PCM
	file.store_16(1)  # AudioFormat 1 = PCM
	file.store_16(num_channels)
	file.store_32(sample_rate)
	file.store_32(byte_rate)
	file.store_16(block_align)
	file.store_16(bits_per_sample)
	
	# "data" subchunk
	file.store_string("data")
	file.store_32(subchunk2_size)
	file.store_buffer(data)
	file.close()
	print("  Generated: ", path, " (", subchunk2_size, " bytes)")
