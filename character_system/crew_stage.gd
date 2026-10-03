extends Control

const PORTRAIT_PATH : String = "res://character/%s_%d.png"

@export var portrait_ids : Dictionary = {
	"mason": "1",
	"elias": "2",
	"mara": "3",
	"helena": "4",
}
@export var portrait_scale : float = 0.26
@export var dead_modulate : Color = Color(0.35, 0.35, 0.35, 0.6)

@onready var row : HBoxContainer = $Row


func _ready() -> void:
	Crew.crew_changed.connect(_rebuild)
	EffectSystem.effect_added.connect(func(_target_id, _effect): _rebuild())
	EffectSystem.effect_removed.connect(func(_target_id, _effect): _rebuild())
	_rebuild()


func _rebuild() -> void:
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	for member in Crew.members:
		if member.status == CrewMember.Status.EXILED:
			continue
		var texture : Texture2D = _get_portrait(member)
		if texture == null:
			continue
		var portrait : TextureRect = TextureRect.new()
		portrait.name = member.member_id
		portrait.texture = texture
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size = texture.get_size() * portrait_scale
		portrait.size_flags_vertical = Control.SIZE_SHRINK_END
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if member.status == CrewMember.Status.DEAD:
			portrait.modulate = dead_modulate
		row.add_child(portrait)


func _get_portrait(member: CrewMember) -> Texture2D:
	var id : String = portrait_ids.get(member.member_id, "")
	if id == "":
		return null
	var variants : Array[int] = [3, 2]
	match Crew.get_health(member.member_id):
		CrewMember.Health.CRITICAL:
			variants = [1, 2]
		CrewMember.Health.INJURED:
			variants = [2]
	for variant in variants:
		var path : String = PORTRAIT_PATH % [id, variant]
		if ResourceLoader.exists(path):
			return load(path)
	return null
