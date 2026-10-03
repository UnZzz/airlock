extends TextureRect

@export var member_id : String = ""
@export var healthy_texture : Texture2D
@export var injured_texture : Texture2D
@export var critical_texture : Texture2D
@export var dead_modulate : Color = Color(0.35, 0.35, 0.35, 0.6)


func _ready() -> void:
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
