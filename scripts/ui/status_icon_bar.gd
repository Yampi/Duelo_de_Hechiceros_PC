class_name StatusIconBar
extends HBoxContainer

const IconRegistry = preload("res://scripts/ui/icon_registry.gd")

## Barra horizontal de efectos de estado y buffs/debuffs activos.
## Muestra iconos de 24px con barrido de duracion y tooltips accesibles.

class StatusEntry:
	var id: String
	var total_duration: float
	var remaining_time: float
	var container: Control
	var icon_rect: TextureRect
	var progress_bar: ProgressBar
	var tooltip: String

var _active_statuses: Dictionary = {}

func _ready() -> void:
	custom_minimum_size = Vector2(0, 24)
	add_theme_constant_override("separation", 4)

func _process(delta: float) -> void:
	var to_remove: Array[String] = []
	for id in _active_statuses:
		var entry: StatusEntry = _active_statuses[id]
		entry.remaining_time -= delta
		if entry.progress_bar:
			if entry.total_duration > 0.0:
				entry.progress_bar.value = clamp(entry.remaining_time / entry.total_duration, 0.0, 1.0)
			else:
				entry.progress_bar.value = 1.0
		
		if entry.remaining_time <= 0.0 and entry.total_duration > 0.0:
			to_remove.append(id)
	
	for id in to_remove:
		remove_status(id)

## Agrega o actualiza un efecto de estado activo.
func add_status(id: String, duration: float, custom_title: String = "", custom_desc: String = "") -> void:
	var id_lower = id.to_lower()
	if _active_statuses.has(id_lower):
		var existing: StatusEntry = _active_statuses[id_lower]
		existing.remaining_time = duration
		return
	
	var entry = StatusEntry.new()
	entry.id = id_lower
	entry.total_duration = duration
	entry.remaining_time = duration
	
	# Contenedor del icono de 24x24 px
	var item_box = Control.new()
	item_box.custom_minimum_size = Vector2(24, 24)
	item_box.size = Vector2(24, 24)
	item_box.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Fondo oscuro sutil
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.1, 0.14, 0.9)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_box.add_child(bg)
	
	# Icono de 24x24 px desde IconRegistry
	var icon = TextureRect.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 2.0
	icon.offset_top = 2.0
	icon.offset_right = -2.0
	icon.offset_bottom = -4.0
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = Control.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon.texture = IconRegistry.get_icon("status", id_lower)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_box.add_child(icon)
	entry.icon_rect = icon
	
	# Barra inferior de duracion (3px)
	var pbar = ProgressBar.new()
	pbar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	pbar.offset_top = -3.0
	pbar.offset_bottom = 0.0
	pbar.show_percentage = false
	pbar.max_value = 1.0
	pbar.value = 1.0
	pbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = _get_status_bar_color(id_lower)
	pbar.add_theme_stylebox_override("fill", fill_style)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.5)
	pbar.add_theme_stylebox_override("background", bg_style)
	
	item_box.add_child(pbar)
	entry.progress_bar = pbar
	
	# Tooltip accesible descriptivo
	var tip = _generate_tooltip(id_lower, custom_title, custom_desc)
	item_box.tooltip_text = tip
	entry.tooltip = tip
	entry.container = item_box
	
	_active_statuses[id_lower] = entry
	add_child(item_box)
	
	# Transicion de aparicion suave
	item_box.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(item_box, "modulate:a", 1.0, 0.15)

## Elimina un estado activo con desvanecimiento.
func remove_status(id: String) -> void:
	var id_lower = id.to_lower()
	if not _active_statuses.has(id_lower):
		return
	
	var entry: StatusEntry = _active_statuses[id_lower]
	_active_statuses.erase(id_lower)
	
	if is_instance_valid(entry.container):
		var tween = create_tween()
		tween.tween_property(entry.container, "modulate:a", 0.0, 0.15)
		tween.tween_callback(entry.container.queue_free)

func has_status(id: String) -> bool:
	return _active_statuses.has(id.to_lower())

func _get_status_bar_color(id: String) -> Color:
	match id:
		"haste":
			return Color(0.3, 0.9, 1.0) # Cian celeridad
		"arcane_shield":
			return Color(0.85, 0.45, 1.0) # Violeta arcano
		"burn":
			return Color(1.0, 0.45, 0.2) # Fuego anaranjado
		"freeze":
			return Color(0.4, 0.8, 1.0) # Azul escarcha
		"poison":
			return Color(0.4, 0.9, 0.3) # Verde veneno
		"buff_health":
			return Color(0.95, 0.3, 0.3) # Rojo vida
		"debuff_vulnerable":
			return Color(1.0, 0.25, 0.25)
		_:
			return Color(1.0, 0.85, 0.4) # Oro arcano

func _generate_tooltip(id: String, custom_title: String, custom_desc: String) -> String:
	if not custom_title.is_empty():
		return "%s\n%s" % [custom_title, custom_desc]
	
	match id:
		"haste":
			return "Celeridad Arcana\n+30% velocidad de movimiento y lanzamiento acelerado"
		"arcane_shield":
			return "Escudo Arcano\nAbsorbe el 65% del daño recibido durante su duracion"
		"burn":
			return "Quemadura Ígnea\nDaño continuo de fuego"
		"freeze":
			return "Congelación\nRalentizacion de movimiento"
		"poison":
			return "Veneno\nDaño por toxina arcana"
		"buff_health":
			return "Vitalidad Aumentada\nRegeneracion temporal de salud"
		"debuff_vulnerable":
			return "Vulnerabilidad\nDaño recibido incrementado"
		_:
			return "Efecto Activo: %s" % id.capitalize()
