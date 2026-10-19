shader_type canvas_item;
// Pal Prix 2's deep layer (scripts/pal_prix_2.gd): what's far below where the ground opens (a
// jump's gap, the drop under a flight) and all round in space. It moves slower than the ground
// (parallax: it's far away), on the same chunky board px, hazier than what's near. Neon City:
// the streets far down with their traffic; the Rapids: the jungle valley, its river, mist
// drifting; the Canyon: its floor, a river, long shadows; the Ice Fjord: dark water and ice;
// the Asteroid Belt: stars, a nebula, a planet; Saturn's Rings: the sky over the sea and clouds
// near the Earth, deep space with Saturn and its rings farther out.

uniform vec2 cam;                       // mat px at the view's middle
uniform float zoom = 1.25;
uniform vec2 view_size = vec2(896.0, 830.0);
uniform int world = 0;
uniform float parallax = 0.55;
uniform float t = 0.0;
uniform float altitude = 0.0;           // (Saturn's Rings) how high the flight is: 0 the sky over the sea, 1 deep space
uniform vec2 planet = vec2(3000.0, 1500.0);   // where the big planet hangs (deep mat px)

varying vec2 local;

void vertex() {
	local = VERTEX;
}

vec3 c8(float r, float g, float b) { return vec3(r, g, b) / 255.0; }

uint hash_u(uvec2 p) {
	uint h = p.x * 1664525u + p.y * 1013904223u + 374761393u;
	h ^= h >> 16u;
	h *= 2246822519u;
	h ^= h >> 13u;
	h *= 3266489917u;
	h ^= h >> 16u;
	return h;
}

float hash(vec2 p) {
	ivec2 i = ivec2(floor(p)) + ivec2(65536);
	return float(hash_u(uvec2(i)) & 16777215u) / 16777215.0;
}

float hash3(vec2 p, float s) {
	return hash(p + vec2(s * 17.31, s * 9.17));
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	return (0.5 * vnoise(p) + 0.25 * vnoise(p * 2.03 + 7.1) + 0.125 * vnoise(p * 4.07 + 3.3)) / 0.875;
}

float bayer(vec2 bp) {
	int x = int(mod(bp.x, 2.0));
	int y = int(mod(bp.y, 2.0));
	if (y == 0) {
		return x == 0 ? 0.125 : 0.625;
	}
	return x == 0 ? 0.875 : 0.375;
}

float stepped(float v, float n, vec2 bp) {
	float f = clamp(v, 0.0, 0.999) * n;
	float b = floor(f);
	if (f - b > 0.75 && bayer(bp) < (f - b - 0.75) * 4.0) {
		b += 1.0;
	}
	return min(b, n - 1.0);
}

vec3 pick4(float i, vec3 a, vec3 b, vec3 c, vec3 d) {
	if (i < 0.5) return a;
	if (i < 1.5) return b;
	if (i < 2.5) return c;
	return d;
}

// a winding river far below (its line's distance)
float river(vec2 bp, float scale) {
	float y = sin(bp.x * 0.012 * scale) * 40.0 + sin(bp.x * 0.031 * scale + 1.3) * 14.0;
	return abs(mod(bp.y - y + 90.0, 180.0) - 90.0);
}

vec3 stars(vec2 rel, float speed, float density, float bright) {
	vec2 m = cam * speed + rel;
	vec2 bp = floor(m / 4.0);
	float h = hash(bp + speed * 1000.0);
	if (h < density) {
		float tw = 0.65 + 0.35 * sin(t * (2.0 + hash(bp + 3.0) * 4.0) + hash(bp + 7.0) * 6.28);
		vec3 sc = hash(bp + 9.0) < 0.3 ? c8(255.0, 214.0, 170.0) : (hash(bp + 11.0) < 0.3 ? c8(170.0, 214.0, 255.0) : vec3(1.0));
		return sc * tw * bright;
	}
	return vec3(0.0);
}

vec3 space(vec2 rel, vec2 bp) {
	// deep space: dark blue-black, a soft nebula (violet, teal), three layers of stars
	vec2 mn = cam * 0.25 + rel;
	vec2 bn = floor(mn / 4.0);
	float n = fbm(bn * 0.012);
	float n2 = fbm(bn * 0.02 + 30.0);
	vec3 col = c8(10.0, 12.0, 30.0);
	float v = stepped(n * 0.9, 4.0, bn);
	if (n > 0.52) col = pick4(v, c8(10.0, 12.0, 30.0), c8(22.0, 18.0, 52.0), c8(40.0, 26.0, 78.0), c8(58.0, 36.0, 100.0));
	if (n2 > 0.62 && bayer(bn) < (n2 - 0.62) * 6.0) col = mix(col, c8(30.0, 90.0, 110.0), 0.5);
	vec3 s = stars(rel, 0.08, 0.004, 0.6) + stars(rel, 0.18, 0.003, 0.85) + stars(rel, 0.32, 0.0015, 1.0);
	col = max(col, s);
	return col;
}

// a planet seen from far (its own slow parallax): banded, lit from the top left, a ring round it
vec4 planet_px(vec2 rel, float rad, bool rings) {
	vec2 m = cam * 0.12 + rel;
	vec2 bp = floor(m / 4.0);
	vec2 o = bp + 0.5 - floor(planet / 4.0);
	float d = length(o);
	vec4 out_c = vec4(0.0);
	if (d < rad) {
		float light = (-(o.x) - (o.y)) / (rad * 1.6) + 0.5;
		float band = sin((o.y + sin(o.x * 0.08) * 2.0) * 0.45);
		vec3 base = band > 0.3 ? c8(230.0, 196.0, 140.0) : (band > -0.4 ? c8(206.0, 164.0, 112.0) : c8(178.0, 134.0, 92.0));
		float v = stepped(light, 4.0, bp);
		base *= 0.55 + 0.15 * v;
		if (d > rad - 1.0) base = c8(40.0, 30.0, 40.0);
		out_c = vec4(base, 1.0);
	}
	if (rings) {
		// the rings: a flat ellipse round it, in bands of ice, behind the planet at the top, in front at the bottom
		vec2 e = vec2(o.x, o.y / 0.32);
		float er = length(e);
		if (er > rad * 1.25 && er < rad * 2.1 && (o.y > 0.0 || d >= rad)) {
			float bnd = mod(floor(er / 2.0), 5.0);
			vec3 rc = bnd < 1.0 ? c8(236.0, 220.0, 190.0) : (bnd < 2.5 ? c8(200.0, 180.0, 150.0) : c8(160.0, 144.0, 124.0));
			if (bnd > 3.5) return out_c;                  // (a gap between the rings)
			float lite = clamp(0.6 - o.x / (rad * 4.0), 0.3, 1.0);
			return vec4(rc * lite, 1.0);
		}
	}
	return out_c;
}

void fragment() {
	vec2 rel = (local - view_size * 0.5) / zoom;        // mat px from the view's middle
	vec2 m = cam * parallax + rel;
	vec2 bp = floor(m / 4.0);
	vec3 col;
	if (world == 0) {
		// the streets far down: dark blocks, the roads' lights, cars' lights streaming along them
		float P = 22.0;
		vec2 c = floor(bp / P);
		vec2 lp = bp - c * P;
		col = c8(18.0, 15.0, 30.0);
		if (lp.x < 3.0 || lp.y < 3.0) {
			col = c8(30.0, 26.0, 44.0);
			if (lp.y < 3.0 && lp.x >= 3.0 && abs(lp.y - 1.0) < 0.6 && mod(bp.x + t * (30.0 + hash3(c, 1.0) * 30.0), 14.0) < 2.0) col = c8(255.0, 230.0, 180.0);
			if (lp.x < 3.0 && lp.y >= 3.0 && abs(lp.x - 1.0) < 0.6 && mod(bp.y - t * (30.0 + hash3(c, 2.0) * 30.0), 14.0) < 2.0) col = c8(255.0, 90.0, 90.0);
		} else if (mod(lp.x, 3.0) < 1.0 && mod(lp.y, 3.0) < 1.0 && hash(bp) < 0.3) {
			col = hash(bp + 2.0) < 0.5 ? c8(150.0, 120.0, 80.0) : c8(80.0, 120.0, 150.0);
		}
		// (a pink-blue glow of the city up through the haze)
		col = mix(col, c8(80.0, 40.0, 90.0), 0.25);
	} else if (world == 1) {
		// the jungle valley: small crowns in hazy greens, a river through it, mist drifting
		float n = fbm(bp * 0.08);
		float v = stepped(n, 4.0, bp);
		col = pick4(v, c8(52.0, 96.0, 80.0), c8(66.0, 118.0, 88.0), c8(86.0, 140.0, 100.0), c8(110.0, 162.0, 116.0));
		if (river(bp, 1.0) < 4.0) col = river(bp, 1.0) < 3.0 ? c8(90.0, 190.0, 190.0) : c8(150.0, 210.0, 190.0);
		col = mix(col, c8(170.0, 214.0, 220.0), 0.2);
		float mist = fbm(bp * 0.025 + vec2(t * 0.15, 0.0));
		if (mist > 0.68) col = mix(col, vec3(0.95, 0.98, 1.0), (mist > 0.74 || bayer(bp) < 0.5) ? 0.4 : 0.18);
	} else if (world == 2) {
		// the canyon's floor: red-brown, long purple shadows, a river, rocks
		float n2 = fbm(bp * 0.05);
		float v2 = stepped(n2, 4.0, bp);
		col = pick4(v2, c8(110.0, 52.0, 44.0), c8(134.0, 66.0, 50.0), c8(156.0, 84.0, 58.0), c8(178.0, 104.0, 70.0));
		if (river(bp, 0.8) < 3.0) col = c8(60.0, 140.0, 140.0);
		if (fbm(bp * 0.03 + 9.0) > 0.6) col *= 0.8;
		col = mix(col, c8(110.0, 80.0, 120.0), 0.3);
	} else if (world == 3) {
		// the fjord far below: dark water, ice floes, the aurora's sheen, mist
		col = c8(14.0, 40.0, 58.0);
		vec2 cell = floor(bp / 14.0);
		vec2 cen = (cell + vec2(0.3 + 0.4 * hash3(cell, 61.0), 0.3 + 0.4 * hash3(cell, 62.0))) * 14.0;
		if (hash3(cell, 65.0) < 0.16 && length(bp + 0.5 - cen) < 1.2 + hash3(cell, 63.0) * 2.2) col = c8(170.0, 196.0, 222.0);
		float sh = sin(bp.y * 0.4 + sin(bp.x * 0.025 + t * 0.4) * 3.0);
		if (sh > 0.97 && mod(bp.x, 4.0) < 2.0) col = mix(col, c8(80.0, 220.0, 160.0), 0.22);
		col = mix(col, c8(90.0, 120.0, 160.0), 0.2);
	} else if (world == 4) {
		col = space(rel, bp);
		vec4 pl = planet_px(rel, 34.0, false);
		if (pl.a > 0.5) col = pl.rgb;
	} else {
		// the Earth to space: low down, the sea far below with clouds drifting over it; climbing,
		// the blue deepens to indigo and the stars come out; at the top, deep space and Saturn
		float e = clamp(altitude * 1.15 - 0.05 - rel.y / view_size.y * 0.25, 0.0, 1.0);
		float n3 = fbm(bp * 0.045 + vec2(t * 0.08, 0.0));
		float wv = sin(bp.x * 0.3 + sin(bp.y * 0.15) * 2.0) * sin(bp.y * 0.5);
		vec3 sky = c8(46.0, 110.0, 180.0);
		if (wv > 0.85) sky = c8(90.0, 150.0, 210.0);
		if (n3 > 0.68) sky = (n3 > 0.73 || bayer(bp) < 0.5) ? c8(240.0, 246.0, 255.0) : c8(190.0, 212.0, 238.0);
		else if (n3 > 0.64 && bayer(bp) < 0.5) sky = c8(150.0, 186.0, 226.0);
		sky = mix(sky, c8(170.0, 200.0, 235.0), 0.25);
		vec3 sp = space(rel, bp);
		vec4 pl2 = planet_px(rel, 46.0, true);
		if (pl2.a > 0.5) sp = pl2.rgb;
		// (the edge of the atmosphere: in steps from the sky into space)
		float st = stepped(e * 0.999, 4.0, bp);
		col = st < 0.5 ? sky : (st < 1.5 ? mix(sky, c8(30.0, 60.0, 140.0), 0.6) : (st < 2.5 ? mix(sp, c8(36.0, 30.0, 90.0), 0.6) : sp));
	}
	COLOR = vec4(col, 1.0);
}
