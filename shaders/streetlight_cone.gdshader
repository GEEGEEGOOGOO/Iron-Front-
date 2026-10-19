shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
void fragment() {
 float edge = pow(clamp(1.0 - abs(UV.x - 0.5) * 2.0, 0.0, 1.0), 1.5);
 ALBEDO = vec3(1.0, 0.73, 0.36);
 ALPHA = 0.12 * edge * (0.25 + UV.y * 0.75);
}
