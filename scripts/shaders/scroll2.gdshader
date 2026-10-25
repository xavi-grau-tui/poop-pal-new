shader_type canvas_item;

uniform float scroll_speed;
// (the shrine: its upper clouds a little lower, off the screen's edge, and its lower ones a little
// higher, off the floor; in UV, 0 = as painted)
uniform float top_down = 0.0;
uniform float bottom_up = 0.0;

void fragment (){
	vec2 shifteduv = UV;
	shifteduv.x += TIME * scroll_speed;
	shifteduv.y += UV.y < 0.5 ? -top_down : bottom_up;
	vec4 color = texture(TEXTURE, shifteduv);
	if (shifteduv.y < 0.0 || shifteduv.y > 1.0)
		color = vec4(0.0);
	COLOR = color;
}
