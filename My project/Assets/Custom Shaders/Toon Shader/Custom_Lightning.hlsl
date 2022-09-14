#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED


// Workaround by @cyanilux
#ifndef SHADERGRAPH_PREVIEW
    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
    #if (SHADERPASS != SHADERPASS_FORWARD)
        #undef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
    #endif
#endif

struct CustomLightingData {
    // Interpolated Position and Orientation
    float3 WSNormal;
    float3 WSViewDir;
    float3 WSPosition;
    float4 ShadowCoord;
    // Surface Properties (Texture Maps)
    float3 albedo;
    float smoothness;
    float ambientOcclusion;
    float metallic;
    Texture2D ramp;
    SamplerState rampTS;
    float fresneloff;
    float fresnelint;
    float fresnelpow;
    float3 rimcolor;

    // BAKED GI //
    float3 bakedGI;
    float4 shadowMask;
    float fogFactor;
};

// 0-1 Float value to an exponent to make the specularity of the material //
float SmoothnessPow(float smoothness){
    return exp2(10* smoothness + 1);
}

// Shadergraph previews don't have the light struct defined, so it returns error //
#ifndef SHADERGRAPH_PREVIEW
    float3 CustomGI(CustomLightingData d){
        // Metallic Albedo //
        float3 reflection = reflect(-d.WSViewDir,d.WSNormal);
        float3 MixedAlbedo = GlossyEnvironmentReflection(reflection,RoughnessToPerceptualRoughness(1-d.smoothness),d.ambientOcclusion);
        
        float3 indirectDiffuse = lerp(d.albedo,MixedAlbedo,d.metallic)* d.bakedGI * d.ambientOcclusion;
        
        
        float fresnel = Pow4(1- saturate(dot(d.WSViewDir, d.WSNormal)))*(d.smoothness/2);

        float3 indirectSpecular = GlossyEnvironmentReflection(reflection,RoughnessToPerceptualRoughness(1-d.smoothness), d.ambientOcclusion) * fresnel;
        
        return indirectDiffuse + indirectSpecular;

    }


    float3 DirectionalLightLambert(CustomLightingData d, Light light){

        // Light color and it's intensity * (If it's in shadow * Attenuation)//
        float3 suncolor = light.color *(light.shadowAttenuation * light.distanceAttenuation);
        // Dot product between WSpace Normals and Directional Light Direction (Lambert Lightning Model) //
        float3 lambertshading = saturate(dot(d.WSNormal,light.direction)) * (1-d.metallic);
        float3 ramped = SAMPLE_TEXTURE2D(d.ramp,d.rampTS,lambertshading);

        // Specular Component //
        float specular = saturate(dot(d.WSNormal,normalize(light.direction + d.WSViewDir)));
        float specularshading = pow(specular, SmoothnessPow(d.smoothness)) * lerp(ramped,1,d.metallic);

        // Multiply Albedo with the lambert and Light Color //
        float3 color = d.albedo * suncolor * (ramped+specularshading);
        
        return color;
}
#endif

float3 CalculateCustomLighting(CustomLightingData d) {
    #ifdef SHADERGRAPH_PREVIEW
        // Main Light Simulation Preview //
        float3 prevlight = float3(0.5,0.5,0);
        float3 previntensity = saturate(dot(d.WSNormal,prevlight)) + pow(saturate(dot(d.WSNormal,normalize(d.WSViewDir+prevlight))),SmoothnessPow(d.smoothness));
        float2 uv = (previntensity.x,0);
        float4 ramped = SAMPLE_TEXTURE2D(d.ramp,d.rampTS,previntensity.x);

        // Rim Light //
        float fresnel = Pow4(1- saturate(dot(d.WSViewDir, d.WSNormal)))*d.fresnelint;
        float3 rimcalc = pow(1 - (saturate((d.fresneloff+d.WSViewDir))),d.fresnelpow)*d.rimcolor * d.fresnelint;
        float3 rim = rimcalc;

        
        return (d.albedo * ramped.xyz)+rim;
    #else
        // Get Main Light (Directional) //
        Light DirectionalLight = GetMainLight(d.ShadowCoord,d.WSPosition,d.shadowMask);
        MixRealtimeAndBakedGI(DirectionalLight,d.WSNormal,d.bakedGI);
        float3 Color = CustomGI(d);
        // Directional Light Shade //
        Color += DirectionalLightLambert(d, DirectionalLight);   

        //Rim Light //
        //float fresnel = Pow4(1- saturate(dot(d.WSViewDir, d.WSNormal)))*d.fresnelint;
        //float rim = pow(fresnel,d.fresnelpow)*d.rimcolor;
        float rimcalc = saturate(dot(d.WSNormal,d.WSViewDir));
        float3 rim =  pow((1-saturate(d.fresneloff+rimcalc)),d.fresnelpow)*d.rimcolor*d.fresnelint;
        Color += rim;
        // If there are multiple lights in scene, cycle through them and add to final color //
        #ifdef _ADDITIONAL_LIGHTS
            uint numAdditionalLights = GetAdditionalLightsCount();
            for (uint i=0; i<numAdditionalLights; i++){
                Light light = GetAdditionalLight(i,d.WSPosition,d.shadowMask);
                Color += DirectionalLightLambert(d,light);
            }
        #endif

        return Color;

    #endif
}


void CustomLightModel_float(float3 WSPosition, float3 WSNormal, float3 WSViewDir, float3 Albedo, float Smoothness, float AmbientOcclusion, float2 LightmapUV, float Metallic, Texture2D Ramp, SamplerState RampTS, float fresnelint, float fresnelpow, float3 rimcolor, float rimoff, out float3 Color) {

    CustomLightingData d;
    d.WSPosition = WSPosition;
    d.WSNormal = WSNormal;
    d.WSViewDir = WSViewDir;
    d.smoothness = Smoothness;
    d.albedo = Albedo;
    d.metallic = Metallic;
    d.ambientOcclusion = AmbientOcclusion;
    d.ramp = Ramp;
    d.rampTS = RampTS;
    d.fresnelint = fresnelint;
    d.fresnelpow = fresnelpow;
    d.rimcolor = rimcolor;
    d.fresneloff = rimoff;
    // Fill Shadow Inputs in the Struct //
    #ifdef SHADERGRAPH_PREVIEW
        d.ShadowCoord = 0;
        d.bakedGI = 0;
        d.shadowMask = 0;
        d.fogFactor = 0;
    #else
        // WSpace Position to Clip Space Position //
        float4 positionCS = TransformWorldToHClip(WSPosition);
        #if SHADOWS_SCREEN
            d.ShadowCoord = ComputeScreenPos(positionCS);
        #else
            d.ShadowCoord = TransformWorldToShadowCoord(WSPosition);
        #endif

        // Sample Lightmap UVS //
        float3 lightmapUV;
        OUTPUT_LIGHTMAP_UV(LightmapUV, unity_LightmapST, lightmapUV);

        // Sample Light Probe Data (I didn't know that it was called Spherical Harmonics...)
        float3 VertexSH;
        OUTPUT_SH(WSNormal, VertexSH);
        // Final GI //
        d.bakedGI = SAMPLE_GI(lightmapUV,VertexSH,WSNormal);
        d.shadowMask = SAMPLE_SHADOWMASK(lightmapUV);
        d.fogFactor = ComputeFogFactor(positionCS.z);
    #endif

    Color = CalculateCustomLighting(d);
}
#endif