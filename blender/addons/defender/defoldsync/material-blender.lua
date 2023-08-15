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
local vp_lightdir_local = [[normalize(vLightModelPosition - p.xyz)]]
local vp_lightdir_global = [[vec3(0.0, 2.0, 3.0)]]

------------------------------------------------------------------------------------------------------------

local sampler = [[
samplers {
  name: "MATERIAL_SAMPLER_NANE"
  wrap_u: WRAP_MODE_REPEAT
  wrap_v: WRAP_MODE_REPEAT
  filter_min: FILTER_MODE_MIN_NEAREST
  filter_mag: FILTER_MODE_MAG_NEAREST
}  
]]

------------------------------------------------------------------------------------------------------------

local material = [[
name: "pbr-simple"
tags: "model"
vertex_program: "MATERIAL_VP"
fragment_program: "MATERIAL_FP"
vertex_space: VERTEX_SPACE_WORLD
vertex_constants {
  name: "mtx_world"
  type: CONSTANT_TYPE_WORLD
  value {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 0.0
  }
}
vertex_constants {
  name: "mtx_view"
  type: CONSTANT_TYPE_VIEW
  value {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 0.0
  }
}
vertex_constants {
  name: "mtx_proj"
  type: CONSTANT_TYPE_PROJECTION
  value {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 0.0
  }
}
vertex_constants {
  name: "mtx_normal"
  type: CONSTANT_TYPE_NORMAL
  value {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 0.0
  }
}
vertex_constants {
  name: "light"
  type: CONSTANT_TYPE_USER
  value {
MATERIAL_LIGHT_VECTOR
  }
}
vertex_constants {
  name: "mtx_worldview"
  type: CONSTANT_TYPE_WORLDVIEW
  value {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 0.0
  }
}
fragment_constants {
  name: "exposure"
  type: CONSTANT_TYPE_USER
  value {
    x: 2.2
    y: 1.0
    z: 1.0
    w: 1.0
  }
}
fragment_constants {
  name: "params"
  type: CONSTANT_TYPE_USER
  value {
MATERIAL_PARAMS
  }
}

MATERIAL_SAMPLERS

]]

------------------------------------------------------------------------------------------------------------

local vp = [[

// Positions can be world or local space, since world and normal
// matrices are identity for world vertex space materials.
// If world vertex space is selected, you can remove the
// normal matrix multiplication for optimal performance.

attribute vec4 position;
attribute vec2 texcoord0;
attribute vec3 normal;

uniform mat4 mtx_worldview;
uniform mat4 mtx_view;
uniform mat4 mtx_proj;
uniform mat4 mtx_normal;
uniform vec4 light;

varying vec3 v_position;
varying vec3 v_cam_position;
varying vec3 v_normal;
varying vec3 v_objectNormal;
varying vec2 v_texCoord;

void main()
{
  vec4 p = mtx_worldview * vec4(position.xyz, 1.0);
  v_position = p.xyz;
  v_cam_position = (mtx_view * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
  v_objectNormal = normal;
  v_normal=normalize((mtx_normal * vec4(normal, 0.0)).xyz);
  v_texCoord=texcoord0;  
  gl_Position = mtx_proj * p;
}    
 
]]

------------------------------------------------------------------------------------------------------------

local fp = [[
MATERIAL_FRAGMENT_SHADER
]]

------------------------------------------------------------------------------------------------------------

local fp_pbr_varyings = [[

// Based on https://learnopengl.com/PBR/Theory
// textures from https://freepbr.com/

// lights
uniform vec3 lightPositions[4];
uniform vec3 lightColors[4];
uniform vec4 exposure;
varying vec3 v_cam_position;
]]

------------------------------------------------------------------------------------------------------------

local fp_pbr_funcs = [[
const float PI = 3.14159265359;

vec3 getNormalFromMap(vec3 in_normal)
{
  vec3 Q1  = dFdx(v_cam_position - v_position);
  vec3 Q2  = dFdy(v_cam_position - v_position);
  vec2 st1 = dFdx(v_texCoord);
  vec2 st2 = dFdy(v_texCoord);

  vec3 N   = normalize(v_normal);
  vec3 dp2perp = cross( Q2, N );
  vec3 dp1perp = cross( N, Q1 );
  vec3 T  = (dp2perp*st1.x + dp1perp*st2.x);
  vec3 B  = (dp2perp*st1.y + dp1perp*st2.y);
  float invmax = inversesqrt( max( dot(T,T), dot(B,B) ) );
  mat3 TBN = mat3(T *invmax, B *invmax, N);
  return normalize(TBN * in_normal);
}
// ----------------------------------------------------------------------------
float DistributionGGX(vec3 N, vec3 H, float roughness)
{
    float a = roughness*roughness;
    float a2 = a*a;
    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;

    float nom   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return nom / denom;
}
// ----------------------------------------------------------------------------
float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    float nom   = NdotV;
    float denom = NdotV * (1.0 - k) + k;

    return nom / denom;
}
// ----------------------------------------------------------------------------
float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2 = GeometrySchlickGGX(NdotV, roughness);
    float ggx1 = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}
// ----------------------------------------------------------------------------
vec3 fresnelSchlick(float cosTheta, vec3 F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}
// ----------------------------------------------------------------------------
vec4 getPbrColor(struct material mat)
{
    vec3 albedo     = mat.color.xyz;
    float metallic  = mat.metallic;
    float roughness = mat.roughness;
    float ao        = mat.ior;

    vec3 N = getNormalFromMap(mat.normal);
    vec3 V = normalize(v_cam_position - v_position);

    // calculate reflectance at normal incidence; if dia-electric (like plastic) use F0
    // of 0.04 and if it's a metal, use the albedo color as F0 (metallic workflow)
    vec3 F0 = vec3(0.04);
    F0 = mix(F0, albedo, metallic);

    // reflectance equation
    vec3 Lo = vec3(0.0);
    for(int i = 0; i < 4; ++i)
    {
        float x = float(i) * 0.6 + 1.0;
        vec3 lightpos = vec3(x, 1, 1);
        vec3 lightColor = vec3(30.0);

        // calculate per-light radiance
        vec3 L = normalize(lightpos - v_position);
        vec3 H = normalize(V + L);
        float distance = length(lightpos - v_position);
        float attenuation = 1.0 / (distance * distance);
        vec3 radiance = lightColor * attenuation;

        // Cook-Torrance BRDF
        float NDF = DistributionGGX(N, H, roughness);
        float G   = GeometrySmith(N, V, L, roughness);
        vec3 F    = fresnelSchlick(max(dot(H, V), 0.0), F0);

        vec3 nominator    = NDF * G * F;
        float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.001; // 0.001 to prevent divide by zero.
        vec3 specular = nominator / denominator;

        // kS is equal to Fresnel
        vec3 kS = F;
        // for energy conservation, the diffuse and specular light can't
        // be above 1.0 (unless the surface emits light); to preserve this
        // relationship the diffuse component (kD) should equal 1.0 - kS.
        vec3 kD = vec3(1.0) - kS;
        // multiply kD by the inverse metalness such that only non-metals
        // have diffuse lighting, or a linear blend if partly metal (pure metals
        // have no diffuse light).
        kD *= 1.0 - metallic;

        // scale light by NdotL
        float NdotL = max(dot(N, L), 0.0);

        // add to outgoing radiance Lo
        Lo += (kD * albedo / PI + specular) * radiance * NdotL;  // note that we already multiplied the BRDF by the Fresnel (kS) so we won't multiply by kS again
    }

    // ambient lighting (note that the next IBL tutorial will replace
    // this ambient lighting with environment lighting).
    vec3 ambient = vec3(0.03) * albedo * ao;

    vec3 color = ambient + Lo;

    // HDR tonemapping
    color = color / (color + vec3(1.0));
    // gamma correct
    color = pow(color, vec3(1.0/exposure.x));

    return vec4(color, mat.alpha);
}  
]]

------------------------------------------------------------------------------------------------------------
-- Setting this simple pbd up for use as a custom material as well.
return {

    vp_lightdir_local   = vp_lightdir_local, 
    vp_lightdir_global  = vp_lightdir_global,
    vp                  = vp,
    fp                  = fp,
    fp_pbr_funcs        = fp_pbr_funcs,
    fp_pbr_varyings     = fp_pbr_varyings,
    material            = material,
    sampler             = sampler,
}

------------------------------------------------------------------------------------------------------------
