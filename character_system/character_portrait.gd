extends TextureRect

const HIGHLIGHT_SHADER : Shader = preload("res://character_system/highlight.gdshader")
const GROUP : StringName = &"character_portrait"
const DIM_GROUP : StringName = &"dimmable"

static var _active : TextureRect = null
static var _dim_tweens : Dictionary = {}
static var _alpha_masks : Dictionary = {}

@export var member_id : String = ""
@export var healthy_texture : Texture2D
@export var injured_texture : Texture2D
@export var critical_texture : Texture2D
@export var dead_modulate : Color = Color(0.35, 0.35, 0.35, 0.6)
@export_range(0.0, 1.0) var hover_strength : float = 0.3
@export_range(0.0, 1.0) var dim_strength : float = 0.5
@export var rise_time : float = 0.15
@export var fall_time : float = 0.35

var _tween : Tween = null
var _amount : float = 0.0


func _ready() -> void:
	add_to_group(GROUP)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var mat : ShaderMaterial = ShaderMaterial.new()
	mat.shader = HIGHLIGHT_SHADER
	material = mat
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	Crew.crew_changed.connect(_refresh)
	EffectSystem.effect_added.connect(func(_target_id, _effect): _refresh())
	EffectSystem.effect_removed.connect(func(_target_id, _effect): _refresh())
	_refresh()


func _refresh() -> void:
	var member : CrewMember = Crew.get_member(member_id)
	if member == null or member.status == CrewMember.Status.EXILED:
		visible = false
		return
	visible = true
	modulate = dead_modulate if member.status == CrewMember.Status.DEAD else Color.WHITE
	match Crew.get_health(member_id):
		CrewMember.Health.CRITICAL:
			texture = critical_texture
		CrewMember.Health.INJURED:
			texture = injured_texture
		_:
			texture = healthy_texture


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


func _on_mouse_entered() -> void:
	_active = self
	_tween_highlight(hover_strength, rise_time)
	for portrait in get_tree().get_nodes_in_group(GROUP):
		if portrait != self:
			portrait._tween_highlight(-portrait.dim_strength, rise_time)
	_dim_group(get_tree(), dim_strength, rise_time)


func _on_mouse_exited() -> void:
	if _active != self:
		return
	_active = null
	for portrait in get_tree().get_nodes_in_group(GROUP):
		portrait._tween_highlight(0.0, portrait.fall_time)
	_dim_group(get_tree(), 0.0, fall_time)


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
