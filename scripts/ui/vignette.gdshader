shader_type canvas_item;

// Screen edge vignette shader for damage feedback and low HP warning
uniform vec4 vignette_color : source_color = vec4(0.85, 0.08, 0.08, 1.0);
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float vignette_radius : hint_range(0.1, 1.5) = 0.75;
uniform float vignette_softness : hint_range(0.1, 1.5) = 0.45;

void fragment() {
	if (vignette_intensity <= 0.001) {
		COLOR = vec4(0.0);
	} else {
		vec2 uv = UV - vec2(0.5);
		float dist = length(uv);
		float vig = smoothstep(vignette_radius, vignette_radius + vignette_softness, dist);
		COLOR = vec4(vignette_color.rgb, vig * vignette_intensity * vignette_color.a);
	}
}
