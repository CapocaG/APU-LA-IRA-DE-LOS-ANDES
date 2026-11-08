shader_type canvas_item;

void fragment() {
	vec4 center = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE;
	vec3 average = (
		texture(TEXTURE, UV + vec2(px.x, 0.0)).rgb +
		texture(TEXTURE, UV - vec2(px.x, 0.0)).rgb +
		texture(TEXTURE, UV + vec2(0.0, px.y)).rgb +
		texture(TEXTURE, UV - vec2(0.0, px.y)).rgb
	) * 0.25;
	center.rgb = clamp(center.rgb + (center.rgb - average) * 0.45, vec3(0.0), vec3(1.0));
	COLOR = center;
}
