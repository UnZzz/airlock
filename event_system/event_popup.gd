class_name EventPopup
extends Control

@export var box_color : Color = Color(0.03, 0.03, 0.04, 0.92)
@export var border_color : Color = Color(0.86, 0.85, 0.79, 0.85)
@export var shade_color : Color = Color(0.0, 0.0, 0.0, 0.55)
@export var title_color : Color = Color.WHITE
@export var text_color : Color = Color(0.9, 0.88, 0.85)
@export var title_font_size : int = 26
@export var box_width : float = 760.0
@export var max_height_ratio : float = 0.82
@export var fade_time : float = 0.2

var is_open : bool = false
var _shade : ColorRect = null
var _box : PanelContainer = null
var _title : Label = null
var _scroll : ScrollContainer = null
var _text : RichTextLabel = null
var _options : VBoxContainer = null
var _fade : Tween = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	modulate.a = 0.0
	_build()


func open(title: String, text: String, buttons: Array[Dictionary]) -> void:
	_title.text = title
	_title.visible = title != ""
	_text.text = text
	_scroll.scroll_vertical = 0
	_clear_options()
	for data in buttons:
		var button : Button = Button.new()
		button.text = String(data.get("text", ""))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.disabled = bool(data.get("disabled", false))
		button.focus_mode = Control.FOCUS_NONE
		var callback : Callable = data.get("callback", Callable())
		if callback.is_valid():
			button.pressed.connect(callback)
		_options.add_child(button)
	if not is_open:
		is_open = true
		visible = true
		CharacterPortrait.interaction_enabled = false
		CharacterPortrait.hide_names(get_tree())
		CharacterPortrait.clear_focus(get_tree())
		_fade_to(1.0)
	_fit.call_deferred()


func close() -> void:
	if not is_open:
		return
	is_open = false
	_clear_options()
	CharacterPortrait.interaction_enabled = true
	_fade_to(0.0)
	await _fade.finished
	if not is_open:
		visible = false


func _fade_to(alpha: float) -> void:
	if _fade != null and _fade.is_running():
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(self, "modulate:a", alpha, fade_time)


func _fit() -> void:
	await get_tree().process_frame
	var width : float = minf(box_width, get_viewport_rect().size.x - 48.0)
	_box.custom_minimum_size.x = width
	var chrome : float = _box.size.y - _scroll.size.y
	var limit : float = get_viewport_rect().size.y * max_height_ratio - chrome
	_scroll.custom_minimum_size.y = clampf(_text.get_content_height(), 0.0, maxf(limit, 120.0))


func _clear_options() -> void:
	for child in _options.get_children():
		_options.remove_child(child)
		child.queue_free()


func _build() -> void:
	_shade = ColorRect.new()
	_shade.color = shade_color
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)
	var center : CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_box = PanelContainer.new()
	_box.custom_minimum_size.x = box_width
	var style : SketchBox = SketchBox.new()
	style.fill_color = box_color
	style.line_color = border_color
	style.tape = true
	style.salt = 11
	style.content_margin_left = 32.0
	style.content_margin_right = 32.0
	style.content_margin_top = 26.0
	style.content_margin_bottom = 24.0
	_box.add_theme_stylebox_override("panel", style)
	center.add_child(_box)
	var column : VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	_box.add_child(column)
	_title = Label.new()
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.add_theme_color_override("font_color", title_color)
	_title.add_theme_font_size_override("font_size", title_font_size)
	column.add_child(_title)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(_scroll)
	_text = RichTextLabel.new()
	_text.fit_content = true
	_text.scroll_active = false
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.add_theme_color_override("default_color", text_color)
	_scroll.add_child(_text)
	_options = VBoxContainer.new()
	_options.add_theme_constant_override("separation", 8)
	column.add_child(_options)
