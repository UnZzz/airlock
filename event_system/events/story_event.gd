class_name StoryEvent
extends BaseEvent

const PASSENGER_ORDER : Array[String] = ["elias", "mara", "helena", "mason"]


func begin() -> void:
	title = story_text("title")
	_start()


func _start() -> void:
	_finish(story_text("description"))


func story_text(key: String, args: Dictionary = {}) -> String:
	return Journal.event_text(event_id, key, args)


func _show(text: String, options_to_show: Array[EventOption]) -> void:
	current_text = text
	current_options = build_options(options_to_show)
	is_finished = current_options.is_empty()


func _finish(text: String) -> void:
	current_text = text
	current_options = []
	is_finished = true
	Crew.crew_changed.emit()


func _option(key: String, option_action: String, target: String = "", args: Dictionary = {}) -> EventOption:
	return EventOption.create(story_text(key, args), option_action, target)


func _ordered_passengers() -> Array[CrewMember]:
	var result : Array[CrewMember] = []
	for member_id in PASSENGER_ORDER:
		if Crew.is_on_board(member_id):
			result.append(Crew.get_member(member_id))
	for member in Crew.passengers_on_board():
		if not result.has(member):
			result.append(member)
	return result


func _try_injure(member: CrewMember, chance: float, lines: Array[String]) -> void:
	if member == null or not member.is_on_board() or randf() >= chance:
		return
	_injure(member, lines)


func _injure(member: CrewMember, lines: Array[String]) -> void:
	Crew.injure(member.member_id)
	var key : String = "task_injured" if member.is_on_board() else "task_died"
	lines.append(Journal.text(key, {"name": member.display_name}))
