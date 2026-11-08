shader_type canvas_item;

uniform float amplitude = 0.008;
uniform float frequency = 18.0;
uniform float speed = 2.5;

void fragment() {
	vec2 uv = UV;
	uv.x += sin(UV.y * frequency + TIME * speed) * amplitude;
	COLOR = texture(TEXTURE, uv);
}
