shader_type canvas_item;

uniform float highlight_amount : hint_range(-1.0, 1.0) = 0.0;

void fragment() {
	COLOR.rgb = min(COLOR.rgb * (1.0 + highlight_amount), vec3(0.99));
}
