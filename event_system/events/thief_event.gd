class_name ThiefEvent
extends StoryEvent

@export
var required_hungry_days : int = 3
@export
var force_injury_chance : float = 0.25
@export
var trade_mouthwash_cost : int = 1
@export
var release_food_cost : int = 2

var thief : CrewMember = null


func can_trigger() -> bool:
	return super.can_trigger() and not _suspects().is_empty()


func _suspects() -> Array[CrewMember]:
	var result : Array[CrewMember] = []
	for member in Crew.passengers_on_board():
		if member.hungry_day_count >= required_hungry_days:
			result.append(member)
	return result


func _start() -> void:
	thief = _suspects().pick_random()
	var args : Dictionary = Journal.member_args(thief)
	var trade : EventOption = _option("option_trade", "trade", thief.member_id, args)
	trade.mouthwash_change = -trade_mouthwash_cost
	var release : EventOption = _option("option_release", "release", thief.member_id, args)
	release.food_change = -release_food_cost
	var choices : Array[EventOption] = [_option("option_force", "force", thief.member_id, args), trade, release]
	if Crew.is_loyalty_full() and thief.role != CrewMember.Role.CRIMINAL:
		choices.append(_option("option_mason", "mason", thief.member_id, args))
	_show(story_text("description", args), choices)


func choose(option: EventOption) -> void:
	option.apply()
	thief.hungry_day_count = 0
	var lines : Array[String] = []
	if option.action == "force":
		_try_injure(thief, force_injury_chance, lines)
	_finish("\n\n".join(lines))
