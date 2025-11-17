shader_type canvas_item;

// Adjustable parameters
uniform float paper_scale : hint_range(0.1, 5.0) = 1.0;
uniform float wrinkle_strength : hint_range(0.0, 1.0) = 0.3;
uniform float crease_intensity : hint_range(0.0, 2.0) = 0.8;
uniform vec3 paper_color : source_color = vec3(0.95, 0.92, 0.85);
uniform vec3 shadow_color : source_color = vec3(0.7, 0.68, 0.6);
uniform float noise_scale : hint_range(1.0, 50.0) = 15.0;
uniform float detail_scale : hint_range(50.0, 200.0) = 80.0;
uniform vec2 camera_offset = vec2(0.0, 0.0);
uniform float parallax_strength : hint_range(0.0, 1.0) = 0.2;

// Simple noise function
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Enhanced noise function for more organic patterns
float enhanced_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    // Use smoother interpolation for more organic feel
    f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Improved fractal noise with rotation for more organic patterns
float organic_fbm(vec2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    mat2 rotation = mat2(vec2(cos(0.5), sin(0.5)), vec2(-sin(0.5), cos(0.5)));

    for (int i = 0; i < octaves; i++) {
        value += amplitude * enhanced_noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
        p = rotation * p; // Rotate for more organic patterns
    }

    return value;
}

// Generate paper wrinkles with organic shapes
float paper_wrinkles(vec2 uv) {
    vec2 offset_uv = uv + camera_offset * parallax_strength * 0.01;

    // Large organic wrinkles
    float wrinkle1 = organic_fbm(offset_uv * noise_scale * 0.3, 4);

    // Medium creases with different rotation
    float wrinkle2 = organic_fbm((offset_uv + vec2(100.0, 50.0)) * noise_scale * 0.8, 3);

    // Fine details
    float detail = organic_fbm((offset_uv + vec2(200.0, 300.0)) * detail_scale, 2);

    // Create flowing, curved creases
    float flow_pattern = sin(offset_uv.x * noise_scale * 0.5 + wrinkle1 * 6.28) *
                        cos(offset_uv.y * noise_scale * 0.7 + wrinkle2 * 6.28);

    // Combine different scales with flow pattern
    float combined = wrinkle1 * 0.5 + wrinkle2 * 0.3 + detail * 0.1 + flow_pattern * 0.1;

    // Create softer, more organic creases
    combined = smoothstep(0.2, 0.8, combined);

    return combined;
}

// Generate paper fiber texture
float paper_fibers(vec2 uv) {
    vec2 offset_uv = uv + camera_offset * parallax_strength * 0.01;

    // Horizontal fibers
    float fiber1 = enhanced_noise(vec2(offset_uv.x * detail_scale * 2.0, offset_uv.y * detail_scale * 0.1));

    // Vertical fibers
    float fiber2 = enhanced_noise(vec2(offset_uv.x * detail_scale * 0.1, offset_uv.y * detail_scale * 2.0));

    // Random fiber directions with organic noise
    float fiber3 = organic_fbm(offset_uv * detail_scale * 0.5, 2);

    return (fiber1 + fiber2 + fiber3) / 3.0;
}

void fragment() {
    vec2 uv = UV * paper_scale;

    // Generate base wrinkle pattern
    float wrinkles = paper_wrinkles(uv);

    // Generate paper fiber texture
    float fibers = paper_fibers(uv);

    // Combine wrinkles and fibers
    float surface_variation = mix(fibers * 0.3, wrinkles, wrinkle_strength);

    // Create lighting effect based on surface variation
    vec2 gradient = vec2(
        dFdx(surface_variation),
        dFdy(surface_variation)
    );

    // Calculate lighting
    float lighting = 1.0 - length(gradient) * crease_intensity;
    lighting = clamp(lighting, 0.0, 1.0);

    // Apply lighting to paper color
    vec3 final_color = mix(shadow_color, paper_color, lighting);

    // Add subtle color variation with parallax
    float color_variation = organic_fbm((uv + camera_offset * parallax_strength * 0.01) * noise_scale * 2.0, 2) * 0.1;
    final_color += vec3(color_variation);

    // Slight aging effect with parallax
    float aging = organic_fbm((uv + camera_offset * parallax_strength * 0.01) * noise_scale * 0.5, 2) * 0.05;
    final_color -= vec3(aging * 0.5, aging * 0.3, aging * 0.1);

    COLOR = vec4(final_color, 1.0);
}