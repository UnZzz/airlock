extends Control

const START_SCENE_PATH: String = "res://start/StartScreen.tscn"
const GAME_SCENE_PATH: String = "res://main.tscn"

@export var fade_in_time: float = 1.2
@export var fade_out_time: float = 0.8
@export var menu_delay: float = 2.0
@export var max_story_height: float = 380.0

@onready var menu = $Menu
@onready var back_menu_button = $Menu/BackMenuButton
@onready var credit_button = $Menu/CreditButton
@onready var restart_button = $Menu/RestartButton
@onready var story_panel = $StoryPanel
@onready var story_title = $StoryPanel/Box/Title
@onready var story_text = $StoryPanel/Box/Text
@onready var continue_button = $StoryPanel/Box/ContinueButton
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

	back_menu_button.text = Journal.text("ui_return_menu")
	credit_button.text = Journal.text("ui_credits")
	restart_button.text = Journal.text("ui_restart")
	story_title.text = Journal.text("ending_title")
	story_text.text = GameFlow.get_ending_text()
	continue_button.text = Journal.text("ui_continue")

	back_menu_button.pressed.connect(_on_back_menu)
	credit_button.pressed.connect(_on_credit)
	restart_button.pressed.connect(_on_restart)
	continue_button.pressed.connect(_on_continue)

	# Only hide the buttons/menu.
	# Background stays visible.
	menu.modulate.a = 0.0
	menu.hide()
	continue_button.grab_focus()
	story_text.resized.connect(_fit_story)
	_fit_story()


func _fit_story() -> void:
	var height: float = minf(story_text.get_content_height(), max_story_height)
	if not is_equal_approx(story_text.custom_minimum_size.y, height):
		story_text.custom_minimum_size.y = height


func _on_continue() -> void:
	continue_button.disabled = true
	var story_tween: Tween = create_tween()
	story_tween.tween_property(story_panel, "modulate:a", 0.0, fade_out_time)
	await story_tween.finished
	story_panel.hide()
	menu.show()

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


func _refresh_characters() -> void:
	remaining_character_count = 0
	var survived: bool = GameFlow.ending_id == "survived"
	dim.visible = not survived
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
	print("Credits pressed")
