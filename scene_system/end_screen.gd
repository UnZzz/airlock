extends Control

const START_SCENE_PATH: String = "res://start/StartScreen.tscn"

@export var fade_in_time: float = 1.2
@export var fade_out_time: float = 0.8
@export var menu_delay: float = 2.0

@onready var menu = $Menu
@onready var back_menu_button = $Menu/BackMenuButton
@onready var credit_button = $Menu/CreditButton

var leaving: bool = false


func _ready() -> void:
	back_menu_button.text = "Back to menu"
	credit_button.text = "Credits"

	back_menu_button.pressed.connect(_on_back_menu)
	credit_button.pressed.connect(_on_credit)

	# Only hide the buttons/menu.
	# Background stays visible.
	menu.modulate.a = 0.0

	# Wait 2 seconds
	await get_tree().create_timer(menu_delay).timeout

	# Fade only the buttons in
	var tween: Tween = create_tween()

	tween.tween_property(
		menu,
		"modulate:a",
		1.0,
		fade_in_time
	)

	await tween.finished

	back_menu_button.grab_focus()


func _on_back_menu() -> void:
	if leaving:
		return

	leaving = true

	back_menu_button.disabled = true
	credit_button.disabled = true

	# Fade only the buttons out
	var tween: Tween = create_tween()

	tween.tween_property(
		menu,
		"modulate:a",
		0.0,
		fade_out_time
	)

	await tween.finished

	get_tree().change_scene_to_file(START_SCENE_PATH)


func _on_credit() -> void:
	print("Credits pressed")
