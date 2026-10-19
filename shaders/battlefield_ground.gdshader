shader_type spatial;
uniform sampler2D surface_map : filter_linear_mipmap, repeat_enable;
uniform vec4 earth_color : source_color = vec4(0.30, 0.27, 0.21, 1.0);
uniform vec4 paving_color : source_color = vec4(0.39, 0.37, 0.31, 1.0);
uniform bool asphalt = false;
varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
 vec2 uv = world_pos.xz;
 float aggregate = texture(surface_map, uv * 0.20).r;
 float grit = texture(surface_map, uv * 1.2).r;
 // Separate service streets, earth verges and slab sidewalks at building fronts.
 float pavement = 1.0 - smoothstep(0.0, 0.20, abs(world_pos.z + 9.6) - 1.5);
 pavement = max(pavement, 1.0 - smoothstep(0.0, 0.20, abs(world_pos.z + 22.2) - 1.4));
 vec2 tiles = fract(uv * vec2(0.8, 1.0));
 float joints = 1.0 - smoothstep(0.012, 0.04, min(tiles.x, tiles.y));
 float rough_patch = smoothstep(0.28, 0.65, texture(surface_map, uv * 0.045).r);
 vec3 base = asphalt ? earth_color.rgb : mix(earth_color.rgb, paving_color.rgb, pavement);
 ALBEDO = base * (0.83 + aggregate * 0.28 + grit * 0.07 - joints * pavement * 0.17 - rough_patch * 0.09);
 ROUGHNESS = 0.92;
 // Filtered, subtle aggregate relief; large surface shape is actual mesh geometry.
 NORMAL_MAP = normalize(vec3((texture(surface_map, uv * 0.20 + vec2(0.006,0)).r - aggregate) * 2.0, (texture(surface_map, uv * 0.20 + vec2(0,0.006)).r - aggregate) * 2.0, 1.0)) * 0.5 + 0.5;
 NORMAL_MAP_DEPTH = 0.4;
}
