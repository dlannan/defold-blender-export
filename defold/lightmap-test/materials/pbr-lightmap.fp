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
  varying vec2 vuvCoord1 ;
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
    vec3 rgbEmissive = texture(emissiveMap, vuvCoord1).rgb;
  
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
    rgbFragment += vec3(rgbEmissive.r + params.w, rgbEmissive.g + params.w, rgbEmissive.b + params.w) ;
    rgbFragment *= amrtex.r;
  
    gl_FragColor = vec4(rgbFragment, rgbAlbedo.a);
  }  
