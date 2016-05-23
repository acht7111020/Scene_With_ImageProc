#version 420
layout (binding = 0) uniform sampler2D tex; 
layout (binding = 1) uniform sampler2D noise_map;
uniform int shader_now ;
uniform int magflag;
uniform int comflag;
uniform float CompareBarX ;
uniform vec2 img_size;
uniform vec2 mouse_pos;
uniform float time;
out vec4 color;

in VS_OUT
	{
		vec2 texcoord;
	} fs_in;
float sigma_e = 2.0f;
float sigma_r = 2.8f;
float phi = 3.4f;
float tau = 0.99f;
float twoSigmaESquared = 2.0 * sigma_e * sigma_e;
float twoSigmaRSquared = 2.0 * sigma_r * sigma_r;
int halfWidth = int(ceil( 2.0 * sigma_r ));
float rt_w = img_size.x; 
float rt_h = img_size.y;


int nbins = 8;

vec4 oilpainting(){
	int uni_Radius = 3;
	float lRadiusSquare = float((uni_Radius + 1) * (uni_Radius + 1));
    vec3 lColor[4];
    vec3 lColorSquare[4];
	vec4 out_Color;
    for (int lIndex = 0; lIndex < 4; lIndex++)
    {
        lColor[lIndex] = vec3(0.0f);
        lColorSquare[lIndex] = vec3(0.0f);
    }

    for (int j = -uni_Radius; j <= 0; j++)
    {
        for (int i = -uni_Radius; i <= 0; i++)
        {
            vec3    lTexColor = texture2D(tex, fs_in.texcoord + vec2(i, j) / img_size).rgb;
            lColor[0] += lTexColor;
            lColorSquare[0] += lTexColor * lTexColor;
        }
    }

    for (int j = -uni_Radius; j <= 0; j++)
    {
        for (int i = 0; i <= uni_Radius; i++)
        {
            vec3    lTexColor = texture2D(tex, fs_in.texcoord + vec2(i, j) / img_size).rgb;
            lColor[1] += lTexColor;
            lColorSquare[1] += lTexColor * lTexColor;
        }
    }

    for (int j = 0; j <= uni_Radius; j++)
    {
        for (int i = 0; i <= uni_Radius; i++)
        {
            vec3    lTexColor = texture2D(tex, fs_in.texcoord + vec2(i, j) / img_size).rgb;
            lColor[2] += lTexColor;
            lColorSquare[2] += lTexColor * lTexColor;
        }
    }

    for (int j = 0; j <= uni_Radius; j++)
    {
        for (int i = -uni_Radius; i <= 0; i++)
        {
            vec3    lTexColor = texture2D(tex, fs_in.texcoord + vec2(i, j) / img_size).rgb;
            lColor[3] += lTexColor;
            lColorSquare[3] += lTexColor * lTexColor;
        }
    }

    float   lMinSigma = 4.71828182846;

    for (int i = 0; i < 4; i++)
    {
        lColor[i] /= lRadiusSquare;
        lColorSquare[i] = abs(lColorSquare[i] / lRadiusSquare - lColor[i] * lColor[i]);
        float   lSigma = lColorSquare[i].r + lColorSquare[i].g + lColorSquare[i].b;
        if (lSigma < lMinSigma)
        {
            lMinSigma = lSigma;
            out_Color = vec4(lColor[i], texture2D(tex, fs_in.texcoord).a);
        }
    }
	return out_Color;
}

vec4 spline(float x, vec4 c1, vec4 c2, vec4 c3, vec4 c4, vec4 c5, vec4 c6, vec4 c7, vec4 c8, vec4 c9)
{
	float w1, w2, w3, w4, w5, w6, w7, w8, w9;
	w1 = 0.0;
	w2 = 0.0;
	w3 = 0.0;
	w4 = 0.0;
	w5 = 0.0;
	w6 = 0.0;
	w7 = 0.0;
	w8 = 0.0;
	w9 = 0.0;
	float tmp = x * 8.0;
	if (tmp<=1.0) {
		w1 = 1.0 - tmp;
		w2 = tmp;
	}
	else if (tmp<=2.0) {
		tmp = tmp - 1.0;
		w2 = 1.0 - tmp;
		w3 = tmp;
	}
	else if (tmp<=3.0) {
		tmp = tmp - 2.0;
		w3 = 1.0-tmp;
		w4 = tmp;
	}
	else if (tmp<=4.0) {
		tmp = tmp - 3.0;
		w4 = 1.0-tmp;
		w5 = tmp;
	}
	else if (tmp<=5.0) {
		tmp = tmp - 4.0;
		w5 = 1.0-tmp;
		w6 = tmp;
	}
	else if (tmp<=6.0) {
		tmp = tmp - 5.0;
		w6 = 1.0-tmp;
		w7 = tmp;
	}
	else if (tmp<=7.0) {
		tmp = tmp - 6.0;
		w7 = 1.0 - tmp;
		w8 = tmp;
	}
	else 
	{
		//tmp = saturate(tmp - 7.0);
		// http://www.ozone3d.net/blogs/lab/20080709/saturate-function-in-glsl/
		tmp = clamp(tmp - 7.0, 0.0, 1.0);
		w8 = 1.0-tmp;
		w9 = tmp;
	}
	return w1*c1 + w2*c2 + w3*c3 + w4*c4 + w5*c5 + w6*c6 + w7*c7 + w8*c8 + w9*c9;
}
 
vec3 NOISE2D(vec2 p)
  { return texture2D(noise_map,p).xyz; }

vec4 FrostGlass(){
	float vx_offset;
	float PixelX = 2.0;
	float PixelY = 2.0;
	float Freq = 10.115;

	vec3 tc = vec3(1.0, 0.0, 0.0);
    
	float DeltaX = PixelX / 1024;
	float DeltaY = PixelY / 1024;
	vec2 ox = vec2(DeltaX,0.0);
	vec2 oy = vec2(0.0,DeltaY);
	vec2 PP = fs_in.texcoord - oy;
	vec4 C00 = texture2D(tex,PP - ox);
	vec4 C01 = texture2D(tex,PP);
	vec4 C02 = texture2D(tex,PP + ox);
	PP = fs_in.texcoord;
	vec4 C10 = texture2D(tex,PP - ox);
	vec4 C11 = texture2D(tex,PP);
	vec4 C12 = texture2D(tex,PP + ox);
	PP = fs_in.texcoord + oy;
	vec4 C20 = texture2D(tex,PP - ox);
	vec4 C21 = texture2D(tex,PP);
	vec4 C22 = texture2D(tex,PP + ox);
    
	float n = NOISE2D(Freq*fs_in.texcoord).x;
	n = mod(n, 0.111111)/0.111111;
	vec4 result = spline(n,C00,C01,C02,C10,C11,C12,C20,C21,C22);
	tc = result.rgb;  
	
	return vec4(tc, 1.0);

}

vec4 Ripple(){
	vec2 p = -1.0 + 2.0 * fs_in.texcoord;
	float len = length(p);
	vec2 uv = fs_in.texcoord + (p/len)*cos(len*12.0-time/20*3.0)*0.03;
	vec3 col = texture2D(tex, uv).xyz;
	return vec4(col,1.0); 
	
}
vec4 Swirl()
{
	
	// Swirl effect parameters
	float radius = 400.0;
	float angle = 1.8;
	vec2 center = vec2(img_size.x/2, img_size.y/2);
	vec2 texSize = vec2(rt_w, rt_h);
	vec2 tc = fs_in.texcoord * texSize;
	tc -= center;
	float dist = length(tc);
	if (dist < radius) 
	{
	float percent = (radius - dist) / radius;
	float theta = percent * percent * angle * 8.0;
	float s = sin(theta);
	float c = cos(theta);
	tc = vec2(dot(tc, vec2(c, -s)), dot(tc, vec2(s, c)));
	}
	tc += center;
	vec3 color = texture2D(tex, tc / texSize).rgb;
	return vec4(color, 1.0);
}

vec4 Watercolor(){
// 0.15 0.15 0.65 0.02 0.02 0.2 0.7 0.1
	float gradientStep = 0.1;
	float advectStep = 0.05 ;
	float flipHeightMap = 0.7 ;
	float expand = 0.05;
	vec4 advectMatrix = vec4 (0.1);
	vec4 cxp = texture2D(noise_map, vec2(fs_in.texcoord.x + gradientStep, flipHeightMap*fs_in.texcoord.y));
	vec4 cxn = texture2D(noise_map, vec2(fs_in.texcoord.x - gradientStep, flipHeightMap*fs_in.texcoord.y));
	vec4 cyp = texture2D(noise_map, vec2(fs_in.texcoord.x, flipHeightMap*(fs_in.texcoord.y + gradientStep)));
	vec4 cyn = texture2D(noise_map, vec2(fs_in.texcoord.x, flipHeightMap*(fs_in.texcoord.y - gradientStep)));

	vec3 grey = vec3(.3, .59, .11);
	float axp = dot(grey, cxp.xyz);
	float axn = dot(grey, cxn.xyz);
	float ayp = dot(grey, cyp.xyz);
	float ayn = dot(grey, cyn.xyz);

	vec2 grad = vec2(axp - axn, ayp - ayn);
	vec2 newtc = fs_in.texcoord + advectStep * normalize(advectMatrix.xy * grad) * expand;

	return vec4(texture2D(tex, newtc).rgb, 1 );


}
vec4 Contrast(){
	float T = 2.0;
    vec2 st = fs_in.texcoord.st;
    vec3 irgb = texture2D(tex, st).rgb;
    vec3 target = vec3(0.5, 0.5, 0.5);
    return vec4(mix(target, irgb, T), 1.);

}
vec4 Embossion(){
	vec3 irgb = texture2D(tex, fs_in.texcoord).rgb;
    float ResS = 720.;
    float ResT = 720.;

    vec2 stp0 = vec2(1./ResS, 0.);
    vec2 stpp = vec2(1./ResS, 1./ResT);
    vec3 c00 = texture2D(tex, fs_in.texcoord).rgb;
    vec3 cp1p1 = texture2D(tex, fs_in.texcoord + stpp).rgb;

    vec3 diffs = c00 - cp1p1;
    float max = diffs.r;
    if(abs(diffs.g)>abs(max)) max = diffs.g;
    if(abs(diffs.b)>abs(max)) max = diffs.b;

    float gray = clamp(max + .5, 0., 1.);
    vec3 color = vec3(gray, gray, gray);

    return vec4(mix(color,c00, 0.1), 1.);

}
vec4 Toon(){
	float ResS = 720.;
	float ResT = 720.;
	float MagTol = .5;
	float Quantize = 10.;
	
	vec3 irgb = texture2D(tex, fs_in.texcoord ).rgb;
	vec2 stp0 = vec2(1./ResS, 0.);
	vec2 st0p = vec2(0., 1./ResT);
	vec2 stpp = vec2(1./ResS, 1./ResT);
	vec2 stpm = vec2(1./ResS, -1./ResT);
	vec4 gl_FragColor;

	const vec3 W = vec3(0.2125, 0.7154, 0.0721);
	float i00 = 	dot(texture2D(tex, fs_in.texcoord ).rgb, W);
	float im1m1 =	dot(texture2D(tex, fs_in.texcoord -stpp).rgb, W);
	float ip1p1 = 	dot(texture2D(tex, fs_in.texcoord +stpp).rgb, W);
	float im1p1 = 	dot(texture2D(tex, fs_in.texcoord -stpm).rgb, W);
	float ip1m1 = 	dot(texture2D(tex, fs_in.texcoord +stpm).rgb, W);
	float im10 = 	dot(texture2D(tex, fs_in.texcoord -stp0).rgb, W);
	float ip10 = 	dot(texture2D(tex, fs_in.texcoord +stp0).rgb, W);
	float i0m1 = 	dot(texture2D(tex, fs_in.texcoord -st0p).rgb, W);
	float i0p1 = 	dot(texture2D(tex, fs_in.texcoord +st0p).rgb, W);
	
	//H and V sobel filters
	float h = -1.*im1p1 - 2.*i0p1 - 1.*ip1p1 + 1.*im1m1 + 2.*i0m1 + 1.*ip1m1;
	float v = -1.*im1m1 - 2.*im10 - 1.*im1p1 + 1.*ip1m1 + 2.*ip10 + 1.*ip1p1;
	float mag = length(vec2(h, v));
	
	if(mag > MagTol){
		gl_FragColor = vec4(0., 0., 0., 1.);
	}else{
		irgb.rgb *= Quantize;
		irgb.rgb += vec3(.5,.5,.5);
		ivec3 intrgb = ivec3(irgb.rgb);
		irgb.rgb = vec3(intrgb)/Quantize;
		gl_FragColor = vec4(irgb, 1.);
	}
	return gl_FragColor;
}

vec4 Pixelation(){
	vec2 uv = fs_in.texcoord.xy;

	vec3 tc = vec3(1.0, 0.0, 0.0);
	
		float dx = 0.007;
		float dy = 0.007;
		vec2 coord = vec2(dx*floor(uv.x/dx), dy*floor(uv.y/dy));
		tc = texture2D(tex, coord).rgb;
	
	return vec4(tc, 1.0);
}
vec4 Laplacian(){

	float tmpcolor = 0;	
	int half_size = 1;
	for ( int i = -half_size; i <= half_size; ++i ) {      
		for ( int j = -half_size; j <= half_size; ++j ) {
				float c;
				vec4 texture_color = texture(tex,fs_in.texcoord + vec2(i,j)/img_size);
				float grayscale_color = 0.2126*texture_color.r+0.7152*texture_color.g+0.0722*texture_color.b;
				if(i == 0 && j == 0)
					c = grayscale_color*8; 
				else 
					c = grayscale_color*-1; 
				tmpcolor+= c;
			}
		}

	float edge = ( tmpcolor > 0.3 )? 1.0 : 0.0;

	return vec4(edge,edge,edge,1.0 );

}

vec4 Sharpen(){

	vec4 tmpcolor = vec4(0);	
	int half_size = 1;
	int n = 0;
	for ( int i = -half_size; i <= half_size; ++i ) {      
		for ( int j = -half_size; j <= half_size; ++j ) {
				vec4 c;
				vec4 texture_color = texture(tex,fs_in.texcoord + vec2(i,j)/img_size);
				if(i == 0 && j == 0)
					c = texture_color*9; 
				else 
					c = texture_color*-1; 
				tmpcolor+= c;				
			}
		}
	
	return vec4(tmpcolor.r,tmpcolor.g,tmpcolor.b,1.0 );

}
vec4 RedBlue(){

	float offset = 0.005;
	vec4 Left_Color = texture(tex, vec2(fs_in.texcoord.x-offset, fs_in.texcoord.y));
	vec4 Right_Color = texture(tex, vec2(fs_in.texcoord.x+offset, fs_in.texcoord.y));
	
	float Color_R = Left_Color.r*0.299 + Left_Color.g*0.587 + Left_Color.b*0.114;
	float Color_G = Right_Color.g;
	float Color_B = Right_Color.b;
	return vec4(Color_R,Color_G,Color_B,1.0);

}
vec4 Dog(){
	vec2 sum = vec2(0.0);
	vec2 norm = vec2(0.0);
	int kernel_count = 0;
	for ( int i = -halfWidth; i <= halfWidth; ++i ) {
		for ( int j = -halfWidth; j <= halfWidth; ++j ) {
				float d = length(vec2(i,j));
				vec2 kernel = vec2( exp( -d * d / twoSigmaESquared ),
									exp( -d * d / twoSigmaRSquared ));
				vec4 c = texture(tex, fs_in.texcoord + vec2(i,j) / img_size);
				vec2 L = vec2(0.299 * c.r + 0.587 * c.g + 0.114 * c.b);
													
				norm += 2.0 * kernel;
				sum += kernel * L;
			}
	}
	sum /= norm;

	float H = 100.0 * (sum.x - tau * sum.y);
	float edge = ( H > 0.0 )? 1.0 : 2.0 * smoothstep(-2.0, 2.0, phi * H );

	return vec4(edge,edge,edge,1.0 );

}
vec4 quantization(){
	vec4 texture_color = texture(tex,fs_in.texcoord);

	float r = floor(texture_color.r * float(nbins)) / float(nbins);
	float g = floor(texture_color.g * float(nbins)) / float(nbins);
	float b = floor(texture_color.b * float(nbins)) / float(nbins);
	return vec4(r,g,b,texture_color.a);

}

vec4 blurred(int half_size){
	vec4 tmpcolor = vec4(0);	
	int n = 0;
	//int half_size = 5;
	for ( int i = -half_size; i <= half_size; ++i ) {      
		for ( int j = -half_size; j <= half_size; ++j ) {
				vec4 c = texture(tex, fs_in.texcoord + vec2(i,j)/img_size); 
				tmpcolor+= c;
				n++;
			}
		}
	tmpcolor /= n;
	return tmpcolor;

}

void main(void)
{
	float x_dist = fs_in.texcoord.x - mouse_pos.x;
	float y_dist = fs_in.texcoord.y - mouse_pos.y;
	float dist = sqrt(x_dist* x_dist+ y_dist* y_dist);
	if(magflag == 1 && dist < 0.1 && dist > 0){
		float newX = mouse_pos.x + x_dist *0.5;
		float newY = mouse_pos.y + y_dist *0.5;
		fs_in.texcoord = vec2(newX, newY);
	}
	if(fs_in.texcoord.x < (CompareBarX - 0.003) || comflag == 0){
		switch(shader_now)
		{
			case(16):
				{
					vec4 mycolor = Watercolor();
					float graycolor = 0.2126*mycolor.r+0.7152*mycolor.g+0.0722*mycolor.b;;
					graycolor = floor(graycolor*5)/5;
					color = vec4(graycolor, graycolor, graycolor, 1);
					break;
				}
			case(15):
				{
					color = oilpainting();
					break;
				}
			case(14):
				{
					color = FrostGlass();
					break;
				}
			case(13):
				{
					color = Ripple();
					break;
				}
			case(12):
				{
					color = Swirl();
					break;
				}
			case(11):
				{
					color = Watercolor();
					break;
				}
			case(10):
				{
					color = Embossion();
					break;
				}
			case(9):
				{
					color = Contrast();
					break;
				}
			case(8):
				{
					color = Pixelation();
					break;
				}
			case(7):
				{
					color = texture(tex, fs_in.texcoord)+ blurred(2)*0.3 + blurred(3)*0.3;
					break;
				}
			case(6):
				{
					color = Laplacian();
					break;
				}
			case(5):
				{
					color = Sharpen();
					break;
				}
			case(4):
				{
					color = RedBlue();
					break;
				}
			case(3):
				{
					color = ( (quantization()+blurred(3))/2 * Dog() );
					/*vec4 texture_color = (Combination() * Dog() );

					float r = floor(texture_color.r * 256) / 256;
					float g = floor(texture_color.g * 256) / 256;
					float b = floor(texture_color.b * 256) / 256;
					color = vec4(r,g,b,texture_color.a);*/
					break;
				}
			case(2):
				{
					color = Dog();
					break;
				}
			case(1):
				{
					color = quantization();
					break;
				}
			case(0):
				{
					color = blurred(2);
					//color = oilpainting();
					
					break;
				}


		}
	}
	else if(fs_in.texcoord.x > (CompareBarX + 0.003)){
		color = texture(tex, fs_in.texcoord);
	}
	else
		color = vec4(0.597, 1, 1, 1); 
}