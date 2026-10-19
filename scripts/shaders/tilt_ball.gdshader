shader_type canvas_item;
// Tilt Maze's ball (scripts/tilt_maze.gd): the pal curled into a ball (PalBall's art, a 24 px canvas
// holding a 16 px ball), rolling for real: its art is wrapped on the front half of a sphere turned by
// `roll`, so the face rolls away the way it goes and comes back round over the top (its back: the
// body's colour); the light stays put, from the top-left (bands, a shine, a bounce of light along
// the lower right rim, the outline), on the art's own pixels (whole texels, nearest). What sticks
// out of the ball (ears, leaves, wrappers) shows while it rests face up (`extras`), tucked in when
// it rolls.

uniform mat3 roll = mat3(1.0);                       // the ball's turn: its body -> what you see
uniform vec4 back_col : source_color = vec4(0.8, 0.5, 0.3, 1.0);
uniform vec4 ink : source_color = vec4(0.25, 0.12, 0.06, 1.0);
uniform float art = 24.0;                            // the canvas (texels)
uniform float rad = 8.0;                             // the ball's radius (texels)
uniform float extras = 1.0;

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec2 px = floor(UV * art) + 0.5;
	vec2 p = (px - art * 0.5) / rad;
	float d = length(p);
	vec4 col;
	if (d > 1.0) {
		col = texture(TEXTURE, px / art);
		col.a *= extras;
	} else if (d > (rad - 1.0) / rad) {
		col = ink;
	} else {
		vec3 n = vec3(p, sqrt(max(0.0, 1.0 - d * d)));
		vec3 b = transpose(roll) * n;
		vec3 c = back_col.rgb;
		// (the art's own outline ring is left out: squeezed at the edge it would be a dark smear)
		vec2 tq = b.xy * rad;
		if (b.z > 0.0 && length(floor(tq + art * 0.5) + 0.5 - art * 0.5) < rad - 1.0) {
			vec4 t = texture(TEXTURE, (floor(tq + art * 0.5) + 0.5) / art);
			if (t.a > 0.5) {
				c = t.rgb;
			}
		}
		// the light, from the top-left in front
		vec3 L = normalize(vec3(-0.55, -0.65, 0.75));
		float dif = dot(n, L);
		if (dif > 0.975) {
			c = mix(c, vec3(1.0), 0.8);
		} else if (dif > 0.8) {
			c = c * 1.14 + 0.04;
		} else if (dif < 0.12) {
			c = c * 0.6;
			if (d > 0.62 && p.x + p.y > 0.7) {
				c = mix(c, back_col.rgb * 1.05, 0.45);      // the bounce along the lower right rim
			}
		} else if (dif < 0.42) {
			c = c * 0.8;
		}
		col = vec4(c, 1.0);
	}
	COLOR = col * tint;
}
