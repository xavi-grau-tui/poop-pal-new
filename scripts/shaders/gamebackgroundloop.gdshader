shader_type canvas_item;

uniform vec2 scroll_speed = vec2(-1.0, 1.0);
uniform vec2 screen_size = vec2(256.0, 64.0);

void fragment() {
    vec2 uv = UV;
    uv -= TIME * scroll_speed / screen_size;
    uv = fract(uv);
    COLOR = texture(TEXTURE, uv);
}