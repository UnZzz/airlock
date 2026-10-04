class_name MasonRightsEvent
extends StoryEvent

@export
var endure_loyalty_change : int = 1

var accuser : CrewMember = null


func can_trigger() -> bool:
	return super.can_trigger() and Crew.is_role_on_board(CrewMember.Role.CRIMINAL) and not _accusers().is_empty()


func _accusers() -> Array[CrewMember]:
	var result : Array[CrewMember] = []
	for member in Crew.passengers_on_board():
		if member.role != CrewMember.Role.CRIMINAL:
			result.append(member)
	return result


func _start() -> void:
	accuser = _accusers().pick_random()
	var endure : EventOption = _option("option_endure", "endure")
	endure.loyalty_change = endure_loyalty_change
	_show(story_text("description", Journal.member_args(accuser)), [_option("option_tie", "tie"), endure])


func choose(option: EventOption) -> void:
	option.apply()
	if option.action == "tie":
		var criminal : CrewMember = Crew.get_by_role(CrewMember.Role.CRIMINAL)
		if criminal != null:
			Crew.exile(criminal.member_id, "tied")
	_finish("")
