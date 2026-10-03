class_name AlcoholDistillEvent
extends StoryEvent

@export
var mouthwash_cost : int = 2

var patient : CrewMember = null


func can_trigger() -> bool:
	return super.can_trigger() and Crew.doctor_available() and not _patients().is_empty()


func _patients() -> Array[CrewMember]:
	var result : Array[CrewMember] = []
	for member in Crew.passengers_on_board():
		if member.role == CrewMember.Role.DOCTOR or member.distill_triggered:
			continue
		if Crew.get_injury_effect(member.member_id) == null:
			continue
		if member.last_mouthwash_day >= Timeline.current_day - 1:
			result.append(member)
	return result


func _start() -> void:
	patient = _patients().pick_random()
	patient.distill_triggered = true
	var args : Dictionary = Journal.member_args(patient)
	var accept : EventOption = _option("option_accept", "heal", patient.member_id, args)
	accept.mouthwash_change = -mouthwash_cost
	var choices : Array[EventOption] = [accept, _option("option_refuse", "refuse", patient.member_id, args)]
	if Crew.is_loyalty_full():
		var mason : EventOption = _option("option_mason", "heal", patient.member_id, args)
		mason.mouthwash_change = -mouthwash_cost
		choices.append(mason)
	_show(story_text("description", args), choices)


func choose(option: EventOption) -> void:
	option.apply()
	if option.action == "heal":
		Crew.heal(patient.member_id)
	_finish("")
