extends Node
func _ready():
	var s = load("res://start/StartScreen.tscn").instantiate()
	add_child(s)
	await get_tree().create_timer(1.5).timeout
	s.start_button.pressed.emit()
