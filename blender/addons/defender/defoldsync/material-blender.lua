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
tags: "MATERIAL_MODEL_TAG"
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
varying vec4 v_light;

void main()
{
  vec4 p = mtx_worldview * vec4(position.xyz, 1.0);
  v_position = p.xyz;
  v_cam_position = (mtx_view * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
  v_objectNormal = normal;
  v_normal=normalize((mtx_normal * vec4(normal, 0.0)).xyz);
  v_texCoord=texcoord0;  
  v_light = light;
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
uniform vec4 params;

vec3 lightPositions[4];
vec3 lightColors[4];

varying vec4 v_light;
varying vec3 v_cam_position;
]]

------------------------------------------------------------------------------------------------------------

local fp_pbr_funcs = [[
  const float cpi = 3.14159265358979323846264338327950288419716939937510f ;

  // Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
  vec3 ACESToneMap(vec3 x) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
  }
  
  // ----------------------------------------------------------------------------
  
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
  
  float computeFresnelTerm(float fZero, vec3 vSurfaceToViewerDirection, vec3 vSurfaceNormal)
  {
      float baseValue = 1.0 - dot(vSurfaceToViewerDirection, vSurfaceNormal);
      float exponential = pow(baseValue, 5.0) ;
      float fresnel = exponential + fZero * (1.0 - exponential) ;
  
      return fresnel ;
  }
  
  float chiGGX(float f)
  {
      return f > 0.0 ? 1.0 : 0.0 ;
  }
  
  // APPROVED! Works as expected
  float computeGGXDistribution(vec3 vSurfaceNormal, vec3 vSurfaceToLightDirection, float fRoughness)
  {
      float fNormalDotLight = clamp(dot(vSurfaceNormal, vSurfaceToLightDirection), 0.0, 1.0) ;
      float fNormalDotLightSquared = fNormalDotLight * fNormalDotLight ;
      float fRoughnessSquared = fRoughness * fRoughness ;
      float fDen = fNormalDotLightSquared * fRoughnessSquared + (1.0 - fNormalDotLightSquared);
  
      return clamp((chiGGX(fNormalDotLight) * fRoughnessSquared) / (cpi * fDen * fDen), 0.0, 1.0);
  }
  
  float computeGGXPartialGeometryTerm(vec3 vSurfaceToViewerDirection, vec3 vSurfaceNormal, vec3 vLightViewHalfVector, float fRoughness)
  {
      float fViewerDotLightViewHalf = clamp(dot(vSurfaceToViewerDirection, vLightViewHalfVector), 0.0, 1.0) ;
      float fChi = chiGGX(fViewerDotLightViewHalf / clamp(dot(vSurfaceToViewerDirection, vSurfaceNormal), 0.0, 1.0));
      fViewerDotLightViewHalf *= fViewerDotLightViewHalf;
      float fTan2 = (1.0 - fViewerDotLightViewHalf) / fViewerDotLightViewHalf;
  
      return (fChi * 2.0) / (1.0 + sqrt(1.0 + fRoughness * fRoughness * fTan2)) ;
  }
  
  
  // ----------------------------------------------------------------------------
  vec4 getPbrColor(struct material mat)
  {
      vec3 mappedNormal = mat.normal;  
      vec3 MN = normalize((v_normal + mappedNormal) * 0.5) ;
  
      vec3 N = getNormalFromMap(mat.normal);
      vec3 V = normalize(v_cam_position - v_position);
  
      lightPositions[0] = v_light.xyz;
      
      // calculate per-light radiance
      int i = 0;
      vec3 L = normalize(lightPositions[i] - v_position);
      vec3 H = normalize(V + L);
      float distance = length(lightPositions[i] - v_position);
      float attenuation = 1.0 / (distance * distance);
      
      float fLightIntensity = max(dot(L, MN), 0.0) ;
  
      float fMetalness = mat.metallic;
      float fRoughness = max(0.001, mat.roughness);
  
      float distributionMicroFacet = computeGGXDistribution(MN, L, fRoughness) ;
      float geometryMicroFacet = computeGGXPartialGeometryTerm(V, MN, H, fRoughness) ;
      float microFacetContribution = distributionMicroFacet * geometryMicroFacet ;
  
      float fLightSourceFresnelTerm = computeFresnelTerm(0.5, V, MN) ;
  
      vec4 rgbAlbedo = mat.color * params.y;
      vec3 rgbEmissive = mat.emission.rgb;
  
      vec3 rgbFragment = rgbAlbedo.rgb * (1.0 - fMetalness);
  
      // vec3 rgbSourceReflection = texture2D( reflectionMap, vN ).rgb * fRoughness;
      // vec3 rgbReflection = rgbSourceReflection ;
      // rgbReflection *= rgbAlbedo.rgb * fMetalness ;
      // rgbReflection *= fLightSourceFresnelTerm ;
      // rgbReflection = min(rgbReflection, rgbSourceReflection) ; // conservation of energy
  
      vec3 rgbSpecular = vec3(0.0) ;
      if (fLightIntensity > 0.0)
      {
          rgbSpecular = vec3(params.z);
          rgbSpecular *= microFacetContribution * fLightSourceFresnelTerm ;
          rgbSpecular = min(vec3(1.0), rgbSpecular) ; // conservation of energy
      }
  
      float ambientLevel = fLightIntensity * (1.0 - params.x) + params.x;
      rgbFragment += rgbSpecular;
      rgbFragment *= ambientLevel;
      //rgbFragment += rgbReflection ;
      rgbFragment += rgbEmissive ;
      //rgbFragment *= amrtex.r;
  
      return vec4(rgbFragment, mat.alpha);
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
