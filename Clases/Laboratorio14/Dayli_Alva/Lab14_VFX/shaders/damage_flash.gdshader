shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(1.0, 0.88, 0.58, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 rgb = mix(tex.rgb, flash_color.rgb, flash_amount);
	COLOR = vec4(rgb, tex.a);
}
