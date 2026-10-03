class_name DebtCrisisEvent
extends StoryEvent

@export
var fight_injury_chance : float = 0.3


func can_trigger() -> bool:
	return super.can_trigger() and not Crew.passengers_on_board().is_empty()


func _start() -> void:
	var choices : Array[EventOption] = []
	for member in _ordered_passengers():
		choices.append(_option("option_" + member.member_id, "send", member.member_id))
	choices.append(_option("option_fight", "fight"))
	_show(story_text("description"), choices)


func choose(option: EventOption) -> void:
	if option.action == "send":
		var member : CrewMember = Crew.get_member(option.target_id)
		var text : String = story_text("leave_" + member.member_id, Journal.member_args(member))
		Crew.exile(member.member_id, "debt")
		_finish(text)
		return
	var lines : Array[String] = [story_text("fight_result")]
	for member in _ordered_passengers():
		_try_injure(member, fight_injury_chance, lines)
	_finish("\n\n".join(lines))
