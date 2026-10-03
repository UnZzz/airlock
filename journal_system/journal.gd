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
				result.append(_fill_paragraph(item))
		else:
			result.append(String(item))
	return result


func _matches(conditions: Dictionary) -> bool:
	for key in conditions:
		if get_flag(key) != String(conditions[key]):
			return false
	return true


func _fill_paragraph(item: Dictionary) -> String:
	var content : String = String(item.get("text", ""))
	var member_flag : String = String(item.get("member", ""))
	if member_flag == "":
		return content
	var member : CrewMember = Crew.get_member(get_flag(member_flag))
	if member == null:
		return content
	return content.format({"name": member.short_name, "ta": member.pronoun})


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
