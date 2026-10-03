extends Control

const ROLE_COLORS : Dictionary = {
	CrewMember.Role.CAPTAIN: Color(0.36, 0.52, 0.78),
	CrewMember.Role.CRIMINAL: Color(0.72, 0.30, 0.28),
	CrewMember.Role.WORKER: Color(0.80, 0.62, 0.26),
	CrewMember.Role.DOCTOR: Color(0.40, 0.70, 0.56),
	CrewMember.Role.CHEF: Color(0.62, 0.46, 0.74),
}

@export var head_size : float = 56.0
@export var body_size : Vector2 = Vector2(84, 150)
@export var dead_modulate : Color = Color(0.35, 0.35, 0.35, 0.6)

@onready var row : HBoxContainer = $Row


func _ready() -> void:
	Crew.crew_changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	for member in Crew.members:
		if member.status == CrewMember.Status.EXILED:
			continue
		var figure : Control = _build_figure(member)
		if member.status == CrewMember.Status.DEAD:
			figure.modulate = dead_modulate
		row.add_child(figure)


func _build_figure(member: CrewMember) -> VBoxContainer:
	var color : Color = ROLE_COLORS.get(member.role, Color.GRAY)
	var figure : VBoxContainer = VBoxContainer.new()
	figure.name = member.member_id
	figure.alignment = BoxContainer.ALIGNMENT_END
	figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	figure.add_theme_constant_override("separation", 6)
	var head : Panel = _make_block(Vector2(head_size, head_size), color.lightened(0.15), int(head_size / 2.0))
	head.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	figure.add_child(head)
	var body : Panel = _make_block(body_size, color, 18)
	body.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	figure.add_child(body)
	var label : Label = Label.new()
	label.text = member.short_name if member.short_name != "" else member.display_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	figure.add_child(label)
	return figure


func _make_block(block_size: Vector2, color: Color, radius: int) -> Panel:
	var block : Panel = Panel.new()
	block.custom_minimum_size = block_size
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style : StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = color.darkened(0.45)
	style.set_border_width_all(3)
	block.add_theme_stylebox_override("panel", style)
	return block
