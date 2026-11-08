shader_type canvas_item;

uniform float speed = 3.0;
uniform float intensity : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float pulse = sin(TIME * speed) * 0.5 + 0.5;
	vec3 boosted = tex.rgb * (1.0 + pulse * intensity);
	COLOR = vec4(boosted, tex.a);
}
