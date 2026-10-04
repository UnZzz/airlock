extends Control

const START_SCENE_PATH: String = "res://start/StartScreen.tscn"

@export var fade_in_time: float = 1.2
@export var fade_out_time: float = 0.8

@onready var background = $EndingBackground
@onready var menu = $Menu
@onready var back_menu_button = $Menu/BackMenuButton
@onready var credit_button = $Menu/CreditButton

var leaving: bool = false


func _ready() -> void:
	# Set text directly
	back_menu_button.text = "Back to menu"
	credit_button.text = "Credits"
	back_menu_button.custom_minimum_size = Vector2(250, 60)
	credit_button.custom_minimum_size = Vector2(250, 60)

	# Connect buttons
	back_menu_button.pressed.connect(_on_back_menu)
	credit_button.pressed.connect(_on_credit)

	# Start invisible
	menu.modulate.a = 0.0
	background.modulate.a = 0.0

	# Wait 2 seconds
	await get_tree().create_timer(2.0).timeout

	# Fade background and menu in together
	var tween: Tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		background,
		"modulate:a",
		1.0,
		fade_in_time
	)

	tween.tween_property(
		menu,
		"modulate:a",
		1.0,
		fade_in_time
	)


func _on_back_menu() -> void:
	if leaving:
		return

	leaving = true

	back_menu_button.disabled = true
	credit_button.disabled = true

	var tween: Tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		background,
		"modulate:a",
		0.0,
		fade_out_time
	)

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
