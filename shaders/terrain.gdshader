shader_type spatial;

// Texturas PBR de alta resolución del proyecto
uniform sampler2D grass_diff : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D grass_nor : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_diff : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_nor : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D stone_diff : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D stone_nor : hint_normal, filter_linear_mipmap, repeat_enable;

// Niebla de Guerra (Fog of War) y parámetros dinámicos
uniform sampler2D fog_texture : filter_linear;
uniform vec3 player_pos = vec3(0.0, 0.0, 96.0);
uniform float reveal_radius = 26.0;
uniform bool enable_fog_of_war = true;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 uv_macro = v_world_pos.xz * 0.09;
	vec2 uv_mid = v_world_pos.xz * 0.22;
	vec2 uv_detail = v_world_pos.xz * 0.45;
	vec2 uv_tri_x = v_world_pos.zy * 0.14;
	vec2 uv_tri_z = v_world_pos.xy * 0.14;
	
	// 1. Muestreo de texturas PBR con variaciones de escala
	vec3 grass_col = texture(grass_diff, uv_mid).rgb;
	vec3 rock_flat = texture(rock_diff, uv_macro).rgb;
	vec3 stone_col = texture(stone_diff, uv_mid).rgb;
	
	// Triplanar para acantilados y taludes pronunciados
	vec3 rock_wall = mix(texture(rock_diff, uv_tri_x).rgb, texture(rock_diff, uv_tri_z).rgb, 0.5);
	
	// 2. Variación orgánica macro del suelo (evita patrones repetitivos y aspecto plano)
	float macro_noise1 = sin(v_world_pos.x * 0.045) * cos(v_world_pos.z * 0.045);
	float macro_noise2 = sin(v_world_pos.x * 0.12 + 1.2) * cos(v_world_pos.z * 0.10 + 0.8);
	float soil_patch = clamp(macro_noise1 * 0.6 + macro_noise2 * 0.4, -1.0, 1.0);
	
	// 3. Gradación de Biomas por Zonas
	float z = v_world_pos.z;
	vec3 biome_col = grass_col;
	float roughness_val = 0.85;
	
	if (z >= 64.0) {
		// Zona 1: Pradera Arcadia — Hierba verde bosque vibrante, musgo y praderas abiertas
		vec3 moss_deep = mix(grass_col, vec3(0.24, 0.38, 0.18), 0.35);
		vec3 grass_warm = mix(grass_col, vec3(0.38, 0.54, 0.22), 0.25);
		vec3 heath_gold = mix(grass_col, vec3(0.48, 0.48, 0.24), 0.30);
		
		vec3 meadow_blend = mix(moss_deep, grass_warm, smoothstep(-0.4, 0.3, soil_patch));
		meadow_blend = mix(meadow_blend, heath_gold, smoothstep(0.2, 0.7, macro_noise2));
		biome_col = meadow_blend;
		roughness_val = 0.82;
	} else if (z >= 0.0) {
		// Zona 2: Bosque Exterior — Humus de pino, musgo umbrío y tierra forestal
		float t = clamp((64.0 - z) / 64.0, 0.0, 1.0);
		vec3 z1_shade = mix(grass_col, vec3(0.26, 0.42, 0.20), 0.4);
		vec3 z2_shade = mix(grass_col * 0.85, rock_flat * 0.75, 0.35);
		biome_col = mix(z1_shade, z2_shade, smoothstep(0.0, 0.5, t));
		roughness_val = 0.86;
	} else if (z >= -64.0) {
		// Zona 3: Corazón del Bosque y Desfiladero — Tierra crepuscular y pizarra húmeda
		float t = clamp(-z / 64.0, 0.0, 1.0);
		vec3 z2_shade = mix(grass_col * 0.85, rock_flat * 0.75, 0.35);
		vec3 z3_shade = mix(rock_flat * 0.72, grass_col * 0.55, 0.40);
		biome_col = mix(z2_shade, z3_shade, smoothstep(0.0, 0.4, t));
		roughness_val = 0.78;
	} else {
		// Zona 4: Ruinas Arcanas — Enlosado de granito ancestral
		float t = clamp((-64.0 - z) / 64.0, 0.0, 1.0);
		vec3 z3_shade = mix(rock_flat * 0.72, grass_col * 0.55, 0.40);
		vec3 z4_shade = stone_col * 0.95;
		biome_col = mix(z3_shade, z4_shade, smoothstep(0.0, 0.30, t));
		
		// Vetas arcanas luminiscentes en las losas cercanas al Altar Central (0, -98)
		float dist_altar = length(v_world_pos.xz - vec2(0.0, -98.0));
		if (dist_altar < 24.0) {
			float rune_pattern = sin(v_world_pos.x * 2.5) * cos(v_world_pos.z * 2.5);
			if (rune_pattern > 0.68) {
				float rune_glow = (1.0 - (dist_altar / 24.0)) * (0.6 + 0.4 * sin(TIME * 2.0));
				EMISSION = vec3(0.18, 0.75, 1.0) * rune_glow * 1.6;
			}
		}
		roughness_val = 0.68;
	}
	
	// 4. Camino Orgánico Integrado (Organic Worn Trail with Dirt, Gravel & Mossy Edges)
	float road_center_x = 0.0;
	if (z >= 78.0) {
		road_center_x = 0.0;
	} else if (z >= 42.0) {
		float t_c = (78.0 - z) / 36.0;
		road_center_x = -4.0 * sin(t_c * 3.14159265);
	} else if (z >= 8.0) {
		float t_c = (42.0 - z) / 34.0;
		road_center_x = -4.0 * (1.0 - t_c);
	} else {
		road_center_x = 0.0;
	}
	
	float dist_main_road = abs(v_world_pos.x - road_center_x);
	// Ruido de alta y media frecuencia para bordes irregulares y deshilachados con hierba
	float edge_noise = sin(v_world_pos.x * 3.8 + 1.0) * cos(v_world_pos.z * 3.2) * 0.42
	                 + sin(v_world_pos.z * 7.5) * 0.18;
	
	// Ancho del camino principal ~2.8m con transicion suave de 1.2m
	float road_core = 1.0 - smoothstep(0.9, 2.2 + edge_noise, dist_main_road);
	float road_fringe = 1.0 - smoothstep(1.8, 3.6 + edge_noise, dist_main_road);
	
	// Textura de sendero: Tierra compacta, gravilla y piedra desgastada clara
	vec3 trail_soil = mix(vec3(0.38, 0.30, 0.22), rock_flat * 0.85, 0.45);
	vec3 trail_stone = mix(stone_col * 0.9, trail_soil, 0.35);
	vec3 trail_composite = mix(trail_stone, trail_soil, smoothstep(0.2, 0.8, abs(macro_noise2)));
	
	// Surcos centrales con humedad sutil
	float rut_factor = smoothstep(0.5, 0.1, abs(dist_main_road - 0.6)) * road_core;
	
	// Aplicar sendero sobre el terreno
	if (road_fringe > 0.01) {
		vec3 fringe_col = mix(biome_col, vec3(0.30, 0.36, 0.20), 0.5);
		biome_col = mix(biome_col, fringe_col, road_fringe * 0.7);
		biome_col = mix(biome_col, trail_composite, road_core * 0.95);
		roughness_val = mix(roughness_val, 0.82, road_core);
		roughness_val = mix(roughness_val, 0.60, rut_factor * 0.5);
	}
	
	// 5. Acantilados y Taludes Rocosos (Rock cliffs on steep terrain)
	float slope = v_world_normal.y;
	float cliff_factor = 1.0 - smoothstep(0.68, 0.84, slope); // > 32 grados se vuelve roca
	vec3 mossy_cliff = mix(rock_wall * 0.85, vec3(0.28, 0.36, 0.22), 0.25);
	vec3 final_albedo = mix(biome_col, mossy_cliff, cliff_factor);
	
	// 6. Normal Maps PBR combinados
	vec3 norm_grass = texture(grass_nor, uv_detail).rgb * 2.0 - 1.0;
	vec3 norm_stone = texture(stone_nor, uv_mid).rgb * 2.0 - 1.0;
	vec3 norm_cliff = texture(rock_nor, uv_macro).rgb * 2.0 - 1.0;
	vec3 norm_ground = mix(norm_grass, norm_stone, road_core * 0.85);
	NORMAL_MAP = mix(norm_ground, norm_cliff, cliff_factor);
	NORMAL_MAP_DEPTH = 1.15;
	
	// 7. Niebla de Guerra atmosférica (suave, sin oscurecer de golpe el mapa)
	if (enable_fog_of_war) {
		float dist_to_player = length(v_world_pos.xz - player_pos.xz);
		float player_circle = 1.0 - smoothstep(reveal_radius + 20.0, reveal_radius + 60.0, dist_to_player);
		float fog_factor = (1.0 - player_circle) * 0.30;
		final_albedo = mix(final_albedo, vec3(0.18, 0.22, 0.26), fog_factor);
	}
	
	ALBEDO = final_albedo;
	ROUGHNESS = roughness_val;
	SPECULAR = 0.22;
}
