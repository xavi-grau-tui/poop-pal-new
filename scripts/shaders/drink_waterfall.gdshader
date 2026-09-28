shader_type canvas_item;

uniform float speed = 0.3;

void fragment() {
	vec2 uv = UV;
	uv.y = fract((uv.y * 3.0) - TIME * speed); // Tile 3x vertically and scroll
	COLOR = texture(TEXTURE, uv); // Keep original RGB + alpha
}