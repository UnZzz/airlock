extends Control

const START_SCENE_PATH: String = "res://start/StartScreen.tscn"
const GAME_SCENE_PATH: String = "res://main.tscn"

@export var fade_out_time: float = 0.8

@onready var menu = $Menu
@onready var back_menu_button = $Menu/BackMenuButton
@onready var credit_button = $Menu/CreditButton
@onready var restart_button = $Menu/RestartButton
@onready var credits_panel = $CreditsPanel
@onready var credits_title = $CreditsPanel/Box/Title
@onready var credits_back_button = $CreditsPanel/Box/BackButton
@onready var dim: ColorRect = $"../Dim"
@onready var crew_portraits: Dictionary = {
	"mason": $"../TextureRect2",
	"captain": $"../TextureRect3",
	"mara": $"../TextureRect4",
	"helena": $"../TextureRect5",
	"elias": $"../TextureRect7",
}
@onready var guest_portrait: TextureRect = $"../TextureRect6"

var leaving: bool = false
var remaining_character_count: int = 0


func _ready() -> void:
	Crew.crew_changed.connect(_refresh_characters)
	EventManager.guest_changed.connect(func(_aboard: bool): _refresh_characters())
	_refresh_characters()

	Journal.language_changed.connect(_on_language_changed)
	_refresh_text()

	back_menu_button.pressed.connect(_on_back_menu)
	credit_button.pressed.connect(_on_credit)
	restart_button.pressed.connect(_on_restart)
	credits_back_button.pressed.connect(_on_credit_back)
	credits_panel.hide()
	dim.hide()
	menu.show()
	back_menu_button.grab_focus()


func _on_language_changed(_language: String) -> void:
	_refresh_text()


func _refresh_text() -> void:
	back_menu_button.text = Journal.text("ui_return_menu")
	credit_button.text = Journal.text("ui_credits")
	restart_button.text = Journal.text("ui_restart")
	credits_title.text = Journal.text("ui_credits")
	credits_back_button.text = Journal.text("ui_guide_back")


func _refresh_characters() -> void:
	remaining_character_count = 0
	var survived: bool = GameFlow.ending_id == "survived"

	for member_id in crew_portraits:
		var member: CrewMember = Crew.get_member(member_id)
		var portrait: TextureRect = crew_portraits[member_id]
		portrait.visible = survived and member != null and member.is_on_board()
		if portrait.visible:
			remaining_character_count += 1
	guest_portrait.visible = survived and EventManager.guest_aboard
	if guest_portrait.visible:
		remaining_character_count += 1


func _on_back_menu() -> void:
	_leave(START_SCENE_PATH)


func _on_restart() -> void:
	_leave(GAME_SCENE_PATH)


func _leave(scene_path: String) -> void:
	if leaving:
		return

	leaving = true

	back_menu_button.disabled = true
	credit_button.disabled = true
	restart_button.disabled = true

	# Fade only the buttons out
	var tween: Tween = create_tween()

	tween.tween_property(
		menu,
		"modulate:a",
		0.0,
		fade_out_time
	)

	await tween.finished

	get_tree().change_scene_to_file(scene_path)


func _on_credit() -> void:
	if leaving:
		return
	menu.hide()
	dim.show()
	credits_panel.show()
	credits_back_button.grab_focus()


func _on_credit_back() -> void:
	credits_panel.hide()
	dim.hide()
	menu.show()
	credit_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if credits_panel.visible and event.is_action_pressed("ui_cancel"):
		_on_credit_back()
		get_viewport().set_input_as_handled()
