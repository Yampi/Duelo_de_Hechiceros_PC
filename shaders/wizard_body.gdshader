shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform vec4 robe_color : source_color = vec4(0.12, 0.22, 0.65, 1.0);
uniform vec4 skin_color : source_color = vec4(0.96, 0.82, 0.72, 1.0);
uniform vec4 hair_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 trim_color : source_color = vec4(0.90, 0.75, 0.30, 1.0);

void fragment() {
	vec4 tex = texture(albedo_texture, UV);
	
	// Clasificación espectral basada en el atlas original de Quaternius
	// 1. Piel (rostro, cabeza, cuello y manos): tono cálido carne
	bool is_skin = (tex.r > 0.32 && tex.g > 0.22 && (tex.r - tex.b) > 0.12 && tex.r >= tex.g * 0.95 && tex.g > tex.b);
	
	// 2. Túnica / Ropa / Manto: azul/índigo característico en la textura original
	bool is_robe = (!is_skin) && (tex.b > 0.14 && tex.b > tex.r * 1.08 && tex.b >= tex.g * 0.88);
	
	// 3. Cabello (mechones en cabeza): escala de grises neutra clara
	bool is_hair = (!is_skin) && (!is_robe) && (abs(tex.r - tex.g) < 0.04 && abs(tex.g - tex.b) < 0.04 && tex.r > 0.50);
	
	float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	
	if (is_skin) {
		ALBEDO = skin_color.rgb * clamp(lum / 0.50, 0.6, 1.4);
		ROUGHNESS = 0.65;
		RIM = 0.5;
		RIM_TINT = 0.4;
	} else if (is_robe) {
		ALBEDO = robe_color.rgb * clamp(lum / 0.35, 0.45, 1.45);
		ROUGHNESS = 0.55;
		RIM = 0.6;
		RIM_TINT = 0.35;
	} else if (is_hair) {
		ALBEDO = tex.rgb * hair_color.rgb;
		ROUGHNESS = 0.65;
		RIM = 0.5;
	} else {
		// Cuero, botas, correas y detalles naturales
		ALBEDO = tex.rgb;
		ROUGHNESS = 0.60;
	}
}
