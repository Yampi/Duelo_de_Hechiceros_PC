shader_type spatial;
render_mode blend_add, cull_disabled, unshaded;

uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 halo_color : source_color = vec4(0.2, 0.85, 1.0, 0.9);
uniform sampler2D noise_texture : filter_linear_mipmap, repeat_enable;
uniform vec2 scroll_speed = vec2(0.0, -4.5);
uniform float core_width : hint_range(0.05, 0.5) = 0.18;
uniform float distortion_strength : hint_range(0.0, 0.5) = 0.12;

float hash12(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * .1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 moving_uv = UV + scroll_speed * TIME;
	
	// Sample animated noise distortion
	float noise_val = texture(noise_texture, moving_uv).r;
	if (noise_val < 0.001) {
		noise_val = hash12(floor(moving_uv * 16.0) + vec2(floor(TIME * 24.0), 0.0));
	}
	
	float dist_from_center = abs(UV.x - 0.5) * 2.0;
	dist_from_center += (noise_val - 0.5) * distortion_strength;
	dist_from_center = clamp(dist_from_center, 0.0, 1.0);
	
	// White incandescent core
	float core_mask = smoothstep(core_width, 0.0, dist_from_center);
	// Outer glowing halo
	float halo_mask = smoothstep(1.0, 0.0, dist_from_center);
	
	vec3 col = mix(halo_color.rgb, core_color.rgb, core_mask);
	float alpha = clamp(halo_mask * halo_color.a + core_mask * core_color.a, 0.0, 1.0);
	
	ALBEDO = col;
	ALPHA = alpha;
}
