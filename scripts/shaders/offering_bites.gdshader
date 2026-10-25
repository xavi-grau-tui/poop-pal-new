shader_type canvas_item;
// An offering on the shrine's tray being eaten (scripts/shrine.gd): bites taken out of it, each a
// couple of round cuts (on the picture's own pixels, so the edge stays pixel art), a dark rim
// along the cut like the food's outline

uniform vec2 px = vec2(32.0);        // the picture's size
uniform vec4 b0 = vec4(0.0);         // a cut: centre (uv), radius (uv), on (> 0.5)
uniform vec4 b1 = vec4(0.0);
uniform vec4 b2 = vec4(0.0);
uniform vec4 b3 = vec4(0.0);
uniform vec4 rim_color : source_color = vec4(0.30, 0.20, 0.19, 1.0);

float cut(vec2 uv, vec4 b) {
	return b.w > 0.5 ? distance(uv, b.xy) - b.z : 1.0;
}

void fragment() {
	vec2 uv = (floor(UV * px) + 0.5) / px;
	float d = min(min(cut(uv, b0), cut(uv, b1)), min(cut(uv, b2), cut(uv, b3)));
	if (d < 0.0) {
		COLOR.a = 0.0;
	} else if (d < 1.0 / px.x && COLOR.a > 0.5) {
		COLOR.rgb = rim_color.rgb;
	}
}
