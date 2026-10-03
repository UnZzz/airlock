class_name DangerousTaskEvent
extends BaseEvent

@export_multiline
var success_text : String = ""
@export_multiline
var abandon_text : String = ""
@export
var success_food_change : int = 0
@export
var success_mouthwash_change : int = 0
@export
var abandon_food_change : int = 0
@export
var abandon_mouthwash_change : int = 0
@export
var injury_chance : float = 0.2
@export
var death_chance : float = 0.05
@export
var worker_injury_chance : float = 0.05
@export
var send_option_texts : Dictionary = {}
@export
var abandon_option_text : String = ""
@export_multiline
var worker_demand_text : String = ""
@export
var worker_demand_options : Array[EventOption] = []
@export
var outcome_flag : String = ""

var excluded_ids : Array[String] = []
var skip_promise_active : bool = false
var pending_demand : Dictionary = {}


func can_trigger() -> bool:
	return super.can_trigger() and not _eligible_members().is_empty()


func begin() -> void:
	excluded_ids.clear()
	pending_demand = {}
	skip_promise_active = false
	var lines : Array[String] = [description]
	var worker : CrewMember = _worker()
	if worker != null and worker.is_on_board():
		if worker.refuses_next_task:
			worker.refuses_next_task = false
			excluded_ids.append(worker.member_id)
			lines.append(Journal.text("worker_refuses_task", {"worker": worker.display_name}))
		elif worker.current_promise == CrewMember.Promise.SKIP_NEXT_TASK:
			skip_promise_active = true
	_show_assignment("\n\n".join(lines))


func choose(option: EventOption) -> void:
	match option.action:
		"send":
			_on_send(option.target_id)
		"accept":
			option.apply()
			_apply_demand()
			_complete_task(_worker())
		"intimidate":
			var lines : Array[String] = [Journal.text("worker_intimidated", {"criminal": _criminal_name(), "worker": _worker().display_name})]
			_complete_task(_worker(), lines)
		"refuse":
			excluded_ids.append(_worker().member_id)
			pending_demand = {}
			_show_assignment(description)
		"abandon":
			_abandon()


func _show_assignment(text: String) -> void:
	current_text = text
	current_options = []
	for member in _ordered_members():
		current_options.append(EventOption.create(_send_text(member), "send", member.member_id))
	current_options.append(EventOption.create(abandon_option_text if abandon_option_text != "" else Journal.text("ui_abandon_task"), "abandon"))
	is_finished = false


func _ordered_members() -> Array[CrewMember]:
	var eligible : Array[CrewMember] = _eligible_members()
	if send_option_texts.is_empty():
		return eligible
	var result : Array[CrewMember] = []
	for member_id in send_option_texts:
		for member in eligible:
			if member.member_id == member_id:
				result.append(member)
	return result


func _send_text(member: CrewMember) -> String:
	if send_option_texts.has(member.member_id):
		return String(send_option_texts[member.member_id])
	return Journal.text("ui_send", {"name": member.display_name})


func _eligible_members() -> Array[CrewMember]:
	var result : Array[CrewMember] = []
	for member in Crew.passengers_on_board():
		if excluded_ids.has(member.member_id):
			continue
		if Crew.get_health(member.member_id) == CrewMember.Health.CRITICAL:
			continue
		result.append(member)
	return result


func _on_send(member_id: String) -> void:
	var member : CrewMember = Crew.get_member(member_id)
	if member.role != CrewMember.Role.WORKER:
		_complete_task(member)
		return
	if skip_promise_active:
		skip_promise_active = false
		member.current_promise = CrewMember.Promise.NONE
		excluded_ids.append(member.member_id)
		_show_assignment(Journal.text("worker_refuses_promise", {"worker": member.display_name}))
		return
	_start_negotiation(member)


func _start_negotiation(worker: CrewMember) -> void:
	if not worker_demand_options.is_empty():
		_start_fixed_negotiation()
		return
	pending_demand = _available_demands(worker).pick_random()
	current_text = pending_demand["text"]
	var accept : EventOption = EventOption.create(Journal.text("ui_accept_demand"), "accept")
	accept.food_change = pending_demand.get("food", 0)
	accept.mouthwash_change = pending_demand.get("mouthwash", 0)
	current_options = [accept, EventOption.create(Journal.text("ui_refuse_demand"), "refuse")]
	if Crew.can_intimidate():
		current_options.append(EventOption.create(Journal.text("ui_intimidate", {"text": Journal.text("ui_intimidate_demand", {"criminal": _criminal_name()})}), "intimidate"))
	current_options.append(EventOption.create(Journal.text("ui_abandon_task"), "abandon"))
	is_finished = false


func _start_fixed_negotiation() -> void:
	pending_demand = {}
	current_text = worker_demand_text
	current_options = []
	current_options.append_array(worker_demand_options)
	if Crew.can_intimidate():
		current_options.append(EventOption.create(Journal.text("ui_intimidate", {"text": Journal.text("ui_intimidate_demand", {"criminal": _criminal_name()})}), "intimidate"))
	is_finished = false


func _available_demands(worker: CrewMember) -> Array[Dictionary]:
	var args : Dictionary = {"worker": worker.display_name}
	var demands : Array[Dictionary] = [
		{"type": "food", "food": -1, "text": Journal.text("worker_demand_food", args)},
		{"type": "mouthwash", "mouthwash": -1, "text": Journal.text("worker_demand_mouthwash", args)},
	]
	if worker.current_promise != CrewMember.Promise.NONE:
		return demands
	demands.append({"type": "skip_task", "text": Journal.text("worker_demand_skip_task", args)})
	if not worker.knows_airlock_secret:
		if Crew.exiled_count() > 0:
			demands.append({"type": "spare_airlock", "text": Journal.text("worker_demand_spare_airlock", args)})
			demands.append({"type": "secret", "text": Journal.text("worker_demand_secret", args)})
	else:
		var targets : Array[CrewMember] = []
		for member in Crew.passengers_on_board():
			if member.member_id != worker.member_id:
				targets.append(member)
		if not targets.is_empty():
			var target : CrewMember = targets.pick_random()
			args["target"] = target.display_name
			demands.append({"type": "exile_target", "target_id": target.member_id, "text": Journal.text("worker_demand_exile_target", args)})
	return demands


func _apply_demand() -> void:
	var worker : CrewMember = _worker()
	match pending_demand.get("type", ""):
		"skip_task":
			worker.current_promise = CrewMember.Promise.SKIP_NEXT_TASK
		"spare_airlock":
			worker.current_promise = CrewMember.Promise.SPARE_NEXT_AIRLOCK
		"secret":
			worker.knows_airlock_secret = true
			Journal.add_entry(Timeline.current_day + 1, Journal.text("journal_secret_reveal", {"worker": worker.display_name}))
		"exile_target":
			worker.current_promise = CrewMember.Promise.EXILE_TARGET
			worker.requested_exile_target = pending_demand["target_id"]
	pending_demand = {}
	Crew.crew_changed.emit()


func _complete_task(member: CrewMember, lines: Array[String] = []) -> void:
	var died : bool = false
	var injured : bool = false
	if member.role == CrewMember.Role.WORKER:
		injured = randf() < worker_injury_chance
	else:
		var roll : float = randf()
		died = roll < death_chance
		injured = not died and roll < death_chance + injury_chance
	if died:
		_set_outcome("died", member.member_id)
		Crew.kill(member.member_id, "task")
		lines.append(Journal.text("task_died", {"name": member.display_name}))
	else:
		_set_outcome("worker" if member.role == CrewMember.Role.WORKER else "other", member.member_id)
		Inventory.apply_change(success_food_change, success_mouthwash_change)
		if success_text != "":
			lines.append(success_text.format({"name": member.display_name}))
		if injured:
			Crew.injure(member.member_id)
			lines.append(Journal.text("task_injured", {"name": member.display_name}))
	_finish("\n\n".join(lines))


func _abandon() -> void:
	_set_outcome("nothing", "")
	Inventory.apply_change(abandon_food_change, abandon_mouthwash_change)
	_finish(abandon_text)


func _set_outcome(outcome: String, member_id: String) -> void:
	if outcome_flag == "":
		return
	Journal.set_flag(outcome_flag, outcome)
	Journal.set_flag(outcome_flag + "_member", member_id)


func _finish(text: String) -> void:
	var worker : CrewMember = _worker()
	if skip_promise_active and worker != null and worker.current_promise == CrewMember.Promise.SKIP_NEXT_TASK:
		worker.current_promise = CrewMember.Promise.NONE
	skip_promise_active = false
	current_text = text
	current_options = []
	is_finished = true
	Crew.crew_changed.emit()


func _worker() -> CrewMember:
	return Crew.get_by_role(CrewMember.Role.WORKER)


func _criminal_name() -> String:
	var criminal : CrewMember = Crew.get_by_role(CrewMember.Role.CRIMINAL)
	return criminal.display_name if criminal != null else ""
