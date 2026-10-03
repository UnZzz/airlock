extends Control

signal finished
signal _advanced
signal _picked(index: int)

const DIALOGUE_PATH : String = "res://story/dialogue_en.json"

@export var text_color : Color = Color(0.9, 0.88, 0.85)
@export var option_color : Color = Color(0.6, 0.58, 0.56)
@export var option_lit_color : Color = Color.WHITE
@export var box_color : Color = Color(0.03, 0.03, 0.04, 0.88)
@export var border_color : Color = Color(0.86, 0.85, 0.79, 0.85)
@export var background_dim : float = 0.55
@export var margin : float = 20.0
@export var box_height : float = 190.0
@export var type_cps : float = 40.0
@export var pause_long : float = 0.22
@export var pause_short : float = 0.08
@export var fade_time : float = 0.2

var dialogues : Dictionary = {}
var is_open : bool = false
var _box : PanelContainer = null
var _name_tag : Label = null
var _text : Label = null
var _options : VBoxContainer = null
var _typing : bool = false
var _skip_typing : bool = false
var _choosing : bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	modulate.a = 0.0
	dialogues = _load_json(DIALOGUE_PATH)
	_build()


func has_dialogue(member_id: String) -> bool:
	return dialogues.has(member_id)


func talk(portrait: CharacterPortrait) -> void:
	if is_open or portrait == null:
		return
	var data : Dictionary = dialogues.get(portrait.member_id, {})
	if data.is_empty() or not portrait.can_talk():
		return
	is_open = true
	CharacterPortrait.interaction_enabled = false
	CharacterPortrait.hide_names(get_tree())
	CharacterPortrait.focus(get_tree(), portrait, background_dim)
	_name_tag.text = portrait.get_display_name()
	_text.text = ""
	_clear_options()
	visible = true
	var fade : Tween = create_tween()
	fade.tween_property(self, "modulate:a", 1.0, fade_time)
	var lines : Array = data.get("lines", [])
	var options : Array = data.get("options", [])
	for i in lines.size():
		await _type(String(lines[i]))
		if i < lines.size() - 1 or options.is_empty():
			await _advanced
	if not options.is_empty():
		var labels : Array[String] = []
		for option in options:
			labels.append(String(option.get("text", "")))
		var pick : int = await _ask(labels)
		for line in options[pick].get("reply", []):
			await _type(String(line))
			await _advanced
	await _close()


func _close() -> void:
	var fade : Tween = create_tween()
	fade.tween_property(self, "modulate:a", 0.0, fade_time)
	await fade.finished
	visible = false
	is_open = false
	CharacterPortrait.interaction_enabled = true
	CharacterPortrait.clear_focus(get_tree())
	finished.emit()


func _type(line: String) -> void:
	_clear_options()
	_text.text = line
	_text.visible_characters = 0
	_typing = true
	_skip_typing = false
	var count : int = line.length()
	for i in count:
		if _skip_typing:
			break
		_text.visible_characters = i + 1
		await get_tree().create_timer(1.0 / type_cps + _pause_after(line, i)).timeout
	_text.visible_characters = -1
	_typing = false


func _pause_after(line: String, i: int) -> float:
	if i >= line.length() - 1:
		return 0.0
	var c : String = line[i]
	if ".!?".contains(c) and line[i + 1] == " ":
		return pause_long
	if ",;:".contains(c):
		return pause_short
	return 0.0


func _ask(labels: Array[String]) -> int:
	_choosing = true
	_clear_options()
	for i in labels.size():
		var button : Button = Button.new()
		button.text = "  " + labels[i]
		button.flat = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_color_override("font_color", option_color)
		button.add_theme_color_override("font_hover_color", option_lit_color)
		button.add_theme_color_override("font_pressed_color", option_lit_color)
		button.mouse_entered.connect(func(): button.text = "> " + labels[i])
		button.mouse_exited.connect(func(): button.text = "  " + labels[i])
		button.pressed.connect(func(): _picked.emit(i))
		_options.add_child(button)
	var pick : int = await _picked
	_choosing = false
	_clear_options()
	return pick


func _clear_options() -> void:
	for child in _options.get_children():
		_options.remove_child(child)
		child.queue_free()


func _gui_input(event: InputEvent) -> void:
	var mb : InputEventMouseButton = event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
		accept_event()
		_press()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_press()


func _press() -> void:
	if not is_open or _choosing:
		return
	if _typing:
		_skip_typing = true
	else:
		_advanced.emit()


func _build() -> void:
	_box = PanelContainer.new()
	_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_box.offset_left = margin
	_box.offset_right = -margin
	_box.offset_bottom = -margin
	_box.offset_top = -margin - box_height
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style : SketchBox = SketchBox.new()
	style.fill_color = box_color
	style.line_color = border_color
	style.salt = 7
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 18.0
	_box.add_theme_stylebox_override("panel", style)
	add_child(_box)
	var column : VBoxContainer = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 8)
	_box.add_child(column)
	_name_tag = Label.new()
	_name_tag.add_theme_color_override("font_color", option_lit_color)
	column.add_child(_name_tag)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_color_override("font_color", text_color)
	column.add_child(_text)
	_options = VBoxContainer.new()
	_options.add_theme_constant_override("separation", 0)
	column.add_child(_options)


func _load_json(path: String) -> Dictionary:
	var file : FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed : Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
