class_name MasonGuardEvent
extends StoryEvent

@export
var food_gain : int = 2
@export
var injury_chance : float = 0.5


func can_trigger() -> bool:
	return super.can_trigger() and Crew.is_loyalty_full() and not _targets().is_empty()


func _targets() -> Array[CrewMember]:
	var result : Array[CrewMember] = []
	for member in Crew.passengers_on_board():
		if member.role != CrewMember.Role.CRIMINAL:
			result.append(member)
	return result


func _start() -> void:
	var target : CrewMember = _targets().pick_random()
	Inventory.apply_change(food_gain, 0)
	var lines : Array[String] = [story_text("description", Journal.member_args(target))]
	_try_injure(target, injury_chance, lines)
	_finish("\n\n".join(lines))
