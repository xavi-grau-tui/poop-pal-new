shader_type canvas_item;
render_mode unshaded;
varying vec4 plane_tint;
void vertex() {
    plane_tint = COLOR;
}
void fragment() {
    vec4 texel = texture(TEXTURE, UV);
    if (texel.a < 0.5) { discard; }
    COLOR = plane_tint * vec4(texel.rgb, 1.0);
}
