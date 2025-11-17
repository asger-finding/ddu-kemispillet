extends TileMapLayer

@export var line_color = Vector3(0.6, 0.6, 0.67)
@export var shadow_color = Color(0, 0, 0, 0.3)

var shader_material: ShaderMaterial

func _ready() -> void:
	var shader_code := '''
shader_type canvas_item;
render_mode world_vertex_coords;

// Paper settings
uniform float tile_size = 32.0;
uniform float line_width = 1.0;
uniform vec3 line_color = vec3(0.6);
uniform float noise_strength = 0.05;

// Shadow settings
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.2);
uniform float blur_std = 1.0;

// Precomputed constants
const float SQRT_PI = 1.77245385;
const float SQRT_2 = 1.41421356;
const vec2 NOISE_SEED = vec2(12.9898, 78.233);
const float NOISE_MULT = 43758.5453;

float fast_erf(float x) {
	float x2 = x * x;
	float x3 = x2 * x;
	float x4 = x2 * x2;
	return sign(x) * (1.0 - exp(-x2 * (1.27324 + 0.14001 * x2) / (1.0 + 0.14001 * x2 + 0.01008 * x4)));
}

float gaussian_cdf_diff(float x1, float x2) {
	float inv_sqrt2_std = 1.0 / (SQRT_2 * blur_std);
	return 0.5 * (fast_erf(x2 * inv_sqrt2_std) - fast_erf(x1 * inv_sqrt2_std));
}

varying vec4 pos;
varying mat4 canvas_matrix;
varying vec4 modulate;

void vertex() {
	pos = vec4(VERTEX, 0.0, 0.0);
	canvas_matrix = CANVAS_MATRIX;
	modulate = COLOR;
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	
	// Make early exit if completely transparent
	if (base.a <= 0.001) {
		COLOR = vec4(0.0);
		discard;
	}
	
	// ==== PAPER EFFECT ====
	// World position calculation matching old behavior
	float resizeRatio = SCREEN_PIXEL_SIZE.x * 1024.0;
	vec4 screenspace = canvas_matrix * pos;
	vec2 globalPos = (resizeRatio * screenspace).xy;
	
	vec2 grid_pos = globalPos / tile_size;
	vec2 fract_pos = fract(grid_pos);
	vec2 dist_to_edge = min(fract_pos, 1.0 - fract_pos);
	
	float pixel_w = line_width / tile_size;
	vec2 anti = fwidth(grid_pos);
	
	float lineX = 1.0 - smoothstep(pixel_w - anti.x, pixel_w + anti.x, dist_to_edge.x);
	float lineY = 1.0 - smoothstep(pixel_w - anti.y, pixel_w + anti.y, dist_to_edge.y);
	float lineAlpha = clamp(lineX + lineY, 0.0, 1.0);
	
	// Apply line effect
	vec3 paper_rgb = mix(base.rgb, line_color, lineAlpha);
	
	// Fast noise using optimized hash
	float n = fract(sin(dot(globalPos, NOISE_SEED)) * NOISE_MULT);
	paper_rgb *= (1.0 - n * noise_strength);
	
	vec4 paper_color = vec4(paper_rgb, base.a);
	
	// ==== SOFT SHADOW ====
	float blur_radius = ceil(blur_std * 3.0);
	
	// Skip shadow calculation if blur_std is very small
	if (blur_std < 0.1) {
		COLOR = paper_color * modulate;
	} else {
		float weight = 0.0;
		vec2 pixel_coord = fract(UV / TEXTURE_PIXEL_SIZE);
		
		// Reduced loop iterations with larger steps for performance
		float step_size = max(1.0, blur_radius / 8.0); // Adaptive step size
		
		for (float x = -blur_radius; x <= blur_radius; x += step_size) {
			for (float y = -blur_radius; y <= blur_radius; y += step_size) {
				vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE;
				vec2 sample_uv = UV + offset;
				
				// Bounds check
				if (sample_uv.x >= 0.0 && sample_uv.x <= 1.0 && sample_uv.y >= 0.0 && sample_uv.y <= 1.0) {
					float sample_alpha = texture(TEXTURE, sample_uv).a;
					if (sample_alpha > 0.01) {
						float weight_x = gaussian_cdf_diff(-pixel_coord.x + x, -pixel_coord.x + x + step_size);
						float weight_y = gaussian_cdf_diff(-pixel_coord.y + y, -pixel_coord.y + y + step_size);
						weight += weight_x * weight_y * sample_alpha;
					}
				}
			}
		}
		
		// Final composition
		vec4 shadow = vec4(shadow_color.rgb, shadow_color.a * weight * base.a);
		COLOR = mix(shadow, paper_color, base.a) * modulate;
	}
}
'''
	
	var shader = Shader.new()
	shader.code = shader_code

	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	shader_material.set_shader_parameter('line_color', line_color)
	shader_material.set_shader_parameter('shadow_color', shadow_color)
	shader_material.set_shader_parameter('blur_std', 1.0)

	material = shader_material

func _process(_delta: float) -> void:
	var camera = get_viewport().get_camera_2d()
	if camera and shader_material:
		var cam_zoom = camera.zoom.x
		shader_material.set_shader_parameter('tile_size', 12.0 * cam_zoom)
		shader_material.set_shader_parameter('line_width', 0.3 * cam_zoom)
