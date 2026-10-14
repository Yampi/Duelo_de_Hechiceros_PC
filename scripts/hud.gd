extends CanvasLayer

const IconRegistry = preload("res://scripts/ui/icon_registry.gd")
const StatusIconBar = preload("res://scripts/ui/status_icon_bar.gd")
const UIConstants = preload("res://scripts/ui/ui_constants.gd")
const QuickSlot = preload("res://scripts/ui/quick_slot.gd")
const StatBar = preload("res://scripts/ui/stat_bar.gd")
const TargetIndicator = preload("res://scripts/ui/target_indicator.gd")
const CursorManager = preload("res://scripts/ui/cursor_manager.gd")
const LootToastScene = preload("res://scenes/ui/LootToast.tscn")
const InteractionPrompt = preload("res://scripts/ui/interaction_prompt.gd")
const InteractionPromptScene = preload("res://scenes/ui/InteractionPrompt.tscn")
const SettingsManager = preload("res://scripts/settings_manager.gd")

signal spell_button_pressed(slot: int)

@onready var hp_bar: StatBar = $BottomHUD/LeftCluster/HealthBar
@onready var stamina_bar: StatBar = $BottomHUD/LeftCluster/StaminaBar if has_node("BottomHUD/LeftCluster/StaminaBar") else null
@onready var mana_bar: StatBar = $BottomHUD/RightCluster/ManaBar
@onready var target_indicator: TargetIndicator = $TargetIndicator
@onready var status_bar: StatusIconBar = $BottomHUD/LeftCluster/StatusBar

@onready var quick_slot_hp: QuickSlot = $BottomHUD/CenterCluster/QuickSlotsRow/QuickSlotHealth
@onready var quick_slot_mp: QuickSlot = $BottomHUD/CenterCluster/QuickSlotsRow/QuickSlotMana
@onready var lbl_shrines_count: Label = $BottomHUD/CenterCluster/QuickSlotsRow/ShrinesCompact/LblShrinesCount

@onready var spell_slots: Array[Control] = [
	$BottomHUD/CenterCluster/SpellBar/Slot1,
	$BottomHUD/CenterCluster/SpellBar/Slot2,
	$BottomHUD/CenterCluster/SpellBar/Slot3,
	$BottomHUD/CenterCluster/SpellBar/Slot4,
	$BottomHUD/CenterCluster/SpellBar/Slot5,
	$BottomHUD/CenterCluster/SpellBar/Slot6,
	$BottomHUD/CenterCluster/SpellBar/Slot7,
	$BottomHUD/CenterCluster/SpellBar/Slot8,
	$BottomHUD/CenterCluster/SpellBar/Slot9
]

@onready var control_hints: PanelContainer = $ControlHints
@onready var hint_badge: Button = $HintBadge
@onready var btn_close_hint: Button = $ControlHints/VBox/HeaderRow/BtnCloseHint

@onready var objective_tracker: PanelContainer = $ObjectiveTracker
@onready var mode_title: Label = $ObjectiveTracker/VBox/ModeTitle
@onready var mode_detail: Label = $ObjectiveTracker/VBox/ModeDetail
@onready var mode_sub: Label = $ObjectiveTracker/VBox/ModeSub

@onready var minimap: Control = $Minimap
@onready var inventory_ui: Control = $InventoryUI
@onready var world_map_modal: Control = $WorldMapModal
@onready var grimoire_modal: Control = $GrimoireModal if has_node("GrimoireModal") else null
@onready var crafting_modal: Control = $CraftingModal if has_node("CraftingModal") else null

@onready var btn_inv_toggle: Button = $BottomHUD/RightCluster/NavRow/BtnInvToggle
@onready var btn_map_toggle: Button = $BottomHUD/RightCluster/NavRow/BtnMapToggle
@onready var btn_grimoire_toggle: Button = find_child("BtnGrimoireToggle", true, false)
@onready var btn_craft_toggle: Button = find_child("BtnCraftToggle", true, false)

@onready var game_over_panel: Control = $GameOverPanel
@onready var victory_panel: Control = $VictoryPanel

@onready var screen_vignette: ColorRect = $ScreenVignette
@onready var damage_flash: ColorRect = $DamageFlash
@onready var screen_effects: ColorRect = $ScreenEffects if has_node("ScreenEffects") else null
@onready var loot_toast_container: VBoxContainer = $LootToastContainer if has_node("LootToastContainer") else null
@onready var interaction_prompts_layer: Control = $InteractionPrompts if has_node("InteractionPrompts") else null
@onready var pause_menu: Control = $PauseMenu if has_node("PauseMenu") else null
@onready var screen_fade: ColorRect = $ScreenFade if has_node("ScreenFade") else null

var active_slot: int = 1
var player_ref: Node3D = null
var current_banner: Control = null
var _last_hp: float = 100.0

func _ready() -> void:
	# Configure spell buttons
	for i in range(spell_slots.size()):
		var slot_idx = i + 1
		if spell_slots[i] and spell_slots[i].has_signal("slot_pressed"):
			spell_slots[i].slot_pressed.connect(func(idx): spell_button_pressed.emit(idx))
	
	GameManager.reagents_updated.connect(update_reagents_display)
	GameManager.shrines_updated.connect(update_shrines_display)
	GameManager.grimorio_updated.connect(refresh_spell_bar)
	
	# Quick slots
	if quick_slot_hp:
		quick_slot_hp.quick_slot_used.connect(_on_quick_slot_used)
	if quick_slot_mp:
		quick_slot_mp.quick_slot_used.connect(_on_quick_slot_used)
	
	# Navigation buttons
	if btn_inv_toggle:
		btn_inv_toggle.pressed.connect(toggle_inventory)
		btn_inv_toggle.icon = IconRegistry.get_icon("ui", "inventory")
	if btn_map_toggle:
		btn_map_toggle.pressed.connect(toggle_world_map)
		btn_map_toggle.icon = IconRegistry.get_icon("ui", "map")
	if btn_grimoire_toggle:
		btn_grimoire_toggle.pressed.connect(toggle_grimoire)
		btn_grimoire_toggle.icon = IconRegistry.get_icon("spells", "spell_book")
	if btn_craft_toggle:
		btn_craft_toggle.pressed.connect(toggle_crafting)
		btn_craft_toggle.icon = IconRegistry.get_icon("ui", "crafting")
	if minimap and minimap.has_signal("open_world_map_requested"):
		minimap.open_world_map_requested.connect(toggle_world_map)
	
	# Control hints dismiss and toggle
	if btn_close_hint:
		btn_close_hint.pressed.connect(func(): _set_control_hints_visible(false))
	if hint_badge:
		hint_badge.pressed.connect(func(): _set_control_hints_visible(true))
	
	SettingsManager.init_settings()
	if not SettingsManager.show_control_hints:
		control_hints.visible = false
		hint_badge.visible = true
	else:
		_schedule_hint_fade(6.5)
	
	update_active_spell(1)
	update_reagents_display()
	update_shrines_display()
	
	game_over_panel.visible = false
	victory_panel.visible = false
	
	$GameOverPanel/Panel/VBox/BtnRetry.pressed.connect(_on_retry_pressed)
	$GameOverPanel/Panel/VBox/BtnMenu.pressed.connect(_on_menu_pressed)
	$VictoryPanel/Panel/VBox/BtnNext.pressed.connect(_on_retry_pressed)
	$VictoryPanel/Panel/VBox/BtnMenu.pressed.connect(_on_menu_pressed)
	
	CursorManager.init_cursors()
	if GameManager.has_signal("loot_collected"):
		GameManager.loot_collected.connect(_on_loot_collected)
	fade_in_screen(0.35)

func _process(delta: float) -> void:
	_sync_player_statuses()
	_update_vignette_feedback(delta)

func _update_vignette_feedback(_delta: float) -> void:
	if not screen_vignette or not screen_vignette.material:
		return
	
	var mat = screen_vignette.material as ShaderMaterial
	if not mat:
		return
	
	# Pulsación de vida baja (<25%)
	var max_hp = GameManager.player_max_health
	var cur_hp = GameManager.player_health
	if max_hp > 0.0 and (cur_hp / max_hp) <= 0.25:
		var pulse = (sin(Time.get_ticks_msec() * 0.006) + 1.0) * 0.5
		var target_intensity = lerp(0.15, 0.45, pulse)
		mat.set_shader_parameter("vignette_intensity", target_intensity)
	else:
		var cur_intensity = mat.get_shader_parameter("vignette_intensity")
		if cur_intensity is float and cur_intensity > 0.001:
			mat.set_shader_parameter("vignette_intensity", max(0.0, cur_intensity - (_delta * 2.0)))

func trigger_damage_feedback() -> void:
	if damage_flash:
		var target_alpha = 0.25 if SettingsManager.reduce_flashes else 0.75
		damage_flash.modulate.a = target_alpha
		var tween = create_tween()
		tween.tween_property(damage_flash, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if screen_vignette and screen_vignette.material:
		var mat = screen_vignette.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("vignette_intensity", 0.6)
	
	var cam = get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.4)

func _on_quick_slot_used(action: String) -> void:
	if action == "Q":
		if player_ref and player_ref.has_method("use_consumable_apple"):
			player_ref.use_consumable_apple()
	elif action == "E":
		if player_ref and player_ref.has_method("use_consumable_scroll"):
			player_ref.use_consumable_scroll()

func _schedule_hint_fade(delay: float) -> void:
	var timer = get_tree().create_timer(delay)
	timer.timeout.connect(func():
		if control_hints and control_hints.visible:
			_set_control_hints_visible(false)
	)

func _set_control_hints_visible(show_it: bool) -> void:
	if show_it:
		hint_badge.visible = false
		control_hints.visible = true
		control_hints.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(control_hints, "modulate:a", 1.0, 0.2)
	else:
		var tween = create_tween()
		tween.tween_property(control_hints, "modulate:a", 0.0, 0.25)
		tween.tween_callback(func():
			control_hints.visible = false
			hint_badge.visible = true
		)

func toggle_control_hints() -> void:
	_set_control_hints_visible(not control_hints.visible)

func _sync_player_statuses() -> void:
	if not status_bar or not player_ref or not is_instance_valid(player_ref):
		return
	
	if "haste_timer" in player_ref and player_ref.haste_timer > 0.0:
		status_bar.add_status("haste", player_ref.haste_timer)
	elif status_bar.has_status("haste"):
		status_bar.remove_status("haste")
	
	if "active_shield" in player_ref and is_instance_valid(player_ref.active_shield):
		var shield_time: float = 7.5
		if "life_timer" in player_ref.active_shield:
			shield_time = player_ref.active_shield.life_timer
		status_bar.add_status("arcane_shield", shield_time)
	elif status_bar.has_status("arcane_shield"):
		status_bar.remove_status("arcane_shield")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_I:
			toggle_inventory()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_M:
			toggle_world_map()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_G:
			toggle_grimoire()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_C:
			toggle_crafting()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_H:
			toggle_control_hints()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_V:
			toggle_camera_perspective()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			if crafting_modal and crafting_modal.visible:
				toggle_crafting()
				get_viewport().set_input_as_handled()
			elif grimoire_modal and grimoire_modal.visible:
				toggle_grimoire()
				get_viewport().set_input_as_handled()
			elif inventory_ui and inventory_ui.visible:
				toggle_inventory()
				get_viewport().set_input_as_handled()
			elif world_map_modal and world_map_modal.visible:
				toggle_world_map()
				get_viewport().set_input_as_handled()
			elif pause_menu and pause_menu.has_method("toggle_pause"):
				pause_menu.toggle_pause()
				get_viewport().set_input_as_handled()

func set_player_reference(player: Node3D) -> void:
	player_ref = player
	if minimap and minimap.has_method("set_player"):
		minimap.set_player(player)
	if world_map_modal and world_map_modal.has_method("set_player"):
		world_map_modal.set_player(player)

func toggle_inventory() -> void:
	if inventory_ui and inventory_ui.has_method("toggle_inventory"):
		var will_open = not inventory_ui.visible
		inventory_ui.toggle_inventory()
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_ui"):
			am.play_ui("open" if will_open else "close")

func toggle_world_map() -> void:
	if world_map_modal and world_map_modal.has_method("toggle_map"):
		var will_open = not world_map_modal.visible
		world_map_modal.toggle_map()
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_ui"):
			am.play_ui("open" if will_open else "close")

func toggle_grimoire() -> void:
	if grimoire_modal and grimoire_modal.has_method("toggle_grimoire"):
		var will_open = not grimoire_modal.visible
		grimoire_modal.toggle_grimoire()
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_ui"):
			am.play_ui("open" if will_open else "close")

func toggle_crafting() -> void:
	if crafting_modal and crafting_modal.has_method("toggle_crafting"):
		var will_open = not crafting_modal.visible
		crafting_modal.toggle_crafting()
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_ui"):
			am.play_ui("open" if will_open else "close")

func refresh_spell_bar() -> void:
	for slot_comp in spell_slots:
		if slot_comp and slot_comp.has_method("_update_ui"):
			slot_comp._update_ui()

func update_active_spell(slot: int) -> void:
	active_slot = slot
	for i in range(spell_slots.size()):
		var slot_comp = spell_slots[i]
		if slot_comp and "is_selected" in slot_comp:
			slot_comp.is_selected = ((i + 1) == slot)

func update_hp(current: float, max_val: float) -> void:
	if current < _last_hp:
		trigger_damage_feedback()
	_last_hp = current
	
	if hp_bar and hp_bar.has_method("set_values"):
		hp_bar.set_values(current, max_val)

func update_stamina(current: float, max_val: float) -> void:
	if stamina_bar and stamina_bar.has_method("set_values"):
		stamina_bar.set_values(current, max_val)

func update_mana(current: float, max_val: float, regen: float) -> void:
	if mana_bar and mana_bar.has_method("set_values"):
		var regen_text = "+%.1f/s" % regen
		mana_bar.set_values(current, max_val, regen_text)
	
	for slot_comp in spell_slots:
		if slot_comp and slot_comp.has_method("update_mana_status"):
			slot_comp.update_mana_status(current)

func update_cast_progress(slot: int, progress: float) -> void:
	var idx = slot - 1
	if idx >= 0 and idx < spell_slots.size():
		var s = spell_slots[idx]
		if s and s.has_method("set_cooldown"):
			s.set_cooldown(progress)
			if progress >= 0.95 and s.has_method("flash_cast"):
				s.flash_cast()

func set_target_enemy(enemy: Node) -> void:
	if target_indicator and target_indicator.has_method("set_target_node"):
		target_indicator.set_target_node(enemy)

func update_reagents_display() -> void:
	var h_pots = GameManager.inventory.get_item_count("potion_health") if GameManager.inventory else 0
	var m_pots = GameManager.inventory.get_item_count("potion_mana") if GameManager.inventory else 0
	
	if quick_slot_hp:
		quick_slot_hp.count = h_pots
	if quick_slot_mp:
		quick_slot_mp.count = m_pots

func update_shrines_display() -> void:
	if lbl_shrines_count:
		lbl_shrines_count.text = "%d/3" % GameManager.active_shrines
	
	if GameManager.arcana_empowered and spell_slots.size() > 0:
		var slot1 = spell_slots[0]
		if "spell_name" in slot1:
			slot1.spell_name = "Centella Sobrecargada"
		if "icon_color" in slot1:
			slot1.icon_color = Color(0.3, 0.95, 1.0)

func update_mode_hud(title_text: String, detail_text: String, sub_text: String) -> void:
	var changed = (mode_title and mode_title.text != title_text)
	if mode_title:
		mode_title.text = title_text
	if mode_detail:
		mode_detail.text = detail_text
	if mode_sub:
		mode_sub.text = sub_text
	
	if changed and objective_tracker:
		_pulse_objective_tracker()

func _pulse_objective_tracker() -> void:
	var tween = create_tween()
	tween.tween_property(objective_tracker, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(objective_tracker, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func show_zone_banner(title_text: String, subtitle_text: String, title_color: Color = Color(1.0, 0.85, 0.4)) -> void:
	if current_banner and is_instance_valid(current_banner):
		current_banner.queue_free()
	
	var banner = Control.new()
	banner.name = "ZoneBanner"
	banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	banner.offset_top = 78.0
	banner.offset_bottom = 154.0
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 72)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.06, 0.09, 0.90)
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.85, 0.72, 0.35, 0.8)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	sb.content_margin_left = 20.0
	sb.content_margin_right = 20.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)
	
	var div_top = TextureRect.new()
	div_top.texture = preload("res://assets/ui/frames/divider-000.png")
	div_top.custom_minimum_size = Vector2(0, 8)
	div_top.modulate = Color(1.0, 0.85, 0.35, 0.75)
	div_top.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	div_top.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(div_top)
	
	var lbl_title = Label.new()
	lbl_title.text = title_text
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_override("font", preload("res://assets/ui/fonts/Cinzel.ttf"))
	lbl_title.add_theme_font_size_override("font_size", 20)
	lbl_title.add_theme_color_override("font_color", title_color)
	lbl_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	lbl_title.add_theme_constant_override("shadow_offset_x", 1)
	lbl_title.add_theme_constant_override("shadow_offset_y", 1)
	vbox.add_child(lbl_title)
	
	var lbl_sub = Label.new()
	lbl_sub.text = subtitle_text
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sub.add_theme_font_size_override("font_size", 12)
	lbl_sub.add_theme_color_override("font_color", Color(0.9, 0.9, 0.8, 0.95))
	lbl_sub.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	lbl_sub.add_theme_constant_override("shadow_offset_x", 1)
	lbl_sub.add_theme_constant_override("shadow_offset_y", 1)
	vbox.add_child(lbl_sub)
	
	var div_bot = TextureRect.new()
	div_bot.texture = preload("res://assets/ui/frames/divider-000.png")
	div_bot.custom_minimum_size = Vector2(0, 8)
	div_bot.modulate = Color(1.0, 0.85, 0.35, 0.75)
	div_bot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	div_bot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(div_bot)
	
	add_child(banner)
	current_banner = banner
	
	banner.modulate = Color(1, 1, 1, 0)
	banner.scale = Vector2(0.94, 0.94)
	banner.pivot_offset = Vector2(banner.size.x * 0.5, 36.0)
	
	var tween = create_tween()
	tween.tween_property(banner, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(2.6)
	tween.tween_property(banner, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(banner, "position:y", banner.position.y - 12.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(banner.queue_free)

func trigger_element_flash(color: Color, duration: float = 0.22) -> void:
	if not screen_effects or not screen_effects.material:
		return
	var mat = screen_effects.material as ShaderMaterial
	if not mat:
		return
	mat.set_shader_parameter("flash_tint", color)
	mat.set_shader_parameter("flash_power", 0.32)
	var tween = create_tween()
	tween.tween_method(func(val: float):
		if is_instance_valid(screen_effects) and screen_effects.material:
			(screen_effects.material as ShaderMaterial).set_shader_parameter("flash_power", val)
	, 0.32, 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func trigger_player_death_sequence(on_complete: Callable) -> void:
	# Ralentizar tiempo para efecto dramático
	Engine.time_scale = 0.25
	
	# Desaturar pantalla gradualmente
	if screen_effects and screen_effects.material:
		var mat = screen_effects.material as ShaderMaterial
		if mat:
			var tween = create_tween()
			tween.tween_method(func(val: float):
				if is_instance_valid(screen_effects) and screen_effects.material:
					(screen_effects.material as ShaderMaterial).set_shader_parameter("desaturation", val)
			, 0.0, 0.90, 0.6)
	
	# Oscurecer levemente
	if screen_fade:
		var fade_tween = create_tween()
		fade_tween.tween_property(screen_fade, "modulate:a", 0.4, 0.6)
	
	# Esperar 0.6 segundos reales (a escala reducida 0.25 = ~0.15s en juego)
	var timer = get_tree().create_timer(0.6, true, false, true)
	timer.timeout.connect(func():
		Engine.time_scale = 1.0
		if on_complete.is_valid():
			on_complete.call()
	)

func _on_loot_collected(item_id: String, amount: int) -> void:
	show_loot_toast_for_item(item_id, amount)

func show_loot_toast_for_item(item_id: String, count: int = 1) -> void:
	if not loot_toast_container:
		return
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("loot")
	var toast = LootToastScene.instantiate()
	loot_toast_container.add_child(toast)
	toast.setup_from_item(item_id, count)

func show_loot_toast(item_name: String, count: int, icon_tex: Texture2D = null, border_col: Color = UIConstants.GOLD_BASE) -> void:
	if not loot_toast_container:
		return
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("loot")
	var toast = LootToastScene.instantiate()
	loot_toast_container.add_child(toast)
	toast.setup(item_name, count, icon_tex, border_col)

func show_toast_message(msg: String, icon_tex: Texture2D = null, border_col: Color = UIConstants.GOLD_BASE) -> void:
	if not loot_toast_container or not LootToastScene:
		return
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("button_click")
	var toast = LootToastScene.instantiate()
	loot_toast_container.add_child(toast)
	if toast.has_method("setup_message"):
		toast.setup_message(msg, icon_tex, border_col)
	else:
		toast.setup(msg, 1, icon_tex, border_col)

func toggle_camera_perspective() -> void:
	var new_mode = 1 if SettingsManager.camera_mode == 0 else 0
	SettingsManager.camera_mode = new_mode
	SettingsManager.save_to_disk()
	
	var mode_name = "2.5D Isométrica (Fija)" if new_mode == 1 else "3D Libre (Tercera Persona)"
	var accent_col = UIConstants.ARCANE_CYAN if new_mode == 1 else UIConstants.GOLD_BASE
	show_toast_message("📷 " + mode_name, null, accent_col)

func create_interaction_prompt(target_node: Node3D, text: String, key_str: String = "F", height: float = 1.2) -> InteractionPrompt:
	var prompt = InteractionPromptScene.instantiate() as InteractionPrompt
	if interaction_prompts_layer:
		interaction_prompts_layer.add_child(prompt)
	else:
		add_child(prompt)
	prompt.setup_target(target_node, text, key_str, height)
	return prompt

func trigger_no_mana_slot(slot: int) -> void:
	if slot >= 1 and slot <= spell_slots.size():
		var slot_comp = spell_slots[slot - 1]
		if slot_comp and slot_comp.has_method("shake_no_mana"):
			slot_comp.shake_no_mana()

func fade_in_screen(duration: float = 0.35) -> void:
	if not screen_fade:
		return
	screen_fade.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(screen_fade, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func fade_out_screen(duration: float = 0.35, callback: Callable = Callable()) -> void:
	if not screen_fade:
		if callback.is_valid():
			callback.call()
		return
	screen_fade.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(screen_fade, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if callback.is_valid():
		tween.tween_callback(callback)

func show_game_over() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("defeat")
	game_over_panel.visible = true
	var lbl = $GameOverPanel/Panel/VBox/StatsLabel
	var target_enemies = GameManager.enemies_defeated
	var target_score = GameManager.score
	var tween = create_tween()
	tween.tween_method(func(prog: float):
		var e = int(target_enemies * prog)
		var s = int(target_score * prog)
		lbl.text = "Enemigos derrotados: %d\nPuntuación final: %d" % [e, s]
	, 0.0, 1.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func show_victory() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_ui"):
		am.play_ui("victory")
	victory_panel.visible = true
	var lbl = $VictoryPanel/Panel/VBox/StatsLabel
	var target_shrines = GameManager.active_shrines
	var target_enemies = GameManager.enemies_defeated
	var target_score = GameManager.score
	var tween = create_tween()
	tween.tween_method(func(prog: float):
		var sh = int(target_shrines * prog)
		var e = int(target_enemies * prog)
		var s = int(target_score * prog)
		lbl.text = "¡Has completado el nivel con éxito!\nLugares conquistados: %d\nBajas enemigas: %d\nPuntuación: %d" % [sh, e, s]
	, 0.0, 1.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_retry_pressed() -> void:
	fade_out_screen(0.3, func(): GameManager.start_game(GameManager.current_mode))

func _on_menu_pressed() -> void:
	fade_out_screen(0.3, func(): GameManager.return_to_main_menu())
