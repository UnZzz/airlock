extends Node

signal entry_added(day: int, text: String)
signal language_changed(language: String)

const STORY_PATH : String = "res://story/story_%s.json"
const SYSTEM_TEXT_PATH : String = "res://story/system_text_%s.json"
const EVENT_TEXT_PATH : String = "res://story/event_text_%s.json"
const OPTION_LISTS : Array[String] = ["options", "worker_demand_options"]
const SETTINGS_PATH : String = "user://settings.cfg"
const LANGUAGES : Array[String] = ["en", "zh"]
const NO_EVENT : String = "none"
const RANDOM_EVENT : String = "random"

var story : Dictionary = {}
var system_text : Dictionary = {}
var event_overrides : Dictionary = {}
var pending_entries : Dictionary = {}
var flags : Dictionary = {}
var language : String = "en"


func _ready() -> void:
	var settings : ConfigFile = ConfigFile.new()
	if settings.load(SETTINGS_PATH) == OK:
		language = String(settings.get_value("general", "language", language))
	if not LANGUAGES.has(language):
		language = LANGUAGES[0]
	_load_texts()


func set_language(value: String) -> void:
	if not LANGUAGES.has(value) or value == language:
		return
	language = value
	_load_texts()
	var settings : ConfigFile = ConfigFile.new()
	settings.load(SETTINGS_PATH)
	settings.set_value("general", "language", language)
	settings.save(SETTINGS_PATH)
	language_changed.emit(language)


func next_language() -> String:
	return LANGUAGES[(LANGUAGES.find(language) + 1) % LANGUAGES.size()]


func localize_member(member: CrewMember) -> void:
	member.display_name = String(system_text.get("member_name_" + member.member_id, member.display_name))
	member.short_name = String(system_text.get("member_short_" + member.member_id, member.short_name))
	member.pronoun = String(system_text.get("member_pronoun_" + member.member_id, member.pronoun))


func member_name(member_id: String, fallback: String) -> String:
	return String(system_text.get("member_name_" + member_id, fallback))


func localize_event(event: BaseEvent) -> void:
	_apply_overrides(event, event_overrides.get(event.event_id, {}))


func effect_name(effect: BaseEffect) -> String:
	return String(system_text.get("effect_name_" + effect.effect_name, effect.display_name))


func _load_texts() -> void:
	story = _load_localized(STORY_PATH)
	system_text = _load_localized(SYSTEM_TEXT_PATH)
	event_overrides = {}
	if FileAccess.file_exists(EVENT_TEXT_PATH % language):
		event_overrides = _load_json(EVENT_TEXT_PATH % language)


func _apply_overrides(target: Object, overrides: Dictionary) -> void:
	var defaults : Dictionary = target.get_meta("text_defaults", {})
	for key in defaults:
		target.set(key, defaults[key])
	for key in overrides:
		if overrides[key] is Array:
			continue
		if not defaults.has(key):
			defaults[key] = target.get(key)
		target.set(key, overrides[key])
	target.set_meta("text_defaults", defaults)
	for key in OPTION_LISTS:
		if not key in target:
			continue
		var items : Array = target.get(key)
		var item_overrides : Array = overrides.get(key, [])
		for i in items.size():
			var item_override : Variant = item_overrides[i] if i < item_overrides.size() else {}
			_apply_overrides(items[i], item_override if item_override is Dictionary else {})


func _load_localized(path: String) -> Dictionary:
	var result : Dictionary = _load_json(path % LANGUAGES[0])
	if language != LANGUAGES[0]:
		_merge_into(result, _load_json(path % language))
	return result


func _merge_into(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		if target.get(key) is Dictionary and source[key] is Dictionary:
			_merge_into(target[key], source[key])
		else:
			target[key] = source[key]


func reset() -> void:
	pending_entries.clear()
	flags.clear()


func set_flag(key: String, value: String) -> void:
	flags[key] = value


func get_flag(key: String) -> String:
	return String(flags.get(key, ""))


func text(key: String, args: Dictionary = {}) -> String:
	return String(system_text.get(key, key)).format(args)


func get_opening() -> Dictionary:
	var opening : Dictionary = story.get("opening", {})
	return {
		"title": String(opening.get("title", "")),
		"paragraphs": _to_string_array(opening.get("paragraphs", [])),
	}


func get_ending(ending_id: String, args: Dictionary = {}) -> Array[String]:
	var result : Array[String] = []
	for paragraph in _resolve_paragraphs(story.get("endings", {}).get(ending_id, [])):
		result.append(paragraph.format(args))
	return result


func get_airlock_text(day: int) -> String:
	return String(_day_data(day).get("airlock_text", ""))


func get_day_page(day: int) -> Dictionary:
	var data : Dictionary = _day_data(day)
	var paragraphs : Array[String] = _resolve_paragraphs(data.get("journal", []))
	paragraphs.append_array(_to_string_array(pending_entries.get(day, [])))
	if paragraphs.is_empty():
		paragraphs.append(text("ui_journal_empty"))
	var title : String = String(data.get("journal_title", text("journal_title_format", {"day": "%02d" % day})))
	return {"title": title, "paragraphs": paragraphs}


func get_allocation_title(day: int) -> String:
	return String(_day_data(day).get("allocation_title", text("allocation_title")))


func get_allocation_text(day: int) -> String:
	return String(_day_data(day).get("allocation_text", ""))


func get_fixed_event(day: int) -> String:
	return String(_day_data(day).get("event", ""))


func has_event_text(event_id: String) -> bool:
	return story.get("events", {}).has(event_id)


func event_value(event_id: String, key: String) -> Variant:
	return story.get("events", {}).get(event_id, {}).get(key, "")


func event_text(event_id: String, key: String, args: Dictionary = {}) -> String:
	var value : Variant = event_value(event_id, key)
	if not value is Array:
		return String(value).format(args)
	var parts : Array[String] = []
	for item in value:
		if item is Dictionary:
			var member_id : String = String(item.get("if_on_board", ""))
			if member_id != "" and not Crew.is_on_board(member_id):
				continue
			parts.append(String(item.get("text", "")).format(args))
		else:
			parts.append(String(item).format(args))
	return "\n\n".join(parts)


func member_args(member: CrewMember) -> Dictionary:
	if member == null:
		return {}
	var objects : Dictionary = {"he": "him", "she": "her"}
	var possessives : Dictionary = {"he": "his", "she": "her"}
	return {
		"name": member.short_name,
		"full_name": member.display_name,
		"ta": member.pronoun,
		"ta_obj": String(objects.get(member.pronoun, member.pronoun)),
		"ta_pos": String(possessives.get(member.pronoun, member.pronoun)),
	}


func add_entry(day: int, entry: String) -> void:
	if not pending_entries.has(day):
		pending_entries[day] = []
	pending_entries[day].append(entry)
	entry_added.emit(day, entry)


func _day_data(day: int) -> Dictionary:
	return story.get("days", {}).get(str(day), {})


func _resolve_paragraphs(source: Array) -> Array[String]:
	var result : Array[String] = []
	for item in source:
		if item is Dictionary:
			if _matches(item.get("if", {})):
				var filled : String = _fill_paragraph(item)
				if filled != "":
					result.append(filled)
		else:
			result.append(String(item))
	return result


func _matches(conditions: Dictionary) -> bool:
	for key in conditions:
		var target_val : String = String(conditions[key])
		if key == "if_on_board":
			var id : String = target_val
			if id == "doctor":
				id = "helena"
			if not Crew.is_on_board(id):
				return false
		elif key == "if_not_on_board":
			var id : String = target_val
			if id == "doctor":
				id = "helena"
			if Crew.is_on_board(id):
				return false
		elif key.ends_with("_status"):
			var id : String = key.replace("_status", "")
			if id == "doctor":
				id = "helena"
			var member : CrewMember = Crew.get_member(id)
			if target_val == "alive":
				if member == null or not member.is_on_board():
					return false
			elif target_val == "exiled":
				if member == null or member.status != CrewMember.Status.EXILED:
					return false
			elif target_val == "dead":
				if member != null and member.is_on_board():
					return false
		else:
			if get_flag(key) != target_val:
				return false
	return true


func _fill_paragraph(item: Dictionary) -> String:
	var content : String = String(item.get("text", ""))
	var member_flag : String = String(item.get("member", ""))
	var args : Dictionary = {}
	if member_flag == "any_passenger":
		var passengers : Array[CrewMember] = Crew.passengers_on_board()
		if passengers.is_empty():
			return ""
		var member : CrewMember = passengers[0]
		args = member_args(member)
	elif member_flag != "":
		var member : CrewMember = Crew.get_member(get_flag(member_flag))
		if member != null:
			args = member_args(member)
	
	if content.contains("{random_passenger}"):
		var passengers : Array[CrewMember] = Crew.passengers_on_board()
		if not passengers.is_empty():
			args["random_passenger"] = passengers.pick_random().display_name
		else:
			args["random_passenger"] = text("someone")
			
	if content.contains("{exiled_name}"):
		var name : String = get_flag("last_airlock_target_name")
		args["exiled_name"] = name if name != "" else "Daniel Price"
		
	if args.is_empty():
		return content
	return content.format(args)


func _to_string_array(source: Array) -> Array[String]:
	var result : Array[String] = []
	for item in source:
		result.append(String(item))
	return result


func _load_json(path: String) -> Dictionary:
	var content : String = FileAccess.get_file_as_string(path)
	var parsed : Variant = JSON.parse_string(content)
	if parsed is Dictionary:
		return parsed
	push_error("Failed to load " + path)
	return {}
