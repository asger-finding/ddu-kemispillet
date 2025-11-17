shader_type canvas_item;

uniform float opacity : hint_range(0.0, 1.0) = 0.2;
uniform int blend_mode : hint_range(0, 4) = 1;

// Blend mode options:
// 0 = Normal
// 1 = Multiply (good for paper)
// 2 = Overlay
// 3 = Soft Light (very subtle)
// 4 = Hard Light

vec3 blend_multiply(vec3 base, vec3 blend) {
    return base * blend;
}

vec3 blend_overlay(vec3 base, vec3 blend) {
    vec3 result;
    result.r = base.r < 0.5 ? (2.0 * base.r * blend.r) : (1.0 - 2.0 * (1.0 - base.r) * (1.0 - blend.r));
    result.g = base.g < 0.5 ? (2.0 * base.g * blend.g) : (1.0 - 2.0 * (1.0 - base.g) * (1.0 - blend.g));
    result.b = base.b < 0.5 ? (2.0 * base.b * blend.b) : (1.0 - 2.0 * (1.0 - base.b) * (1.0 - blend.b));
    return result;
}

vec3 blend_soft_light(vec3 base, vec3 blend) {
    vec3 result;
    result.r = blend.r < 0.5 ? (base.r - (1.0 - 2.0 * blend.r) * base.r * (1.0 - base.r)) :
               (base.r + (2.0 * blend.r - 1.0) * (sqrt(base.r) - base.r));
    result.g = blend.g < 0.5 ? (base.g - (1.0 - 2.0 * blend.g) * base.g * (1.0 - base.g)) :
               (base.g + (2.0 * blend.g - 1.0) * (sqrt(base.g) - base.g));
    result.b = blend.b < 0.5 ? (base.b - (1.0 - 2.0 * blend.b) * base.b * (1.0 - base.b)) :
               (base.b + (2.0 * blend.b - 1.0) * (sqrt(base.b) - base.b));
    return result;
}

vec3 blend_hard_light(vec3 base, vec3 blend) {
    vec3 result;
    result.r = blend.r < 0.5 ? (2.0 * base.r * blend.r) : (1.0 - 2.0 * (1.0 - base.r) * (1.0 - blend.r));
    result.g = blend.g < 0.5 ? (2.0 * base.g * blend.g) : (1.0 - 2.0 * (1.0 - base.g) * (1.0 - blend.g));
    result.b = blend.b < 0.5 ? (2.0 * base.b * blend.b) : (1.0 - 2.0 * (1.0 - base.b) * (1.0 - blend.b));
    return result;
}

void fragment() {
    // Get the texture color
    vec4 tex_color = texture(TEXTURE, UV);

    // Apply opacity
    tex_color.a *= opacity;

    // Get the background color (what's behind this control)
    vec4 bg_color = vec4(1.0, 1.0, 1.0, 1.0); // Default white background

    // Apply blending based on selected mode
    vec3 blended_color;

    if (blend_mode == 0) {
        // Normal blend
        blended_color = tex_color.rgb;
    } else if (blend_mode == 1) {
        // Multiply blend (darkens - good for paper)
        blended_color = blend_multiply(bg_color.rgb, tex_color.rgb);
    } else if (blend_mode == 2) {
        // Overlay blend
        blended_color = blend_overlay(bg_color.rgb, tex_color.rgb);
    } else if (blend_mode == 3) {
        // Soft Light blend (subtle)
        blended_color = blend_soft_light(bg_color.rgb, tex_color.rgb);
    } else if (blend_mode == 4) {
        // Hard Light blend
        blended_color = blend_hard_light(bg_color.rgb, tex_color.rgb);
    } else {
        blended_color = tex_color.rgb;
    }

    COLOR = vec4(blended_color, tex_color.a);
}