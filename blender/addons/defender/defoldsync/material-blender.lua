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
  
  varying vec3 v_position;
  varying vec3 v_normal;
  varying vec3 v_objectNormal ;
  varying vec3 vvLocalSurfaceToLightDirection;
  varying vec3 vvLocalReflectedSurfaceToViewerDirection;
  varying vec3 vvLocalSurfaceToViewerDirection;
  varying vec2 v_texCoord ;
  varying vec2 vN;
  
  void main()
  {
      v_position = position.xyz;
      vec4 p = mtx_worldview * vec4(position.xyz, 1.0);
      vec3 vViewModelPosition = normalize( mtx_view * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
      vvLocalSurfaceToViewerDirection = normalize(vViewModelPosition - p.xyz) ;
  
      vec3 vLightModelPosition = vec3(mtx_view * vec4(light.xyz, 1.0));
      vvLocalSurfaceToLightDirection = normalize(vLightModelPosition - p.xyz);
  
      v_objectNormal = normal;
      v_normal = normalize((mtx_normal * vec4(normal, 0.0)).xyz);
      //	v_objectNormal = normalize(gl_Normal) ; // use the actual normal from the actual geometry
  
      vec3 vLocalSurfaceToViewerDirection = normalize(vViewModelPosition - p.xyz) ;
      vvLocalReflectedSurfaceToViewerDirection = normalize(reflect(vLocalSurfaceToViewerDirection, v_normal)) ;

      vec3 e = p.xyz;
      vec3 n = v_normal;

      vec3 r = reflect( e, n );
      float m = 2. * sqrt( pow( r.x, 2. ) + pow( r.y, 2. ) + pow( r.z + 1., 2. ) );
      vN = r.xy / m + .5;
      
      v_texCoord = texcoord0 ;
      gl_Position = mtx_proj * p;
  }    
]]

------------------------------------------------------------------------------------------------------------

local fp = [[
MATERIAL_FRAGMENT_SHADER
]]

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

MATERIAL_SAMPLERS

]]

------------------------------------------------------------------------------------------------------------
-- Setting this simple pbd up for use as a custom material as well.
return {

    vp_lightdir_local   = vp_lightdir_local, 
    vp_lightdir_global  = vp_lightdir_global,
    vp                  = vp,
    fp                  = fp,
    material            = material,
    sampler             = sampler,
}

------------------------------------------------------------------------------------------------------------
