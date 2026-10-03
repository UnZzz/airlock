extends Node

signal airlock_resolved(target: CrewMember)

var airlock_count : int = 0
var is_resolved : bool = false
var result_text : String = ""


func reset() -> void:
	airlock_count = 0
	is_resolved = false
	result_text = ""


func begin() -> void:
	is_resolved = false
	result_text = ""


func get_sedated() -> Array[CrewMember]:
	var result : Array[CrewMember] = []
	for member in Crew.passengers_on_board():
		if member.fed_today:
			result.append(member)
	return result


func get_intro_text() -> String:
	var lines : Array[String] = []
	var chef : CrewMember = Crew.get_by_role(CrewMember.Role.CHEF)
	if chef != null and chef.is_on_board():
		var key : String = "airlock_intro_first" if airlock_count == 0 else "airlock_intro_chef"
		lines.append(Journal.text(key, {"chef": chef.display_name}))
	else:
		lines.append(Journal.text("airlock_intro_captain"))
	var names : Array[String] = []
	for member in get_sedated():
		names.append(member.display_name)
	if names.is_empty():
		lines.append(Journal.text("airlock_nobody_sedated"))
	else:
		lines.append(Journal.text("airlock_sedated_list", {"names": Journal.text("list_separator").join(names)}))
	return "\n\n".join(lines)


func resolve(target_id: String) -> void:
	if is_resolved:
		return
	_check_worker_promise(target_id)
	airlock_count += 1
	is_resolved = true
	var target : CrewMember = Crew.get_member(target_id)
	if target == null:
		result_text = Journal.text("airlock_result_nobody")
	else:
		Crew.exile(target_id)
		result_text = Journal.text("airlock_result_exile", {"name": target.display_name})
	airlock_resolved.emit(target)


func _check_worker_promise(target_id: String) -> void:
	var worker : CrewMember = Crew.get_by_role(CrewMember.Role.WORKER)
	if worker == null or not worker.is_on_board():
		return
	match worker.current_promise:
		CrewMember.Promise.SPARE_NEXT_AIRLOCK:
			worker.current_promise = CrewMember.Promise.NONE
		CrewMember.Promise.EXILE_TARGET:
			var requested : String = worker.requested_exile_target
			worker.current_promise = CrewMember.Promise.NONE
			worker.requested_exile_target = ""
			if Crew.is_on_board(requested) and target_id != requested:
				worker.refuses_next_task = true
				Journal.add_entry(Timeline.current_day + 1, Journal.text("journal_worker_promise_broken", {"worker": worker.display_name}))
	Crew.crew_changed.emit()
