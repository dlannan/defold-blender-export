-- -----  MIT license ------------------------------------------------------------
-- Copyright (c) 2022 David Lannan

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
------------------------------------------------------------------------------------------------------------
-- Source ShaderToy: https://www.shadertoy.com/view/lslGzl
-- This shader experiments the effect of different tone mapping operators.
-- This is still a work in progress.

-- More info:
-- http://slideshare.net/ozlael/hable-john-uncharted2-hdr-lighting
-- http://filmicgames.com/archives/75
-- http://filmicgames.com/archives/183
-- http://filmicgames.com/archives/190
-- http://imdoingitwrong.wordpress.com/2010/08/19/why-reinhard-desaturates-my-blacks-3/
-- http://mynameismjp.wordpress.com/2010/04/30/a-closer-look-at-tone-mapping/
-- http://renderwonk.com/publications/s2010-color-course/

-- --
-- Zavie
------------------------------------------------------------------------------------------------------------

local tonemap = {}

local common = [[
float gamma = 2.2;
]]

tonemap.none = {
    src = [[ ]],
    func = [[ ]],
}

tonemap.linear = { 
    src = [[
    vec3 linearToneMapping(vec3 color)
    {
        float exposure = 1.;
        color = clamp(exposure * color, 0., 1.);
        color = pow(color, vec3(1. / gamma));
        return color;
    }
    ]],
    func = [[
        col = vec4(linearToneMapping(col.rgb),col.a);
    ]]
}

tonemap.simpleReinhard = {
    src = [[
    vec3 simpleReinhardToneMapping(vec3 color)
    {
        float exposure = 1.5;
        color *= exposure/(1. + color / exposure);
        color = pow(color, vec3(1. / gamma));
        return color;
    }
    ]],
    func = [[
        col = vec4(simpleReinhardToneMapping(col.rgb),col.a);
    ]]
}

tonemap.lumaReinhard = {
    src = [[
    vec3 lumaBasedReinhardToneMapping(vec3 color)
    {
        float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
        float toneMappedLuma = luma / (1. + luma);
        color *= toneMappedLuma / luma;
        color = pow(color, vec3(1. / gamma));
        return color;
    }
    ]],
    func = [[
        col = vec4(lumaBasedReinhardToneMapping(col.rgb),col.a);
    ]]
}

tonemap.whitePreserve = {
    src= [[
    vec3 whitePreservingLumaBasedReinhardToneMapping(vec3 color)
    {
        float white = 2.;
        float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
        float toneMappedLuma = luma * (1. + luma / (white*white)) / (1. + luma);
        color *= toneMappedLuma / luma;
        color = pow(color, vec3(1. / gamma));
        return color;
    }
    ]],
    func = [[
        col = vec4(whitePreservingLumaBasedReinhardToneMapping(col.rgb),col.a);
    ]]
}

tonemap.RomBinDaHouse = {
    src = [[
    vec3 RomBinDaHouseToneMapping(vec3 color)
    {
        color = exp( -1.0 / ( 2.72*color + 0.15 ) );
        color = pow(color, vec3(1. / gamma));
        return color;
    }
    ]],
    func = [[
        col = vec4(RomBinDaHouseToneMapping(col.rgb),col.a);
    ]]
}

tonemap.ACESfilmic = {
    src = [[
    // Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
    vec3 ACESToneMap(vec3 x) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
    }
    ]],
    func = [[
        col = vec4(ACESToneMap(col.rgb),col.a);
    ]]
}

tonemap.filmic = {
    src = [[
    vec3 filmicToneMapping(vec3 color)
    {
        color = max(vec3(0.), color - vec3(0.004));
        color = (color * (6.2 * color + .5)) / (color * (6.2 * color + 1.7) + 0.06);
        return color;
    }
    ]],
    func = [[
        col = vec4(filmicToneMapping(col.rgb),col.a);
    ]]
}

tonemap.uncharted2 = {
    src = [[
    vec3 Uncharted2ToneMapping(vec3 color)
    {
        float A = 0.15;
        float B = 0.50;
        float C = 0.10;
        float D = 0.20;
        float E = 0.02;
        float F = 0.30;
        float W = 11.2;
        float exposure = 2.;
        color *= exposure;
        color = ((color * (A * color + C * B) + D * E) / (color * (A * color + B) + D * F)) - E / F;
        float white = ((W * (A * W + C * B) + D * E) / (W * (A * W + B) + D * F)) - E / F;
        color /= white;
        color = pow(color, vec3(1. / gamma));
        return color;
    }
    ]],
    func = [[
        col = vec4(Uncharted2ToneMapping(col.rgb),col.a);
    ]]
}

return {
    maps        = tonemap,
    common      = common,
}