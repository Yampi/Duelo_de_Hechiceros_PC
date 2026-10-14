shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform vec3 color_root : source_color = vec3(0.12, 0.22, 0.10);
uniform vec3 color_tip : source_color = vec3(0.38, 0.56, 0.24);
uniform float wind_strength = 0.08;
uniform float wind_speed = 2.2;
uniform sampler2D grass_tex : hint_default_white, filter_linear_mipmap;

void vertex() {
	// Wind displacement concentrated at the upper tip of grass blades
	float height_mask = clamp(VERTEX.y * 0.8, 0.0, 1.0);
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float wave = sin(TIME * wind_speed + world_pos.x * 1.4 + world_pos.z * 1.2);
	VERTEX.x += wave * wind_strength * height_mask;
	VERTEX.z += wave * wind_strength * 0.6 * height_mask;
}

void fragment() {
	float h = clamp(VERTEX.y * 0.65 + 0.15, 0.0, 1.0);
	vec3 base_col = mix(color_root, color_tip, h);
	
	ALBEDO = base_col;
	ROUGHNESS = 0.85;
	SPECULAR = 0.08;
}
