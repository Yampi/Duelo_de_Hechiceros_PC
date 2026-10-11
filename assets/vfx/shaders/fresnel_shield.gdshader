shader_type spatial;
render_mode blend_add, cull_disabled, unshaded, depth_draw_never;

uniform vec4 shield_color : source_color = vec4(0.25, 0.75, 1.0, 0.85);
uniform vec4 rim_color : source_color = vec4(0.8, 0.95, 1.0, 1.0);
uniform float fresnel_power : hint_range(0.5, 6.0) = 2.4;
uniform float hex_scale : hint_range(5.0, 50.0) = 18.0;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.5;
uniform float hit_intensity : hint_range(0.0, 5.0) = 0.0;
uniform vec3 hit_point = vec3(0.0, 0.0, 0.0);

// Hexagonal tiling helper
vec2 hex_coords(vec2 uv) {
	vec2 r = vec2(1.0, 1.7320508);
	vec2 h = r * 0.5;
	vec2 a = mod(uv, r) - h;
	vec2 b = mod(uv - h, r) - h;
	vec2 gv = dot(a, a) < dot(b, b) ? a : b;
	return gv;
}

void fragment() {
	// 1. Fresnel Edge
	float fresnel = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = pow(fresnel, fresnel_power);
	
	// 2. Hexagonal energy grid pattern
	vec2 hex_uv = hex_coords(UV * hex_scale);
	float hex_edge = smoothstep(0.42, 0.48, length(hex_uv));
	
	// 3. Subtle animated energy pulse
	float pulse = 0.85 + 0.15 * sin(TIME * pulse_speed + UV.y * 12.0);
	
	// 4. Hit ripple impact wave
	float hit_wave = 0.0;
	if (hit_intensity > 0.01) {
		float d = distance(VERTEX, hit_point);
		hit_wave = hit_intensity * max(0.0, 1.0 - d * 1.5) * (0.5 + 0.5 * sin(TIME * 16.0 - d * 8.0));
	}
	
	// Composite emission and alpha
	vec3 col = mix(shield_color.rgb, rim_color.rgb, rim);
	col += rim_color.rgb * (hex_edge * 0.4 + hit_wave);
	
	float alpha = clamp((rim * 0.9 + hex_edge * 0.15 + hit_wave * 0.5) * pulse * shield_color.a, 0.0, 1.0);
	
	ALBEDO = col;
	ALPHA = alpha;
}
