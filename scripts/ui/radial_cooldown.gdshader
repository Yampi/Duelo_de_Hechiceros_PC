shader_type canvas_item;

// Shader de barrido radial para enfriamiento de hechizos y habilidades.
// progress: 0.0 (listo / sin barrido) a 1.0 (enfriamiento total).
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 cooldown_color : source_color = vec4(0.02, 0.03, 0.05, 0.75);
uniform vec4 edge_color : source_color = vec4(0.4, 0.85, 1.0, 0.9);

void fragment() {
	if (progress <= 0.001) {
		COLOR = vec4(0.0);
	} else {
		vec2 centered = UV - vec2(0.5);
		float angle = atan(centered.x, -centered.y);
		if (angle < 0.0) {
			angle += 6.28318530718;
		}
		float norm_angle = angle / 6.28318530718;
		
		if (norm_angle <= progress) {
			// Sutil borde brillante en el frente de barrido
			float edge_dist = abs(norm_angle - progress);
			if (edge_dist < 0.015 && progress < 0.98) {
				COLOR = edge_color;
			} else {
				COLOR = cooldown_color;
			}
		} else {
			COLOR = vec4(0.0);
		}
	}
}
