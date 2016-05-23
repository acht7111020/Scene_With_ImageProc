#version 420

layout(location = 0) in vec2 iv3vertex;
layout(location = 1) in vec2 iv2texcoor;

out VS_OUT
	{
		vec2 texcoord;
	} fs_out;

void main()
{
	gl_Position = vec4(iv3vertex, 0.0, 1.0);

	fs_out.texcoord = iv2texcoor;
}