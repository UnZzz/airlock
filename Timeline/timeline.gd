extends Node

@export
var remaining_days = 30
var is_time_to_kick_out = false
var seven_day_counter = 0

signal on_next_day
signal on_final_day

func to_next_day():
	remaining_days -= 1
	seven_day_counter += 1
	is_time_to_kick_out = false
	
	if (seven_day_counter == 7):
		is_time_to_kick_out = true
		seven_day_counter = 0
	
	if (remaining_days < 0):
		remaining_days = 0
		on_final_day.emit()
	else:
		on_next_day.emit()
	pass
