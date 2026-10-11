shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform sampler2D noise_texture : filter_linear_mipmap, repeat_enable;
uniform float dissolve_progress : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(0.01, 0.2) = 0.06;
uniform vec4 edge_color : source_color = vec4(0.85, 0.35, 1.0, 1.0); // Arcane purple default
uniform float edge_emission_energy : hint_range(1.0, 15.0) = 6.0;

// Procedural hash fallback if no noise texture is bound
float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float noise2d(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
	           mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec4 base_tex = texture(albedo_texture, UV) * albedo_color;
	
	// Sample noise or procedural fallback
	float noise_val = texture(noise_texture, UV * 3.0).r;
	if (noise_val < 0.001) {
		noise_val = noise2d(UV * 12.0);
	}
	
	// Threshold comparison
	float threshold = dissolve_progress;
	if (noise_val < threshold) {
		discard;
	}
	
	// Burning edge detection
	float edge_factor = 1.0 - smoothstep(threshold, threshold + edge_width, noise_val);
	
	ALBEDO = mix(base_tex.rgb, edge_color.rgb, edge_factor);
	EMISSION = edge_color.rgb * (edge_factor * edge_emission_energy);
	ALPHA = base_tex.a;
}
