class_name InventoryManager
extends RefCounted

const ItemDB = preload("res://scripts/inventory/item_db.gd")
const ItemDefinition = preload("res://scripts/inventory/item_definition.gd")

signal inventory_updated
signal item_added(item_id: String, amount: int)
signal item_used(item_id: String, success: bool)
signal inventory_full_warning(item_id: String)

const MAX_SLOTS: int = 16

# Each slot is a Dictionary: {"item_id": String, "count": int} or empty {}
var slots: Array[Dictionary] = []

func _init() -> void:
	clear()

func clear() -> void:
	slots.clear()
	for i in range(MAX_SLOTS):
		slots.append({})
	inventory_updated.emit()

func can_add_item(item_id: String, amount: int = 1) -> bool:
	var def = ItemDB.get_item(item_id)
	if not def:
		return false
	if amount <= 0:
		return true
	
	var remaining = amount
	for slot in slots:
		if not slot.is_empty() and slot.get("item_id", "") == item_id:
			var space = def.max_stack - slot.get("count", 0)
			if space > 0:
				remaining -= min(remaining, space)
				if remaining <= 0:
					return true
	
	for slot in slots:
		if slot.is_empty():
			remaining -= min(remaining, def.max_stack)
			if remaining <= 0:
				return true
	
	return remaining <= 0

func add_item(item_id: String, amount: int = 1) -> bool:
	var def = ItemDB.get_item(item_id)
	if not def:
		push_warning("InventoryManager: Intento de agregar objeto desconocido: " + item_id)
		return false
	if amount <= 0:
		return true
	
	if not can_add_item(item_id, amount):
		inventory_full_warning.emit(item_id)
		return false
	
	var remaining = amount
	
	# First pass: stack onto existing slots
	for i in range(slots.size()):
		var slot = slots[i]
		if not slot.is_empty() and slot.get("item_id", "") == item_id:
			var current_count = slot.get("count", 0)
			var space = def.max_stack - current_count
			if space > 0:
				var to_add = min(remaining, space)
				slot["count"] = current_count + to_add
				remaining -= to_add
				if remaining <= 0:
					break
	
	# Second pass: fill empty slots
	if remaining > 0:
		for i in range(slots.size()):
			if slots[i].is_empty():
				var to_add = min(remaining, def.max_stack)
				slots[i] = {
					"item_id": item_id,
					"count": to_add
				}
				remaining -= to_add
				if remaining <= 0:
					break
	
	inventory_updated.emit()
	item_added.emit(item_id, amount)
	return true

func remove_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return true
	if get_item_count(item_id) < amount:
		return false
	
	var remaining = amount
	# Remove starting from last slots to keep stacks clean
	for i in range(slots.size() - 1, -1, -1):
		var slot = slots[i]
		if not slot.is_empty() and slot.get("item_id", "") == item_id:
			var current_count = slot.get("count", 0)
			if current_count <= remaining:
				remaining -= current_count
				slots[i] = {}
			else:
				slot["count"] = current_count - remaining
				remaining = 0
			
			if remaining <= 0:
				break
	
	inventory_updated.emit()
	return true

func get_item_count(item_id: String) -> int:
	var total = 0
	for slot in slots:
		if not slot.is_empty() and slot.get("item_id", "") == item_id:
			total += slot.get("count", 0)
	return total

func has_item(item_id: String, amount: int = 1) -> bool:
	return get_item_count(item_id) >= amount

func use_item(item_id: String, player: Node = null) -> bool:
	var def = ItemDB.get_item(item_id)
	if not def or not def.is_usable:
		item_used.emit(item_id, false)
		return false
	
	if get_item_count(item_id) <= 0:
		item_used.emit(item_id, false)
		return false
	
	var player_pos = player.global_position if (player and "global_position" in player) else Vector3.ZERO
	
	match def.effect_type:
		"heal_hp":
			GameManager.player_health = min(GameManager.player_max_health, GameManager.player_health + def.effect_value)
			GameManager.spawn_damage_number(player_pos + Vector3(0, 1.2, 0), "💚 +%d HP" % int(def.effect_value), Color(0.2, 1.0, 0.4), 1.25)
			if player and player.has_method("_pulse_staff"):
				player._pulse_staff(Color(0.2, 1.0, 0.4), 0.4)
			if player and "heal_scene" in player and player.heal_scene:
				var h = player.heal_scene.instantiate()
				player.add_child(h)
		"restore_mana":
			GameManager.player_mana = min(GameManager.player_max_mana, GameManager.player_mana + def.effect_value)
			GameManager.spawn_damage_number(player_pos + Vector3(0, 1.2, 0), "💧 +%d MP" % int(def.effect_value), Color(0.3, 0.8, 1.0), 1.25)
			if player and player.has_method("_pulse_staff"):
				player._pulse_staff(Color(0.3, 0.8, 1.0), 0.4)
		"haste_buff":
			if player and player.has_method("apply_haste_buff"):
				player.apply_haste_buff(def.effect_value)
			GameManager.spawn_damage_number(player_pos + Vector3(0, 1.4, 0), "⚡ ¡CELERIDAD!", Color(0.9, 0.3, 1.0), 1.3)
			if player and player.has_method("_pulse_staff"):
				player._pulse_staff(Color(0.9, 0.3, 1.0), 0.6)
		_:
			item_used.emit(item_id, false)
			return false
	
	remove_item(item_id, 1)
	item_used.emit(item_id, true)
	return true

func get_used_slots_count() -> int:
	var count = 0
	for s in slots:
		if not s.is_empty():
			count += 1
	return count

func swap_slots(idx_a: int, idx_b: int) -> void:
	if idx_a < 0 or idx_a >= slots.size() or idx_b < 0 or idx_b >= slots.size() or idx_a == idx_b:
		return
	var temp = slots[idx_a]
	slots[idx_a] = slots[idx_b]
	slots[idx_b] = temp
	inventory_updated.emit()
