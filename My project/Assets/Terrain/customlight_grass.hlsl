#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

#ifndef SHADERGRAPH_PREVIEW
    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
    #if (SHADERPASS != SHADERPASS_FORWARD)
        #undef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
    #endif
#endif

struct LightDataStruct
{
    float3 WSNormal;
    float3 WSPosition;
    float4 ShadowCoord;
    float3 Albedo;
    float4 ShadowMask;

    float3 bakedGI;

};

#ifndef SHADERGRAPH_PREVIEW

float3 CustomGI(LightDataStruct d)
{

    float3 indirectDiffuse = d.Albedo * d.bakedGI * 1;
    return indirectDiffuse;

}



float3 LambertCalc(LightDataStruct d, Light light)
{
    float3 lightcolor = light.color * (light.shadowAttenuation * light.distanceAttenuation);
    float3 lambershading = saturate(dot(d.WSNormal,light.direction));
    float3 result = lightcolor * lambershading;
    return result;
}
#endif

float3 Shade(LightDataStruct d)
{

    #ifdef SHADERGRAPH_PREVIEW
        float3 prevdir = float3(0.5,0.5,0);
        float3 calc = saturate(dot(d.WSNormal,prevdir));
        float3 color = d.Albedo;
        color += calc;
        return color;

    #else
        float3 FColor = CustomGI(d);
        Light DirectionalLight = GetMainLight(d.ShadowCoord,d.WSPosition,d.ShadowMask);
        FColor += LambertCalc(d,DirectionalLight);

        #ifdef _ADDITIONAL_LIGHTS
            uint numAdditionalLights = GetAdditionalLightsCount();
            for (uint i=0; i<numAdditionalLights; i++){
                Light light = GetAdditionalLight(i,d.WSPosition,d.ShadowMask);
                FColor += LambertCalc(d,light);
            }
        #endif
        return FColor;
    #endif

}



void CustomLightGrass_float(float3 WSNormal, float3 WSPosition, float3 Albedo, float2 LightMapUV, out float3 Color )
{
    LightDataStruct d;
    d.WSNormal = WSNormal;
    d.WSPosition = WSPosition;
    d.Albedo = Albedo;
    
    #ifdef SHADERGRAPH_PREVIEW
        d.ShadowCoord = 0;
        d.ShadowMask = 0;
    #else
        float4 positionCS = TransformWorldToHClip(WSPosition);
        #if SHADOWS_SCREEN
            d.ShadowCoord = ComputeScreenPos(positionCS);
        #else
            d.ShadowCoord = TransformWorldToShadowCoord(WSPosition);
        #endif
    
        float3 lightmapUV;
        OUTPUT_LIGHTMAP_UV(LightMapUV, unity_LightmapST, lightmapUV);
        float3 VertexSH;
        OUTPUT_SH(WSNormal, VertexSH);
        d.bakedGI = SAMPLE_GI(lightmapUV,VertexSH,WSNormal);
        d.ShadowMask = SAMPLE_SHADOWMASK(lightmapUV);

    #endif

    Color = Shade(d);
}
#endif