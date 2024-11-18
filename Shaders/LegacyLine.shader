Shader "Hslr/LegacyLine"
{
    Properties
    {
        [MainTexture] _MainTex ("Overlay Texture", 2D) = "black" {}
        _Color ("Tint", Color) = (1, 1, 1, 1)
        // [Toggle(_USE_PQS_BUFFER)] _NoComputeBuffer ("Use PathDataBuffer for line data. ", float) = 0.9
        _NodeCount ("Node Count", Integer) = 0
        _Thickness ("Thickness", float) = 0.1
    }

    SubShader
    {
        // Tags { "RenderType"="Opaque" }
        // Blend SrcAlpha OneMinusSrcAlpha
        Cull Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "HslrBuffer.hlsl"

            struct appdata
            {
                uint vertexID : SV_VertexID;
                // float4 vertex : POSITION;
                // float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                // float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 color : COLOR0;
            };

            sampler2D _MainTex;
            float4 _Color;
            int _NodeCount;
            float _Thickness;
            

            v2f vert (appdata v)
            {
                v2f o;
                NodeContext context = ReadFromBuffer(v.vertexID, (uint)_NodeCount);

                float thicknessSign = GetVertThicknessSign(v.vertexID);

                float4 prevPosSs = UnityObjectToClipPos(context.prevNode.position);
                float4 thisPosSs = UnityObjectToClipPos(context.thisNode.position);
                float4 nextPosSs = UnityObjectToClipPos(context.nextNode.position);

                thisPosSs += float4(0, thicknessSign * _Thickness, 0, 0);



                o.vertex = thisPosSs;
                o.color = context.thisNode.color;
                // o.vertex = UnityObjectToClipPos(position);
                // o.uv = float2(0, 0);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // fixed4 col = tex2D(_MainTex, i.uv);

                return _Color * i.color;
            }
            ENDHLSL
        }
    }
}
