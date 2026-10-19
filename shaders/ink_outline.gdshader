shader_type spatial;
render_mode cull_front, unshaded, shadows_disabled;
void vertex() { VERTEX += NORMAL * 0.012; }
void fragment() { ALBEDO = vec3(0.075, 0.060, 0.047); }
