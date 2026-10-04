extends Control

const GAME_SCENE_PATH : String = "res://main.tscn"

@export var fade_in_time : float = 1.2
@export var fade_out_time : float = 0.8

@onready var background : TextureRect = $Background
@onready var sky : Node2D = $Background/Sky
@onready var title_label : Label = $Menu/TitleLabel
@onready var start_button : Button = $Menu/StartButton
@onready var language_button : Button = $Menu/LanguageButton
@onready var quit_button : Button = $Menu/QuitButton
@onready var fade : ColorRect = $Fade
@onready var hover_sfx: AudioStreamPlayer2D = $HoverSFX

var leaving : bool = false


func _ready() -> void:
	_refresh_text()
	start_button.pressed.connect(_on_start)
	language_button.pressed.connect(_on_language)
	quit_button.pressed.connect(_on_quit)
	quit_button.visible = not OS.has_feature("web")
	resized.connect(_fit_background)
	_fit_background()
	fade.color.a = 1.0
	create_tween().tween_property(fade, "color:a", 0.0, fade_in_time)
	start_button.grab_focus()
	Music.play_playlist()
	start_button.mouse_entered.connect(_on_button_hover)
	language_button.mouse_entered.connect(_on_button_hover)
	quit_button.mouse_entered.connect(_on_button_hover)


func _refresh_text() -> void:
	title_label.text = Journal.text("start_title")
	start_button.text = Journal.text("ui_start_game")
	language_button.text = Journal.text("ui_language")
	quit_button.text = Journal.text("ui_quit")


func _on_language() -> void:
	Journal.set_language(Journal.next_language())
	_refresh_text()


func _fit_background() -> void:
	var texture_size : Vector2 = background.texture.get_size()
	var fit : float = maxf(size.x / texture_size.x, size.y / texture_size.y)
	background.size = texture_size * fit
	background.position = Vector2((size.x - background.size.x) * 0.5, 0.0)
	sky.scale = Vector2.ONE * fit


func _on_start() -> void:
	if leaving:
		return
	leaving = true
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween : Tween = create_tween()
	tween.tween_property(fade, "color:a", 1.0, fade_out_time)
	tween.tween_callback(get_tree().change_scene_to_file.bind(GAME_SCENE_PATH))

func _on_button_hover() -> void:
	hover_sfx.play()

func _on_quit() -> void:
	get_tree().quit()
