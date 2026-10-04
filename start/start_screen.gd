extends Control

const GAME_SCENE_PATH : String = "res://main.tscn"

@export var fade_in_time : float = 1.2
@export var fade_out_time : float = 0.8

@onready var background : TextureRect = $Background
@onready var sky : Node2D = $Background/Sky
@onready var title_label : Label = $Menu/TitleLabel
@onready var start_button : Button = $Menu/StartButton
@onready var guide_button : Button = $Menu/GuideButton
@onready var language_button : Button = $Menu/LanguageButton
@onready var quit_button : Button = $Menu/QuitButton
@onready var fade : ColorRect = $Fade
@onready var hover_sfx: AudioStreamPlayer2D = $HoverSFX
@onready var menu : Control = $Menu
@onready var guide_panel : Control = $GuidePanel
@onready var guide_title : Label = $GuidePanel/GuideBox/GuideTitle
@onready var guide_text : RichTextLabel = $GuidePanel/GuideBox/GuideText
@onready var back_button : Button = $GuidePanel/GuideBox/BackButton

var leaving : bool = false


func _ready() -> void:
	_refresh_text()

	start_button.pressed.connect(_on_start)
	guide_button.pressed.connect(_on_guide)
	language_button.pressed.connect(_on_language)
	quit_button.pressed.connect(_on_quit)

	guide_panel.visible = false

	back_button.pressed.connect(_on_guide_back)

	start_button.mouse_entered.connect(_on_button_hover)
	guide_button.mouse_entered.connect(_on_button_hover)
	language_button.mouse_entered.connect(_on_button_hover)
	quit_button.mouse_entered.connect(_on_button_hover)
	back_button.mouse_entered.connect(_on_button_hover)

	quit_button.visible = not OS.has_feature("web")

	resized.connect(_fit_background)
	_fit_background()

	fade.color.a = 1.0
	create_tween().tween_property(fade, "color:a", 0.0, fade_in_time)

	start_button.grab_focus()

	Music.play_playlist()


func _refresh_text() -> void:
	title_label.text = Journal.text("start_title")
	start_button.text = Journal.text("ui_start_game")
	guide_button.text = Journal.text("ui_guide")
	language_button.text = Journal.text("ui_language")
	quit_button.text = Journal.text("ui_quit")
	guide_title.text = Journal.text("ui_guide")
	guide_text.text = Journal.text("ui_guide_text")
	back_button.text = Journal.text("ui_guide_back")

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
	
func _on_guide() -> void:
	menu.visible = false
	guide_panel.visible = true
	back_button.grab_focus()
	
func _on_guide_back() -> void:
	guide_panel.visible = false
	menu.visible = true
	guide_button.grab_focus()

func _on_button_hover() -> void:
	hover_sfx.play()

func _on_quit() -> void:
	get_tree().quit()
