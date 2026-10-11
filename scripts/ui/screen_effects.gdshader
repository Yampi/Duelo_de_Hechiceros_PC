shader_type canvas_item;

// Post-processing canvas_item shader for combat screen effects
// Supports: Death desaturation, elemental cast flash, screen darkening
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float desaturation : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_tint : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform float flash_power : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 sc = texture(screen_texture, SCREEN_UV);
	
	// Desaturacion progresiva (muerte / camara lenta)
	if (desaturation > 0.001) {
		float gray = dot(sc.rgb, vec3(0.299, 0.587, 0.114));
		sc.rgb = mix(sc.rgb, vec3(gray), desaturation);
	}
	
	// Flash elemental / tinte
	if (flash_power > 0.001 && flash_tint.a > 0.001) {
		sc.rgb = mix(sc.rgb, flash_tint.rgb, flash_power * flash_tint.a);
	}
	
	COLOR = sc;
}
