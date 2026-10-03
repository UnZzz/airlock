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
	if ending_id == "survived":
		var names : Array[String] = []
		for member in Crew.passengers_on_board():
			names.append(member.display_name)
		if names.is_empty():
			return Journal.text("ending_survived_alone")
		return Journal.text("ending_survived", {"names": Journal.text("list_separator").join(names)})
	var criminal : CrewMember = Crew.get_by_role(CrewMember.Role.CRIMINAL)
	return Journal.text("ending_" + ending_id, {"criminal": criminal.display_name if criminal != null else ""})


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
	phase_changed.emit(phase)


func _next_day_entry(key: String, args: Dictionary) -> void:
	Journal.add_entry(Timeline.current_day + 1, Journal.text(key, args))


func _on_member_died(member: CrewMember, cause: String) -> void:
	if member.role == CrewMember.Role.CAPTAIN:
		_set_ending("captain_" + cause)
		return
	_next_day_entry("journal_died_" + cause, {"name": member.display_name})


func _on_member_exiled(member: CrewMember) -> void:
	var key : String = "journal_exiled" if member.exile_cause == "airlock" else "journal_exiled_" + member.exile_cause
	_next_day_entry(key, {"name": member.display_name})


func _on_intimidate_unlocked(criminal: CrewMember) -> void:
	_next_day_entry("journal_intimidate_unlocked", {"criminal": criminal.display_name})


func _on_mutiny(_criminal: CrewMember) -> void:
	_set_ending("mutiny")


func _on_final_day() -> void:
	_set_ending("survived")
