class_name OracleMonolith
extends Area3D

## Monolito del Oráculo / Inscripciones de Lucian
## Permite descubrir la trama narrativa del juego interactuando con la tecla [E]

@export var lore_id: String = "lucian_journal_1"
@export var prompt_text: String = "[E] Consultar Inscripción Antigua"

var is_player_nearby: bool = false
var is_read: bool = false

@onready var light: OmniLight3D = $OmniLight3D
@onready var prompt_label: Label3D = $PromptLabel
@onready var runes: MeshInstance3D = $RunesMesh

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt_label.visible = false
	prompt_label.text = prompt_text
	_update_visuals()

func _process(delta: float) -> void:
	if runes:
		runes.rotate_y(delta * 0.25)
	
	if is_player_nearby and Input.is_action_just_pressed("interact"):
		interact()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = true
		prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = false
		prompt_label.visible = false

func interact() -> void:
	if not GameManager or not GameManager.lore:
		return
	
	var data = GameManager.lore.unlock_lore(lore_id)
	is_read = true
	_update_visuals()
	
	# Audio feedback
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("shrine")
	
	# Camera and screen feedback
	GameManager.shake_camera(0.2)
	prompt_label.text = "📜 LEÍDO"
	prompt_label.modulate = Color(0.4, 0.9, 0.4)
	
	# Show notification banner in HUD if available
	var tree = get_tree()
	if tree:
		var hud = tree.get_first_node_in_group("hud")
		if hud and hud.has_method("show_zone_banner") and data.has("title"):
			hud.show_zone_banner("📜 " + data["title"], data.get("text", "").substr(0, 75) + "...", Color(0.9, 0.8, 0.2))

func _update_visuals() -> void:
	if is_read:
		if light:
			light.light_color = Color(0.3, 0.9, 0.5)
			light.light_energy = 0.65
			light.omni_range = 3.2
		if runes and runes.material_override:
			runes.material_override.set("emission", Color(0.3, 0.9, 0.5))
	else:
		if light:
			light.light_color = Color(0.85, 0.7, 0.2)
			light.light_energy = 0.85
			light.omni_range = 3.6
		if runes and runes.material_override:
			runes.material_override.set("emission", Color(0.85, 0.7, 0.2))
