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

local vp = [[
  // Positions can be world or local space, since world and normal
  // matrices are identity for world vertex space materials.
  // If world vertex space is selected, you can remove the
  // normal matrix multiplication for optimal performance.
  
  attribute highp vec4 position;
  attribute mediump vec2 texcoord0;
  attribute mediump vec3 normal;
  
  uniform mediump mat4 mtx_worldview;
  uniform mediump mat4 mtx_view;
  uniform mediump mat4 mtx_proj;
  uniform mediump mat4 mtx_normal;
  uniform mediump vec4 light;
  
  //uniform mediump vec4 camPos;
  
  // Original work by Martia A Saunders
  // https://dominium.maksw.com/articles/physically-based-rendering-pbr/pbr-part-one/
  
  // attribute vec3 aVertexTangent;
  
  varying vec3 vvLocalSurfaceNormal ;
  varying vec3 vvLocalSurfaceToLightDirection;
  varying vec3 vvLocalReflectedSurfaceToViewerDirection;
  varying vec3 vvLocalSurfaceToViewerDirection;
  varying vec2 vuvCoord0 ;
  varying vec2 vN;
  
  void main()
  {
      vec4 p = mtx_worldview * vec4(position.xyz, 1.0);
      vec3 vViewModelPosition = normalize( mtx_view * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
      vvLocalSurfaceToViewerDirection = normalize(vViewModelPosition - p.xyz) ;
  
      vec3 vLightModelPosition = vec3(mtx_view * vec4(light.xyz, 1.0));
      vvLocalSurfaceToLightDirection = normalize(vLightModelPosition - p.xyz);
  
      vvLocalSurfaceNormal = normalize((mtx_normal * vec4(normal, 0.0)).xyz);
      //	vvLocalSurfaceNormal = normalize(gl_Normal) ; // use the actual normal from the actual geometry
  
      vec3 vLocalSurfaceToViewerDirection = normalize(vViewModelPosition - p.xyz) ;
      vvLocalReflectedSurfaceToViewerDirection = normalize(reflect(vLocalSurfaceToViewerDirection, vvLocalSurfaceNormal)) ;

      vec3 e = p.xyz;
      vec3 n = vvLocalSurfaceNormal;

      vec3 r = reflect( e, n );
      float m = 2. * sqrt( pow( r.x, 2. ) + pow( r.y, 2. ) + pow( r.z + 1., 2. ) );
      vN = r.xy / m + .5;
      
      vuvCoord0 = texcoord0 ;
      gl_Position = mtx_proj * p;
  }    
]]

------------------------------------------------------------------------------------------------------------

local fp = [[
  // Original work by Martia A Saunders
  // https://dominium.maksw.com/articles/physically-based-rendering-pbr/pbr-part-one/
  
  // uniform samplerCube cubeMap ;
  uniform sampler2D emissiveMap ;
  uniform sampler2D aoMetallicRoughnessMap;
  uniform sampler2D albedoMap ;
  uniform sampler2D normalMap ;
  uniform sampler2D reflectionMap;
  
  uniform vec4 tint;
  uniform vec4 params;
  
  varying vec3 vvLocalSurfaceNormal ;
  varying vec3 vvLocalSurfaceToLightDirection;
  varying vec3 vvLocalReflectedSurfaceToViewerDirection;
  varying vec2 vuvCoord0 ;
  varying vec3 vvLocalSurfaceToViewerDirection;
  
  varying vec2 vN;
  
  const float cpi = 3.14159265358979323846264338327950288419716939937510f ;
  
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
  
  void main()
  {
    vec3 mappedNormal = normalize(texture(normalMap, vuvCoord0).xyz);  
    vec3 vNormalisedLocalSurfaceNormal = normalize((vvLocalSurfaceNormal + mappedNormal) * 0.5) ;
  
    vec3 vNormalisedLocalSurfaceToLightDirection = normalize(vvLocalSurfaceToLightDirection) ;
    vec3 vNormalisedLocalReflectedSurfaceToViewerDirection = normalize(vvLocalReflectedSurfaceToViewerDirection) ;
    vec3 vNormalisedLocalSurfaceToViewerDirection = normalize(vvLocalSurfaceToViewerDirection) ;
  
    vec3 vLocalLightViewHalfVector = normalize(vNormalisedLocalSurfaceToLightDirection + vNormalisedLocalSurfaceToViewerDirection) ;
  
    float fLightIntensity = max(dot(vNormalisedLocalSurfaceToLightDirection, vNormalisedLocalSurfaceNormal), 0.0) ;
  
    vec4 amrtex = texture(aoMetallicRoughnessMap, vuvCoord0);
    float fMetalness = amrtex.g ;
    float fRoughness = max(0.001, amrtex.b ) ;
  
    float distributionMicroFacet = computeGGXDistribution(vNormalisedLocalSurfaceNormal, vNormalisedLocalSurfaceToLightDirection, fRoughness) ;
    float geometryMicroFacet = computeGGXPartialGeometryTerm(vNormalisedLocalSurfaceToViewerDirection, vNormalisedLocalSurfaceNormal, vLocalLightViewHalfVector, fRoughness) ;
    float microFacetContribution = distributionMicroFacet * geometryMicroFacet ;
  
    float fLightSourceFresnelTerm = computeFresnelTerm(0.5, vNormalisedLocalSurfaceToViewerDirection, vNormalisedLocalSurfaceNormal) ;
  
    vec4 rgbAlbedo = texture(albedoMap, vuvCoord0) * tint * params.y;
    vec3 rgbEmissive = texture(emissiveMap, vuvCoord0).rgb;
  
    vec3 rgbFragment = rgbAlbedo.rgb * (1.0 - fMetalness);
  
    vec3 rgbSourceReflection = texture2D( reflectionMap, vN ).rgb * fRoughness;
    vec3 rgbReflection = rgbSourceReflection ;
    rgbReflection *= rgbAlbedo.rgb * fMetalness ;
    rgbReflection *= fLightSourceFresnelTerm ;
    rgbReflection = min(rgbReflection, rgbSourceReflection) ; // conservation of energy
  
    vec3 rgbSpecular = vec3(0.0) ;
    if (fLightIntensity > 0.0)
    {
      rgbSpecular = vec3(params.z) ;
      rgbSpecular *= microFacetContribution * fLightSourceFresnelTerm ;
      rgbSpecular = min(vec3(1.0), rgbSpecular) ; // conservation of energy
    }
  
    float ambientLevel = fLightIntensity * (1.0 - params.x) + params.x;
    rgbFragment += rgbSpecular;
    rgbFragment *= ambientLevel;
    rgbFragment += rgbReflection ;
    rgbFragment += rgbEmissive ;
    rgbFragment *= amrtex.r;
  
    gl_FragColor = vec4(rgbFragment, rgbAlbedo.a);
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
  name: "tint"
  type: CONSTANT_TYPE_USER
  value {
    x: 1.0
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
samplers {
  name: "albedoMap"
  wrap_u: WRAP_MODE_REPEAT
  wrap_v: WRAP_MODE_REPEAT
  filter_min: FILTER_MODE_MIN_NEAREST
  filter_mag: FILTER_MODE_MAG_NEAREST
}
samplers {
  name: "aoMetallicRoughnessMap"
  wrap_u: WRAP_MODE_REPEAT
  wrap_v: WRAP_MODE_REPEAT
  filter_min: FILTER_MODE_MIN_NEAREST
  filter_mag: FILTER_MODE_MAG_NEAREST
}
samplers {
  name: "emissiveMap"
  wrap_u: WRAP_MODE_REPEAT
  wrap_v: WRAP_MODE_REPEAT
  filter_min: FILTER_MODE_MIN_NEAREST
  filter_mag: FILTER_MODE_MAG_NEAREST
}
samplers {
  name: "normalMap"
  wrap_u: WRAP_MODE_REPEAT
  wrap_v: WRAP_MODE_REPEAT
  filter_min: FILTER_MODE_MIN_NEAREST
  filter_mag: FILTER_MODE_MAG_NEAREST
}
samplers {
  name: "reflectionMap"
  wrap_u: WRAP_MODE_REPEAT
  wrap_v: WRAP_MODE_REPEAT
  filter_min: FILTER_MODE_MIN_NEAREST
  filter_mag: FILTER_MODE_MAG_NEAREST
}
]]

------------------------------------------------------------------------------------------------------------
-- Setting this simple pbd up for use as a custom material as well.
return {

    vp_lightdir_local   = vp_lightdir_local, 
    vp_lightdir_global  = vp_lightdir_global,
    vp                  = vp,
    fp                  = fp,
    material            = material,
}

------------------------------------------------------------------------------------------------------------
