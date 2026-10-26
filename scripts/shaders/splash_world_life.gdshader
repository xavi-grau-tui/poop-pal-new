shader_type canvas_item;
// Splash Hoops' back panel, alive (the user, 2026-10-26: the backgrounds should move, each world in its
// own way, keeping its look). What moves comes from the world's life map (tools/art/splash_life_maps.py:
// R how far up its plant, G the floor's caustic lines, B plant / glowing speck) and the world's settings
// (SplashHoops.WORLD_LIFE). Everything on the art's own pixel grid and stepped like hand animation
// (STEP_FPS), so it stays pixel art: plants swaying from their bases, the caustics rippling with a glint
// running along them, the sun's (or moon's) shafts drifting and breathing, light rippling over the water,
// the surface line waving, the sun's reflection glittering, specks twinkling, the storm's lightning.

const float STEP_FPS = 8.0;
uniform sampler2D life : filter_nearest;
uniform float sway = 2.0;                    // the plants' tips' swing, art px
uniform float wobble = 1.2;                  // the caustics' ripple, art px
uniform float glint = 0.14;
uniform vec2 ray_apex = vec2(180.0, 0.0);    // where the shafts fan out from (panel px)
uniform vec2 ray_rows = vec2(56.0, 200.0);   // they start at the first row and are gone by the second
uniform float ray_spread = 0.6;              // the fan's half-angle (radians from straight down)
uniform float rays = 0.0;                    // their brightening per step (0: none)
uniform vec3 ray_col : source_color = vec3(0.96, 1.0, 0.86);
uniform vec2 ripple_rows = vec2(0.0, 0.0);   // the water's light ripple, between these rows
uniform float ripple = 0.0;
uniform vec2 surface_rows = vec2(0.0, 0.0);  // the surface line's rows: they wave sideways and glint
uniform vec4 glitter_rect = vec4(0.0);       // the sun's / moon's reflection: its bright pixels glitter
uniform float glitter = 0.0;
uniform float twinkle = 0.0;                 // the glowing specks' pulse
uniform float flash_every = 0.0;             // seconds between lightning flashes (0: none)

vec3 texel(sampler2D tex, vec2 px, vec2 size) {
	return texture(tex, (px + 0.5) / size).rgb;
}
vec4 lifeat(vec2 px, vec2 size) {
	return texture(life, (px + 0.5) / size);
}
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 px = floor(UV * size);
	float t = floor(TIME * STEP_FPS) / STEP_FPS;
	vec3 col = texel(TEXTURE, px, size);
	vec4 here = lifeat(px, size);
	bool plant_here = here.b > 0.75;

	// the surface line: its rows drawn from a pixel to the side (a slow wave), a glint running along
	if (px.y >= surface_rows.x && px.y < surface_rows.y) {
		float dx = floor(sin(px.y * 0.9 + t * 2.2 + px.x * 0.04) + 0.5);
		col = texel(TEXTURE, px - vec2(dx, 0.0), size);
		if (sin(px.x * 0.21 - t * 2.6 + px.y * 0.5) > 0.93) {
			col = mix(col, vec3(1.0, 0.98, 0.9), 0.3);
		}
	}

	// the plants: each pixel drawn from where its plant has swung from (more towards its tip); the
	// gap a leaf leaves filled from beside it
	if (here.r > 0.0 && sway > 0.0) {
		float up = here.r;
		float dx = floor(sin(t * 1.7 + floor(px.x / 24.0) * 1.9 - px.y * 0.09) * sway * up * up + 0.5);
		vec2 from = px - vec2(dx, 0.0);
		if (lifeat(from, size).b > 0.75) {
			col = texel(TEXTURE, from, size);
		} else if (plant_here) {
			float s = dx >= 0.0 ? 1.0 : -1.0;
			for (float k = 1.0; k <= 3.0; k += 1.0) {
				if (lifeat(px + vec2(k * s, 0.0), size).b < 0.75) { col = texel(TEXTURE, px + vec2(k * s, 0.0), size); break; }
				if (lifeat(px - vec2(k * s, 0.0), size).b < 0.75) { col = texel(TEXTURE, px - vec2(k * s, 0.0), size); break; }
			}
		}
	}

	// the caustics on the floor: each light line drawn from a pixel or so away, a glint along them
	if (!plant_here && wobble > 0.0) {
		vec2 w = vec2(floor(sin(px.y * 0.23 + t * 1.4) * wobble + 0.5), floor(sin(px.x * 0.19 - t * 1.1) * wobble + 0.5));
		bool line_from = lifeat(px - w, size).g > 0.5;
		if (line_from) {
			col = texel(TEXTURE, px - w, size);
			float g = 0.5 + 0.5 * sin(dot(px, vec2(0.11, 0.17)) - t * 1.8);
			col = mix(col, vec3(1.0, 1.0, 0.88), g > 0.75 ? glint : 0.0);
		} else if (here.g > 0.5) {
			vec2 o = w == vec2(0.0) ? vec2(1.0, 0.0) : w;
			col = lifeat(px + o, size).g > 0.5 ? texel(TEXTURE, px + vec2(o.y, -o.x), size) : texel(TEXTURE, px + o, size);
		}
	}

	// the water's light: two slow wavy fields crossing; where they peak a pixel lights up a step
	if (ripple > 0.0 && px.y >= ripple_rows.x && px.y < ripple_rows.y && !plant_here) {
		vec2 q = px * 0.5;
		float c = sin(q.x * 0.55 + sin(q.y * 0.42 + t * 0.9) * 1.6 + t * 0.7) + sin(q.y * 0.6 + sin(q.x * 0.37 - t * 0.8) * 1.6 - t * 0.6);
		float fade = 1.0 - smoothstep(ripple_rows.x, ripple_rows.y, px.y) * 0.75;
		float lift = c > 1.6 ? 2.0 : (c > 1.2 ? 1.0 : 0.0);
		col = mix(col, vec3(1.0, 1.0, 0.92), ripple * lift * fade);
	}

	// the reflection's glitter: its bright pixels catch the light at random, a few at a time
	if (glitter > 0.0 && px.x >= glitter_rect.x && px.x < glitter_rect.z && px.y >= glitter_rect.y && px.y < glitter_rect.w) {
		float lum = dot(col, vec3(0.3, 0.59, 0.11));
		float h = hash(px + floor(t * 3.0));
		if (lum > 0.55 && h > 0.82) {
			col = mix(col, vec3(1.0, 0.97, 0.85), glitter);
		} else if (lum > 0.55 && h < 0.12) {
			col *= 1.0 - glitter * 0.5;
		}
	}

	// the shafts: bands of light fanning out along the painted ones, drifting and breathing, fading
	// with depth and at the fan's sides; two steps, over everything they cross
	if (rays > 0.0 && px.y > ray_rows.x && px.y < ray_rows.y) {
		vec2 d = px - ray_apex;
		float a = atan(d.x, max(d.y, 0.001));
		if (abs(a) < ray_spread) {
			float bands = (0.5 + 0.5 * sin(a * 23.0 + t * 0.45)) * (0.5 + 0.5 * sin(a * 37.0 - t * 0.3 + 1.3));
			float breathe = 0.8 + 0.2 * sin(t * 1.1);
			float fade = (1.0 - smoothstep(mix(ray_rows.x, ray_rows.y, 0.35), ray_rows.y, px.y))
					* smoothstep(ray_spread, ray_spread * 0.55, abs(a)) * smoothstep(ray_rows.x, ray_rows.x + 8.0, px.y);
			float k = bands * breathe * fade;
			col = mix(col, ray_col, rays * (k > 0.45 ? 2.0 : (k > 0.22 ? 1.0 : 0.0)));
		}
	}

	// the glowing specks: each pulses on its own beat (bright, normal, a little dim)
	if (twinkle > 0.0 && here.b > 0.4 && here.b < 0.6) {
		float p = sin(t * 2.2 + hash(px) * 6.283);
		col = p > 0.5 ? mix(col, vec3(1.0), twinkle) : (p < -0.6 ? col * (1.0 - twinkle * 0.6) : col);
	}

	// the storm's lightning: now and then the whole panel blinks pale twice
	if (flash_every > 0.0) {
		float ph = mod(TIME, flash_every);
		float strike = (ph < 0.08 || (ph > 0.2 && ph < 0.3)) ? 1.0 : 0.0;
		strike *= step(0.35, hash(vec2(floor(TIME / flash_every), 1.0)));   // (not every time)
		col = mix(col, vec3(0.93, 0.96, 1.0), 0.35 * strike);
	}
	COLOR = vec4(col, texture(TEXTURE, UV).a);
}
