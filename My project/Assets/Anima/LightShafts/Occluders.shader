Shader "Hidden/Anima/UnlitColor"
{
    Properties
    {
        _Color("Main Color", Color) = (0.0, 0.0, 0.0, 0.0)
    }

        SubShader
    {
        Tags { "RenderType" = "Opaque" }
        Fog {Mode Off}

        Pass 
        {
            HLSLPROGRAM
            #pragma multi_compile_instancing
            ENDHLSL
        }
    }
}