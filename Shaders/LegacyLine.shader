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

            float2 WCorrect(float4 positionCs)
            {
                return float2(positionCs.x * positionCs.w, positionCs.y * positionCs.w);
            }

            v2f vert (appdata v)
            {
                v2f o;
                NodeContext context = ReadFromBuffer(v.vertexID, (uint)_NodeCount);

                float thicknessSign = GetVertThicknessSign(v.vertexID);

                float4 prevPosSs = UnityObjectToClipPos(context.prevNode.position);
                float4 thisPosSs = UnityObjectToClipPos(context.thisNode.position);
                float4 nextPosSs = UnityObjectToClipPos(context.nextNode.position);

                float2 aspectRatioCorrection = float2(_ScreenParams.y / _ScreenParams.x, 1);

                float2 toRight = normalize(WCorrect(nextPosSs) -  WCorrect(thisPosSs));
                float2 toLeft = normalize(WCorrect(thisPosSs) - WCorrect(prevPosSs));
                float2 toRightRotated = float2(-toRight.y, toRight.x);
                float2 toLeftRotated = float2(-toLeft.y, toLeft.x);
                float2 jointNormal = normalize ((toRightRotated + toLeftRotated));

                float2 offset = jointNormal * _Thickness * thicknessSign * thisPosSs.w / 2 * aspectRatioCorrection ;

                thisPosSs.xy += offset;

                o.vertex = thisPosSs;
                o.color = context.thisNode.color;
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
