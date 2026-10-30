shader_type canvas_item;
// The hokora's colours (Home Decor > Colours: HokoraCatalog "colour" items) and a lantern's
// placeholder recolour. Each pixel's material is told by its hue, as painted: the roof tiles
// terracotta (hue under ~19 degrees), the wood and roots tan, the moss green; the dark outline and
// near-greys are left alone. Each material's [hue shift (turns), saturation x, value x]. With
// `classify` off one set (wood) moves every pixel (a lantern). The sprite's own modulate still
// applies (the sides' shades, the night tint).
uniform bool classify = true;
uniform vec3 wood = vec3(0.0, 1.0, 1.0);
uniform vec3 roof = vec3(0.0, 1.0, 1.0);
uniform vec3 moss = vec3(0.0, 1.0, 1.0);
// (root planes: their faint edge pixels dropped, as their own shader did)
uniform bool cut_alpha = false;
// The stone base under the slab is painted in the front's picture with the wood's pale beige: its
// pale pixels inside this box (UV: x0, y0, x1, y1) keep their colour
uniform vec4 stone_box = vec4(2.0, 2.0, 2.0, 2.0);

varying vec4 tint;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (cut_alpha && tex.a < 0.5) {
		discard;
	}
	vec3 hsv = rgb2hsv(tex.rgb);
	bool stone = hsv.y < 0.4 && UV.x > stone_box.x && UV.y > stone_box.y && UV.x < stone_box.z && UV.y < stone_box.w;
	if (hsv.z > 0.22 && hsv.y > 0.08 && !stone) {
		vec3 t = wood;
		if (classify) {
			float h = hsv.x * 360.0;
			if (h >= 45.0 && h < 170.0) {
				t = moss;
			} else if (hsv.y > 0.35 && (h < 19.0 || h >= 330.0)) {
				t = roof;
			}
		}
		hsv.x = fract(hsv.x + t.x + 1.0);
		hsv.y = clamp(hsv.y * t.y, 0.0, 1.0);
		hsv.z = clamp(hsv.z * t.z, 0.0, 1.0);
		tex.rgb = hsv2rgb(hsv);
	}
	COLOR = (cut_alpha ? vec4(tex.rgb, 1.0) : tex) * tint;
}
