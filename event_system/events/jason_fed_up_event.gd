class_name JasonFedUpEvent
extends StoryEvent


func can_trigger() -> bool:
	return super.can_trigger() and EventManager.guest_aboard and not Crew.passengers_on_board().is_empty()


func _start() -> void:
	var choices : Array[EventOption] = []
	for member in _ordered_passengers():
		choices.append(_option("option_" + member.member_id, "evict", member.member_id))
	choices.append(_option("option_nothing", "nothing"))
	_show(story_text("description"), choices)


func choose(option: EventOption) -> void:
	if option.action != "evict":
		_finish("")
		return
	EventManager.evict_guest()
	_finish(story_text("result_evict", Journal.member_args(Crew.get_member(option.target_id))))
