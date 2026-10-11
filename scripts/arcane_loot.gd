extends Area3D

enum LootType { BRIMSTONE, CLOVER, SCROLL, BEAST_CORE }

@export var loot_type: LootType = LootType.BRIMSTONE

var base_y: float = 0.5
var time: float = 0.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var light: OmniLight3D = $OmniLight3D
@onready var label: Label3D = $Label3D

func _ready() -> void:
	base_y = position.y
	_setup_visuals()
	body_entered.connect(_on_body_entered)

func set_random_type() -> void:
	var r = randi() % 4
	loot_type = r as LootType
	_setup_visuals()

func _setup_visuals() -> void:
	if not is_inside_tree():
		return
	
	var col = Color.ORANGE
	var txt = "🔥 Azufre Ígneo"
	
	match loot_type:
		LootType.BRIMSTONE:
			col = Color(1.0, 0.45, 0.1)
			txt = "🔥 Azufre Ígneo\n[Bola de Fuego Gratis]"
		LootType.CLOVER:
			col = Color(0.2, 1.0, 0.4)
			txt = "🍀 Trébol Mágico\n[Regeneración Rápida]"
		LootType.SCROLL:
			col = Color(0.3, 0.7, 1.0)
			txt = "📜 Pergamino Arcano\n[Maná Máximo Inmediato]"
		LootType.BEAST_CORE:
			col = Color(0.9, 0.2, 1.0)
			txt = "💎 Núcleo de Bestia\n[Furia y Rapidez Mágica]"
	
	if mesh and mesh.material_override:
		mesh.material_override.set("albedo_color", col)
		mesh.material_override.set("emission", col)
	if light:
		light.light_color = col
	if label:
		label.text = txt
		label.modulate = col

func _process(delta: float) -> void:
	time += delta
	rotate_y(delta * 2.8)
	position.y = base_y + sin(time * 3.5) * 0.12

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		apply_loot_effect(body)
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "scale", Vector3(1.8, 1.8, 1.8), 0.15)
		if light:
			tween.tween_property(light, "light_energy", 6.0, 0.15)
		await tween.finished
		queue_free()

func apply_loot_effect(player: Node3D) -> void:
	match loot_type:
		LootType.BRIMSTONE:
			GameManager.add_reagent("sulfur", 1)
			GameManager.player_mana = min(GameManager.player_max_mana, GameManager.player_mana + 25.0)
		LootType.CLOVER:
			GameManager.add_reagent("clover", 1)
			GameManager.player_health = min(GameManager.player_max_health, GameManager.player_health + 45.0)
		LootType.SCROLL:
			GameManager.add_reagent("scroll", 1)
			GameManager.player_mana = GameManager.player_max_mana
		LootType.BEAST_CORE:
			GameManager.add_reagent("core", 1)
			if player.has_method("apply_haste_buff"):
				player.apply_haste_buff(8.0)
			else:
				GameManager.player_health = min(GameManager.player_max_health, GameManager.player_health + 30.0)
				GameManager.player_mana = min(GameManager.player_max_mana, GameManager.player_mana + 40.0)
