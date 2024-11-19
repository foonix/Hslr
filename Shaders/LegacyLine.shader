Shader "Hslr/LegacyLine"
{
    Properties
    {
        [MainTexture] _MainTex ("Overlay Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1, 1, 1, 1)
        // [Toggle(_USE_PQS_BUFFER)] _NoComputeBuffer ("Use PathDataBuffer for line data. ", float) = 0.9
        _NodeCount ("Node Count", Integer) = 0
        _Thickness ("Thickness", float) = 0.1
        _MiterThreshold("Miter Threshold", float) = 0.8
        _Perspective("Perspective", Range(0,1)) = 0
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Blend One One
        ZWrite off
        // Cull Off

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
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 color : COLOR0;
            };

            sampler2D _MainTex;
            float4 _Color;
            int _NodeCount;
            float _Thickness;
            float _MiterThreshold;
            float _Perspective;

            float2 WCorrect(float4 positionCs)
            {
                return float2(positionCs.x * positionCs.w, positionCs.y * positionCs.w);
            }

            v2f vert (appdata v)
            {
                v2f o;
                NodeContext context = ReadFromBuffer(v.vertexID, (uint)_NodeCount);

                float thicknessSign = GetVertThicknessSign(v.vertexID);

                float4 prev = UnityObjectToClipPos(context.prevNode.position);
                float4 current = UnityObjectToClipPos(context.thisNode.position);
                float4 next = UnityObjectToClipPos(context.nextNode.position);

                float2 current_screen = current.xy / current.w * _ScreenParams.xy;
                float2 prev_screen = prev.xy / prev.w * _ScreenParams.xy;
                float2 next_screen = next.xy / next.w * _ScreenParams.xy;

                float len = _Thickness/*  * _ThicknessMultiplier */;
                // y here is 0 for midpoint, 1 for beginning, 2 for end.
                float2 orientation = float2(thicknessSign, 0);
                float2 dir = float2(0,0);

                float flip;
                if (orientation.y == 1.0) {
                    dir = normalize(next_screen - current_screen);
                }
                else if (orientation.y == 2.0) {
                    dir = normalize(current_screen - prev_screen);
                }
                else {
                    float2 dirA = normalize(current_screen - prev_screen);
                    float2 dirB = normalize(next_screen - current_screen);

                    flip = sign(.1 + sign(dot(dirA,dirB) + _MiterThreshold));

                    dirB *= flip;

                    float2 tangent = (dirA + dirB) / 2; //Divide by two normalizes since len is 2.
                    float2 perp_dirA = float2(-dirA.y, dirA.x);
                    float2 perp_tangent = float2(-tangent.y, tangent.x);

                    dir = tangent;
                    len /= dot(perp_tangent, perp_dirA);
                }

                float2 normal = (float2(-dir.y, dir.x));

                bool isSegmentEnd = IsSegmentEnd(v.vertexID);

                if(!isSegmentEnd && (flip < 0))
                {
                    len *= -1;
                }

                // One might think that we should "extrude" only half of the length,
                // since the other point will also be moved away from this point by the same distance.
                // However, we are actually only moving half of len pixels since the space we are working in
                // is twice as large as the screen: (-width, +width) rather than (0, width) and same for the height.
                // Essentially there are two factor of two which cancel each other out.
                normal *= len;
                normal *= _ScreenParams.zw - 1; // Equivalent to `normal /= _ScreenParams.xy` but with less division.

                float2 offset = normal * orientation.x;

                o.vertex = current + float4(offset * pow(current.w, 1 - _Perspective), 0, 0);

                o.uv = float2((thicknessSign + 1) / 2, isSegmentEnd ? 0 : 1);
                o.color = context.thisNode.color;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 texColor = tex2D(_MainTex, i.uv);

                fixed4 color = _Color * i.color * texColor;
                color.xyz *= color.a;
                return color;
            }
            ENDHLSL
        }
    }
}
