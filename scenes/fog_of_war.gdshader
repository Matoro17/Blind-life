shader_type canvas_item;

uniform vec2 sonar_origin = vec2(0.5, 0.5);
uniform float sonar_radius = 0.0;

void fragment() {
    float dist = distance(UV, sonar_origin);
    float alpha = dist < sonar_radius ? 0.0 : 1.0;
    COLOR = vec4(0.0, 0.0, 0.0, alpha);
}