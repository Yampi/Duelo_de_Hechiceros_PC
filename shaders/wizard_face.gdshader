shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform vec4 skin_color : source_color = vec4(0.96, 0.82, 0.72, 1.0);
uniform vec4 eye_color : source_color = vec4(0.20, 0.75, 1.0, 1.0);
uniform vec4 hair_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float eye_emission_energy : hint_range(0.0, 10.0) = 4.2;
uniform int eye_shape = 0; // 0: Sabio, 1: Dracónico, 2: Estrella, 3: Eclipse, 4: Orbe, 5: Vórtice
uniform int beard_trim = 0; // 0: Barba Larga Ancestral, 1: Barba Recortada, 2: Barba Corta / Compacta
uniform int expression_style = 0;

void vertex() {
	if (beard_trim == 1 && VERTEX.y < -0.35) {
		VERTEX.y = mix(VERTEX.y, -0.35, 0.45);
		VERTEX.z = mix(VERTEX.z, 0.02, 0.25);
	} else if (beard_trim == 2 && VERTEX.y < -0.35) {
		VERTEX.y = mix(VERTEX.y, -0.35, 0.72);
		VERTEX.z = mix(VERTEX.z, 0.02, 0.45);
	}
}

void fragment() {
	vec4 tex = texture(albedo_texture, UV);
	
	// Detección de zonas UV del modelo del hechicero de Quaternius
	// Parche de ojos UV: x < 0.038 y entre 0.490 y 0.555 (52 caras de las cuencas oculares del modelo)
	bool is_eye = (UV.x < 0.038 && UV.y > 0.490 && UV.y < 0.555);
	// Parche de piel facial: frente, nariz y mejillas (atlas Quaternius en x > 0.94 o cromatismo cálido)
	bool is_skin = (!is_eye) && ((UV.x > 0.94 && UV.y > 0.65 && UV.y < 0.78) || (tex.r - tex.b > 0.05));
	
	if (is_eye) {
		// UVs normalizadas dentro de la cavidad ocular modelada
		float eye_u = clamp((UV.y - 0.505) / (0.548 - 0.505), 0.0, 1.0);
		float eye_v = clamp((UV.x - 0.004) / (0.024 - 0.004), 0.0, 1.0);
		
		vec2 eye_center = vec2(0.5, 0.5);
		vec2 p = vec2(eye_u, eye_v) - eye_center;
		p.x *= 0.8; // forma almendrada estilizada
		float dist = length(p);
		
		// Delineado / contorno natural de la cuenca ocular
		float border_mask = smoothstep(0.48, 0.35, max(abs(eye_u - 0.5) * 1.0, abs(eye_v - 0.5) * 1.2));
		
		// Ajuste de radio y enfoque según porte / expresión mística
		float iris_radius = 0.38;
		float pupil_radius = 0.18;
		if (expression_style == 1) { // Místico Iluminado
			iris_radius = 0.44;
			pupil_radius = 0.22;
		} else if (expression_style == 2) { // Adepto Joven
			iris_radius = 0.34;
			pupil_radius = 0.14;
		} else if (expression_style == 3) { // Archimago Cósmico
			iris_radius = 0.46;
			pupil_radius = 0.25;
		}
		
		float iris_core = 0.0;
		vec3 core_highlight = eye_color.rgb;
		vec3 socket_dark = vec3(0.08, 0.09, 0.12);
		
		// MODULACIÓN DE FORMA OCULAR (6 geometrías arcanas)
		if (eye_shape == 1) {
			// 1: Dracónico / Felino (Pupila rasgada vertical afilada)
			float slit = smoothstep(0.09, 0.01, abs(p.x) * 2.4 + abs(p.y) * 0.35);
			iris_core = smoothstep(iris_radius, 0.05, dist);
			core_highlight = mix(eye_color.rgb * 0.4, vec3(1.0, 0.95, 0.8), slit);
			iris_core = max(iris_core * 0.7, slit);
		} else if (eye_shape == 2) {
			// 2: Estrella Cósmica (Cruz celestial de 4 puntas)
			float star = min(abs(p.x) * 1.0 + abs(p.y) * 0.25, abs(p.y) * 1.0 + abs(p.x) * 0.25);
			float star_core = smoothstep(0.20, 0.02, star);
			iris_core = smoothstep(iris_radius, 0.05, dist);
			core_highlight = mix(eye_color.rgb, vec3(1.0), star_core);
			iris_core = max(iris_core * 0.8, star_core);
		} else if (eye_shape == 3) {
			// 3: Eclipse Rúnico (Halo exterior radiante con centro oscuro abisal)
			float ring = smoothstep(0.10, 0.20, dist) * smoothstep(0.38, 0.26, dist);
			iris_core = ring * 1.4;
			core_highlight = mix(socket_dark, eye_color.rgb * 1.3, ring);
		} else if (eye_shape == 4) {
			// 4: Orbe Elemental / Ceguera Mística (Resplandor puro y total sin pupila)
			iris_core = smoothstep(0.46, 0.10, dist);
			core_highlight = mix(eye_color.rgb, vec3(1.0), smoothstep(0.30, 0.0, dist) * 0.9);
		} else if (eye_shape == 5) {
			// 5: Vórtice Hipnótico (Espiral concéntrica de energía arcana)
			float angle = atan(p.y, p.x);
			float spiral = sin(dist * 26.0 - angle * 2.0) * 0.5 + 0.5;
			iris_core = smoothstep(iris_radius, 0.05, dist) * (0.6 + 0.4 * spiral);
			core_highlight = mix(eye_color.rgb * 0.6, vec3(1.0), spiral * 0.7);
		} else {
			// 0: Sabio Clásico (Pupila redonda tradicional con destello noble)
			iris_core = smoothstep(iris_radius, 0.05, dist);
			core_highlight = mix(eye_color.rgb, vec3(1.0), smoothstep(pupil_radius, 0.0, dist) * 0.75);
		}
		
		ALBEDO = mix(socket_dark, core_highlight, border_mask);
		EMISSION = eye_color.rgb * eye_emission_energy * iris_core * border_mask;
		ROUGHNESS = mix(0.8, 0.1, iris_core);
	} else if (is_skin) {
		// Tez del mago modulada de forma natural con el tono seleccionado
		float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
		ALBEDO = skin_color.rgb * clamp(lum / 0.50, 0.6, 1.4);
		ROUGHNESS = 0.65;
		RIM = 0.6;
		RIM_TINT = 0.4;
	} else {
		// Barba, bigote y cejas modulados con el tinte capilar seleccionado
		ALBEDO = tex.rgb * hair_color.rgb;
		ROUGHNESS = 0.65;
		RIM = 0.5;
	}
}
