shader_type canvas_item;
uniform sampler2D noise: repeat_enable;
void fragment() {
	// Called for every pixel the material is visible on.
	vec4 t = texture(TEXTURE, UV);
	vec4 n = texture(noise, UV);
	
	t.a -= t.r;
	t.rgb = n.rgb;
	COLOR = t;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}