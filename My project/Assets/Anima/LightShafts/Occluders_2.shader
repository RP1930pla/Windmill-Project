Shader "Unlit/Anima/Occluders_2"
{
    Properties
    {

    }
    SubShader
    {
        Tags { 
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Opaque" 
            "Queue" = "Geometry"
        }
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        ENDHLSL

        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertexShad
            #pragma fragment FragmentShad
            #pragma multi_compile_instancing

            struct Attributes {
                float4 positionOS:POSITION;
            };

            struct Varyings {
                float4 positionCS:SV_POSITION;
            };

            Varyings VertexShad(Attributes IN) {
                Varyings OUT;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = positionInputs.positionCS;
                return OUT;
            }

            half4 FragmentShad(Varyings IN) : SV_Target{
                half4 color = (0,0,0,0);
                return color;
            }
            ENDHLSL
        }
    }
}
