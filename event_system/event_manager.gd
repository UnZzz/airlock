extends Node

signal event_started(event: BaseEvent)
signal event_finished(event: BaseEvent)
signal guest_changed(aboard: bool)

@export
var event_chance : float = 0.6
@export
var events : Array[BaseEvent] = []
@export
var guest_drink_interval : int = 2
@export
var guest_drink_cost : int = 1

var used_event_ids : Array[String] = []
var current_event : BaseEvent = null
var guest_aboard : bool = false
var guest_join_day : int = 0


func reset() -> void:
	used_event_ids.clear()
	current_event = null
	guest_aboard = false
	guest_join_day = 0
	guest_changed.emit(false)


func admit_guest() -> void:
	guest_aboard = true
	guest_join_day = Timeline.current_day
	guest_changed.emit(true)


func evict_guest() -> void:
	guest_aboard = false
	guest_changed.emit(false)


func end_day() -> void:
	if not guest_aboard or guest_drink_interval <= 0:
		return
	var days : int = Timeline.current_day - guest_join_day + 1
	if days % guest_drink_interval == 0:
		Inventory.apply_change(0, -guest_drink_cost)


func find_event(event_id: String) -> BaseEvent:
	for event in events:
		if event.event_id == event_id:
			return event
	return null


func pick_event_for_day(day: int) -> BaseEvent:
	var fixed_id : String = Journal.get_fixed_event(day)
	if fixed_id == Journal.NO_EVENT or fixed_id == "airlock" or fixed_id == "none" or fixed_id == "ending":
		return null
	if fixed_id != "" and fixed_id != Journal.RANDOM_EVENT:
		var fixed : BaseEvent = find_event(fixed_id)
		if fixed == null:
			push_error("Missing fixed event: " + fixed_id)
			return null
		return fixed.duplicate() as BaseEvent
	if randf() >= event_chance:
		return null
	var candidates : Array[BaseEvent] = []
	for event in events:
		if not event.in_random_pool or not event.can_trigger():
			continue
		if not event.repeatable and used_event_ids.has(event.event_id):
			continue
		candidates.append(event)
	if candidates.is_empty():
		return null
	return candidates.pick_random().duplicate() as BaseEvent


func start_event(event: BaseEvent) -> void:
	current_event = event
	event.begin()
	event_started.emit(event)


func choose(option: EventOption) -> void:
	if current_event == null or current_event.is_finished:
		return
	current_event.choose(option)


func finish() -> void:
	if current_event != null:
		used_event_ids.append(current_event.event_id)
		event_finished.emit(current_event)
	current_event = null
