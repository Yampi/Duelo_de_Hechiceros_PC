extends Node

const UI_SOUNDS: Dictionary = {
	"hover": "res://assets/audio/ui/ui_hover.wav",
	"click": "res://assets/audio/ui/ui_click.wav",
	"open": "res://assets/audio/ui/ui_open.wav",
	"close": "res://assets/audio/ui/ui_close.wav",
	"error": "res://assets/audio/ui/ui_error.wav",
	"error_mana": "res://assets/audio/ui/ui_error.wav",
	"loot": "res://assets/audio/ui/ui_loot.wav",
	"shrine": "res://assets/audio/ui/ui_shrine.wav",
	"victory": "res://assets/audio/ui/ui_victory.wav",
	"defeat": "res://assets/audio/ui/ui_defeat.wav"
}

const MUSIC_TRACKS: Dictionary = {
	"exploration": "res://assets/audio/music/ambient_exploration.wav",
	"boss": "res://assets/audio/music/ambient_boss.wav"
}

var _streams: Dictionary = {}
var _ui_players: Array[AudioStreamPlayer] = []
var _sfx_players: Array[AudioStreamPlayer] = []

var _music_player_a: AudioStreamPlayer = null
var _music_player_b: AudioStreamPlayer = null
var _active_music_player: AudioStreamPlayer = null
var _current_track_id: String = ""

var _volume_levels: Dictionary = {
	"Master": 0.85,
	"Music": 0.70,
	"SFX": 0.85,
	"UI": 0.90
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_bus_layout()
	_create_player_pools()
	_load_all_audio_streams()
	load_settings()

func _setup_bus_layout() -> void:
	var buses = ["Music", "SFX", "UI"]
	for bus_name in buses:
		var idx = AudioServer.get_bus_index(bus_name)
		if idx == -1:
			AudioServer.add_bus()
			var new_idx = AudioServer.bus_count - 1
			AudioServer.set_bus_name(new_idx, bus_name)
			AudioServer.set_bus_send(new_idx, "Master")

func _create_player_pools() -> void:
	# UI Audio Player Pool (polyphonic, max 6 simultaneous UI sounds)
	for i in range(6):
		var p = AudioStreamPlayer.new()
		p.name = "UIPlayer_%d" % i
		p.bus = "UI"
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_ui_players.append(p)
	
	# SFX Audio Player Pool (polyphonic, max 6 simultaneous SFX sounds)
	for i in range(6):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = "SFX"
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_sfx_players.append(p)
	
	# Dual Music Players for crossfading
	_music_player_a = AudioStreamPlayer.new()
	_music_player_a.name = "MusicPlayer_A"
	_music_player_a.bus = "Music"
	_music_player_a.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player_a)
	
	_music_player_b = AudioStreamPlayer.new()
	_music_player_b.name = "MusicPlayer_B"
	_music_player_b.bus = "Music"
	_music_player_b.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player_b)

func _load_wav_file(path: String, is_loop: bool = false) -> AudioStream:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStream:
			return res
	
	var global_path = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(global_path):
		return null
	
	var file = FileAccess.open(global_path, FileAccess.READ)
	if not file:
		return null
	
	if file.get_length() <= 44:
		return null
	
	file.seek(44)
	var raw_data = file.get_buffer(file.get_length() - 44)
	
	var stream = AudioStreamWAV.new()
	stream.data = raw_data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = false
	if is_loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = int(raw_data.size() / 2)
	return stream

func _load_all_audio_streams() -> void:
	for id in UI_SOUNDS:
		var stream = _load_wav_file(UI_SOUNDS[id], false)
		if stream:
			_streams["ui_" + id] = stream
	
	for id in MUSIC_TRACKS:
		var stream = _load_wav_file(MUSIC_TRACKS[id], true)
		if stream:
			_streams["music_" + id] = stream

func play_ui(id: String, pitch_scale: float = 1.0) -> void:
	var key = "ui_" + id
	if not _streams.has(key):
		# Fallback if alias
		if id == "error_mana":
			key = "ui_error"
		elif id == "level_up":
			key = "ui_shrine"
	
	if not _streams.has(key):
		return
	
	var stream = _streams[key] as AudioStream
	if not stream:
		return
	
	# Find available player in pool
	var player: AudioStreamPlayer = null
	for p in _ui_players:
		if not p.is_playing():
			player = p
			break
	if not player:
		player = _ui_players[0] # Steal oldest
	
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = 0.0
	player.play()

func play_sfx(id: String, pitch_scale: float = 1.0) -> void:
	var key = "ui_" + id
	if not _streams.has(key):
		return
	var stream = _streams[key] as AudioStream
	if not stream:
		return
	
	var player: AudioStreamPlayer = null
	for p in _sfx_players:
		if not p.is_playing():
			player = p
			break
	if not player:
		player = _sfx_players[0]
	
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = 0.0
	player.play()

func play_music(track_id: String, fade_duration: float = 1.0) -> void:
	if _current_track_id == track_id and _active_music_player and _active_music_player.is_playing():
		return
	
	var key = "music_" + track_id
	if not _streams.has(key):
		return
	
	var stream = _streams[key] as AudioStream
	if not stream:
		return
	
	_current_track_id = track_id
	
	var next_player = _music_player_b if _active_music_player == _music_player_a else _music_player_a
	var prev_player = _active_music_player
	
	next_player.stream = stream
	next_player.volume_db = -40.0
	next_player.play()
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(next_player, "volume_db", 0.0, fade_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if prev_player and prev_player.is_playing():
		tween.tween_property(prev_player, "volume_db", -40.0, fade_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(prev_player.stop)
	
	_active_music_player = next_player

func stop_music(fade_duration: float = 1.0) -> void:
	_current_track_id = ""
	if _active_music_player and _active_music_player.is_playing():
		var tween = create_tween()
		tween.tween_property(_active_music_player, "volume_db", -40.0, fade_duration)
		tween.tween_callback(_active_music_player.stop)

func set_volume(bus_name: String, linear_val: float) -> void:
	linear_val = clamp(linear_val, 0.0, 1.0)
	_volume_levels[bus_name] = linear_val
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		if linear_val <= 0.001:
			AudioServer.set_bus_mute(bus_idx, true)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			var db = linear_to_db(linear_val)
			AudioServer.set_bus_volume_db(bus_idx, db)

func get_volume(bus_name: String) -> float:
	return _volume_levels.get(bus_name, 0.8)

func save_settings() -> void:
	var cfg = ConfigFile.new()
	for bus_name in _volume_levels:
		cfg.set_value("audio", bus_name.to_lower() + "_volume", _volume_levels[bus_name])
	cfg.save("user://audio_settings.cfg")

func load_settings() -> void:
	var cfg = ConfigFile.new()
	var err = cfg.load("user://audio_settings.cfg")
	if err == OK:
		for bus_name in _volume_levels:
			var key = bus_name.to_lower() + "_volume"
			if cfg.has_section_key("audio", key):
				var val = cfg.get_value("audio", key, _volume_levels[bus_name])
				set_volume(bus_name, val)
	else:
		# Apply default volumes
		for bus_name in _volume_levels:
			set_volume(bus_name, _volume_levels[bus_name])
