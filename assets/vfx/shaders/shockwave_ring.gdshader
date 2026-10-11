shader_type spatial;
render_mode blend_add, cull_disabled, unshaded;

uniform vec4 inner_color : source_color = vec4(1.0, 0.75, 0.2, 0.6);
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.6, 1.0);
uniform float ring_progress : hint_range(0.0, 1.0) = 0.5;
uniform float ring_thickness : hint_range(0.02, 0.4) = 0.12;
uniform float distortion_amount : hint_range(0.0, 0.2) = 0.05;

void fragment() {
	vec2 center_uv = UV - vec2(0.5);
	float r = length(center_uv) * 2.0; // 0.0 at center, 1.0 at edge
	
	float current_r = ring_progress;
	float dist_to_ring = abs(r - current_r);
	
	// Sharp outer edge with trailing inner gradient
	float ring_intensity = 0.0;
	if (dist_to_ring < ring_thickness) {
		float normalized_dist = dist_to_ring / ring_thickness;
		ring_intensity = 1.0 - smoothstep(0.0, 1.0, normalized_dist);
	}
	
	// Fade out towards edge of plane
	float edge_fade = 1.0 - smoothstep(0.85, 1.0, r);
	float total_alpha = ring_intensity * edge_fade * (1.0 - ring_progress * 0.75);
	
	vec3 col = mix(inner_color.rgb, rim_color.rgb, ring_intensity * 0.85);
	
	ALBEDO = col;
	ALPHA = clamp(total_alpha, 0.0, 1.0);
}
