// vignette_shader.gdshader
shader_type canvas_item;

// A cor da vinheta (a área escura). Pode ser alterada no Inspector.
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// O raio do círculo visível (0.0 = totalmente fechado, 1.0 = cobre a tela na altura)
uniform float radius = 0.1;

// A suavidade da borda do círculo
uniform float softness = 0.15;

// The viewport_size in pixels, set from script
uniform vec2 viewport_size;

void fragment() {
    // ## FIX 2: Add a safeguard against division by zero.
    // If viewport_size.y is 0 (before it's set by the script), this prevents a crash.
    float aspect_ratio = viewport_size.x / max(viewport_size.y, 1.0);

    // Calculate distance from the center, respecting the aspect ratio
    // The UV coordinates go from (0,0) at the top-left to (1,1) at the bottom-right.
    // The center is at (0.5, 0.5). We scale the UVs to make the distance calculation circular.
    vec2 scaled_uv = UV * vec2(aspect_ratio, 1.0);
    vec2 center = vec2(0.5 * aspect_ratio, 0.5);
    float dist = distance(scaled_uv, center);

    // Calculate the vignette alpha using smoothstep for a soft edge
    float alpha = smoothstep(radius, radius + softness, dist);

    // Apply the final color. The vignette is transparent in the middle and opaque outside.
    COLOR = vec4(vignette_color.rgb, vignette_color.a * alpha);
}