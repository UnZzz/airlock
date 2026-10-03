extends Node

signal entry_added(day: int, text: String)

const STORY_PATH : String = "res://story/story_en.json"
const SYSTEM_TEXT_PATH : String = "res://story/system_text_en.json"
const NO_EVENT : String = "none"
const RANDOM_EVENT : String = "random"

var story : Dictionary = {}
var system_text : Dictionary = {}
var pending_entries : Dictionary = {}
var flags : Dictionary = {}


func _ready() -> void:
	story = _load_json(STORY_PATH)
	system_text = _load_json(SYSTEM_TEXT_PATH)


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
			args["random_passenger"] = "Someone"
			
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
