shader_type canvas_item;

uniform bool is_energy = false;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	if (color.a < 0.5) {
		COLOR = vec4(0.0);
	} else {
	bool rim = color.r > 0.18 && color.g > 0.10
		&& color.r > color.g * 1.06 && color.g > color.r * 0.55
		&& color.g > color.b * 1.15;
	if (rim) {
		color.rgb = vec3(0.7412, 0.5569, 0.3176);
	} else if (is_energy) {
		vec2 local_uv = (UV * vec2(1261.0, 1247.0) - vec2(261.0, 224.0))
			/ vec2(741.0, 760.0);
		vec2 glint = (local_uv - vec2(0.38, 0.28)) / vec2(0.055, 0.040);
		if (color.r > 0.20 && color.g > 0.60 && color.b > 0.55) {
			color.rgb = vec3(0.17, 0.61, 0.63);
		} else {
			color.rgb = max(color.g, color.b) > 0.45
				? vec3(0.08, 0.50, 0.52) : vec3(0.04, 0.29, 0.31);
		}
		if (dot(glint, glint) < 1.0) {
			color.rgb = vec3(0.22, 0.67, 0.69);
		}
	} else {
		vec2 local_uv = (UV * vec2(1261.0, 1247.0) - vec2(279.0, 326.0))
			/ vec2(704.0, 658.0);
		vec2 glint = (local_uv - vec2(0.30, 0.27)) / vec2(0.055, 0.040);
		color.rgb = color.g > 0.45 && color.b > 0.35
			? vec3(0.82, 0.29, 0.31) : vec3(0.69, 0.16, 0.19);
		if (dot(glint, glint) < 1.0) {
			color.rgb = vec3(0.88, 0.33, 0.35);
		}
	}
	COLOR = vec4(color.rgb, 1.0);
	}
}
