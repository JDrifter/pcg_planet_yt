shader_type spatial;

uniform float min_height;
uniform float max_height;
uniform sampler2D height_color : repeat_disable; //important to avoid redrawing the gradients over each other

varying float height;

void fragment() {
	float t = height / (max_height - min_height) - (min_height / (max_height-min_height)); //linear interpolation
	t += 0.1;
	vec3 color = texture(height_color, vec2(t, UV.y)).rgb;
	ALBEDO = color;
}
void vertex() {
	height = length(VERTEX);
}