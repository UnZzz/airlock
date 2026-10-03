class_name CharacterPortrait
extends TextureRect

signal clicked(member_id: String)

const HIGHLIGHT_SHADER : Shader = preload("res://character_system/highlight.gdshader")
const SICK_PARTICLES : PackedScene = preload("res://character_system/SickParticles.tscn")
const GROUP : StringName = &"character_portrait"
const DIM_GROUP : StringName = &"dimmable"

static var interaction_enabled : bool = true
static var _active : TextureRect = null
static var _dim_tweens : Dictionary = {}
static var _alpha_masks : Dictionary = {}

@export var member_id : String = ""
@export var healthy_texture : Texture2D
@export var injured_texture : Texture2D
@export var critical_texture : Texture2D
@export var dead_modulate : Color = Color(0.35, 0.35, 0.35, 0.6)
@export var sick_tint : Color = Color(0.6565805, 0.85915035, 0.6579475, 1)
@export var sick_particles_anchor : Vector2 = Vector2(0.5, 0.35)
@export_range(0.0, 1.0) var hover_strength : float = 0.3
@export_range(0.0, 1.0) var dim_strength : float = 0.5
@export var rise_time : float = 0.15
@export var fall_time : float = 0.35
@export var name_font_size : int = 24
@export var name_gap : float = 6.0

var _tween : Tween = null
var _amount : float = 0.0
var _name_label : Label = null
var _name_tween : Tween = null
var _sick_particles : GPUParticles2D = null


func _ready() -> void:
	add_to_group(GROUP)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var mat : ShaderMaterial = ShaderMaterial.new()
	mat.shader = HIGHLIGHT_SHADER
	material = mat
	_build_name_label()
	_sick_particles = SICK_PARTICLES.instantiate()
	_sick_particles.emitting = false
	add_child(_sick_particles)
	resized.connect(_place_sick_particles)
	_place_sick_particles()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	Crew.crew_changed.connect(_refresh)
	EffectSystem.effect_added.connect(func(_target_id, _effect): _refresh())
	EffectSystem.effect_removed.connect(func(_target_id, _effect): _refresh())
	_refresh()


func get_member() -> CrewMember:
	return Crew.get_member(member_id)


func _refresh() -> void:
	var member : CrewMember = get_member()
	if member == null or member.status == CrewMember.Status.EXILED:
		visible = false
		return
	visible = true
	modulate = dead_modulate if member.status == CrewMember.Status.DEAD else Color.WHITE
	var sick : bool = Crew.is_sick(member_id)
	self_modulate = sick_tint if sick else Color.WHITE
	if _sick_particles.emitting != sick:
		_sick_particles.emitting = sick
	_name_label.text = member.short_name if member.short_name != "" else member.display_name
	match Crew.get_health(member_id):
		CrewMember.Health.CRITICAL:
			texture = critical_texture
		CrewMember.Health.INJURED:
			texture = injured_texture
		_:
			texture = healthy_texture


func _place_sick_particles() -> void:
	_sick_particles.position = size * sick_particles_anchor


func _build_name_label() -> void:
	_name_label = Label.new()
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", name_font_size)
	_name_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.85))
	_name_label.add_theme_color_override("font_outline_color", Color(0.03, 0.03, 0.04))
	_name_label.add_theme_constant_override("outline_size", 8)
	_name_label.modulate.a = 0.0
	add_child(_name_label)


func _place_name_label() -> void:
	if texture == null:
		return
	var tex_size : Vector2 = texture.get_size()
	var fit : float = minf(size.x / tex_size.x, size.y / tex_size.y)
	var top : float = (size.y - tex_size.y * fit) * 0.5
	var label_size : Vector2 = _name_label.get_combined_minimum_size()
	_name_label.size = label_size
	_name_label.position = Vector2((size.x - label_size.x) * 0.5, top - label_size.y - name_gap)


func _show_name(shown: bool, duration: float) -> void:
	if shown:
		_place_name_label()
	if _name_tween != null and _name_tween.is_running():
		_name_tween.kill()
	_name_tween = create_tween()
	_name_tween.tween_property(_name_label, "modulate:a", 1.0 if shown else 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _has_point(point: Vector2) -> bool:
	if texture == null:
		return false
	var tex_size : Vector2 = texture.get_size()
	var fit : float = minf(size.x / tex_size.x, size.y / tex_size.y)
	if fit <= 0.0:
		return false
	var origin : Vector2 = (size - tex_size * fit) * 0.5
	var pixel : Vector2i = Vector2i((point - origin) / fit)
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= int(tex_size.x) or pixel.y >= int(tex_size.y):
		return false
	return _get_alpha_mask(texture).get_bitv(pixel)


static func _get_alpha_mask(tex: Texture2D) -> BitMap:
	if not _alpha_masks.has(tex):
		var mask : BitMap = BitMap.new()
		mask.create_from_image_alpha(tex.get_image(), 0.5)
		_alpha_masks[tex] = mask
	return _alpha_masks[tex]


func _gui_input(event: InputEvent) -> void:
	if not interaction_enabled:
		return
	var mb : InputEventMouseButton = event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
		accept_event()
		clicked.emit(member_id)


func _on_mouse_entered() -> void:
	if not interaction_enabled:
		return
	_active = self
	focus(get_tree(), self, dim_strength)
	_show_name(true, rise_time)


func _on_mouse_exited() -> void:
	if _active != self:
		return
	_active = null
	_show_name(false, fall_time)
	if interaction_enabled:
		clear_focus(get_tree())


static func focus(tree: SceneTree, target: TextureRect, background_dim: float) -> void:
	for portrait in tree.get_nodes_in_group(GROUP):
		if portrait == target:
			portrait._tween_highlight(portrait.hover_strength, portrait.rise_time)
		else:
			portrait._tween_highlight(-portrait.dim_strength, portrait.rise_time)
	_dim_group(tree, background_dim, target.rise_time if target != null else 0.15)


static func clear_focus(tree: SceneTree) -> void:
	for portrait in tree.get_nodes_in_group(GROUP):
		portrait._tween_highlight(0.0, portrait.fall_time)
	_dim_group(tree, 0.0, 0.35)


static func hide_names(tree: SceneTree) -> void:
	_active = null
	for portrait in tree.get_nodes_in_group(GROUP):
		portrait._show_name(false, portrait.fall_time)


static func _dim_group(tree: SceneTree, amount: float, duration: float) -> void:
	var value : float = 1.0 - amount
	for node in tree.get_nodes_in_group(DIM_GROUP):
		var prev : Tween = _dim_tweens.get(node)
		if prev != null and prev.is_running():
			prev.kill()
		var tween : Tween = node.create_tween()
		tween.tween_property(node, "modulate", Color(value, value, value, node.modulate.a), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_dim_tweens[node] = tween


func _tween_highlight(amount: float, duration: float) -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_apply_amount, _amount, amount, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _apply_amount(value: float) -> void:
	_amount = value
	(material as ShaderMaterial).set_shader_parameter(&"highlight_amount", value)
