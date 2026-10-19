shader_type spatial;
uniform vec4 tint : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform bool metal = false;
varying vec3 world_pos;
varying vec3 world_normal;
void vertex() {
 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
 world_normal = normalize(mat3(MODEL_MATRIX) * NORMAL);
}
void fragment() {
 vec3 n = abs(world_normal);
 vec2 uv = n.y > n.x && n.y > n.z ? world_pos.xz : (n.x > n.z ? world_pos.zy : world_pos.xy);
 float wave = sin(uv.x * 0.7) * sin(uv.y * 1.1);
 float shade = 0.95 + wave * 0.045 + smoothstep(0.0, 8.0, world_pos.y) * 0.06;
 ALBEDO = tint.rgb * shade;
 ROUGHNESS = metal ? 0.62 : 0.93;
 METALLIC = metal ? 0.2 : 0.0;
 RIM = 0.18;
 RIM_TINT = 0.4;
}
