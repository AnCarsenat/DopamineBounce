shader_type canvas_item;
// Radial speed lines streaking outward from a vanishing point.
// Drive "intensity" from 0 (off) to 1 (full) with the game speed.

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 0.8);
// Point the lines radiate from, in screen UV.
uniform vec2 center = vec2(0.5, 0.45);
// Number of angular slots a streak can appear in.
uniform float line_count = 90.0;
// How fast streaks fly outward at full intensity.
uniform float line_speed = 4.0;

float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

void fragment() {
	vec2 p = UV - center;
	float r = length(p);
	float angle = atan(p.y, p.x) / TAU + 0.5;

	float slot = floor(angle * line_count);
	float across = fract(angle * line_count) - 0.5;
	float rnd = hash(slot);

	// Each slot runs its own looping streak; faster and more numerous as intensity rises.
	float t = TIME * mix(1.5, line_speed, intensity) * (0.6 + rnd) + rnd * 17.0;
	float phase = fract(t);
	float lit = step(1.0 - mix(0.12, 0.55, intensity), hash(slot + floor(t) * 7.3));

	// Thin wedge across the slot, random thickness.
	float thin = smoothstep(mix(0.12, 0.4, hash(slot + 3.1)), 0.0, abs(across));

	// A dash travelling outward along the radius, fading in and out over its life.
	float d = r - phase * 0.9;
	float dash = smoothstep(0.0, 0.03, d) * smoothstep(0.4, 0.1, d) * sin(phase * PI);

	// Keep the middle of the screen clear; lines creep further in as intensity rises.
	float inner = mix(0.5, 0.22, intensity);
	float edge = smoothstep(inner, inner + 0.25, r);

	COLOR = vec4(line_color.rgb, line_color.a * thin * dash * lit * edge * intensity);
}
