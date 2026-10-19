shader_type canvas_item;
// Pal Prix 2's ground (scripts/pal_prix_2.gd): the near layer of every world, painted per board
// px (4 mat px) on the games' chunky grid: few flat colours in steps with a 2x2 dither between
// them, raised pieces outlined dark with a side face and a shadow, lit from the top left (the
// Tilt Maze / Pal Prix rules). It reads the course from two textures (PalPrix2Course): every
// point of its middle line (board px, kind, flags) and, on a coarse grid, the nearest point of
// the course (all of it, its land, its sea, its air), refined here to the exact distance, side
// and how far along. Where the course flies (air) the ground opens: a cliff or a waterfall hangs
// down its far side and the deep layer (pal_prix_2_deep.gdshader) shows below. The raised hover
// road, its neon edges, the water lane, ramps, boost plates and the start line are painted here
// too, and they move (edge lights running, water flowing, neon flickering).

uniform vec2 origin;                    // mat (0, 0) in this rect's px
uniform float zoom = 1.25;
uniform int world = 0;                  // 0 Neon City, 1 Rapids, 2 Canyon, 3 Ice Fjord, 4 Asteroid Belt, 5 Saturn's Rings
uniform int count = 1;
uniform float hw = 37.5;                // the road's half width (board px)
uniform float cs = 12.0;                // a field cell (board px)
uniform vec2 field_size = vec2(1.0);
uniform sampler2D pts_tex : filter_nearest;
uniform sampler2D near_tex : filter_nearest;
uniform float r_sea = 60.0;             // the water round a sea stretch (board px)
uniform float r_air = 64.0;             // the drop round a flight
uniform float r_land = 70.0;            // (space) the rock round a land stretch
uniform bool has_land = true;
uniform bool has_sea = false;
uniform bool has_air = false;
uniform float face_h = 22.0;            // a cliff's height (board px)
uniform vec4 gates[8];                  // (point, from kind, to kind, 0)
uniform int n_gates = 0;
uniform vec4 pads[12];                  // land boost plates: (point, half length (points), lateral (board px), half width)
uniform int n_pads = 0;
uniform vec4 gaps[8];                   // jumps: (first point, last point, ramp points, kind)
uniform int n_gaps = 0;
uniform float t = 0.0;                  // the race's clock (s)
uniform bool icy = false;               // (the Ice Fjord's icy roads: frost on them)

varying vec2 local;

const int LAND = 0;
const int SEA = 1;
const int AIR = 2;
const vec3 OUTLINE = vec3(40.0, 30.0, 40.0) / 255.0;

void vertex() {
	local = VERTEX;
}

// ---------------------------------------------------------------- helpers

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

// the 2x2 dither (Pal Prix's DITHER)
float bayer(vec2 bp) {
	int x = int(mod(bp.x, 2.0));
	int y = int(mod(bp.y, 2.0));
	if (y == 0) {
		return x == 0 ? 0.125 : 0.625;
	}
	return x == 0 ? 0.875 : 0.375;
}

// v in 0..1 -> one of n steps, the top quarter of each step dithered into the next
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

vec4 pt(int k) {
	int kk = k;
	if (kk < 0) kk += count;
	if (kk >= count) kk -= count;
	return texelFetch(pts_tex, ivec2(kk, 0), 0);
}

int wrapk(int k) {
	int kk = k;
	if (kk < 0) kk += count;
	if (kk >= count) kk -= count;
	return kk;
}

// the course near a point: its distance, how far along (points), which side, its kind, the way
// out from the line (n) and the way along it (dir); cut: past a stretch's end (its gate)
struct Hit {
	float d;
	float along;
	float side;
	int kind;
	vec2 n;
	vec2 dir;
	bool cut;
};

Hit nearest(vec2 p, int ch, bool cut_ends) {
	Hit h;
	h.d = 1e9;
	h.along = 0.0;
	h.side = 1.0;
	h.kind = -1;
	h.n = vec2(0.0, 1.0);
	h.dir = vec2(1.0, 0.0);
	h.cut = false;
	vec2 cf = floor(p / cs);
	if (cf.x < 0.0 || cf.y < 0.0 || cf.x >= field_size.x || cf.y >= field_size.y) {
		return h;
	}
	vec4 nf = texelFetch(near_tex, ivec2(cf), 0);
	float kf = ch == 0 ? nf.r : (ch == 1 ? nf.g : (ch == 2 ? nf.b : nf.a));
	if (kf < 0.0) {
		return h;
	}
	int k0 = int(kf + 0.5);
	int kind0 = int(pt(k0).z + 0.5);
	for (int o = -6; o <= 6; o++) {
		int a = wrapk(k0 + o);
		vec4 A = pt(a);
		vec4 B = pt(a + 1);
		if (ch > 0 && (int(A.z + 0.5) != kind0 || int(B.z + 0.5) != kind0)) {
			continue;
		}
		vec2 ab = B.xy - A.xy;
		float l2 = max(dot(ab, ab), 1e-4);
		float raw = dot(p - A.xy, ab) / l2;
		float tt = clamp(raw, 0.0, 1.0);
		vec2 q = A.xy + ab * tt;
		float d = length(p - q);
		if (d < h.d) {
			h.d = d;
			h.along = float(a) + tt;
			vec2 dv = ab / sqrt(l2);
			h.dir = dv;
			h.side = sign(dv.x * (p.y - A.y) - dv.y * (p.x - A.x));
			h.n = d > 1e-3 ? (p - q) / d : vec2(-dv.y, dv.x) * h.side;
			h.kind = int(A.z + 0.5);
			h.cut = cut_ends && ((raw < 0.0 && (int(A.w + 0.5) & 1) != 0) || (raw > 1.0 && (int(B.w + 0.5) & 2) != 0));
		}
	}
	// (the first point of a stretch: a point before it is past the gate)
	if (cut_ends && ch > 0) {
		int ai = int(floor(h.along));
		vec4 A2 = pt(ai);
		if ((int(A2.w + 0.5) & 1) != 0) {
			vec2 dv2 = normalize(pt(ai + 1).xy - A2.xy);
			if (dot(p - A2.xy, dv2) < 0.0) {
				h.cut = true;
			}
		}
	}
	return h;
}

// along the course, in points, from a to b (forwards, wrapping)
float ahead(float from_i, float to_i) {
	float d = to_i - from_i;
	if (d < -float(count) * 0.5) d += float(count);
	if (d > float(count) * 0.5) d -= float(count);
	return d;
}

vec3 lit(vec3 c, float k) {
	return k >= 0.0 ? mix(c, vec3(1.0), k) : c * (1.0 + k);
}

// ---------------------------------------------------------------- the worlds' accents

vec3 accent() {
	if (world == 0) return c8(65.0, 227.0, 255.0);     // cyan
	if (world == 1) return c8(120.0, 255.0, 170.0);    // mint
	if (world == 2) return c8(255.0, 160.0, 60.0);     // orange
	if (world == 3) return c8(160.0, 236.0, 255.0);    // ice
	if (world == 4) return c8(255.0, 90.0, 220.0);     // magenta
	return c8(255.0, 224.0, 102.0);                    // gold
}

vec3 accent2() {
	if (world == 0) return c8(255.0, 79.0, 163.0);
	if (world == 1) return c8(255.0, 214.0, 90.0);
	if (world == 2) return c8(255.0, 90.0, 80.0);
	if (world == 3) return c8(190.0, 130.0, 255.0);
	if (world == 4) return c8(110.0, 240.0, 255.0);
	return c8(90.0, 190.0, 255.0);
}

bool night() {
	return world == 0 || world == 3 || world == 4;
}

// ---------------------------------------------------------------- the land

vec3 city(vec2 bp) {
	// Neon City at night: blocks of buildings (roofs, their lit south walls, rooftop things,
	// neon signs) in a grid of dark streets with cars' lights running along them
	float P = 34.0;
	vec2 cid = floor(bp / P);
	vec2 lp = bp - cid * P;
	float h1 = hash3(cid, 1.0);
	float h2 = hash3(cid, 2.0);
	float h3 = hash3(cid, 3.0);
	float street = 5.0;
	float x0 = street + floor(h1 * 3.0);
	float x1 = P - 1.0 - floor(h2 * 3.0);
	float y0 = street + floor(h3 * 3.0);
	float y1 = P - 1.0;
	if (lp.x < street || lp.y < street) {
		// the streets: dark asphalt, a faint dashed line, cars' lights (white one way, red the other)
		vec3 s = c8(22.0, 20.0, 33.0);
		bool horiz = lp.y < street && lp.x >= street;
		bool vert = lp.x < street && lp.y >= street;
		if (horiz) {
			float lane = lp.y < 2.5 ? 1.0 : -1.0;
			float row = lp.y < 2.5 ? 1.0 : 3.0;
			if (abs(lp.y - row) < 0.6) {
				float sp = 20.0 + hash3(vec2(cid.y, lane), 4.0) * 26.0;
				float m = mod(bp.x - lane * t * sp + hash3(vec2(cid.y, lane), 5.0) * 60.0, 23.0 + floor(hash3(vec2(cid.y, lane), 6.0) * 30.0));
				if (m < 2.0) {
					s = lane > 0.0 ? c8(255.0, 244.0, 214.0) : c8(255.0, 70.0, 80.0);
				}
			}
			if (abs(lp.y - 2.0) < 0.5 && mod(bp.x, 6.0) < 3.0) s = c8(46.0, 44.0, 60.0);
		} else if (vert) {
			float lane2 = lp.x < 2.5 ? 1.0 : -1.0;
			float col = lp.x < 2.5 ? 1.0 : 3.0;
			if (abs(lp.x - col) < 0.6) {
				float sp2 = 20.0 + hash3(vec2(cid.x, lane2), 7.0) * 26.0;
				float m2 = mod(bp.y - lane2 * t * sp2 + hash3(vec2(cid.x, lane2), 8.0) * 60.0, 23.0 + floor(hash3(vec2(cid.x, lane2), 9.0) * 30.0));
				if (m2 < 2.0) {
					s = lane2 > 0.0 ? c8(255.0, 244.0, 214.0) : c8(255.0, 70.0, 80.0);
				}
			}
		} else {
			s = c8(30.0, 28.0, 42.0);                   // a crossing
		}
		return s;
	}
	if (lp.x < x0 || lp.x > x1 || lp.y < y0) {
		return c8(30.0, 27.0, 44.0);                    // a gap between buildings: an alley
	}
	// the building: its height, its roof above its south wall
	float hb = 3.0 + floor(hash3(cid, 10.0) * 6.0);
	float wall_top = y1 - hb;
	vec3 roof = pick4(floor(hash3(cid, 11.0) * 4.0), c8(58.0, 51.0, 85.0), c8(47.0, 58.0, 87.0), c8(70.0, 58.0, 92.0), c8(45.0, 66.0, 80.0));
	bool outl = lp.x == x0 || lp.x == x1 || lp.y == y0;
	if (lp.y > wall_top) {
		// the south wall: darker, rows of windows lit warm / cool, a few dark, one now and then flicking
		if (lp.x == x0 || lp.x == x1 || lp.y == y1) return OUTLINE;
		vec3 wall = roof * 0.55;
		float wy = lp.y - wall_top;
		if (mod(lp.x - x0, 2.0) < 0.5 && mod(wy, 2.0) > 0.5 && wy < hb - 0.5) {
			float hw2 = hash(bp + vec2(cid.x * 3.0, 0.0));
			if (hw2 < 0.55) {
				vec3 win = hash3(cid, 12.0) < 0.5 ? c8(255.0, 214.0, 130.0) : c8(150.0, 230.0, 255.0);
				if (hash(bp + floor(t * 0.5)) < 0.03) win *= 0.4;
				wall = win;
			}
		}
		return wall;
	}
	if (outl) return OUTLINE;
	if (lp.y == wall_top) return roof * 0.8;              // (the roof's edge over the wall)
	// the roof: lit along its top and left edges
	vec3 r = roof;
	if (lp.y == y0 + 1.0 || lp.x == x0 + 1.0) r = lit(roof, 0.12);
	if (lp.x == x1 - 1.0) r = roof * 0.85;
	// rooftop things
	float kind = hash3(cid, 13.0);
	vec2 rc = vec2((x0 + x1) * 0.5, (y0 + wall_top) * 0.5);
	vec2 rd = lp - rc;
	float rw = (x1 - x0) * 0.5;
	float rh = (wall_top - y0) * 0.5;
	if (kind < 0.18 && rw > 8.0 && rh > 7.0) {
		// a helipad: a ring with an H
		float rr = length(rd);
		if (abs(rr - 5.5) < 0.8) return c8(240.0, 210.0, 90.0);
		if (rr < 4.5 && ((abs(rd.x) > 1.5 && abs(rd.x) < 2.6 && abs(rd.y) < 3.0) || (abs(rd.y) < 0.6 && abs(rd.x) < 2.6))) return c8(236.0, 236.0, 246.0);
		if (rr < 7.0) r = r * 0.9;
	} else if (kind < 0.38) {
		// air vents: little grey boxes, lit top-left, a shadow down-right
		vec2 vp = mod(lp - vec2(x0 + 3.0, y0 + 3.0), vec2(7.0, 6.0));
		vec2 vi = floor((lp - vec2(x0 + 3.0, y0 + 3.0)) / vec2(7.0, 6.0));
		if (hash3(vi + cid * 7.0, 14.0) < 0.6 && lp.x < x1 - 3.0 && lp.y < wall_top - 2.0) {
			if (vp.x < 3.0 && vp.y < 2.0) return vp.y < 0.5 ? c8(170.0, 172.0, 190.0) : c8(126.0, 128.0, 146.0);
			if (vp.x >= 1.0 && vp.x < 4.0 && vp.y >= 2.0 && vp.y < 3.0) return roof * 0.7;
		}
	} else if (kind < 0.55) {
		// a garden on the roof: soft green, a few round trees
		if (abs(rd.x) < rw - 2.0 && abs(rd.y) < rh - 2.0) {
			float g = fbm(bp * 0.35);
			vec3 gc = g > 0.62 ? c8(86.0, 150.0, 92.0) : (g > 0.45 ? c8(62.0, 120.0, 78.0) : c8(48.0, 96.0, 70.0));
			return gc;
		}
	} else if (kind < 0.7) {
		// a water tank: a round drum, lit top-left
		vec2 tc = rd - vec2(rw * 0.3, -rh * 0.2);
		float tr = length(tc);
		if (tr < 3.6) {
			if (tr > 2.8) return OUTLINE;
			return tc.x + tc.y < -1.0 ? c8(176.0, 120.0, 92.0) : c8(140.0, 92.0, 74.0);
		}
	}
	// the neon sign along the roof's south edge (some buildings): bright letters, flickering
	if (hash3(cid, 15.0) < 0.45) {
		float sy = wall_top - 3.0;
		float sx0 = x0 + 3.0 + floor(hash3(cid, 16.0) * 4.0);
		float sx1 = x1 - 3.0;
		if (lp.y >= sy - 1.0 && lp.y <= sy + 1.0 && lp.x >= sx0 && lp.x <= sx1) {
			vec3 nc = pick4(floor(hash3(cid, 17.0) * 4.0), c8(255.0, 79.0, 163.0), c8(65.0, 227.0, 255.0), c8(255.0, 214.0, 70.0), c8(150.0, 255.0, 120.0));
			float letter = hash(vec2(floor((lp.x - sx0) / 2.0), cid.x + cid.y * 31.0));
			bool on = hash(vec2(cid.x * 13.0 + floor(t * 3.0), cid.y)) > 0.06;
			if (lp.y == sy && letter < 0.25) return roof * 0.6;
			return on ? nc : nc * 0.35;
		}
		if (lp.y >= sy - 3.0 && lp.y <= sy + 3.0 && lp.x >= sx0 - 2.0 && lp.x <= sx1 + 2.0 && bayer(bp) < 0.5) {
			vec3 nc2 = pick4(floor(hash3(cid, 17.0) * 4.0), c8(255.0, 79.0, 163.0), c8(65.0, 227.0, 255.0), c8(255.0, 214.0, 70.0), c8(150.0, 255.0, 120.0));
			return mix(r, nc2, 0.35);                        // (its glow on the roof)
		}
	}
	// an antenna with a blinking red light
	if (kind > 0.85 && lp.x == x0 + 3.0 && lp.y >= y0 + 2.0 && lp.y <= y0 + 5.0) {
		if (lp.y == y0 + 2.0) return mod(t + hash3(cid, 18.0) * 2.0, 1.6) < 0.5 ? c8(255.0, 60.0, 60.0) : c8(110.0, 40.0, 50.0);
		return c8(110.0, 112.0, 130.0);
	}
	return r;
}

vec3 jungle(vec2 bp) {
	// the Rapids' banks: a thick jungle canopy, round crowns lit top-left, in steps of green,
	// a darker rim to the bottom right, flowers on some; dark undergrowth between them
	vec3 under = c8(30.0, 72.0, 46.0);
	float best = -1.0;
	vec3 col = under;
	vec2 cell = floor(bp / 13.0);
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 c = cell + vec2(float(i), float(j));
			vec2 cen = (c + vec2(0.2 + 0.6 * hash3(c, 21.0), 0.2 + 0.6 * hash3(c, 22.0))) * 13.0;
			float rad = 6.0 + hash3(c, 23.0) * 4.0;
			vec2 o = bp + 0.5 - cen;
			float dd = length(o);
			if (dd < rad && cen.y > best) {
				best = cen.y;
				float light = (-(o.x) - (o.y)) / (rad * 1.5) + 0.45;
				float v = stepped(light + 0.1, 4.0, bp);
				col = pick4(v, c8(44.0, 104.0, 58.0), c8(62.0, 136.0, 68.0), c8(88.0, 166.0, 80.0), c8(126.0, 196.0, 98.0));
				if (dd > rad - 1.0 && o.x + o.y > 0.0) col = c8(30.0, 72.0, 46.0);
				float fl = hash3(c, 24.0);
				if (fl < 0.2 && abs(o.x - 2.0) < 0.6 && abs(o.y + 1.0) < 0.6) col = fl < 0.1 ? c8(255.0, 140.0, 190.0) : c8(255.0, 226.0, 110.0);
			}
		}
	}
	return col;
}

vec3 mesa(vec2 bp) {
	// the Canyon's mesa tops at sunset: red rock in soft patches (fbm, stepped, dithered),
	// cracks, scattered boulders lit top-left, olive scrub, pale sand drifts
	float n = fbm(bp * 0.045);
	float v = stepped(n * 1.1 - 0.05, 4.0, bp);
	vec3 col = pick4(v, c8(176.0, 82.0, 48.0), c8(200.0, 104.0, 58.0), c8(222.0, 132.0, 72.0), c8(240.0, 166.0, 100.0));
	float s = fbm(bp * 0.02 + 40.0);
	if (s > 0.64) col = (s > 0.7 || bayer(bp) < 0.5) ? c8(244.0, 196.0, 130.0) : col;
	float cr = abs(fbm(bp * 0.06 + 11.0) - 0.5);
	if (cr < 0.012) col = c8(130.0, 56.0, 38.0);
	vec2 cell = floor(bp / 16.0);
	vec2 cen = (cell + vec2(0.25 + 0.5 * hash3(cell, 31.0), 0.25 + 0.5 * hash3(cell, 32.0))) * 16.0;
	float rad = 1.5 + hash3(cell, 33.0) * 2.5;
	vec2 o = bp + 0.5 - cen;
	float h = hash3(cell, 34.0);
	if (h < 0.1) {
		if (length(o) < rad + 1.0) {
			if (length(o) > rad) return OUTLINE;
			return o.x + o.y < -0.5 ? c8(214.0, 140.0, 96.0) : c8(150.0, 84.0, 60.0);
		}
		if (length(o - vec2(1.0, 1.5)) < rad + 1.0) col *= 0.82;      // (its shadow)
	} else if (h < 0.22 && length(o) < 1.6) {
		return o.y < 0.0 ? c8(150.0, 160.0, 80.0) : c8(110.0, 120.0, 60.0);
	}
	return col;
}

vec3 glacier(vec2 bp) {
	// the Ice Fjord's glacier at night: snow in cold blues, wind ripples, crevasses, a sparkle
	float n = fbm(bp * 0.04);
	float rip = sin(bp.x * 0.35 + bp.y * 0.2 + fbm(bp * 0.05) * 6.0);
	float v = stepped(n * 0.9 + rip * 0.06 + 0.05, 4.0, bp);
	vec3 col = pick4(v, c8(110.0, 140.0, 190.0), c8(146.0, 176.0, 218.0), c8(184.0, 208.0, 236.0), c8(220.0, 234.0, 250.0));
	float cr = abs(fbm(bp * 0.03 + 5.0) - 0.5);
	if (cr < 0.01) col = c8(40.0, 70.0, 130.0);
	else if (cr < 0.018 && bayer(bp) < 0.5) col = c8(80.0, 110.0, 170.0);
	if (hash(bp) < 0.004 && mod(t * 2.0 + hash(bp + 3.0) * 10.0, 3.0) < 0.4) col = vec3(1.0);
	return col;
}

vec3 asteroid(vec2 bp) {
	// the Asteroid Belt's rock: grey-violet, dusty patches, craters (dark where the light can't
	// reach, the far inner wall lit, a light rim)
	float n = fbm(bp * 0.05);
	float v = stepped(n, 4.0, bp);
	vec3 col = pick4(v, c8(78.0, 70.0, 92.0), c8(98.0, 90.0, 112.0), c8(120.0, 112.0, 136.0), c8(146.0, 138.0, 160.0));
	vec2 cell = floor(bp / 20.0);
	for (int j = 0; j <= 1; j++) {
		for (int i = 0; i <= 1; i++) {
			vec2 c = floor((bp + vec2(float(i), float(j)) * 10.0) / 20.0);
			if (hash3(c, 41.0) > 0.55) continue;
			vec2 cen = (c + vec2(0.3 + 0.4 * hash3(c, 42.0), 0.3 + 0.4 * hash3(c, 43.0))) * 20.0;
			float rad = 3.0 + hash3(c, 44.0) * 5.0;
			vec2 o = bp + 0.5 - cen;
			float dd = length(o);
			if (dd < rad) {
				float side = (o.x + o.y) / rad;
				col = side > 0.25 ? c8(150.0, 142.0, 166.0) : (side < -0.2 ? c8(46.0, 40.0, 58.0) : c8(70.0, 62.0, 84.0));
				if (dd > rad - 1.0 && o.x + o.y > 0.0) col = c8(170.0, 162.0, 186.0);
			} else if (dd < rad + 1.0 && o.x + o.y < 0.0) {
				col = c8(160.0, 152.0, 176.0);
			}
		}
	}
	return col;
}

vec3 spaceport(vec2 bp) {
	// Saturn's Rings' launch coast: concrete slabs with their seams, a painted landing circle now
	// and then, grass verges with palms between the slabs
	vec2 cell = floor(bp / 16.0);
	vec2 lp = bp - cell * 16.0;
	float h = hash3(cell, 51.0);
	if (h < 0.18) {
		// a grass verge with a palm
		float g = fbm(bp * 0.2);
		vec3 gc = g > 0.55 ? c8(120.0, 186.0, 96.0) : c8(92.0, 160.0, 82.0);
		vec2 o = lp - vec2(8.0, 8.0);
		if (length(o) < 4.5) {
			float ang = atan(o.y, o.x);
			if (abs(sin(ang * 3.0)) > 0.4 || length(o) < 1.5) return length(o) < 1.5 ? c8(140.0, 96.0, 60.0) : c8(60.0, 140.0, 70.0);
		}
		return gc;
	}
	vec3 col = h < 0.6 ? c8(176.0, 180.0, 194.0) : c8(164.0, 168.0, 182.0);
	if (lp.x < 1.0 || lp.y < 1.0) col = c8(134.0, 138.0, 152.0);
	if (h > 0.975) {
		float rr = length(lp - vec2(8.0));
		if (abs(rr - 5.0) < 0.7) col = c8(250.0, 210.0, 70.0);
	}
	if (hash(bp * 0.5) < 0.04) col *= 0.94;
	return col;
}

vec3 land_px(vec2 bp) {
	if (world == 0) return city(bp);
	if (world == 1) return jungle(bp);
	if (world == 2) return mesa(bp);
	if (world == 3) return glacier(bp);
	if (world == 4) return asteroid(bp);
	return spaceport(bp);
}

// ---------------------------------------------------------------- the water

vec3 water_px(vec2 bp, Hit hs, float edge_d) {
	// edge_d: how far inside the water's edge (board px)
	float lane = hs.d < hw ? 1.0 : 0.0;
	float along_px = hs.along * 2.0;                        // (points are 2 board px apart)
	vec3 col;
	if (world == 0) {
		// the harbour at night: dark water, slow light ripples, neon glints from the city
		col = mix(c8(16.0, 24.0, 52.0), c8(26.0, 40.0, 78.0), lane * 0.7);
		float w = sin(bp.x * 0.3 + sin(bp.y * 0.2 + t * 0.8) * 2.0 + t * 0.6) * sin(bp.y * 0.45 - t * 0.5);
		if (w > 0.88) col = c8(48.0, 70.0, 120.0);
		float near_q = clamp(1.0 - edge_d / 26.0, 0.0, 1.0);
		vec2 gc = vec2(floor(bp.x / 6.0), bp.y);
		float g = hash(gc + floor(t * 1.5 + hash(gc) * 3.0) * 7.0);
		if (g < 0.0012 + 0.05 * near_q * near_q) {
			vec3 nc = pick4(floor(hash(gc + 9.0) * 4.0), c8(255.0, 79.0, 163.0), c8(65.0, 227.0, 255.0), c8(255.0, 214.0, 70.0), c8(200.0, 200.0, 255.0));
			col = mix(col, nc, 0.55);
		}
	} else if (world == 1) {
		// the river: turquoise, deeper in the lane, foam streaks flowing down it, white water
		col = mix(c8(70.0, 206.0, 196.0), c8(36.0, 160.0, 176.0), clamp(1.0 - hs.d / (hw * 1.2), 0.0, 1.0));
		float fl = fract((along_px - t * 70.0) / 22.0 + hash(vec2(floor(hs.side * hs.d / 3.0), 0.0)) * 3.0);
		if (fl < 0.07 && hash(vec2(floor(hs.side * hs.d / 3.0), floor((along_px - t * 70.0) / 22.0))) < 0.3) col = c8(214.0, 250.0, 244.0);
		float wh = fbm(vec2(along_px * 0.06 - t * 1.4, hs.side * hs.d * 0.12));
		if (wh > 0.77) col = (wh > 0.81 || bayer(bp) < 0.5) ? c8(236.0, 252.0, 250.0) : col;
	} else if (world == 3) {
		// the fjord: deep teal, floating ice, the aurora's green and violet in it
		col = mix(c8(14.0, 52.0, 70.0), c8(22.0, 72.0, 94.0), lane * 0.6);
		float sh = sin(bp.y * 0.5 + sin(bp.x * 0.03 + t * 0.5) * 3.0);
		if (sh > 0.96 && mod(bp.x, 4.0) < 2.0) col = mix(col, (fract(bp.x / 300.0 + t * 0.02) < 0.5 ? c8(80.0, 220.0, 160.0) : c8(150.0, 110.0, 230.0)), 0.3);
		if (lane < 0.5) {
			vec2 cell = floor(bp / 18.0);
			vec2 cen = (cell + vec2(0.3 + 0.4 * hash3(cell, 61.0), 0.3 + 0.4 * hash3(cell, 62.0))) * 18.0;
			float rad = 3.0 + hash3(cell, 63.0) * 3.5;
			vec2 o = bp + 0.5 - cen;
			float wob = rad * (1.0 + 0.1 * sin(atan(o.y, o.x) * 3.0 + hash3(cell, 64.0) * 6.0));
			if (hash3(cell, 65.0) < 0.22 && length(o) < wob + 1.0) {
				if (length(o) > wob) return OUTLINE;
				return o.x + o.y < 0.0 ? c8(240.0, 248.0, 255.0) : c8(190.0, 214.0, 240.0);
			}
		}
	} else if (world == 4) {
		// the stardust stream: violet, glittering, a glowing rim fading to space
		col = mix(c8(36.0, 22.0, 80.0), c8(60.0, 36.0, 120.0), clamp(1.0 - hs.d / r_sea, 0.0, 1.0));
		float gl = hash(bp + floor(t * 6.0) * 13.0);
		if (gl < 0.03) col = pick4(floor(hash(bp + 5.0) * 4.0), c8(255.0, 140.0, 220.0), c8(127.0, 243.0, 255.0), vec3(1.0), c8(255.0, 230.0, 140.0));
		float fl2 = fract((along_px - t * 50.0) / 30.0 + hs.d * 0.05);
		if (fl2 < 0.035 && hash(vec2(floor(hs.d), 2.0)) < 0.3) col = mix(col, c8(200.0, 160.0, 255.0), 0.45);
	} else {
		// the ocean at the launch coast: blue, wave crests, lighter towards the shore
		col = mix(c8(46.0, 110.0, 180.0), c8(38.0, 92.0, 160.0), lane);
		float wv = sin(bp.x * 0.25 + sin(bp.y * 0.12 + t * 0.7) * 2.5) * sin(bp.y * 0.4 + t * 0.9);
		if (wv > 0.86) col = c8(150.0, 200.0, 240.0);
	}
	// the shallows by the edge, foam on it
	if (edge_d < 3.0 && world != 4) {
		col = mix(col, vec3(1.0), 0.18);
		if (edge_d < 1.5 && bayer(bp + floor(t * 4.0)) < 0.5) col = vec3(0.94, 0.98, 1.0);
	}
	return col;
}

// the edge of the water on land: a quay, a sandy or rocky bank, an ice edge
vec3 shore_px(vec2 bp, float out_d) {
	if (world == 0) {
		if (out_d < 1.0) return OUTLINE;
		if (out_d < 2.0) return mod(bp.x + bp.y, 6.0) < 3.0 ? c8(250.0, 210.0, 70.0) : c8(40.0, 36.0, 48.0);
		return c8(96.0, 96.0, 116.0);
	}
	if (world == 1) {
		if (out_d < 1.0) return c8(110.0, 96.0, 80.0);
		return hash(floor(bp / 2.0)) < 0.5 ? c8(150.0, 140.0, 120.0) : c8(214.0, 196.0, 150.0);
	}
	if (world == 3) {
		if (out_d < 1.0) return c8(60.0, 90.0, 150.0);
		return c8(230.0, 242.0, 255.0);
	}
	if (out_d < 1.0) return c8(150.0, 120.0, 70.0);
	return out_d < 3.0 ? c8(240.0, 220.0, 160.0) : c8(226.0, 204.0, 146.0);
}

// ---------------------------------------------------------------- the cliffs (into the drop)

vec4 face_px(vec2 bp, float u, bool waterfall) {
	// u: px below the edge (0 = the lip). The rock (or the falling water) going down into haze
	float k = u / face_h;
	vec3 col;
	if (waterfall) {
		float x = bp.x;
		float s = fract(u / 7.0 - t * 2.2 + hash(vec2(floor(x / 2.0), 3.0)) * 4.0);
		col = s < 0.4 ? c8(240.0, 252.0, 255.0) : (s < 0.7 ? c8(180.0, 232.0, 240.0) : c8(120.0, 200.0, 220.0));
		if (world == 3) col = s < 0.5 ? c8(230.0, 244.0, 255.0) : c8(150.0, 190.0, 230.0);
		if (u < 1.5) col = vec3(1.0);
	} else if (world == 0) {
		vec3 wall = c8(40.0, 36.0, 60.0);
		col = wall;
		if (mod(bp.x, 3.0) < 1.0 && mod(u, 3.0) < 1.0 && hash(bp) < 0.5) col = hash(bp + 1.0) < 0.5 ? c8(255.0, 214.0, 130.0) : c8(150.0, 230.0, 255.0);
		if (u < 1.0) col = c8(90.0, 84.0, 120.0);
	} else if (world == 1) {
		float band = fbm(vec2(bp.x * 0.15, u * 0.4));
		col = band > 0.55 ? c8(120.0, 112.0, 98.0) : c8(92.0, 86.0, 78.0);
		if (u < 2.5) col = c8(70.0, 140.0, 70.0);
		else if (u < 6.0 && hash(vec2(bp.x, 9.0)) < 0.35) col = c8(56.0, 120.0, 62.0);
	} else if (world == 2) {
		float st = floor((u + fbm(vec2(bp.x * 0.05, 0.0)) * 6.0) / 3.0);
		float m = mod(st, 4.0);
		col = pick4(m, c8(168.0, 74.0, 43.0), c8(196.0, 95.0, 53.0), c8(140.0, 60.0, 38.0), c8(212.0, 122.0, 69.0));
		if (u < 1.0) col = c8(246.0, 179.0, 122.0);
	} else if (world == 3) {
		col = mix(c8(150.0, 190.0, 236.0), c8(60.0, 100.0, 170.0), k);
		if (mod(bp.x + floor(u / 4.0), 5.0) < 1.0) col *= 0.9;
		if (u < 1.5) col = c8(240.0, 248.0, 255.0);
	} else if (world == 4) {
		float st2 = mod(floor((u + vnoise(vec2(bp.x * 0.2, 0.0)) * 3.0) / 3.0), 2.0);
		col = st2 < 0.5 ? c8(62.0, 54.0, 76.0) : c8(48.0, 42.0, 60.0);
		if (u < 1.0) col = c8(150.0, 142.0, 168.0);
	} else {
		col = mix(c8(110.0, 100.0, 96.0), c8(70.0, 64.0, 70.0), k);
		if (u < 1.0) col = c8(200.0, 196.0, 200.0);
	}
	// darker downwards, then the haze (dithered away into the depth)
	col *= 1.0 - 0.35 * k;
	float alpha = 1.0;
	if (k > 0.72) {
		float f = (k - 0.72) / 0.28;
		if (bayer(bp) < f) alpha = 0.0;
	}
	return vec4(col, alpha);
}

// ---------------------------------------------------------------- the road

// the raised hover road (land): its dark glossy surface with panel seams, the neon edges with
// lights running along them, the dashed middle, chevron ramps before a jump or a gate into the
// water or the air, the landing stripes after one, boost plates, the start line
vec3 road_px(vec2 bp, Hit h) {
	float lat = h.d * h.side;
	float along_px = h.along * 2.0;
	vec3 base = c8(44.0, 48.0, 70.0);
	if (world == 2) base = c8(70.0, 52.0, 56.0);
	if (world == 3) base = c8(58.0, 70.0, 100.0);
	if (world == 5) base = c8(70.0, 74.0, 88.0);
	vec3 col = base;
	if (icy) {
		// frost: the road glazed pale blue in patches, streaks of ice catching the light
		float fr = fbm(bp * 0.08);
		if (fr > 0.45) base = mix(base, c8(150.0, 190.0, 230.0), fr > 0.55 ? 0.45 : (bayer(bp) < 0.5 ? 0.3 : 0.0));
		col = base;
		if (abs(fract((bp.x - bp.y) * 0.05 + fr) - 0.5) < 0.02 && fr > 0.5) col = c8(220.0, 240.0, 255.0);
	}
	if (mod(along_px, 16.0) < 1.0) col = base * 0.85;                              // a seam across
	if (abs(abs(lat) - hw * 0.34) < 0.5 && mod(along_px, 10.0) < 5.0) col = mix(base, accent(), 0.25);
	if (abs(lat) < 0.7 && mod(along_px, 12.0) < 6.0) col = mix(vec3(1.0), accent(), 0.3);    // the middle
	// the edges: a neon strip (a light running along it), a lit lip, the outline
	float e = hw - h.d;
	if (e < 1.0) return OUTLINE;
	if (e < 3.0) {
		float run = fract((along_px - t * 160.0) / 40.0);
		vec3 ac = accent();
		return run < 0.12 ? vec3(1.0) : (e < 2.0 ? ac : ac * 0.7);
	}
	if (e < 4.0) col = base * 0.75;
	// the start / finish line: a checker across the road
	float to_start = min(h.along, float(count) - h.along);
	if (to_start < 2.0) {
		return (mod(floor(bp.x / 2.0) + floor(bp.y / 2.0), 2.0) < 1.0) ? c8(30.0, 30.0, 34.0) : c8(244.0, 240.0, 226.0);
	}
	// the gates: chevrons rising to a gate out of the land, stripes after a landing
	for (int g = 0; g < n_gates; g++) {
		vec4 G = gates[g];
		float a = ahead(G.x, h.along);
		if (int(G.y + 0.5) == LAND && a > -14.0 && a < 0.0) {
			float rise = (a + 14.0) / 14.0;
			float ch = fract((along_px - abs(lat) * 0.8) / 10.0 - t * 1.5);
			vec3 gc = int(G.z + 0.5) == SEA ? c8(110.0, 220.0, 255.0) : c8(255.0, 120.0, 220.0);
			col = ch < 0.45 ? lit(gc, 0.25 * rise) : mix(base, gc, 0.25);
		}
		if (int(G.z + 0.5) == LAND && a >= 0.0 && a < 12.0) {
			if (mod(floor(along_px / 4.0), 2.0) < 1.0 && abs(lat) < hw - 6.0) col = mix(col, c8(255.0, 224.0, 102.0), 0.5);
		}
	}
	// the jumps: a ramp, then the gap
	for (int j = 0; j < n_gaps; j++) {
		vec4 J = gaps[j];
		if (int(J.w + 0.5) != LAND) continue;
		float a2 = ahead(J.x, h.along);
		if (a2 > -J.z && a2 < 0.0) {
			float rise2 = (a2 + J.z) / J.z;
			float ch2 = fract((along_px - abs(lat) * 0.8) / 10.0);
			col = ch2 < 0.5 ? lit(c8(252.0, 210.0, 64.0), 0.3 * rise2) : c8(70.0, 64.0, 78.0) * (1.0 + rise2 * 0.4);
		}
	}
	// the boost plates: chevrons flowing down the road over a dark plate
	for (int p = 0; p < n_pads; p++) {
		vec4 P = pads[p];
		float a3 = ahead(P.x, h.along);
		if (abs(a3) < P.y && abs(lat - P.z) < P.w) {
			if (abs(a3) > P.y - 1.0 || abs(lat - P.z) > P.w - 1.0) return OUTLINE;
			float ch3 = fract((a3 * 2.0 - abs(lat - P.z) * 0.8) / 8.0 - t * 2.4);
			vec3 pc = accent2();
			return ch3 < 0.4 ? lit(pc, 0.3) : (ch3 < 0.55 ? pc * 0.7 : c8(36.0, 34.0, 50.0));
		}
	}
	return col;
}

// the road's side face (it's raised: seen from the south), lit strip and pylons, the outline
vec3 road_side(vec2 bp, Hit h, float u) {
	float along_px = h.along * 2.0;
	vec3 metal = c8(34.0, 36.0, 54.0);
	if (world == 2) metal = c8(60.0, 40.0, 40.0);
	if (world == 3) metal = c8(50.0, 60.0, 90.0);
	if (world == 5) metal = c8(80.0, 84.0, 100.0);
	if (u > 6.0) return OUTLINE;
	vec3 col = u < 1.0 ? metal * 1.6 : metal;
	if (abs(u - 3.0) < 0.6 && mod(along_px, 6.0) < 2.0) col = mod(along_px / 6.0 + t * 4.0, 8.0) < 1.0 ? vec3(1.0) : accent2() * 0.85;
	if (mod(along_px, 40.0) < 4.0 && u > 1.0) col = metal * 1.3;                      // a pylon
	return col;
}

// ---------------------------------------------------------------- all together

vec4 ground(vec2 lp) {
	vec2 m = (lp - origin) / zoom;                   // mat px
	vec2 bp = floor(m / 4.0);                           // board px
	vec2 p = bp + 0.5;
	Hit h0 = nearest(p, 0, false);
	// the regions: the drop round a flight, the water round a sea stretch, the land (in space:
	// the rock round a land stretch, everything else open space)
	float nz = (vnoise(bp * 0.09) - 0.5) * 10.0 + (vnoise(bp * 0.31) - 0.5) * 3.0;
	Hit ha;
	ha.d = 1e9;
	ha.cut = true;
	Hit hs;
	hs.d = 1e9;
	hs.cut = true;
	Hit hl;
	hl.d = 1e9;
	hl.cut = true;
	if (has_air) ha = nearest(p, 3, true);
	if (has_sea) hs = nearest(p, 2, true);
	bool space = world == 4;
	if ((world == 4 || world == 5) && has_land) hl = nearest(p, 1, true);
	float ra = r_air + nz;
	float rs = r_sea + nz * 0.8;
	float rl = r_land + nz;
	bool hole = !ha.cut && ha.d < ra;
	bool water = !hole && !hs.cut && hs.d < rs;
	if (space) {
		bool rock = !hl.cut && hl.d < rl;
		water = !hs.cut && hs.d < rs;
		hole = !rock && !water;
	}
	if (world == 5) {
		// the launch coast: the Earth round the land and the sea, open sky past it
		bool earth = (!hl.cut && hl.d < rl) || (!hs.cut && hs.d < rl);
		hole = hole || !earth;
		water = !hole && !hs.cut && hs.d < rs;
	}
	// a jump's gap: the road and the ground under it open (the street far below)
	bool gap = false;
	for (int j = 0; j < n_gaps; j++) {
		vec4 J = gaps[j];
		if (int(J.w + 0.5) == LAND && h0.kind == LAND && ahead(J.x, h0.along) >= 0.0 && ahead(J.y, h0.along) <= 0.0 && h0.d < hw + 10.0) {
			gap = true;
		}
	}
	// the road (land stretches): its surface, its side face and its shadow
	if (h0.kind == LAND && !gap) {
		if (h0.d < hw) {
			return vec4(road_px(bp, h0), 1.0);
		}
		if (h0.n.y > 0.05) {
			float u = (h0.d - hw) / h0.n.y;
			if (u < 7.0) {
				return vec4(road_side(bp, h0, u), 1.0);
			}
		}
	}
	if (gap) {
		float e = hw + 10.0 - h0.d;
		if (e < 1.0) {
			return vec4(OUTLINE, 1.0);
		}
		if (e < 4.0 && bayer(bp) < 0.6) return vec4(0.04, 0.03, 0.08, 1.0);
		return vec4(0.0);
	}
	// the water lane's sea stretches (in the sea, its own lane colour is in water_px)
	vec4 col = vec4(0.0);
	if (hole) {
		// open: the deep layer shows, but the far side's cliff hangs down into it
		col = vec4(0.0);
		if (space) {
			// the rock slab's south side, fading into space
			if (!hl.cut && hl.n.y > 0.05) {
				float u3 = (hl.d - rl) / hl.n.y;
				if (u3 >= 0.0 && u3 < face_h) {
					col = face_px(bp, u3, false);
				}
			}
		} else if (has_air && !ha.cut && ha.n.y < -0.05) {
			float u2 = (ra - ha.d) / (-ha.n.y);
			if (u2 < face_h) {
				bool wf = has_sea && !hs.cut && hs.d < rs + u2 + 2.0;
				col = face_px(bp, u2, wf);
			}
		}
		// the drop's ends at its gates: a cliff (or the river pouring over as a waterfall) hangs
		// down from the edge where the ground stops, when it faces you (south)
		if (!space && col.a < 0.5) {
			for (int g = 0; g < n_gates; g++) {
				vec4 G = gates[g];
				int from = int(G.y + 0.5);
				int to = int(G.z + 0.5);
				if (from != AIR && to != AIR) continue;
				int gi = int(G.x + 0.5);
				vec2 gp = pt(gi).xy;
				vec2 gd = normalize(pt(gi + 1).xy - gp);
				float lat = abs(gd.x * (p.y - gp.y) - gd.y * (p.x - gp.x));
				if (lat > ra + 2.0 || abs(gd.y) < 0.05) continue;
				float s = dot(p - gp, gd);
				float u4 = s / gd.y;
				bool before_high = to == AIR;
				if (u4 >= 0.0 && u4 < face_h && ((before_high && gd.y > 0.0 && s >= 0.0) || (!before_high && gd.y < 0.0 && s <= 0.0))) {
					col = face_px(bp, u4, (before_high ? from : to) == SEA);
				}
			}
		}
		if (world == 5 && col.a < 0.5) {
			// the Earth's edge: clouds round it
			float ed = min(hl.cut ? 1e9 : hl.d - rl, hs.cut ? 1e9 : hs.d - rl);
			if (ed >= 0.0 && ed < 14.0) {
				float cl = fbm(bp * 0.12 + vec2(t * 0.3, 0.0));
				if (cl > 0.35 + ed / 14.0 * 0.45) {
					col = vec4(cl > 0.6 ? vec3(1.0) : c8(214.0, 228.0, 246.0), 1.0);
				}
			}
		}
		return col;
	}
	vec3 g;
	if (water) {
		float ed2 = (space ? rs - hs.d : rs - hs.d);
		g = water_px(bp, hs, ed2);
		// a waterfall step across the river (a jump): the white lip, the water falling (moving),
		// the dark drop at its foot
		for (int j2 = 0; j2 < n_gaps; j2++) {
			vec4 J2 = gaps[j2];
			if (int(J2.w + 0.5) != SEA) continue;
			float a5 = ahead(J2.x, hs.along);
			if (a5 > -1.0 && a5 < 4.0 && hs.d < rs - 2.0) {
				if (a5 < 0.0) g = vec3(1.0);
				else if (a5 < 3.0) {
					float fall = fract(a5 / 3.0 - t * 2.5 + hash(vec2(floor(hs.d * hs.side / 2.0), 7.0)));
					g = fall < 0.45 ? c8(236.0, 252.0, 255.0) : (fall < 0.75 ? c8(160.0, 230.0, 236.0) : c8(90.0, 190.0, 206.0));
				} else {
					g = c8(30.0, 120.0, 140.0);
				}
			}
		}
		if (space && ed2 < 3.0) {
			// (the stream's glowing rim, dithered off into space)
			g = mix(g, c8(255.0, 140.0, 230.0), 0.5);
			if (ed2 < 1.5 && bayer(bp) < 0.5) {
				return vec4(0.0);
			}
		}
	} else {
		g = land_px(bp);
		// the shore: a quay, a bank
		if (has_sea && !hs.cut && hs.d < rs + 4.0 && !space) {
			g = shore_px(bp, hs.d - rs);
		}
		// the far edge of a drop (its near side: no face shows, just the outline and a lit lip)
		if (has_air && !ha.cut && !space && ha.d < ra + 1.5) {
			g = ha.n.y > 0.0 ? OUTLINE : lit(g, 0.2);
		}
		if (space && !hl.cut && hl.d > rl - 1.5) {
			g = hl.n.y < 0.0 ? lit(g, 0.25) : OUTLINE;
		}
	}
	// at the gates: the shore where a road meets the water, the lip (or the outline) where the
	// ground stops at a drop
	if (!space) {
		for (int g2 = 0; g2 < n_gates; g2++) {
			vec4 G2 = gates[g2];
			int from2 = int(G2.y + 0.5);
			int to2 = int(G2.z + 0.5);
			int gi2 = int(G2.x + 0.5);
			vec2 gp2 = pt(gi2).xy;
			vec2 gd2 = normalize(pt(gi2 + 1).xy - gp2);
			float s2 = dot(p - gp2, gd2);
			float lat2 = abs(gd2.x * (p.y - gp2.y) - gd2.y * (p.x - gp2.x));
			bool shore_gate = (from2 == LAND && to2 == SEA) || (from2 == SEA && to2 == LAND);
			if (shore_gate && !water && lat2 < rs) {
				float on_land = from2 == LAND ? -s2 : s2;
				if (on_land >= 0.0 && on_land < 4.0) g = shore_px(bp, on_land);
			}
			if ((from2 == AIR || to2 == AIR) && lat2 < ra) {
				float on_high = to2 == AIR ? -s2 : s2;
				if (on_high >= 0.0 && on_high < 1.5) {
					bool faces_you = to2 == AIR ? gd2.y > 0.0 : gd2.y < 0.0;
					g = faces_you ? lit(g, 0.2) : OUTLINE;
				}
			}
		}
	}
	// the road's shadow on the ground (down and to the right of it)
	if (h0.kind == LAND) {
		float sd = h0.d - dot(vec2(3.0, 9.0), h0.n);
		if (sd < hw && h0.d >= hw) g *= 0.7;
	}
	if (night() && !water) g *= 0.92;
	return vec4(g, 1.0);
}

void fragment() {
	COLOR = ground(local);
}
