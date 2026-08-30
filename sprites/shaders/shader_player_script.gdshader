shader_type canvas_item;

uniform float saturation = 1.0;
uniform float brightness = 1.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	
	//Saturação do personagem
	float gray = dot(color.rgb, vec3(0.299,0.587, 0.114));
	color.rgb = mix(vec3(gray), color.rgb, saturation);
	
	//Brilho do personagem
	color.rgb *= brightness;
	COLOR = color;
}