shader_type spatial;
render_mode unshaded;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	ALBEDO = vec3(1.0);
	ALPHA = strength;
}
