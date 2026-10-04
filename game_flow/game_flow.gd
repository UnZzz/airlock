extends Node

enum Phase { OPENING, JOURNAL, ALLOCATION, EVENT, AIRLOCK, ENDING }

signal phase_changed(phase: Phase)


var phase : Phase = Phase.OPENING
var ending_id : String = ""


func _ready() -> void:
	Crew.member_died.connect(_on_member_died)
	Crew.member_exiled.connect(_on_member_exiled)
	Crew.intimidate_unlocked.connect(_on_intimidate_unlocked)
	Crew.mutiny.connect(_on_mutiny)
	Crew.infighting.connect(_on_infighting)
	Timeline.on_final_day.connect(_on_final_day)


func start_game() -> void:
	ending_id = ""
	Inventory.reset()
	EffectSystem.clear_all()
	Crew.reset()
	Timeline.reset()
	Journal.reset()
	EventManager.reset()
	Airlock.reset()
	_set_phase(Phase.OPENING)


func finish_opening() -> void:
	_set_phase(Phase.JOURNAL)


func finish_journal() -> void:
	_set_phase(Phase.ALLOCATION)


func submit_allocation(fed_ids: Array[String]) -> bool:
	if phase != Phase.ALLOCATION:
		return false
	if not Crew.serve_meals(fed_ids):
		return false
	var event : BaseEvent = EventManager.pick_event_for_day(Timeline.current_day)
	if event == null:
		_after_event()
	else:
		EventManager.start_event(event)
		_set_phase(Phase.EVENT)
	return true


func choose_event_option(option: EventOption) -> void:
	EventManager.choose(option)


func finish_event() -> void:
	EventManager.finish()
	_after_event()


func resolve_airlock(target_id: String) -> void:
	Airlock.resolve(target_id)


func finish_airlock() -> void:
	_end_day()


func get_ending_text() -> String:
	var has_survivors : bool = EventManager.guest_aboard or not Crew.passengers_on_board().is_empty()
	Journal.set_flag("guest_aboard", "yes" if EventManager.guest_aboard else "no")
	Journal.set_flag("survivors", "yes" if has_survivors else "no")
	var paragraphs : Array[String] = []
	var last_target : String = Journal.get_flag("last_airlock_target")
	if ending_id == "survived" and Journal.get_flag("day%d_exile" % Timeline.total_days) == "yes" and last_target != "":
		paragraphs.append(Journal.event_text("departure_" + ("doctor" if last_target == "helena" else last_target), "text"))
	var criminal : CrewMember = Crew.get_by_role(CrewMember.Role.CRIMINAL)
	paragraphs.append_array(Journal.get_ending(ending_id, {"criminal": criminal.short_name if criminal != null else ""}))
	return "\n\n".join(paragraphs)


func _after_event() -> void:
	if _check_ending():
		return
	if Timeline.is_time_to_kick_out:
		Airlock.begin()
		_set_phase(Phase.AIRLOCK)
	else:
		_end_day()


func _end_day() -> void:
	if _check_ending():
		return
	EventManager.end_day()
	Crew.end_day()
	if _check_ending():
		return
	EffectSystem.tick()
	if _check_ending():
		return
	Timeline.to_next_day()
	if _check_ending():
		return
	_set_phase(Phase.JOURNAL)


func _check_ending() -> bool:
	if ending_id == "":
		return false
	_set_phase(Phase.ENDING)
	return true


func _set_ending(id: String) -> void:
	if ending_id == "":
		ending_id = id


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	if phase == Phase.JOURNAL:
		_check_day_story_effects()
		if ending_id != "":
			phase = Phase.ENDING
	phase_changed.emit(phase)


func _check_day_story_effects() -> void:
	var day : int = Timeline.current_day
	if day == 6:
		if Journal.get_flag("day6_injure_elias") != "true":
			Journal.set_flag("day6_injure_elias", "true")
			if Crew.is_on_board("elias"):
				Crew.injure("elias")
	elif day == 12:
		if not Crew.is_on_board("helena") and Journal.get_flag("day12_poison") != "true":
			Journal.set_flag("day12_poison", "true")
			for member in Crew.on_board():
				if randf() < 0.5:
					Crew.injure(member.member_id)
	elif day == 16:
		if Journal.get_flag("day16_spider_food") != "true":
			Journal.set_flag("day16_spider_food", "true")
			Inventory.apply_change(5, 0)


func _next_day_entry(key: String, args: Dictionary) -> void:
	Journal.add_entry(Timeline.current_day + 1, Journal.text(key, args))


func _on_member_died(member: CrewMember, cause: String) -> void:
	if member.role == CrewMember.Role.CAPTAIN and cause == "starvation":
		_set_ending("captain_starvation")
		return
	_set_ending("uprising")


func _on_member_exiled(member: CrewMember) -> void:
	if member.exile_cause != "airlock":
		_next_day_entry("journal_exiled_" + member.exile_cause, {"name": member.display_name})


func _on_intimidate_unlocked(criminal: CrewMember) -> void:
	_next_day_entry("journal_intimidate_unlocked", {"criminal": criminal.display_name})


func _on_mutiny(_criminal: CrewMember) -> void:
	_set_ending("mutiny")


func _on_infighting() -> void:
	_set_ending("infighting")


func _on_final_day() -> void:
	_set_ending("survived")
