extends Node

signal effect_added(target_id: String, effect: BaseEffect)
signal effect_removed(target_id: String, effect: BaseEffect)
signal effect_expired(target_id: String, effect: BaseEffect)

const SHIP : String = "ship"

var active_effects : Dictionary = {}


func add_effect(target_id: String, effect: BaseEffect) -> void:
	if effect == null:
		return
	remove_effect(target_id, effect.effect_name)
	if not active_effects.has(target_id):
		active_effects[target_id] = []
	active_effects[target_id].append({"effect": effect, "remaining": effect.duration})
	effect_added.emit(target_id, effect)


func remove_effect(target_id: String, effect_name: String) -> void:
	var entry : Dictionary = _find_entry(target_id, effect_name)
	if entry.is_empty():
		return
	active_effects[target_id].erase(entry)
	effect_removed.emit(target_id, entry["effect"])


func has_effect(target_id: String, effect_name: String) -> bool:
	return not _find_entry(target_id, effect_name).is_empty()


func get_effects(target_id: String) -> Array[BaseEffect]:
	var result : Array[BaseEffect] = []
	for entry in active_effects.get(target_id, []):
		result.append(entry["effect"])
	return result


func get_remaining(target_id: String, effect_name: String) -> int:
	var entry : Dictionary = _find_entry(target_id, effect_name)
	if entry.is_empty():
		return 0
	return entry["remaining"]


func reset_duration(target_id: String, effect_name: String) -> void:
	var entry : Dictionary = _find_entry(target_id, effect_name)
	if entry.is_empty():
		return
	entry["remaining"] = entry["effect"].duration


func clear_target(target_id: String) -> void:
	if not active_effects.has(target_id):
		return
	var entries : Array = active_effects[target_id]
	active_effects.erase(target_id)
	for entry in entries:
		effect_removed.emit(target_id, entry["effect"])


func clear_all() -> void:
	for target_id in active_effects.keys():
		clear_target(target_id)


func tick() -> void:
	var expired : Array = []
	for target_id in active_effects.keys():
		for entry in active_effects[target_id].duplicate():
			if entry["remaining"] > 0:
				entry["remaining"] -= 1
				if entry["remaining"] == 0:
					active_effects[target_id].erase(entry)
					expired.append([target_id, entry["effect"]])
	for pair in expired:
		var target_id : String = pair[0]
		var effect : BaseEffect = pair[1]
		effect_expired.emit(target_id, effect)
		effect_removed.emit(target_id, effect)
		if effect.next_effect != null:
			add_effect(target_id, effect.next_effect)


func _find_entry(target_id: String, effect_name: String) -> Dictionary:
	for entry in active_effects.get(target_id, []):
		if entry["effect"].effect_name == effect_name:
			return entry
	return {}
