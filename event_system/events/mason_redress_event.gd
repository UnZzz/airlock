class_name MasonRedressEvent
extends StoryEvent

@export
var apology_mouthwash_cost : int = 1
@export
var apology_loyalty_change : int = 1
@export
var silence_injury_chance : float = 0.5


func can_trigger() -> bool:
	return super.can_trigger() and Crew.is_role_on_board(CrewMember.Role.CRIMINAL)


func _start() -> void:
	var apology : EventOption = _option("option_apology", "apology")
	apology.mouthwash_change = -apology_mouthwash_cost
	apology.loyalty_change = apology_loyalty_change
	_show(story_text("description"), [apology, _option("option_silence", "silence")])


func choose(option: EventOption) -> void:
	option.apply()
	var lines : Array[String] = []
	if option.action == "silence":
		_try_injure(Crew.get_by_role(CrewMember.Role.CAPTAIN), silence_injury_chance, lines)
	_finish("\n\n".join(lines))
