class_name SettingsManager
extends RefCounted

const SAVE_PATH = "user://settings.cfg"

static var master_volume: float = 0.85
static var music_volume: float = 0.70
static var sfx_volume: float = 0.85
static var ui_volume: float = 0.90

static var reduce_shake: bool = false
static var reduce_flashes: bool = false
static var show_control_hints: bool = true
static var camera_mode: int = 0 # 0: 3D Libre (Tercera persona), 1: 2.5D Isométrica
static var fullscreen: bool = false
static var ui_scale: float = 1.0
static var effects_quality: int = 2 # 0: Low, 1: Med, 2: High

static var _loaded: bool = false

static func init_settings() -> void:
	if _loaded:
		return
	_loaded = true
	load_from_disk()
	apply_all()

static func apply_all() -> void:
	# 1. Apply audio
	var am = Engine.get_main_loop().root.get_node_or_null("AudioManager") if Engine.get_main_loop() else null
	if am and am.has_method("set_volume"):
		am.set_volume("Master", master_volume)
		am.set_volume("Music", music_volume)
		am.set_volume("SFX", sfx_volume)
		am.set_volume("UI", ui_volume)
	
	# 2. Apply window mode
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	# 3. Apply camera settings to active camera rigs
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree:
		var scene_tree = main_loop as SceneTree
		for cam in scene_tree.get_nodes_in_group("camera"):
			if cam.has_method("apply_settings"):
				cam.apply_settings()

static func save_to_disk() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("audio", "ui", ui_volume)
	
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "ui_scale", ui_scale)
	cfg.set_value("video", "effects_quality", effects_quality)
	
	cfg.set_value("gameplay", "reduce_shake", reduce_shake)
	cfg.set_value("gameplay", "reduce_flashes", reduce_flashes)
	cfg.set_value("gameplay", "show_control_hints", show_control_hints)
	cfg.set_value("gameplay", "camera_mode", camera_mode)
	
	cfg.save(SAVE_PATH)
	apply_all()

static func load_from_disk() -> void:
	var cfg = ConfigFile.new()
	var err = cfg.load(SAVE_PATH)
	if err != OK:
		return
	
	master_volume = cfg.get_value("audio", "master", master_volume)
	music_volume = cfg.get_value("audio", "music", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
	ui_volume = cfg.get_value("audio", "ui", ui_volume)
	
	fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
	ui_scale = cfg.get_value("video", "ui_scale", ui_scale)
	effects_quality = cfg.get_value("video", "effects_quality", effects_quality)
	
	reduce_shake = cfg.get_value("gameplay", "reduce_shake", reduce_shake)
	reduce_flashes = cfg.get_value("gameplay", "reduce_flashes", reduce_flashes)
	show_control_hints = cfg.get_value("gameplay", "show_control_hints", show_control_hints)
	camera_mode = cfg.get_value("gameplay", "camera_mode", camera_mode)
