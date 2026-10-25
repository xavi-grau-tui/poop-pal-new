shader_type canvas_item;
// The shrine's ground (scripts/shrine.gd): a plane for the 3D tilt. Each row of it moves by its own
// depth, all behind the shrine (like its back, the horizon further), so seen from below the horizon
// drops and the base's sides show down to their lower edge, standing on it. tilt: the shrine's (-1..1); size_px: the
// sprite's size on screen; depths in px per full tilt (as shrine.gd's FRONT / BACK).
uniform vec2 tilt = vec2(0.0);
uniform vec2 size_px = vec2(925.0, 924.0);
uniform float y_far = 0.836;    // (grid 92 / 110: the horizon)
uniform float y_near = 0.945;   // (grid 104)
uniform float far_d = -72.0;
uniform float near_d = -52.0;

void fragment() {
	float d = mix(far_d, near_d, clamp((UV.y - y_far) / (y_near - y_far), 0.0, 1.0));
	vec2 uv = UV - tilt * d / size_px;
	uv.x = clamp(uv.x, 0.0005, 0.9995);    // (past its sides the ground just goes on)
	vec4 c = texture(TEXTURE, uv);
	if (uv.y > 1.0)
		c = texture(TEXTURE, vec2(uv.x, 0.9995));    // (below its bottom the ground goes on too)
	if (uv.y < 0.0)
		c = vec4(0.0);
	COLOR = c * COLOR;
}
