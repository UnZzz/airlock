@tool
class_name SketchBox
extends StyleBox

@export var fill_color : Color = Color(0.14, 0.13, 0.2, 0.86):
	set(value):
		fill_color = value
		emit_changed()
@export var line_color : Color = Color(0.86, 0.85, 0.79, 0.95):
	set(value):
		line_color = value
		emit_changed()
@export var shade_color : Color = Color(0.27, 0.33, 0.33, 0.9):
	set(value):
		shade_color = value
		emit_changed()
@export var line_width : float = 3.0:
	set(value):
		line_width = value
		emit_changed()
@export var wobble : float = 2.4:
	set(value):
		wobble = value
		emit_changed()
@export var overshoot : float = 6.0:
	set(value):
		overshoot = value
		emit_changed()
@export var step : float = 36.0:
	set(value):
		step = value
		emit_changed()
@export var tape : bool = false:
	set(value):
		tape = value
		emit_changed()
@export var tape_color : Color = Color(0.87, 0.78, 0.8, 0.75):
	set(value):
		tape_color = value
		emit_changed()
@export var salt : int = 0:
	set(value):
		salt = value
		emit_changed()


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var rng : RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(rect.size)) + salt
	var corners : Array[Vector2] = [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	]
	for i in corners.size():
		corners[i] += Vector2(rng.randf_range(-wobble, wobble), rng.randf_range(-wobble, wobble)) * 1.5
	var outline : PackedVector2Array = PackedVector2Array()
	for i in corners.size():
		var a : Vector2 = corners[i]
		var b : Vector2 = corners[(i + 1) % corners.size()]
		var pieces : int = maxi(1, int(a.distance_to(b) / step))
		var normal : Vector2 = (b - a).orthogonal().normalized()
		for j in pieces:
			var t : float = float(j) / pieces
			var push : float = 0.0 if j == 0 else rng.randf_range(-wobble, wobble)
			outline.append(a.lerp(b, t) + normal * push)
	RenderingServer.canvas_item_add_polygon(to_canvas_item, outline, PackedColorArray([fill_color]))
	var shade_offset : Vector2 = Vector2(line_width, line_width) * 0.9
	for i in corners.size():
		_stroke(to_canvas_item, rng, corners[i] + shade_offset, corners[(i + 1) % corners.size()] + shade_offset, shade_color, line_width * 0.8)
	for i in corners.size():
		_stroke(to_canvas_item, rng, corners[i], corners[(i + 1) % corners.size()], line_color, line_width)
	var ghost : Color = Color(line_color, line_color.a * 0.45)
	for i in corners.size():
		_stroke(to_canvas_item, rng, corners[i], corners[(i + 1) % corners.size()], ghost, line_width * 0.5)
	if tape:
		_tape(to_canvas_item, rng, corners[0].lerp(corners[1], rng.randf_range(0.42, 0.58)))


func _stroke(item: RID, rng: RandomNumberGenerator, a: Vector2, b: Vector2, color: Color, width: float) -> void:
	var direction : Vector2 = (b - a).normalized()
	var normal : Vector2 = direction.orthogonal()
	var start : Vector2 = a - direction * rng.randf_range(0.0, overshoot)
	var end : Vector2 = b + direction * rng.randf_range(0.0, overshoot)
	var pieces : int = maxi(2, int(start.distance_to(end) / step))
	var points : PackedVector2Array = PackedVector2Array()
	for j in pieces + 1:
		var t : float = float(j) / pieces
		points.append(start.lerp(end, t) + normal * rng.randf_range(-wobble, wobble) * 0.6)
	RenderingServer.canvas_item_add_polyline(item, points, PackedColorArray([color]), width, true)


func _tape(item: RID, rng: RandomNumberGenerator, at: Vector2) -> void:
	var angle : float = deg_to_rad(rng.randf_range(-6.0, 6.0))
	var along : Vector2 = Vector2.RIGHT.rotated(angle)
	var across : Vector2 = along.orthogonal()
	var half_length : float = rng.randf_range(34.0, 44.0)
	var half_width : float = 9.0
	var points : PackedVector2Array = PackedVector2Array([
		at - along * half_length - across * half_width,
		at + along * half_length - across * half_width,
		at + along * half_length + across * half_width,
		at - along * half_length + across * half_width,
	])
	RenderingServer.canvas_item_add_polygon(item, points, PackedColorArray([tape_color]))
