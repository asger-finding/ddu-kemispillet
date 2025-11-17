shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float vignette_strength : hint_range(0.0, 2.0) = 1.0;
uniform float vignette_radius   : hint_range(0.0, 1.0) = 0.75;
uniform vec2 camera_zoom = vec2(1.0, 1.0);
uniform float grayscale_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 col = texture(screen_tex, SCREEN_UV);

	float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	col.rgb = mix(col.rgb, vec3(gray), grayscale_amount);

	vec2 uv = SCREEN_UV * 2.0 - 1.0;
	uv *= camera_zoom;
	float dist = length(uv);

	float vignette = smoothstep(vignette_radius, vignette_radius - vignette_strength * 0.5, dist);
	col.rgb *= vignette;

	COLOR = col;
}
