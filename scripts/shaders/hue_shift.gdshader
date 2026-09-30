shader_type canvas_item;
// Recolours a sprite by rotating its hue (keeps shading, saturation and outlines).
// Used for the gut colours (Collection DECOR items of kind "color").
uniform float hue_shift = 0.0;   // fraction of the colour wheel, e.g. -0.18 = pink -> purple

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

// In a canvas_item fragment, COLOR already holds texture * modulate: shift that (reading
// TEXTURE again and multiplying by COLOR would apply the colour twice = darker)
void fragment() {
	vec4 c = COLOR;
	vec3 hsv = rgb2hsv(c.rgb);
	hsv.x = fract(hsv.x + hue_shift);
	COLOR = vec4(hsv2rgb(hsv), c.a);
}
