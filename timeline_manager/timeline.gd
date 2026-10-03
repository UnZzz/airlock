extends Node

@export
var total_days = 30
@export
var airlock_interval = 7
var current_day = 1
var remaining_days = 30
var is_time_to_kick_out = false

signal on_next_day
signal on_airlock_day
signal on_final_day


func reset():
	current_day = 1
	_refresh()


func to_next_day():
	if current_day >= total_days:
		on_final_day.emit()
		return
	current_day += 1
	_refresh()
	on_next_day.emit()
	if is_time_to_kick_out:
		on_airlock_day.emit()


func is_airlock_day(day: int) -> bool:
	return day % airlock_interval == 0


func get_next_airlock_day() -> int:
	var day : int = int(ceil(float(current_day) / airlock_interval)) * airlock_interval
	if day > total_days:
		return -1
	return day


func _refresh():
	remaining_days = total_days - current_day + 1
	is_time_to_kick_out = is_airlock_day(current_day)
