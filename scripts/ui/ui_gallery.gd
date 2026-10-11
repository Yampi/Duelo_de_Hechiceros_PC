extends Control

const IconRegistry = preload("res://scripts/ui/icon_registry.gd")

@onready var hp_bar: StatBar = $Scroll/Content/BarsSection/HBoxBars/HpBar
@onready var mana_bar: StatBar = $Scroll/Content/BarsSection/HBoxBars/ManaBar
@onready var slot1: SpellSlot = $Scroll/Content/SlotsSection/HBoxSlots/Slot1
@onready var slot2: SpellSlot = $Scroll/Content/SlotsSection/HBoxSlots/Slot2
@onready var slot3: SpellSlot = $Scroll/Content/SlotsSection/HBoxSlots/Slot3
@onready var slot4: SpellSlot = $Scroll/Content/SlotsSection/HBoxSlots/Slot4

func _ready() -> void:
	if hp_bar:
		hp_bar.set_values(72.0, 100.0)
	if mana_bar:
		mana_bar.set_values(35.0, 75.0, "+4.5/s")
	
	if slot1:
		slot1.icon_texture = IconRegistry.get_icon("spells", "spell_lightning")
		slot1.is_selected = true
	if slot2:
		slot2.icon_texture = IconRegistry.get_icon("spells", "fireball")
		slot2.set_cooldown(0.45)
	if slot3:
		slot3.icon_texture = IconRegistry.get_icon("spells", "summon_goblin")
		slot3.update_mana_status(10.0) # Insufficient mana demonstration
	if slot4:
		slot4.is_locked = true
