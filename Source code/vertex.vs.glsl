#version 410

layout(location = 0) in vec3 iv3vertex;
layout(location = 1) in vec2 iv2texcoor;
layout(location = 2) in vec3 iv3normal;

uniform mat4 um4mvp;
uniform int changemode;

out vec3 vv3color;

void main()
{
	gl_Position = um4mvp * vec4(iv3vertex, 1.0);
	if(changemode == 0)
		vv3color = vec3(iv2texcoor, 1);
	else
		vv3color = iv3normal;
}