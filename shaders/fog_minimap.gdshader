shader_type canvas_item;

// Niebla de Guerra en Radar Minimapa (Minimap Fog of War Overlay)
uniform sampler2D fog_texture : filter_linear;
uniform vec2 player_pos = vec2(0.0, 96.0);
uniform float radar_radius = 75.0;
uniform float reveal_radius = 20.0;

void fragment() {
	vec2 rel = UV - vec2(0.5);
	float dist = length(rel);
	
	// Recorte circular del minimapa
	if (dist > 0.46) {
		COLOR = vec4(0.0);
	} else {
		// Mapear UV relativa al offset en metros del mundo
		vec2 world_offset = (rel / 0.46) * radar_radius;
		vec2 world_xz = player_pos + world_offset;
		
		// Coordenadas UV en la textura de niebla 128x128 (-128m a +128m)
		vec2 fog_uv = (world_xz + vec2(128.0)) / 256.0;
		
		float fog_val = 1.0;
		float is_explored = 0.0;
		if (fog_uv.x >= 0.0 && fog_uv.x <= 1.0 && fog_uv.y >= 0.0 && fog_uv.y <= 1.0) {
			vec4 f_sample = texture(fog_texture, fog_uv);
			fog_val = f_sample.a;
			if (f_sample.a < 0.85 && f_sample.a > 0.1) {
				is_explored = 1.0;
			}
		} else {
			fog_val = 1.0;
		}
		
		// Despeje dinámico suave alrededor del jugador
		float world_dist_to_player = length(world_offset);
		float player_clear = 1.0 - smoothstep(reveal_radius - 2.5, reveal_radius + 1.5, world_dist_to_player);
		float active_fog = clamp(fog_val - player_clear, 0.0, 1.0);
		
		// Borde de visión arcano luminiscente
		float rim_dist = abs(world_dist_to_player - reveal_radius);
		float rim_glow = (1.0 - smoothstep(0.0, 2.0, rim_dist)) * 0.45;
		
		vec4 occult_fog = vec4(0.02, 0.03, 0.06, 0.96);
		vec4 memory_fog = vec4(0.04, 0.06, 0.10, 0.58);
		vec4 fog_tint = mix(occult_fog, memory_fog, is_explored);
		
		vec4 final_col = fog_tint;
		final_col.a *= active_fog;
		
		// Resplandor arcano en el límite de la visión
		final_col.rgb += vec3(0.25, 0.85, 1.0) * rim_glow;
		final_col.a = max(final_col.a, rim_glow * 0.75);
		
		COLOR = final_col;
	}
}
