varying highp vec4 var_position;
varying mediump vec3 var_normal;
varying mediump vec2 var_texcoord0;
varying mediump vec4 var_light;

uniform lowp sampler2D tex0;
uniform lowp vec4 tint;

float gamma = 2.4;

vec3 linearToneMapping(vec3 color)
{
    float exposure = 1.;
    color = clamp(exposure * color, 0., 1.);
    color = pow(color, vec3(1. / gamma));
    return color;
}

vec3 simpleReinhardToneMapping(vec3 color)
{
    float exposure = 1.5;
    color *= exposure/(1. + color / exposure);
    color = pow(color, vec3(1. / gamma));
    return color;
}

vec3 whitePreservingLumaBasedReinhardToneMapping(vec3 color)
{
    float white = 2.;
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    float toneMappedLuma = luma * (1. + luma / (white*white)) / (1. + luma);
    color *= toneMappedLuma / luma;
    color = pow(color, vec3(1. / gamma));
    return color;
}

vec3 RomBinDaHouseToneMapping(vec3 color)
{
    color = exp( -1.0 / ( 2.72*color + 0.15 ) );
    color = pow(color, vec3(1. / gamma));
    return color;
}

void main()
{   
    // Pre-multiply alpha since all runtime textures already are
    vec4 color = texture2D(tex0, var_texcoord0.xy);
    color.rgb = linearToneMapping(color.rgb);
    vec2 pos = var_texcoord0.xy*2.0 - vec2(0.0,2.0);
    vec3 riverCol = mix(vec3(1.0),vec3(0.15,0.6,1.8),1.0-smoothstep(tint.w*0.25,tint.w*0.25+0.01,pos.y));
    color.rgb *= riverCol;
    gl_FragColor = vec4(color.rgb,1.0);
}

