shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled;

// Niebla de Guerra 3D en Escenario (3D World Fog of War Post-Processing)
// Reconstruye la posición 3D de cada pixel y aplica la niebla de guerra sobre el entorno
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D fog_texture : filter_linear;

uniform vec3 player_pos = vec3(0.0, 0.0, 96.0);
uniform float reveal_radius = 26.0;
uniform bool fog_enabled = true;

// Colores atmosféricos arcanos
uniform vec3 fog_color_unexplored : source_color = vec3(0.06, 0.08, 0.12);
uniform vec3 fog_color_explored : source_color = vec3(0.10, 0.12, 0.16);

void vertex() {
	// Fullscreen camera projection quad
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec4 screen_col = texture(screen_texture, SCREEN_UV);
	if (!fog_enabled) {
		ALBEDO = screen_col.rgb;
	} else {
		float depth = texture(depth_texture, SCREEN_UV).x;
		vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
		vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
		view.xyz /= view.w;
		vec4 world = INV_VIEW_MATRIX * vec4(view.xyz, 1.0);
		vec3 world_pos = world.xyz;
		
		// Convertir posición XZ a coordenadas UV de la cuadrícula de niebla (-128m a +128m)
		vec2 fog_uv = (world_pos.xz + vec2(128.0)) / 256.0;
		
		// Distancia radial continua al jugador para transición suave y libre de artefactos
		float dist_to_player = length(world_pos.xz - player_pos.xz);
		float player_reveal = 1.0 - smoothstep(reveal_radius - 3.5, reveal_radius + 1.5, dist_to_player);
		
		// Muestrear textura de niebla
		float fog_density = 1.0;
		float is_explored = 0.0;
		if (fog_uv.x >= 0.0 && fog_uv.x <= 1.0 && fog_uv.y >= 0.0 && fog_uv.y <= 1.0) {
			vec4 fog_sample = texture(fog_texture, fog_uv);
			fog_density = fog_sample.a;
			// Si el pixel fue explorado (alpha entre 0.4 y 0.85 en fog_texture)
			if (fog_sample.a < 0.85 && fog_sample.a > 0.1) {
				is_explored = 1.0;
			}
		} else {
			fog_density = 1.0;
		}
		
		// El círculo de visión del jugador despeja la niebla
		float active_fog = clamp(fog_density - player_reveal, 0.0, 1.0);
		
		// Bruma etérea animada en zonas inexploradas
		float mist_wave = sin(world_pos.x * 0.14 + TIME * 0.45) * cos(world_pos.z * 0.14 + TIME * 0.35) * 0.03;
		vec3 occult_mist = fog_color_unexplored + vec3(0.01, 0.02, 0.035) * (mist_wave + 0.03);
		
		// Cielo y horizonte lejano permanecen visibles para profundidad escénica
		if (depth <= 0.0001 || depth >= 0.9999) {
			active_fog = 0.0;
		} else {
			// Disminuir niebla en alturas superiores (picos de montaña y copas altas)
			float height_factor = clamp((world_pos.y - 8.0) / 16.0, 0.0, 0.85);
			active_fog *= (1.0 - height_factor);
		}
		
		vec3 target_fog_col = mix(occult_mist, fog_color_explored, is_explored);
		float shroud_opacity = mix(0.75, 0.35, is_explored) * active_fog;
		
		ALBEDO = mix(screen_col.rgb, target_fog_col, shroud_opacity);
	}
}
