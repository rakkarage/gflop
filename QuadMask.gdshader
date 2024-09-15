shader_type spatial;

uniform sampler2D texture: source_color;
uniform mat4 mask_transform = mat4(1.0);
uniform vec2 mask_size = vec2(1.0);

const int NUM_CORNERS = 4;
varying vec4 mask_corners[NUM_CORNERS];

void vertex() {
	vec2 half_size = mask_size * 0.5;
	vec4 corners[NUM_CORNERS] = {
		vec4(-half_size.x, -half_size.y, 0.0, 1.0),
		vec4(half_size.x, -half_size.y, 0.0, 1.0),
		vec4(half_size.x, half_size.y, 0.0, 1.0),
		vec4(-half_size.x, half_size.y, 0.0, 1.0)
	};

	for (int i = 0; i < NUM_CORNERS; i++) {
		mask_corners[i] = PROJECTION_MATRIX * VIEW_MATRIX * mask_transform * corners[i];
	}
}

bool point_in_triangle(vec2 p, vec2 a, vec2 b, vec2 c) {
	vec2 v0 = c - a, v1 = b - a, v2 = p - a;
	float den = v0.x * v1.y - v1.x * v0.y;
	float v = (v2.x * v1.y - v1.x * v2.y) / den;
	float w = (v0.x * v2.y - v2.x * v0.y) / den;
	float u = 1.0 - v - w;
	return u >= 0.0 && v >= 0.0 && w >= 0.0;
}

void fragment() {
	vec2 clip_pos = SCREEN_UV * 2.0 - 1.0;

	bool inside = point_in_triangle(clip_pos, mask_corners[0].xy / mask_corners[0].w,
											  mask_corners[1].xy / mask_corners[1].w,
											  mask_corners[2].xy / mask_corners[2].w) ||
				  point_in_triangle(clip_pos, mask_corners[0].xy / mask_corners[0].w,
											  mask_corners[2].xy / mask_corners[2].w,
											  mask_corners[3].xy / mask_corners[3].w);

	if (!inside) {
		discard;
	}

	vec4 tex_color = texture(texture, UV);
	ALBEDO = tex_color.rgb;
	ALPHA = tex_color.a;
}
