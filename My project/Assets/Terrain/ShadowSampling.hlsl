#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

#ifndef SHADERGRAPH_PREVIEW
    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
    #if (SHADERPASS != SHADERPASS_FORWARD)
        #undef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
    #endif
#endif

struct DataStruct
{
    float3 WSPosition;
    float4 ShadowCoord;
};

float3 Shadows(DataStruct d)
{
    #ifdef SHADERGRAPH_PREVIEW
        float3 White;
        White = (1,1,1);
        return White;
    #else
        Light dir = GetMainLight(d.ShadowCoord, d.WSPosition,1);
        float3 Color;
        Color = (1,1,1) * dir.shadowAttenuation;
        return Color;
    #endif
}

void ShadowSampling_float(float3 WSPosition,out float3 Color)
{
    DataStruct data;
    
    data.WSPosition = WSPosition;

    #ifdef SHADERGRAPH_PREVIEW
        data.ShadowCoord = 0;
    #else
        float4 positionCS = TransformWorldToHClip(WSPosition);
        #if SHADOWS_SCREEN
            data.ShadowCoord = ComputeScreenPos(positionCS);
        #else
            data.ShadowCoord = TransformWorldToShadowCoord(WSPosition);
        #endif
    #endif

    Color = Shadows(data);

}
#endif