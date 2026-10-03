class_name BaseEvent
extends Resource

@export
var event_id : String = ""
@export
var title : String = ""
@export_multiline
var description : String
@export
var options : Array[EventOption] = []
@export
var required_members : Array[String] = []
@export
var in_random_pool : bool = true
@export
var repeatable : bool = false

var current_text : String = ""
var current_options : Array[EventOption] = []
var is_finished : bool = false


func can_trigger() -> bool:
	for member_id in required_members:
		if not Crew.is_on_board(member_id):
			return false
	return true


func begin() -> void:
	current_text = description
	current_options = build_options(options)
	is_finished = current_options.is_empty()


func choose(option: EventOption) -> void:
	option.apply()
	current_text = option.result_text
	current_options = []
	is_finished = true


func build_options(source: Array[EventOption]) -> Array[EventOption]:
	var result : Array[EventOption] = []
	for option in source:
		if not option.is_visible():
			continue
		result.append(option)
		if option.intimidatable and option.has_cost() and Crew.can_intimidate():
			result.append(option.make_intimidated())
	return result
