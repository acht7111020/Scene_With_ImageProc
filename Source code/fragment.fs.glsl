#version 410

in vec3 vv3color;
uniform sampler2D S;
layout(location = 0) out vec4 fragColor;

uniform int changemode;

void main()
{
	if(changemode == 0){
		vec2 vv2cor = vec2(vv3color);
		//fragColor = vec4(texture(S, vv3color).rgb, 1.0);
		//fragColor = vec4(vv3color, 1);
		vec4 texColor = texture(S, vv2cor).rgba;
		if(texColor.a < 0.5)
			discard;
		fragColor = vec4(texture(S, vv2cor).rgb, 1.0);
	}
	else
		fragColor = vec4(vv3color, 1);
}